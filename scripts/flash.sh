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

# Flash via USB mass storage (mount point detection)
flash_usb() {
  local UF2=$1
  local SIDE=$2
  
  echo "Waiting for nice!nano ($SIDE) in bootloader mode..."
  while true; do
    MOUNT_POINT=$(find /media -name "NICE_NANO" -type d 2>/dev/null | head -1)
    if [ -n "$MOUNT_POINT" ]; then
      echo "  Detected: $MOUNT_POINT"
      cp "$UF2" "$MOUNT_POINT/"
      sync
      echo "  ✓ Flashed $SIDE via USB"
      sleep 2  # Wait for reboot
      return 0
    fi
    echo "  → Press reset on nice!nano ($SIDE)..."
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

echo "=========================================="
echo "Flashing ${#UF2_FILES[@]} device(s) via $METHOD method"
echo "=========================================="

# Loop over UF2 files
for UF2 in "${UF2_FILES[@]}"; do
  if [ ! -e "$UF2" ]; then
    continue
  fi
  
  SIDE=$(basename "$UF2" .uf2)
  echo ""
  echo "Device: $SIDE"
  
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
echo "=========================================="
echo "✓ All devices flashed successfully."
echo "=========================================="
