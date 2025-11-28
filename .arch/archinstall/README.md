# Archinstall Configuration

This directory contains archinstall configuration files for reproducible Arch Linux installations.

## Configuration Files

### `user_configuration.json`
Complete system configuration including:

**Key Features:**
- **Disk Layout**: 3-partition layout on `/dev/nvme0n1`:
  - 1GB `/boot` (FAT32, ESP)
  - 50GB `/` (ext4, LUKS encrypted)
  - ~880GB `/home` (ext4, LUKS encrypted)
- **Boot**: systemd-boot bootloader
- **Desktop**: Hyprland (Wayland compositor) with SDDM greeter
- **Graphics**: AMD/ATI open-source drivers
- **Audio**: PipeWire
- **Bluetooth**: Enabled
- **Network**: NetworkManager
- **Kernels**: linux and linux-lts
- **Locale**: US keyboard, en_US.UTF-8, Pacific timezone
- **Encryption**: LUKS encryption on both root and home partitions

### `user_credentials.json`
User accounts and passwords (template with empty passwords).

**Fields:**
- `encryption_password`: LUKS disk encryption password (for root and home partitions)
- `root_enc_password`: Root user account password
- `users[].enc_password`: User account password(s)
- `users[].username`: Username (currently: `jacques`)
- `users[].sudo`: Sudo access (currently: `true`)
- `users[].groups`: Additional groups (currently: empty)

**How to populate passwords:**

The `enc_password` fields use **plain text passwords**, not hashes. Despite the "enc" prefix, you provide passwords as normal strings and archinstall handles the hashing automatically during installation.

**Option 1 - Interactive (Recommended):**
- Leave all password fields as empty strings: `""`
- Archinstall will prompt you to enter passwords during installation
- Most secure - no passwords stored in files

**Option 2 - Automated:**
- Fill password fields with plain text: `"encryption_password": "MySecurePass123"`
- Archinstall will hash these automatically
- Convenient for automated installations
- **Security risk**: Never commit this file with real passwords to git!

## Usage

### Method 1: Automated Installation with Credentials

**Best for**: Fully automated installation with minimal prompts

1. **Prepare credentials file** (on a secure system before installation):
   ```bash
   # Edit user_credentials.json and add your passwords as plain text
   # archinstall will handle hashing automatically
   {
     "encryption_password": "your-strong-luks-password",
     "root_enc_password": "your-root-password",
     "users": [
       {
         "enc_password": "your-user-password",
         "username": "jacques",
         "sudo": true,
         "groups": []
       }
     ]
   }
   ```

   **⚠️ Security Warning**: Never commit files with actual passwords to git!

2. **Boot from Arch Linux installation media**

3. **Copy configuration files**:
   ```bash
   # If files are on USB drive
   mount /dev/sdX1 /mnt
   cp /mnt/.arch/archinstall/user_configuration.json /root/
   cp /mnt/.arch/archinstall/user_credentials.json /root/

   # Or download from GitHub (then edit credentials locally)
   curl -O https://raw.githubusercontent.com/frederickjjoubert/dotfiles-archlinux/main/.arch/archinstall/user_configuration.json
   curl -O https://raw.githubusercontent.com/frederickjjoubert/dotfiles-archlinux/main/.arch/archinstall/user_credentials.json

   # Edit credentials file with your passwords
   nano /root/user_credentials.json
   ```

4. **Run archinstall**:
   ```bash
   archinstall --config /root/user_configuration.json --creds /root/user_credentials.json
   ```

5. **Installation proceeds automatically** with your provided credentials

### Method 2: Interactive Password Entry (Recommended for Security)

**Best for**: Secure installation without storing passwords in files

1. **Boot from Arch Linux installation media**

2. **Copy only the configuration file**:
   ```bash
   # Leave user_credentials.json with empty passwords
   curl -O https://raw.githubusercontent.com/frederickjjoubert/dotfiles-archlinux/main/.arch/archinstall/user_configuration.json
   ```

3. **Run archinstall**:
   ```bash
   archinstall --config /root/user_configuration.json
   ```

4. **Enter passwords interactively** when prompted:
   - LUKS encryption password (for disk encryption)
   - Root password
   - User password

### Method 3: Manual Configuration

1. Boot from Arch Linux installation media
2. Run archinstall interactively:
   ```bash
   archinstall
   ```
3. Load `user_configuration.json` when prompted
4. Review/modify settings as needed
5. Enter passwords when prompted

## Customization

### Modifying User Credentials

Edit `user_credentials.json` to:

**Add/modify users**:
```json
"users": [
  {
    "username": "jacques",
    "enc_password": "",
    "sudo": true,
    "groups": ["docker", "wheel"]
  },
  {
    "username": "additional_user",
    "enc_password": "",
    "sudo": false,
    "groups": []
  }
]
```

**Password handling**:
- Leave `enc_password` fields empty (`""`) to be prompted during installation
- Or fill with plain text passwords (archinstall hashes them automatically)
- Never commit files with actual passwords to version control!

### Adding Packages

Edit `user_configuration.json` to add packages:

