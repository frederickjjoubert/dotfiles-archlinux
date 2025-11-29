#!/bin/bash
# Disable hibernation configuration (revert to backups)
# This script restores the original backup configuration files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Hibernation Configuration Reverter ===${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Confirm action
echo -e "${YELLOW}This will revert to backup (non-hibernation) configuration files.${NC}"
echo "The following changes will be made:"
echo "  - Copy fstab.backup -> /etc/fstab"
echo "  - Copy mkinitcpio.conf.backup -> /etc/mkinitcpio.conf"
echo "  - Copy boot loader entries (*.backup -> /boot/loader/entries/)"
echo "  - Rebuild initramfs with mkinitcpio -P"
echo
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo
echo -e "${GREEN}Step 1: Restoring fstab backup...${NC}"
cp -v /home/jacques/.arch/etc/fstab.backup /etc/fstab

echo
echo -e "${GREEN}Step 2: Restoring mkinitcpio backup...${NC}"
cp -v /home/jacques/.arch/etc/mkinitcpio.conf.backup /etc/mkinitcpio.conf

echo
echo -e "${GREEN}Step 3: Restoring boot loader entries...${NC}"
cp -v /home/jacques/.arch/boot/loader/entries/linux.conf.backup \
   /boot/loader/entries/linux.conf
cp -v /home/jacques/.arch/boot/loader/entries/linux-lts.conf.backup \
   /boot/loader/entries/linux-lts.conf
cp -v /home/jacques/.arch/boot/loader/entries/linux-fallback.conf.backup \
   /boot/loader/entries/linux-fallback.conf
cp -v /home/jacques/.arch/boot/loader/entries/linux-lts-fallback.conf.backup \
   /boot/loader/entries/linux-lts-fallback.conf

echo
echo -e "${GREEN}Step 4: Rebuilding initramfs...${NC}"
echo -e "${YELLOW}This may take a minute...${NC}"
mkinitcpio -P

echo
echo -e "${GREEN}=== Configuration reverted to backups successfully! ===${NC}"
echo
echo "Hibernation support has been disabled."
echo "Your system should now be in the original working state."
echo
