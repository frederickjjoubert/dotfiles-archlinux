# WiFi Configuration

## Network Setup

- **Network Manager**: NetworkManager with iwd backend
- **WiFi Service**: iwd (wpa_supplicant disabled)
- **Network**: Eero mesh network ("JJ Home")
- **Config Files**:
  - `/etc/iwd/main.conf` - iwd configuration optimized for mesh stability
  - `/etc/NetworkManager/conf.d/iwd.conf` - NetworkManager backend configuration

## Issue History

### Problem: Frequent Disconnections on Eero Mesh Network

**Symptoms**: WiFi constantly connecting and disconnecting as the system jumped between different Eero mesh nodes.

**Root Cause**:
1. Multiple WiFi managers running simultaneously (wpa_supplicant, iwd, and NetworkManager)
2. Aggressive roaming thresholds causing constant AP switching in mesh environment

**Solution Applied**:
1. Configured NetworkManager to use iwd as WiFi backend instead of wpa_supplicant
2. Disabled wpa_supplicant service (cannot uninstall due to NetworkManager package dependency)
3. Optimized iwd roaming settings for mesh networks

## Current iwd Configuration

**File**: `/etc/iwd/main.conf`

```ini
[General]
EnableNetworkConfiguration=false
# Less aggressive roaming for mesh networks
RoamThreshold=-70
RoamThreshold5G=-75
# Increase roam retry interval (default is 60 seconds)
RoamRetryInterval=120

[Scan]
# Disable roaming scans - prevents constant AP switching
DisableRoamingScan=true
DisablePeriodicScan=false
```

### Key Settings Explained

- **RoamThreshold=-70**: Only roam when 2.4GHz signal drops below -70 dBm (less aggressive than default -80)
- **RoamThreshold5G=-75**: Only roam when 5GHz signal drops below -75 dBm (less aggressive than default -85)
- **RoamRetryInterval=120**: Wait 2 minutes between roaming attempts (reduces constant switching)
- **DisableRoamingScan=true**: Prevents active scanning while connected

These settings make the connection "stickier" to the current Eero node, reducing disconnections.

## NetworkManager Configuration

**File**: `/etc/NetworkManager/conf.d/iwd.conf`

```ini
[device]
wifi.backend=iwd
```

This tells NetworkManager to use iwd instead of wpa_supplicant for WiFi management.

## Verification Commands

```bash
# Check which services are running
systemctl status iwd NetworkManager
systemctl is-active wpa_supplicant  # Should be 'inactive'

# Check WiFi connection status
nmcli device status
nmcli device wifi list

# View iwd logs
journalctl -u iwd -f

# Check connection details
nmcli connection show "JJ Home"
```

## Service States

- **iwd**: enabled and active
- **NetworkManager**: enabled and active
- **wpa_supplicant**: disabled and inactive (but package installed due to NetworkManager dependency)

## Notes

- If disconnections still occur, roaming thresholds can be made even less aggressive (e.g., -65 dBm)
- The system should now maintain more stable connections even when moving between Eero nodes
- Monitor connection stability over time to determine if further tuning is needed
