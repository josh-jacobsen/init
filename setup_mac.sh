#!/bin/bash

# Download the file and save it. 
# Then make executable with: chmod +x setup_mac.sh 
# Then run with ./setup_mac.sh

# Exit on error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to log messages
log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S"): $1"
}

# Function to handle errors
handle_error() {
    log "Error occurred in line $1"
    exit 1
}

# Function to install cask with silent skipping of existing installations
install_cask() {
    local cask_name="$1"
    local app_name="$2"
    
    if [ -d "/Applications/${app_name}.app" ]; then
        log "${app_name} already installed, skipping..."
    else
        brew install --cask "$cask_name" || log "Failed to install ${cask_name}"
    fi
}

trap 'handle_error $LINENO' ERR

# Detect CPU architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

log "Starting setup for $ARCH architecture"

# Install Homebrew if not already installed
if ! command_exists brew; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH based on architecture
    if [ "$ARCH" = "arm64" ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    log "Homebrew already installed"
fi

# Check if Fish shell is already installed
if command_exists fish; then
    log "Fish shell is already installed"
    FISH_PATH=$(which fish)
else
    # Install Fish shell
    log "Installing Fish shell..."
    brew install fish
    FISH_PATH=$(which fish)
fi

log "Fish shell path: $FISH_PATH"

# Check if Fish is already in allowed shells
if grep -q "$FISH_PATH" /etc/shells; then
    log "Fish shell is already in allowed shells"
else
    log "Adding Fish to allowed shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

# Check if Fish is already the default shell
if [ "$SHELL" = "$FISH_PATH" ]; then
    log "Fish is already the default shell"
else
    log "Setting Fish as default shell..."
    chsh -s "$FISH_PATH"
fi

# Install asdf
log "Installing asdf..."
if [ ! -d ~/.asdf ]; then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
fi

# Install build dependencies
log "Installing build dependencies..."
brew install ninja cmake gettext curl ripgrep fzf

# Install Node.js using asdf
log "Installing Node.js..."
source ~/.asdf/asdf.sh
asdf plugin add nodejs || true
asdf install nodejs 20.18.1
asdf global nodejs 20.18.1

# Install Python using asdf
log "Installing Python..."
asdf plugin add python || true
asdf install python 3.12.8
asdf global python 3.12.8

# Install Terraform using asdf
log "Installing Terraform..."
asdf plugin add terraform || true
asdf install terraform 1.10.3
asdf global terraform 1.10.3

# Install Neovim from source
log "Installing Neovim..."
if [ ! -d ~/neovim ]; then
    git clone https://github.com/neovim/neovim ~/neovim
    cd ~/neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd ~
fi

# Install additional tools via Brew
log "Installing additional tools..."
BREW_PACKAGES="stow lazygit gh awscli tmux fd"
for package in $BREW_PACKAGES; do
    brew install "$package"
done

# Install cask applications
log "Installing cask applications..."
install_cask "aws-vault" "aws-vault"
install_cask "raycast" "Raycast"
install_cask "visual-studio-code" "Visual Studio Code"
install_cask "shottr" "Shottr"
install_cask "ghostty" "Ghostty"
install_cask "lastpass" "LastPass"
install_cask "1password" "1Password"
install_cask "firefox" "Firefox"

# Install Aerospace
brew tap nikitabobko/tap
brew install --cask aerospace

# Clone and setup dotfiles
log "Setting up dotfiles..."
if [ ! -d ~/dotfiles ]; then
    log "Cloning dotfiles repository..."
    git clone https://github.com/josh-jacobsen/dotfiles.git ~/dotfiles
fi

cd ~/dotfiles
# Get all top-level directories and stow each one
for dir in */; do
    dir=${dir%/}  # Remove trailing slash
    log "Stowing $dir..."
    # Remove existing stow directory if it exists
    stow -D "$dir" 2>/dev/null || true
    # Restow without --adopt to preserve dotfiles
    stow -v "$dir" || log "Failed to stow $dir"
done
cd ~

# Configure Fish shell after dotfiles are stowed
log "Configuring Fish shell paths..."
FISH_CONFIG=~/.config/fish/config.fish

# Function to safely add line to fish config if not already present
add_to_fish_config() {
    local line="$1"
    if [ -f "$FISH_CONFIG" ]; then
        if ! grep -Fq "$line" "$FISH_CONFIG"; then
            log "Adding to Fish config: $line"
            echo "$line" >> "$FISH_CONFIG"
        else
            log "Already in Fish config: $line"
        fi
    else
        log "Fish config file not found, creating and adding: $line"
        mkdir -p ~/.config/fish
        echo "$line" >> "$FISH_CONFIG"
    fi
}

# Add Homebrew path if not already present
add_to_fish_config "fish_add_path $HOMEBREW_PREFIX/bin"

# Add asdf source if asdf is installed and not already present
if [ -d ~/.asdf ]; then
    add_to_fish_config "source ~/.asdf/asdf.fish"
fi

# Check and install catppuccin for tmux
CATPPUCCIN_DIR="$HOME/.config/tmux/plugins/catppuccin"
if [ -d "$CATPPUCCIN_DIR" ]; then
    log "Catppuccin for tmux already installed, skipping..."
else
    log "Installing catppuccin for tmux..."
    mkdir -p "$CATPPUCCIN_DIR"
    git clone -b v2.1.2 https://github.com/catppuccin/tmux.git "$CATPPUCCIN_DIR/tmux"
fi

# Download and save SSH setup script
log "Downloading SSH setup script..."
curl -o ~/setup_github_ssh.fish https://raw.githubusercontent.com/josh-jacobsen/init/main/setup_github_ssh.fish
chmod +x ~/setup_github_ssh.fish

log "Setup complete! Please run ~/setup_github_ssh.fish to configure SSH keys."
log "Note: You'll need to restart your terminal for Fish shell changes to take effect."
