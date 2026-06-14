#!/bin/bash
set -e

SIDE_FILTER="$1"  # Optional: "corne_left" or "corne_right"
OUTPUT_DIR="build/output"

# Collect UF2 files, optionally filtered by side
if [ -n "$SIDE_FILTER" ]; then
  GLOB_PATTERN="$OUTPUT_DIR/${SIDE_FILTER}*.uf2"
else
  GLOB_PATTERN="$OUTPUT_DIR/*.uf2"
fi

UF2_FILES=($GLOB_PATTERN)

# Check if UF2 files exist
if [ ${#UF2_FILES[@]} -eq 0 ] || [ ! -e "${UF2_FILES[0]}" ]; then
  echo "ERROR: No UF2 files found in $OUTPUT_DIR"
  if [ -n "$SIDE_FILTER" ]; then
    echo "  (filtered for: $SIDE_FILTER)"
  fi
  echo "Run 'make build' first."
  exit 1
fi

# Clean up stale bootloader mounts (from previous flashes)
cleanup_stale_mounts() {
  echo -e "\033[0;33mNettoyage des anciens mounts fantômes...\033[0m"
  for media_dir in /run/media/*/; do
    if [ ! -d "$media_dir" ]; then
      continue
    fi
    for mount in "$media_dir"NICENANO* "$media_dir"NICE_NANO "$media_dir"PYBFLASH; do
      if [ -d "$mount" ]; then
        # Check if it's a stale mount (not currently mounted)
        if ! mountpoint -q "$mount" 2>/dev/null; then
          echo -e "  \033[0;33mSuppression de $mount\033[0m"
          rm -rf "$mount" 2>/dev/null || true
        fi
      fi
    done
  done
}

# Wait for user to unplug and prepare next device
wait_for_next_device() {
  local SIDE=$1
  local IS_LAST=$2
  echo ""
  echo -e "  \033[1;33m✓ Flash terminé pour $SIDE\033[0m"
  echo -e "  \033[0;36mLe clavier va rebooter automatiquement.\033[0m"
  echo ""
  if [ "$IS_LAST" = "true" ]; then
    echo -e "  \033[1m→ Débranche ce clavier, c'est le dernier !\033[0m"
  else
    echo -e "  \033[1m→ Débranche ce clavier et prépare le suivant.\033[0m"
  fi
  echo -e "  \033[0;33mAttente de 5 secondes...\033[0m"
  echo ""
  sleep 5
}

# Detect bootloader mount point by checking for UF2 bootloader files
detect_bootloader_mount() {
  for media_dir in /run/media/*/; do
    if [ ! -d "$media_dir" ]; then
      continue
    fi
    
    # Search for directories that look like nice!nano bootloader
    for mount in "$media_dir"NICENANO*; do
      if [ -d "$mount" ]; then
        if [ -f "$mount/CURRENT.UF2" ] && [ -f "$mount/INFO_UF2.TXT" ]; then
          echo "$mount"
          return 0
        fi
      fi
    done
    
    # Also check for alternative names
    for mount in "$media_dir"NICE_NANO "$media_dir"PYBFLASH; do
      if [ -d "$mount" ]; then
        if [ -f "$mount/CURRENT.UF2" ] && [ -f "$mount/INFO_UF2.TXT" ]; then
          echo "$mount"
          return 0
        fi
      fi
    done
  done
  
  return 1
}

# Flash via USB mass storage
flash_usb() {
  local UF2=$1
  local SIDE=$2
  local IS_LAST=$3
  
  echo ""
  echo -e "\033[1;33m━━━ Préparation pour $SIDE ━━━\033[0m"
  echo ""
  echo -e "\033[0;36mInstructions :\033[0m"
  echo -e "  1. \033[1mDébranche\033[0m tout clavier actuellement connecté"
  echo -e "  2. \033[1mBranche\033[0m le clavier $SIDE"
  echo -e "  3. Appuie \033[1mdeux fois rapidement\033[0m sur le bouton RESET (double-tap)"
  echo -e "  4. Le mode bootloader devrait s'activer"
  echo ""
  echo -e "\033[1;32mEn attente de détection du bootloader...\033[0m"
  
  # Auto-detect bootloader mount
  MOUNT_POINT=""
  while [ -z "$MOUNT_POINT" ]; do
    MOUNT_POINT=$(detect_bootloader_mount || true)
    if [ -z "$MOUNT_POINT" ]; then
      sleep 1
    fi
  done
  
  echo -e "  \033[1;32m✓ Bootloader détecté:\033[0m $MOUNT_POINT"
  
  # Flash the firmware
  cp "$UF2" "$MOUNT_POINT/"
  sync
  echo -e "  \033[1;32m✓ Firmware copié: $SIDE\033[0m"
  
  # Wait for user to unplug and prepare next device
  wait_for_next_device "$SIDE" "$IS_LAST"
}

# Clean stale mounts at startup
cleanup_stale_mounts

echo ""
echo -e "\033[1;36m╔════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║                    FLASHING FIRMWARE                             ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
if [ -n "$SIDE_FILTER" ]; then
  echo -e "\033[1;33mFlashing 1 device: ${SIDE_FILTER}\033[0m"
else
  echo -e "\033[1;33mFlashing ${#UF2_FILES[@]} device(s) via USB method\033[0m"
  echo ""
  echo -e "\033[1;31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo -e "\033[1;31m  IMPORTANT: Flash devices ONE AT A TIME in order:\033[0m"
  echo -e "\033[1;31m  1. Flash LEFT half → wait for reboot → unplug\033[0m"
  echo -e "\033[1;31m  2. Flash RIGHT half → wait for reboot → unplug\033[0m"
  echo -e "\033[1;31m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
fi
echo ""

# Loop over UF2 files
TOTAL=${#UF2_FILES[@]}
COUNT=0
for UF2 in "${UF2_FILES[@]}"; do
  if [ ! -e "$UF2" ]; then
    continue
  fi
  
  COUNT=$((COUNT + 1))
  IS_LAST="false"
  if [ "$COUNT" -eq "$TOTAL" ]; then
    IS_LAST="true"
  fi
  
  SIDE=$(basename "$UF2" .uf2)
  echo ""
  echo -e "\033[1;35m━━━ Device: $SIDE ━━━\033[0m"
  
  flash_usb "$UF2" "$SIDE" "$IS_LAST"
done

echo ""
if [ -n "$SIDE_FILTER" ]; then
  echo -e "\033[1;32m╔════════════════════════════════════════════════════════════════╗\033[0m"
  echo -e "\033[1;32m║              ✓ ${SIDE_FILTER} FLASHED SUCCESSFULLY                 \033[0m"
  echo -e "\033[1;32m╚════════════════════════════════════════════════════════════════╝\033[0m"
else
  echo -e "\033[1;32m╔════════════════════════════════════════════════════════════════╗\033[0m"
  echo -e "\033[1;32m║              ✓ ALL DEVICES FLASHED SUCCESSFULLY                  ║\033[0m"
  echo -e "\033[1;32m╚════════════════════════════════════════════════════════════════╝\033[0m"
fi
echo ""
