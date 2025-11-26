# Archinstall Profiles

This directory contains archinstall configuration profiles for reproducible Arch Linux installations.

## Available Profiles

### `thinkpad-e16.json`
Base configuration for ThinkPad E16 Gen 2 without encryption.

**Key Features:**
- 3-partition layout: 1GB /boot (FAT32), 100GB / (ext4), remaining /home (ext4)
- systemd-boot bootloader
- Hyprland window manager (Wayland compositor)
- Essential Hyprland ecosystem: kitty, wofi, dunst, hyprpaper, grim, slurp
- NetworkManager for networking
- US locale and Pacific timezone
- Base development tools included

### `thinkpad-e16-encrypted.json`
Same as above but with LUKS encryption on the root partition.

**Key Features:**
- All features from base profile
- LUKS encryption on root partition (partition_2)
- Encryption password will be prompted during installation
- /boot remains unencrypted (required for systemd-boot)

## Usage

### Method 1: Using archinstall on Installation Media

1. Boot from Arch Linux installation media
2. Copy your desired profile to the installation environment:
   ```bash
   # If profile is on USB drive
   mount /dev/sdX1 /mnt
   cp /mnt/.arch/archinstall/thinkpad-e16.json /root/

   # Or download from GitHub
   curl -O https://raw.githubusercontent.com/frederickjjoubert/dotfiles-archlinux/main/.arch/archinstall/thinkpad-e16.json
   ```

3. Run archinstall with the profile:
   ```bash
   archinstall --config /root/thinkpad-e16.json
   ```

4. Follow any interactive prompts (user creation, passwords, etc.)

### Method 2: Interactive Installation with Profile Reference

1. Boot from Arch Linux installation media
2. Run archinstall normally:
   ```bash
   archinstall
   ```

3. When asked if you want to load a configuration, select "Yes"
4. Point to your profile JSON file
5. Review and modify settings as needed
6. Proceed with installation

## Customization

### User Configuration
The profiles don't include user configuration. During installation you'll be prompted to:
- Create your username
- Set user password
- Set root password (optional)
- Configure sudo access

### Packages
The `packages` array in the JSON contains essential packages. You may want to add:
- Development tools: `python`, `nodejs`, `docker`, `rust`
- Utilities: `tmux`, `fzf`, `ripgrep`, `bat`
- Applications specific to your workflow

### Disk Layout
The current profiles assume a ~1TB NVMe drive. Adjust partition sizes in `disk_config.device_modifications[0].partitions` if needed:

```json
"length": {
  "unit": "GiB",      // or "percentage" for remaining space
  "value": 100        // size in GiB or percentage
}
```

### Encryption Options
For the encrypted profile, you can modify:
- Encryption type (currently LUKS)
- Which partitions to encrypt (currently only root)
- Consider enabling TPM2 auto-unlock if available

## Important Notes

### Pre-Installation Checklist
- [ ] Backup all important data
- [ ] Verify boot mode (should be UEFI)
- [ ] Check network connectivity
- [ ] Verify disk device name (`lsblk` - currently assumes `/dev/nvme0n1`)
- [ ] Update profile if disk device differs

### Encryption Considerations
- Boot partition (`/boot`) MUST remain unencrypted for systemd-boot
- You'll need to enter encryption password on every boot
- Consider TPM2 auto-unlock for convenience (requires additional configuration)
- Separate `/home` encryption is possible but not configured in current profile

### Post-Installation
After installation completes:
1. Reboot and login
2. Clone your dotfiles:
   ```bash
   git clone --bare git@github.com:frederickjjoubert/dotfiles-archlinux.git $HOME/.dotfiles
   /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout
   ```
3. Install additional packages from `.arch/packages/`
4. Configure your environment

## Troubleshooting

### Profile Validation
To check if your profile is valid JSON:
```bash
python -m json.tool thinkpad-e16.json
```

### Disk Device Name
If your disk isn't `/dev/nvme0n1`, update the profile:
```bash
# Check your disk name
lsblk

# Edit profile and change "device": "/dev/nvme0n1" to your actual device
```

### Version Compatibility
These profiles were created for archinstall version 2.8.3. If you encounter issues:
- Check archinstall version: `archinstall --version`
- Update to latest: `pacman -Sy archinstall`
- Consult archinstall documentation for schema changes

## Profile Maintenance

When making system changes, consider updating these profiles:
- Added essential packages? Update `packages` array
- Changed partition scheme? Update `disk_config`
- Modified system settings? Update respective configuration sections

To export current system configuration (requires booting into installation media):
```bash
# From running system, document current state
pacman -Qe > explicitly-installed.txt
```

## References

- [Archinstall Documentation](https://archinstall.archlinux.page/)
- [Archinstall Configuration](https://archinstall.archlinux.page/installing/guided.html#configuration)
- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
