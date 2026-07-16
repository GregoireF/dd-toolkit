# DD Toolkit

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2.0-green.svg)
[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)

> Remplace `OWNER/REPO` ci-dessus par le chemin réel une fois le repo
> poussé sur GitHub — le badge CI ne peut pas se résoudre avant.

Boîte à outils AutoHotkey v2 pour Dungeon Defenders Redux : macros de
gameplay (relance d'ability, tower stacking, autoclicker, roue Jester,
charge shot) et un correctif connu du jeu lui-même (textures floues),
remplaçant l'ancien `Auto E.ahk` (v1) et le binaire compilé
`DDTurretStack.ahk.exe` dont le source était perdu. Pensé pour être facile
à auditer, à retester et à étendre — voir [CONTRIBUTING.md](CONTRIBUTING.md).

**Jamais utilisé d'outil comme celui-ci ?** Va directement au guide
[docs/DEMARRAGE.md](docs/DEMARRAGE.md) — zéro prérequis technique,
pas-à-pas avec captures de situations (SmartScreen, antivirus...).

**Tu sais ce que tu fais ?** `DDToolkit.exe` regroupe toutes les macros
dans une seule appli avec icône en zone de notification et fenêtre de
réglages à onglets (pas besoin de toucher `settings.ini` à la main) ; les
`.exe` individuels (`AutoAbility`, `TowerStacking`, `AutoClicker`,
`AbilityWheel`, `ChargeShot`, `GameTweaks`) restent disponibles
séparément pour qui préfère n'en lancer qu'un, sans le reste.
`Setup.exe` (optionnel) crée un raccourci Bureau / démarrage Windows.

## Pourquoi AHK v2 et pas autre chose

Le tower stacking exige un timing quasi frame-perfect entre deux touches.
AutoHotkey (hooks clavier bas niveau + `SendInput`) reste, en 2026, la
solution la plus fiable pour ça sous Windows — plus fiable qu'un
interpréteur Python (pynput/pyautogui) qui ajoute de la latence/jitter, et
sans commune mesure avec des outils no-code (Power Automate Desktop, etc.)
qui ne descendent pas à ce niveau de précision. v1 (1.1.x) est en
maintenance minimale ; **v2.0.x est la version stable activement
développée** (v2.1 reste en alpha à ce jour), donc tout le nouveau code
cible v2. v1 et v2 coexistent sans conflit sur la même machine.

## Structure

```
AGENTS.md                      Guide pour agents IA (agent-agnostique)
CLAUDE.md                      Addendum spécifique Claude Code (pointe vers AGENTS.md)
BRANCHING.md                   Stratégie de branches et flux de PR
.github/workflows/ci.yml       CI : smoke-test + build sur windows-latest (chaque push/PR)
.github/workflows/release.yml  Release : build + GitHub Release avec .exe attachés (sur tag vX.Y.Z)
.github/workflows/commitlint.yml  Lint des messages de commit sur chaque PR
.github/dependabot.yml         Mises à jour auto des actions GitHub utilisées en CI
.github/ISSUE_TEMPLATE/        Templates de bug report / feature request
.githooks/pre-commit           Hook local : smoke-test avant chaque commit touchant src/
.githooks/commit-msg           Hook local : lint du message de commit (commitlint)
docs/DEMARRAGE.md              Guide d'installation zéro-prérequis
docs/CORRECTIFS-JEU.md         Correctifs connus du jeu lui-même (textures, écran noir), sources incluses
config/settings.ini            Réglages utilisateur (touches, intervalles, process du jeu)
src/Lib/Common.ahk             Helpers partagés (lecture/écriture config, scoping fenêtre, notifs)
src/Lib/Modules/*.ahk          La logique de chaque macro, en classe réutilisable (voir § Architecture)
src/DDToolkit.ahk              App unifiée : icône zone de notification + fenêtre de réglages à onglets
src/Setup.ahk                  Installeur optionnel : raccourci Bureau / démarrage Windows
src/AutoAbility.ahk            Point d'entrée standalone : relance générique d'ability/piège en cooldown
src/TowerStacking.ahk          Point d'entrée standalone : tower stacking (Ctrl+1..0 + Espace)
src/AutoClicker.ahk            Point d'entrée standalone : turbo-fire clic gauche/droit
src/AbilityWheel.ahk           Point d'entrée standalone : roue Jester (Wheel of Fortune)
src/ChargeShot.ahk             Point d'entrée standalone : tir chargé à durée constante
src/GameTweaks.ahk             Point d'entrée standalone : applique le correctif de textures
templates/NewMacro.ahk.example Point de départ pour une nouvelle macro (module + wrapper)
scripts/Install-Hooks.ps1      Active les hooks git versionnés (une fois par clone)
scripts/Bump-Version.ps1       Bump VERSION + Ahk2Exe + CHANGELOG en une commande
build/Build-All.ps1            Compile src/*.ahk en .exe portables (dist/, non versionné)
tests/Test-Syntax.ps1          Smoke-test : vérifie que chaque script charge sans erreur
commitlint.config.js           Règles de commit (Conventional Commits + gitmoji) + config cz-git
package.json                   Tooling Node dev-only (commitlint, cz-git) — pas requis pour utiliser les macros
VERSION                        Version courante (SemVer)
```

