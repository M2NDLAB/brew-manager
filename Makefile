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

# ============================================================================
# Target specifici di brew-manager (zsh, nessuna build; test assenti — debito
# annotato in .claude/memory/STATE.md).
# ============================================================================

run: ## Avvia la TUI di brew-manager
	./brew_manager.sh

check: ## Check di sintassi zsh su tutti gli script (fallisce al primo errore)
	@for f in brew_manager.sh lib/*.sh modules/*.sh; do \
		zsh -n "$$f" && echo "  ok  $$f" || exit 1; \
	done

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
