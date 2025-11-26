# Arch Linux Package Management

This directory tracks explicitly installed packages for easy system restoration.

## Files

- **pkglist.txt** - Official repository packages (pacman)
- **aurlist.txt** - AUR packages (installed via AUR helpers like yay/paru)

## Update Package Lists

Run these commands after installing new software:

```bash
# Update official package list
pacman -Qqen > ~/.arch/pkglist.txt

# Update AUR package list
pacman -Qqem > ~/.arch/aurlist.txt

# Then commit to dotfiles
config add ~/.arch/pkglist.txt ~/.arch/aurlist.txt
config commit -m "Update package lists"
config push
```

## Restore Packages

On a new Arch installation:

```bash
# Install official packages
sudo pacman -S --needed - < ~/.arch/pkglist.txt

# Install AUR packages (requires AUR helper like yay)
yay -S --needed - < ~/.arch/aurlist.txt
```

The `--needed` flag skips packages that are already installed.

## Notes

- Only explicitly installed packages are tracked (not dependencies)
- Dependencies are automatically installed when needed
- This follows the Arch Wiki recommended approach for package list management
