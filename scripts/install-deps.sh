#!/bin/bash

# Script d'installation des dépendances pour ZMK
# Ce script installe les outils nécessaires pour construire des firmwares ZMK

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour détecter l'OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            echo "debian"
        elif [ -f /etc/redhat-release ]; then
            echo "redhat"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Installation de West
install_west() {
    log_info "Installation de West..."
    
    if command -v west >/dev/null 2>&1; then
        log_success "West est déjà installé ($(west --version))"
        return
    fi
    
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --user west
        log_success "West installé via pip3"
    elif command -v pip >/dev/null 2>&1; then
        pip install --user west
        log_success "West installé via pip"
    else
        log_error "pip/pip3 non trouvé. Veuillez installer Python et pip d'abord."
        exit 1
    fi
}

# Installation de yq
install_yq() {
    log_info "Installation de yq..."
    
    if command -v yq >/dev/null 2>&1; then
        log_success "yq est déjà installé ($(yq --version))"
        return
    fi
    
    local os=$(detect_os)
    
    case $os in
        "debian")
            if command -v snap >/dev/null 2>&1; then
                sudo snap install yq
                log_success "yq installé via snap"
            else
                log_warning "snap non disponible. Installation manuelle recommandée."
                log_info "Visitez: https://github.com/mikefarah/yq/releases"
            fi
            ;;
        "macos")
            if command -v brew >/dev/null 2>&1; then
                brew install yq
                log_success "yq installé via Homebrew"
            else
                log_warning "Homebrew non disponible. Installation manuelle recommandée."
                log_info "Visitez: https://github.com/mikefarah/yq/releases"
            fi
            ;;
        *)
            log_warning "OS non supporté pour l'installation automatique de yq"
            log_info "Visitez: https://github.com/mikefarah/yq/releases"
            ;;
    esac
}

# Installation des dépendances système
install_system_deps() {
    local os=$(detect_os)
    
    log_info "Installation des dépendances système pour $os..."
    
    case $os in
        "debian")
            log_info "Installation des paquets pour Debian/Ubuntu..."
            sudo apt update
            sudo apt install -y git cmake ninja-build gperf \
                ccache dfu-util device-tree-compiler wget \
                python3-dev python3-pip python3-setuptools \
                python3-tk python3-wheel xz-utils file \
                make gcc gcc-multilib g++-multilib libsdl2-dev
            log_success "Dépendances système installées"
            ;;
        "macos")
            log_info "Installation des dépendances pour macOS..."
            if command -v brew >/dev/null 2>&1; then
                brew install cmake ninja gperf python3 ccache qemu dtc
                log_success "Dépendances système installées via Homebrew"
            else
                log_error "Homebrew requis pour macOS. Installez-le depuis: https://brew.sh"
                exit 1
            fi
            ;;
        *)
            log_warning "OS non supporté pour l'installation automatique des dépendances"
            log_info "Consultez la documentation ZMK: https://zmk.dev/docs/development/setup"
            ;;
    esac
}

# Fonction pour détecter l'architecture du système
detect_architecture() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            log_error "Architecture non supportée: $arch"
            return 1
            ;;
    esac
}

