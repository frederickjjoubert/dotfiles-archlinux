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

## Manual Installation Steps

Some tools require manual installation after restoring packages:

### Node Version Manager (nvm)

```bash
# Install nvm (v0.40.3)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Reload shell or source bashrc
source ~/.bashrc

# Install Node.js (example)
nvm install node
```

The nvm initialization code is already in `.bashrc`, so it will work after installation.

### iwd Configuration

After system restore, copy the iwd config back to system location:

```bash
sudo cp ~/.config/iwd/main.conf /etc/iwd/main.conf
sudo systemctl restart iwd
```

## Notes

- Only explicitly installed packages are tracked (not dependencies)
- Dependencies are automatically installed when needed
- This follows the Arch Wiki recommended approach for package list management
