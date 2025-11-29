#!/bin/bash
# Enable hibernation configuration
# This script applies the hibernation-ready configuration files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Hibernation Configuration Installer ===${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Confirm action
echo -e "${YELLOW}This will apply hibernation configuration files.${NC}"
echo "The following changes will be made:"
echo "  - Copy fstab.hibernation -> /etc/fstab"
echo "  - Copy mkinitcpio.conf.hibernation -> /etc/mkinitcpio.conf"
echo "  - Copy boot loader entries (*.hibernation -> /boot/loader/entries/)"
echo "  - Install WiFi hibernation fix -> /usr/lib/systemd/system-sleep/"
echo "  - Rebuild initramfs with mkinitcpio -P"
echo
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo
echo -e "${GREEN}Step 1: Copying fstab configuration...${NC}"
cp -v /home/jacques/.arch/etc/fstab.hibernation /etc/fstab

echo
echo -e "${GREEN}Step 2: Copying mkinitcpio configuration...${NC}"
cp -v /home/jacques/.arch/etc/mkinitcpio.conf.hibernation /etc/mkinitcpio.conf

echo
echo -e "${GREEN}Step 3: Copying boot loader entries...${NC}"
cp -v /home/jacques/.arch/boot/loader/entries/linux.conf.hibernation \
   /boot/loader/entries/linux.conf
cp -v /home/jacques/.arch/boot/loader/entries/linux-lts.conf.hibernation \
   /boot/loader/entries/linux-lts.conf
cp -v /home/jacques/.arch/boot/loader/entries/linux-fallback.conf.hibernation \
   /boot/loader/entries/linux-fallback.conf
cp -v /home/jacques/.arch/boot/loader/entries/linux-lts-fallback.conf.hibernation \
   /boot/loader/entries/linux-lts-fallback.conf

echo
echo -e "${GREEN}Step 4: Installing WiFi hibernation fix...${NC}"
install -m 755 /home/jacques/.arch/usr/lib/systemd/system-sleep/wifi-hibernate-fix \
   /usr/lib/systemd/system-sleep/wifi-hibernate-fix
echo "Installed WiFi module reload hook (fixes rtw89_8852ce resume timeout)"

echo
echo -e "${GREEN}Step 5: Rebuilding initramfs...${NC}"
echo -e "${YELLOW}This may take a minute...${NC}"
mkinitcpio -P

echo
echo -e "${GREEN}=== Hibernation configuration applied successfully! ===${NC}"
echo
echo "Next steps:"
echo "  1. Verify WiFi/network still works"
echo "  2. Test hibernation with: systemctl hibernate"
echo "  3. If issues occur, run: sudo ~/scripts/disable-hibernation.sh"
echo
