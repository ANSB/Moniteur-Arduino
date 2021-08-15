//====================================================================
// Moniteur série
// V1.00 du 15/08/2021
// PL Lamballais aka Féroce Lapin
//====================================================================

// Le 15/08/2021. Finalisation du scroll de texte dans les fenêtres avec prise
// en compte de texte trop long (clipping). Gestion du cas de port série indisponible
// et ajouter boite d'info pendant la tentative de connexion.
// Le 14/08/2021. gestion de tous les boutons du bas avec changement de port
// série, vitesse, changement des fenêtres, pause série et copyright.
// Le 13/08/2021. Début du dév à partir du code de l'Oscilo. Menu de
// sélection du port_serie série et menu de sélection du type de fenêtre.
// Affichage des fenêtres.

//----------------------------------------------------------------------

import processing.serial.*;
import javax.swing.JOptionPane; 
import javax.swing.JDialog;

Serial port_serie;  // Création d'un objet série
// Index du port_serie série. En global car on peut demander à couper
// temporairement la liaison série, pour permettre le téléchargement
// depuis l'Arduino. On utilisera ensuite cet index pour ré-ouvrir
// la liaison.
int idx_serie;

// Position vertical du texte qu'on affiche
int pos_text = 10;

PFont f;

// Les valeurs pour les fenêtres
// Position X
// Position Y
// Largeur
// Hauteur
// Position initiale d'affichage (axe des X)
// Position initiale d'affichage (axe des Y)
// Couleur du cadre
// Couleur de la bande de titre
// Les index:
// 0 = grande fenêtre, seule
// 1 = Fenetre verticale à gauche
// 2 = Fenêtre verticale à droite
// 3 = Fenêtre horizontale en haut
// 4 = Fenêtre horizontale en bas
// 5 = Petite fenêtre en haut à gauche
// 6 = Petite fenêtre en haut à droite
// 7 = Petite fenêtre en bas à gauche
// 8 = Petite fenêtre en bas à droite
// Le tableau ci-dessous donne, pour chaque fenêtre, sa position
// X et Y, sa largeur et sa hauteur.

  // Nous déclarons maintenant notre tableau et nous le remplissons
String selection_fenetre[] = {
"1-Une seule fenetre",
"2-Deux fenetres verticales", 
"3-Deux fenetres horizontale",
"4-Trois fenêtres - Grande à gauche",
"5-Trois fenêtres - Grande à droite",
"6-Trois fenêtres - Grande en haut",
"7-Trois fenêtres - Grande en bas", 
"8-Quatre fenetres"};

int tab_fenetre_dimension[][] = {
{0,0,1000,750},
{0,0,500,750},
{500,0,500,750},
{0,0,1000,375},
{0,375,1000,375},
{0,0,500,375},
{500,0,500,375},
{0,375,500,375},
{500,375,500,375}
};

// On affiche la fenêtre un tout petit peu plus petite, pour voir
// le cadre noir, autour.
final int DEFINE_ECART_X = 2;
final int DEFINE_ECART_Y = 2;
final int DEFINE_ECART_W = 4;
final int DEFINE_ECART_H = 4;
final int DEFINE_ESPACE_MESSAGE = 3;  // Interligne (texte de message)

