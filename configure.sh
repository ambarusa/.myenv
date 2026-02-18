#!/bin/bash
set -e

# ============================================================================
# ZSH Configuration Setup Script
# Installs dependencies, sets up Oh-My-Zsh, and configures plugins & themes
# ============================================================================

# Verify running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo."
    exit 1
fi

# Get the original user who called sudo
ORIGINAL_USER="${SUDO_USER:-$(who -m | awk '{print $1}')}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=$(eval echo "~$ORIGINAL_USER")

echo "Setting up zsh environment for user: $ORIGINAL_USER"
echo "Script directory: $SCRIPT_DIR"
echo "Target directory: $TARGET_DIR"
echo

# ============================================================================
# Helper Functions
# ============================================================================

# Install a package via apt or snap
install_package() {
    local pkg="$1"
    
    # Check if already installed
    if command -v "$pkg" >/dev/null 2>&1; then
        echo "✓ $pkg is already installed."
        return 0
    fi
    
    echo "→ Installing $pkg..."
    if apt-get install -qq -y "$pkg" 2>/dev/null; then
        echo "✓ $pkg installed via apt."
        return 0
    fi
    
    if snap install "$pkg" 2>/dev/null; then
        echo "✓ $pkg installed via snap."
        return 0
    fi
    
    echo "✗ Failed to install $pkg."
    return 1
}

# Install Oh-My-Zsh
install_ohmyzsh() {
    local ohmyzsh_dir="$TARGET_DIR/.oh-my-zsh"
    
    if [ -d "$ohmyzsh_dir" ]; then
        echo "Warning: $ohmyzsh_dir already exists."
        read -p "Remove it to continue? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            echo "Aborted. Please backup $ohmyzsh_dir and try again."
            return 1
        fi
        rm -rf "$ohmyzsh_dir"
    fi
    
    echo "→ Installing Oh-My-Zsh..."
    su -l "$ORIGINAL_USER" -c 'sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended' >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✓ Oh-My-Zsh installed successfully."
        return 0
    else
        echo "✗ Failed to install Oh-My-Zsh."
        return 1
    fi
}

# Create symbolic links for directories and files
link_config() {
    local source="$1"
    local dest_dir="$2"
    local link_name="${3:-$(basename "$source")}"
    local dest="$dest_dir/$link_name"
    
    if [ ! -e "$source" ]; then
        echo "✗ Source not found: $source"
        return 1
    fi
    
    # Remove existing link/file
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        rm -rf "$dest"
    fi
    
    # Create parent directory if needed
    mkdir -p "$dest_dir"
    
    # Create symlink as the original user
    if su - "$ORIGINAL_USER" -c "ln -s '$source' '$dest'" 2>/dev/null; then
        echo "✓ Linked $(basename "$source") to $dest_dir"
        return 0
    else
        echo "✗ Failed to link $(basename "$source")"
        return 1
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

echo "Updating package lists..."
if ! apt-get update -qq; then
    echo "✗ Failed to update package lists."
    exit 1
fi

# Install dependencies
echo
echo "Installing dependencies..."
install_package zsh || exit 1
install_package tmux || exit 1
install_package bat || exit 1
install_package lsd || exit 1
install_package neofetch || exit 1

# Install and configure Oh-My-Zsh
echo
install_ohmyzsh || exit 1

# Setup themes and plugins
echo
echo "Configuring themes and plugins..."
link_config "$SCRIPT_DIR/powerlevel10k" "$TARGET_DIR/.oh-my-zsh/custom/themes" || exit 1
link_config "$SCRIPT_DIR/zsh-autosuggestions" "$TARGET_DIR/.oh-my-zsh/custom/plugins" || exit 1
link_config "$SCRIPT_DIR/zsh-history-substring-search" "$TARGET_DIR/.oh-my-zsh/custom/plugins" || exit 1
link_config "$SCRIPT_DIR/zsh-syntax-highlighting" "$TARGET_DIR/.oh-my-zsh/custom/plugins" || exit 1

# Setup configuration files
echo
echo "Installing configuration files..."
link_config "$SCRIPT_DIR/.p10k.zsh" "$TARGET_DIR" || exit 1
link_config "$SCRIPT_DIR/.zshrc" "$TARGET_DIR" || exit 1
link_config "$SCRIPT_DIR/.tmux.conf" "$TARGET_DIR" || exit 1

# Change default shell to zsh
echo
echo "→ Setting zsh as default shell..."
chsh -s "$(which zsh)" "$ORIGINAL_USER" && echo "✓ Default shell changed to zsh" || echo "✗ Failed to change default shell"

# Success message
echo
echo "✓ Setup completed successfully!"
echo
read -p "Switch to zsh now? (y/n): " switch_shell

if [[ "$switch_shell" == "y" || "$switch_shell" == "Y" ]]; then
    su -l "$ORIGINAL_USER" -c "zsh"
else
    echo "You can switch to zsh later by running: zsh"
fi

exit 0

