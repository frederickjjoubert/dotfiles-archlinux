#!/bin/bash
# Toggle workspace assignments between external and laptop displays
# Usage: ./toggle_external_display.sh Y  (external gets 1-5)
#        ./toggle_external_display.sh N  (laptop gets 1-5)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"
WAYBAR_CONF="$HOME/.config/waybar/config"

# Check argument
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Missing argument${NC}"
    echo "Usage: $0 [Y|N]"
    echo "  Y - External display gets workspaces 1-5, laptop gets 6-10"
    echo "  N - Laptop gets workspaces 1-5, external display gets 6-10"
    exit 1
fi

MODE="$1"

if [[ ! "$MODE" =~ ^[YyNn]$ ]]; then
    echo -e "${RED}Error: Invalid argument '$MODE'${NC}"
    echo "Please use Y or N"
    exit 1
fi

# Normalize to uppercase
MODE=$(echo "$MODE" | tr '[:lower:]' '[:upper:]')

echo -e "${GREEN}=== Workspace Display Toggle ===${NC}"
echo

if [ "$MODE" = "Y" ]; then
    echo -e "${YELLOW}Setting up: External (DP-2) = 1-5, Laptop (eDP-1) = 6-10${NC}"
    PRIMARY_MONITOR="DP-2"
    SECONDARY_MONITOR="eDP-1"
    PRIMARY_WORKSPACES="1 2 3 4 5"
    SECONDARY_WORKSPACES="6 7 8 9 10"
else
    echo -e "${YELLOW}Setting up: Laptop (eDP-1) = 1-5, External (DP-2) = 6-10${NC}"
    PRIMARY_MONITOR="eDP-1"
    SECONDARY_MONITOR="DP-2"
    PRIMARY_WORKSPACES="1 2 3 4 5"
    SECONDARY_WORKSPACES="6 7 8 9 10"
fi

echo

# Update Hyprland config
echo -e "${GREEN}Updating Hyprland configuration...${NC}"

# Create temporary file with new workspace assignments
TEMP_HYPR=$(mktemp)
cp "$HYPRLAND_CONF" "$TEMP_HYPR"

# Remove old workspace lines (between the comment and the next section)
sed -i '/# Bind workspaces to specific monitors/,/^workspace = 10,/{//!d}' "$TEMP_HYPR"
sed -i '/# Bind workspaces to specific monitors/d' "$TEMP_HYPR"

# Find the line number to insert new workspace config
LINE_NUM=$(grep -n "# Ref https://wiki.hypr.land/Configuring/Workspace-Rules/" "$TEMP_HYPR" | cut -d: -f1)
LINE_NUM=$((LINE_NUM + 1))

# Create new workspace config
{
    echo "# Bind workspaces to specific monitors"
    echo "workspace = 1, monitor:$PRIMARY_MONITOR, default:true"
    echo "workspace = 2, monitor:$PRIMARY_MONITOR"
    echo "workspace = 3, monitor:$PRIMARY_MONITOR"
    echo "workspace = 4, monitor:$PRIMARY_MONITOR"
    echo "workspace = 5, monitor:$PRIMARY_MONITOR"
    echo "workspace = 6, monitor:$SECONDARY_MONITOR, default:true"
    echo "workspace = 7, monitor:$SECONDARY_MONITOR"
    echo "workspace = 8, monitor:$SECONDARY_MONITOR"
    echo "workspace = 9, monitor:$SECONDARY_MONITOR"
    echo "workspace = 10, monitor:$SECONDARY_MONITOR"
} > /tmp/workspace_config

# Insert new config
sed -i "${LINE_NUM}r /tmp/workspace_config" "$TEMP_HYPR"

# Replace original file
mv "$TEMP_HYPR" "$HYPRLAND_CONF"
rm -f /tmp/workspace_config

echo -e "${GREEN}Updating Waybar configuration...${NC}"

# Update Waybar persistent workspaces
if [ "$MODE" = "Y" ]; then
    # External gets 1-5, Laptop gets 6-10
    sed -i '/"persistent-workspaces":/,/}/c\
        "persistent-workspaces": {\
            "DP-2": [1, 2, 3, 4, 5],\
            "eDP-1": [6, 7, 8, 9, 10]\
        }' "$WAYBAR_CONF"
else
    # Laptop gets 1-5, External gets 6-10
    sed -i '/"persistent-workspaces":/,/}/c\
        "persistent-workspaces": {\
            "eDP-1": [1, 2, 3, 4, 5],\
            "DP-2": [6, 7, 8, 9, 10]\
        }' "$WAYBAR_CONF"
fi

echo -e "${GREEN}Reloading Hyprland configuration...${NC}"
hyprctl reload

echo -e "${GREEN}Reloading Waybar...${NC}"
pkill waybar
waybar &
disown

echo
echo -e "${GREEN}=== Configuration updated successfully! ===${NC}"
echo
if [ "$MODE" = "Y" ]; then
    echo "External display (DP-2): Workspaces 1-5"
    echo "Laptop display (eDP-1): Workspaces 6-10"
else
    echo "Laptop display (eDP-1): Workspaces 1-5"
    echo "External display (DP-2): Workspaces 6-10"
fi
echo
