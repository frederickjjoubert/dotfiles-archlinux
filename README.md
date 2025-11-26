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
- **Branch**: `customization`

### Key Directories

- `.arch/` - Package lists and system restoration scripts
- `.claude/` - Claude Code memory and documentation
- `.config/` - Application configurations
  - `hypr/` - Hyprland window manager configuration
  - `iwd/` - Internet Wireless Daemon configuration

## Setup

### Prerequisites

- Arch Linux installation
- Git installed (`sudo pacman -S git`)
- SSH key configured for GitHub access

### Initial Setup (Fresh System)

Follow these steps in order to set up the dotfiles on a new system:

#### 1. Add GitHub to Known Hosts

```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

Or test your SSH connection (will prompt to accept host key):

```bash
ssh -T git@github.com
```

#### 2. Clone the Repository

Clone the repository into `~/.dotfiles/`:

```bash
git clone git@github.com:frederickjjoubert/dotfiles-archlinux.git .dotfiles
```

#### 3. Convert to Bare Repository

Move the git directory and convert it to a bare repository:

```bash
mv ~/.dotfiles/.git ~/dotfiles-tmp
rm -rf ~/.dotfiles
mv ~/dotfiles-tmp ~/.dotfiles
git --git-dir=$HOME/.dotfiles/ config --bool core.bare true
```

#### 4. Configure Git Settings

Set up your git identity and hide untracked files:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config user.name "jacques"
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config user.email "20562845+frederickjjoubert@users.noreply.github.com"
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config status.showUntrackedFiles no
```

#### 5. Checkout the Customization Branch

Switch to the customization branch:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout customization
```

#### 6. Restore All Dotfiles

If any files show as deleted, restore them:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME restore .
```

#### 7. Reload Shell Configuration

Source the new `.bashrc` to activate the `config` alias:

```bash
source ~/.bashrc
```

The `config` alias will be available in all new shell sessions.

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
config add .vimrc
config add .config/i3/config
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
config ls-tree -r customization --name-only
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
