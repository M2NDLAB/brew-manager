#!/usr/bin/env bash
# Installa i git hook locali del framework:
#   - pre-commit : secret scanning (gitleaks) — SEMPRE
#   - commit-msg : Conventional Commits (commitlint) — SEMPRE
#   - pre-commit : formattazione automatica del codice — ESEMPIO da adattare allo stack
# Idempotente sui PROPRI hook (riconosciuti dal marcatore nel file generato); se
# un proprio hook contiene modifiche locali (es. blocco formattazione adattato),
# ne salva prima una copia .bak invece di distruggerle.
# Hook preesistenti di ALTRA origine (incl. symlink di un hook manager): lo script
# si FERMA invece di sovrascriverli; override esplicito con FORCE_OVERWRITE=1, che
# prima ne salva una copia .bak (un symlink dangling, senza contenuto, si rimuove
# senza .bak). Se core.hooksPath è impostato (es. husky), si
# ferma: git ignorerebbe .git/hooks e questi hook risulterebbero installati ma inerti.
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

# --- Guardie per un repo con hook preesistenti (innesto su progetto esistente) --
# 1. core.hooksPath attivo (es. husky): git NON legge .git/hooks, quindi gli hook
#    scritti qui sotto non verrebbero MAI eseguiti — installati ma inerti. Meglio
#    fermarsi e far decidere l'utente che dare falsa sicurezza.
hooks_path="$(git -C "${REPO_ROOT}" config --get core.hooksPath || true)"
if [[ -n "${hooks_path}" ]]; then
  echo "ERRORE: core.hooksPath è impostato a '${hooks_path}': git ignora .git/hooks," >&2
  echo "  quindi gli hook del framework non verrebbero mai eseguiti. Scegli:" >&2
  echo "  - integra i comandi di questi hook nel tuo hook manager (es. husky), oppure" >&2
  echo "  - rimuovi l'override e rilancia. Individua PRIMA da dove viene (local," >&2
  echo "    global o system): git config --show-origin --get core.hooksPath" >&2
  echo "    poi: git config --unset core.hooksPath   (aggiungi --global se viene da lì)" >&2
  exit 1
fi

# 2. Hook preesistenti NON generati da questo script: non si sovrascrivono alla
#    cieca — potrebbero appartenere alla pipeline del progetto ospite. Un SYMLINK
#    è sempre "di altra origine" (gli hook manager linkano .git/hooks altrove):
#    scriverci attraverso corromperebbe il file bersaglio FUORI da .git/hooks.
#    Con FORCE_OVERWRITE=1 si procede: backup .bak del contenuto (saltato se il
#    symlink è dangling — niente da salvare), poi rimozione del file/symlink così la
#    scrittura crea un file regolare.
MARKER="Hook generato da scripts/hooks-install.sh"
for hook in pre-commit commit-msg; do
  target="${HOOKS_DIR}/${hook}"
  if [[ -L "${target}" ]] || { [[ -f "${target}" ]] && ! grep -q "${MARKER}" "${target}"; }; then
    if [[ "${FORCE_OVERWRITE:-0}" == "1" ]]; then
      # Un symlink DANGLING (bersaglio inesistente) farebbe fallire `cp -L` sotto
      # `set -e`, abortendo PRIMA della rimozione — ma non ha contenuto da salvare.
      # `-e` segue il link → FALSO sul solo dangling (VERO su symlink valido e su
      # file regolare estraneo): il backup si fa dove ha senso, la rimozione del link
      # è comune ai due rami così la scrittura crea poi un file regolare.
      if [[ -e "${target}" ]]; then
        cp -L "${target}" "${target}.bak"
        echo "AVVISO: hook '${hook}' preesistente salvato in ${target}.bak (FORCE_OVERWRITE=1)." >&2
      else
        echo "AVVISO: hook '${hook}' era un symlink dangling (nessun contenuto da salvare): rimosso (FORCE_OVERWRITE=1)." >&2
      fi
      rm -f "${target}"
    else
      echo "ERRORE: esiste già un hook '${hook}' non installato da questo script." >&2
      echo "  Integra a mano i suoi comandi con quelli del framework, oppure rilancia con" >&2
      echo "  FORCE_OVERWRITE=1 per sovrascriverlo (prima viene salvato in ${hook}.bak)." >&2
      exit 1
    fi
  fi
done

mkdir -p "${HOOKS_DIR}"

# Installa un hook generato: se il target esiste (è per forza NOSTRO, gli estranei
# sono gestiti sopra) ma il contenuto differisce, contiene personalizzazioni locali
# (es. il blocco formattazione adattato, come chiedono i commenti dell'hook):
# se ne salva un .bak prima di riscriverlo, così il rilancio non le distrugge.
install_generated() {
  local target="$1"
  if [[ -f "${target}" ]] && ! cmp -s "${target}" "${target}.new"; then
    cp "${target}" "${target}.bak"
    echo "AVVISO: ${target##*/} conteneva modifiche locali: salvate in ${target}.bak prima della riscrittura." >&2
  fi
  mv "${target}.new" "${target}"
  chmod +x "${target}"
}

# --- pre-commit -------------------------------------------------------------
cat > "${HOOKS_DIR}/pre-commit.new" <<'HOOK'
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
install_generated "${HOOKS_DIR}/pre-commit"

# --- commit-msg -------------------------------------------------------------
cat > "${HOOKS_DIR}/commit-msg.new" <<'HOOK'
#!/usr/bin/env bash
# Hook generato da scripts/hooks-install.sh — non modificare a mano.
# Conventional Commits, config in commitlint.config.cjs.
set -euo pipefail
npx --yes --package @commitlint/cli --package @commitlint/config-conventional \
  commitlint --edit "$1"
HOOK
install_generated "${HOOKS_DIR}/commit-msg"

echo "OK: hook pre-commit (gitleaks) e commit-msg (commitlint) installati."
echo "    Ricorda di abilitare la formattazione automatica nell'hook pre-commit (vedi commenti)."
