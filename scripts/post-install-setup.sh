#!/bin/bash
#
# Arch Linux Post-Install Setup Script
#
# This script automates the complete setup of a fresh Arch Linux installation:
# - Clones and configures dotfiles using bare repository method
# - Installs official packages and AUR packages
# - Sets up development tools (rustup, nvm)
# - Configures system settings
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/frederickjjoubert/dotfiles-archlinux/main/scripts/post-install-setup.sh | bash
#
# Or locally:
#   bash ~/scripts/post-install-setup.sh
#
# Options:
#   --dry-run    Show what would be done without making changes
#   --force      Skip existing system detection and proceed anyway
#   --yes        Answer yes to all prompts (for fully automated installs)
#

set -e  # Exit on error

# Parse command line arguments
DRY_RUN=false
FORCE_RUN=false
AUTO_YES=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE_RUN=true
            shift
            ;;
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        *)
            ;;
    esac
done

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="https://github.com/frederickjjoubert/dotfiles-archlinux.git"
DOTFILES_DIR="$HOME/.dotfiles"
GIT_NAME="jacques"
GIT_EMAIL="20562845+frederickjjoubert@users.noreply.github.com"
NVM_VERSION="v0.40.3"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${GREEN}==>${NC} ${BLUE}$1${NC}"
    echo ""
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a package is installed
package_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

