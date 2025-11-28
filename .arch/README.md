# Arch Linux System Configuration

This directory tracks system configuration and packages for easy system restoration.

## Files

- **pkglist.txt** - Official repository packages (pacman)
- **aurlist.txt** - AUR packages (installed via AUR helpers like paru)
- **archinstall/user_configuration.json** - Archinstall configuration with swap partition for hibernation

## Setup Flow (New System)

Follow these steps in order to restore packages on a new Arch installation:

### 1. Install Official Packages

Install all packages from the official repositories:

```bash
sudo pacman -S --needed - < ~/.arch/pkglist.txt
```

The `--needed` flag skips packages that are already installed.

### 2. Set Up Rust Toolchain

Rustup should now be installed. Set the stable toolchain as default:

```bash
rustup default stable
```

### 3. Install Paru (AUR Helper)

Clone and build paru from the AUR:

```bash
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

This will compile paru using Rust and install it system-wide.

### 4. Install AUR Packages

Now use paru to install AUR packages:

```bash
paru -S cursor-bin
```

Or install all packages from aurlist.txt:

```bash
paru -S --needed - < ~/.arch/aurlist.txt
```

### 5. Additional Setup

#### Node Version Manager (nvm)

If you need Node.js, install nvm:

```bash
# Install nvm (v0.40.3)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Reload shell
source ~/.bashrc

# Install Node.js
nvm install node
```

The nvm initialization code is already in `.bashrc`, so it will work after installation.

#### iwd Configuration

Copy the iwd config to system location:

```bash
sudo cp ~/.config/iwd/main.conf /etc/iwd/main.conf
sudo systemctl restart iwd
```

#### Hyprland Wallpaper

After installing all packages, start hyprpaper for wallpaper:

```bash
hyprpaper &
```

Or reload Hyprland to auto-start it:

```bash
hyprctl reload
```

## Update Package Lists

Run these commands after installing new software to keep the lists current:

```bash
# Update official package list
pacman -Qqen > ~/.arch/pkglist.txt

# Update AUR package list
pacman -Qqem > ~/.arch/aurlist.txt

# Commit changes to dotfiles
config add ~/.arch/pkglist.txt ~/.arch/aurlist.txt
config commit -m "Update package lists"
config push
```

## System Configuration

### Partition Layout
- `/boot` (EFI): 1GB
- `/` (root): 50GB (LUKS encrypted)
- `swap`: 32GB (LUKS encrypted, supports hibernation)
- `/home`: ~848GB (LUKS encrypted)

### Swap Configuration
- **Disk Swap**: 32GB LUKS-encrypted partition (for hibernation)
- **Zram**: 4GB compressed RAM swap (active, for performance)
- System uses both: zram for speed, disk swap for hibernation

### Enabling Hibernation

After installation, configure hibernation support:

1. Find your swap partition UUID:
```bash
lsblk -f | grep swap
```

2. Add resume parameter to bootloader (edit `/boot/loader/entries/*.conf`):
```
options ... resume=/dev/mapper/swap ...
```

3. Add resume hook to `/etc/mkinitcpio.conf` (before `filesystems`):
```
HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 resume filesystems fsck)
```

4. Regenerate initramfs:
```bash
sudo mkinitcpio -P
```

5. Test hibernation:
```bash
systemctl hibernate
```

## Notes

- Only explicitly installed packages are tracked (not dependencies)
- Dependencies are automatically installed when needed
- This follows the Arch Wiki recommended approach for package list management
- The pkglist.txt is curated for Hyprland
- All data partitions (root, swap, home) use LUKS encryption
