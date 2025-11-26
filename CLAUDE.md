# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Memory System

Detailed system configuration notes, troubleshooting history, and technical documentation are stored in `.claude/memory/`. Check this directory for in-depth information about specific subsystems.

## Package Management

Package lists for system restoration are maintained in `.arch/`. See `.arch/README.md` for usage instructions and workflow.

## Repository Purpose

This repository serves a dual purpose:

1. **Dotfiles Management**: A bare git repository tracking system configuration files across the home directory
2. **Arch Linux OS Assistant Workspace**: The working environment for Claude Code to help manage the Arch Linux system and perform various tasks

## Dotfiles Architecture

This uses the **bare repository method** for dotfiles management:

- **Git repository**: `~/.dotfiles/` (bare repository, hidden)
- **Work tree**: `~/` (entire home directory)
- **Remote**: `git@github.com:frederickjjoubert/dotfiles-archlinux.git`
- **Branch**: `main`

### The `config` Alias

The `config` alias (defined in `.bashrc`) replaces `git` for dotfiles management:

```bash
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

**CRITICAL**: Always use `config` instead of `git` when managing dotfiles. Using `git` directly in `~/` will not work correctly.

### Common Dotfiles Commands

```bash
# Check status of tracked dotfiles
config status

# Add a new dotfile to track
config add .vimrc
config add .config/i3/config

# Commit changes
config commit -m "Update configuration"

# Push to GitHub
config push

# View tracked files
config ls-tree -r main --name-only

# See changes in tracked files
config diff
```

### Important Configuration

The repository is configured with `status.showUntrackedFiles no` to prevent showing all files in the home directory. Only explicitly tracked files appear in `config status`.

## System Environment

### Current Setup (as of initial commit)

- **Shell**: bash
- **Node Version Manager**: nvm installed at `~/.config/nvm/`
- **PATH additions**: `~/.local/bin` is prepended to PATH
- **Git identity**:
  - Name: `jacques`
  - Email: `20562845+frederickjjoubert@users.noreply.github.com`

## Working as Arch Linux OS Assistant

When helping with system management tasks:

- Use `pacman` for package management (requires sudo with password)
- User has SSH configured for GitHub access
- This is a fresh Arch Linux installation - minimal packages installed
- Always check if tools/packages are installed before using them
