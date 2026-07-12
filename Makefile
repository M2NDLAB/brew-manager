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

check: ## Check di sintassi zsh su tutti gli script (nessun linter installato)
	@for f in brew_manager.sh lib/*.sh modules/*.sh; do \
		zsh -n "$$f" && echo "  ok  $$f" || exit 1; \
	done
