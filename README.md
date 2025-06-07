# Testeur-de-services
Script en **<ins>Bash</ins>** qui teste l’état de service de services : <br/>


•  *Le script est une boucle qui permet à l’utilisateur de saisir un choix d’action parmi :* <br/>  <br/>  <br/> 

• saisir des noms de services dont on vérifiera le fonctionnement.<br/> 
> La première étape consiste à saisir un nombre de services puis, autant de noms de services.<br/> 
> La seconde étape conciste à ce que le script enregistre les noms des services dans un fichier listeServ placé dans SERV. <br/>
Exemple : l’utilisateur saisit **2** puis **database** et **web**. Le fichier *listeServ* contient deux lignes : une avec **database** et l’autre avec **web**.

• afficher la liste des services
> À travers un echo de la *Liste des services*.

• vérifier si le service fonctionne. 
> Cela consiste à vérifier l’existence d’**un** fichier **par** service dans le répertoire SERV. Le service est fonctionnel si le fichier du même nom contient **<ins>Hello</ins>**. <br/>
> Suite au test, deux fichiers sont mis à jour et créés si nécessaire dans SERV : *ServOK* et *ServNOK*. Chacun contient respectivement les services qui fonctionnent et ceux qui ne fonctionnent pas.
> Exemple : les deux services surveillés sont database et web, il doit donc y avoir deux fichiers ordinaires SERV/database et SERV/web chacun contenant <ins>Hello</ins>.

• afficher le nombre de services qui fonctionnent
> Trouvables dans le fichier *SERV_OK*.

• afficher le nombre de services qui ne fonctionnent pas
> Trouvables dans le fichier *SERV_NOK*.

• afficher la liste des services qui fonctionnent
> Trouvables dans le fichier *SERV_OK*.

• afficher la liste des services qui ne fonctionnent pas
> Trouvables dans le fichier *SERV_NOK*.

• compter le nombre de fichiers dans SERV
> Trouvables dans le fichier *SERV* avec : *ls -l "SERV" | wc -l*

• afficher à l’écran la première ligne d’un fichier dont le nom est saisi
> Obtenable avec : *head -n 1 "$pr_lign"* 

• afficher les X premières lignes de ServOK (le X étant saisi)
> *head -n "$xpremiere_lignsok" "$SERV_OK"*

• afficher les X dernières lignes de ServOK (le X étant saisi)
> *head -n "$xpremiere_lignsnok" "$SERV_NOK"*

• afficher les X premières lignes de ServNOK (le X étant saisi)
> *tail -n "$xderniere_lignsok" "$SERV_OK"*

• afficher les X dernières lignes de ServNOK (le X étant saisi)
> *tail -n "$xderniere_lignsnok" "$SERV_NOK"*

• afficher à l’écran le contenu d’un fichier dont le nom est saisi précédé du nom du fichier
> *read contenu_plus*

• quitter le script
