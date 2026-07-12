// Conventional Commits — tipi e regole (vedi .claude/docs/04-git-workflow.md).
// Usato dall'hook commit-msg (scripts/hooks-install.sh) e, se presente, dalla CI.
module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [
      2,
      "always",
      ["feat", "fix", "refactor", "perf", "test", "docs", "build", "ci", "chore"],
    ],
  },
};
