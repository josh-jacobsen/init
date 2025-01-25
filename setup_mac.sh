#!/bin/bash

# Download the file and save it. 
# Then max executable with: chmod +x setup_mac.sh 
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

# Install Fish shell
log "Installing Fish shell..."
brew install fish

# Get Fish shell path
FISH_PATH=$(which fish)
log "Fish shell path: $FISH_PATH"

# Add Fish to allowed shells if not already present
if ! grep -q "$FISH_PATH" /etc/shells; then
    log "Adding Fish to allowed shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

# Set Fish as default shell
log "Setting Fish as default shell..."
chsh -s "$FISH_PATH"

# Create Fish config directory and file
mkdir -p ~/.config/fish
FISH_CONFIG=~/.config/fish/config.fish

# Add Homebrew to Fish PATH
echo "fish_add_path $HOMEBREW_PREFIX/bin" >> "$FISH_CONFIG"

# Install asdf
log "Installing asdf..."
if [ ! -d ~/.asdf ]; then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
    echo "source ~/.asdf/asdf.fish" >> "$FISH_CONFIG"
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
BREW_PACKAGES="stow lazygit gh awscli tmux"
BREW_CASKS="aws-vault raycast visual-studio-code shottr ghostty 1password lastpass firefox"

for package in $BREW_PACKAGES; do
    brew install "$package"
done

for cask in $BREW_CASKS; do
    brew install --cask "$cask"
done

# Install Aerospace
brew tap nikitabobko/tap
brew install --cask aerospace

# Clone and setup dotfiles
log "Cloning dotfiles repository..."
if [ ! -d ~/dotfiles ]; then
    git clone https://github.com/josh-jacobsen/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    
    # Get all top-level directories and stow each one
    for dir in */; do
        dir=${dir%/}  # Remove trailing slash
        log "Stowing $dir..."
        stow "$dir"
    done
    cd ~
fi

# Install and setup tmux plugin manager
log "Setting up tmux plugin manager..."
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Start tmux server and install plugins
log "Starting tmux and installing plugins..."
tmux start-server
tmux new-session -d
sleep 1
~/.tmux/plugins/tpm/scripts/install_plugins.sh
tmux kill-server


# Download and save SSH setup script
log "Downloading SSH setup script..."
curl -o ~/setup_github_ssh.fish https://raw.githubusercontent.com/josh-jacobsen/init/main/setup_github_ssh.fish
chmod +x ~/setup_github_ssh.fish

log "Setup complete! Please run ~/setup_github_ssh.fish to configure SSH keys."
log "Note: You'll need to restart your terminal for Fish shell changes to take effect."
