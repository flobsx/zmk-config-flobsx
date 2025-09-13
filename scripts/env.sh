#!/bin/bash

# Script d'environnement pour ZMK
# Source ce fichier pour configurer automatiquement l'environnement Zephyr
# Usage: source scripts/env.sh

# Détection automatique du Zephyr SDK
detect_zephyr_sdk() {
    local sdk_paths=(
        "$HOME/.local/zephyr-sdk"
        "/opt/zephyr-sdk"
        "$HOME/zephyr-sdk"
    )
    
    for path in "${sdk_paths[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# Configuration de l'environnement
setup_environment() {
    # Zephyr SDK
    if [ -z "$ZEPHYR_SDK_INSTALL_DIR" ]; then
        local sdk_path
        if sdk_path=$(detect_zephyr_sdk); then
            export ZEPHYR_SDK_INSTALL_DIR="$sdk_path"
            echo "✓ Zephyr SDK: $ZEPHYR_SDK_INSTALL_DIR"
        else
            echo "⚠ Zephyr SDK non trouvé dans les emplacements standards"
            echo "  Utilisez 'make install' pour l'installer automatiquement"
        fi
    fi
    
    # Toolchain variant
    if [ -z "$ZEPHYR_TOOLCHAIN_VARIANT" ]; then
        if command -v arm-zephyr-eabi-gcc >/dev/null 2>&1; then
            export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
            echo "✓ Toolchain: Zephyr SDK"
        elif command -v arm-none-eabi-gcc >/dev/null 2>&1; then
            export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
            local toolchain_path
            toolchain_path=$(dirname "$(dirname "$(which arm-none-eabi-gcc)")")
            export GNUARMEMB_TOOLCHAIN_PATH="$toolchain_path"
            echo "✓ Toolchain: GNU ARM Embedded ($toolchain_path)"
        else
            echo "⚠ Aucun toolchain ARM détecté"
        fi
    fi
    
    # Zephyr base (optionnel)
    if [ -z "$ZEPHYR_BASE" ] && [ -d "$(pwd)/zephyr" ]; then
        export ZEPHYR_BASE="$(pwd)/zephyr"
        echo "✓ Zephyr Base: $ZEPHYR_BASE"
    fi
    
    # PATH pour les outils Zephyr
    if [ -n "$ZEPHYR_SDK_INSTALL_DIR" ] && [ -d "$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin" ]; then
        if [[ ":$PATH:" != *":$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin:"* ]]; then
            export PATH="$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin:$PATH"
            echo "✓ PATH mis à jour pour les outils Zephyr"
        fi
    fi
    
    # Vérifications finales
    if command -v west >/dev/null 2>&1; then
        echo "✓ West: $(west --version)"
    else
        echo "⚠ West non trouvé - utilisez 'make install' pour l'installer"
    fi
}

# Message d'information
echo "=== Configuration de l'environnement ZMK ==="

# Exécuter la configuration
setup_environment

echo ""
echo "Environnement ZMK configuré. Utilisez:"
echo "  make diagnose  - Pour un diagnostic complet"
echo "  make build     - Pour construire les firmwares"
echo "  make help      - Pour voir toutes les commandes"