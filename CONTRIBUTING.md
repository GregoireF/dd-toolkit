# Contribuer

Merci de vouloir contribuer ! Ce repo est volontairement petit et sans
dépendance lourde (AutoHotkey v2 + PowerShell ; Node est optionnel, requis
seulement pour le lint des messages de commit) pour que le setup prenne
deux minutes.

Tu es un agent IA (Claude Code, Copilot, Cursor...) ? Lis
[AGENTS.md](AGENTS.md) à la place — condensé pour un contexte d'agent.
Stratégie de branches/PR détaillée : [BRANCHING.md](BRANCHING.md).

## Setup

1. Installe [AutoHotkey v2](https://www.autohotkey.com/) (v2.0.x, coexiste
   avec une éventuelle v1 déjà présente sur la machine).
2. Clone le repo, ouvre-le, et double-clique n'importe quel script dans
   `src/` pour le lancer directement — pas de build requis pour tester en
   local.
3. Installe les hooks git versionnés (une fois par clone) :
   ```powershell
   .\scripts\Install-Hooks.ps1
   ```
   `.githooks/pre-commit` relance `tests/Test-Syntax.ps1` avant chaque
   commit qui touche `src/*.ahk` ; `.githooks/commit-msg` lint le message
   de commit. Les deux s'effacent silencieusement (sans bloquer) si
   AutoHotkey v2 / `node_modules` ne sont pas présents en local — la CI
   (`ci.yml` + `commitlint.yml`) fait le vrai contrôle de toute façon.
4. (Optionnel, pour committer avec le prompt interactif emoji) :
   ```powershell
   npm install
   npm run commit
   ```
5. (Optionnel) Lance les scripts de `tests/` et `build/` en PowerShell (ou
   `npm test` / `npm run build` si Node est installé) pour valider la
   syntaxe et compiler des `.exe` portables (voir README).

## Conventions de code

- **La logique d'une macro est une classe dans `src/Lib/Modules/`**
  (ex. `AutoAbilityModule`), pas des globales/hotkeys en haut de fichier —
  c'est ce qui permet à `src/DDToolkit.ahk` d'inclure les 4 modules dans
  un seul process sans collision de variables (ils auraient sinon tous eu
  une globale `intervalMs` du même nom). Un module expose `Init()` (lit la
  config, enregistre les hotkeys — ne fait rien si `Enabled=false`) et
  `StatusText()` (résumé une ligne pour l'infobulle de la zone de
  notification). Le script standalone `src/<Nom>.ahk` associé n'est qu'un
  wrapper : `#Include` le module, appelle `.Init()`, envoie une
  notification.
- **Propriétés statiques toujours déclarées explicitement**
  (`static Foo := ""` dans le corps de la classe) avant d'être assignées
  depuis une méthode. Faire `this.Foo := valeur` sur un nom non déclaré
  dans une méthode statique n'est pas garanti créer une vraie propriété
  statique en v2 — seule une déclaration `static` explicite l'est (voir
  `SettingsWindow` dans `DDToolkit.ahk` pour l'exemple).
- **Rien de codé en dur qui devrait être ajustable.** Touches, intervalles,
  nom du process du jeu → dans `config/settings.ini`. Chaînes via
  `DD.Read(section, key, default)`, entiers via `DD.ReadInt(...)`,
  booléens via `DD.ReadBool(...)` — jamais un `Integer(DD.Read(...))` nu ou
  une comparaison `= "true"` brute, ça plante toute la relance du script
  sur une simple faute de frappe dans l'ini au lieu de retomber sur la
  valeur par défaut. Toujours fournir une valeur par défaut sensée pour
  que le script marche même sans toucher au fichier ini.
- **Scoping fenêtre par défaut.** Toute macro qui envoie des touches doit
  se limiter à la fenêtre du jeu via `#HotIf WinActive(DD.GameCriterion())`
  (hotkeys statiques) ou `HotIfWinActive(DD.GameCriterion())` /
  `Hotkey(...)` / `HotIfWinActive()` (hotkeys dynamiques — bien
  `HotIfWinActive`, pas le `HotIf()` générique qui attend une fonction
  callback et pas une chaîne), sauf raison explicite documentée en
  commentaire (ex : un autoclicker volontairement généraliste).
- **Code partagé → `src/Lib/`**, inclus explicitement avec
  `#Include Lib\NomDuFichier.ahk`. On n'utilise pas le mécanisme
  d'auto-inclusion par nom de fonction d'AutoHotkey (pratique seulement
  pour une fonction isolée par fichier) car nos helpers sont regroupés dans
  une classe (`DD`) partagée par tous les scripts.
- **Toujours un retour utilisateur.** Un toggle doit biper
  (`DD.Beep(bool)`) et/ou notifier (`DD.Notify(titre, texte)`) — jamais de
  changement d'état silencieux.
