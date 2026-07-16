/** @type {import('@commitlint/types').UserConfig} */
module.exports = {
  extends: ["@commitlint/config-conventional"],
  parserPreset: {
    parserOpts: {
      // Tolerate an optional leading gitmoji before the usual
      // "type(scope): subject" header (produced by `npm run commit`), e.g.
      // "✨ feat(tower-stacking): add diagonal stacking". The emoji is
      // purely decorative — everything after it still has to satisfy the
      // conventional-commit rules below.
      headerPattern: /^(?:\p{Emoji_Presentation}️?\s+)?(\w*)(?:\(([^)]*)\))?(!?): (.*)$/u,
      headerCorrespondence: ["type", "scope", "breaking", "subject"],
    },
  },
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "feat",
        "fix",
        "docs",
        "style",
        "refactor",
        "perf",
        "test",
        "build",
        "ci",
        "chore",
        "revert",
      ],
    ],
    // Commit subjects in this repo are written in French — an
    // English lower/sentence-case rule would just fight accented words.
    "subject-case": [0],
  },
  // Read by cz-git (config.commitizen.path in package.json) for `npm run commit`.
  prompt: {
    useEmoji: true,
    emojiAlign: "center",
    messages: {
      type: "Type de changement :",
      scope: "Portée (optionnelle) :",
      subject: "Résumé court, à l'impératif :",
      body: "Description longue (optionnelle). Utilise | pour un retour à la ligne :\n",
      confirmCommit: "Confirmer ce message de commit ?",
    },
    types: [
      { value: "feat", name: "feat:     ✨  Nouvelle macro ou fonctionnalité", emoji: "✨" },
      { value: "fix", name: "fix:      🐛  Correction de comportement", emoji: "🐛" },
      { value: "docs", name: "docs:     📝  Documentation uniquement", emoji: "📝" },
      { value: "style", name: "style:    💄  Formatage, sans changement de logique", emoji: "💄" },
      { value: "refactor", name: "refactor: ♻️  Réorganisation sans changement de comportement", emoji: "♻️" },
      { value: "perf", name: "perf:     ⚡️  Amélioration de performance", emoji: "⚡️" },
      { value: "test", name: "test:     ✅  Ajout ou correction de tests", emoji: "✅" },
      { value: "build", name: "build:    📦️  Build, dépendances, packaging", emoji: "📦️" },
      { value: "ci", name: "ci:       👷  CI/CD (workflows, hooks)", emoji: "👷" },
      { value: "chore", name: "chore:    🔧  Maintenance, config, infra", emoji: "🔧" },
      { value: "revert", name: "revert:   ⏪️  Annule un commit précédent", emoji: "⏪️" },
    ],
  },
};
