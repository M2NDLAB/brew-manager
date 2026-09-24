# Framework process commands — stack-agnostic.
# `make` or `make help` for the list.
# The brew-manager-specific targets are in the section at the bottom.

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

hooks-install: ## Install the git hooks (gitleaks + commitlint; formatting to be enabled)
	bash scripts/hooks-install.sh

reset-task: ## Discard the interrupted half-done task, preserving branch and commits (task planning)
	bash scripts/reset-task.sh

test-scripts: ## Self-test of the framework scripts (hooks-install, ...)
	bash scripts/test-hooks-install.sh

# ============================================================================
# brew-manager-specific targets (zsh, no build).
# ============================================================================

run: ## Start the brew-manager TUI
	./brew_manager.sh

check: ## zsh syntax check on every script (fails at the first error)
	@for f in brew_manager.sh lib/*.sh modules/*.sh tests/*.zsh; do \
		zsh -n "$$f" && echo "  ok  $$f" || exit 1; \
	done

# Hand-rolled zsh harness, zero dependencies (no bats to install): consistent with
# the project's philosophy (no mandatory tool). Every tests/*.zsh file runs on
# its own and returns non-zero if a check fails → blocking gate.
test: ## Run the tests (zsh harness, no dependency)
	@fail=0; \
	for t in tests/*.zsh; do \
		echo "── $$t"; \
		zsh "$$t" || fail=1; \
	done; \
	exit $$fail

# The VERSION file is the authoritative source (it works even without .git:
# tarball, copy). This target is the guard-rail against the drift there was
# before (a constant stuck at 1.1.0 while the tags were at v1.1.2): when a
# release is tagged, VERSION and the tag must match.
version-check: ## Check that VERSION matches the latest vX.Y.Z tag
	@v="$$(tr -d '[:space:]' < VERSION)"; \
	t="$$(git tag -l | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$$' | sort -V | tail -1)"; \
	if [ -z "$$t" ]; then \
		echo "  skip: no vX.Y.Z tag present yet (VERSION = $$v)"; \
	elif [ "v$$v" = "$$t" ]; then \
		echo "  ok  VERSION ($$v) aligned with tag $$t"; \
	else \
		echo "  ERROR: VERSION ($$v) diverges from the latest tag ($$t)." >&2; \
		echo "         At release time: update VERSION and tag it in the same commit." >&2; \
		exit 1; \
	fi

# shellcheck has no zsh dialect (only sh/bash/dash/ksh): forcing --shell=bash
# on zsh scripts yields false positives on zsh-only constructs (${(P)var}, read -rA,
# typeset -A). That is why the target is ADVISORY: it shows the findings but does
# not fail — it cannot be a gate while the project is zsh. Clean skip if not installed.
lint: ## Advisory shellcheck if installed (clean skip otherwise; never blocking)
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck --shell=bash --severity=warning brew_manager.sh lib/*.sh modules/*.sh \
			|| echo "  note: ADVISORY findings (shellcheck does not support zsh, false positives expected)"; \
	else \
		echo "  skip: shellcheck not installed (optional: brew install shellcheck)"; \
	fi
