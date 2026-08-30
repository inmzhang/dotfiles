# ============================================================================
# Dotfiles management via Makefile symlinks
# ============================================================================

DOTDIR  := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)
UNAME_S := $(shell uname -s)
CODEX_HOME := $(HOME)/.codex
CODEX_MEMORY_SEED_DIR := $(DOTDIR)/config/codex/memories/seed
CODEX_MEMORY_STATE_DIR := $(HOME)/.local/state/codex/memories
OMARCHY_MONITORS := $(DOTDIR)/config/omarchy/hypr/monitors.lua
OMARCHY_AUTOSTART := $(DOTDIR)/config/omarchy/hypr/autostart.lua
OMARCHY_CODEX_WRAPPER := $(DOTDIR)/config/omarchy/bin/codex
GHOSTTY_LINUX_CONFIG := $(DOTDIR)/config/ghostty/linux
GHOSTTY_LINUX_OVERRIDES := $(DOTDIR)/config/ghostty/linux-overrides

# Symlink helper: ln_sf(source, target)
#   Creates parent dirs and backs up an existing target before linking.
define ln_sf
	@source="$(1)"; target="$(2)"; \
	if [ ! -e "$$source" ]; then \
		printf "Missing source: %s\n" "$$source" >&2; exit 1; \
	fi; \
	mkdir -p "$$(dirname "$$target")"; \
	if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$source" ]; then \
		printf "  %s already linked\n" "$$target"; \
	else \
		if [ -e "$$target" ] || [ -L "$$target" ]; then \
			backup="$$target.bak.$$(date +%Y%m%d-%H%M%S)"; \
			mv "$$target" "$$backup"; \
			printf "  backed up %s → %s\n" "$$target" "$$backup"; \
		fi; \
		ln -s "$$source" "$$target"; \
		printf "  %s → %s\n" "$$target" "$$source"; \
	fi
endef

# Unlink helper: unlink_sf(source, target)
#   Removes only links created by this repository; regular files are preserved.
define unlink_sf
	@if [ -L "$(2)" ] && [ "$$(readlink "$(2)")" = "$(1)" ]; then \
		rm "$(2)"; \
		printf "  removed %s\n" "$(2)"; \
	fi
endef

.PHONY: help install link unlink relink packages firefox ghostty-link omarchy-link omarchy-apply omarchy-diff codex-agents-link codex-agents-unlink codex-memories-link codex-skills-link codex-skills-unlink

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

install: packages ## Install packages and activate the appropriate config set
	@if command -v omarchy >/dev/null 2>&1; then \
		if command -v omarchy-setup-zsh >/dev/null 2>&1 && ! grep -q 'exec zsh' "$(HOME)/.bashrc" 2>/dev/null; then \
			omarchy-setup-zsh; \
		fi; \
		$(MAKE) --no-print-directory omarchy-link; \
	else \
		$(MAKE) --no-print-directory link; \
	fi

# ── Symlink management ──────────────────────────────────────────────────────