# Confirm before proceeding (reads from /dev/tty to work with curl | bash)
confirm() {
    if [[ "$AUTO_YES" == true ]]; then
        echo -e "${YELLOW}[CONFIRM]${NC} $1 [y/N]: y (auto)"
        return 0
    fi
    echo -n -e "${YELLOW}[CONFIRM]${NC} $1 [y/N]: "
    read -n 1 -r < /dev/tty
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Detect if system is already configured
detect_existing_setup() {
    log_step "Detecting existing system setup"

    local setup_indicators=0
    local warnings=()

    # Check for existing dotfiles repo
    if [[ -d "$DOTFILES_DIR" ]]; then
        warnings+=("Dotfiles repository already exists at $DOTFILES_DIR")
        setup_indicators=$((setup_indicators + 1))
    fi

    # Check if config alias exists in .bashrc
    if [[ -f "$HOME/.bashrc" ]] && grep -q "alias config=" "$HOME/.bashrc"; then
        warnings+=("'config' alias already defined in .bashrc")
        setup_indicators=$((setup_indicators + 1))
    fi

    # Check if paru is installed
    if command_exists paru; then
        warnings+=("paru (AUR helper) is already installed")
        setup_indicators=$((setup_indicators + 1))
    fi

    # Check if nvm is installed
    if [[ -d "$HOME/.config/nvm" ]]; then
        warnings+=("nvm is already installed")
        setup_indicators=$((setup_indicators + 1))
    fi

    # Check if rustup is configured
    if command_exists rustup && rustup show &>/dev/null; then
        warnings+=("Rust toolchain is already configured")
        setup_indicators=$((setup_indicators + 1))
    fi

    if [[ $setup_indicators -ge 3 ]]; then
        echo ""
        log_error "EXISTING SYSTEM DETECTED!"
        echo ""
        log_warning "This system appears to already be configured:"
        for warning in "${warnings[@]}"; do
            echo "  • $warning"
        done
        echo ""
        log_error "Running this script may overwrite your existing configuration!"
        echo ""

        if [[ "$FORCE_RUN" == true ]]; then
            log_warning "--force flag provided, continuing anyway..."
            echo ""
            sleep 2
        else
            log_error "Aborting for safety. Use --force to override this check."
            echo ""
            log_info "If you want to see what would happen, use: $0 --dry-run"
            exit 1
        fi
    elif [[ $setup_indicators -gt 0 ]]; then
        log_warning "Some components appear to be already configured:"
        for warning in "${warnings[@]}"; do
            echo "  • $warning"
        done
        echo ""
        if ! confirm "Continue anyway?"; then
            log_info "Installation cancelled"
            exit 0
        fi
    else
        log_success "No existing setup detected - safe to proceed"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites"

    if ! command_exists git; then
        log_error "git is not installed. Please install it first: sudo pacman -S git"
        exit 1
    else
        log_success "git is installed"
    fi

    log_info "Initial setup will use HTTPS (no SSH key required)"
}


# Clone and setup dotfiles
setup_dotfiles() {
    log_step "Setting up dotfiles repository"

    if [[ -d "$DOTFILES_DIR" ]]; then
        log_warning "Dotfiles directory already exists at $DOTFILES_DIR"
        if confirm "Remove existing dotfiles and re-clone?"; then
            rm -rf "$DOTFILES_DIR"
        else
            log_info "Skipping dotfiles setup"
            return 0
        fi
    fi

    log_info "Cloning dotfiles repository"
    if git clone "$DOTFILES_REPO" "$HOME/.dotfiles-tmp" 2>/dev/null; then
        log_success "Repository cloned successfully"

        log_info "Converting to bare repository"
        mv "$HOME/.dotfiles-tmp/.git" "$DOTFILES_DIR"
        rm -rf "$HOME/.dotfiles-tmp"
        git --git-dir="$DOTFILES_DIR" config --bool core.bare true

        log_info "Configuring git settings"
        git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" config user.name "$GIT_NAME"
        git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" config user.email "$GIT_EMAIL"
        git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" config status.showUntrackedFiles no

        log_info "Restoring dotfiles to home directory"
        if git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout -f 2>/dev/null; then
            log_success "Dotfiles restored successfully"
        else
            log_warning "Some files may have conflicts. Forcing checkout..."
            git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" restore . 2>/dev/null || true
            log_success "Dotfiles setup complete"
        fi

        log_info "Reloading shell configuration"
        if [[ -f "$HOME/.bashrc" ]]; then
            source "$HOME/.bashrc" 2>/dev/null || true
            log_success "Shell configuration reloaded"
        fi
    else
        log_error "Failed to clone dotfiles repository"
        log_error "Please check your SSH key is added to GitHub and has access to the repository"
        exit 1
    fi
}

# Update system
update_system() {
    log_step "Updating system"

    log_info "Updating pacman mirrors with reflector"
    if package_installed reflector; then
        log_info "Running reflector to update mirror list"
        sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        log_success "Mirrors updated"
    else
        log_warning "reflector not installed, skipping mirror update"
    fi

    log_info "Updating package database"
    sudo pacman -Syy
    log_success "Package database updated"

    if confirm "Upgrade all installed packages?"; then
        sudo pacman -Syu --noconfirm
        log_success "System upgraded"
    fi
}

# Install official packages
install_official_packages() {
    log_step "Installing official packages"

    local pkglist="$HOME/.arch/pkglist.txt"

    if [[ ! -f "$pkglist" ]]; then
        log_error "Package list not found at $pkglist"
        log_error "Please ensure dotfiles are set up correctly"
        exit 1
    fi

    log_info "Installing packages from $pkglist"
    log_warning "This may take a while and will require sudo password"

    sudo pacman -S --needed --noconfirm - < "$pkglist"
    log_success "Official packages installed"
}

# Setup Rust toolchain
setup_rust() {
    log_step "Setting up Rust toolchain"

    if command_exists rustup; then
        log_info "Setting stable as default toolchain"
        rustup default stable
        log_success "Rust toolchain configured"
    else
        log_error "rustup not found. It should have been installed from pkglist.txt"
        exit 1
    fi
}

# Install paru (AUR helper)
install_paru() {
    log_step "Installing paru (AUR helper)"

    if command_exists paru; then
        log_info "paru is already installed"
        return 0
    fi

    log_info "Building paru from AUR"
    local build_dir="/tmp/paru-build-$$"

    mkdir -p "$build_dir"
    cd "$build_dir"

    git clone https://aur.archlinux.org/paru.git
    cd paru

    log_info "Compiling paru (this may take a few minutes)"
    makepkg -si --noconfirm

    cd "$HOME"
    rm -rf "$build_dir"

    if command_exists paru; then
        log_success "paru installed successfully"
    else
        log_error "paru installation failed"
        exit 1
    fi
}

# Install AUR packages
install_aur_packages() {
    log_step "Installing AUR packages"

    if ! command_exists paru; then
        log_error "paru not found. Cannot install AUR packages"
        exit 1
    fi

    local aurlist="$HOME/.arch/aurlist.txt"

    if [[ ! -f "$aurlist" ]]; then
        log_warning "AUR package list not found at $aurlist"
        return 0
    fi

    log_info "Installing AUR packages from $aurlist"

    # Filter out paru since we already installed it
    grep -v "^paru$" "$aurlist" | paru -S --needed --noconfirm -

    log_success "AUR packages installed"
}

# Install nvm
install_nvm() {
    log_step "Installing Node Version Manager (nvm)"

    if [[ -d "$HOME/.nvm" ]]; then
        log_info "nvm is already installed"
        return 0
    fi

    log_info "Downloading and installing nvm $NVM_VERSION"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash

    # Load nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if command_exists nvm; then
        log_success "nvm installed successfully"

        if confirm "Install latest Node.js LTS?"; then
            nvm install --lts
            log_success "Node.js LTS installed"
        fi
    else
        log_warning "nvm installed but not loaded. Please restart your shell"
    fi
}

# Optional system configurations
optional_configurations() {
    log_step "Optional system configurations"

    # iwd configuration
    if [[ -f "$HOME/.arch/etc/iwd/main.conf" ]] && package_installed iwd; then
        if confirm "Copy iwd configuration to /etc/iwd/?"; then
            sudo mkdir -p /etc/iwd
            sudo cp "$HOME/.arch/etc/iwd/main.conf" /etc/iwd/main.conf
            sudo systemctl restart iwd
            log_success "iwd configured and restarted"
        fi
    fi

    # Hibernation configuration (requires LVM swap partition)
    if [[ -f "$HOME/.arch/etc/fstab" ]] && [[ -f "$HOME/.arch/etc/mkinitcpio.conf" ]]; then
        if confirm "Configure hibernation with LVM swap partition?"; then
            log_info "Applying hibernation configuration"

            # Copy fstab
            sudo cp "$HOME/.arch/etc/fstab" /etc/fstab
            log_success "fstab updated with swap partition"

            # Copy bootloader entries
            if [[ -d "$HOME/.arch/boot/loader/entries" ]]; then
                sudo cp "$HOME/.arch/boot/loader/entries/"*.conf /boot/loader/entries/
                log_success "Bootloader entries updated with resume parameter"
            fi

            # Copy mkinitcpio.conf
            sudo cp "$HOME/.arch/etc/mkinitcpio.conf" /etc/mkinitcpio.conf
            log_success "mkinitcpio.conf updated with resume hook"

            # Rebuild initramfs
            log_info "Rebuilding initramfs (this may take a moment)"
            sudo mkinitcpio -P
            log_success "Initramfs rebuilt"

            # Activate swap partition if it exists
            if [[ -e /dev/mapper/vg0-swap ]]; then
                if ! swapon --show | grep -q vg0-swap; then
                    sudo swapon --priority 50 /dev/mapper/vg0-swap
                    log_success "Swap partition activated"
                fi
            fi

            log_success "Hibernation configured - reboot required to take effect"
        fi
    fi

    # Enable and start sddm
    if package_installed sddm; then
        if confirm "Enable SDDM display manager?"; then
            sudo systemctl enable sddm
            log_success "SDDM enabled (will start on next boot)"
        fi
    fi

    # Enable bluetooth
    if package_installed bluez; then
        if confirm "Enable Bluetooth service?"; then
            sudo systemctl enable bluetooth
            sudo systemctl start bluetooth
            log_success "Bluetooth enabled and started"
        fi
    fi
}

# Main execution
main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                       ║${NC}"
    echo -e "${BLUE}║        Arch Linux Post-Install Setup Script          ║${NC}"
    echo -e "${BLUE}║                                                       ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    log_warning "This script will set up your Arch Linux system with:"
    echo "  - Dotfiles (bare repository method)"
    echo "  - Official packages from pkglist.txt"
    echo "  - Rust toolchain (rustup)"
    echo "  - Paru AUR helper"
    echo "  - AUR packages from aurlist.txt"
    echo "  - Node Version Manager (nvm)"
    echo "  - Optional system configurations"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Dry run mode: Checking system state only..."
        check_prerequisites
        detect_existing_setup
        log_info "Dry run complete. No changes were made."
        exit 0
    fi

    if ! confirm "Continue with installation?"; then
        log_info "Installation cancelled"
        exit 0
    fi

    # Run setup steps
    check_prerequisites
    detect_existing_setup
    setup_dotfiles
    update_system
    install_official_packages
    setup_rust
    install_paru
    install_aur_packages
    install_nvm
    optional_configurations

    # Final message
    echo ""
    log_step "Installation Complete!"
    echo ""
    log_success "Your Arch Linux system has been configured successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc"
    echo "  2. The 'config' alias is available for managing dotfiles"
    echo "  3. Review and apply any additional configurations in .arch/README.md"
    echo ""
    log_warning "IMPORTANT: SSH Setup"
    echo "  Your dotfiles are currently using HTTPS (read-only)."
    echo "  To enable push access:"
    echo "    1. Generate SSH key: ssh-keygen -t ed25519 -C \"your_email@example.com\""
    echo "    2. Add key to GitHub: https://github.com/settings/keys"
    echo "    3. Run: bash ~/scripts/switch-to-ssh.sh"
    echo ""

    if confirm "Reboot now?"; then
        log_info "Rebooting system..."
        sudo reboot
    else
        log_info "Please reboot when convenient"
    fi
}

# Run main function
main "$@"
