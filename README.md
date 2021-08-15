# Moniteur-Arduino
Moniteur pour Arduino avec 4 zones d'affichages


Lorsque l'on débuggue du code Arduino, on utilise généralement le Serial Moniteur. Mais celui-ci ne dispose que d'une fenêtre. Ce petit outil, développé avec Processing, permet d'afficher des messages dans 4 zones différentes (petites fenêtres).

## Démarrage
Chargez le code Arduino et compilez le dans un UNO par exemple.
Lancez Moniteur.pde avec Processing 3 ou 4.
Au lancement, il y a recherche du port série disponible. La vitesse par défaut est de 9600 bauds.

## Les réglages

### Menu de fenêtre
Heure: ajoute heure minute seconde en face de chaque message. Option désactivée par défaut.
Scroll: active ou désactive le scroll de cette fenêtre. Option activée par défaut.
Effacement: efface le contenu de cette fenêtre.

### Menu en partie inférieure
De gauche à droite:

1. Nom du port série actuellement actif ou "..." si aucun n'est disponible. En cliquant sur ce bouton, un formulaire s'ouvre permettant de choisir le port série.
2. Vitese en bauds. En cliquant sur ce bouton, on peut choisir la vitesse.
3. Pause série. La communication série entre l'Arduino et le moniteur empêche le téléversement dans l'Arduino. En cliquant sur ce bouton, la liaison série entre le moniteur et l'Arduino est interrompue, permettant de renvoyer du code dans l'Arduino. La communication reprend lorsque l'on ferme la boîte de message.
4. Fenêtre. Permet de choisir le type d'affichage (de 1 à 4 fenêtres)

## Les commandes côté Arduino

Les messages sont envoyés au Moniteur avec Serial.println(). Avec un adatateur USB TTL, il est possible d'utiliser Software Serial et donc de continuer à utiliser D0-D1 pour autre chose.
Les messages peuvent comporter des "ordres" pour le moniteur. 
Exemples:
- Serial.println("&E2");                // & = début commande, E = effacement, 2 = fenêtre 2
- Serial.println("&T3Nouveau titre");   // & = début commande, T = changer le titre, 3 = fenêtre 3 puis le nouveau titre
- Serial.println("&A1Message");         // & = début commande, A = affichage, 1 = fenêtre 1 puis le message à afficher
- Serial.println("Nouveau Message");    // Message qui sera affiché dans la fenêtre défini par la dernière commande A envoyée

## Changement des valeurs des codes de commandes
Les codes permettant d'afficher, changer le titre de la fenêrte ou effacer celle-ci, sont définis au début du code pde, tout comme l'ensemble des textes, boutons etc... 
Les valeurs des codes sont dans OPCODE_START, OPCODE_EFFACEMENT, OPCODE_TITRE, OPCODE_AFFICHAGE.
