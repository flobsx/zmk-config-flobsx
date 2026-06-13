#!/bin/bash
set -e

OUTPUT_DIR="/zmk/build/output"
METHOD="${FLASH_METHOD:-usb}"
UF2_FILES=("$OUTPUT_DIR"/*.uf2)

# Check if UF2 files exist
if [ ${#UF2_FILES[@]} -eq 0 ] || [ ! -e "${UF2_FILES[0]}" ]; then
  echo "ERROR: No UF2 files found in $OUTPUT_DIR"
  echo "Run 'make build' first."
  exit 1
fi

# Wait for mount point to disappear (device rebooted)
wait_for_unmount() {
  local SIDE=$1
  echo -e "  \033[0;36mWaiting for device to reboot...\033[0m"
  while true; do
    MOUNT_POINT=$(find /run/media -name "NICE_NANO" -type d 2>/dev/null | head -1)
    if [ -z "$MOUNT_POINT" ]; then
      MOUNT_POINT=$(find /run/media -name "NICENANO" -type d 2>/dev/null | head -1)
    fi
    if [ -z "$MOUNT_POINT" ]; then
      MOUNT_POINT=$(find /run/media -name "PYBFLASH" -type d 2>/dev/null | head -1)
    fi
    
    if [ -z "$MOUNT_POINT" ]; then
      echo -e "  \033[1;32m✓ Device rebooted successfully\033[0m"
      return 0
    fi
    sleep 1
  done
}

# Flash via USB mass storage (mount point detection)
flash_usb() {
  local UF2=$1
  local SIDE=$2
  
  echo -e "\033[1;33mWaiting for nice!nano ($SIDE) in bootloader mode...\033[0m"
  echo -e "  \033[0;36m(Mount point should appear in /run/media/)\033[0m"
  
  # Allow manual override via environment variable
  if [ -n "$NICE_NANO_PATH" ]; then
    echo "  Using manual path: $NICE_NANO_PATH"
    if [ -d "$NICE_NANO_PATH" ]; then
      cp "$UF2" "$NICE_NANO_PATH/"
      sync
      echo -e "  \033[1;32m✓ Flashed $SIDE via USB\033[0m"
      wait_for_unmount "$SIDE"
      echo ""
      echo -e "\033[1;33m  ━━━ Next: unplug this device and connect the next one ━━━\033[0m"
      echo ""
      return 0
    else
      echo "  ERROR: Path does not exist: $NICE_NANO_PATH"
      exit 1
    fi
  fi
  
  while true; do
    # Search for NICE_NANO mount point (try various names)
    MOUNT_POINT=$(find /run/media -name "NICE_NANO" -type d 2>/dev/null | head -1)
    if [ -z "$MOUNT_POINT" ]; then
      MOUNT_POINT=$(find /run/media -name "NICENANO" -type d 2>/dev/null | head -1)
    fi
    if [ -z "$MOUNT_POINT" ]; then
      MOUNT_POINT=$(find /run/media -name "PYBFLASH" -type d 2>/dev/null | head -1)
    fi
    
    if [ -n "$MOUNT_POINT" ]; then
      echo -e "  \033[1;32m✓ Detected:\033[0m $MOUNT_POINT"
      cp "$UF2" "$MOUNT_POINT/"
      sync
      echo -e "  \033[1;32m✓ Flashed $SIDE via USB\033[0m"
      wait_for_unmount "$SIDE"
      echo ""
      echo -e "\033[1;33m  ━━━ Next: unplug this device and connect the next one ━━━\033[0m"
      echo ""
      return 0
    fi
    echo -e "  \033[0;33m→ Press reset on nice!nano ($SIDE)...\033[0m"
    sleep 1
  done
}

# Flash via dfu-util (future extension)
flash_dfu() {
  local UF2=$1
  local SIDE=$2
  echo "ERROR: DFU method not yet implemented."
  echo "Use USB method (default): make flash"
  exit 1
}

echo ""
echo -e "\033[1;36m╔════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║                    FLASHING FIRMWARE                             ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[1;33mFlashing ${#UF2_FILES[@]} device(s) via $METHOD method\033[0m"
echo ""
echo -e "\033[1;31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\033[1;31m  IMPORTANT: Flash devices ONE AT A TIME in order:\033[0m"
echo -e "\033[1;31m  1. Flash LEFT half → wait for reboot → unplug\033[0m"
echo -e "\033[1;31m  2. Flash RIGHT half → wait for reboot → unplug\033[0m"
echo -e "\033[1;31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# Loop over UF2 files
for UF2 in "${UF2_FILES[@]}"; do
  if [ ! -e "$UF2" ]; then
    continue
  fi
  
  SIDE=$(basename "$UF2" .uf2)
  echo ""
  echo -e "\033[1;35m━━━ Device: $SIDE ━━━\033[0m"
  
  case "$METHOD" in
    usb) flash_usb "$UF2" "$SIDE" ;;
    dfu) flash_dfu "$UF2" "$SIDE" ;;
    *) 
      echo "ERROR: Unknown flash method: $METHOD"
      echo "Supported methods: usb, dfu"
      exit 1 
      ;;
  esac
done

echo ""
echo -e "\033[1;32m╔════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;32m║              ✓ ALL DEVICES FLASHED SUCCESSFULLY                  ║\033[0m"
echo -e "\033[1;32m╚════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
