#!/usr/bin/env bash
# ============================================================================
# reset-task: scarta SOLO il lavoro non committato dell'ultimo task
#
# A differenza di un reset di branch, questo è CHIRURGICO: butta unicamente le
# modifiche non ancora committate (il mezzo-task interrotto da uno stop/crash) e
# PRESERVA tutti i commit dei task precedenti e il branch. È il cleanup corretto
# per il protocollo di task planning (.claude/docs/01-task-planning.md).
#
# Uso:  ./scripts/reset-task.sh          # mostra cosa scarterebbe e chiede conferma
#       ./scripts/reset-task.sh --yes    # scarta senza chiedere (per automazioni)
# ============================================================================
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

AUTO="${1:-}"
BRANCH=$(git branch --show-current)

# Guardia 1: non operare sui branch condivisi/protetti.
# brew-manager è trunk-based su main; "dev" resta protetto perché esiste come
# branch remoto storico. Override via env, es.
#   PROTECTED_BRANCHES="main trunk" ./scripts/reset-task.sh
PROTECTED_BRANCHES="${PROTECTED_BRANCHES:-main dev}"
for b in $PROTECTED_BRANCHES; do
  if [ "$BRANCH" = "$b" ]; then
    echo "❌ Sei su '$BRANCH' (branch protetto). reset-task opera solo sui feature branch."
    echo "   Se '$BRANCH' è sporco, ispeziona a mano con 'git status'."
    exit 1
  fi
done

# Niente da fare?
if git diff --quiet && git diff --cached --quiet && [ -z "$(git clean -nd)" ]; then
  echo "✓ Working tree già pulito su '$BRANCH'. Nessun mezzo-task da scartare."
  echo "  Ultimo commit: $(git log --oneline -1)"
  exit 0
fi

echo "→ Branch: $BRANCH"
echo "→ I COMMIT dei task completati sono al sicuro e NON verranno toccati."
echo "→ Verrebbe scartato SOLO questo lavoro non committato (il task interrotto):"
echo "---- file modificati/staged ----"
git status -s
echo "---- file non tracciati che verrebbero rimossi ----"
git clean -nd
echo "--------------------------------"
echo "Ultimo commit (da cui riprenderai): $(git log --oneline -1)"

if [ "$AUTO" != "--yes" ]; then
  printf "Procedo a scartare SOLO il lavoro non committato? [y/N] "
  read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "Annullato. Niente toccato."; exit 0; }
fi

git restore . 2>/dev/null || true
git restore --staged . 2>/dev/null || true
git clean -fd -q

echo "✅ Mezzo-task scartato. Branch '$BRANCH' intatto fino all'ultimo commit."
echo "   git log: $(git log --oneline -1)"
echo "→ Riprendi rilanciando lo stesso prompt: il protocollo docs/01 ripartirà"
echo "  dal primo task non spuntato nel piano (.claude/memory/plans/)."
