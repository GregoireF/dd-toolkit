# Stratégie de branches

Volontairement minimale (GitHub Flow) — une seule branche longue, tout le
reste est jetable.

## `main`

- Toujours dans un état publiable (la CI doit passer).
- Aucun push direct une fois le repo poussé sur GitHub — tout passe par une
  PR (voir § Protection à activer ci-dessous).
- Les tags de release (`vX.Y.Z`) sont créés uniquement depuis `main`, via
  `scripts/Bump-Version.ps1` (voir README § Releases).

## Branches de travail

Nommage : `<type>/<description-courte-en-kebab-case>`, où `<type>` reprend
exactement les types de [`commitlint.config.js`](commitlint.config.js) :

```
feat/tower-stacking-diagonal
fix/auto-ability-panic-key
docs/readme-badges
chore/ci-pin-actions-sha
```

Une branche = une PR = un sujet. Pas de branches fourre-tout.

## Pull Requests

- Cible toujours `main`.
- Le template (`.github/PULL_REQUEST_TEMPLATE.md`) impose la checklist
  (tests locaux, test manuel en jeu, doc à jour).
- **Merge en squash** : l'historique de `main` reste linéaire, un commit
  par PR. Le message du commit de squash doit lui-même respecter
  [Conventional Commits + gitmoji](CONTRIBUTING.md#commits) — GitHub te
  laisse l'éditer au moment du squash, c'est le moment de le corriger si le
  titre de la PR ne suffit pas tel quel.
- Supprime la branche après merge (bouton GitHub, ou
  `git push origin --delete <branche>`).

## Protection à activer une fois le repo poussé sur GitHub

Ceci ne peut pas être fait depuis des fichiers locaux — à configurer dans
*Settings → Branches → Branch protection rules* (ou
`gh api repos/:owner/:repo/rulesets`) une fois le remote existant :

- Require a pull request before merging (1 approbation si/quand il y a
  plus d'une personne sur le repo — sinon 0 mais la CI reste obligatoire).
- Require status checks to pass: `CI / test-and-build`,
  `Commitlint / commitlint`.
- Require branches to be up to date before merging.
- Do not allow force pushes / deletions sur `main`.

## Résumé du flux complet

```
git checkout -b feat/ma-macro
# ... travail, commits via `npm run commit` (ou git commit + hook commitlint) ...
git push -u origin feat/ma-macro
# ouvrir la PR (template pré-rempli) -> CI + Commitlint doivent passer -> squash-merge -> supprimer la branche
# une fois pret a publier :
.\scripts\Bump-Version.ps1 -Version X.Y.Z   # sur main, a jour
git add -A && git commit -m "chore(release): vX.Y.Z"
git tag vX.Y.Z && git push && git push --tags   # declenche release.yml
```
