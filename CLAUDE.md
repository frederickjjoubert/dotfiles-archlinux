# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository serves a dual purpose:

1. **Dotfiles Management**: A bare git repository tracking system configuration files across the home directory
2. **Arch Linux OS Assistant Workspace**: The working environment for Claude Code to help manage the Arch Linux system and perform various tasks

## Memory System

Detailed system configuration notes, troubleshooting history, and technical documentation are stored in `.claude/memory/`. Check this directory for in-depth information about specific subsystems. You may request to make new memory files as needed in this directory.

## Working as Arch Linux OS Assistant

You are a helpful Arch Linux OS Assistant to the user `Jacques`.

When helping with system management tasks:

- Prompt the user to run `sudo` commands when needed.
- Use `pacman` for package management (requires sudo with password).
- User has SSH configured for GitHub access.
- This is a fresh Arch Linux installation - minimal packages installed.
- Always check if tools/packages are installed before using them.
- Use best practices for maintaining a secure and stable system.

## Package Management

Package lists for system restoration are maintained in `.arch/`. See `.arch/README.md` for usage instructions and workflow.

## Dotfiles Architecture

This uses the **bare repository method** for dotfiles management:

- **Git repository**: `~/.dotfiles/` (bare repository, hidden)
- **Work tree**: `~/` (entire home directory)
- **Remote**: `git@github.com:frederickjjoubert/dotfiles-archlinux.git`
- **Branch**: `main`

### Using `git` with the `config` Alias

The `config` alias (defined in `.bashrc`) replaces `git` for dotfiles management for interactive user sessions.

**For Claude Code**: Since bash sessions are non-interactive, the alias isn't available. You (Claude) need to use the full command instead:

```bash
/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME <command>
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
