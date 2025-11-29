# Swap and Hibernation Configuration

## System Specifications

- **RAM**: 31 GB (32 GiB)
- **Disk**: NVMe 931.5GB
- **Hostname**: thinkpad
- **Kernels**: linux, linux-lts
- **Bootloader**: systemd-boot

## Current Configuration (Fresh Install - November 29, 2025)

### Storage Architecture: LVM on LUKS ✅

```
/dev/nvme0n1p1 (1GB, unencrypted)
└─ /boot (FAT32, ESP)
   UUID: 1CF6-F3C0

/dev/nvme0n1p2 (~930GB, encrypted)
└─ LUKS encryption
   UUID: 3ecf638f-95c6-4021-9916-aa9ac498a12b
   └─ cryptlvm (unlocked at boot)
      └─ LVM Physical Volume
         └─ Volume Group: vg0
            ├─ vg0-root  (50GB)  → / (ext4)
            │  UUID: a9976e10-d159-4265-bcc5-e862dc156dd3
            ├─ vg0-swap  (32GB)  → swap
            │  UUID: e1dfe787-9a72-4768-8a67-526395b4df76
            └─ vg0-home  (847GB) → /home (ext4)
               UUID: 118223a3-9e88-47c7-9860-21a7a7432ca6
```

### Swap Configuration: Hybrid Strategy ✅

**1. zram (Performance)**
- Device: zram0
- UUID: d7860db2-5c91-4410-87e8-5e5167797b70
- Priority: 100 (higher - used first)
- Purpose: Fast compressed swap for daily use

**2. LVM Swap Partition (Hibernation)**
- Device: /dev/mapper/vg0-swap
- UUID: e1dfe787-9a72-4768-8a67-526395b4df76
- Size: 32GB (matches RAM requirement)
- Priority: 50 (lower - used for hibernation)
- Location: Inside encrypted LVM

### Hibernation Status: CONFIGURED (Testing Pending)

**Configuration Applied**: November 29, 2025 at ~07:01 PST

Changes made:
1. **fstab** (`/etc/fstab`): Added swap partition with priority 50
2. **mkinitcpio** (`/etc/mkinitcpio.conf`): Added resume hook, reordered hooks for LVM on LUKS
3. **Boot loader entries** (`/boot/loader/entries/*.conf`): Added `resume=/dev/mapper/vg0-swap` parameter
4. **Initramfs**: Rebuilt with `mkinitcpio -P` for both kernels
5. **wlogout** (`~/.config/wlogout/layout`): Added hibernate option (keybind: h)

**Next Step**: Reboot to verify system boots correctly, then test hibernation

## Archinstall Configuration

Fresh installation performed with modified `user_configuration.json`:

### Key Settings

```json
{
  "bootloader": "Systemd-boot",
  "kernels": ["linux", "linux-lts"],
  "swap": true,  // Creates zram
  "disk_config": {
    "config_type": "default_layout",
    "disk_encryption": {
      "encryption_type": "lvm_on_luks",  // ← Key setting
      "partitions": ["cbdc62e7-03df-4b0d-91b7-df7a3ae9958e"]
    },
    "lvm_config": {
      "config_type": "default",
      "vol_groups": [{
        "name": "vg0",
        "volumes": [
          {
            "name": "root",
            "fs_type": "ext4",
            "mountpoint": "/",
            "length": {"unit": "GiB", "value": 50}
          },
          {
            "name": "swap",
            "fs_type": "linux-swap",
            "mountpoint": null,
            "length": {"unit": "GiB", "value": 32}  // ← Hibernate swap
          },
          {
            "name": "home",
            "fs_type": "ext4",
            "mountpoint": "/home",
            "length": {"unit": "GiB", "value": 847}
          }
        ]
      }]
    }
  }
}
```

## Hibernation Configuration Details

### Boot Loader Configuration

All four boot entries updated (`/boot/loader/entries/`):
- `linux.conf`
- `linux-lts.conf`
- `linux-fallback.conf`
- `linux-lts-fallback.conf`

**Kernel parameters**:
```
options cryptdevice=UUID=3ecf638f-95c6-4021-9916-aa9ac498a12b:cryptlvm root=/dev/vg0/root resume=/dev/mapper/vg0-swap zswap.enabled=0 rw rootfstype=ext4
```

Key parameter: `resume=/dev/mapper/vg0-swap`

### mkinitcpio Configuration

**Hooks order** (`/etc/mkinitcpio.conf`):
```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems resume fsck)
```

**Critical ordering for LVM on LUKS with hibernation**:
- `block` before `encrypt` and `lvm2` ✅
- `resume` after `filesystems` but before `fsck` ✅

### fstab Configuration

