# System Configuration Files

This directory contains system configuration files for reproducible Arch Linux setup.

## Hibernation Configuration

These files enable hibernation with the LVM swap partition.

### Files Included

- `fstab` - Filesystem table with swap partition (priority 50, lower than zram)
- `mkinitcpio.conf` - Initramfs configuration with resume hook
- `boot/loader/entries/*.conf` - Bootloader entries with resume parameter

### Installation

Run these commands to apply the hibernation configuration:

```bash
# 1. Copy fstab
sudo cp ~/.arch/etc/fstab /etc/fstab

# 2. Copy bootloader entries
sudo cp ~/.arch/boot/loader/entries/*.conf /boot/loader/entries/

# 3. Copy mkinitcpio.conf
sudo cp ~/.arch/etc/mkinitcpio.conf /etc/mkinitcpio.conf

# 4. Rebuild initramfs for all kernels
sudo mkinitcpio -P

# 5. Verify swap is active (if not already done)
sudo swapon --priority 50 /dev/mapper/vg0-swap
swapon --show  # Should show both zram0 (pri=100) and vg0-swap (pri=50)
```

### Testing Hibernation

After installation and reboot:

```bash
# Test hibernation
systemctl hibernate
```

The system should:
1. Save state to swap partition
2. Power off
3. Resume on next boot with all applications restored

### Configuration Details

**Swap Strategy (Hybrid):**
- zram0: 4 GiB (priority 100) - Used first for performance
- vg0-swap: 32 GiB (priority 50) - Used for hibernation

**Resume Configuration:**
- Bootloader: `resume=/dev/mapper/vg0-swap`
- mkinitcpio: `resume` hook added after `filesystems`

**Important:** The `resume` hook must come AFTER `encrypt` and `filesystems` hooks in mkinitcpio.conf.

### Troubleshooting

If hibernation fails:

```bash
# Check resume parameter is in kernel command line
cat /proc/cmdline | grep resume

# Check swap is active
swapon --show

# Check hibernation service logs
journalctl -u systemd-hibernate.service

# Verify resume hook in initramfs
lsinitcpio /boot/initramfs-linux.img | grep resume
```

## Related Documentation

See `.claude/memory/swap-and-hibernation.md` for detailed technical documentation.
