### 2023-03-09 

* Création de la feuille dans KiCAD pour la **version 2** qui n'utilise pas de cristal externe mais plutôt le signal **TMCO** de 8Mhz en provenance du ST-LINK. 

* Modification de [metal-detector.bas](metal-detector.bas) pour tenir compte de la dernière réversion de [STM8_TBI](https://github.com/picatout/stm8_tbi) qui ajoute les commandes **CLK_HSE** et **CLK_HSI** pour faire la commutation entre l'oscillateur  interne et l'oscillateur externe.

### 2023-03-08 

* [metal-detector.bas](metal-detector.bas) Révision 3
    * Modifié la constante  **SENSIVITY**  de **4** à **2** pour amélliorer la sensibilité. 
    * Ajout de la constante **DEBUG** et modifié le code pour n'interagir avec le terminal lorsque **DEBUG=1**
    * Sauvegarder le programme en flash 
    * Utililsé la commande **AUTORUN DETECTOR** pour exécuter le programme lors de la mise sous tension du détecteur.
    
### 2023-03-07

* Version 1 révision 2
    * Changement au circuit ainsi qu'au programme [metal-detector.bas](metal-detector.bas)


### 2023-03-03

* Mise à jour du [readme.md](readme.md)

* Création du dépot sur [https://github.com/picatout/metal-pointer](https://github.com/picatout/metal-pointer)

* Modification du circuit pour ajouter un cristal de 12Mhz pour la carte NUCLEO-S207K8

* Création du programme [clk-switch.bas](clk-switch.bas) qui permet de commuter de la carte NUCLEO 
de l'oscillateur interne **HSI** au cristal 12Mhz **HSE**. 

* Mise à jour du programme [metal-detector.bas](metal-detector.bas) pour fonctionner avec le cristal 
externe au lieu de l'oscillateur interne.

* Mise à jour du fichier []()

### 2023-03-02

* Ajout du programme [tunig.bas](tuning.bas)

### 2023-03-01

* Remplacement de stm8_eforth par stm8_tbi sur la carte NUCLEO-S207K8

* Création du fichier [metal-detector.bas](metal-detector.bas)

### 2023-02-20

* Création du projet 

* Installation de stm8_eforth sur la carte NUCLEO-S207K8 

