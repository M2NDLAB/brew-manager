# Comandi di processo del framework — agnostici allo stack.
# `make` o `make help` per la lista.
# I target specifici di brew-manager sono nella sezione in fondo.

.DEFAULT_GOAL := help

help: ## Mostra questo help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

hooks-install: ## Installa gli hook git (gitleaks + commitlint; formattazione da abilitare)
	bash scripts/hooks-install.sh

reset-task: ## Scarta il mezzo-task interrotto, preservando branch e commit (task planning)
	bash scripts/reset-task.sh

test-scripts: ## Self-test degli script del framework (hooks-install, ...)
	bash scripts/test-hooks-install.sh

# ============================================================================
# Target specifici di brew-manager (zsh, nessuna build).
# ============================================================================

run: ## Avvia la TUI di brew-manager
	./brew_manager.sh

check: ## Check di sintassi zsh su tutti gli script (fallisce al primo errore)
	@for f in brew_manager.sh lib/*.sh modules/*.sh tests/*.zsh; do \
		zsh -n "$$f" && echo "  ok  $$f" || exit 1; \
	done

# Harness zsh a mano, zero dipendenze (niente bats da installare): coerente con
# la filosofia del progetto (nessun tool obbligatorio). Ogni file tests/*.zsh è
# eseguibile da solo e ritorna non-zero se un check fallisce → gate bloccante.
test: ## Esegue i test (harness zsh, nessuna dipendenza)
	@fail=0; \
	for t in tests/*.zsh; do \
		echo "── $$t"; \
		zsh "$$t" || fail=1; \
	done; \
	exit $$fail

# Il file VERSION è la fonte autorevole (funziona anche senza .git: tarball,
# copia). Questo target è il guard-rail che impedisce il drift che c'era prima
# (costante ferma a 1.1.0 mentre i tag erano a v1.1.2): al momento di taggare
# una release, VERSION e tag devono coincidere.
version-check: ## Verifica che VERSION coincida con l'ultimo tag vX.Y.Z
	@v="$$(tr -d '[:space:]' < VERSION)"; \
	t="$$(git tag -l | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$$' | sort -V | tail -1)"; \
	if [ -z "$$t" ]; then \
		echo "  skip: nessun tag vX.Y.Z ancora presente (VERSION = $$v)"; \
	elif [ "v$$v" = "$$t" ]; then \
		echo "  ok  VERSION ($$v) allineato al tag $$t"; \
	else \
		echo "  ERRORE: VERSION ($$v) diverge dall'ultimo tag ($$t)." >&2; \
		echo "          Alla release: aggiorna VERSION e taggala nello stesso commit." >&2; \
		exit 1; \
	fi

# shellcheck non ha un dialetto zsh (solo sh/bash/dash/ksh): forzare --shell=bash
# su script zsh produce falsi positivi sui costrutti zsh-only (${(P)var}, read -rA,
# typeset -A). Per questo il target è ADVISORY: mostra i finding ma non fallisce —
# non può fare da gate finché il progetto è zsh. Skip pulito se non installato.
lint: ## Shellcheck advisory se installato (skip pulito altrimenti; mai bloccante)
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck --shell=bash --severity=warning brew_manager.sh lib/*.sh modules/*.sh \
			|| echo "  nota: finding ADVISORY (shellcheck non supporta zsh, attesi falsi positivi)"; \
	else \
		echo "  skip: shellcheck non installato (opzionale: brew install shellcheck)"; \
	fi
