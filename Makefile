# ============================================================================
# Dotfiles management via Makefile symlinks
# ============================================================================

DOTDIR  := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)
UNAME_S := $(shell uname -s)
CODEX_HOME := $(HOME)/.codex
CODEX_MEMORY_SEED_DIR := $(DOTDIR)/config/codex/memories/seed
CODEX_MEMORY_STATE_DIR := $(HOME)/.local/state/codex/memories

# Symlink helper: ln_sf(source, target)
#   Creates parent dirs, removes existing target, creates symlink
define ln_sf
	mkdir -p $(dir $(2)) && rm -rf $(2) && ln -sfn $(1) $(2) && printf "  %s → %s\n" "$(2)" "$(1)"
endef

.PHONY: help install link unlink relink packages firefox hyprland-setup codex-agents-link codex-agents-unlink codex-memories-link codex-skills-link codex-skills-unlink

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

install: packages link ## Full setup: install packages + create symlinks

# ── Symlink management ──────────────────────────────────────────────────────

link: ## Create all symlinks for current platform
	@echo "Linking common configs..."
	$(call ln_sf,$(DOTDIR)/config/zsh/.zshrc,$(HOME)/.zshrc)
	$(call ln_sf,$(DOTDIR)/config/tmux/tmux.conf,$(HOME)/.tmux.conf)
	$(call ln_sf,$(DOTDIR)/config/nvim,$(HOME)/.config/nvim)
	$(call ln_sf,$(DOTDIR)/config/starship/starship.toml,$(HOME)/.config/starship.toml)
	$(call ln_sf,$(DOTDIR)/config/sioyek,$(HOME)/.config/sioyek)
	$(call ln_sf,$(DOTDIR)/config/uv,$(HOME)/.config/uv)
	$(call ln_sf,$(DOTDIR)/config/fastfetch,$(HOME)/.config/fastfetch)
	$(call ln_sf,$(DOTDIR)/config/git/config,$(HOME)/.config/git/config)
	$(call ln_sf,$(DOTDIR)/config/bat/config,$(HOME)/.config/bat/config)
	$(call ln_sf,$(DOTDIR)/config/atuin/config.toml,$(HOME)/.config/atuin/config.toml)
	$(call ln_sf,$(DOTDIR)/config/tuicr/config.toml,$(HOME)/.config/tuicr/config.toml)
	@echo "Linking Claude Code configs..."
	$(call ln_sf,$(DOTDIR)/config/claude/settings.json,$(HOME)/.claude/settings.json)
	$(call ln_sf,$(DOTDIR)/config/claude/agents,$(HOME)/.claude/agents)
	$(call ln_sf,$(DOTDIR)/config/claude/commands,$(HOME)/.claude/commands)
	$(call ln_sf,$(DOTDIR)/config/claude/hooks,$(HOME)/.claude/hooks)
	$(call ln_sf,$(DOTDIR)/config/claude/rules,$(HOME)/.claude/rules)
	$(call ln_sf,$(DOTDIR)/config/claude/scripts,$(HOME)/.claude/scripts)
	$(call ln_sf,$(DOTDIR)/config/claude/skills,$(HOME)/.claude/skills)
	@echo "Linking Codex configs..."
	$(call ln_sf,$(DOTDIR)/config/codex/AGENTS.md,$(CODEX_HOME)/AGENTS.md)
	$(call ln_sf,$(DOTDIR)/config/codex/RTK.md,$(CODEX_HOME)/RTK.md)
	$(call ln_sf,$(DOTDIR)/config/codex/config.toml,$(CODEX_HOME)/config.toml)
	$(call ln_sf,$(DOTDIR)/config/codex/rules/default.rules,$(CODEX_HOME)/rules/default.rules)
	@$(MAKE) --no-print-directory codex-memories-link
	@$(MAKE) --no-print-directory codex-agents-link
	@$(MAKE) --no-print-directory codex-skills-link
