# Steam on Arch Linux with Hyprland

## Installation

Steam requires the `multilib` repository for 32-bit libraries.

### Enable multilib

In `/etc/pacman.conf`, uncomment:
```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Then sync: `sudo pacman -Sy`

### Install packages (AMD GPU)

```bash
sudo pacman -S lib32-vulkan-radeon lib32-mesa steam
```

For AMD integrated/discrete graphics, use `lib32-vulkan-radeon` (Mesa RADV driver) - do NOT accept the default `lib32-nvidia-utils` when prompted.

## Hyprland Configuration

### Fullscreen games (hide waybar)

Steam games run in borderless window mode by default. To make them fullscreen at the compositor level (hiding waybar):

```
windowrulev2 = fullscreen, class:^(steam_app_.*)$
```

This rule matches most Steam games. Some native Linux games may use custom class names and need individual rules.

### Check game window class

While a game is running:
```bash
hyprctl clients | grep -A 5 "class:"
```

### Borderless vs Fullscreen

Borderless (windowed fullscreen) is recommended for Hyprland:
- Smoother alt-tab and workspace switching
- Better multi-monitor behavior
- Hyprland keybinds continue to work
- Fewer XWayland focus issues

Set games to borderless in their video settings, and let the Hyprland window rule handle true fullscreen.

## Known Issues

### HiDPI / Fractional Scaling

Steam runs through XWayland and may appear blurry on displays with fractional scaling (e.g., 1.5x). Potential fixes:
- Steam > Settings > Interface > "Enlarge text and icons based on monitor size"
- Steam > Settings > Accessibility > scaling slider
- `STEAM_FORCE_DESKTOPUI_SCALING=1.5` environment variable

These may not fully resolve the issue since XWayland scaling is inherently problematic with fractional scaling.
