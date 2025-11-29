# Logout Issue History and Resolution

## Problem Description

When clicking logout from wlogout (accessed via waybar top-left button), the system exits to a black screen with a blinking underscore cursor (`_`) instead of returning to the SDDM login screen.

Recovery required either:

- Force reboot, OR
- CTRL+ALT+F3 to switch to TTY3, login, and run `systemctl restart sddm`

## Root Cause

The issue stems from using **UWSM (Universal Wayland Session Manager)** with SDDM. When UWSM stops the Wayland compositor session, SDDM doesn't detect the session termination properly and fails to restart its greeter, resulting in a black screen.

This is a known issue documented in multiple forums:

- [SDDM gets black screen after logout from Hyprland UWSM](https://discourse.nixos.org/t/sddm-gets-black-screen-after-logout-from-hyprland-uwsm/66777)
- [Terminating session with loginctl causes Hyprland to exit status 1](https://github.com/hyprwm/Hyprland/issues/4399)

**Important**: Hyprland documentation states that UWSM is "for advanced users and has its issues and additional quirks" ([Hyprland Wiki - Systemd start](https://wiki.hypr.land/Useful-Utilities/Systemd-start/)). It's not recommended for most users due to these compatibility issues.

## Failed Attempts

All of these commands resulted in the same black screen issue when used with the UWSM-managed Hyprland session:

1. `loginctl terminate-user $USER`
2. `sleep 1; hyprctl dispatch exit`
3. `uwsm stop`

## Solution

### Primary Solution (Recommended)

Switch from "Hyprland (uwsm-managed)" to regular "Hyprland" session:

1. At SDDM login screen, select the regular "Hyprland" session instead of "Hyprland (uwsm-managed)"
2. Use logout command: `hyprctl dispatch exit`

### Session Files

Located in `/usr/share/wayland-sessions/`:

- `hyprland.desktop` - Regular Hyprland session (Exec=Hyprland)
- `hyprland-uwsm.desktop` - UWSM-managed session (Exec=uwsm start -- hyprland.desktop)

## Configuration Files

### Waybar

- Config: `~/.config/waybar/config`
- Power button (top-left): Custom module that launches wlogout on click

### wlogout

- Layout: `~/.config/wlogout/layout`
- Logout action updated to: `hyprctl dispatch exit`

## Alternative Solutions (Not Pursued)

1. **Polkit rule for passwordless SDDM restart**: Would allow `pkexec systemctl restart sddm` without password prompt, but requires additional configuration and still uses UWSM.

2. **Keep using UWSM with workarounds**: Not recommended due to experimental status and inherent compatibility issues with SDDM.

## Status

**RESOLVED** - Option 1 (Primary Solution) confirmed working:

- Switched from "Hyprland (uwsm-managed)" to regular "Hyprland" session
- Using `hyprctl dispatch exit` for logout
- System now properly returns to SDDM login screen after logout
- No longer using UWSM