link: ## Create all symlinks for current platform
	@echo "Linking common configs..."
	$(call ln_sf,$(DOTDIR)/config/zsh/.zshrc,$(HOME)/.zshrc)
	$(call ln_sf,$(DOTDIR)/config/ssh/config,$(HOME)/.ssh/config)
	$(call unlink_sf,$(DOTDIR)/config/tmux/tmux.conf,$(HOME)/.tmux.conf)
	$(call ln_sf,$(DOTDIR)/config/tmux/tmux.conf,$(HOME)/.config/tmux/tmux.conf)
	$(call ln_sf,$(DOTDIR)/config/nvim,$(HOME)/.config/nvim)
	$(call ln_sf,$(DOTDIR)/config/starship/starship.toml,$(HOME)/.config/starship.toml)
	$(call ln_sf,$(DOTDIR)/config/sioyek,$(HOME)/.config/sioyek)
	$(call ln_sf,$(DOTDIR)/config/uv,$(HOME)/.config/uv)
	$(call ln_sf,$(DOTDIR)/config/fastfetch,$(HOME)/.config/fastfetch)
	$(call ln_sf,$(DOTDIR)/config/git/config,$(HOME)/.config/git/config)
	$(call ln_sf,$(DOTDIR)/config/bat/config,$(HOME)/.config/bat/config)
	$(call ln_sf,$(DOTDIR)/config/atuin/config.toml,$(HOME)/.config/atuin/config.toml)
	$(call ln_sf,$(DOTDIR)/config/tuicr/config.toml,$(HOME)/.config/tuicr/config.toml)
	$(call ln_sf,$(DOTDIR)/config/zed/keymap.json,$(HOME)/.config/zed/keymap.json)
	$(call ln_sf,$(DOTDIR)/config/zed/settings.json,$(HOME)/.config/zed/settings.json)
	@echo "Linking Claude Code configs..."
	$(call ln_sf,$(DOTDIR)/config/claude/settings.json,$(HOME)/.claude/settings.json)
	$(call ln_sf,$(DOTDIR)/config/claude/commands,$(HOME)/.claude/commands)
	$(call ln_sf,$(DOTDIR)/config/claude/rules,$(HOME)/.claude/rules)
	$(call ln_sf,$(DOTDIR)/config/claude/scripts,$(HOME)/.claude/scripts)
	$(call ln_sf,$(DOTDIR)/config/claude/skills,$(HOME)/.claude/skills)
	@echo "Linking Codex configs..."
	$(call ln_sf,$(DOTDIR)/config/codex/AGENTS.md,$(CODEX_HOME)/AGENTS.md)
	$(call ln_sf,$(DOTDIR)/config/codex/config.toml,$(CODEX_HOME)/config.toml)
	$(call ln_sf,$(DOTDIR)/config/codex/hooks,$(CODEX_HOME)/hooks)
	$(call ln_sf,$(DOTDIR)/config/codex/rules/default.rules,$(CODEX_HOME)/rules/default.rules)
	@$(MAKE) --no-print-directory codex-memories-link
	@$(MAKE) --no-print-directory codex-agents-link
	@$(MAKE) --no-print-directory codex-skills-link
ifeq ($(UNAME_S),Linux)
	@echo "Linking Linux configs..."
	$(call ln_sf,$(DOTDIR)/config/bash/.bash_profile,$(HOME)/.bash_profile)
	@if ! command -v omarchy >/dev/null 2>&1; then $(MAKE) --no-print-directory ghostty-link; fi
	$(call ln_sf,$(DOTDIR)/config/cava,$(HOME)/.config/cava)
	$(call ln_sf,$(DOTDIR)/config/wallpapers,$(HOME)/Pictures/wallpapers)
	@$(MAKE) --no-print-directory omarchy-apply
else ifeq ($(UNAME_S),Darwin)
	@echo "Linking macOS configs..."
	$(call ln_sf,$(DOTDIR)/config/ghostty/macos,$(HOME)/.config/ghostty/config)
endif
	@echo "Done."

