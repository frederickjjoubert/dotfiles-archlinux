# Swap and Hibernation Configuration

## System Specifications

- **RAM**: 31 GB (32 GiB)
- **Disk**: NVMe 931.5GB
- **Hostname**: thinkpad
- **Kernels**: linux, linux-lts
- **Bootloader**: systemd-boot
- **WiFi**: Realtek RTL8852CE (802.11ax) using rtw89_8852ce driver

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

### Hibernation Status: ✅ FULLY TESTED AND WORKING

**Configuration Applied**: November 29, 2025 at ~07:01 PST
**WiFi Fix Added**: November 29, 2025 at ~07:30 PST
**Testing Completed**: November 29, 2025

Changes made:
1. **fstab** (`/etc/fstab`): Added swap partition with priority 50
2. **mkinitcpio** (`/etc/mkinitcpio.conf`): Added resume hook, reordered hooks for LVM on LUKS
3. **Boot loader entries** (`/boot/loader/entries/*.conf`): Added `resume=/dev/mapper/vg0-swap` parameter
4. **Initramfs**: Rebuilt with `mkinitcpio -P` for both kernels
5. **wlogout** (`~/.config/wlogout/layout`): Added hibernate option (keybind: h)
6. **WiFi hibernation fix** (`/usr/lib/systemd/system-sleep/wifi-hibernate-fix`): Systemd sleep hook to reload WiFi modules

**Issue Found & Fixed**:
- **Problem**: Hibernation worked but WiFi broke on resume (rtw89_8852ce driver timeout error -110)
- **Root Cause**: Realtek RTL8852CE WiFi driver fails to resume from hibernation (ieee80211 phy0 wiphy_resume timeout)
- **Solution**: systemd sleep hook that unloads WiFi modules before hibernation and reloads after resume

**Testing Results**: ✅ ALL PASSED
- ✅ Hibernation successful (system powers off completely)
- ✅ Resume from hibernation successful (session restored)
- ✅ WiFi working after hibernation resume
- ✅ Reboot successful
- ✅ Shutdown and restart successful
- ✅ WiFi working after all operations

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
3. Installs WiFi hibernation fix hook
4. Rebuilds initramfs
5. Provides testing instructions

**Usage**: `sudo ~/scripts/enable-hibernation.sh`

### disable-hibernation.sh
Reverts to backup (non-hibernation) configuration:
1. Copies `.backup` files to system locations
2. Restores original boot loader entries
3. Removes WiFi hibernation fix hook
4. Rebuilds initramfs
5. Returns system to working state

**Usage**: `sudo ~/scripts/disable-hibernation.sh`

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

### Phase 1: Reboot Test ✅ COMPLETED
1. ✅ Reboot system
2. ✅ Verify system boots normally
3. ✅ Check WiFi/network connectivity
4. ✅ Verify swap is mounted: `swapon --show`
5. ✅ Check resume parameter: `cat /proc/cmdline | grep resume`

### Phase 2: Hibernation Test ✅ COMPLETED
1. ✅ Save all work
2. ✅ Test hibernate via: `systemctl hibernate` OR wlogout (press `h`)
3. ✅ System powered off completely
4. ✅ Power on - resumed to exact same session
5. ✅ WiFi working after resume (systemd sleep hook successful)

### Additional Testing ✅ COMPLETED
1. ✅ Multiple reboot cycles
2. ✅ Shutdown and restart cycles
3. ✅ WiFi stability verified across all power states

## Troubleshooting

### WiFi Breaking After Hibernation (RESOLVED)

**Timeline**:
1. Nov 29 ~07:01 PST: Applied hibernation config, rebooted - WiFi worked
2. Nov 29 ~07:23 PST: Tested hibernation - system hibernated and resumed successfully
3. **Problem**: WiFi not working after resume (wlan0 interface missing)
4. Rebooted - WiFi still broken
5. Ran disable script - WiFi restored

**Root Cause Identified**:
```
Nov 29 07:23:36 kernel: ieee80211 phy0: PM: dpm_run_callback(): wiphy_resume [cfg80211] returns -110
Nov 29 07:23:36 kernel: ieee80211 phy0: PM: failed to restore async: error -110
```
- Error -110 = ETIMEDOUT
- Realtek RTL8852CE WiFi chip (rtw89_8852ce driver) fails to resume from hibernation
- Driver doesn't properly handle the suspend/resume cycle for hibernation

**Solution Implemented**:
- Created systemd sleep hook: `~/.arch/usr/lib/systemd/system-sleep/wifi-hibernate-fix`
- Hook unloads WiFi modules before hibernation: rtw89_8852ce, rtw89_pci, rtw89_core
- Hook reloads modules after resume
- Updated enable/disable scripts to install/remove the hook

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
- `/usr/lib/systemd/system-sleep/wifi-hibernate-fix` - WiFi module reload hook (installed by enable script)

**User Configuration**:
- `~/.arch/archinstall/user_configuration.json` - Installation configuration
- `~/.config/wlogout/layout` - Logout menu with hibernate option
- `~/scripts/enable-hibernation.sh` - Apply hibernation config
- `~/scripts/disable-hibernation.sh` - Revert to backups

**Backups & Config Files**:
- `~/.arch/boot/loader/entries/*.backup` - Safe boot configs
- `~/.arch/boot/loader/entries/*.hibernation` - Hibernate boot configs
- `~/.arch/etc/fstab.{backup,hibernation}` - fstab versions
- `~/.arch/etc/mkinitcpio.conf.{backup,hibernation}` - Hook configurations
- `~/.arch/usr/lib/systemd/system-sleep/wifi-hibernate-fix` - WiFi module reload hook

## References

- Arch Wiki: Power management/Suspend and hibernate
- Arch Wiki: Dm-crypt/Encrypting an entire system#LVM on LUKS
- Arch Wiki: Swap
- systemd-boot documentation
