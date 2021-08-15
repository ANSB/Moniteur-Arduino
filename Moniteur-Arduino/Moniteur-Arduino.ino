//===================================================================
// Exemple d'usage du Moniteur PDE (Processing)
//===================================================================

int compteur = 0;
void setup() 
{
	// La vitesse doit aussi être réglée sur le Moniteur
	Serial.begin(9600); 
}

// Les commandes
// Les valeurs des commandes sont définies dans le code Processing
// Par défaut:
// OPCODE_START = "&";  // Marque de début de commande
// OPCODE_EFFACEMENT = "E";  // Effacement de la fenêtre
// OPCODE_TITRE = "T";  // Changement de titre de la fenêtre
// OPCODE_AFFICHAGE = "A";  // Sélection de la fenêtre d'affichage

// Exemples:
// &T2Essai -> met "Essai" comme titre de la fenêtre 2
// &E3 -> efface la fenêtre 3
// &A4Hello-> Affiche Hello dans le fenêtre 4
// Note: une fois qu'une commande d'affichage a été reçu, les messages envoyés
// sans opcode continue à être affichés dans la même fenêtre. Donc si on envoi
// "&A2Hello" puis "Les amis", les deux messages seront affichés dans la fenêtre 2.

void loop()
{
	for (int x = 0; x < 10; x++)
	{
		Serial.println("&A1Message fenêtre 1 avec un texte très long qui va surement dépasser en largeur sur cette fenêtre");
		delay (500);
		Serial.println("Toujours dans la fenêtre 1 avec un texte très long qui va surement dépasser en largeur sur cette fenêtre");
		delay (200);
	
		Serial.println("&A2Message fenêtre 2");
		delay (500);

		Serial.println("&A3Message fenêtre 3");
		delay (200);

		Serial.println("&A4Message fenêtre 4");
		Serial.println("Toujours dans la fenêtre 4 avec un texte très long qui va surement dépasser en largeur sur cette fenêtre");

		delay (200);

	}	
	Serial.println("&E4");
	
	compteur = (compteur == 0)? 1 : 0;
	if (compteur == 0)
	{
		Serial.println("&T4Nouveau titre");
	}
	else
	{
		Serial.println("&T4Changement de titre");
	}
}