unlink: ## Remove all symlinks
	@echo "Removing symlinks..."
	$(call unlink_sf,$(DOTDIR)/config/zsh/.zshrc,$(HOME)/.zshrc)
	$(call unlink_sf,$(DOTDIR)/config/ssh/config,$(HOME)/.ssh/config)
	$(call unlink_sf,$(DOTDIR)/config/tmux/tmux.conf,$(HOME)/.tmux.conf)
	$(call unlink_sf,$(DOTDIR)/config/tmux/tmux.conf,$(HOME)/.config/tmux/tmux.conf)
	$(call unlink_sf,$(DOTDIR)/config/nvim,$(HOME)/.config/nvim)
	$(call unlink_sf,$(DOTDIR)/config/starship/starship.toml,$(HOME)/.config/starship.toml)
	$(call unlink_sf,$(DOTDIR)/config/sioyek,$(HOME)/.config/sioyek)
	$(call unlink_sf,$(DOTDIR)/config/uv,$(HOME)/.config/uv)
	$(call unlink_sf,$(DOTDIR)/config/fastfetch,$(HOME)/.config/fastfetch)
	$(call unlink_sf,$(DOTDIR)/config/git/config,$(HOME)/.config/git/config)
	$(call unlink_sf,$(DOTDIR)/config/bat/config,$(HOME)/.config/bat/config)
	$(call unlink_sf,$(DOTDIR)/config/atuin/config.toml,$(HOME)/.config/atuin/config.toml)
	$(call unlink_sf,$(DOTDIR)/config/tuicr/config.toml,$(HOME)/.config/tuicr/config.toml)
	$(call unlink_sf,$(DOTDIR)/config/zed/keymap.json,$(HOME)/.config/zed/keymap.json)
	$(call unlink_sf,$(DOTDIR)/config/zed/settings.json,$(HOME)/.config/zed/settings.json)
	$(call unlink_sf,$(DOTDIR)/config/claude/settings.json,$(HOME)/.claude/settings.json)
	$(call unlink_sf,$(DOTDIR)/config/claude/commands,$(HOME)/.claude/commands)
	$(call unlink_sf,$(DOTDIR)/config/claude/rules,$(HOME)/.claude/rules)
	$(call unlink_sf,$(DOTDIR)/config/claude/scripts,$(HOME)/.claude/scripts)
	$(call unlink_sf,$(DOTDIR)/config/claude/skills,$(HOME)/.claude/skills)
	$(call unlink_sf,$(DOTDIR)/config/codex/AGENTS.md,$(CODEX_HOME)/AGENTS.md)
	$(call unlink_sf,$(DOTDIR)/config/codex/config.toml,$(CODEX_HOME)/config.toml)
	$(call unlink_sf,$(DOTDIR)/config/codex/hooks,$(CODEX_HOME)/hooks)
	$(call unlink_sf,$(DOTDIR)/config/codex/rules/default.rules,$(CODEX_HOME)/rules/default.rules)
	$(call unlink_sf,$(CODEX_MEMORY_STATE_DIR),$(CODEX_HOME)/memories)
	@$(MAKE) --no-print-directory codex-agents-unlink
	@$(MAKE) --no-print-directory codex-skills-unlink
ifeq ($(UNAME_S),Linux)
	$(call unlink_sf,$(DOTDIR)/config/bash/.bash_profile,$(HOME)/.bash_profile)
	$(call unlink_sf,$(GHOSTTY_LINUX_CONFIG),$(HOME)/.config/ghostty/config)
	$(call unlink_sf,$(GHOSTTY_LINUX_OVERRIDES),$(HOME)/.config/ghostty/dotfiles.conf)
	$(call unlink_sf,$(DOTDIR)/config/cava,$(HOME)/.config/cava)
	$(call unlink_sf,$(DOTDIR)/config/wallpapers,$(HOME)/Pictures/wallpapers)
else ifeq ($(UNAME_S),Darwin)
	$(call unlink_sf,$(DOTDIR)/config/ghostty/macos,$(HOME)/.config/ghostty/config)
endif
	@echo "Done."

relink: unlink link ## Remove and recreate all symlinks

omarchy-link: ## Activate the curated personal overrides for Omarchy
	@echo "Linking personal Omarchy overrides..."
	$(call ln_sf,$(DOTDIR)/config/bash/.bash_profile,$(HOME)/.bash_profile)
	$(call ln_sf,$(DOTDIR)/config/zsh/.zshrc,$(HOME)/.zshrc)
	$(call ln_sf,$(DOTDIR)/config/atuin/config.toml,$(HOME)/.config/atuin/config.toml)
	$(call unlink_sf,$(DOTDIR)/config/tmux/tmux.conf,$(HOME)/.tmux.conf)
	$(call ln_sf,$(DOTDIR)/config/tmux/tmux.conf,$(HOME)/.config/tmux/tmux.conf)
	$(call ln_sf,$(DOTDIR)/config/nvim,$(HOME)/.config/nvim)
	@$(MAKE) --no-print-directory omarchy-apply
	@echo "Done. Omarchy still owns the rest of the desktop configuration."

