#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing dotfiles from $DOTFILES_DIR"

# ---------------------------------------------------------------------------
# 1. Install editors (Neovim + Helix)
# ---------------------------------------------------------------------------
install_editors() {
    if command -v nvim &>/dev/null && command -v hx &>/dev/null; then
        echo "==> Neovim and Helix already installed, skipping"
        return
    fi

    echo "==> Installing Neovim and Helix..."

    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        # Neovim — use the stable PPA for a recent version
        if ! command -v nvim &>/dev/null; then
            sudo apt-get install -y -qq software-properties-common
            sudo add-apt-repository -y ppa:neovim-ppa/stable
            sudo apt-get update -qq
            sudo apt-get install -y -qq neovim
        fi
        # Helix
        if ! command -v hx &>/dev/null; then
            sudo add-apt-repository -y ppa:maveonair/helix-editor
            sudo apt-get update -qq
            sudo apt-get install -y -qq helix
        fi
    elif command -v brew &>/dev/null; then
        command -v nvim &>/dev/null || brew install neovim
        command -v hx &>/dev/null || brew install helix
    else
        echo "WARN: No supported package manager found. Install Neovim and Helix manually."
    fi
}

# ---------------------------------------------------------------------------
# 2. Symlink config directories
# ---------------------------------------------------------------------------
link_config() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "    Backing up existing $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    echo "    Linked $src -> $dst"
}

setup_configs() {
    echo "==> Linking config files..."
    link_config "$DOTFILES_DIR/config/nvim"  "$HOME/.config/nvim"
    link_config "$DOTFILES_DIR/config/helix" "$HOME/.config/helix"
}

# ---------------------------------------------------------------------------
# 3. Shell setup
# ---------------------------------------------------------------------------
setup_shell() {
    echo "==> Setting up shell aliases..."
    local marker="# >>> dotfiles <<<"
    local rc="$HOME/.zshrc"

    # Create .zshrc if it doesn't exist
    touch "$rc"

    # Only append if not already sourced
    if ! grep -qF "$marker" "$rc" 2>/dev/null; then
        cat >> "$rc" <<EOF

$marker
[ -f "$DOTFILES_DIR/shell/aliases.sh" ] && source "$DOTFILES_DIR/shell/aliases.sh"
# Source local secrets (not tracked by git)
[ -f "\$HOME/.zshrc.local" ] && source "\$HOME/.zshrc.local"
# <<< dotfiles >>>
EOF
        echo "    Added dotfiles source block to $rc"
    else
        echo "    Shell already configured, skipping"
    fi
}

# ---------------------------------------------------------------------------
# 4. Git config (includes, so it layers on top of existing config)
# ---------------------------------------------------------------------------
setup_git() {
    echo "==> Setting up git config..."
    git config --global include.path "$DOTFILES_DIR/git/gitconfig"
    echo "    Added git include for $DOTFILES_DIR/git/gitconfig"
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
install_editors
setup_configs
setup_shell
setup_git

echo "==> Dotfiles installed successfully!"
