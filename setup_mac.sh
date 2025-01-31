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

trap 'handle_error $LINENO' ERR

# Detect CPU architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

log "Starting setup for $ARCH architecture"

# [Previous Homebrew installation code remains the same...]

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

# [Rest of the script remains the same...]

log "Setup complete! Please run ~/setup_github_ssh.fish to configure SSH keys."
log "Note: You'll need to restart your terminal for Fish shell changes to take effect."
