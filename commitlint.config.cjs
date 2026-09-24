// Conventional Commits — types and rules (see .claude/docs/04-git-workflow.md).
// Used by the commit-msg hook (scripts/hooks-install.sh) and, if present, by CI.
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
