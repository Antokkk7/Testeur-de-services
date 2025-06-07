#!/bin/bash

SERV="SERV"
LIST_SERV="$SERV/listeServ"
SERV_OK="$SERV/ServOK"
SERV_NOK="$SERV/ServNOK"

mkdir -p "$SERV"			# Créer le répertoire SERV s'il n'existe pas mais initialement en dehors de la boucle
	> "$LIST_SERV"			# Effacer l'historique de LISTSERV de la session précédente tout en gardant l'historique de la session actuelle car en dehors de la boucle


# Afficher le menu
function afficher_menu() {
    echo ==================================================
    echo "Choisissez une action :"
	echo "1. Créer un service"
    echo "2. Ajouter des services à vérifier"
    echo "3. Afficher la liste des services"
    echo "4. Vérifier les services"
    echo "5. Afficher les services qui fonctionnent"
    echo "6. Afficher les services qui ne fonctionnent pas"
    echo "7. Compter les fichiers dans SERV"
    echo "8  Afficher la première ligne d'un dossier"
    echo "9  Affiche X premiere ligne de ServOK"
    echo "10. Affiche X premiere ligne de ServNOK"
    echo "11. Affiche X derniere ligne de ServOK"
    echo "12. Affche X derniere ligne de ServNOK"
    echo "13. Affiche un fichier et son contenu"
    echo "14. Quitter"
    echo ==================================================
}

# Créer des services
function creer_services() {
    echo "Donnez le nom du service à créer :"
    
	read nom_service
    touch "$nom_service"
	
	echo "..."	
    echo "Service créé."
}

# Ajouter des services à vérifier
function ajouter_services() {
    echo "Combien de services voulez-vous ajouter à la vérification ?"
    read nb_services
    for ((i = 0; i < nb_services; i++)); do
        echo "Entrez le nom du service $((i + 1)) :"
        read service
        echo "$service" >> "$LIST_SERV"
		
		service_file="$SERV/$service"
		if [ -e $service ]; then
			echo "Hello"> "$service_file"
		else
			echo "vide"> "$service_file"
		fi
    done
    echo "Services ajoutés à la vérification."
}

# Afficher les services
function afficher_services() {
    if [[ -f "$LIST_SERV" ]]; then
        echo "Liste des services :"
        cat "$LIST_SERV"
    else
        echo "Aucun service enregistré."
    fi
}

# Vérifier l'existance des fichiers nécessaires pour la vérification
if [ ! -f SERV/ServOK ]; then 
	touch SERV/ServOK 
fi
	
if [ ! -f SERV/ServNOK ]; then 
	touch SERV/ServNOK 
fi

# Vérifier les services
function verifier_services() {
    > "$SERV_OK"
    > "$SERV_NOK"
    if [[ -f "$LIST_SERV" ]]; then
        while read -r service; do
            service_file="$SERV/$service"
            if [[ -f "$service_file" && $(cat "$service_file") == "Hello" ]]; then
                echo "$service" >> "$SERV_OK" 
            else
                echo "$service" >> "$SERV_NOK"
            fi
        done < "$LIST_SERV"
        echo "Vérification terminée."
    else
        echo "Aucun service à vérifier."
    fi
}

# Afficher les services fonctionnels
function afficher_servok() {
    if [[ -f "$SERV_OK" ]]; then
        echo "Services fonctionnels :"
        cat "$SERV_OK"
    else
        echo "Aucun service fonctionnel."
    fi
}

# Afficher les services non fonctionnels
function afficher_servnok() {
    if [[ -f "$SERV_NOK" ]]; then
        echo "Services non fonctionnels :"
        cat "$SERV_NOK"
    else
        echo "Aucun service non fonctionnel."
    fi
}

# Compter le nombre de fichiers dans le répertoire SERV
function compter_fich() {
	ls -l "SERV" | wc -l 
}

# afficher à l’écran la première ligne d’un fichier dont le nom est saisi
function premiere_ligne() {
	echo "Veulliez saisir le nom du fichier à visualiser :"
	read pr_lign
	head -n 1 "$pr_lign"
}

# afficher à l’écran les X premières lignes de ServOK
function xpremiere_sok() {
	echo "Veulliez saisir le nombre de lignes à visualiser de ServOK:"
	read xpremiere_lignsok
	head -n "$xpremiere_lignsok" "$SERV_OK"
}

# afficher à l’écran les X premières lignes de ServNOK
function xpremiere_snok() {
	echo "Veulliez saisir le nombre de lignes à visualiser de ServNOK :"
	read xpremiere_lignsnok
	head -n "$xpremiere_lignsnok" "$SERV_NOK"
}

# afficher à l’écran les X dernières lignes de ServOK
function xderniere_sok() {
	echo "Veulliez saisir le nombre de lignes à visualiser de ServOK:"
	read xderniere_lignsok
	tail -n "$xderniere_lignsok" "$SERV_OK"
}

# afficher à l’écran les X dernières lignes de ServNOK
function xderniere_snok() {
	echo "Veulliez saisir le nombre de lignes à visualiser de ServNOK :"
	read xderniere_lignsnok
	tail -n "$xderniere_lignsnok" "$SERV_NOK"
}

function contenu_precede() {
	echo "Veulliez saisir le nom du fichier à visualiser :"
	read contenu_plus
	echo "Provenant du fichier $contenu_plus :" && cat "$contenu_plus"
}

# Boucle principale
while true; do
    afficher_menu
    read -p "Votre choix : " choix
    case $choix in
        1) creer_services ;;
        2) ajouter_services ;;		
        3) afficher_services ;;
        4) verifier_services ;;
        5) afficher_servok ;;
        6) afficher_servnok ;;
		7) compter_fich ;;
		8) premiere_ligne ;;
		9) xpremiere_sok ;;
		10) xpremiere_snok ;;
    	11) xderniere_sok ;;
     	12) xderniere_snok ;;
      	13) contenu_precede ;;
        14) echo "Au revoir !"; exit 0 ;;
        *) echo "Choix invalide." ;;
    esac
done