# Installation du Zephyr SDK selon la documentation officielle
install_zephyr_sdk() {
    log_info "Vérification du Zephyr SDK..."
    
    # Vérifier les emplacements recommandés par la documentation officielle
    local sdk_version="0.17.4"
    local possible_locations=(
        "$HOME/zephyr-sdk-$sdk_version"
        "$HOME/.local/zephyr-sdk-$sdk_version"
        "$HOME/.local/opt/zephyr-sdk-$sdk_version"
        "$HOME/bin/zephyr-sdk-$sdk_version"
        "/opt/zephyr-sdk-$sdk_version"
        "/usr/local/zephyr-sdk-$sdk_version"
    )
    
    for location in "${possible_locations[@]}"; do
        if [ -d "$location" ]; then
            log_success "Zephyr SDK $sdk_version trouvé dans: $location"
            return 0
        fi
    done
    
    log_warning "Zephyr SDK $sdk_version non détecté"
    log_info "Installation selon la documentation officielle:"
    log_info "https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html"
    
    read -p "Voulez-vous télécharger et installer automatiquement le Zephyr SDK v$sdk_version? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Détecter l'architecture
        local arch
        if ! arch=$(detect_architecture); then
            log_error "Impossible de détecter l'architecture du système"
            return 1
        fi
        
        log_info "Architecture détectée: $arch"
        log_info "Téléchargement du Zephyr SDK v$sdk_version..."
        
        # URLs selon la documentation officielle
        local sdk_filename="zephyr-sdk-${sdk_version}_linux-${arch}.tar.xz"
        local sdk_url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${sdk_version}/${sdk_filename}"
        local checksum_url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${sdk_version}/sha256.sum"
        
        # Téléchargement dans le répertoire home (recommandé par la documentation)
        cd "$HOME"
        
        # Télécharger le SDK et le fichier de vérification
        if ! wget -q --show-progress "$sdk_url"; then
            log_error "Échec du téléchargement de $sdk_url"
            return 1
        fi
        
        if ! wget -q -O sha256.sum "$checksum_url"; then
            log_warning "Impossible de télécharger les checksums, vérification ignorée"
        else
            log_info "Vérification de l'intégrité du fichier..."
            if command -v shasum >/dev/null 2>&1; then
                if ! shasum --check --ignore-missing sha256.sum; then
                    log_error "Vérification de l'intégrité échouée"
                    rm -f "$sdk_filename" sha256.sum
                    return 1
                fi
            else
                log_warning "shasum non disponible, vérification ignorée"
            fi
            rm -f sha256.sum
        fi
        
        log_info "Extraction du Zephyr SDK..."
        if ! tar xf "$sdk_filename"; then
            log_error "Échec de l'extraction"
            rm -f "$sdk_filename"
            return 1
        fi
        
        # Nettoyer le fichier téléchargé
        rm -f "$sdk_filename"
        
        # Exécuter le script de setup
        local sdk_dir="$HOME/zephyr-sdk-$sdk_version"
        if [ -d "$sdk_dir" ]; then
            log_info "Configuration du Zephyr SDK..."
            cd "$sdk_dir"
            if ! ./setup.sh; then
                log_error "Échec de la configuration du SDK"
                return 1
            fi
            
            # Installer les règles udev (nécessite sudo)
            log_info "Installation des règles udev pour le flash des boards..."
            local udev_rules="$sdk_dir/sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules"
            if [ -f "$udev_rules" ]; then
                if sudo cp "$udev_rules" /etc/udev/rules.d/ 2>/dev/null; then
                    sudo udevadm control --reload 2>/dev/null || true
                    log_success "Règles udev installées"
                else
                    log_warning "Impossible d'installer les règles udev (sudo requis)"
                    log_info "Exécutez manuellement:"
                    log_info "sudo cp $udev_rules /etc/udev/rules.d/"
                    log_info "sudo udevadm control --reload"
                fi
            fi
            
            log_success "Zephyr SDK v$sdk_version installé dans: $sdk_dir"
            
            # Configurer l'environnement
            setup_zephyr_environment
        else
            log_error "Répertoire du SDK non trouvé après extraction"
            return 1
        fi
    else
        log_info "Installation manuelle requise. Consultez la documentation:"
        log_info "https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html"
        log_info "Après installation manuelle, utilisez 'make diagnose' pour vérifier la configuration."
    fi
}

