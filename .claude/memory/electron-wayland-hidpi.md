# Electron Apps on Wayland with HiDPI/Fractional Scaling

## Problem

Electron apps running under XWayland appear blurry/pixelated on displays with fractional scaling (e.g., 1.5x on the laptop screen eDP-1). This is because XWayland renders at a lower resolution and scales up.

## Display Configuration

- **Laptop (eDP-1)**: 1920x1200 @ 1.5x scale
- **External (DP-2)**: 3440x1440 @ 1.0x scale

Apps look fine on the external monitor but grainy on the laptop due to fractional scaling.

## Solution: Force Native Wayland

Electron apps need these flags to run natively on Wayland:
```
--enable-features=UseOzonePlatform
--ozone-platform=wayland
```

### Apps That Read Flags Files (Cursor, Kiro)

These apps have wrapper scripts that read `~/.config/{appname}-flags.conf`:

- `~/.config/cursor-flags.conf`
- `~/.config/kiro-flags.conf`

Kiro also has:
- Wrapper script: `~/.local/bin/kiro`
- Desktop entry: `~/.local/share/applications/kiro.desktop`

### Docker Desktop (Special Case)

Docker Desktop's launcher binary (`/opt/docker-desktop/bin/docker-desktop`) spawns the Electron UI internally and does NOT forward flags from config files.

**Fix applied (requires sudo):**

1. Renamed original binary:
   ```bash
   sudo mv "/opt/docker-desktop/Docker Desktop" "/opt/docker-desktop/Docker Desktop.bin"
   ```

2. Created wrapper script at `/opt/docker-desktop/Docker Desktop`:
   ```bash
   #!/bin/bash
   exec "/opt/docker-desktop/Docker Desktop.bin" --enable-features=UseOzonePlatform --ozone-platform=wayland "$@"
   ```

3. Set permissions:
   ```bash
   sudo chmod 755 "/opt/docker-desktop/Docker Desktop"
   ```

## Verification

Check if an app is running native Wayland vs XWayland:
```bash
hyprctl clients | grep -A 15 -i <appname>
```

- `xwayland: 0` = Native Wayland (good)
- `xwayland: 1` = XWayland (will be blurry with fractional scaling)

## Maintenance

The Docker Desktop fix modifies files in `/opt/docker-desktop/` which will be overwritten on package updates. After updating `docker-desktop` package, the fix needs to be reapplied.

Consider creating a pacman hook to automate this if updates are frequent.

## References

- [Arch Wiki - HiDPI](https://wiki.archlinux.org/title/HiDPI)
- [Hyprland Wiki - XWayland](https://wiki.hypr.land/Configuring/XWayland/)
