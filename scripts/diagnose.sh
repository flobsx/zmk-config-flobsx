#!/bin/bash

# Script de diagnostic pour l'environnement ZMK
# Ce script vérifie que tous les outils nécessaires sont installés et configurés

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables pour le résumé
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

check_item() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    log_info "Vérification: $name"
    
    if eval "$command"; then
        log_success "$name: $expected"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        log_error "$name: Non disponible ou non configuré"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_warning() {
    local name="$1"
    local message="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
    log_warning "$name: $message"
}

# Fonction principale de diagnostic
main() {
    echo -e "${BLUE}=== Diagnostic de l'environnement ZMK ===${NC}"
    echo ""
    
    # Vérification des outils de base
    log_info "=== Outils de base ==="
    check_item "West" "command -v west >/dev/null 2>&1" "$(west --version 2>/dev/null || echo 'Non installé')"
    check_item "yq" "command -v yq >/dev/null 2>&1" "$(yq --version 2>/dev/null || echo 'Non installé')"
    check_item "CMake" "command -v cmake >/dev/null 2>&1" "$(cmake --version | head -1 2>/dev/null || echo 'Non installé')"
    check_item "Ninja" "command -v ninja >/dev/null 2>&1" "$(ninja --version 2>/dev/null || echo 'Non installé')"
    check_item "Python3" "command -v python3 >/dev/null 2>&1" "$(python3 --version 2>/dev/null || echo 'Non installé')"
    
    echo ""
    
    # Vérification des toolchains
    log_info "=== Toolchains ARM ==="
    if check_item "ARM GCC (Zephyr)" "command -v arm-zephyr-eabi-gcc >/dev/null 2>&1" "$(arm-zephyr-eabi-gcc --version | head -1 2>/dev/null || echo 'Non installé')"; then
        :  # OK
    elif check_item "ARM GCC (GNU)" "command -v arm-none-eabi-gcc >/dev/null 2>&1" "$(arm-none-eabi-gcc --version | head -1 2>/dev/null || echo 'Non installé')"; then
        log_warning "Utilisation du toolchain GNU ARM Embedded (compatible mais Zephyr SDK recommandé)"
    else
        log_error "Aucun toolchain ARM détecté"
    fi
    
    echo ""
    
    # Vérification de l'environnement Zephyr
    log_info "=== Environnement Zephyr ==="
    
    if [ -n "$ZEPHYR_BASE" ]; then
        log_success "ZEPHYR_BASE: $ZEPHYR_BASE"
        if [ -d "$ZEPHYR_BASE" ]; then
            log_success "Répertoire Zephyr existe"
        else
            log_error "Répertoire Zephyr n'existe pas: $ZEPHYR_BASE"
        fi
    else
        check_warning "ZEPHYR_BASE" "Non défini (sera détecté automatiquement)"
    fi
    
    if [ -n "$ZEPHYR_SDK_INSTALL_DIR" ]; then
        log_success "ZEPHYR_SDK_INSTALL_DIR: $ZEPHYR_SDK_INSTALL_DIR"
        if [ -d "$ZEPHYR_SDK_INSTALL_DIR" ]; then
            log_success "Zephyr SDK installé"
        else
            log_error "Répertoire Zephyr SDK n'existe pas: $ZEPHYR_SDK_INSTALL_DIR"
        fi
    else
        # Vérifier les emplacements recommandés par la documentation officielle
        local sdk_found=false
        local sdk_paths=(
            "$HOME/zephyr-sdk-0.17.4"
            "$HOME/.local/zephyr-sdk-0.17.4"
            "$HOME/.local/opt/zephyr-sdk-0.17.4"
            "$HOME/bin/zephyr-sdk-0.17.4"
            "/opt/zephyr-sdk-0.17.4"
            "/usr/local/zephyr-sdk-0.17.4"
            # Fallback pour anciennes versions
            "$HOME/.local/zephyr-sdk"
            "/opt/zephyr-sdk"
            "$HOME/zephyr-sdk"
        )
        
        for path in "${sdk_paths[@]}"; do
            if [ -d "$path" ]; then
                log_success "Zephyr SDK trouvé: $path"
                sdk_found=true
                break
            fi
        done
        
        if [ "$sdk_found" = false ]; then
            log_error "Zephyr SDK non trouvé dans les emplacements standards"
            log_info "Utilisez 'make install' ou installez manuellement depuis:"
            log_info "https://docs.zephyrproject.org/latest/getting_started/index.html"
        fi
    fi
    
    if [ -n "$ZEPHYR_TOOLCHAIN_VARIANT" ]; then
        log_success "ZEPHYR_TOOLCHAIN_VARIANT: $ZEPHYR_TOOLCHAIN_VARIANT"
    else
        check_warning "ZEPHYR_TOOLCHAIN_VARIANT" "Non défini (sera configuré automatiquement)"
    fi
    
    echo ""
    
    # Vérification des fichiers de projet
    log_info "=== Configuration du projet ==="
    
    local current_dir="$(pwd)"
    check_item "build.yaml" "[ -f 'build.yaml' ]" "Configuration de build présente"
    check_item "config/corne.keymap" "[ -f 'config/corne.keymap' ]" "Keymap présente"
    check_item "config/west.yml" "[ -f 'config/west.yml' ]" "Configuration West présente"
    
    if [ -d ".west" ]; then
        log_success "Workspace West initialisé"
    else
        log_warning "Workspace West non initialisé (sera fait automatiquement)"
        WARNING_CHECKS=$((WARNING_CHECKS + 1))
    fi
    
    echo ""
    
    # Vérification des firmwares existants
    log_info "=== Firmwares existants ==="
    if [ -d "firmware" ] && [ "$(ls -A firmware 2>/dev/null)" ]; then
        local count=$(ls firmware/*.uf2 2>/dev/null | wc -l)
        log_success "$count firmwares trouvés dans ./firmware/"
    else
        log_info "Aucun firmware trouvé (utilisez 'make build' pour en générer)"
    fi
    
    echo ""
    
    # Résumé
    log_info "=== Résumé ==="
    echo -e "Total des vérifications: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "Succès: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Avertissements: ${YELLOW}$WARNING_CHECKS${NC}"
    echo -e "Erreurs: ${RED}$FAILED_CHECKS${NC}"
    
    echo ""
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        log_success "Environnement prêt pour la construction ZMK!"
        log_info "Utilisez 'make build' pour construire vos firmwares"
    elif [ $FAILED_CHECKS -lt 3 ]; then
        log_warning "Quelques problèmes détectés, mais la construction pourrait fonctionner"
        log_info "Utilisez 'make install' pour installer les dépendances manquantes"
    else
        log_error "Plusieurs problèmes détectés - installation des dépendances requise"
        log_info "Utilisez 'make setup' pour configurer l'environnement complet"
    fi
    
    echo ""
    log_info "Pour plus d'aide:"
    log_info "  make help     - Afficher toutes les commandes disponibles"
    log_info "  make install  - Installer les dépendances"
    log_info "  make setup    - Configuration complète"
}

main "$@"