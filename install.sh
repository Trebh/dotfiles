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

    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"

    if command -v brew &>/dev/null; then
        command -v nvim &>/dev/null || brew install neovim
        command -v hx &>/dev/null || brew install helix
    else
        # Linux — download prebuilt binaries from GitHub releases (works on any distro)
        local raw_arch
        raw_arch="$(uname -m)"

        # Neovim uses "arm64" while uname reports "aarch64"
        local nvim_arch="$raw_arch"
        case "$raw_arch" in
            aarch64) nvim_arch="arm64" ;;
        esac

        # Neovim
        if ! command -v nvim &>/dev/null; then
            echo "    Downloading Neovim (arch: $nvim_arch)..."
            local nvim_url="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${nvim_arch}.tar.gz"
            curl -fsSL "$nvim_url" | tar xz -C /tmp
            cp -r /tmp/nvim-linux-${nvim_arch}/* "$HOME/.local/"
            rm -rf /tmp/nvim-linux-${nvim_arch}
            echo "    Neovim installed to $bin_dir/nvim"
        fi

        # Helix — uses aarch64/x86_64 directly
        if ! command -v hx &>/dev/null; then
            echo "    Downloading Helix (arch: $raw_arch)..."
            local hx_tag
            hx_tag="$(curl -fsSL https://api.github.com/repos/helix-editor/helix/releases/latest | grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4)"
            local hx_version="${hx_tag}"
            local hx_url="https://github.com/helix-editor/helix/releases/download/${hx_tag}/helix-${hx_version}-${raw_arch}-linux.tar.xz"
            curl -fsSL "$hx_url" | tar xJ -C /tmp
            cp /tmp/helix-${hx_version}-${raw_arch}-linux/hx "$bin_dir/"
            mkdir -p "$HOME/.local/lib"
            cp -r /tmp/helix-${hx_version}-${raw_arch}-linux/runtime "$HOME/.local/lib/helix-runtime" 2>/dev/null || true
            export HELIX_RUNTIME="$HOME/.local/lib/helix-runtime"
            rm -rf /tmp/helix-${hx_version}-${raw_arch}-linux
            echo "    Helix installed to $bin_dir/hx"
        fi
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
