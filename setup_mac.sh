#!/bin/bash

# Download the file and save it.
# Then make executable with: chmod +x setup_mac.sh
# Then run with ./setup_mac.sh
# For dry-run mode: ./setup_mac.sh --dry-run
# For help: ./setup_mac.sh --help

# Function to show help
show_help() {
    cat <<EOF
macOS Development Environment Setup Script

USAGE:
    ./setup_mac.sh [OPTIONS]

OPTIONS:
    --help          Show this help message and exit
    --dry-run       Show what would be installed without making changes

DESCRIPTION:
    This script automates the setup of a macOS development environment with
    the following components:

    Core Tools:
    - Homebrew package manager
    - Fish shell (set as default)
    - asdf version manager
    - Neovim (built from source)

    Languages & Runtimes (via asdf):
    - Node.js ${NODEJS_VERSION:-20.18.1}
    - Python ${PYTHON_VERSION:-3.12.8}
    - Terraform ${TERRAFORM_VERSION:-1.10.3}

    Build Dependencies:
    - ninja, cmake, gettext, curl, ripgrep, fzf

    CLI Tools:
    - stow, lazygit, gh, awscli, tmux, fd, bruno

    Applications (Homebrew Casks):
    - AWS Vault, Raycast, VS Code, Shottr, Ghostty
    - LastPass, 1Password, Firefox, DBeaver Community
    - Aerospace (window manager)

    Additional Setup:
    - Dotfiles (cloned from github.com/josh-jacobsen/dotfiles)
    - Catppuccin theme for tmux
    - SSH setup script (downloaded to ~/setup_github_ssh.fish)

EXAMPLES:
    # Normal installation
    ./setup_mac.sh

    # Preview what would be installed
    ./setup_mac.sh --dry-run

    # Show this help
    ./setup_mac.sh --help

NOTES:
    - Script is idempotent - safe to run multiple times
    - Existing installations will be skipped
    - Requires sudo access for some operations
    - Internet connection required

For more information, visit: https://github.com/josh-jacobsen/init

EOF
    exit 0
}

# ============================================================================
# Configuration - Update versions and packages here
# ============================================================================

# Dry-run mode (set via --dry-run flag)
DRY_RUN=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --help|-h)
            show_help
            ;;
        --dry-run)
            DRY_RUN=true
            echo "=========================================="
            echo "DRY-RUN MODE - No changes will be made"
            echo "=========================================="
            echo ""
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Homebrew packages to install
BREW_PACKAGES=(
    "stow"
    "lazygit"
    "gh"
    "awscli"
    "tmux"
    "fd"
    "bruno"
)

# Build dependencies for Neovim and other tools
BUILD_DEPENDENCIES=(
    "ninja"
    "cmake"
    "gettext"
    "curl"
    "ripgrep"
    "fzf"
)

# Homebrew casks to install
# Format: "cask-name|Application Name"
BREW_CASKS=(
    "aws-vault|aws-vault"
    "raycast|Raycast"
    "visual-studio-code|Visual Studio Code"
    "shottr|Shottr"
    "ghostty|Ghostty"
    "lastpass|LastPass"
    "1password|1Password"
    "firefox|Firefox"
    "dbeaver-community|DBeaver Community"
    "nikitabobko/tap/aerospace|Aerospace"
)

# Version management
ASDF_VERSION="v0.13.1"
NODEJS_VERSION="20.18.1"
PYTHON_VERSION="3.12.8"
TERRAFORM_VERSION="1.10.3"
CATPPUCCIN_TMUX_VERSION="v2.1.2"

# Dotfiles configuration
DOTFILES_REPO="https://github.com/josh-jacobsen/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Alternative: Use Brewfile instead of arrays
# Set to true to generate and use a Brewfile for package management
USE_BREWFILE=false

# ============================================================================
# Script starts here
# ============================================================================

# Exit on error for critical operations, but allow individual package failures
# This will be temporarily disabled during non-critical operations
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to log messages
log() {
    local prefix=""
    if [ "$DRY_RUN" = true ]; then
        prefix="[DRY-RUN] "
    fi
    echo "$(date "+%Y-%m-%d %H:%M:%S"): ${prefix}$1"
}

# Function to handle errors
handle_error() {
    log "Error occurred in line $1"
    exit 1
}

# Function to check if a brew package is installed
brew_package_installed() {
    brew list "$1" &>/dev/null
}

# Function to check if asdf plugin is installed
asdf_plugin_installed() {
    asdf plugin list 2>/dev/null | grep -q "^$1$"
}

# Function to check if asdf version is installed
asdf_version_installed() {
    local plugin="$1"
    local version="$2"
    asdf list "$plugin" 2>/dev/null | grep -q "^[[:space:]]*$version$"
}

