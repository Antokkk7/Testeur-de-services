#!/bin/bash

SERV="SERV"
LOGS_SERV="$SERV/logs"
SERV_OK="$SERV/ServOK"
SERV_NOK="$SERV/ServNOK"

mkdir -p "$SERV"			# Créer le répertoire SERV s'il n'existe pas mais initialement en dehors de la boucle
	> "$LOGS_SERV"			# Effacer l'historique de LOGSSERV de la session précédente tout en gardant l'historique de la session actuelle car en dehors de la boucle

# Vérifier l'existance des fichiers nécessaires pour la vérification
if [ ! -f SERV/ServOK ]; then 
	touch SERV/ServOK 
fi
	
if [ ! -f SERV/ServNOK ]; then 
	touch SERV/ServNOK 
fi

# TDS - The super duper ultimate Testeur de Services
function afficher_intro() {
	clear
	cat << "EOF"
 ___________  _____ 
|_   _|  _  \/  ___|
  | | | | | |\ `--. 
  | | | | | | `--. \
  | | | |/ / /\__/ /
  \_/ |___/  \____/ 
                    
                    
EOF
	sleep 3
	clear
}

# Afficher le menu
function afficher_menu() {
    echo ==================================================
    echo "Choisissez une action :"
	echo "1. Service de ping réseau"
    echo "2. Service de monitoring CPU"
    echo "3. Service de monitoring RAM"
    echo "4. Service de disponibilité d'un site web"
    echo "5. Service de vérification DNS"
    echo "6. Service de vitesse réseau"
    echo "7. Service de vérification de certificat SSL"
    echo "8. Service de détection de connexions suspectes"
    echo "9. Service \"nah i'd win\""
    echo "10. Quitter"
    echo ==================================================
}

# Retire http(s):// et le chemin éventeul pour les URL
function extraire_hote() {
	echo "$1" | sed -E 's~^[a-zA-Z]+://~~; s~/.*~~'
}

# Enregistre les logs en "OK" sinon "NOK" et logs (et oui NOK et logs font doublons mais whatever)
function log_resultat() {
	local nom="$1"
	local statut="$2"
	echo "$nom" >> "$LOGS_SERV"
	if [[ "$statut" == "OK" ]]; then
		echo "$nom" >> "$SERV_OK"
		echo "[OK] $nom"
	else
		echo "$nom" >> "$SERV_NOK"
		echo "[NOK] $nom"
	fi
}

# 1. Service de ping réseau - Vérif si une machine ou un site répond
function service_ping() {
	echo "Entrez l'adresse ou le nom de domaine à ping (ex : https://google.com) :"
	read cible
	hote=$(extraire_hote "$cible")
	# Check si windows ou linux ou autres
	if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
		ping -n 2 -w 2000 "$hote" &> /dev/null
	else
		ping -c 2 -W 2 "$hote" &> /dev/null
	fi
	if [ $? -eq 0 ]; then
		log_resultat "Ping:$hote" "OK"
	else
		log_resultat "Ping:$hote" "NOK"
	fi
}

# 2. Service de monitoring CPU - Vérif si la charge CPU dépasse un seuil donné
function service_cpu() {
	echo "Entrez le seuil de charge CPU à ne pas dépasser (en %) :"
	read seuil
	if command -v top &> /dev/null; then
		# Linux
		charge=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.0f", 100 - $1}')
	elif command -v wmic &> /dev/null; then
		# Windows (windows 10 et moins) via wmic
		charge=$(wmic cpu get loadpercentage | grep -Eo '[0-9]+' | head -1)
	elif command -v powershell &> /dev/null; then
		# Windows (via PowerShell si wmic est absent, average windows 11 experience)
		charge=$(powershell -NoProfile -Command "[math]::Round((Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue)" 2>/dev/null | tr -d '\r')
	fi
	if [ -z "$charge" ]; then
		echo "Impossible de récupérer la charge CPU sur ce système."
		log_resultat "CPU:indisponible" "NOK"
		return
	fi
	echo "Charge CPU actuelle : $charge%"
	if [ "$charge" -le "$seuil" ]; then
		log_resultat "CPU:${charge}%<=${seuil}%" "OK"
	else
		log_resultat "CPU:${charge}%>${seuil}%" "NOK"
	fi
}

