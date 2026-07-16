# Démarrage — pour quelqu'un qui n'a jamais fait ça

Ce guide suppose que tu n'as jamais installé d'outil comme celui-ci, que
tu ne sais pas ce qu'est un `.exe` "non signé" ou un fichier `.ini`, et
que tu veux juste que ça marche. Aucune de ces suppositions n'est un
problème — suis les étapes dans l'ordre.

## Étape 1 — Télécharger

1. Va sur la page **Releases** du projet sur GitHub.
2. Trouve la version la plus récente (en haut de la liste).
3. Clique sur le fichier qui ressemble à `dd-toolkit-vX.Y.Z.zip` pour le
   télécharger (X.Y.Z sera un numéro comme `0.2.0`).

## Étape 2 — Extraire le zip

Windows n'exécute pas un programme directement depuis un zip.

1. Une fois téléchargé, fais un clic droit sur le fichier `.zip`.
2. Choisis **Extraire tout...**.
3. Choisis un dossier facile à retrouver (ton Bureau, par exemple), puis
   clique sur **Extraire**.
4. Ouvre le dossier qui vient d'apparaître — tu dois voir plusieurs
   fichiers `.exe` et un fichier `settings.ini`. **Garde-les tous dans le
   même dossier** : les `.exe` ont besoin de `settings.ini` à côté d'eux.

## Étape 3 — Lancer le programme

Double-clique sur **`DDToolkit.exe`** (pas les autres — celui-là regroupe
tout : les autres `.exe` du dossier sont des versions "une seule macro à
la fois" pour qui préfère, tu peux les ignorer pour l'instant).

### "Windows a protégé votre PC"

Un écran bleu peut apparaître avec ce message. C'est normal et attendu —
ça arrive à **tout** programme qui n'a pas payé une licence de signature
numérique (plusieurs centaines d'euros par an), ce qui est le cas de la
quasi-totalité des petits outils gratuits comme celui-ci, y compris des
outils très populaires et sans danger.

1. Clique sur **Informations complémentaires**.
2. Clique sur **Exécuter quand même**.

Le code source complet est public sur GitHub — n'importe qui peut le lire
avant de l'exécuter, ce qui n'est pas le cas d'un logiciel fermé.

### Ton antivirus proteste

Certains antivirus (et Windows Defender) signalent parfois les outils
AutoHotkey comme suspects, parce qu'ils envoient des touches clavier/clics
de façon automatisée — exactement le même comportement technique qu'un
outil malveillant, même quand (comme ici) c'est fait pour une raison
légitime et documentée. C'est un faux positif connu et fréquent dans toute
la communauté AutoHotkey, pas un signe que ce programme-ci pose problème.
Autorise le fichier si ton antivirus te le demande.

### (Optionnel) Un raccourci sur le Bureau

Si tu préfères ne pas rouvrir le dossier à chaque fois, double-clique sur
**`Setup.exe`** une fois : il crée un raccourci "DD Toolkit" sur ton
Bureau, et peut lancer DD Toolkit automatiquement à chaque démarrage de
Windows si tu coches la case proposée. Entièrement facultatif — tout
fonctionne pareil sans, et ça ne modifie rien d'autre sur ta machine (pas
de service, pas de registre).

Si `Setup.exe` détecte qu'AutoHotkey v2 n'est pas installé, il propose un
bouton pour l'installer automatiquement. **Ce n'est utile que si tu veux
un jour modifier ou lancer directement les scripts sources (`.ahk`)** —
les `.exe` de ce dossier fonctionnent déjà seuls, sans rien installer.
Si tu cliques, tu confirmes une fois, puis tout se fait tout seul
(téléchargement depuis la source officielle, installation silencieuse
pour ton compte uniquement — pas besoin d'être administrateur).

## Étape 4 — L'icône dans la barre des tâches

Une fois lancé, le programme ne s'ouvre pas dans une fenêtre : il vit dans
la **zone de notification**, en bas à droite de l'écran (la petite flèche
`^` à côté de l'horloge — clique dessus si tu ne vois pas l'icône
directement).

- **Un clic** sur l'icône ouvre la fenêtre de réglages.
- **Clic droit** sur l'icône ouvre un petit menu : Réglages, Recharger,
  Quitter.

## Étape 5 — Régler les macros

Dans la fenêtre de réglages, un onglet par macro (AutoAbility,
TowerStacking, AutoClicker, AbilityWheel, ChargeShot) :

- Chaque onglet a sa propre case **Activé** — décoche celles que tu ne
  veux pas utiliser.
- Pour changer une touche, clique dans le champ correspondant et appuie
  directement sur la touche que tu veux (pas besoin de taper son nom).
- Clique sur **Enregistrer** : le programme redémarre tout seul pour
  appliquer les changements (ça prend une seconde, c'est normal).

L'onglet **"Correctifs jeu"** est différent des autres : il ne règle pas
une macro, il corrige un problème connu du jeu lui-même (textures
floues). Voir [docs/CORRECTIFS-JEU.md](CORRECTIFS-JEU.md) pour le détail
— une sauvegarde du fichier du jeu est toujours créée avant modification.

## Étape 6 — Jouer

Lance Dungeon Defenders Redux. Les macros ne font quoi que ce soit que
lorsque le jeu est la fenêtre au premier plan — impossible d'envoyer une
touche par accident ailleurs (dans le chat, Discord, ton navigateur...).

## Pour quitter complètement

Clic droit sur l'icône dans la zone de notification → **Quitter**.

## Ça ne marche pas / questions fréquentes

**Rien ne se passe quand j'appuie sur la touche en jeu.**
Vérifie que le jeu est bien la fenêtre active (cliquée, au premier plan),
et que la macro concernée est cochée **Activé** dans les réglages.

**Je ne vois pas l'icône dans la zone de notification.**
Clique sur la petite flèche `^` à côté de l'heure, en bas à droite — elle
peut être cachée dans les icônes "masquées". Tu peux l'épingler pour
qu'elle reste toujours visible (glisser-déposer dans Windows).

**J'ai fermé la fenêtre de réglages par erreur, comment je la rouvre ?**
Un clic sur l'icône dans la zone de notification.

**Je veux tout désinstaller.**
Quitte le programme (voir plus haut), puis supprime simplement le dossier
où tu as extrait le zip. Si tu as utilisé `Setup.exe`, supprime aussi le
raccourci "DD Toolkit" sur ton Bureau (et, si coché, celui dans le dossier
Démarrage). Rien d'autre n'est installé sur ta machine (pas de service
Windows, pas d'entrée dans le Panneau de configuration, pas de
modification du registre).
**Exception** : si tu as utilisé le correctif de textures (onglet
"Correctifs jeu"), ça modifie un fichier du jeu qui reste modifié même
après avoir supprimé ce dossier — une sauvegarde de l'original est créée
à côté au moment du correctif si tu veux revenir en arrière (voir
[docs/CORRECTIFS-JEU.md](CORRECTIFS-JEU.md)).

**J'ai plusieurs questions plus techniques / je veux modifier le
comportement.**
Voir le [README](../README.md) principal du projet.
