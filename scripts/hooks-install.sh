#!/usr/bin/env bash
# Installa i git hook locali del framework:
#   - pre-commit : secret scanning (gitleaks) — SEMPRE
#   - commit-msg : Conventional Commits (commitlint) — SEMPRE
#   - pre-commit : formattazione automatica del codice — ESEMPIO da adattare allo stack
# Idempotente: sovrascrive gli hook precedenti installati da questo script.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="${REPO_ROOT}/.git/hooks"

# --- Prerequisiti -----------------------------------------------------------
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "ERRORE: gitleaks non installato (è la regola 1 di CLAUDE.md, non opzionale)." >&2
  echo "  macOS: brew install gitleaks   |   altri: https://github.com/gitleaks/gitleaks" >&2
  exit 1
fi
if ! command -v npx >/dev/null 2>&1; then
  echo "ERRORE: npx (Node.js) non installato — serve per commitlint." >&2
  exit 1
fi

mkdir -p "${HOOKS_DIR}"

# --- pre-commit -------------------------------------------------------------
cat > "${HOOKS_DIR}/pre-commit" <<'HOOK'
#!/usr/bin/env bash
# Hook generato da scripts/hooks-install.sh — non modificare a mano.
set -euo pipefail

# 1. Secret scanning sui file staged (regola 1: nessun secret committato). SEMPRE.
gitleaks protect --staged --redact -v

# 2. FORMATTAZIONE AUTOMATICA — predisposta ma NON attiva in questo progetto
#    (decisione all'innesto del framework: shfmt/shellcheck non installati; se in
#    futuro si adotta shfmt, decommentare il blocco e verificare che il diff di
#    riformattazione iniziale sia un commit dedicato). L'idea: applicare il
#    formatter ai SOLI file staged e ri-stagearli, così non si accumula drift e non
#    servono commit di sola formattazione.
#
#    # --- Esempio per questo progetto: shfmt sugli script zsh staged ---
#    # (shfmt non ha un dialetto zsh nativo: usare -ln bash è un'approssimazione
#    #  accettabile per questo codice; verificare il diff prima di adottarlo.)
#    # staged="$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.sh$' || true)"
#    # if [[ -n "${staged}" ]]; then
#    #   echo "${staged}" | xargs shfmt -w -i 4 -ln bash
#    #   echo "${staged}" | xargs git add                 # ri-stagea i file riformattati
#    # fi
#
#    Nota: il linter (per shell: shellcheck) resta fuori dall'hook — qui si fa solo
#    la formattazione (veloce, deterministica). Check di sintassi manuale: zsh -n.
HOOK

# --- commit-msg -------------------------------------------------------------
cat > "${HOOKS_DIR}/commit-msg" <<'HOOK'
#!/usr/bin/env bash
# Hook generato da scripts/hooks-install.sh — non modificare a mano.
# Conventional Commits, config in commitlint.config.cjs.
set -euo pipefail
npx --yes --package @commitlint/cli --package @commitlint/config-conventional \
  commitlint --edit "$1"
HOOK

chmod +x "${HOOKS_DIR}/pre-commit" "${HOOKS_DIR}/commit-msg"
echo "OK: hook pre-commit (gitleaks) e commit-msg (commitlint) installati."
echo "    Ricorda di abilitare la formattazione automatica nell'hook pre-commit (vedi commenti)."