# 3. Service de monitoring RAM - Vérif l'utilisation de RAM de ce prgm
function service_ram() {
	local winpid mem_octets ram_ko
 
	if ps -o rss= -p $$ &> /dev/null; then
		# Linux
		ram_ko=$(ps -o rss= -p $$)
		mem_octets=$(( ram_ko * 1024 ))
	elif [ -f "/proc/$$/winpid" ]; then
		# Windows
		winpid=$(cat "/proc/$$/winpid")
		if command -v powershell &> /dev/null; then
			mem_octets=$(powershell -NoProfile -Command "(Get-Process -Id $winpid).WorkingSet64" 2>/dev/null | tr -d '\r')
		elif command -v wmic &> /dev/null; then
			mem_octets=$(wmic process where "ProcessId=$winpid" get WorkingSetSize | grep -Eo '[0-9]+')
		fi
	fi
 
    # Giga sad si ce message proc (average frigo connecté) 
	if [ -z "$mem_octets" ]; then
		echo "Impossible de récupérer l'utilisation mémoire sur ce système."
		log_resultat "RAM:indisponible" "NOK"
		return
	fi
 
	ram_ko=$(( mem_octets / 1024 ))
	echo "Utilisation mémoire de ce programme : ${ram_ko} Ko"
	log_resultat "RAM:${ram_ko}Ko" "OK"
}

# 4. Service de disponibilité d'un site web - Teste si un site renvoie un code HTTP 200
function service_web() {
	echo "Entrez l'URL du site à tester (ex : https://google.com) :"
	read url
	code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url")
	echo "Code HTTP reçu : $code"
	if [ "$code" == "200" ]; then
		log_resultat "Web:$url" "OK"
	else
		log_resultat "Web:$url(${code})" "NOK"
	fi
}

# 5. Service de vérification DNS - Vérif si un domaine pointe correctement
function service_dns() {
	echo "Entrez le nom de domaine à vérifier :"
	read domaine
	resultat=$(nslookup "$domaine" 2>/dev/null)
	if [ -n "$resultat" ] && ! echo "$resultat" | grep -qi "can't find"; then
		echo "$resultat"
		log_resultat "DNS:$domaine" "OK"
	else
		echo "Le domaine ne pointe vers aucune adresse."
		log_resultat "DNS:$domaine" "NOK"
	fi
}

# 6. Service de vitesse réseau - Mesure la latence ou le débit (download / upload / les deux)
function service_vitesse() {
	echo "Que voulez-vous mesurer ?"
	echo "1. Download"
	echo "2. Upload"
	echo "3. Les deux"
	read choix_vitesse
	case $choix_vitesse in
		1) mesurer_download ;;
		2) mesurer_upload ;;
		3) mesurer_download; mesurer_upload ;;
		*) echo "Choix invalide." ;;
	esac
}

function mesurer_download() {
	vitesse=$(curl -o /dev/null -s -w "%{speed_download}" --max-time 10 "http://speedtest.tele2.net/1MB.zip")
	vitesse_mo=$(echo "$vitesse" | awk '{printf "%.2f", $1/1024/1024}')
	echo "Vitesse de téléchargement : ${vitesse_mo} Mo/s"
	log_resultat "Download:${vitesse_mo}Mo/s" "OK"
}

function mesurer_upload() {
	dd if=/dev/zero of=/tmp/upload_test.bin bs=1M count=1 &> /dev/null
	vitesse=$(curl -o /dev/null -s -w "%{speed_upload}" --max-time 10 -F "file=@/tmp/upload_test.bin" "https://httpbin.org/post")
	vitesse_mo=$(echo "$vitesse" | awk '{printf "%.2f", $1/1024/1024}')
	echo "Vitesse d'envoi : ${vitesse_mo} Mo/s"
	rm -f /tmp/upload_test.bin
	log_resultat "Upload:${vitesse_mo}Mo/s" "OK"
}