```
# /dev/mapper/vg0-root
UUID=a9976e10-d159-4265-bcc5-e862dc156dd3  /        ext4  rw,relatime  0 1

# /dev/mapper/vg0-home
UUID=118223a3-9e88-47c7-9860-21a7a7432ca6  /home    ext4  rw,relatime  0 2

# /dev/nvme0n1p1
UUID=1CF6-F3C0  /boot  vfat  rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro  0 2

# /dev/mapper/vg0-swap (priority 50, lower than zram which is 100)
UUID=e1dfe787-9a72-4768-8a67-526395b4df76  none  swap  sw,pri=50  0 0
```

## Management Scripts

Created in `~/scripts/`:

### enable-hibernation.sh
Applies hibernation configuration:
1. Copies `.hibernation` files to system locations
2. Updates boot loader entries
3. Rebuilds initramfs
4. Provides testing instructions

**Usage**: `sudo ~/scripts/enable-hibernation.sh`

### disable-hibernation.sh
Reverts to backup (non-hibernation) configuration:
1. Copies `.backup` files to system locations
2. Restores original boot loader entries
3. Rebuilds initramfs
4. Returns system to working state

**Usage**: `sudo ~/scripts/disable-hibernation.sh`

**Status**: enable-hibernation.sh run successfully on Nov 29, 2025

## Configuration File Backups

Located in `~/.arch/`:

### Boot Loader Entries
- `boot/loader/entries/*.backup` - Original working configuration
- `boot/loader/entries/*.hibernation` - Hibernation-enabled configuration

### System Configuration
- `etc/fstab.backup` - Original fstab
- `etc/fstab.hibernation` - With swap partition added
- `etc/mkinitcpio.conf.backup` - Original hooks configuration
- `etc/mkinitcpio.conf.hibernation` - With resume hook added

## Testing Procedure

### Phase 1: Reboot Test (Current)
1. Reboot system
2. Verify system boots normally
3. Check WiFi/network connectivity
4. Verify swap is mounted: `swapon --show`
5. Check resume parameter: `cat /proc/cmdline | grep resume`

### Phase 2: Hibernation Test
1. Save all work
2. Test hibernate via: `systemctl hibernate` OR wlogout (press `h`)
3. System should power off completely
4. Power on - should resume to exact same session
5. If fails, run: `sudo ~/scripts/disable-hibernation.sh`

## Troubleshooting

### Previous Issue: WiFi Breaking
- **When**: Earlier attempt to apply hibernation config
- **Cause**: Unknown (configuration files were correct)
- **Resolution**: Reverted to backups
- **Current attempt**: Successful - WiFi working after applying config

### Verification Commands

```bash
# Check swap status
swapon --show

# Verify resume parameter in kernel command line
cat /proc/cmdline

# Check systemd-hibernate service
systemctl status systemd-hibernate.service

# View hibernation logs
journalctl -u systemd-hibernate.service

# Check initramfs hooks
lsinitcpio /boot/initramfs-linux.img | grep resume
```

### Common Issues

**Hibernation fails silently**:
- Check journal: `journalctl -u systemd-hibernate.service`
- Verify swap is active and large enough
- Ensure resume parameter matches swap device

**Resume not working**:
- Verify resume hook order in mkinitcpio
- Check resume UUID matches vg0-swap
- Rebuild initramfs after changes

**Encrypted swap**:
- LUKS password entered at boot unlocks all volumes
- Resume happens automatically after unlock
- Swap must be inside same LUKS container as root

## Why LVM on LUKS Works Best

**Advantages**:
- ✅ Flexible: Resize/add/remove volumes without repartitioning
- ✅ Secure: Swap is encrypted (safe hibernation)
- ✅ Professional: Industry standard for storage management
- ✅ Simple: Single password unlocks all volumes
- ✅ Hybrid: Can combine with zram for optimal performance

**vs. Swap File**:
- Swap file requires calculating physical offset
- Swap file on Btrfs has additional complications
- LVM swap "just works" with simple UUID

## Related Files

**System Configuration**:
- `/etc/fstab` - Filesystem mount configuration
- `/etc/mkinitcpio.conf` - Initramfs hooks
- `/boot/loader/entries/*.conf` - Boot loader entries

**User Configuration**:
- `~/.arch/archinstall/user_configuration.json` - Installation configuration
- `~/.config/wlogout/layout` - Logout menu with hibernate option
- `~/scripts/enable-hibernation.sh` - Apply hibernation config
- `~/scripts/disable-hibernation.sh` - Revert to backups

**Backups**:
- `~/.arch/boot/loader/entries/*.backup` - Safe boot configs
- `~/.arch/boot/loader/entries/*.hibernation` - Hibernate boot configs
- `~/.arch/etc/fstab.{backup,hibernation}` - fstab versions
- `~/.arch/etc/mkinitcpio.conf.{backup,hibernation}` - Hook configurations

## References

- Arch Wiki: Power management/Suspend and hibernate
- Arch Wiki: Dm-crypt/Encrypting an entire system#LVM on LUKS
- Arch Wiki: Swap
- systemd-boot documentation
