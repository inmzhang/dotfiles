# ============================================================================
# Dotfiles management via Makefile symlinks
# ============================================================================

DOTDIR  := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)
UNAME_S := $(shell uname -s)

# Symlink helper: ln_sf(source, target)
#   Creates parent dirs, removes existing target, creates symlink
define ln_sf
	mkdir -p $(dir $(2)) && rm -rf $(2) && ln -sfn $(1) $(2) && printf "  %s → %s\n" "$(2)" "$(1)"
endef

.PHONY: help install link unlink relink packages firefox hyprland-setup

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
	@echo "Linking Claude Code configs..."
	$(call ln_sf,$(DOTDIR)/config/claude/settings.json,$(HOME)/.claude/settings.json)
	$(call ln_sf,$(DOTDIR)/config/claude/scripts,$(HOME)/.claude/scripts)
	$(call ln_sf,$(DOTDIR)/config/claude/skills,$(HOME)/.claude/skills)
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
	rm -f $(HOME)/.claude/settings.json
	rm -f $(HOME)/.claude/scripts
	rm -f $(HOME)/.claude/skills
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

# ── Package management ──────────────────────────────────────────────────────

packages: ## Install packages for current platform
ifeq ($(UNAME_S),Linux)
	@echo "Installing Arch packages via yay..."
	yay -S --needed $$(grep -vE '^\s*(#|$$)' packages/arch.txt)
else ifeq ($(UNAME_S),Darwin)
	@echo "Installing Homebrew packages..."
	xargs brew install < packages/brew.txt
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
