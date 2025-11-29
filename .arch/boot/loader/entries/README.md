# Bootloader Configuration Files

This directory contains systemd-boot loader entries for all installed kernels with both backup (non-hibernation) and hibernation-enabled versions.

## Files

This directory maintains two versions of each bootloader entry:

**Backup versions (original working configuration):**
- `linux.conf.backup` - Main kernel entry without hibernation
- `linux-lts.conf.backup` - LTS kernel entry without hibernation
- `linux-fallback.conf.backup` - Main kernel fallback entry without hibernation
- `linux-lts-fallback.conf.backup` - LTS kernel fallback entry without hibernation

**Hibernation versions (currently active and working):**
- `linux.conf.hibernation` - Main kernel entry with resume parameter
- `linux-lts.conf.hibernation` - LTS kernel entry with resume parameter
- `linux-fallback.conf.hibernation` - Main kernel fallback entry with resume parameter
- `linux-lts-fallback.conf.hibernation` - LTS kernel fallback entry with resume parameter

## Current Status

The system is currently using the **hibernation-enabled** bootloader entries. These entries include the `resume=/dev/mapper/vg0-swap` kernel parameter required for hibernation to function.

### Configuration Details

**Hibernation kernel parameters:**
```
cryptdevice=UUID=3ecf638f-95c6-4021-9916-aa9ac498a12b:cryptlvm root=/dev/vg0/root resume=/dev/mapper/vg0-swap zswap.enabled=0 rw rootfstype=ext4
```

Key parameter: `resume=/dev/mapper/vg0-swap` enables resume from hibernation using the encrypted LVM swap partition.

**Backup kernel parameters:**
Same as above but without the `resume=/dev/mapper/vg0-swap` parameter.

## Management Scripts

Use these scripts to switch between configurations:

**Enable hibernation (apply .hibernation files):**
```bash
sudo ~/scripts/enable-hibernation.sh
```

**Disable hibernation (revert to .backup files):**
```bash
sudo ~/scripts/disable-hibernation.sh
```

The scripts automatically copy the appropriate versions to `/boot/loader/entries/` and rebuild the initramfs.

## Active Boot Entries

The actual boot entries used by the system are located in `/boot/loader/entries/`:
- `linux.conf`
- `linux-lts.conf`
- `linux-fallback.conf`
- `linux-lts-fallback.conf`

These files are overwritten by the management scripts depending on which configuration is active.

## Related Documentation

See `.arch/etc/README.md` for system configuration files (fstab, mkinitcpio).

See `.claude/memory/swap-and-hibernation.md` for comprehensive technical documentation.
