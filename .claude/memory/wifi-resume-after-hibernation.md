# WiFi Resume After Hibernation

## Problem Statement

After successfully hibernating and resuming, the WiFi interface (`wlan0`) disappears from the system. Running `ip addr` shows no wireless interface.

**First observed**: November 29, 2025 (first hibernation test)

## Current Status

**INVESTIGATING** - Identifying WiFi driver and root cause

### What Works
- Hibernation successfully saves state to LVM swap partition
- Resume restores desktop session with all applications open
- System boots and resumes correctly

### What's Broken
- WiFi interface `wlan0` is missing after resume
- Network connectivity lost until manual intervention

## System Configuration

- **Network Manager**: NetworkManager with iwd backend
- **WiFi Service**: iwd (wpa_supplicant disabled)
- **Network**: Eero mesh network ("JJ Home")
- **WiFi Driver**: TBD (investigating)

## Troubleshooting Steps

### 1. Identify WiFi Driver

```bash
# Check loaded WiFi modules
lsmod | grep -E 'iwlwifi|ath|rtw|mt7|brcm|iwl'

# Check dmesg for WiFi hardware
dmesg | grep -i -E 'wifi|wireless|wlan' | head -20

# List network interfaces
ls /sys/class/net/

# Check rfkill status (might be soft-blocked)
rfkill list
```

### 2. Immediate Fix (Manual)

```bash
# If WiFi is soft-blocked
rfkill unblock wifi

# Reload WiFi driver (replace 'iwlwifi' with actual driver)
sudo modprobe -r <driver_name>
sudo modprobe <driver_name>

# Restart network services
sudo systemctl restart iwd NetworkManager

# Verify interface is back
ip addr show
```

## Proposed Solution

Create a systemd service to automatically reload the WiFi driver after hibernation.

**File**: `~/.arch/etc/systemd/system/wifi-resume@.service`

```ini
[Unit]
Description=Reload WiFi driver after hibernation
After=hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/usr/bin/modprobe -r %i
ExecStart=/usr/bin/modprobe %i
ExecStart=/usr/bin/systemctl restart iwd NetworkManager

[Install]
WantedBy=hibernate.target hybrid-sleep.target suspend-then-hibernate.target
```

### Installation (once driver is identified)

```bash
# Copy the service file
sudo cp ~/.arch/etc/systemd/system/wifi-resume@.service /etc/systemd/system/

# Enable for your WiFi driver (e.g., iwlwifi)
sudo systemctl enable wifi-resume@iwlwifi.service

# Test by hibernating again
systemctl hibernate
```

## Root Cause Analysis

WiFi drivers often fail to properly restore state after hibernation because:

1. **Driver state not saved**: Some WiFi drivers don't implement proper suspend/resume hooks
2. **Firmware not reloaded**: WiFi firmware may need to be re-uploaded to the hardware
3. **rfkill blocking**: Power management may soft-block the radio after resume
4. **Race condition**: Services may start before the hardware is fully initialized

## Related Files

- WiFi config: `~/.claude/memory/wifi.md`
- Hibernation config: `~/.claude/memory/swap-and-hibernation.md`
- iwd config: `~/.arch/etc/iwd/main.conf`
- Proposed fix: `~/.arch/etc/systemd/system/wifi-resume@.service`

## References

- [Arch Wiki - Power management/Suspend and hibernate](https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate)
- [Arch Wiki - Network configuration/Wireless](https://wiki.archlinux.org/title/Network_configuration/Wireless)