- **Point de départ pour un nouveau script :**
  [`templates/NewMacro.ahk.example`](templates/NewMacro.ahk.example) — copie-le
  dans `src/`, renomme-le, et suis la checklist en commentaire.

## Style / formatage

Un [`.editorconfig`](.editorconfig) est fourni — la plupart des éditeurs
(VS Code, JetBrains, etc.) l'appliquent automatiquement. Pas de linter AHK
imposé au-delà de ça.

## Commits

Ce repo suit [Conventional Commits](https://www.conventionalcommits.org/),
avec un [gitmoji](https://gitmoji.dev/) optionnel devant le type — validé
par `commitlint.config.js` (`@commitlint/config-conventional` + une
tolérance d'emoji en tête). Types acceptés :

| Type       | Emoji | Usage                                        |
|------------|:-----:|-----------------------------------------------|
| `feat`     |  ✨   | Nouvelle macro ou fonctionnalité               |
| `fix`      |  🐛   | Correction de comportement                     |
| `docs`     |  📝   | README/CHANGELOG/commentaires uniquement       |
| `style`    |  💄   | Formatage, sans changement de logique          |
| `refactor` |  ♻️   | Réorganisation sans changement de comportement |
| `perf`     |  ⚡️   | Amélioration de performance                    |
| `test`     |  ✅   | Ajout/correction de tests                      |
| `build`    |  📦️   | Build, dépendances, packaging                  |
| `ci`       |  👷   | CI/CD (workflows, hooks)                       |
| `chore`    |  🔧   | Infra, config, maintenance                     |
| `revert`   |  ⏪️   | Annule un commit précédent                     |

Deux façons d'écrire un commit valide :

```powershell
# 1) Prompt interactif (choisit le type/emoji pour toi)
npm run commit

# 2) À la main — le hook commit-msg (ou la CI) valide le format
git commit -m "feat(tower-stacking): ajoute le stacking diagonal"
git commit -m "✨ feat(tower-stacking): ajoute le stacking diagonal"   # emoji optionnel, décoratif
```

Les sujets en français sont acceptés tels quels (`subject-case` est
désactivé exprès). Voir [BRANCHING.md](BRANCHING.md) pour le nommage des
branches et le flux de PR.

## Tests avant une PR

```powershell
.\tests\Test-Syntax.ps1
.\tests\Run-UnitTests.ps1
.\build\Build-All.ps1
```

`Test-Syntax.ps1` est un smoke test (chargement sans erreur). `Run-UnitTests.ps1`
va plus loin : de vraies assertions sur la logique de chaque module, `Init()`
compris, avec les fonctions qui parlent à l'OS (`Send`, `PixelSearch`,
`RegRead`...) remplacées par des doublures de test (`tests/Shims.ahk`) —
donc aucune touche/clic réel n'est jamais envoyé pendant les tests. Si tu
ajoutes un nouveau module ou une nouvelle méthode, ajoute ses tests dans
`tests/*.test.ahk` (logique pure directement ; toute méthode qui touche
l'OS via un nouveau `Shims.ahk`, sur le même modèle que l'existant).

Aucun des deux n'est un test fonctionnel pour autant. Il n'existe aucun
moyen d'automatiser "est-ce que ça stacke vraiment en jeu" sans lancer
Dungeon Defenders : teste toujours manuellement en jeu avant d'ouvrir une
PR, et décris ce que tu as testé dans la description de la PR (le
template te le demande).

La CI (`.github/workflows/ci.yml`) relance ces mêmes scripts sur
`windows-latest` à chaque push/PR. `.github/dependabot.yml` garde les
versions des actions GitHub utilisées à jour automatiquement (PR
hebdomadaire si besoin).

## Publier une release (.exe téléchargeables)

Pas de build manuel à distribuer : pousser un tag déclenche
`.github/workflows/release.yml`, qui compile et publie les `.exe` sur une
GitHub Release.

```powershell
.\scripts\Bump-Version.ps1 -Version 0.2.0   # met à jour VERSION, les
                                              # directives Ahk2Exe, et
                                              # CHANGELOG.md
git add -A
git commit -m "chore(release): v0.2.0"
git tag v0.2.0
git push && git push --tags
```

Le contenu de la nouvelle section `## [0.2.0] - ...` du CHANGELOG devient
automatiquement les notes de la Release.

## Checklist PR

- [ ] Le script est scopé à la fenêtre du jeu (ou l'exception est justifiée
      en commentaire).
- [ ] Toute valeur ajustable est dans `config/settings.ini`, pas codée en
      dur.
- [ ] `tests/Test-Syntax.ps1`, `tests/Run-UnitTests.ps1` et
      `build/Build-All.ps1` passent en local.
- [ ] Testé manuellement en jeu.
- [ ] README.md et CHANGELOG.md mis à jour si le comportement visible
      change.

## Signaler un bug / proposer une idée

Utilise les templates d'issue GitHub (`.github/ISSUE_TEMPLATE/`) — ça
prend 2 minutes et ça évite les allers-retours.