# Fonction pour configurer l'environnement Zephyr
setup_zephyr_environment() {
    log_info "Configuration de l'environnement Zephyr..."
    
    # Détection automatique du Zephyr SDK selon les emplacements recommandés
    local zephyr_sdk_paths=(
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
    
    local zephyr_sdk_path=""
    for path in "${zephyr_sdk_paths[@]}"; do
        if [ -d "$path" ]; then
            zephyr_sdk_path="$path"
            break
        fi
    done
    
    if [ -n "$zephyr_sdk_path" ]; then
        log_info "Zephyr SDK trouvé dans: $zephyr_sdk_path"
        
        # Créer un script d'environnement
        cat > "$HOME/.zephyr-env.sh" << EOF
#!/bin/bash
# Configuration de l'environnement Zephyr pour ZMK

export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
export ZEPHYR_SDK_INSTALL_DIR="$zephyr_sdk_path"
export PATH="\$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin:\$PATH"

# Optionnel: définir ZEPHYR_BASE si zephyr est cloné localement
if [ -d "\$(pwd)/zephyr" ]; then
    export ZEPHYR_BASE="\$(pwd)/zephyr"
fi

echo "Environnement Zephyr configuré:"
echo "  ZEPHYR_SDK_INSTALL_DIR=\$ZEPHYR_SDK_INSTALL_DIR"
echo "  ZEPHYR_TOOLCHAIN_VARIANT=\$ZEPHYR_TOOLCHAIN_VARIANT"
if [ -n "\$ZEPHYR_BASE" ]; then
    echo "  ZEPHYR_BASE=\$ZEPHYR_BASE"
fi
EOF
        
        chmod +x "$HOME/.zephyr-env.sh"
        log_success "Script d'environnement créé: $HOME/.zephyr-env.sh"
        log_info "Vous pouvez sourcer ce script avec: source ~/.zephyr-env.sh"
        
        # Ajouter au profil bash/zsh si souhaité
        read -p "Voulez-vous ajouter la configuration Zephyr à votre profil shell? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            local shell_rc=""
            if [ -n "$ZSH_VERSION" ]; then
                shell_rc="$HOME/.zshrc"
            elif [ -n "$BASH_VERSION" ]; then
                shell_rc="$HOME/.bashrc"
            fi
            
            if [ -n "$shell_rc" ] && [ -f "$shell_rc" ]; then
                echo "" >> "$shell_rc"
                echo "# Configuration Zephyr pour ZMK" >> "$shell_rc"
                echo "source ~/.zephyr-env.sh" >> "$shell_rc"
                log_success "Configuration ajoutée à $shell_rc"
                log_info "Redémarrez votre terminal ou exécutez: source $shell_rc"
            fi
        fi
    else
        log_warning "Zephyr SDK non trouvé après installation"
    fi
}

# Fonction pour appliquer les modifications de configuration ZMK
apply_zmk_config_overrides() {
    log_info "Application des modifications de configuration ZMK..."
    
    local overlay_file="config/zmk-overlay.conf"
    
    # Créer le fichier de configuration overlay s'il n'existe pas
    if [ ! -f "$overlay_file" ]; then
        log_info "Création du fichier de configuration overlay: $overlay_file"
        cat > "$overlay_file" << 'EOF'
# ZMK Configuration Overlay
# This file contains configuration overrides for ZMK builds
# It is automatically applied during the build process

# Use newlib instead of picolibc to avoid mutex type conflicts
CONFIG_NEWLIB_LIBC=y
CONFIG_PICOLIBC=n
EOF
        log_success "Fichier de configuration overlay créé"
    else
        log_info "Fichier de configuration overlay déjà présent: $overlay_file"
    fi
    
    # Vérifier que le fichier build.sh utilise bien la variable d'environnement
    local build_script="scripts/build.sh"
    if [ -f "$build_script" ]; then
        if ! grep -q "ZEPHYR_EXTRA_CONF_FILE" "$build_script"; then
            log_warning "Le script build.sh ne semble pas utiliser ZEPHYR_EXTRA_CONF_FILE"
            log_info "Modification du script build.sh..."
            
            # Trouver la ligne avec "west build" et ajouter la variable d'environnement
            sed -i 's|eval "west build $build_args"|export ZEPHYR_EXTRA_CONF_FILE="$(pwd)/config/zmk-overlay.conf"\neval "west build $build_args"|' "$build_script"
            
            if [ $? -eq 0 ]; then
                log_success "Script build.sh modifié pour utiliser la configuration overlay"
            else
                log_error "Échec de la modification du script build.sh"
            fi
        else
            log_success "Le script build.sh utilise déjà ZEPHYR_EXTRA_CONF_FILE"
        fi
    else
        log_error "Script build.sh non trouvé"
    fi
    
    log_success "Modifications de configuration ZMK appliquées"
}

# Fonction principale
main() {
    log_info "=== Installation des dépendances ZMK ==="
    
    # Parser les options
    local install_all=true
    local install_west_only=false
    local install_yq_only=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --west-only)
                install_west_only=true
                install_all=false
                shift
                ;;
            --yq-only)
                install_yq_only=true
                install_all=false
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --west-only    Installer seulement West"
                echo "  --yq-only      Installer seulement yq"
                echo "  -h, --help     Afficher cette aide"
                exit 0
                ;;
            *)
                log_error "Option inconnue: $1"
                exit 1
                ;;
        esac
    done
    
    if [ "$install_west_only" = true ]; then
        install_west
    elif [ "$install_yq_only" = true ]; then
        install_yq
    elif [ "$install_all" = true ]; then
        install_system_deps
        install_west
        install_yq
        install_zephyr_sdk
        apply_zmk_config_overrides
    fi
    
    log_success "=== Installation terminée ==="
    log_info "Vous pouvez maintenant utiliser ./build.sh pour construire vos firmwares"
}

main "$@"