```json
"packages": [
  "git",
  "vim",
  "python",
  "nodejs",
  "docker",
  "rust",
  "tmux",
  "fzf",
  "ripgrep",
  "bat"
]
```

The current configuration has an empty packages array - Hyprland and its dependencies are installed via the profile, but you'll want to add your essential tools here.

### Adjusting Disk Layout

Modify `disk_config.device_modifications[0].partitions` in `user_configuration.json`:

**Change partition sizes**:
```json
"size": {
  "unit": "GiB",    // or "B" for bytes
  "value": 100      // size value
}
```

**Change device** (if not using `/dev/nvme0n1`):
```json
"device": "/dev/sda"  // or your actual device
```

**Current layout**:
- Boot: 1 GiB
- Root: 50 GiB
- Home: ~880 GiB (remaining space)

### Encryption Configuration

The current configuration uses LUKS encryption on both root and home partitions.

**To disable encryption**:
Remove or empty the `disk_encryption` section:
```json
"disk_encryption": null
```

**To encrypt only root** (not home):
Modify the `partitions` array in `disk_encryption`:
```json
"disk_encryption": {
  "encryption_type": "luks",
  "partitions": [
    "b3a21f73-860c-4203-b557-a805d6c991b2"  // root only
  ]
}
```

**Advanced**: Consider TPM2 auto-unlock (requires post-install configuration)

## Important Notes

### Pre-Installation Checklist

- [ ] **Backup all important data** - installation will wipe the target disk
- [ ] Verify boot mode is UEFI: `ls /sys/firmware/efi/efivars`
- [ ] Check network connectivity: `ping archlinux.org`
- [ ] Verify disk device name with `lsblk` (currently assumes `/dev/nvme0n1`)
- [ ] Update `user_configuration.json` if disk device differs
- [ ] Decide on password strategy (interactive vs. pre-filled credentials)
- [ ] If using pre-filled credentials, ensure file is on secure removable media only

### Encryption Considerations

- **Boot partition** (`/boot`) MUST remain unencrypted for systemd-boot
- Current config encrypts **both root and home** partitions
- You'll need to enter LUKS password on **every boot**
- Same password unlocks both root and home (single encryption password)
- Consider TPM2 auto-unlock for convenience (requires post-install configuration)
- LUKS encryption adds negligible performance overhead on modern hardware

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

## Hibernation

After using this configuration for a fresh install, you'll need to:
  1. Add resume=/dev/mapper/swap to kernel parameters (in /boot/loader/entries/*.conf)
  2. Configure initramfs hooks for resume support

## Troubleshooting

### Configuration Validation

Validate your JSON files before installation:

```bash
# Check configuration syntax
python -m json.tool user_configuration.json

# Check credentials syntax
python -m json.tool user_credentials.json
```

### Disk Device Name Issues

If your disk isn't `/dev/nvme0n1`:

```bash
# Check your actual disk device
lsblk

# Edit configuration and update device path
nano user_configuration.json
# Find: "device": "/dev/nvme0n1"
# Change to your actual device (e.g., "/dev/sda")
```

### Password Not Being Accepted

If archinstall doesn't accept your credentials file:
- Ensure passwords are plain text strings (archinstall handles hashing)
- Verify JSON syntax is valid (no trailing commas, proper quotes)
- Try leaving passwords empty and entering them interactively instead

### Version Compatibility

This configuration was created with archinstall version **3.0.11**. If you encounter issues:

```bash
# Check your archinstall version
archinstall --version

# Update to latest (from installation media)
pacman -Sy archinstall

# Schema may change between versions - consult documentation
```

### Configuration Schema Changes

If the configuration fails to load:
- Archinstall schema may have changed between versions
- Generate a new config: run `archinstall`, configure manually, save configuration
- Compare with these files and merge your customizations

## Configuration Maintenance

### Keeping Configurations Updated

When making system changes, keep configurations in sync:

**Added essential packages?**
```bash
# List explicitly installed packages
pacman -Qe > /tmp/packages.txt

# Update user_configuration.json packages array
# Add core packages you want in fresh installs
```

**Changed partition scheme?**
- Document new layout
- Update `disk_config` in `user_configuration.json`
- Test configuration on VM before physical installation

**Modified system settings?**
- Update relevant sections in `user_configuration.json`
- Locale, timezone, mirrors, services, etc.

### Exporting Current Configuration

To generate a fresh configuration from a running system:

```bash
# Boot into Arch installation media
# Mount your system and chroot (optional)

# Run archinstall to generate new config
archinstall --dry-run --save-config /path/to/new_config.json

# Compare with existing configuration
# Merge changes as needed
```

### Security Best Practices

- **Never commit actual passwords** to git repositories
- Keep `user_credentials.json` template with empty passwords in repo
- Store actual credentials on encrypted removable media only
- Consider using a password manager for installation passwords
- Rotate passwords regularly, especially encryption passwords

## References

- [Archinstall Documentation](https://archinstall.archlinux.page/)
- [Archinstall Configuration](https://archinstall.archlinux.page/installing/guided.html#configuration)
- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