ifeq ($(UNAME_S),Linux)
	@echo "Linking Linux configs..."
	$(call ln_sf,$(DOTDIR)/config/hyprland/config,$(HOME)/.config/hypr)
	$(call ln_sf,$(DOTDIR)/config/waybar,$(HOME)/.config/waybar)
	$(call ln_sf,$(DOTDIR)/config/rofi,$(HOME)/.config/rofi)
	$(call ln_sf,$(DOTDIR)/config/ghostty/linux,$(HOME)/.config/ghostty/config)
	$(call ln_sf,$(DOTDIR)/config/ags,$(HOME)/.config/ags)
	$(call ln_sf,$(DOTDIR)/config/cava,$(HOME)/.config/cava)
	$(call ln_sf,$(DOTDIR)/config/qt5ct,$(HOME)/.config/qt5ct)
	$(call ln_sf,$(DOTDIR)/config/qt6ct,$(HOME)/.config/qt6ct)
	$(call ln_sf,$(DOTDIR)/config/wallust,$(HOME)/.config/wallust)
	$(call ln_sf,$(DOTDIR)/config/wlogout,$(HOME)/.config/wlogout)
	$(call ln_sf,$(DOTDIR)/config/wallpapers,$(HOME)/Pictures/wallpapers)
	$(call ln_sf,$(DOTDIR)/config/Kvantum,$(HOME)/.config/Kvantum)
	$(call ln_sf,$(DOTDIR)/config/swappy,$(HOME)/.config/swappy)
else ifeq ($(UNAME_S),Darwin)
	@echo "Linking macOS configs..."
	$(call ln_sf,$(DOTDIR)/config/ghostty/macos,$(HOME)/.config/ghostty/config)
endif
	@echo "Done."

unlink: ## Remove all symlinks
	@echo "Removing symlinks..."
	rm -f $(HOME)/.zshrc
	rm -f $(HOME)/.tmux.conf
	rm -f $(HOME)/.config/nvim
	rm -f $(HOME)/.config/starship.toml
	rm -f $(HOME)/.config/sioyek
	rm -f $(HOME)/.config/uv
	rm -f $(HOME)/.config/fastfetch
	rm -f $(HOME)/.config/git/config
	rm -f $(HOME)/.config/bat/config
	rm -f $(HOME)/.config/atuin/config.toml
	rm -f $(HOME)/.config/tuicr/config.toml
	rm -f $(HOME)/.claude/settings.json
	rm -f $(HOME)/.claude/agents
	rm -f $(HOME)/.claude/commands
	rm -f $(HOME)/.claude/hooks
	rm -f $(HOME)/.claude/rules
	rm -f $(HOME)/.claude/scripts
	rm -f $(HOME)/.claude/skills
	rm -f $(CODEX_HOME)/AGENTS.md
	rm -f $(CODEX_HOME)/RTK.md
	rm -f $(CODEX_HOME)/config.toml
	rm -f $(CODEX_HOME)/rules/default.rules
	rm -f $(CODEX_HOME)/memories
	@$(MAKE) --no-print-directory codex-agents-unlink
	@$(MAKE) --no-print-directory codex-skills-unlink
ifeq ($(UNAME_S),Linux)
	rm -f $(HOME)/.config/hypr
	rm -f $(HOME)/.config/waybar
	rm -f $(HOME)/.config/rofi
	rm -f $(HOME)/.config/ghostty/config
	rm -f $(HOME)/.config/ags
	rm -f $(HOME)/.config/cava
	rm -f $(HOME)/.config/qt5ct
	rm -f $(HOME)/.config/qt6ct
	rm -f $(HOME)/.config/wallust
	rm -f $(HOME)/.config/wlogout
	rm -f $(HOME)/Pictures/wallpapers
	rm -f $(HOME)/.config/Kvantum
	rm -f $(HOME)/.config/swappy
else ifeq ($(UNAME_S),Darwin)
	rm -f $(HOME)/.config/ghostty/config
endif
	@echo "Done."

relink: unlink link ## Remove and recreate all symlinks

