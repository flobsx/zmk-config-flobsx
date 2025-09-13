#!/bin/bash

# Script de construction des firmwares ZMK
# Ce script construit les firmwares ZMK basés sur la configuration dans build.yaml
# et les place dans le dossier ./firmware

set -e  # Arrêter le script en cas d'erreur

# Configuration
CONFIG_DIR="config"
FIRMWARE_DIR="firmware"
BUILD_DIR="build"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher des messages colorés
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour nettoyer les builds précédents
clean_build() {
    log_info "Nettoyage des builds précédents..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        log_success "Dossier de build nettoyé"
    fi
}

# Fonction pour créer le dossier firmware s'il n'existe pas
setup_firmware_dir() {
    if [ ! -d "$FIRMWARE_DIR" ]; then
        mkdir -p "$FIRMWARE_DIR"
        log_info "Dossier $FIRMWARE_DIR créé"
    fi
}

# Fonction pour vérifier l'environnement Zephyr
check_zephyr_environment() {
    log_info "Vérification de l'environnement Zephyr..."
    
    # Vérifier si ZEPHYR_BASE est défini
    if [ -z "$ZEPHYR_BASE" ]; then
        log_warning "ZEPHYR_BASE non défini. Tentative de détection automatique..."
        
        # Chercher zephyr dans les emplacements recommandés et dans le workspace
        local possible_paths=(
            "$(pwd)/zephyr"
            "$HOME/zephyr-sdk-0.17.4/zephyr"
            "$HOME/.local/zephyr-sdk-0.17.4/zephyr"
            "$HOME/.local/opt/zephyr-sdk-0.17.4/zephyr"
            "/opt/zephyr-sdk-0.17.4/zephyr"
            # Fallback pour anciennes versions
            "$HOME/.local/zephyr-sdk/zephyr"
            "/opt/zephyr-sdk/zephyr"
            "$HOME/zephyr"
        )
        
        for path in "${possible_paths[@]}"; do
            if [ -d "$path" ] && [ -f "$path/CMakeLists.txt" ]; then
                export ZEPHYR_BASE="$path"
                log_info "Zephyr trouvé dans: $path"
                break
            fi
        done
        
        if [ -z "$ZEPHYR_BASE" ]; then
            log_error "Zephyr non trouvé. Veuillez installer le Zephyr SDK."
            log_info "Vous pouvez utiliser 'make install' pour installer automatiquement les dépendances."
            return 1
        fi
    fi
    
    # Sourcer l'environnement Zephyr
    if [ -f "$ZEPHYR_BASE/zephyr-env.sh" ]; then
        log_info "Sourçage de l'environnement Zephyr..."
        source "$ZEPHYR_BASE/zephyr-env.sh"
        log_success "Environnement Zephyr sourcé"
    else
        log_warning "Script zephyr-env.sh non trouvé dans $ZEPHYR_BASE"
    fi
    
    # Vérifier si le toolchain est configuré
    if [ -z "$ZEPHYR_TOOLCHAIN_VARIANT" ]; then
        log_info "Configuration du toolchain par défaut..."
        if command -v arm-zephyr-eabi-gcc >/dev/null 2>&1; then
            export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
        elif command -v arm-none-eabi-gcc >/dev/null 2>&1; then
            export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
            export GNUARMEMB_TOOLCHAIN_PATH="$(dirname "$(dirname "$(which arm-none-eabi-gcc)")")"
        else
            log_warning "Aucun toolchain ARM détecté. La compilation pourrait échouer."
        fi
    fi
    
    log_success "Environnement Zephyr configuré"
    return 0
}

# Fonction pour vérifier et installer les dépendances Python
check_python_deps() {
    log_info "Vérification des dépendances Python..."
    
    # Utiliser le même Python que West utilise
    local python_exec="/home/linuxbrew/.linuxbrew/Cellar/west/1.4.0/libexec/bin/python"
    
    if [ ! -f "$python_exec" ]; then
        python_exec="python3"
    fi
    
    # Vérifier si pyelftools est installé
    if ! $python_exec -c "import elftools" >/dev/null 2>&1; then
        log_info "Installation de pyelftools..."
        $python_exec -m pip install pyelftools --user
        log_success "pyelftools installé"
    else
        log_success "pyelftools déjà disponible"
    fi
}

# Fonction pour initialiser West
init_west() {
    log_info "Initialisation de l'environnement West..."
    
    if [ ! -f ".west/config" ]; then
        log_info "Initialisation du workspace West..."
        west init -l "$CONFIG_DIR"
    fi
    
    log_info "Mise à jour des modules West..."
    west update
    
    log_success "Environnement West prêt"
}