# 7. Service de vérif de certificat SSL - Vérif si un certificat est valide ou expiré
function service_ssl() {
	echo "Entrez le domaine à vérifier (ex : https://google.com) :"
	read domaine
	hote=$(extraire_hote "$domaine")
	date_exp=$(echo | openssl s_client -servername "$hote" -connect "$hote:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
	if [ -z "$date_exp" ]; then
		echo "Impossible de récupérer le certificat."
		log_resultat "SSL:$hote" "NOK"
		return
	fi
	echo "Date d'expiration : $date_exp"
	exp_epoch=$(date -d "$date_exp" +%s 2>/dev/null)
	now_epoch=$(date +%s)
	if [ -n "$exp_epoch" ] && [ "$exp_epoch" -gt "$now_epoch" ]; then
		log_resultat "SSL:$hote" "OK"
	else
		log_resultat "SSL:$hote" "NOK"
	fi
}

# 8. Service de détection de connexions sus - Analyse les IP connectées
function service_ip_suspectes() {
	echo "Analyse des connexions actives..."
	connexions=$(ss -tn state established 2>/dev/null | awk 'NR>1 {print $4}' | cut -d: -f1 | sort | uniq -c | sort -rn)
	if [ -z "$connexions" ]; then
		echo "Aucune connexion active détectée."
		log_resultat "IP:aucune" "OK"
	else
		echo "Adresses IP distantes connectées :"
		echo "$connexions"
		log_resultat "IP:analyse" "OK"
	fi
}

# 9. Service "nah i'd win" - oui.
function nah_id_win() {
	local art_file
	art_file=$(mktemp)
	cat > "$art_file" << "EOF"
          ⠀⠀⠀⠀⠀⠀⣾⡳⣼⣆⠀⠀⢹⡄⠹⣷⣄⢠⠇⠻⣷⣶⢀⣸⣿⡾⡏⠀⠰⣿⣰⠏⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⣀⣀⣀⡹⣟⡪⢟⣷⠦⠬⣿⣦⣌⡙⠿⡆⠻⡌⠿⣦⣿⣿⣿⣿⣦⣿⡿⠟⠚⠉⠀⠉⠳⣄⡀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⡀⢀⣼⣟⠛⠛⠙⠛⠉⠻⢶⣮⢿⣯⡙⢶⡌⠲⢤⡑⠀⠈⠛⠟⢿⣿⠛⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣆⠀⠀⠀
⠀⠀⠀⠀⠀⡸⠯⣙⠛⢉⣉⣙⣿⣿⡳⢶⣦⣝⢿⣆⠉⠻⣄⠈⢆⢵⡈⠀⠀⢰⡆⠀⣼⠓⠀⠀⠀  Nah    ⠀⠀⠈⣷⠀⠀
⠀⠀⠀⠖⠉⠻⣟⡿⣿⣭⢽⣽⣶⣈⢛⣾⣿⣧⠀⠙⠓⠀⠑⢦⡀⠹⣧⢂⠀⣿⡇⢀⣿⠺⠇    I'd       ⠀⣿⠀⠀
⠀⠀⠀⠀⠐⠈⠉⢛⣿⣿⣶⣤⣈⠉⣰⣗⡈⢛⣇⠀⣵⡀⠀⠘⣿⡄⢻⣤⠀⢻⡇⣼⣧⣿⡄⠀   Win      ⠀⠀⡿⠀⠀
⠀⠀⠀⠀⠀⣠⣾⣿⢍⡉⠛⠻⣷⡆⠨⣿⣭⣤⣍⠀⢹⣷⡀⠀⠹⣿⡄⠈⠀⢿⠁⣿⣿⠏⠀⠀⠀         ⠀⠀⠀⣇⠀⠀
⠀⣿⣇⣠⣾⣿⣛⣲⣿⠛⠀⠀⢀⣸⣿⣿⣟⣮⡻⣷⣤⡙⢟⡀⠀⠙⢧⠀⠀⠎⠀⠉⠁⠰⣿⠀⠀         ⠀⢀⡿⠀⠀
⠀⠈⢻⣿⣿⣽⣿⣿⣿⣴⡏⠚⢛⣈⣍⠛⠛⠿⢦⣌⢙⠻⡆⠁⠀⠀⠀⣴⣦⠀⠀⠀⠐⢳⢻⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠮⠀⠀⠀
⠀⠀⠈⠙⣿⣧⣶⣿⠿⣧⣴⣿⢻⡉⠀⢀⣠⣴⣾⡟⠿⠃⠁⣠⣤⡶⣾⡟⠅⠀⣀⡄⠀⣾⢸⣿⣏⢻⢶⣦⣤⣤⣄⢶⣾⣿⣡⣤⡄⠀
⠀⠀⣠⣞⣋⣿⣿⣾⣿⡿⡛⣹⡟⣤⢰⡿⠟⠉⣀⣀⣤⣤⡠⠙⢁⣾⡿⠂⠀⣿⠟⣁⠀⣹⠀⣹⣿⡟⣼⣿⣿⣌⣿⣞⣿⣿⠁⠀⠀⠀
⠀⢠⡿⢛⢟⣿⣿⣿⣿⣿⣿⡟⣼⣿⣟⢓⠛⣿⣏⣿⣵⣗⣵⣴⣿⢟⡵⣣⣼⣿⢟⣵⣶⢻⣶⣿⠀⠀⣈⢻⣿⣿⣿⢿⣾⢿⣧⠀⠀⠀
⠀⠘⠃⢸⣿⡾⣿⣿⣿⣿⣯⣿⣿⣿⣶⣿⣿⣟⣾⡿⣫⣿⣿⣿⣽⣿⣿⣿⣿⢫⣾⣿⣿⣿⣿⣿⣴⡆⣻⣿⡏⣿⢻⣧⣿⡿⣿⡆⠀⠀
⠀⠀⠀⠜⣿⣾⢿⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣭⣿⣖⣿⢿⣿⡿⣿⣿⣿⡿⢡⢯⣿⣿⣿⣿⣿⣿⣿⣧⡿⣾⣷⣿⣿⢿⣿⡇⠉⠁⠀⠀
⠀⠀⠀⠀⣿⣥⣾⣿⣿⣿⣿⣿⣿⣿⡇⣭⣿⣿⣿⣿⠃⠞⠟⣸⣿⠏⣸⣧⣀⠿⢿⣿⣿⣟⣿⣿⣿⣿⣽⣿⢿⣿⣿⣿⣿⠁⠀⠀⠀⠀
⠀⠀⠀⠈⠛⣹⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣟⣿⣿⡿⢶⣦⣄⣿⠏⠀⣿⣟⣿⣶⠾⣿⣟⣋⣛⣿⣿⣿⣿⡇⣻⣿⣿⣿⡏⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠟⠛⠫⣿⣿⣿⣿⣿⡿⣧⠛⣿⠛⣿⣿⣿⣷⡌⠹⡟⠀⠀⠉⡟⠋⢠⣾⣿⣿⣿⡟⣿⣿⣿⣿⢀⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠘⠋⣾⣷⣿⣿⣧⠙⠀⠙⢣⠝⠛⠋⣽⣷⢦⠇⠀⠀⠘⠁⣤⣾⣿⠝⠛⠉⠘⢻⣿⣿⢿⣼⣷⡟⢻⣷⠉⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠐⠟⢻⣿⣿⣿⡀⠀⠀⠀⠀ ⠀⠀⠀⠉⠀⠀⠀⠀  ⠈⠛⠀⠀⠀⠀⣾⠟⠀⢸⣷⣿⡇⠀⠛⠀⠀⠁⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠁⠀⢹⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⡧⠀⠀⠀⠀⠀⠀⠀⠀
       ⠀⠀⠀⠀⠀⠀⠈⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⢻⡿⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣇⠀⠀⠀⠀⠀⠀⠀⠀⠲⣄⠀⡄⠆⠀⠀⠀⠀⠀⠀⠀⠀⣼⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⣀⠀⠀⣠⣾⣿⣀⡄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⢻⣆⠀⠛⠁⠶⣶⣶⣶⣶⣶⣶⡶⠆⠘⠋⣠⡾⢫⣾⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠛⠀⠙⣷⡀⠀⠀⠙⠛⠛⠛⠛⠋⠁⠀⢀⣴⠋⠀⣾⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣿⣰⣦⡀⠸⣿⣦⡀⠀⠀⠀⠀⠀⠀⢀⣴⡟⠁⠀⠐⢻⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⣿⣿⣿⡄⢺⣿⡄⠹⣿⠻⢦⣤⣤⣤⣤⣶⣿⡟⢀⣀⠀⠀⢸⣿⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣠⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣮⣿⣿⡀⠹⡷⣦⣀⡀⡀⢸⣿⠏⢠⣾⣿⠀⠀⣾⣿⣿⣿⣿⣶⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀
⣀⣤⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠘⣷⣻⡟⠀⡼⠁⣴⣿⣿⣯⣥⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⠀⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣯⣿⣤⣤⣤⣬⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣄
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿ 
EOF
	if command -v mintty &> /dev/null; then
		# mintty comme terminal vu que j'ai gitbash mais...
		mintty -e bash -c "cat '$art_file'; echo; read -p 'Appuyez sur Entrée pour fermer...'" &
	elif command -v gnome-terminal &> /dev/null; then
		gnome-terminal -- bash -c "cat '$art_file'; echo; read -p 'Appuyez sur Entrée pour fermer...'"
	elif command -v konsole &> /dev/null; then
		konsole -e bash -c "cat '$art_file'; read -p 'Appuyez sur Entrée pour fermer...'"
	elif command -v xterm &> /dev/null; then
		xterm -hold -e "cat '$art_file'"
	elif command -v cmd.exe &> /dev/null; then
		# ... Windows sans mintty dispo : cmd.exe pour ouvrir une nouvelle fenêtre
		# et forcement (double "//" nécessaire pour éviter que gitbash ne convertisse "/c" en chemin)
		cmd.exe //c start "" bash -c "cat '$art_file'; echo; read -p 'Appuyez sur Entree pour fermer...'"
	else
		echo "Aucun terminal graphique détecté, affichage ici :"
		cat "$art_file"
	fi
}

# Boucle principale
afficher_intro
while true; do
    afficher_menu
    read -p "Votre choix : " choix
    case $choix in
        1) service_ping ;;
        2) service_cpu ;;
        3) service_ram ;;
        4) service_web ;;
        5) service_dns ;;
        6) service_vitesse ;;
        7) service_ssl ;;
        8) service_ip_suspectes ;;
        9) nah_id_win ;;
        10) echo "Au revoir !"; exit 0 ;;
        *) echo "Choix invalide." ;;
    esac
done