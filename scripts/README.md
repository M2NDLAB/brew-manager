# scripts/ — script di processo

Solo script del **metodo di lavoro**, agnostici allo stack. Gli script di build/run
del progetto (compilazione, test, avvio) NON stanno qui: li aggiunge ogni progetto.

| Script | Cosa fa |
|---|---|
| `hooks-install.sh` | Installa gli hook git locali: secret scanning (gitleaks, pre-commit) e Conventional Commits (commitlint, commit-msg), sempre attivi. La formattazione automatica del codice è inclusa come **esempio commentato** da adattare al linguaggio del progetto. Idempotente. |
| `reset-task.sh` | Cleanup CHIRURGICO di un task interrotto: scarta SOLO il lavoro non committato e preserva branch e commit precedenti. È il cleanup del protocollo di task planning (`.claude/docs/01-task-planning.md`). Rifiuta di operare sui branch condivisi. |

## Uso tipico

```bash
make hooks-install      # oppure: bash scripts/hooks-install.sh
./scripts/reset-task.sh # dopo un'interruzione, prima di riprendere un piano
```

Prerequisiti di `hooks-install.sh`: `gitleaks` e `npx` (Node.js) installati.
