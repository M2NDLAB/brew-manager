# scripts/ — script di processo

Solo script del **metodo di lavoro**, agnostici allo stack. Gli script di build/run
del progetto (compilazione, test, avvio) NON stanno qui: li aggiunge ogni progetto.

| Script | Cosa fa |
|---|---|
| `hooks-install.sh` | Installa gli hook git locali: secret scanning (gitleaks, pre-commit) e Conventional Commits (commitlint, commit-msg), sempre attivi. La formattazione automatica del codice è inclusa come **esempio commentato** da adattare al linguaggio del progetto. Idempotente sui propri hook (se li hai personalizzati, il rilancio salva prima un `.bak`); davanti a hook preesistenti di ALTRA origine — inclusi i symlink degli hook manager — si ferma (override: `FORCE_OVERWRITE=1`, con backup `.bak`), e si ferma anche se `core.hooksPath` è attivo (es. husky: `.git/hooks` verrebbe ignorato e gli hook sarebbero inerti). |
| `reset-task.sh` | Cleanup CHIRURGICO di un task interrotto: scarta SOLO il lavoro non committato e preserva branch e commit precedenti. È il cleanup del protocollo di task planning (`.claude/docs/01-task-planning.md`). Rifiuta di operare sui branch condivisi. |
| `test-hooks-install.sh` | Self-test hermetic di `hooks-install.sh` (stub di `gitleaks`/`npx` + repo git usa-e-getta): esegue lo script REALE end-to-end e dimostra il contratto del ramo `FORCE_OVERWRITE=1` sul caso del symlink dangling, senza toccare il repo reale. Si lancia con `make test-scripts`. |

## Uso tipico

```bash
make hooks-install      # oppure: bash scripts/hooks-install.sh
make test-scripts       # self-test degli script (hermetic: non tocca il repo reale)
./scripts/reset-task.sh # dopo un'interruzione, prima di riprendere un piano
```

Prerequisiti di `hooks-install.sh`: `gitleaks` e `npx` (Node.js) installati.
