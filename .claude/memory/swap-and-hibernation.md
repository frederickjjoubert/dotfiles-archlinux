# Swap and Hibernation Configuration

## System Specifications
- **RAM**: 31 GB (32 GiB)
- **Disk**: NVMe 931.5GB
  - `/dev/nvme0n1p1`: 1GB `/boot` (vfat, unencrypted)
  - `/dev/nvme0n1p2`: 50GB `/` (ext4, LUKS encrypted)
  - `/dev/nvme0n1p3`: 880.5GB `/home` (ext4, LUKS encrypted)

## Current Configuration (As Installed - November 2025)
- **Storage Layout**: Direct LUKS on partitions (NO LVM)
- **Swap Type**: zram only (4GB compressed RAM swap)
- **Hibernation**: DISABLED - zram cannot persist to disk
- **Status**: Hibernation removed from wlogout (not supported with current setup)

## Best Practice: Hybrid Swap Strategy

For optimal performance AND hibernation support, use:

### 1. Swap File (for hibernation)
- **Location**: `/swapfile` on encrypted root partition
- **Size**: 32GB minimum (≥ RAM size)
- **Purpose**: Hibernation resume image storage
- **Priority**: Lower (50)

### 2. zram (for performance)
- **Size**: 4GB (or 25-50% of RAM)
- **Purpose**: Fast compressed swap for daily use
- **Priority**: Higher (100) - used first

### Why This Approach?
- zram handles most swapping (faster, no disk wear)
- Swapfile only used for hibernation
- Best of both worlds: performance + hibernation capability

## Archinstall Configuration Changes

### Current Setting (Lines 290-291 of user_configuration.json)
```json
"swap": true,
```

**This creates zram ONLY** - no hibernation support.

### Recommended Future Installation Strategy: LVM on LUKS (BEST)

**Why LVM?**
- Easily resize/add/remove volumes after installation
- No repartitioning needed to add swap later
- Snapshot support for backups
- Professional standard for flexible storage management

**Architecture:**
```
/dev/nvme0n1p1 (1GB, unencrypted)
└─ /boot (FAT32, ESP)

/dev/nvme0n1p2 (~930GB, encrypted)
└─ LUKS encryption
   └─ LVM Physical Volume
      └─ Volume Group (vg0)
         ├─ root (50GB) → /
         ├─ swap (32GB) → swap
         └─ home (remaining) → /home
```

**Archinstall Configuration Changes:**

⚠️ **Note**: As of archinstall 3.0.11, LVM support may require manual configuration or newer archinstall version. Check archinstall documentation for LVM schema.

**High-level approach:**
1. Create 2 partitions: `/boot` (1GB, unencrypted) and one large encrypted partition
2. Inside LUKS, create LVM with three logical volumes: root, swap, home
3. Enable zram with `"swap": true` for hybrid performance

**Alternative if archinstall doesn't support LVM directly:**
- Use manual installation with `cryptsetup` + `lvm2`
- Or use archinstall with manual post-config
- Or create swap file post-install (see Option B below)

### Alternative: Swap Partition Without LVM

If not using LVM, add a dedicated swap partition:

Modify partition layout in `user_configuration.json` to add a 4th partition between root and home:

```json
"partitions": [
    {
        "fs_type": "fat32",
        "mountpoint": "/boot",
        "size": {"unit": "GiB", "value": 1},
        "flags": ["boot", "esp"],
        "type": "primary"
    },
    {
        "fs_type": "ext4",
        "mountpoint": "/",
        "size": {"unit": "GiB", "value": 50},
        "obj_id": "b3a21f73-860c-4203-b557-a805d6c991b2",
        "type": "primary"
    },
    {
        "fs_type": "swap",
        "mountpoint": null,
        "size": {"unit": "GiB", "value": 32},
        "obj_id": "SWAP-PARTITION-UUID",
        "type": "primary"
    },
    {
        "fs_type": "ext4",
        "mountpoint": "/home",
        "flags": ["linux-home"],
        "size": {"unit": "B", "value": <remaining-space>},
        "obj_id": "677c000f-d1b3-42a6-bdce-8d8044c10b08",
        "type": "primary"
    }
]
```

