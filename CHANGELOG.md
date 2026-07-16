# Changelog

## Unreleased

## [0.1.0] - 2026-07-16

### Added
- `src/Setup.ahk` détecte l'absence d'AutoHotkey v2 et propose (bouton
  explicite, jamais automatique sans clic) de le télécharger et
  l'installer silencieusement (`/silent`, compte utilisateur, pas besoin
  d'admin) depuis la source officielle GitHub. Testé pour de vrai : le
  téléchargement binaire (WinHttpRequest + ADODB.Stream) a été vérifié
  octet pour octet contre la taille réelle de l'installeur officiel.

### Testé pour de vrai (première fois cette session — pas juste une revue statique)
- AutoHotkey v2 (portable, officiel) a pu être installé temporairement
  dans l'environnement de travail. Les 8 scripts (`src/*.ahk`) ont été
  chargés avec un vrai interpréteur AutoHotkey via `tests/Test-Syntax.ps1`
  — tous OK.
- `DDToolkit.ahk` : la fenêtre de réglages a été réellement ouverte et
  capturée en image — onglets, valeurs pré-remplies (dont le contrôle
  Hotkey qui traduit correctement "CapsLock" en "VERR.MAJ" pour
  l'affichage français), aucun chevauchement. Un incident est survenu
  pendant ce test : un clic simulé mal calculé a atterri sur une autre
  fenêtre déjà ouverte (pas d'impact, immédiatement stoppé et nettoyé) —
  plus aucune simulation de clic/frappe n'est faite dans cet
  environnement sans confirmation explicite.
- `GameTweaksModule` : testé sur une **copie** du vrai `UDKEngine.ini`
  d'une installation Steam de Dungeon Defenders trouvée sur la machine de
  travail (jamais l'original) — la section `[TextureStreaming]` et les
  quatre lignes `PoolSize*` ont été trouvées et corrigées exactement comme
  prévu, sans toucher à `CommonAudioPoolSize` (faux positif potentiel
  écarté). La détection automatique du dossier d'installation (voir
  ci-dessous) a aussi été testée en conditions réelles avec succès.

### Added (recherche de juillet 2026 : voir README § Idées explorées)
- `src/ChargeShot.ahk` + `ChargeShotModule` : maintient le bouton d'attaque
  une durée configurable puis le relâche automatiquement, pour un tir
  chargé reproductible (les bâtons d'Apprentice bénéficient d'une charge
  partielle, ~70% cité comme repère par le wiki DD). Seule des 4 macros
  candidates (guide Steam d'automatisation DD) à avoir été retenue après
  recherche — Minion Line Placement, Aura/Trap Stacking et Upgrade
  Automation ont été explicitement écartées avec justification sourcée
  (README § Idées explorées, délibérément pas retenues).
- `src/GameTweaks.ahk` + `GameTweaksModule` : corrige les textures floues
  connues de Redux en modifiant `UDKGame\Config\UDKEngine.ini`
  (PoolSize/PoolSizeLow/PoolSizeMedium/PoolSizeHigh). Sauvegarde
  horodatée systématique avant écriture ; recherche-et-remplace des
  lignes existantes plutôt qu'`IniWrite` vers une section devinée ;
  abandon propre sans écriture si aucune ligne correspondante n'est
  trouvée. Voir `docs/CORRECTIFS-JEU.md` pour les sources et ce qui n'est
  délibérément *pas* automatisé (option de lancement Steam
  `-nolauncher`).
- `GameTweaksModule.AutoDetectInstallPath()` : trouve le dossier
  d'installation du jeu tout seul via le registre Steam
  (`HKCU\Software\Valve\Steam`) + sa bibliothèque par défaut, sans aucune
  saisie utilisateur si le jeu y est installé. Ne demande de choisir le
  dossier (`DirSelect`) qu'en dernier recours, si l'auto-détection ne
  trouve rien (bibliothèque Steam secondaire, copie non-Steam...).
- `src/Setup.ahk` : installeur optionnel (raccourci Bureau, entrée de
  démarrage Windows facultative) — aucune modification du registre,
  aucun service, désinstallable en supprimant le raccourci.
- `docs/CORRECTIFS-JEU.md` : correctifs connus du jeu, sourcés.
- Fenêtre de réglages de `DDToolkit.ahk` réorganisée en onglets (`Tab3`)
  au lieu d'un long formulaire vertical — un onglet par macro/outil.

### Added
- **`src/DDToolkit.ahk`** : appli unifiée regroupant les 4 macros dans un
  seul processus — icône en zone de notification, menu (Réglages /
  Recharger / Quitter), et une fenêtre de réglages (`Gui()`) qui écrit
  dans `settings.ini` puis relance (`Reload()`) au lieu d'exiger l'édition
  manuelle du fichier ini. Pensée pour un utilisateur qui ne connaît rien
  à AutoHotkey — voir `docs/DEMARRAGE.md`.
- **`src/Lib/Modules/*Module.ahk`** : logique des 4 macros extraite en
  classes réutilisables (état en propriétés statiques, pas en globales)
  pour pouvoir coexister dans le process unique de `DDToolkit.ahk` sans
  collision de noms. Les 4 scripts standalone (`AutoAbility.ahk`, etc.)
  deviennent de fins wrappers autour de leur module.
- `DD.Write()` / `DD.WriteBool()` dans `Common.ahk` (écriture ini,
  utilisées par la fenêtre de réglages).
- `Enabled=true` par section dans `settings.ini` : chaque macro peut être
  coupée entièrement (aucun hotkey enregistré) sans supprimer ses réglages.
- `docs/DEMARRAGE.md` : guide d'installation zéro-prérequis (SmartScreen,
  antivirus, zone de notification, tout en français simple).
- `templates/NewMacroModule.ahk.example` : gabarit module, en plus du
  wrapper existant, pour suivre le nouveau pattern module+wrapper.

### Fixed (trouvé en vérifiant chaque API avant de l'utiliser)
- Toutes les API AHK v2 nouvellement utilisées pour `DDToolkit.ahk`
  (`Gui()`, `A_TrayMenu`, `IniWrite`, `Persistent()`, `HotIf()` générique
  avec callback compound) ont été vérifiées via la documentation avant
  d'être écrites, faute de pouvoir exécuter AutoHotkey dans cet
  environnement. Deux erreurs ont été attrapées avant d'être commises :
  assigner `this.x := valeur` à une propriété non déclarée dans une
  méthode statique n'est pas garanti créer une vraie propriété statique
  (toutes les propriétés de `SettingsWindow` sont maintenant déclarées
  explicitement) ; `IniWrite` prend `(Valeur, Fichier, Section, Clé)`,
  ordre différent d'`IniRead`.

### Security
- **`release.yml`** : `${{ inputs.tag }}` (texte libre du déclenchement
  manuel `workflow_dispatch`) était interpolé directement dans deux blocs
  `run:` PowerShell — le vecteur d'injection de script classique des
  workflows GitHub Actions. Corrigé en passant la valeur par `env:
  TAG_NAME` et en la relisant via `$env:TAG_NAME`, qui la traite comme
  donnée plutôt que comme texte de script. Les SHA de commit
  (`github.event.pull_request.*.sha`) restent interpolés directement dans
  `commitlint.yml` : ce sont des identifiants calculés par GitHub, pas du
  texte libre attaquable.

### Fixed
- **`tests/Test-Syntax.ps1` et `scripts/Install-Hooks.ps1` ne s'exécutaient
  pas du tout sous Windows PowerShell 5.1** (`powershell.exe`, le shell par
  défaut de la plupart des machines Windows) : un tiret cadratin dans une
  chaîne de caractères réelle (pas un commentaire) se fait mal décoder par
  PS 5.1 sur un fichier sans BOM, produisant un octet qui ressemble à un
  guillemet Unicode — que le parser PowerShell traite comme un vrai
  délimiteur de chaîne, cassant le script ("Le terminateur \" est
  manquant"). Confirmé en exécutant réellement les scripts (pas seulement
  en les parsant). Remplacé par des tirets ASCII simples ; les tirets
  cadratins dans des blocs de commentaires (`Bump-Version.ps1`,
  `Build-All.ps1`) ne posent pas ce problème et restent inchangés.
- `scripts/Install-Hooks.ps1` affichait "OK" même quand `git config`
  échouait (pas dans un repo git, etc.) : une commande externe qui échoue
  ne déclenche pas `$ErrorActionPreference = "Stop"`, il faut vérifier
  `$LASTEXITCODE` explicitement. Testé en conditions réelles (repo git
  valide + hors repo git) après correction.
- **Distribution cassée pour `AbilityWheel.ahk` (et en théorie tous les
  scripts) une fois compilée en `.exe` et distribuée seule** : `DD.ConfigPath`
  pointait uniquement vers `..\config\settings.ini` (disposition du repo en
  dev), un chemin qui n'existe pas pour un `.exe` téléchargé isolément
  depuis une Release GitHub — `AbilityWheel.ahk.exe` se serait chargé sans
  erreur mais avec zéro spin enregistré. `DD.ConfigPath` cherche
  maintenant `settings.ini` dans son propre dossier en premier (voir
  `DD.ResolveConfigPath()`), et `build/Build-All.ps1` copie
  `config/settings.ini` dans `dist/` pour que ce cas marche par défaut.
- Une valeur non numérique ou mal cochée dans `settings.ini`
  (`IntervalMs`, `ToleranceRGB`, `ScopeToGame`, une couleur hex invalide
  dans `[AbilityWheelColors]`...) faisait planter tout le script au
  chargement au lieu de retomber sur la valeur par défaut. Ajout de
  `DD.ReadInt()` / `DD.ReadBool()` (notifient et utilisent le fallback au
  lieu de lever une exception non gérée) et d'un `try`/`catch` par entrée
  de couleur dans `AbilityWheel.ahk`.
- `release.yml` publie maintenant aussi un zip combiné
  `dd-toolkit-vX.Y.Z.zip` (tous les `.exe` + `settings.ini`), en plus des
  `.exe` isolés, pour un téléchargement unique prêt à l'emploi.
- `AbilityWheel.ahk` : nettoyage de `WinGetPos` (X/Y jamais utilisés,
  paramètres omis au lieu de variables mortes).
- `tests/Test-Syntax.ps1` : délai de smoke-test relevé à 2,5s (marge contre
  la lenteur/charge variable des runners CI).
- `package.json` : scripts `test`/`build` en alias des scripts PowerShell
  correspondants, pour `npm test` / `npm run build`.

### Added
- `src/AutoClicker.ahk` : remplace le repo de référence Azazel131's `10 CPS
  Left.ahk` / `10 CPS Right.ahk` (deux fichiers quasi-dupliqués, un par
  bouton, délai codé en dur malgré le nom "10 CPS" alors qu'ils tournent en
  réalité à ~50 clics/s). Un seul script, intervalle et touches de toggle
  configurables via `settings.ini`, scoping fenêtre activé par défaut
  (`ScopeToGame`, désactivable pour retrouver le comportement système
  d'origine).
- `src/AbilityWheel.ahk` : réécriture complète de `Auto Wheel.ahk` (roue
  Jester / Wheel of Fortune), qui était en AutoHotkey **v1** alors que le
  reste du repo de référence exige v2. Port v2 complet (`PixelSearch`/
  `WinGetPos` par valeur de retour et `&`-params, `WinExist` en garde),
  matching sur `ahk_exe` au lieu du titre de fenêtre litéral (fragile),
  hotkeys scopées au jeu (absent de l'original), et combinaisons
  (`Spin.*`) + couleurs entièrement pilotées par `config/settings.ini` au
  lieu d'appels codés en dur qu'il fallait copier-coller à la main pour en
  ajouter. La math de détection (espacement des slots, mise à l'échelle
  par résolution) est reprise telle quelle de la source communautaire —
  non revérifiée en jeu dans le cadre de cette réécriture.
- `DD.ReadSection()` dans `src/Lib/Common.ahk` : lit une section ini
  entière en Map, nécessaire pour la liste ouverte de spins d'AbilityWheel.

### Fixed
- Bug réel trouvé et corrigé dans `src/AutoAbility.ahk` et le nouveau
  `src/AbilityWheel.ahk` (+ `templates/NewMacro.ahk.example`) : le code
  appelait `HotIf(gameCriterion)` avec une chaîne de critère fenêtre, alors
  que la fonction `HotIf()` attend un callback booléen — ça ne plante pas
  au chargement, ça ne matche juste jamais. La bonne fonction pour ce cas
  est `HotIfWinActive(gameCriterion)`. Vérifié via la doc AHK v2 (recherche
  croisée, la doc officielle bloque le fetch direct depuis cet
  environnement) avant correction.

### Changed
- Repo entièrement restructuré (`config/`, `src/`, `src/Lib/`, `build/`, `tests/`).
- Migration complète AutoHotkey v1 → v2.
- `Auto E.ahk` remplacé par `src/AutoAbility.ahk` : générique et piloté par
  `config/settings.ini` (touche, intervalle, touches de toggle/panic), au
  lieu d'une boucle `Send/Sleep` codée en dur. Ajout d'un scoping fenêtre
  (`#HotIf WinActive`) pour ne jamais envoyer de touche hors du jeu.
- `DDTurretStack.ahk.exe` (binaire compilé, source perdue) remplacé par
  `src/TowerStacking.ahk`, reconstruit à partir de la technique
  communautaire documentée (wiki DD + dépôt Azazel131/Dungeon-Defenders-AHK-Scripts).

### Added
- `src/Lib/Common.ahk` : helpers partagés (lecture config, nom du process
  du jeu, notifications, bip on/off).
- `build/Build-All.ps1` : compilation automatisée de `src/*.ahk` vers des
  `.exe` portables dans `dist/`.
- `tests/Test-Syntax.ps1` : smoke-test de chargement pour chaque script.
- `.github/workflows/ci.yml` : CI sur `windows-latest` (smoke-test + build),
  AutoHotkey v2 récupéré depuis les releases officielles GitHub (portable,
  sans installeur tiers).
- `.github/ISSUE_TEMPLATE/` (bug report, feature request) et
  `.github/PULL_REQUEST_TEMPLATE.md`.
- `LICENSE` (MIT), `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1),
  `SECURITY.md`, `CONTRIBUTING.md`.
- `.editorconfig` pour un formatage cohérent entre éditeurs.
- `templates/NewMacro.ahk.example` : point de départ pour ajouter une
  nouvelle macro sans repartir de zéro.
- `VERSION` (SemVer) et métadonnées de build (`;@Ahk2Exe-Set*`) embarquées
  dans chaque script pour que les `.exe` compilés portent nom/description/
  version — contrairement à l'ancien `DDTurretStack.ahk.exe`, anonyme.
- `.github/workflows/release.yml` : sur un tag `vX.Y.Z`, build les `.exe`
  et les publie automatiquement sur une GitHub Release (notes extraites du
  CHANGELOG). Aucun binaire commité en historique git.
- `.github/dependabot.yml` : mises à jour hebdomadaires automatiques des
  actions GitHub utilisées en CI.
- `.githooks/pre-commit` + `scripts/Install-Hooks.ps1` : smoke-test
  syntaxe local avant chaque commit touchant `src/*.ahk` (skip silencieux
  si AutoHotkey v2 n'est pas installé en local).
- `scripts/Bump-Version.ps1` : bump `VERSION`, directives Ahk2Exe et
  CHANGELOG en une seule commande (testé en dry-run, y compris
  encodage UTF-8 sans BOM des caractères accentués).
- `commitlint.config.js` + `package.json` (commitlint, commitizen, cz-git) :
  Conventional Commits avec gitmoji optionnel en tête, prompt interactif
  (`npm run commit`), config testée avec l'API Node de commitlint (cas
  valide simple, valide avec emoji, type invalide rejeté, breaking change).
- `.githooks/commit-msg` : lint local du message de commit (skip
  silencieux si `node_modules` absent).
- `.github/workflows/commitlint.yml` : lint de tous les commits d'une PR
  sur `ubuntu-latest`.
- `BRANCHING.md` : stratégie de branches minimale (GitHub Flow), nommage
  aligné sur les types de commit, squash-merge, protection à activer côté
  GitHub une fois le repo poussé.
- `AGENTS.md` : guide agent-agnostique (commandes, conventions de code,
  limites des tests, sécurité, commits/branches) pour tout agent IA.
- `CLAUDE.md` : addendum spécifique Claude Code (réalités d'environnement
  PowerShell/encodage découvertes pendant ce travail, limite de
  vérification en jeu, règle de non-automatisation git sans accord
  explicite).
- `README.md`, `.gitignore`, ce changelog.

### Security
- Actions GitHub (`checkout`, `upload-artifact`, `setup-node`) épinglées
  par SHA de commit (vérifiés via l'API GitHub) plutôt que par tag mobile,
  dans `ci.yml`, `release.yml` et `commitlint.yml`.
- Workflows durcis : `concurrency` (annule les runs obsolètes),
  `timeout-minutes` explicite, `permissions` minimales, retry réseau sur
  le téléchargement d'AutoHotkey.

### Removed
- `Auto E.ahk` (racine, v1).
- `DDTurretStack.ahk.exe` (racine, binaire opaque).

