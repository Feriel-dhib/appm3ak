# Modèle de détection d'obstacles – explication

Ce document explique **pourquoi** l’écran « Détection d’obstacles » affiche « Modèle manquant » et **comment** corriger.

---

## Pourquoi ce message ?

L’écran **Détection d’obstacles** utilise un **modèle de machine learning** (YOLOv8) pour détecter les objets devant la caméra. Ce modèle est fourni sous forme d’un **fichier** que l’app charge au démarrage de l’écran.

- Ce fichier **n’est pas inclus** dans le dépôt du projet (il est lourd et souvent généré côté Python).
- S’il est **absent**, l’app ne peut pas charger le modèle et affiche :  
  **« Modèle manquant… m3ak_yolov8.tflite »**

Donc : le message n’est **pas un bug**, c’est une **étape de configuration** à faire une fois sur votre machine.

---

## Que faire en bref ?

1. **Obtenir** le fichier `m3ak_yolov8.tflite` (export `export_ma3ak_tflite.py` du dépôt obstacle-detection-assistant, ou équivalent Ultralytics).
2. **Le placer** dans le dossier **`assets/models/`** du projet, à la racine du repo appm3ak.
3. **Relancer** l’app (`flutter run` ou Run dans l’IDE).

Dès que le fichier est au bon endroit et que vous avez relancé l’app, l’écran peut charger le modèle et la détection fonctionne.

---

## Instructions détaillées

Tout est décrit pas à pas dans :

**`assets/models/README.md`**

Vous y trouverez :
- ce qu’est le fichier et pourquoi il est nécessaire ;
- **option A** : export depuis un projet Python existant (ex. obstacle-detection-assistant) ;
- **option B** : export depuis zéro avec Ultralytics (YOLOv8) ;
- où mettre le fichier exactement et comment vérifier ;
- qu’il faut relancer l’app après avoir ajouté le fichier.

Ouvrez ce fichier pour la procédure complète.
