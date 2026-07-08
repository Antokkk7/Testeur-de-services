# Testeur-de-services
Script en **<ins>Bash</ins>** qui teste l’état de service de services :

•  *Au lancement, le script affiche un ASCII pendant 3 secondes avant de faire apparaître la boucle de choix d’action.*

•  *Le script est une boucle qui permet à l’utilisateur de saisir un choix d’action parmi :*

<br/>  <br/>

• tester un service de ping réseau
> Vérifie si une machine ou un site répond. L’utilisateur saisit une adresse ou un nom de domaine, le script en extrait le nom d’hôte puis lance un ping dessus.
> Exemple : l’utilisateur saisit **antok.fr**, le script ping cette adresse et enregistre le résultat.

• tester un service de monitoring CPU
> Vérifie si la charge CPU dépasse un seuil saisi par l’utilisateur (en %).
> Exemple : l’utilisateur saisit **15**, le script relève la charge CPU actuelle et compare au seuil donné.

• tester un service de monitoring RAM
> Vérifie l’utilisation de RAM de **ce programme**, exprimée en Ko.

• tester un service de disponibilité d’un site web
> Teste si un site renvoie un code HTTP 200. L’utilisateur saisit l’URL du site à tester (ex : **antok.fr**).

• tester un service de vérification DNS
> Vérifie si un domaine pointe correctement via *nslookup*. L’utilisateur saisit le nom de domaine à vérifier.

• tester un service de vitesse réseau
> Mesure la vitesse de téléchargement et/ou d’envoi. L’utilisateur choisit entre **Download**, **Upload** ou **Les deux**, le résultat est affiché en Mo/s.

• tester un service de vérification de certificat SSL
> Vérifie si un certificat est valide ou expiré. L’utilisateur saisit le domaine à vérifier (ex : **antok.fr**), le script relève la date d’expiration du certificat.

• tester un service de détection de connexions suspectes
> Analyse les IP connectées à la machine à travers les connexions réseau actives.

• Chaque test met à jour deux fichiers créés si nécessaire dans SERV : *ServOK* et *ServNOK*. Chacun contient respectivement les services qui fonctionnent et ceux qui ne fonctionnent pas, ainsi qu’un fichier *logs* qui garde l’historique de tous les tests effectués.
> Exemple : un test de ping sur **antok.fr** réussi ajoute la ligne **Ping:antok.fr** dans *ServOK*.

• le service *"nah i’d win"*
> ¯\\\_(ツ)\_/¯

• quitter le script

</br>

## Contributeurs

| <a href="https://github.com/Antokkk7"><img src="https://github.com/Antokkk7.png" width="70"></a> | <a href="https://github.com/Severinvlm"><img src="https://github.com/Severinvlm.png" width="70"></a> 
|---|---|
| **Antokkk7**<br>Dev | **Severinvlm**<br>Dev (v1)

Ceci était initialement un projet Universitaire en <ins>Bash</ins>.