Add swap partition to encryption:
```json
"disk_encryption": {
    "encryption_type": "luks",
    "partitions": [
        "b3a21f73-860c-4203-b557-a805d6c991b2",  // root
        "SWAP-PARTITION-UUID",                    // swap - ADD THIS
        "677c000f-d1b3-42a6-bdce-8d8044c10b08"   // home
    ]
}
```

Keep zram enabled:
```json
"swap": true,  // This adds zram in addition to swap partition
```

**Drawback**: Not flexible after install (would need to repartition to change sizes)

**Option B: Post-Install Swap File (CURRENT SYSTEM)**

Keep `"swap": true` in archinstall config, then after installation:

1. Create swap file:
```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=32768 status=progress
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon --priority 50 /swapfile
```

2. Add to `/etc/fstab`:
```
/swapfile none swap sw,pri=50 0 0
```

3. Configure zram priority (ensure it's higher):
```bash
# Check current zram priority
swapon --show
# Should show zram0 with priority 100, swapfile with priority 50
```

## Hibernation Resume Configuration

After creating persistent swap, configure resume:

### 1. Find Swap Location
```bash
# For swap file:
findmnt -no UUID -T /swapfile
filefrag -v /swapfile | head -n 5  # Get physical offset

# For swap partition:
blkid /dev/nvme0n1p3  # Get UUID
```

### 2. Update Bootloader (systemd-boot)

Edit `/boot/loader/entries/arch.conf`:
```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/mapper/root resume=UUID=<swap-uuid> resume_offset=<offset-if-file> rw quiet
```

For encrypted swap, use:
```
options ... resume=/dev/mapper/swap ...
```

### 3. Update mkinitcpio

Edit `/etc/mkinitcpio.conf`:
```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems resume fsck)
```

Note: `resume` hook must come AFTER `encrypt` and `filesystems`.

Rebuild initramfs:
```bash
sudo mkinitcpio -P
```

### 4. Test Hibernation
```bash
systemctl hibernate
```

## Current System Migration Path

To enable hibernation on the current system:

1. **Check available space** on root partition
2. **Create 32GB swap file** on `/` (encrypted partition)
3. **Configure resume parameters** in bootloader
4. **Update initramfs** with resume hook
5. **Keep zram** for daily performance
6. **Test hibernate** from wlogout

Space requirement: ~32GB on root (currently using ? of 50GB)

## Package Requirements

Hibernation works with base packages, but useful tools:
- `systemd` (already installed) - provides systemctl hibernate
- `pm-utils` (optional) - additional power management
- `uswsusp` (optional alternative) - userspace software suspend

## Troubleshooting

### Hibernation Fails Silently
- Check journal: `journalctl -u systemd-hibernate.service`
- Verify resume parameter in kernel cmdline: `cat /proc/cmdline`
- Check swap is active: `swapon --show`
- Ensure swap is large enough: `free -h` vs swap size

### Resume Not Working
- Verify resume hook is AFTER encrypt in mkinitcpio
- Check resume UUID matches actual swap device
- For swap file: verify offset is correct
- Rebuild initramfs after changes

### Encrypted Swap Issues
- Root partition must be unlocked before resume
- LUKS password entered at boot unlocks all encrypted partitions
- Resume happens automatically after unlock

## Related Files
- Archinstall config: `~/.arch/archinstall/user_configuration.json`
- wlogout config: `~/.config/wlogout/layout`
- Bootloader: `/boot/loader/entries/arch.conf`
- Initramfs: `/etc/mkinitcpio.conf`
- Fstab: `/etc/fstab`

## References
- Arch Wiki: Power management/Suspend and hibernate
- Arch Wiki: Swap (for swap file creation)
- Arch Wiki: Dm-crypt/Swap encryption
