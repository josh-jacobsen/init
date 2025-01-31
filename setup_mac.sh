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

# Function to install cask with error handling
install_cask() {
    local cask_name="$1"
    local app_name="$2"
    
    # Check if the application is already installed
    if [ -d "/Applications/${app_name}.app" ]; then
        echo "Found existing installation of ${app_name}"
        read -p "Do you want to reinstall ${app_name}? (y/n) " choice
        case "$choice" in
            y|Y)
                log "Removing existing ${app_name} installation..."
                rm -rf "/Applications/${app_name}.app"
                brew install --cask "$cask_name" || log "Failed to install ${cask_name}"
                ;;
            n|N)
                log "Skipping ${cask_name} installation..."
                ;;
            *)
                log "Invalid choice. Skipping ${cask_name} installation..."
                ;;
        esac
    else
        brew install --cask "$cask_name" || log "Failed to install ${cask_name}"
    fi
}


# Function to handle stow conflicts
handle_stow_conflicts() {
    local dir="$1"
    local backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    # Find all files that would be stowed
    local stow_files=$(cd ~/dotfiles/$dir && find . -type f -not -path '*/\.*' -print)
    
    # Check each file for conflicts
    while IFS= read -r file; do
        # Remove leading ./
        file="${file#./}"
        # Get the target path in home directory
        local target="$HOME/$file"
        
        if [ -f "$target" ] && [ ! -L "$target" ]; then
            log "Found existing file: $target"
            read -p "File $target already exists. Backup and replace? (y/n) " choice
            case "$choice" in
                y|Y)
                    # Create necessary subdirectories in backup
                    mkdir -p "$(dirname "$backup_dir/$file")"
                    # Backup the file
                    mv "$target" "$backup_dir/$file"
                    log "Backed up $target to $backup_dir/$file"
                    ;;
                n|N)
                    log "Skipping $target"
                    return 1
                    ;;
                *)
                    log "Invalid choice. Skipping $target"
                    return 1
                    ;;
            esac
        fi
    done <<< "$stow_files"
    
    return 0
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

# Create Fish config directory if it doesn't exist
mkdir -p ~/.config/fish
FISH_CONFIG=~/.config/fish/config.fish

# Check if Homebrew path is already in Fish config
if [ -f "$FISH_CONFIG" ] && grep -q "fish_add_path $HOMEBREW_PREFIX/bin" "$FISH_CONFIG"; then
    log "Homebrew path already in Fish config"
else
    log "Adding Homebrew to Fish PATH..."
    echo "fish_add_path $HOMEBREW_PREFIX/bin" >> "$FISH_CONFIG"
fi

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
for package in $BREW_PACKAGES; do
    brew install "$package"
done

# Install casks with proper error handling
log "Installing cask applications..."
# Define casks with their application names
declare -A CASK_APPS=(
    ["aws-vault"]="aws-vault"
    ["raycast"]="Raycast"
    ["visual-studio-code"]="Visual Studio Code"
    ["shottr"]="Shottr"
    ["ghostty"]="Ghostty"
    ["1password"]="1Password"
    ["lastpass"]="LastPass"
    ["firefox"]="Firefox"
)

for cask in "${!CASK_APPS[@]}"; do
    install_cask "$cask" "${CASK_APPS[$cask]}"
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
        log "Checking $dir for conflicts..."
        if handle_stow_conflicts "$dir"; then
            log "Stowing $dir..."
            stow "$dir" || log "Failed to stow $dir"
        else
            log "Skipping stow for $dir due to unresolved conflicts"
        fi
    done
    cd ~
fi

log "Installing catppuccin for tmux..."
mkdir -p ~/.config/tmux/plugins/catppuccin
git clone -b v2.1.2 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux


# Download and save SSH setup script
log "Downloading SSH setup script..."
curl -o ~/setup_github_ssh.fish https://raw.githubusercontent.com/josh-jacobsen/init/main/setup_github_ssh.fish
chmod +x ~/setup_github_ssh.fish

log "Setup complete! Please run ~/setup_github_ssh.fish to configure SSH keys."
log "Note: You'll need to restart your terminal for Fish shell changes to take effect."
