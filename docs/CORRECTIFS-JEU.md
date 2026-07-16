# Correctifs connus pour Dungeon Defenders Redux

Ce document couvre des problèmes du jeu **lui-même** — pas de nos macros
— documentés publiquement (PCGamingWiki, guides Steam, support officiel
Chromatic Games). Modifier un fichier du jeu est une catégorie de risque
différente de nos macros : fermer un script AHK ne défait rien, alors
qu'un fichier modifié reste modifié après coup. D'où la règle suivie
partout ici : **toujours sauvegarder avant d'écrire, ne jamais deviner
une structure non vérifiée.**

## Textures floues (streaming trop agressif) — automatisé

**Symptôme** : textures/modèles flous qui ne se raffinent jamais,
indépendamment des réglages graphiques en jeu.

**Cause documentée** : Redux ne configure pas une taille de pool de
streaming de texture suffisante par défaut, sur toutes les versions
PC/Steam.

**Sources** :
- [Steam Community Guide — Blurry Textures Fix/VRAM Limit fix](https://steamcommunity.com/sharedfiles/filedetails/?id=2326716378)
- [GamePretty — How to Fix Blurry Textures & VRAM Limit](https://gamepretty.com/dungeon-defenders-how-to-fix-blurry-textures-vram-limit/)
- [PCGamingWiki — Dungeon Defenders](https://www.pcgamingwiki.com/wiki/Dungeon_Defenders)

**Ce que fait notre outil** (`GameTweaks.ahk`, ou l'onglet "Correctifs
jeu" de DDToolkit) : détecte automatiquement ton dossier d'installation
(via le registre Steam — aucune saisie si le jeu est dans la bibliothèque
Steam par défaut ; sélection manuelle seulement si l'auto-détection
échoue), cherche les lignes `PoolSize=`, `PoolSizeLow=`,
`PoolSizeMedium=`, `PoolSizeHigh=` dans `UDKGame\Config\UDKEngine.ini` et
les remplace par des valeurs plus élevées (1536/768/1536/3072, ou
1024/512/1024/2048 en cochant "moins de 3 Go de VRAM"). Une sauvegarde
horodatée (`UDKEngine.ini.dd-toolkit-backup-AAAAMMJJ-HHMMSS`) est créée
avant toute écriture.

**Vérifié sur une vraie installation** (pas juste en théorie) : la
section est bien `[TextureStreaming]` et contenait, sur l'installation
Steam testée, `PoolSize=256`, `PoolSizeLow=256`, `PoolSizeMedium=384`,
`PoolSizeHigh=512` — la recherche de ligne les a trouvées et remplacées
correctement (1536/768/1536/3072), sans toucher à `CommonAudioPoolSize`
(un réglage audio sans rapport qui contient "PoolSize" en sous-chaîne).
Testé sur une copie du fichier, jamais sur l'original.

**Pourquoi une recherche de ligne plutôt qu'une section ini ciblée** :
même si le nom de section est maintenant confirmé, chercher directement
les lignes `Cle=Nombre` reste plus robuste qu'un `IniWrite` ciblé — ça ne
dépend pas de la structure exacte du fichier (ordre des sections,
variantes entre versions du jeu). Si aucune ligne n'est trouvée,
**rien n'est modifié** et un message te le signale — jamais d'écriture
"au cas où".

**Pour revenir en arrière** : renomme le fichier de sauvegarde en
`UDKEngine.ini` (en écrasant la version modifiée).

**Limite connue** : les mises à jour du jeu peuvent réinitialiser ce
fichier. Passe-le en lecture seule après coup si tu veux éviter d'avoir à
réappliquer le correctif (clic droit sur `UDKEngine.ini` → Propriétés →
coche "Lecture seule").

## Tearing d'écran (V-Sync) — automatisé, optionnel

**Symptôme** : déchirures visuelles horizontales pendant les mouvements de caméra.

**Cause documentée** : `UseVsync=False` par défaut dans `UDKEngine.ini`.

**Source** : [Steam Community — discussion "Any more graphic options in the full game?"](https://steamcommunity.com/app/65800/discussions/0/846956740726596855/) (section `[SystemSettings]`, clé `UseVsync`).

**Ce que fait notre outil** : contrairement au correctif textures (un vrai bug sans contrepartie), activer la V-Sync est une **préférence** — ça supprime le tearing mais ajoute un peu de latence d'entrée, comme dans la plupart des jeux. C'est pour ça que c'est une case à cocher (décochée par défaut), pas un correctif automatique. Onglet "Correctifs jeu" de DDToolkit, ou `GameTweaks.ahk` : cherche la ligne `UseVsync=` n'importe où dans `UDKEngine.ini` et la remplace par `True` ou `False` selon la case cochée. Même sauvegarde horodatée que le correctif textures avant toute écriture.

**Vérifié sur une vraie installation** : la ligne `UseVsync=False` a été retrouvée telle quelle, une seule fois, dans la section `[SystemSettings]` du `UDKEngine.ini` de l'installation Steam testée.

## Performances (ombres, occlusion ambiante, bloom, LOD) — automatisé, optionnel

**Symptôme** : FPS bas, en particulier avec les ombres dynamiques et l'occlusion ambiante activées.

**Source** : [collection de tweaks UDKEngine.ini partagée sur r/dungeondefenders](https://www.reddit.com/r/dungeondefenders/comments/o7cj9/tip_collection_of_udkengineini_tweaks_that_might/) — l'auteur rapporte un passage de ~30 à 60 FPS avec les deux premiers réglages seuls (V-Sync activée).

**Ce que fait notre outil** : comme la V-Sync, c'est une **préférence** (qualité visuelle contre FPS), donc un bouton, pas un correctif automatique. Cherche puis remplace, n'importe où dans `UDKEngine.ini` :

| Clé | Valeur appliquée |
| --- | --- |
| `DetailMode` | `0` |
| `GraphicsQualityMode` | `0` |
| `DynamicShadows` | `False` |
| `AmbientOcclusion` | `False` |
| `UseHighQualityBloom` | `False` |
| `SkeletalMeshLODBias` | `1` |
| `ParticleLODBias` | `2` |
| `MaxAnisotropy` | `1` |
| `MaxMultisamples` | `1` |

Ces deux premiers réglages (`DetailMode`, `GraphicsQualityMode`) sont ceux cités par la source comme ayant le plus d'impact — entre autres, ils retirent le cel-shading (contours façon dessin animé) et baissent la qualité des auras du Monk, sans repasser tout le jeu en qualité "Basse". Les autres ont un effet individuellement plus faible mais s'additionnent.

**Vérifié sur une vraie installation** : les 9 clés ont été retrouvées telles quelles, chacune une seule fois, toutes dans la section `[SystemSettings]` du `UDKEngine.ini` de l'installation Steam testée (valeurs trouvées : `DetailMode=2`, `GraphicsQualityMode=2`, `DynamicShadows=True`, `AmbientOcclusion=True`, `UseHighQualityBloom=True`, `SkeletalMeshLODBias=0`, `ParticleLODBias=0`, `MaxAnisotropy=8`, `MaxMultisamples=1`).

**Non automatisé — désactivation du Triple Buffering** : la même source recommande de désactiver le Triple Buffering (avec V-Sync activée) pour réduire les plantages, notamment en mode fenêtré ou à l'alt-tab. Aucun nom de clé exact n'est donné dans la source, et **aucune clé contenant "TripleBuffer" n'a été trouvée** dans le `UDKEngine.ini` réel testé cette session — donc rien à chercher/remplacer de façon fiable. Si tu trouves le nom de clé réel (avec source), ouvre une PR.

**Limite connue** (comme pour les textures et la V-Sync) : une mise à jour du jeu peut réinitialiser ces valeurs — voir la note "Lecture seule" plus haut.

## Écran noir / plantage au lancement — non automatisé, documenté ici

**Symptôme** : écran noir après avoir cliqué sur Jouer, ou le jeu ne se
lance pas du tout.

**Cause/fix documentés** :
- Ajoute `-nolauncher` aux options de lancement Steam (clic droit sur le
  jeu dans Steam → Propriétés → Options de lancement).
- Un correctif communautaire "No_Launcher" existe (fichiers à placer dans
  `Binaries\Win32`, lancés via un `.bat`).
- Désactive temporairement pare-feu/VPN/antivirus si le jeu reste bloqué
  au lancement (peut interférer avec l'établissement de connexion).

**Source** : [support officiel Chromatic Games](https://support.chromatic.games/hc/en-us/articles/203709410-My-game-won-t-launch),
[forum officiel DD](https://forums.dungeondefenders.com/forums/topic/147464-black-screen-after-clicking-play/).

**Pourquoi ce n'est pas automatisé** : `-nolauncher` est une option de
lancement **Steam**, stockée dans la configuration du client Steam
(`localconfig.vdf`), pas un fichier du jeu — une modification plus
profonde et moins vérifiable dans le cadre de ce repo que l'édition d'un
seul fichier ini du jeu. Le correctif "No_Launcher" implique de
remplacer des fichiers exécutables, encore un cran plus invasif. Les deux
sont documentés ici pour que tu les appliques toi-même en connaissance de
cause plutôt qu'automatisés à l'aveugle.

## Ce qu'on ne couvre pas (hors périmètre pour l'instant)

D'autres soucis existent (FOV, ultrawide, DirectX manquant à
l'installation...) mais les sources trouvées pendant cette recherche
reposaient sur des captures d'écran plutôt que du texte exploitable, donc
rien de assez solide à automatiser ou même documenter précisément ici. Si
tu as un fix vérifié (avec source), ouvre une PR — voir
[CONTRIBUTING.md](../CONTRIBUTING.md).
