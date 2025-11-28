#!/bin/bash
#
# Switch Dotfiles Remote to SSH
#
# This script converts the dotfiles repository remote from HTTPS to SSH.
# Run this after you've set up SSH keys and added them to GitHub.
#
# Usage:
#   bash ~/scripts/switch-to-ssh.sh
#

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$HOME/.dotfiles"
SSH_REPO="git@github.com:frederickjjoubert/dotfiles-archlinux.git"
HTTPS_REPO="https://github.com/frederickjjoubert/dotfiles-archlinux.git"

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

# Main execution
main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                       ║${NC}"
    echo -e "${BLUE}║      Switch Dotfiles Remote to SSH                   ║${NC}"
    echo -e "${BLUE}║                                                       ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Check if dotfiles repository exists
    log_step "Checking dotfiles repository"

    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles repository not found at $DOTFILES_DIR"
        log_error "Please run the post-install setup script first"
        exit 1
    fi

    log_success "Dotfiles repository found"

    # Check if SSH key exists
    log_step "Checking for SSH key"

    if [[ ! -f "$HOME/.ssh/id_rsa" ]] && [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        log_error "No SSH key found"
        echo ""
        log_info "Generate an SSH key with:"
        echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
        echo ""
        log_info "Then add it to GitHub:"
        echo "  https://github.com/settings/keys"
        exit 1
    fi

    log_success "SSH key found"

    # Add GitHub to known_hosts if not already there
    log_step "Checking GitHub in known_hosts"

    if ssh-keygen -F github.com >/dev/null 2>&1; then
        log_info "GitHub already in known_hosts"
    else
        log_info "Adding GitHub to known_hosts"
        mkdir -p "$HOME/.ssh"
        ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
        log_success "GitHub added to known_hosts"
    fi

    # Test GitHub SSH connection
    log_step "Testing GitHub SSH connection"

    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_success "GitHub SSH authentication successful"
    else
        log_error "GitHub SSH authentication failed"
        echo ""
        log_info "Make sure you've added your SSH key to GitHub:"
        echo "  https://github.com/settings/keys"
        echo ""
        log_info "Test your connection manually with:"
        echo "  ssh -T git@github.com"
        exit 1
    fi

    # Check current remote
    log_step "Checking current remote URL"

    CURRENT_REMOTE=$(/usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" remote get-url origin 2>/dev/null || echo "none")

    if [[ "$CURRENT_REMOTE" == "$SSH_REPO" ]]; then
        log_success "Remote is already set to SSH"
        echo "  $CURRENT_REMOTE"
        echo ""
        log_info "No changes needed. You're all set!"
        exit 0
    elif [[ "$CURRENT_REMOTE" == "$HTTPS_REPO" ]]; then
        log_info "Current remote (HTTPS): $CURRENT_REMOTE"
    else
        log_warning "Current remote: $CURRENT_REMOTE"
        log_warning "This doesn't match the expected HTTPS URL"
        read -p "$(echo -e ${YELLOW}[CONFIRM]${NC} Continue anyway? [y/N]: )" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled"
            exit 0
        fi
    fi

    # Switch to SSH
    log_step "Switching remote to SSH"

    /usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" remote set-url origin "$SSH_REPO"
    log_success "Remote URL updated to SSH"

    # Verify the change
    log_step "Verifying remote URL"

    NEW_REMOTE=$(/usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" remote get-url origin)

    if [[ "$NEW_REMOTE" == "$SSH_REPO" ]]; then
        log_success "Verification successful"
        echo "  New remote (SSH): $NEW_REMOTE"
        echo ""
        log_success "Your dotfiles repository is now using SSH!"
        echo ""
        log_info "You can now push changes using the 'config' alias:"
        echo "  config push"
    else
        log_error "Verification failed - remote URL is: $NEW_REMOTE"
        exit 1
    fi

    echo ""
}

# Run main function
main "$@"
