# Framework process commands — stack-agnostic.
# `make` or `make help` for the list.
# The brew-manager-specific targets are in the section at the bottom.

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

hooks-install: ## Install the git hooks (gitleaks + commitlint + the pre-push push boundary)
	bash scripts/hooks-install.sh

# The branches reset-task must never touch: brew-manager is trunk-based on main, its
# integration and stable branch at once (CLAUDE.md, Branches); "dev" stays protected because
# it exists as a historical remote branch. A plain `=`, not `?=`: an exported
# environment variable must not silently replace the project's list; one run can still
# override it on the command line: make reset-task PROTECTED_BRANCHES="main trunk".
# YES=1 discards without asking — the user's form, never an agent's (the core's Resumption);
# make reads YES from the environment too, and any non-empty value skips the question.
PROTECTED_BRANCHES = main dev

reset-task: ## Discard the interrupted half-done task, preserving branch and commits (YES=1: no prompt)
	PROTECTED_BRANCHES="$(PROTECTED_BRANCHES)" bash scripts/reset-task.sh $(if $(YES),--yes)

# The last line runs the framework repository's own documentation check — tools/ is never
# copied into a project, where the line does nothing.
test-scripts: ## Self-test of the framework scripts (hooks-install, the agent git guard, repo-snapshot, the prerequisite check, reset-task, the STATE injection)
	bash scripts/test-hooks-install.sh
	bash scripts/test-agent-git-guard.sh
	bash scripts/test-repo-snapshot.sh
	bash scripts/test-check-prerequisites.sh
	bash scripts/test-reset-task.sh
	bash scripts/test-state-inject.sh
	@if [ -f tools/docs-check.mjs ]; then bash tools/test-docs-check.sh && node tools/docs-check.mjs; fi

# ============================================================================
# brew-manager-specific targets (zsh, no build).
# ============================================================================

# These targets are commands, not files. Without .PHONY a file named like one — a stray
# `check` at the root — makes make call the target up to date and exit 0 without its
# recipe: the blocking syntax gate, and the lint that depends on it, would pass unrun
# (the security gate of 2026-11-07, finding F6).
.PHONY: run check test version-check lint

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

# The project's lint is a syntax check only. shellcheck has no zsh dialect: on a zsh
# script it stops at SC1071, and --shell=bash yields false positives on zsh-only
# constructs (${(P)var}, read -rA, typeset -A). So lint runs check's `zsh -n` over the
# same files and holds no logic of its own that could drift from it (the framework
# architect's decision A of 2026-11-07,
# .claude/memory/decisions/2026-11-07-framework-architect-decisions.md).
lint: check ## Syntax check only: the same zsh -n as check (shellcheck does not support zsh)
