## Quoi / pourquoi


## Checklist

- [ ] Script scopé à la fenêtre du jeu (`#HotIf` / `HotIf()` +
      `DD.GameCriterion()`), ou exception justifiée en commentaire
- [ ] Aucune valeur codée en dur qui devrait être dans
      `config/settings.ini`
- [ ] `.\tests\Test-Syntax.ps1` passe en local
- [ ] `.\build\Build-All.ps1` passe en local
- [ ] Testé manuellement en jeu (décrire ci-dessous)
- [ ] `README.md` / `CHANGELOG.md` mis à jour si le comportement visible
      change

## Test manuel en jeu

Décris ce que tu as vérifié (quelle tour, quelle touche, quel mode de
jeu...) — un smoke test PowerShell ne peut pas remplacer ça.