ghostty-link:
	$(call ln_sf,$(GHOSTTY_LINUX_CONFIG),$(HOME)/.config/ghostty/config)
	$(call ln_sf,$(GHOSTTY_LINUX_OVERRIDES),$(HOME)/.config/ghostty/dotfiles.conf)

codex-agents-link: ## Link all Codex custom agents from this repo
	@echo "Linking Codex agents..."
	@mkdir -p "$(CODEX_HOME)/agents"
	@if [ -d "$(DOTDIR)/config/codex/agents" ]; then \
		for agent_file in $(DOTDIR)/config/codex/agents/*.toml; do \
			if [ -f "$$agent_file" ]; then \
				agent_name=$$(basename "$$agent_file"); \
				target="$(CODEX_HOME)/agents/$$agent_name"; \
				if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$agent_file" ]; then \
					printf "  %s already linked\n" "$$target"; \
				else \
					if [ -e "$$target" ] || [ -L "$$target" ]; then \
						backup="$$target.bak.$$(date +%Y%m%d-%H%M%S)"; mv "$$target" "$$backup"; \
						printf "  backed up %s → %s\n" "$$target" "$$backup"; \
					fi; \
					ln -s "$$agent_file" "$$target"; \
					printf "  %s → %s\n" "$$target" "$$agent_file"; \
				fi; \
			fi; \
		done; \
	fi

codex-agents-unlink: ## Remove Codex agent symlinks that came from this repo
	@echo "Removing Codex agents..."
	@if [ -d "$(DOTDIR)/config/codex/agents" ]; then \
		for agent_file in $(DOTDIR)/config/codex/agents/*.toml; do \
			if [ -f "$$agent_file" ]; then \
				agent_name=$$(basename "$$agent_file"); \
				target="$(CODEX_HOME)/agents/$$agent_name"; \
				if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$agent_file" ]; then rm "$$target"; fi; \
			fi; \
		done; \
	fi

codex-memories-link: ## Seed live Codex memories into state and link runtime path
	@echo "Linking Codex memories..."
	@mkdir -p "$(CODEX_HOME)" "$(CODEX_MEMORY_STATE_DIR)" "$(CODEX_MEMORY_STATE_DIR)/rollout_summaries"
	@if [ -e "$(CODEX_HOME)/memories" ] && [ ! -L "$(CODEX_HOME)/memories" ] && [ -z "$$(find "$(CODEX_MEMORY_STATE_DIR)" -mindepth 1 -maxdepth 1 -print -quit)" ]; then \
		cp -a "$(CODEX_HOME)/memories"/. "$(CODEX_MEMORY_STATE_DIR)"/; \
		printf "  migrated %s -> %s\n" "$(CODEX_HOME)/memories" "$(CODEX_MEMORY_STATE_DIR)"; \
	fi
	@for seed in "$(CODEX_MEMORY_SEED_DIR)"/*; do \
		if [ -f "$$seed" ]; then \
			name=$$(basename "$$seed"); \
			if [ ! -e "$(CODEX_MEMORY_STATE_DIR)/$$name" ]; then \
				cp "$$seed" "$(CODEX_MEMORY_STATE_DIR)/$$name"; \
				printf "  seeded %s\n" "$(CODEX_MEMORY_STATE_DIR)/$$name"; \
			fi; \
		fi; \
	done
	@if [ -L "$(CODEX_HOME)/memories" ] && [ "$$(readlink "$(CODEX_HOME)/memories")" = "$(CODEX_MEMORY_STATE_DIR)" ]; then \
		printf "  %s already linked\n" "$(CODEX_HOME)/memories"; \
	else \
		if [ -e "$(CODEX_HOME)/memories" ] || [ -L "$(CODEX_HOME)/memories" ]; then \
			backup="$(CODEX_HOME)/memories.bak.$$(date +%Y%m%d-%H%M%S)"; \
			mv "$(CODEX_HOME)/memories" "$$backup"; \
			printf "  backed up %s → %s\n" "$(CODEX_HOME)/memories" "$$backup"; \
		fi; \
		ln -s "$(CODEX_MEMORY_STATE_DIR)" "$(CODEX_HOME)/memories"; \
		printf "  %s → %s\n" "$(CODEX_HOME)/memories" "$(CODEX_MEMORY_STATE_DIR)"; \
	fi

codex-skills-link: ## Link all Codex skills from this repo
	@echo "Linking Codex skills..."
	@mkdir -p "$(CODEX_HOME)/skills"
	@for skill_dir in $(DOTDIR)/config/codex/skills/*; do \
		if [ -d "$$skill_dir" ] && [ -f "$$skill_dir/SKILL.md" ]; then \
			skill_name=$$(basename "$$skill_dir"); \
			target="$(CODEX_HOME)/skills/$$skill_name"; \
			if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$skill_dir" ]; then \
				printf "  %s already linked\n" "$$target"; \
			else \
				if [ -e "$$target" ] || [ -L "$$target" ]; then \
					backup="$$target.bak.$$(date +%Y%m%d-%H%M%S)"; mv "$$target" "$$backup"; \
					printf "  backed up %s → %s\n" "$$target" "$$backup"; \
				fi; \
				ln -s "$$skill_dir" "$$target"; \
				printf "  %s → %s\n" "$$target" "$$skill_dir"; \
			fi; \
		fi; \
	done

codex-skills-unlink: ## Remove Codex skill symlinks from this repo
	@echo "Removing Codex skills..."
	@if [ -d "$(DOTDIR)/config/codex/skills" ]; then \
		for skill_dir in $(DOTDIR)/config/codex/skills/*; do \
			if [ -d "$$skill_dir" ] && [ -f "$$skill_dir/SKILL.md" ]; then \
				skill_name=$$(basename "$$skill_dir"); \
				target="$(CODEX_HOME)/skills/$$skill_name"; \
				if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$skill_dir" ]; then rm "$$target"; fi; \
			fi; \
		done; \
	fi

# ── Package management ──────────────────────────────────────────────────────

packages: ## Install packages for current platform
ifeq ($(UNAME_S),Linux)
	@if command -v omarchy >/dev/null 2>&1; then \
		set -e; \
		echo "Installing Arch packages through Omarchy..."; \
		omarchy pkg add $$(grep -vE '^\s*(#|$$)' packages/arch.txt); \
		omarchy pkg add $$(grep -vE '^\s*(#|$$)' packages/omarchy.txt); \
		omarchy pkg aur add $$(grep -vE '^\s*(#|$$)' packages/arch-aur.txt); \
	else \
		echo "Installing Arch packages via yay..."; \
		yay -S --needed $$(grep -vE '^\s*(#|$$)' packages/arch.txt packages/arch-aur.txt); \
	fi
else ifeq ($(UNAME_S),Darwin)
	@echo "Installing Homebrew packages..."
	grep -vE '^\s*(#|$$)' packages/brew.txt | xargs brew install
endif

# ── Special targets ─────────────────────────────────────────────────────────

omarchy-apply: ## Copy tracked Omarchy overrides into ~/.config with backups
ifeq ($(UNAME_S),Linux)
	@if command -v omarchy >/dev/null 2>&1; then \
		set -e; \
		apply_file() { \
			source="$$1"; target="$$2"; label="$$3"; \
			if [ ! -f "$$source" ]; then printf "Missing source: %s\n" "$$source" >&2; return 1; fi; \
			mkdir -p "$$(dirname "$$target")"; \
			if [ ! -L "$$target" ] && cmp -s "$$source" "$$target"; then \
				printf "  %s already current\n" "$$label"; return 0; \
			fi; \
			if [ -L "$$target" ]; then \
				backup="$$target.bak.$$(date +%Y%m%d-%H%M%S)"; mv "$$target" "$$backup"; \
				printf "  backed up %s → %s\n" "$$target" "$$backup"; \
			elif [ -f "$$target" ]; then \
				backup="$$target.bak.$$(date +%Y%m%d-%H%M%S)"; cp -p "$$target" "$$backup"; \
				printf "  backed up %s → %s\n" "$$target" "$$backup"; \
			elif [ -e "$$target" ]; then \
				printf "Refusing to replace non-file target: %s\n" "$$target" >&2; return 1; \
			fi; \
			install -m 644 "$$source" "$$target"; \
			printf "  applied %s → %s\n" "$$source" "$$target"; \
		}; \
		apply_file "$(GHOSTTY_LINUX_CONFIG)" "$(HOME)/.config/ghostty/config" "Ghostty base overlay"; \
		apply_file "$(GHOSTTY_LINUX_OVERRIDES)" "$(HOME)/.config/ghostty/dotfiles.conf" "Ghostty personal override"; \
		apply_file "$(OMARCHY_MONITORS)" "$(HOME)/.config/hypr/monitors.lua" "Omarchy monitor override"; \
		apply_file "$(OMARCHY_AUTOSTART)" "$(HOME)/.config/hypr/autostart.lua" "Omarchy autostart override"; \
		apply_file "$(OMARCHY_CODEX_WRAPPER)" "$(HOME)/.local/bin/codex" "Codex compatibility wrapper"; \
		chmod 755 "$(HOME)/.local/bin/codex"; \
		omarchy restart terminal >/dev/null; \
		if [ -n "$${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then \
			hyprctl reload >/dev/null; \
			errors="$$(hyprctl configerrors)"; \
			if [ -n "$$errors" ]; then printf "%s\n" "$$errors" >&2; exit 1; fi; \
		fi; \
	else \
		echo "Omarchy not detected; skipping Omarchy overrides."; \
	fi
endif

omarchy-diff: ## Compare tracked Omarchy overrides with the live files
ifeq ($(UNAME_S),Linux)
	@diff -u "$(GHOSTTY_LINUX_CONFIG)" "$(HOME)/.config/ghostty/config" || true
	@diff -u "$(GHOSTTY_LINUX_OVERRIDES)" "$(HOME)/.config/ghostty/dotfiles.conf" || true
	@diff -u "$(OMARCHY_MONITORS)" "$(HOME)/.config/hypr/monitors.lua" || true
	@diff -u "$(OMARCHY_AUTOSTART)" "$(HOME)/.config/hypr/autostart.lua" || true
	@diff -u "$(OMARCHY_CODEX_WRAPPER)" "$(HOME)/.local/bin/codex" || true
endif

firefox: ## Symlink Firefox userChrome.css (Linux, auto-detects profile)
ifeq ($(UNAME_S),Linux)
	@profile=$$(ls -d $(HOME)/.mozilla/firefox/*.default-release 2>/dev/null | head -1); \
	if [ -n "$$profile" ]; then \
		source="$(DOTDIR)/config/firefox/chrome/userChrome.css"; target="$$profile/chrome/userChrome.css"; \
		mkdir -p "$$(dirname "$$target")"; \
		if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$source" ]; then \
			printf "  %s already linked\n" "$$target"; \
		else \
			if [ -e "$$target" ] || [ -L "$$target" ]; then \
				backup="$$target.bak.$$(date +%Y%m%d-%H%M%S)"; mv "$$target" "$$backup"; \
				printf "  backed up %s → %s\n" "$$target" "$$backup"; \
			fi; \
			ln -s "$$source" "$$target"; \
			printf "  %s → %s\n" "$$target" "$$source"; \
		fi; \
	else \
		echo "No Firefox profile found. Run Firefox first, then retry."; \
	fi
endif