## Prérequis

- [AutoHotkey v2](https://www.autohotkey.com/) installé (coexiste avec une
  éventuelle v1 déjà présente) — pour lancer/compiler les macros.
- [Node.js](https://nodejs.org/) 20+ — optionnel, seulement pour
  `npm run commit` (prompt de commit interactif) ou lancer `commitlint` en
  local ; jamais requis pour utiliser les macros elles-mêmes.

## Architecture

Chaque macro existe en un seul exemplaire de logique, dans
`src/Lib/Modules/*.ahk` (une classe avec un `Init()` qui lit
`config/settings.ini`, enregistre les hotkeys, et un `StatusText()` pour
l'affichage). Deux façons de la lancer, qui partagent exactement le même
code :

- **`src/DDToolkit.ahk`** — charge tous les modules dans un seul
  processus, avec une icône en zone de notification (menu : Réglages /
  Corriger les textures / Recharger / Quitter) et une fenêtre de réglages
  à onglets (`Tab3`) qui écrit dans `settings.ini` puis relance
  (`Reload()`). C'est l'entrée recommandée, et la seule qui a besoin d'un
  guide dédié ([docs/DEMARRAGE.md](docs/DEMARRAGE.md)).
- **`src/AutoAbility.ahk`, `TowerStacking.ahk`, `AutoClicker.ahk`,
  `AbilityWheel.ahk`, `ChargeShot.ahk`, `GameTweaks.ahk`** — de fins
  wrappers qui démarrent un seul module. Utile pour qui veut un seul
  outil sans le reste, ou pour la CI/les tests (chaque module reste
  indépendamment compilable et testable).
- **`src/Setup.ahk`** — n'est pas un module, juste un utilitaire
  ponctuel : crée un raccourci et éventuellement une entrée de démarrage
  Windows pointant vers `DDToolkit.exe`. Si AutoHotkey v2 n'est pas
  détecté sur la machine, propose (bouton, jamais automatique sans clic)
  de le télécharger et l'installer silencieusement — utile uniquement
  pour qui veut modifier/lancer les scripts sources, pas pour utiliser
  les `.exe` (déjà autonomes).

Chaque module a un flag `Enabled` dans son ini (activable aussi bien
depuis `settings.ini` à la main que depuis la fenêtre de réglages de
DDToolkit) — le désactiver n'enregistre tout simplement aucun hotkey pour
ce module.

## Utilisation

1. **Zéro prérequis technique ?** Suis
   [docs/DEMARRAGE.md](docs/DEMARRAGE.md) — télécharge le zip de la
   dernière Release, lance `DDToolkit.exe`, tout se règle depuis son
   icône en zone de notification.
2. **À l'aise avec un fichier `.ini` ?** Ajuste `config/settings.ini`
   directement (touche d'ability, intervalle, nom du process si ton
   launcher diffère de `DunDefGame.exe`), puis double-clique sur
   `DDToolkit.ahk` ou l'un des scripts individuels dans `src/` pour le
   lancer directement, ou compile d'abord (§ Build).
3. Tout ce qui envoie des touches ne réagit que quand Dungeon Defenders
   est au premier plan — aucun risque de fuite de touche vers le
   chat/Discord/le navigateur si tu alt-tab (sauf `AutoClicker` avec
   `ScopeToGame=false`, explicitement voulu pour un usage généraliste).

### AutoAbility.ahk
- `F2` (configurable) : arme/désarme la boucle — un bip aigu/grave confirme
  l'état sans avoir à regarder l'écran.
- `F3` (configurable) : arrêt d'urgence, coupe le timer même si l'état
  interne est désynchronisé.

### TowerStacking.ahk
- `Ctrl+1` .. `Ctrl+0` : place la tour du slot correspondant en la stackant
  sur ce qui est déjà présent (touche + Espace quasi simultanés).
- Ne fonctionne que sur les défenses à collision (Apprentice/Squire/Jester,
  SAM Units, minions) ; il faut être host du lobby. Voir la
  [page wiki Tower Stacking](https://dungeondefenders.wiki.gg/wiki/Tower_Stacking).

### AutoClicker.ahk
- `CapsLock` (configurable) arme/désarme le turbo-fire du clic gauche,
  `F6` (configurable) celui du clic droit — indépendants l'un de l'autre.
  Une fois armé, il faut quand même maintenir le bouton physiquement
  appuyé : il turbo-fire tant qu'il est maintenu, rien ne se déclenche
  tout seul.
- `ScopeToGame=true` (par défaut) dans `settings.ini` : n'agit que quand
  Dungeon Defenders est au premier plan. Passe à `false` pour un
  autoclicker généraliste, actif dans n'importe quelle fenêtre.

### AbilityWheel.ahk
- Automatise la roue Jester (Wheel of Fortune) : ouvre la roue, détecte la
  couleur de chaque slot par analyse de pixels, verrouille les 3 dans
  l'ordre. Chaque combinaison (`Spin.*`) et chaque couleur sont définies
  dans `config/settings.ini` — pas besoin de toucher au code pour en
  ajouter ou en retirer.
- **Non revérifié en jeu** dans le cadre de cette réécriture (voir
  `CLAUDE.md`) : la formule de détection est reprise telle quelle d'une
  source communautaire, mais si les couleurs ne matchent pas chez toi
  (calibration moniteur/HDR), ajuste `[AbilityWheelColors]` ou
  `ToleranceRGB`.

### ChargeShot.ahk
- `Ctrl+Espace` (configurable) : maintient le bouton d'attaque appuyé
  pendant une durée configurable (500ms par défaut) puis le relâche
  automatiquement — un tir à charge constante et reproductible au lieu de
  chronométrer une pression à l'oreille. Le wiki DD cite ~70% de charge
  comme bon repère pour les bâtons d'Apprentice ; la durée exacte dépend
  de la vitesse de charge de ton arme du moment, à ajuster toi-même.

### GameTweaks.ahk
- Corrige les textures floues connues de Redux en modifiant
  `UDKEngine.ini` (sauvegarde automatique avant écriture). Détecte le
  dossier d'installation tout seul via le registre Steam — aucune saisie
  requise si le jeu est dans la bibliothèque Steam par défaut ; ne
  demande de choisir le dossier que si l'auto-détection échoue (jeu sur
  une bibliothèque Steam secondaire, copie non-Steam...). Vérifié sur une
  vraie installation, pas seulement en théorie — voir
  [docs/CORRECTIFS-JEU.md](docs/CORRECTIFS-JEU.md) pour le détail, les
  sources, et pourquoi certains autres correctifs connus (écran noir au
  lancement) sont documentés plutôt qu'automatisés.

## Build (.exe portable)

Nécessite le compilateur fourni avec AutoHotkey v2 :

```powershell
.\build\Build-All.ps1
# ou, si Node est installé :
npm run build
```

Génère un `.exe` par script dans `dist/` (ignoré par git — ce sont des
artefacts de build, pas du code source), avec nom/description/version
embarqués (directives `;@Ahk2Exe-Set*` en tête de chaque script) — contrairement
à l'ancien `DDTurretStack.ahk.exe`, qui n'en avait aucun. `settings.ini` est
copié à côté des `.exe` dans `dist/` : `DD.ConfigPath` (`src/Lib/Common.ahk`)
cherche d'abord dans le dossier du script/exe lui-même avant de retomber sur
la disposition `src/`↔`config/` du repo — un `.exe` téléchargé seul (voir
§ Releases) reste donc autonome sans checkout du repo.

## Tests

```powershell
.\tests\Test-Syntax.ps1
# ou :
npm test
```

C'est un smoke-test de chargement (syntaxe/erreurs au démarrage), **pas**
un test fonctionnel — personne ne peut automatiser "est-ce que la tour
s'est bien stackée en jeu" sans lancer Dungeon Defenders. Teste toujours
manuellement en jeu après une modification. La CI relance ce même test
(et le build) sur `windows-latest` à chaque push/PR, et `commitlint.yml`
vérifie en plus que chaque commit d'une PR respecte le format défini dans
`commitlint.config.js`. Les hooks locaux (`.\scripts\Install-Hooks.ps1`)
font la même vérification avant que le commit ne parte.

## Releases (.exe téléchargeables, sans build manuel)

```powershell
.\scripts\Bump-Version.ps1 -Version 0.2.0
git add -A && git commit -m "chore(release): v0.2.0"
git tag v0.2.0
git push && git push --tags
```

Pousser le tag déclenche `.github/workflows/release.yml` : build des
`.exe`, publication automatique sur une GitHub Release (les `.exe`
individuels **et** un zip combiné `dd-toolkit-vX.Y.Z.zip` contenant tout +
`settings.ini`, prêt à décompresser et lancer sans rien d'autre), notes
générées depuis la section correspondante de `CHANGELOG.md`. Aucun binaire
n'est jamais commité dans l'historique git.

## Idées explorées, délibérément pas retenues

En creusant [le guide Steam d'automatisations DD](https://steamcommunity.com/sharedfiles/filedetails/?id=477701363)
et le [wiki DD Life Hacks](https://dungeondefenders.wiki.gg/wiki/DD_Life_Hacks)
pour trois autres macros candidates, la recherche a changé la conclusion —
notée ici pour ne pas la reperdre et ne pas les re-proposer sans relire
ceci d'abord :

- **Minion Line Placement / Overlord Summon** — abandonné. Le wiki DD est
  explicite : *"For Redux, there is no timer for minion collision"* —
  contrairement à l'original ou à *Dungeon Defenders: Awakened* (un jeu
  différent, moteur différent), Redux a supprimé la contrainte de timing
  qui rendait un macro utile ici. Un placement manuel suffit.
- **Aura/Trap Stacking** — abandonné. Toujours le wiki DD : un "Aura
  Stack" est la superposition de 2-3 auras **différentes** (pas la même
  aura plusieurs fois), et les auras n'ont pas de collision entre elles —
  pas besoin du combo Espace+touche frame-perfect du tower stacking, ça
  marche déjà en posant normalement.
- **Upgrade Automation** — abandonné. Le jeu a un **"Pro Mode"** intégré :
  Shift+clic = 10 upgrades, Ctrl+clic = 50 d'un coup. Un macro externe
  n'ajouterait de valeur que pour une boucle AFK non supervisée — une
  catégorie différente des autres macros de ce repo (assistance de
  précision sur une action ponctuelle, pas du grind automatisé).

`ChargeShot.ahk` est la seule des 4 candidates du guide Steam à avoir
survécu à cette recherche et être implémentée (§ ci-dessus) — mécanique
réelle et documentée, sans solution intégrée au jeu.

## Contribuer

Voir [CONTRIBUTING.md](CONTRIBUTING.md) — setup, conventions de code, style
de commit, et [`templates/NewMacro.ahk.example`](templates/NewMacro.ahk.example)
comme point de départ pour une nouvelle macro. Stratégie de branches/PR :
[BRANCHING.md](BRANCHING.md). Ce projet suit le
[Contributor Covenant](CODE_OF_CONDUCT.md). Tu es un agent IA ? Commence
par [AGENTS.md](AGENTS.md) (Claude Code : [CLAUDE.md](CLAUDE.md) en plus).

## Historique

Voir [CHANGELOG.md](CHANGELOG.md).

## Sécurité

Voir [SECURITY.md](SECURITY.md).

## Licence

[MIT](LICENSE).

## Contexte / mécanique de jeu

Le tower stacking est une technique tolérée par la communauté Dungeon
Defenders, documentée publiquement (wiki officieux, forums, dépôts
GitHub publics) ; probablement non prévue par les développeurs à
l'origine mais largement acceptée dans le coop. Aucun anti-triche
(VAC/EAC) n'intervient sur ces inputs.
