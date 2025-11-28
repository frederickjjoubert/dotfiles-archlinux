# Dotfiles

Personal dotfiles for Arch Linux, managed using the bare repository method.

## Overview

This repository serves a dual purpose:

1. **Dotfiles Management**: A bare git repository tracking system configuration files across the home directory
2. **Arch Linux OS Assistant Workspace**: The working environment for Claude Code to help manage the Arch Linux system

## Repository Structure

- **Git repository**: `~/.dotfiles/` (bare repository, hidden)
- **Work tree**: `~/` (entire home directory)
- **Remote**: `git@github.com:frederickjjoubert/dotfiles-archlinux.git`
- **Branch**: `main`

### Key Directories

- `.arch/` - Package lists and system restoration scripts
- `.claude/` - Claude Code memory and documentation
- `.config/` - Application configurations
  - `hypr/` - Hyprland window manager configuration
  - `waybar/` - Waybar status bar configuration
  - `wlogout/` - Wlogout logout menu configuration
  - `iwd/` - Internet Wireless Daemon configuration
- `scripts/` - Automation scripts
  - `post-install-setup.sh` - Automated post-installation setup (uses HTTPS)
  - `switch-to-ssh.sh` - Convert dotfiles remote from HTTPS to SSH

## Quick Start (Fresh System)

For a completely automated setup on a fresh Arch Linux installation:

```bash
# Ensure you have git installed
sudo pacman -S git

# Run the automated setup script (uses HTTPS, no SSH required)
curl -fsSL https://raw.githubusercontent.com/frederickjjoubert/dotfiles-archlinux/main/scripts/post-install-setup.sh | bash -s -- --yes
```

This script will:
- Clone and configure the dotfiles repository (via HTTPS)
- Install all official and AUR packages
- Set up Rust toolchain and nvm
- Configure system settings
- Prompt for optional configurations

**After Installation - Enable Push Access**:

The initial setup uses HTTPS (read-only). To enable pushing changes to GitHub:

```bash
# 1. Generate an SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. Add the key to GitHub: https://github.com/settings/keys
cat ~/.ssh/id_ed25519.pub

# 3. Switch dotfiles remote to SSH
bash ~/scripts/switch-to-ssh.sh
```

**Safety Features**:
- Detects existing setups and aborts to prevent accidental overwrites
- Prompts for confirmation at key steps
- Supports `--dry-run` to preview changes without making modifications
- Requires your sudo password for system changes

**Options**:
```bash
# Preview what would happen without making changes
bash ~/scripts/post-install-setup.sh --dry-run

# Force run on an already-configured system (use with caution!)
bash ~/scripts/post-install-setup.sh --force
```

## Manual Setup

### Prerequisites

- Arch Linux installation
- Git installed (`sudo pacman -S git`)

### Initial Setup (Fresh System)

If you prefer to set up manually, follow these steps in order:

#### 1. Clone the Repository

Clone the repository using HTTPS (no SSH key required):

```bash
git clone https://github.com/frederickjjoubert/dotfiles-archlinux.git .dotfiles
```

Alternatively, if you already have SSH keys set up:

```bash
# Add GitHub to known_hosts first
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Then clone with SSH
git clone git@github.com:frederickjjoubert/dotfiles-archlinux.git .dotfiles
```

#### 2. Convert to Bare Repository

Move the git directory and convert it to a bare repository:

```bash
mv ~/.dotfiles/.git ~/dotfiles-tmp
rm -rf ~/.dotfiles
mv ~/dotfiles-tmp ~/.dotfiles
git --git-dir=$HOME/.dotfiles/ config --bool core.bare true
```

#### 3. Configure Git Settings

Set up your git identity and hide untracked files:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config user.name "jacques"
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config user.email "20562845+frederickjjoubert@users.noreply.github.com"
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config status.showUntrackedFiles no
```

#### 4. Restore All Dotfiles

If any files show as deleted, restore them:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME restore .
```

#### 5. Reload Shell Configuration

Source the new `.bashrc` to activate the `config` alias:

```bash
source ~/.bashrc
```

The `config` alias will be available in all new shell sessions.

#### 6. Switch to SSH (Optional)

If you cloned with HTTPS and want to enable push access:

```bash
bash ~/scripts/switch-to-ssh.sh
```

## Usage

### The `config` Alias

The `config` alias (defined in `.bashrc`) replaces `git` for dotfiles management:

```bash
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

**CRITICAL**: Always use `config` instead of `git` when managing dotfiles. Using `git` directly in `~/` will not work correctly.

### Common Commands

Check status of tracked dotfiles:
```bash
config status
```

Add a new dotfile to track:
```bash
config add .bashrc
```

Commit changes:
```bash
config commit -m "Update configuration"
```

Push to GitHub:
```bash
config push
```

View all tracked files:
```bash
config ls-tree -r main --name-only
```

See changes in tracked files:
```bash
config diff
```

Pull latest changes:
```bash
config pull
```

### Important Notes

- Only explicitly tracked files appear in `config status` (thanks to `status.showUntrackedFiles no`)
- The bare repository at `~/.dotfiles/` stores git data, while `~/` is the work tree
- Never use `git` commands in `~/` for dotfiles management - always use `config`

## System Environment

- **OS**: Arch Linux
- **Shell**: bash
- **Window Manager**: Hyprland
- **Node Version Manager**: nvm installed at `~/.config/nvm/`
- **PATH additions**: `~/.local/bin` is prepended to PATH

## Package Management

Package lists for system restoration are maintained in `.arch/`. See `.arch/README.md` for usage instructions.

## Claude Code Integration

Detailed system configuration notes and troubleshooting history are stored in `.claude/memory/`. See `CLAUDE.md` for guidance on working with Claude Code in this repository.

## Resources

- [Bare Repository Method for Dotfiles](https://www.atlassian.com/git/tutorials/dotfiles)
- [Arch Linux Wiki - Dotfiles](https://wiki.archlinux.org/title/Dotfiles)
