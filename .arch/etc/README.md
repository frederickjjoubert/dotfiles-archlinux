# System Configuration Files

This directory contains system configuration files for reproducible Arch Linux setup.

## Network Configuration (iwd)

Configuration for the iwd wireless daemon to prevent aggressive roaming on mesh networks.

### Files

- `iwd/main.conf` - iwd configuration with roaming optimizations

### Configuration Details

- Disables NetworkManager integration (using NetworkManager's built-in WiFi)
- Less aggressive roaming thresholds for mesh networks
- Disables automatic roaming scans to prevent constant AP switching
- Increased roam retry interval (120 seconds)

### Usage

To apply the iwd configuration:

```bash
sudo cp ~/.arch/etc/iwd/main.conf /etc/iwd/main.conf
sudo systemctl restart iwd
```

## Hibernation Configuration

This directory maintains two versions of critical system configuration files: backup (non-hibernation) and hibernation-enabled versions.

### Files

**Backup versions (original working configuration):**
- `fstab.backup` - Filesystem table without swap partition
- `mkinitcpio.conf.backup` - Initramfs configuration without resume hook

**Hibernation versions (currently active and working):**
- `fstab.hibernation` - Filesystem table with swap partition (priority 50, lower than zram)
- `mkinitcpio.conf.hibernation` - Initramfs configuration with resume hook for hibernation

### Current Status

Hibernation is **fully configured and working** on this system. The hibernation-enabled configuration includes:

- **Hybrid swap strategy:** zram0 (4 GiB, priority 100) for performance, vg0-swap (32 GiB, priority 50) for hibernation
- **Resume hook:** Properly ordered in mkinitcpio.conf after encrypt/filesystems hooks
- **WiFi fix:** systemd sleep hook handles Realtek RTL8852CE driver hibernation issues

See `.arch/boot/loader/entries/README.md` for bootloader configuration details.

See `.arch/usr/lib/systemd/system-sleep/wifi-hibernate-fix` for the WiFi module reload hook.

### Management Scripts

Use these scripts to switch between configurations:

**Enable hibernation (apply .hibernation files):**
```bash
sudo ~/scripts/enable-hibernation.sh
```

**Disable hibernation (revert to .backup files):**
```bash
sudo ~/scripts/disable-hibernation.sh
```

Both scripts handle copying configuration files, updating bootloader entries, managing the WiFi fix hook, and rebuilding the initramfs.

## Related Documentation

See `.claude/memory/swap-and-hibernation.md` for comprehensive technical documentation, testing history, and troubleshooting information.