// Les couleurs des fenêtres
int tab_fenetre_couleur_cadre[] = {#000000,#000000,#000000,#000000,#000000,#000000,#000000,#000000,#000000};
int tab_fenetre_couleur_menu[] = {#b3ffb3,#b3ffb3,#ffcccc,#b3ffb3,#cceeff,#b3ffb3,#ffb3b3,#d9b3ff,#ffffb3};
int tab_fenetre_couleur_fond[] = {#EEEEEE,#EEEEEE,#EEEEEE,#EEEEEE,#EEEEEE,#EEEEEE,#EEEEEE,#EEEEEE,#EEEEEE};

// Le tableau qui contiendra les index de fenêtre
// 0-Une seule fenetre => 0,100,100,100
// 1-Deux fenetres verticales => 1,2,100,100
// 2-Deux fenetres horizontale => 3,4,100,100
// 3-Trois fenêtres - Grande à gauche => 1,6,8,100
// 4-Trois fenêtres - Grande à droite=> 5,6,2,100
// 5-Trois fenêtres - Grande en haut => 3,7,8,100
// 6-Trois fenêtres - Grande en bas => 5,6,4,100
// 7-Quatre fenetres => 5,6,7,8
int tab_idx_fenetre[][] = {{0,100,100,100},{1,2,100,100},{3,4,100,100},{1,6,8,100},{5,2,7,100},{3,7,8,100},{5,6,4,100},{5,6,7,8}};
int selected_affichage_fenetre = 7;  // Défaut = 4 petites fenêtres
int selected_message_fenetre = 0;  // Fenêtre dans laquelle on écrit les messages

// Ce tableau donne pour chaque fenêtre, l'offset XY de ses boutons de menus
int tab_fenetre_offset_menu[][] = {
{0,17},
{0,17},
{500,17},
{0,17},
{0,392},
{0,17},
{500,17},
{0,392},
{500,392}
};

int hauteur_menu = 45;  // Hauteur de la bande de menu en haut des fenêtres

// Les titres des fenêtres (par défaut car l'Arduino peut les changer
String tab_fenetre_titre[] = {"Fenêtre 1","Fenêtre 2", "Fenêtre 3", "Fenêtre 4"};

// Les tailles de fonte
int grand_texte = 14;
int petit_texte = 10;
int debug_texte = 12;
int btn_texte = 12;

// Coord XY, largeur et hauteur des boutons de menu de fenêtre
// Pour l'affichage et la détection, on appliquera l'offset qui
// se trouve dans tab_fenetre_offset_menu
// Activation ou non de la date
int tab_fenetre_pos_menu[][] = {{5,5,80,20},{95,5,80,20},{185,5,80,20}};
String tab_fenetre_texte_menu[]= {"Date","Scroll","Effacer"};

// Etat des fenêtres au niveau affichage de date et scroll
// 0= pas de date; 1= affichage date
// 0 = pas de scroll, 1=scroll actif
int tab_fenetre_etat[][] = {{0,1},{0,1},{0,1},{0,1}};

// Position Y d'affichage du prochain texte dans la fenêtre
int tab_fenetre_pos_scroll[] = {0,0,0,0};

// Coord XY, largeur et hauteur des boutons du menus (en bas)
// Port série
// Vitesse série
// Type de fenêtre
// Stop le port_serie série
int tab_size_btn_menu[][] = {{5,760,200,20},{215,760,100,20},{325,760,100,20},{435,760,100,20},{850,760,100,20}};
String tab_texte_btn_menu[]= {"Port série","Vitesse série","Pause série","Fenêtres","A propos..."};

// Par défaut on se connecte sur le 1er port_serie série disponible
int selected_port_serie = 0;

// Les diférentes vitesses possibles pour le port_serie série
String selection_bauds[] = {"4800 bauds","9600 bauds","19200 bauds","38400 bauds","57600 bauds","74880 bauds","115200 bauds"};
int selected_bauds = 9600;  // Par défaut, 9600 bauds
boolean flag_port_serie_ouvert;  //Flag permettant de savoir si un port est actif ou non (true=oui, false=non)

// Texte pour traduction
final String DEFINE_TEXT_PORT_SERIE = "Choisissez le port_serie série de l'Arduino";
final String DEFINE_TEXT_AFFICHAGE = "Choisissez le type d'affichage";
final String DEFINE_TEXT_VITESSE_SERIE = "Choisissez la vitesse du port série";
final String DEFINE_TEXT_BOITE = "Boite de dialogue";
final String DEFINE_TEXT_PAUSE_SERIE = "Arrêt du port série pour envoi de programme vers l'Arduino.\nFermez cette boite de dialogue pour rédémarrer le port série.";
final String DEFINE_TEXT_COPYRIGHT = "Moniteur Série pour débuggage Arduino\nPL Lamballais aka Féroce Lapin\nV1.00 - 14/08/2021";
final String DEFINE_ERREUR_FENETRE = "Le numéro de fenêtre reçu de l'Arduino ne correspond\nà aucune fenêtre active. La communication série a été interrompue.\nCorriger votre code Arduino puis fermez ce message pour relancer.";
final String DEFINE_ERREUR_FENETRE_ACTIVE = "Le numéro de fenêtre reçu de l'Arduino ne correspond\nà aucune fenêtre active.\nLe moniteur va activer toutes ses fenêtres.";
final String DEFINE_ERREUR_PORT_SERIE = "Erreur: le port série sélectionné n'est pas disponible.";
final String DEFINE_ERREUR_ALL_PORT_SERIE = "Erreur: aucun port série ne semble disponible.";
final String DEFINE_RECHERCHE_PORT_SERIE = "Recherche d'un port série disponible\nPatience...";
final String DEFINE_CONNEXION_PORT_SERIE = "Connexion au port série\nPatience...";
// Les codes que l'Arduino peut envoyer
final String OPCODE_START = "&";  // Marque de début de commande
final String OPCODE_EFFACEMENT = "E";  // Effacement de la fenêtre
final String OPCODE_TITRE = "T";  // Changement de titre de la fenêtre
final String OPCODE_AFFICHAGE = "A";  // Sélection de la fenêtre d'affichage
//=======================================================================================
void setup() 
{
  size(1000,800);          // Défini la taille de la fenêtre
  init_serie();            // Recherche du port série par défaut
  affichage_fenetres();    // Affichage des fenêtres et de leurs boutons
  affichage_menu();        // Affichage de la bande de menu, tout en bas
} 
//================================================================================
// Les boites de dialogue pour les différentes sélections
//================================================================================
// Liste les port_series série pour que l'utilisateur choisisse celui de l'Arduino
boolean selection_serie()
{
  
  int tmp;
  
  final String[] lst_port_series = Serial.list();  // Demande liste des port_series série
  int num_port_serie = lst_port_series.length;    // Nombre de port_series série disponibles
  
  // La lecture des Ports Série nous donne aussi bien les port_series "CU" que
  // les port_series "TTY". Comme nous ne voulons que les port_series non TTY, nous allons lire
  // la liste afin de les compter, ce qui nous permettra de déclarer le tableau d'Objet
  int num_port_serie_ok = 0;
  for (int x = 0; x < num_port_serie; x++)
  {
    String nom_port_serie = lst_port_series[x];
    if (!nom_port_serie.startsWith("/dev/tty"))
    {
      num_port_serie_ok++;  // Compte ce port_serie
    }
  }
  
  // Nous déclarons maintenant notre tableau et nous le remplissons
  Object[] selection = new Object[num_port_serie_ok];

  // Boucle sur les port_series série potentiels
  for (int x = 0; x < num_port_serie; x++)
  {
    // Nous ne voulons que les port_series "non TTY"
    String nom_port_serie = lst_port_series[x];
    if (!nom_port_serie.startsWith("/dev/tty"))
    {
      nom_port_serie = (x+1)+"-"+nom_port_serie;  // Prend le nom du port_serie
      selection[x] = nom_port_serie;
    }
  }
  
  // Affichage de la boite avec le menu déroulant pour le choix
  String retour = (String) JOptionPane.showInputDialog(
                                   null, DEFINE_TEXT_PORT_SERIE,
                                   DEFINE_TEXT_BOITE,
                                   JOptionPane.QUESTION_MESSAGE,
                                   null, selection, selection[selected_port_serie]);

  // Nous testons le retour. Si c'est Cancel, ou fermeture fenêtre, on s'en va
  if ((retour == null)||(retour == ""))
  {
      return false; 
  }
  else
  {
    // Texte de l'entrée choisie, qui commence par l'index du port série
    String[] parts = retour.split("-");
    tmp = (Integer.parseInt(parts[0]))-1; // -1 car dans la liste on a fait +1
    if (tmp != selected_port_serie)
    {
      selected_port_serie = tmp;
      return true;
    }
    else
    {
      return false;
    }
  }
}
//--------------------------------------------------------------------------------------
// Selection du nombre de fenêtres et de leur positon
boolean selection_fenetre()
{  
  int tmp;
  
  // Affichage de la boite avec le menu déroulant pour le choix
  String retour = (String) JOptionPane.showInputDialog(
                                   null, DEFINE_TEXT_AFFICHAGE,
                                   DEFINE_TEXT_BOITE,
                                   JOptionPane.QUESTION_MESSAGE,
                                   null, selection_fenetre, selection_fenetre[selected_affichage_fenetre]);

  // Nous testons le retour. Si c'est Cancel, ou fermeture fenêtre...
  if ((retour == null)||(retour == ""))
  {
      return false; 
  }
  else
  {
    // Texte de l'entrée choisie, qui commence par l'index du tableau de fenêtre
    String[] parts = retour.split("-");
    tmp = (Integer.parseInt(parts[0]))-1; // -1 car dans la liste on a fait +
    if (tmp != selected_affichage_fenetre)
    {
      selected_affichage_fenetre = tmp;
      return true;
    }
    else
    {
      return false;  
    }
  }
}
//---------------------------------------------------------------------------------------
// Selection de la vitesse du port série
boolean selection_bauds()
{  
  int tmp;
  
  // Dans selected_bauds nous avons la vitesse en bauds. Mais la pré-sélection du menu
  // demande l'index dans le tableau. Or, le concept "Value/Text" des select HTML n'existe
  // pas... 
  int index_default = 0;
  int nb_bauds = selection_bauds.length; 
  
  String selected_bauds_str = str(selected_bauds);  // Vitesse mise en String
  // Boucle sur toutes les vitesses disponibles
  for (int x = 0; x < nb_bauds; x++)
  {
      // Si l'entrée de menu est pour la vitesse par défaut
     if (selection_bauds[x].startsWith(selected_bauds_str))
     {
       index_default = x;  // On note l'index de pré-réglage
       break;
     }
  }
  
  // Affichage de la boite avec le menu déroulant pour le choix
  String retour = (String) JOptionPane.showInputDialog(
                                   null, DEFINE_TEXT_VITESSE_SERIE,
                                   DEFINE_TEXT_BOITE,
                                   JOptionPane.QUESTION_MESSAGE,
                                   null, selection_bauds, selection_bauds[index_default]);
                                   
  // Nous testons le retour. Si c'est Cancel, ou fermeture fenêtre, on sort tout de suite
  if ((retour == null)||(retour == ""))
  {
      return false;
  }
  else
  {
    // Texte de l'entrée choisie, qui commence par la vitesse en bauds
    String[] parts = retour.split(" ");
    tmp = (Integer.parseInt(parts[0]));
    if (tmp != selected_bauds)
    {
      selected_bauds = tmp;
      return true;
    }
    else
    {
      return false;
    }
  }
}
//--------------------------------------------------------------------------------------
// Boite d'info
JDialog boite_info_on(String message)
{
  final JOptionPane optionPane = new JOptionPane(message, JOptionPane.INFORMATION_MESSAGE, JOptionPane.DEFAULT_OPTION, null, new Object[]{}, null);
  final JDialog dialog = new JDialog();
  dialog.setTitle("");
  dialog.setModal(false);
  dialog.setContentPane(optionPane);

  dialog.setDefaultCloseOperation(JDialog.DO_NOTHING_ON_CLOSE);
  dialog.setResizable(false);
  dialog.pack();
  dialog.setLocationRelativeTo(null);
  dialog.setVisible(true);
  return dialog;
}
void boite_info_off(JDialog dialog)
{
    dialog.dispose();
}
//=======================================================================================
// Application des réglages
//=======================================================================================
// Parcours les ports séries pour en trouver un libre et l'activer
void init_serie()
{
 
    JDialog dialog = boite_info_on(DEFINE_RECHERCHE_PORT_SERIE);
  
    boolean ret = false;
    final String[] lst_port_series = Serial.list();  // Demande liste des port_series série
    int num_port_serie = lst_port_series.length;    // Nombre de port_series série disponibles
    int x;
  
  // La lecture des Ports Série nous donne aussi bien les port_series "CU" que
  // les port_series "TTY". Comme nous ne voulons que les port_series non TTY, nous allons lire
  // la liste afin de les compter, ce qui nous permettra de déclarer le tableau d'Objet
  for (x = 0; x < num_port_serie; x++)
  {
    String nom_port_serie = lst_port_series[x];
    if (!nom_port_serie.startsWith("/dev/tty"))
    {
      // On tente l'ouverture...
      ret = test_connexion_serie(x,selected_bauds);

      if (ret == true)
      {
        selected_port_serie = x;
        break; 
      }
    }
  }
  boite_info_off(dialog);
  
  // Si on arrive ici avec ret = false c'est qu'on a trouvé aucun port série disponible
  if (ret == false)
  {
    JOptionPane.showMessageDialog(null, DEFINE_ERREUR_ALL_PORT_SERIE, DEFINE_TEXT_BOITE, JOptionPane.INFORMATION_MESSAGE);        
     flag_port_serie_ouvert = false;    
  }
  else
  {
    flag_port_serie_ouvert = true;
    port_serie.clear(); 
}
}
//--------------------------------------------------------------------------------------
// Régle le port série et sa vitesse. Cette fonction est appelée quand on change le
// port série ou sa vitesse.
void reglage_serie(boolean flag_stop)
{
    boolean ret;
    
    // Le flag indique si on doit stopper le port série
    if (flag_stop == true)
    {
      port_serie.clear();
      port_serie.stop();
    }
    
    JDialog dialog = boite_info_on(DEFINE_CONNEXION_PORT_SERIE);
    ret = test_connexion_serie(selected_port_serie, selected_bauds);
    boite_info_off(dialog);
    
    // Si le port est occupé, on l'indique...
    if (ret == false)
    {
      JOptionPane.showMessageDialog(null, DEFINE_ERREUR_PORT_SERIE, DEFINE_TEXT_BOITE, JOptionPane.INFORMATION_MESSAGE);        
     flag_port_serie_ouvert = false;
  }
    else
    {
      port_serie.clear(); 
     flag_port_serie_ouvert = true;
  }
}
//----------------------------------------------------------------------------------
// Tentative de connexion au port série. Retourne true si c'est un succés, false
// si c'est un échec
boolean test_connexion_serie(int portNumber, int baudRate)
{
      try
      {
            port_serie = new Serial(this, Serial.list()[portNumber], baudRate);
      }catch(Exception e){
        println("Port série "+portNumber+" Echec");
        return false;
      }
    return true;
}
//---------------------------------------------------------------------------------------
// Fonction d'affichage des éléments de fenêtres
void affichage_fenetres()
{
    //int numero_fenetre = 1;  // A l'écran nos fenêtres sont numérotés de 1 à 4 
    background(#000000);     // Sur fond noir   
    for (int x = 0; x < 4; x++)
    {
      // On cherche l'index de la fenêtre à afficher pour avoir ses data graphiques
      int index_draw = tab_idx_fenetre[selected_affichage_fenetre][x];
      
      // On ne dessine que les fenêtres avec un index != 100
      if (index_draw != 100)
      {
        affiche_fenetre(index_draw,x,true);  // Centre et aussi le haut
      }
    }
}
//---------------------------------------------------------------------------------------
// Sous routine de la précédente: affichage d'une seule fenêtre dont on reçoit l'index
// Sert à l'init mais aussi pour réinitialiser une fenêtre
void affiche_fenetre(int index_draw,int id_fenetre,boolean flag_centre)
{
  // tab_fenetre_dimension
  // tab_fenetre_couleur_cadre[]
  // tab_fenetre_couleur_menu[]    
  // tab_fenetre_couleur_fond[]
     
  int pos_x = tab_fenetre_dimension[index_draw][0];
  int pos_y = tab_fenetre_dimension[index_draw][1];
  int largeur = tab_fenetre_dimension[index_draw][2];
  int hauteur = tab_fenetre_dimension[index_draw][3];  
   
  int offset_x_menu = tab_fenetre_offset_menu[index_draw][0];
  int offset_y_menu = tab_fenetre_offset_menu[index_draw][1];       
         
  // Un petit peu de cadre autour
  pos_x = pos_x + DEFINE_ECART_X;
  pos_y = pos_y + DEFINE_ECART_Y;     
  largeur = largeur - DEFINE_ECART_W; 
  hauteur = hauteur - DEFINE_ECART_H; 
   
  // Si on doit afficher toute la fenêtre...
  // Note: cela sert quand on en efface le contenu
  if (flag_centre == true)
  {
    // Cadre principal de la fenêtre
    stroke(tab_fenetre_couleur_cadre[index_draw]);
    fill(tab_fenetre_couleur_fond[index_draw]);
    rect(pos_x,pos_y,largeur,hauteur);
    // Comme on efface le centre on ré-init sa position de scroll
    tab_fenetre_pos_scroll[id_fenetre] = 0;
  }          
  
  // La bande du haut, bouton etc... toujours mis à jour
  
  // Bande de menu du haut
  stroke(tab_fenetre_couleur_cadre[index_draw]);
  fill(tab_fenetre_couleur_menu[index_draw]);
  rect(pos_x,pos_y,largeur,hauteur_menu);
          
  // Trait de séparation entre la bande de titre et la zone d'affichage
  stroke(#000000);
  line(pos_x,pos_y+hauteur_menu,pos_x+largeur,pos_y+hauteur_menu);
 
  // Titre de la fenêtre, centrée, en haut
  f = createFont("Arial Black",grand_texte);
  textFont(f,grand_texte);
  textAlign(CENTER);
  fill(0,0,0);
  String txt = tab_fenetre_titre[id_fenetre];
  text(txt,pos_x+(largeur/2),pos_y+grand_texte);      
     
  f = createFont("Arial Black",btn_texte);
  textFont(f,btn_texte);
  textAlign(CENTER);
     
  // On dessine les boutons
  for (int y = 0; y < 3; y++)
  {
    int pos_x_menu = tab_fenetre_pos_menu[y][0] + offset_x_menu;
    int pos_y_menu = tab_fenetre_pos_menu[y][1] + offset_y_menu;
    int largeur_menu = tab_fenetre_pos_menu[y][2]; 
    int hauteur_menu = tab_fenetre_pos_menu[y][3];
    String text_menu = tab_fenetre_texte_menu[y];
       
    fill(#FFFFFF); 
    rect(pos_x_menu,pos_y_menu,largeur_menu,hauteur_menu,6); 
        
    fill(#000000);  
    text(text_menu,pos_x_menu+(largeur_menu/2),pos_y_menu+(hauteur_menu/2)+(btn_texte/2)); 
    
    // Si nous sommes sur le bouton Date et que la date est active, on met un rond vert
    if (y == 0 && tab_fenetre_etat[id_fenetre][0] == 1)
    {
        fill(#669900);
        circle(pos_x_menu+largeur_menu-10, pos_y_menu+(hauteur_menu/2), 8);
    }
    
    // Si nous sommes sur le bouton Scroll et que le scroll est actif, on met un rond vert
    if (y == 1 && tab_fenetre_etat[id_fenetre][1] == 1)
    {
         fill(#669900);
        circle(pos_x_menu+largeur_menu-10, pos_y_menu+(hauteur_menu/2), 8);     
    }
  }    
}
//---------------------------------------------------------------------------------------
// Affichage du menu, tout en bas. Permet de changer le port_serie série, de changer la vitesse
// de celui-ci, de changer les fenêtre et de stopper temporairement la liaison série.
// Ordre des boutons:
// Nom du port série (sera remplacé par le nom véritable)
// Vitesse du port série '(donne la vitesse en bauds
// Pause du port série
// Type de fenêtre
// Copyright
void affichage_menu()
{
  String text_menu;
  int tmp;
  
  fill(#FFFFFF);
  stroke(#FFFFFF);
  f = createFont("Arial Black",btn_texte);
  textFont(f,btn_texte);
  textAlign(CENTER);
 
  tmp = tab_texte_btn_menu.length;
  for (int x = 0; x < tmp; x++)
  {
    int pos_x = tab_size_btn_menu[x][0];
    int pos_y = tab_size_btn_menu[x][1];
    int largeur = tab_size_btn_menu[x][2];
    int hauteur = tab_size_btn_menu[x][3]; 
    fill(255,255,255); 
    rect(pos_x,pos_y,largeur,hauteur,6); 
    
    fill(0,0,0);  
    
    // Si nous sommes sur le nom du port série ou la vitesse...
    if (x == 0 || x == 1)
    {
      if (x == 0)
      {
        if (flag_port_serie_ouvert == true)
        {
          // Le port série est actif, on met son nom
          String[] lst_port_series = Serial.list();
          String tmp_str = lst_port_series[selected_port_serie];
          // On ne prend que la fin du nom pour que ce soit plus court
          String[] parts = tmp_str.split("/");
          int nb_tmp = parts.length;
          text_menu = parts[nb_tmp-1];
        }
        else
        {
          // Pas de port série actif donc on met pas de nom
          text_menu = "...";
        }
      }
      else
      {
        text_menu = str(selected_bauds)+ " bauds";
      }
    }
    else
    {
      text_menu = tab_texte_btn_menu[x];  
    }
    
    text(text_menu,pos_x+(largeur/2),pos_y+(hauteur/2)+(btn_texte/2));
  }  
}
//=======================================================================================
// Fonction d'affichage de ce qu'on a reçu de l'Arduino
// C'est pour tester, mais ça a l'air OK.
void action_fenetre(String ligne_affichage)
{  
  String message = ligne_affichage;
  int index_draw;
  int idx_fenetre = 0;
  
  // Les valeurs d'opcode sont déclarés en haut
  // OPCODE_START Marque de début de commande
  // OPCODE_EFFACEMENT  Effacement de la fenêtre
  // OPCODE_TITRE Changement de titre de la fenêtre
  // OPCODE_AFFICHAGE Sélection de la fenêtre d'affichage
  // La valeur suivante, c'est le numéro de la fenêtre (1,2,3,4)
  
  String opcode = ligne_affichage.substring(0,1);
  if (opcode.equals(OPCODE_START) == true) 
  {
    String action = ligne_affichage.substring(1,2); 
  
   try 
      {
        idx_fenetre = Integer.parseInt(ligne_affichage.substring(2,3));
      }
    catch(NumberFormatException e)
      {        
        port_serie.clear();
        return;
      }
   
    // On ne peut pas avoir de numéro de fenêtre > 4
    if (idx_fenetre < 1 || idx_fenetre > 4)
    {
      port_serie.clear();
      port_serie.stop();
      JOptionPane.showMessageDialog(null, DEFINE_ERREUR_FENETRE, DEFINE_TEXT_BOITE, JOptionPane.INFORMATION_MESSAGE);  
      reglage_serie(false); 
      return;
    }
  
    index_draw = tab_idx_fenetre[selected_affichage_fenetre][idx_fenetre-1];
    // La fenêtre doit être active...
    if (index_draw == 100)
    {
        // On demande un affichage dans une fenêtre inactive... Donc on passe en mode 4 fenêtres!
      JOptionPane.showMessageDialog(null, DEFINE_ERREUR_FENETRE_ACTIVE, DEFINE_TEXT_BOITE, JOptionPane.INFORMATION_MESSAGE); 
      selected_affichage_fenetre = 7;
      affichage_fenetres();
      affichage_menu();
      return;
    }
  
    // Affichage d'un nouveau titre
    if (action.equals(OPCODE_TITRE) == true)
    {
      String titre = ligne_affichage.substring(3); 
      titre =  idx_fenetre+ "-" +titre;
      tab_fenetre_titre[idx_fenetre-1] = titre;
      affiche_fenetre(index_draw,idx_fenetre-1,false); 
      message = "";
    }
    else if (action.equals(OPCODE_EFFACEMENT) == true)
    {
      // Effacement fenêtre
      affiche_fenetre(index_draw,idx_fenetre-1,true); 
      message = ligne_affichage.substring(3); 
    }
    else if (action.equals(OPCODE_AFFICHAGE) == true)
    {
      selected_message_fenetre = idx_fenetre-1;
      message = ligne_affichage.substring(3);  
      //print("Affectation selected_message_fenetre: ");
      //println(selected_message_fenetre);
    }
  }
  
  // Nous avons fini de traiter les opcodes. S'il y a quelque chose à afficher, on affiche
  if (message.length() > 0)
  {
     index_draw = tab_idx_fenetre[selected_affichage_fenetre][selected_message_fenetre];
     affiche_message(index_draw,selected_message_fenetre,message);
  }
}
//---------------------------------------------------------------------------
// Affiche le message dans la fenêtre. Fait éventuellement scroller
void affiche_message(int index_draw,int idx_fenetre, String message)
{
  // Cherchons les préférences de cette fenêtre
  int affichage_date = tab_fenetre_etat[idx_fenetre][0];
  int scroll_message= tab_fenetre_etat[idx_fenetre][1];
 
 // Si on doit ajouter l'heure devant la date...
 if (affichage_date == 1)
 {
   // On pad avec des 0 si nécessaire
   int tmp_hour = hour();
   int tmp_min = minute();
   int tmp_sec = second(); 
   String str_hour;
   String str_min;
   String str_sec; 
   if (tmp_hour < 10)
   {
     str_hour = "0"+str(tmp_hour);
   }
   else
   {
     str_hour = str(tmp_hour);
   }
 
   if (tmp_min < 10)
   {
     str_min = "0"+str(tmp_min);
   }
   else
   {
     str_min = str(tmp_min);
   }   

   if (tmp_sec < 10)
   {
     str_sec = "0"+str(tmp_sec);
   }
   else
   {
     str_sec = str(tmp_sec);
   }      
    
    message = str_hour+":"+str_min+":"+str_sec+" - "+message;
 }
 
  // On cherche la position verticale d'affichage de la fenêtre destination
  int pos_affichage = tab_fenetre_pos_scroll[idx_fenetre];
  
  //Prenons les données de coord de la fenêtre
  int zone_copy_x = tab_fenetre_dimension[index_draw][0]+DEFINE_ECART_X+1; // + 1 pour le pixel du trait de gauche
  // On place Y sous le menu
  int zone_copy_y = tab_fenetre_dimension[index_draw][1]+DEFINE_ECART_Y+hauteur_menu+1;
  
  int zone_copy_largeur = tab_fenetre_dimension[index_draw][2]-DEFINE_ECART_W-1;  // - 1 pour le pixel du trait de droite
  
  // Comme l'affichage précédent on a incrémenter pos_affichage, on regarde
  // si, avec la valeur actuelle, on peut afficher. Mais pos_affichage n'étant
  // que la hauteur depuis le bas du menu, on doit compter l'écart tout en haut
  // Attention: on ajoute la hauteur des caractères car on veut que le bas de la
  // ligen soit visible. Or pos_affichage donne la position du haut du texte!
  int tmp_pos_affichage = pos_affichage +DEFINE_ECART_Y+hauteur_menu+DEFINE_ECART_H + debug_texte  +DEFINE_ESPACE_MESSAGE;
  if (tmp_pos_affichage > tab_fenetre_dimension[index_draw][3])
  {
     // On dépasse. Si on peut scroller on scrolle...
     if (scroll_message == 0)
     {
       return;  // En bas et pas de scroll donc bye bye...
     }
     // On fait une copie graphique de la zone  
      int src_copy_y = zone_copy_y + debug_texte+DEFINE_ESPACE_MESSAGE;
      pos_affichage = pos_affichage - debug_texte - DEFINE_ESPACE_MESSAGE;
      copy(zone_copy_x,src_copy_y,zone_copy_largeur,pos_affichage,zone_copy_x,zone_copy_y,zone_copy_largeur,pos_affichage);
      
      // On doit maintenant couvrir la zone du bas pour que le texte s'affiche dessus
      stroke(tab_fenetre_couleur_fond[index_draw]);
      fill(tab_fenetre_couleur_fond[index_draw]);
      rect(zone_copy_x,src_copy_y+pos_affichage - debug_texte - DEFINE_ESPACE_MESSAGE,zone_copy_largeur-1,debug_texte + DEFINE_ESPACE_MESSAGE-1);

  }
 
   // Affichage du message. La coord de le fonction text() c'est le coin supérieur gauche du texte
   // On va donc afficher et ensuite, incrémenter la position qui sera testé la fois suivante
  f = createFont("ArialMT",debug_texte);
  textFont(f,debug_texte);
  textAlign(LEFT);
  fill(#000000);
  // Le texte est affiché avec un petit écart pour ne pas coller en haut et à gauche
  // On passe, à la fonction texte, la position XY d'affichage et aussi la largeur
  // et la hauteur de la zone dans laquelle on accepte l'affichage. Ceci permet de
  // faire du cliping, dans le cas des chaines de caractères trop longues.
  int x1 = zone_copy_x+4;
  int y1 = pos_affichage+zone_copy_y;
  int largeur_texte = zone_copy_largeur-10;
  int hauteur_text = debug_texte+DEFINE_ESPACE_MESSAGE;
  text(message,x1,y1,largeur_texte,hauteur_text);  
  
  // Descend d'une ligne et sauve la valeur
  pos_affichage = pos_affichage + debug_texte + DEFINE_ESPACE_MESSAGE;
  tab_fenetre_pos_scroll[idx_fenetre] = pos_affichage;
  
}
//========================================================================================
// Fonction d'affichage. Appelée en boucle...
void draw()
{
  String ligne_affichage = "";
  
  // Si on a un port série de connecté...
  if (flag_port_serie_ouvert == true)
   {
    if ( port_serie.available() > 0) 
    {
      ligne_affichage = port_serie.readStringUntil('\n');
      // Parfois la lecture renvoi null...
      if (ligne_affichage != null)
        {
          //println(ligne_affichage);
          ligne_affichage = ligne_affichage.trim();
          action_fenetre(ligne_affichage); 
        }
    }
   }
}
//========================================================================================
// Evenement appelé quand la souris est enfoncée. On détecte la position du clic ce qui
// permet de savoir sur quoi on a cliqué.
void mousePressed()
{
    int tmp;
    boolean retour;
    int x;
  
    int pos_x;
    int pos_y;
    int largeur;
    int hauteur;   
    
    // Clic dans la zone de menu, en bas?
    tmp = tab_texte_btn_menu.length;
    for (x = 0; x < tmp; x++)
    {
      // Boucle sur les 4 boutons et prends leurs coordonnées
      pos_x = tab_size_btn_menu[x][0];
      pos_y = tab_size_btn_menu[x][1];
      largeur = tab_size_btn_menu[x][2];
      hauteur = tab_size_btn_menu[x][3];
  
      if(mouseX>pos_x && mouseX<pos_x+largeur && mouseY>pos_y && mouseY<pos_y+hauteur)
      {
        switch (x)
        {
          // Change port série
          case 0:
            retour = selection_serie();
            if (retour == true)
            {
              reglage_serie(true);
              affichage_menu();  // Réaffiche le menu du bas
            }
            break;
             
          // Change vitesse
          case 1:
            retour = selection_bauds();
            if (retour == true)
            {
              reglage_serie(true);
              affichage_menu();  // Réaffiche le menu du bas
            }
            break;
            
            // Met le port série en pause. En fait on l'arrête, on 
            // met une alerte et quand on clic, on le réactive
            case 2:
              port_serie.clear();
              port_serie.stop();
              JOptionPane.showMessageDialog(null, DEFINE_TEXT_PAUSE_SERIE, DEFINE_TEXT_BOITE, JOptionPane.INFORMATION_MESSAGE);  
              reglage_serie(false);   
              break;
              
           // Change l'affichage des fenêtres
           case 3:
             retour = selection_fenetre();
             if (retour == true)
             {
               affichage_fenetres();
               affichage_menu();
             }
             break;
             
             // Copyright
             case 4:
               JOptionPane.showMessageDialog(null, DEFINE_TEXT_COPYRIGHT, DEFINE_TEXT_BOITE, JOptionPane.INFORMATION_MESSAGE);  
               break;
        }
        return;
      }
    }
    // Clic dans un des menus de fenêtre?
    // Boucle sur les 4 fenêtres
   for (x = 0; x < 4; x++)
    {
      // On cherche l'index de la fenêtre à tester pour voir si elle existe
      int index_draw = tab_idx_fenetre[selected_affichage_fenetre][x];
      
      // On ne taite que les fenêtres avec un index != 100
      if (index_draw != 100)
      {
        // Offset de dépot des boutons pour cette fenêtre
        int offset_x = tab_fenetre_offset_menu[index_draw][0];
        int offset_y = tab_fenetre_offset_menu[index_draw][1];
    
        for (int y=0; y < 3; y++)
        {
         // Nous bouclons sur les 3 boutons de la fenêtre
          pos_x = tab_fenetre_pos_menu[y][0] + offset_x;
          pos_y = tab_fenetre_pos_menu[y][1] + offset_y;
          largeur = tab_fenetre_pos_menu[y][2];
          hauteur = tab_fenetre_pos_menu[y][3];
  
          if(mouseX>pos_x && mouseX<pos_x+largeur && mouseY>pos_y && mouseY<pos_y+hauteur)
          {
              // L'action dépend du bouton
              switch (y)
              {
                // Activation ou désactivation affichage date
                 case 0: 
                    tab_fenetre_etat[x][0] = (tab_fenetre_etat[x][0] == 0) ? 1:0;
                    affiche_fenetre(index_draw,x,false);   
                    break;
                 
                // Activation ou désactivation du scroll
                case 1:
                  tab_fenetre_etat[x][1] = (tab_fenetre_etat[x][1] == 0) ? 1:0;
                  affiche_fenetre(index_draw,x,false); 
                break;
                
                // Effacement de la fenêtre. On la réaffiche completement
                case 2:
                  affiche_fenetre(index_draw,x,true); 
                break;
              }
              return;         
          }
      }
    }
  }
}
//-----------------------------------------------------------------------------------------------
