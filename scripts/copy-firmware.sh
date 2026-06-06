#!/usr/bin/env bash
# copy-firmware.sh — Detect bootloader mount, copy UF2, verify, wait for reboot
set -euo pipefail

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

SIDE="$1"
FIRMWARE="$2"
TIMEOUT="${3:-120}"

log() { echo -e "${CYAN}==>${RESET} $1"; }
ok()  { echo -e "${GREEN}==>${RESET} $1"; }
warn() { echo -e "${YELLOW}==>${RESET} $1"; }
err()  { echo -e "${RED}==>${RESET} $1" >&2; }

# Attendre qu'un disque USB bootloader apparaisse
wait_for_mount() {
    log "Waiting for $SIDE half to enter bootloader mode..."
    log "Double-tap the RESET button on the $SIDE half now."
    echo ""
    
    local end=$((SECONDS + TIMEOUT))
    
    while [ $SECONDS -lt $end ]; do
        local mountpoint=""
        
        # 1. Chercher par label NICENANO (nice_nano bootloader)
        mountpoint=$(findmnt -rn -o TARGET -S LABEL=NICENANO 2>/dev/null | head -1 || true)
        
        # 2. Fallback : chercher dans /media et /run/media des disques vfat petits
        if [ -z "$mountpoint" ]; then
            mountpoint=$(lsblk -rn -o LABEL,MOUNTPOINT,SIZE,FSTYPE 2>/dev/null | \
                awk -F' ' '$4 == "vfat" && $3 ~ /^[0-9]+[KM]$/ && $2 ~ /\/media|\/run\/media/ {
                    gsub(/[KM]/, "", $3)
                    if ($3 + 0 < 20) print $2
                }' | head -1 || true)
        fi
        
        # 3. Vérifier que le point de montage existe et est accessible
        if [ -n "$mountpoint" ] && [ -d "$mountpoint" ] && [ -w "$mountpoint" ]; then
            echo ""
            ok "Detected bootloader mount: ${BOLD}$mountpoint${RESET}"
            echo "$mountpoint"
            return 0
        fi
        
        sleep 0.5
        printf "."
    done
    
    echo ""
    err "Timeout: no bootloader device detected after ${TIMEOUT}s"
    err "Make sure the half is connected via USB and you double-tapped RESET."
    return 1
}

# Vérifier l'espace disponible
check_space() {
    local mountpoint="$1"
    local firmware="$2"
    local needed
    needed=$(stat -c%s "$firmware")
    local avail
    avail=$(df -P "$mountpoint" | awk 'NR==2 {print $4}')
    
    if [ "$avail" -lt "$needed" ]; then
        err "Not enough space on $mountpoint (needed: $needed bytes, available: $avail bytes)"
        return 1
    fi
    
    log "Space check OK (${needed} bytes needed, ${avail} available)"
}

# Copier le firmware
copy_firmware() {
    local mountpoint="$1"
    local firmware="$2"
    local basename
    basename=$(basename "$firmware")
    
    log "Copying ${BOLD}$basename${RESET} to bootloader..."
    cp "$firmware" "$mountpoint/$basename"
    
    # Vérifier que le fichier est bien là
    if [ -f "$mountpoint/$basename" ]; then
        local src_size dst_size
        src_size=$(stat -c%s "$firmware")
        dst_size=$(stat -c%s "$mountpoint/$basename")
        
        if [ "$src_size" -eq "$dst_size" ]; then
            ok "Firmware copied successfully (${src_size} bytes)"
        else
            err "Size mismatch after copy! Expected ${src_size}, got ${dst_size}"
            return 1
        fi
    else
        err "Copy failed: file not found on target"
        return 1
    fi
}

# Attendre le démontage (le clavier redémarre)
wait_for_unmount() {
    local mountpoint="$1"
    log "Waiting for device to reboot and unmount..."
    
    local timeout=30
    local end=$((SECONDS + timeout))
    
    while [ $SECONDS -lt $end ]; do
        # Vérifier si le point de montage existe toujours et est monté
        if [ ! -d "$mountpoint" ]; then
            echo ""
            ok "$SIDE half rebooted successfully!"
            return 0
        fi
        
        # Vérifier s'il est encore dans les mounts actifs
        if ! findmnt -rn -o TARGET | grep -Fxq "$mountpoint" 2>/dev/null; then
            echo ""
            ok "$SIDE half rebooted successfully!"
            return 0
        fi
        
        sleep 0.5
        printf "."
    done
    
    echo ""
    warn "Device did not unmount within ${timeout}s (may have rebooted too fast)"
    return 0
}

# Flux principal
main() {
    echo ""
    log "Flashing ${BOLD}$SIDE${RESET} half"
    echo "════════════════════════════════════════════════════"
    
    if [ ! -f "$FIRMWARE" ]; then
        err "Firmware not found: $FIRMWARE"
        err "Run $(BOLD)make all$(RESET) first to build the firmware."
        exit 1
    fi
    
    local mountpoint
    mountpoint=$(wait_for_mount)
    
    check_space "$mountpoint" "$FIRMWARE"
    copy_firmware "$mountpoint" "$FIRMWARE"
    wait_for_unmount "$mountpoint"
    
    echo ""
}

main