codex-agents-link: ## Link all Codex custom agents from this repo
	@echo "Linking Codex agents..."
	@mkdir -p $(CODEX_HOME)/agents
	@if [ -d "$(DOTDIR)/config/codex/agents" ]; then \
		for agent_file in $(DOTDIR)/config/codex/agents/*.toml; do \
			if [ -f "$$agent_file" ]; then \
				agent_name=$$(basename "$$agent_file"); \
				rm -rf "$(CODEX_HOME)/agents/$$agent_name"; \
				ln -sfn "$$agent_file" "$(CODEX_HOME)/agents/$$agent_name"; \
				printf "  %s → %s\n" "$(CODEX_HOME)/agents/$$agent_name" "$$agent_file"; \
			fi; \
		done; \
	fi

codex-agents-unlink: ## Remove Codex agent symlinks that came from this repo
	@echo "Removing Codex agents..."
	@if [ -d "$(DOTDIR)/config/codex/agents" ]; then \
		for agent_file in $(DOTDIR)/config/codex/agents/*.toml; do \
			if [ -f "$$agent_file" ]; then \
				agent_name=$$(basename "$$agent_file"); \
				rm -f "$(CODEX_HOME)/agents/$$agent_name"; \
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
	@rm -rf "$(CODEX_HOME)/memories"
	@ln -sfn "$(CODEX_MEMORY_STATE_DIR)" "$(CODEX_HOME)/memories"
	@printf "  %s → %s\n" "$(CODEX_HOME)/memories" "$(CODEX_MEMORY_STATE_DIR)"

codex-skills-link: ## Link all Codex skills from this repo
	@echo "Linking Codex skills..."
	@mkdir -p $(CODEX_HOME)/skills
	@for skill_dir in $(DOTDIR)/config/codex/skills/*; do \
		if [ -d "$$skill_dir" ] && [ -f "$$skill_dir/SKILL.md" ]; then \
			skill_name=$$(basename "$$skill_dir"); \
			rm -rf "$(CODEX_HOME)/skills/$$skill_name"; \
			ln -sfn "$$skill_dir" "$(CODEX_HOME)/skills/$$skill_name"; \
			printf "  %s → %s\n" "$(CODEX_HOME)/skills/$$skill_name" "$$skill_dir"; \
		fi; \
	done

codex-skills-unlink: ## Remove Codex skill symlinks from this repo
	@echo "Removing Codex skills..."
	@if [ -d "$(DOTDIR)/config/codex/skills" ]; then \
		for skill_dir in $(DOTDIR)/config/codex/skills/*; do \
			if [ -d "$$skill_dir" ] && [ -f "$$skill_dir/SKILL.md" ]; then \
				skill_name=$$(basename "$$skill_dir"); \
				rm -rf "$(CODEX_HOME)/skills/$$skill_name"; \
			fi; \
		done; \
	fi

# ── Package management ──────────────────────────────────────────────────────

packages: ## Install packages for current platform
ifeq ($(UNAME_S),Linux)
	@echo "Installing Arch packages via yay..."
	yay -S --needed $$(grep -vE '^\s*(#|$$)' packages/arch.txt)
else ifeq ($(UNAME_S),Darwin)
	@echo "Installing Homebrew packages..."
	grep -vE '^\s*(#|$$)' packages/brew.txt | xargs brew install
endif

# ── Special targets ─────────────────────────────────────────────────────────

firefox: ## Symlink Firefox userChrome.css (Linux, auto-detects profile)
ifeq ($(UNAME_S),Linux)
	@profile=$$(ls -d $(HOME)/.mozilla/firefox/*.default-release 2>/dev/null | head -1); \
	if [ -n "$$profile" ]; then \
		mkdir -p "$$profile/chrome"; \
		ln -sfn "$(DOTDIR)/config/firefox/chrome/userChrome.css" "$$profile/chrome/userChrome.css"; \
		echo "  $$profile/chrome/userChrome.css → config/firefox/chrome/userChrome.css"; \
	else \
		echo "No Firefox profile found. Run Firefox first, then retry."; \
	fi
endif

hyprland-setup: ## Bootstrap Hyprland desktop via JaKooLit installer (Arch only)
ifeq ($(UNAME_S),Linux)
	@if [ ! -d "$(HOME)/Arch-Hyprland" ]; then \
		git clone --depth=1 https://github.com/JaKooLit/Arch-Hyprland.git $(HOME)/Arch-Hyprland; \
	fi
	cd $(HOME)/Arch-Hyprland && chmod +x install.sh && ./install.sh
endif