# Fonction pour construire un firmware
build_firmware() {
    local board="$1"
    local shield="$2"
    local snippet="$3"
    
    log_info "Construction du firmware pour $board avec shield: $shield"
    
    # Préparer les arguments pour west build
    local build_args="-s zmk/app -b $board"
    
    if [ -n "$shield" ]; then
        build_args="$build_args -- -DSHIELD=\"$shield\""
    fi
    
    if [ -n "$snippet" ]; then
        build_args="$build_args -DSNIPPET=\"$snippet\""
    fi
    
    # Construire le firmware avec les variables d'environnement nécessaires
    export ZEPHYR_BASE="$(pwd)/zephyr"
    export Zephyr_DIR="$ZEPHYR_BASE/share/zephyr-package/cmake"
    
    # Utiliser les options de configuration directement au lieu du fichier overlay
    build_args="$build_args -DCONFIG_NEWLIB_LIBC=y -DCONFIG_PICOLIBC=n"
    
    log_info "Configuration: NEWLIB activé, PICOLIBC désactivé"
    eval "west build $build_args"
    
    if [ $? -eq 0 ]; then
        # Chercher le fichier .uf2 généré
        local uf2_file=$(find build/zephyr -name "*.uf2" 2>/dev/null | head -1)
        
        if [ -n "$uf2_file" ] && [ -f "$uf2_file" ]; then
            # Générer un nom de fichier descriptif
            local filename="${board}"
            if [ -n "$shield" ]; then
                # Remplacer les espaces par des tirets et nettoyer le nom
                local clean_shield=$(echo "$shield" | sed 's/ /-/g')
                filename="${clean_shield}-${filename}"
            fi
            filename="${filename}-zmk.uf2"
            
            # Copier le fichier dans le dossier firmware
            cp "$uf2_file" "$FIRMWARE_DIR/$filename"
            log_success "Firmware créé: $FIRMWARE_DIR/$filename"
        else
            log_error "Fichier .uf2 non trouvé après la construction"
            return 1
        fi
    else
        log_error "Échec de la construction pour $board avec shield: $shield"
        return 1
    fi
    
    # Nettoyer le dossier de build pour la prochaine construction
    rm -rf "$BUILD_DIR"
}

# Fonction principale
main() {
    log_info "=== Début de la construction des firmwares ZMK ==="
    
    # Vérifier que nous sommes dans le bon répertoire
    if [ ! -f "build.yaml" ]; then
        log_error "Fichier build.yaml non trouvé. Assurez-vous d'être dans le répertoire racine du projet."
        exit 1
    fi
    
    # Parser les options en ligne de commande
    local clean=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean|-c)
                clean=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -c, --clean    Nettoyer les builds précédents avant de commencer"
                echo "  -h, --help     Afficher cette aide"
                exit 0
                ;;
            *)
                log_error "Option inconnue: $1"
                exit 1
                ;;
        esac
    done
    
    # Nettoyer si demandé
    if [ "$clean" = true ]; then
        clean_build
    fi
    
    # Créer le dossier firmware
    setup_firmware_dir
    
    # Vérifier l'environnement Zephyr
    if ! check_zephyr_environment; then
        log_error "Environnement Zephyr non configuré correctement"
        exit 1
    fi
    
    # Initialiser West
    init_west
    
    # Vérifier et installer les dépendances Python nécessaires
    check_python_deps
    
    # Lire et parser build.yaml pour extraire les configurations
    log_info "Lecture de la configuration depuis build.yaml..."
    
    # Utiliser yq pour parser le YAML (ou fallback sur grep/sed si yq n'est pas disponible)
    if command -v yq >/dev/null 2>&1; then
        # Utiliser yq pour une parsing plus robuste
        yq e '.include[] | "BOARD:" + .board + " SHIELD:" + (.shield // "") + " SNIPPET:" + (.snippet // "")' build.yaml | while read -r line; do
            if [ -n "$line" ]; then
                local board=$(echo "$line" | sed 's/.*BOARD:\([^ ]*\).*/\1/')
                local shield=$(echo "$line" | sed 's/.*SHIELD:\([^S]*\) SNIPPET:.*/\1/' | sed 's/\s*$//')
                local snippet=$(echo "$line" | sed 's/.*SNIPPET:\(.*\)/\1/')
                
                build_firmware "$board" "$shield" "$snippet"
            fi
        done
    else
        # Fallback simple pour les cas basiques
        log_warning "yq non trouvé, utilisation d'une méthode de parsing simplifiée"
        
        # Parser basique du YAML (fonctionne pour la structure actuelle)
        grep -A 10 "include:" build.yaml | grep -E "^\s*-\s*board:" | while read -r line; do
            local board=$(echo "$line" | sed 's/.*board:\s*//' | sed 's/\s*$//')
            local shield_line=$(grep -A 5 "board: $board" build.yaml | grep "shield:" | head -1)
            local shield=""
            local snippet_line=$(grep -A 5 "board: $board" build.yaml | grep "snippet:" | head -1)
            local snippet=""
            
            if [ -n "$shield_line" ]; then
                shield=$(echo "$shield_line" | sed 's/.*shield:\s*//' | sed 's/\s*$//')
            fi
            
            if [ -n "$snippet_line" ]; then
                snippet=$(echo "$snippet_line" | sed 's/.*snippet:\s*//' | sed 's/\s*$//')
            fi
            
            build_firmware "$board" "$shield" "$snippet"
        done
    fi
    
    log_success "=== Construction des firmwares terminée ==="
    log_info "Les firmwares sont disponibles dans le dossier: $FIRMWARE_DIR"
    
    # Lister les fichiers générés
    if [ -d "$FIRMWARE_DIR" ] && [ "$(ls -A $FIRMWARE_DIR 2>/dev/null)" ]; then
        log_info "Fichiers générés:"
        ls -la "$FIRMWARE_DIR"/*.uf2 2>/dev/null | while read -r file; do
            echo "  - $(basename "$file")"
        done
    fi
}

# Exécuter le script principal
main "$@"