# Function to generate Brewfile from arrays
generate_brewfile() {
    local brewfile="$HOME/Brewfile"
    log "Generating Brewfile at $brewfile..."

    cat > "$brewfile" <<EOF
# Generated Brewfile for macOS setup
# Usage: brew bundle install --file=$brewfile

# Taps
tap "nikitabobko/tap"

# Packages
EOF

    for package in "${BREW_PACKAGES[@]}"; do
        echo "brew \"$package\"" >> "$brewfile"
    done

    for dep in "${BUILD_DEPENDENCIES[@]}"; do
        echo "brew \"$dep\"" >> "$brewfile"
    done

    echo "" >> "$brewfile"
    echo "# Casks" >> "$brewfile"

    for cask_entry in "${BREW_CASKS[@]}"; do
        cask_name="${cask_entry%%|*}"
        # Remove tap prefix if present
        if [[ "$cask_name" == */* ]]; then
            cask_name="${cask_name##*/}"
        fi
        echo "cask \"$cask_name\"" >> "$brewfile"
    done

    log "Brewfile generated successfully"
}

# Function to install using Brewfile
install_with_brewfile() {
    generate_brewfile
    log "Installing packages using brew bundle..."
    if [ "$DRY_RUN" = false ]; then
        brew bundle install --file="$HOME/Brewfile" --no-lock
    fi
}

# Function to install cask with silent skipping of existing installations
install_cask() {
    local cask_name="$1"
    local app_name="$2"
    local progress="$3"

    if [ -d "/Applications/${app_name}.app" ]; then
        log "${progress}${app_name} already installed, skipping..."
    else
        log "${progress}Installing ${app_name}..."
        if [ "$DRY_RUN" = false ]; then
            brew install --cask "$cask_name" || log "Failed to install ${cask_name}"
        fi
    fi
}

# Function to install brew package with checking
install_brew_package() {
    local package="$1"
    local progress="$2"

    if brew_package_installed "$package"; then
        log "${progress}${package} already installed, skipping..."
    else
        log "${progress}Installing ${package}..."
        if [ "$DRY_RUN" = false ]; then
            brew install "$package" || log "Failed to install ${package}"
        fi
    fi
}

# Function to check and install Xcode Command Line Tools
check_xcode_tools() {
    log "Checking for Xcode Command Line Tools..."

    # Check if Command Line Tools are installed
    if xcode-select -p &>/dev/null; then
        log "Xcode Command Line Tools already installed at $(xcode-select -p)"
        return 0
    fi

    log "Xcode Command Line Tools not found. Installing..."

    if [ "$DRY_RUN" = true ]; then
        log "Would install Xcode Command Line Tools"
        return 0
    fi

    # Trigger the installation
    xcode-select --install &>/dev/null || true

    # Wait for user to complete the installation
    log "Please complete the Xcode Command Line Tools installation in the dialog."
    log "Waiting for installation to complete..."

    # Poll until installation is complete
    until xcode-select -p &>/dev/null; do
        sleep 5
    done

    log "Xcode Command Line Tools installed successfully!"

    # Accept the license
    sudo xcodebuild -license accept 2>/dev/null || true
}

# Only trap errors for critical operations (Homebrew, Fish, asdf installation)
# Package installation failures will be logged but not fatal
trap 'handle_error $LINENO' ERR

# Detect CPU architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

log "Starting setup for $ARCH architecture"

# Check and install Xcode Command Line Tools (required for many installations)
check_xcode_tools

# Install Homebrew if not already installed
if ! command_exists brew; then
    log "Installing Homebrew..."
    if [ "$DRY_RUN" = false ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH based on architecture
        if [ "$ARCH" = "arm64" ]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
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
    if [ "$DRY_RUN" = false ]; then
        brew install fish
        FISH_PATH=$(which fish)
    else
        FISH_PATH="/opt/homebrew/bin/fish"  # Placeholder for dry-run
    fi
fi

log "Fish shell path: $FISH_PATH"

# Check if Fish is already in allowed shells
if grep -q "$FISH_PATH" /etc/shells 2>/dev/null; then
    log "Fish shell is already in allowed shells"
else
    log "Adding Fish to allowed shells..."
    if [ "$DRY_RUN" = false ]; then
        echo "$FISH_PATH" | sudo tee -a /etc/shells
    fi
fi

# Check if Fish is already the default shell
if [ "$SHELL" = "$FISH_PATH" ]; then
    log "Fish is already the default shell"
else
    log "Setting Fish as default shell..."
    if [ "$DRY_RUN" = false ]; then
        chsh -s "$FISH_PATH"
    fi
fi

# Install asdf
log "Installing asdf..."
if [ ! -d ~/.asdf ]; then
    if [ "$DRY_RUN" = false ]; then
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch $ASDF_VERSION
    fi
else
    log "asdf already installed, skipping..."
fi

# Install packages using Brewfile or individual commands
if [ "$USE_BREWFILE" = true ]; then
    install_with_brewfile
else
    # Install build dependencies
    log "Installing build dependencies..."
    total="${#BUILD_DEPENDENCIES[@]}"
    current=0
    for dep in "${BUILD_DEPENDENCIES[@]}"; do
        current=$((current + 1))
        install_brew_package "$dep" "[$current/$total] "
    done
fi

# Source asdf if not in dry-run mode
if [ "$DRY_RUN" = false ] && [ -d ~/.asdf ]; then
    source ~/.asdf/asdf.sh
fi

# Install Node.js using asdf
log "Installing Node.js..."
if [ "$DRY_RUN" = false ]; then
    if ! asdf_plugin_installed nodejs; then
        asdf plugin add nodejs || log "Warning: Failed to add nodejs plugin"
    else
        log "nodejs plugin already installed"
    fi

    if ! asdf_version_installed nodejs $NODEJS_VERSION; then
        asdf install nodejs $NODEJS_VERSION || log "Warning: Failed to install Node.js $NODEJS_VERSION"
        asdf global nodejs $NODEJS_VERSION
    else
        log "Node.js $NODEJS_VERSION already installed"
        asdf global nodejs $NODEJS_VERSION
    fi
fi

# Install Python using asdf
log "Installing Python..."
if [ "$DRY_RUN" = false ]; then
    if ! asdf_plugin_installed python; then
        asdf plugin add python || log "Warning: Failed to add python plugin"
    else
        log "python plugin already installed"
    fi

    if ! asdf_version_installed python $PYTHON_VERSION; then
        asdf install python $PYTHON_VERSION || log "Warning: Failed to install Python $PYTHON_VERSION"
        asdf global python $PYTHON_VERSION
    else
        log "Python $PYTHON_VERSION already installed"
        asdf global python $PYTHON_VERSION
    fi
fi

# Install Terraform using asdf
log "Installing Terraform..."
if [ "$DRY_RUN" = false ]; then
    if ! asdf_plugin_installed terraform; then
        asdf plugin add terraform || log "Warning: Failed to add terraform plugin"
    else
        log "terraform plugin already installed"
    fi

    if ! asdf_version_installed terraform $TERRAFORM_VERSION; then
        asdf install terraform $TERRAFORM_VERSION || log "Warning: Failed to install Terraform $TERRAFORM_VERSION"
        asdf global terraform $TERRAFORM_VERSION
    else
        log "Terraform $TERRAFORM_VERSION already installed"
        asdf global terraform $TERRAFORM_VERSION
    fi
fi

# Install Neovim from source
log "Installing Neovim..."
if command_exists nvim; then
    log "Neovim already installed ($(nvim --version | head -n1)), skipping..."
elif [ "$DRY_RUN" = false ]; then
    if [ ! -d ~/neovim ]; then
        git clone https://github.com/neovim/neovim ~/neovim
    else
        log "Neovim source directory exists, pulling latest changes..."
        cd ~/neovim
        git pull
        cd ~
    fi
    cd ~/neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd ~
fi

# Only install individual packages if not using Brewfile
if [ "$USE_BREWFILE" = false ]; then
    # Install additional tools via Brew
    log "Installing additional tools..."
    total="${#BREW_PACKAGES[@]}"
    current=0
    for package in "${BREW_PACKAGES[@]}"; do
        current=$((current + 1))
        install_brew_package "$package" "[$current/$total] "
    done

    # Install cask applications
    log "Installing cask applications..."
    total="${#BREW_CASKS[@]}"
    current=0
    for cask_entry in "${BREW_CASKS[@]}"; do
        current=$((current + 1))
        cask_name="${cask_entry%%|*}"
        app_name="${cask_entry##*|}"

        # Handle taps (e.g., nikitabobko/tap/aerospace)
        if [[ "$cask_name" == */* ]]; then
            tap="${cask_name%/*}"
            if [ "$DRY_RUN" = false ]; then
                brew tap "$tap" 2>/dev/null || true
            fi
            cask_name="${cask_name##*/}"
        fi

        install_cask "$cask_name" "$app_name" "[$current/$total] "
    done
fi

# Clone and setup dotfiles
log "Setting up dotfiles..."
if [ ! -d "$DOTFILES_DIR" ]; then
    log "Cloning dotfiles repository from $DOTFILES_REPO..."
    if [ "$DRY_RUN" = false ]; then
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
else
    log "Dotfiles directory already exists at $DOTFILES_DIR"
fi

if [ "$DRY_RUN" = false ] && [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"
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
fi

# Configure Fish shell after dotfiles are stowed
log "Configuring Fish shell paths..."
FISH_CONFIG=~/.config/fish/config.fish

# Function to safely add line to fish config if not already present
add_to_fish_config() {
    local line="$1"
    if [ "$DRY_RUN" = true ]; then
        log "Would add to Fish config: $line"
        return
    fi

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
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$CATPPUCCIN_DIR"
        git clone -b $CATPPUCCIN_TMUX_VERSION https://github.com/catppuccin/tmux.git "$CATPPUCCIN_DIR/tmux"
    fi
fi

# Download and save SSH setup script
log "Downloading SSH setup script..."
if [ "$DRY_RUN" = false ]; then
    curl -o ~/setup_github_ssh.fish https://raw.githubusercontent.com/josh-jacobsen/init/main/setup_github_ssh.fish
    chmod +x ~/setup_github_ssh.fish
fi

log "Setup complete! Please run ~/setup_github_ssh.fish to configure SSH keys."
log "Note: You'll need to restart your terminal for Fish shell changes to take effect."
