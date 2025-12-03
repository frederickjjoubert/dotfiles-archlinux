---
description: Save package lists and commit configuration dotfiles changes
---

Save the current system state by:

1. Updating package lists (pkglist.txt and aurlist.txt) in ~/.arch/ and stage and commit the changes.
2. Staging and committing all tracked configuration dotfiles changes to the bare repository.

When saving package lists:

- Use `pacman -Qqen > ~/.arch/pkglist.txt` for official packages.
- Use `pacman -Qqem > ~/.arch/aurlist.txt` for AUR packages.

When committing dotfiles:

- Use the full git command: `/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME`.
- Stage the package list files and any other modified tracked files.
- Methodically commit the changes each with their own commit.
- Create a commit with a brief, descriptive message based on the changes. Use bullet points when appropriate.
- Do NOT add "Generated with Claude Code" or "Co-Authored-By: Claude" to commit messages.

After saving, show a summary of what was updated.
