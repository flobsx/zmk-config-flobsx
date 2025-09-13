# Makefile pour la construction des firmwares ZMK
# Usage: make [target]

# Variables
SCRIPTS_DIR = scripts
BUILD_SCRIPT = $(SCRIPTS_DIR)/build.sh
INSTALL_SCRIPT = $(SCRIPTS_DIR)/install-deps.sh
DIAGNOSE_SCRIPT = $(SCRIPTS_DIR)/diagnose.sh
FIRMWARE_DIR = firmware
CONFIG_DIR = config

# Couleurs pour les messages
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build clean install deps firmware list test check setup diagnose

# Target par défaut
all: build

# Afficher l'aide
help:
	@echo "$(BLUE)Makefile pour ZMK Firmware Build$(NC)"
	@echo ""
	@echo "$(YELLOW)Targets disponibles:$(NC)"
	@echo "  $(GREEN)build$(NC)         - Construire les firmwares"
	@echo "  $(GREEN)clean$(NC)         - Construire avec nettoyage préalable"
	@echo "  $(GREEN)install$(NC)       - Installer toutes les dépendances"
	@echo "  $(GREEN)deps$(NC)          - Installer seulement West et yq"
	@echo "  $(GREEN)firmware$(NC)      - Lister les firmwares générés"
	@echo "  $(GREEN)list$(NC)          - Lister le contenu du dossier firmware"
	@echo "  $(GREEN)check$(NC)         - Vérifier la configuration"
	@echo "  $(GREEN)diagnose$(NC)      - Diagnostic complet de l'environnement"
	@echo "  $(GREEN)setup$(NC)         - Configuration initiale complète"
	@echo "  $(GREEN)test$(NC)          - Tester la configuration sans build"
	@echo "  $(GREEN)verify-zmk-config$(NC) - Vérifier la configuration ZMK overlay"
	@echo "  $(GREEN)clean-all$(NC)     - Nettoyer tous les fichiers générés"
	@echo "  $(GREEN)help$(NC)          - Afficher cette aide"
	@echo ""
	@echo "$(YELLOW)Exemples:$(NC)"
	@echo "  make build        # Construction normale (vérification automatique)"
	@echo "  make clean        # Construction avec nettoyage (vérification automatique)"
	@echo "  make install      # Installation des dépendances"

# Construire les firmwares
build: verify-zmk-config
	@echo "$(BLUE)[INFO]$(NC) Construction des firmwares ZMK..."
	@$(BUILD_SCRIPT)

# Construire avec nettoyage préalable
clean: verify-zmk-config
	@echo "$(BLUE)[INFO]$(NC) Construction avec nettoyage préalable..."
	@$(BUILD_SCRIPT) --clean

# Installation complète des dépendances
install:
	@echo "$(BLUE)[INFO]$(NC) Installation des dépendances ZMK..."
	@$(INSTALL_SCRIPT)

# Installation des dépendances essentielles seulement
deps:
	@echo "$(BLUE)[INFO]$(NC) Installation de West et yq..."
	@$(INSTALL_SCRIPT) --west-only
	@$(INSTALL_SCRIPT) --yq-only

# Lister les firmwares générés
firmware list:
	@echo "$(BLUE)[INFO]$(NC) Firmwares disponibles dans ./$(FIRMWARE_DIR):"
	@if [ -d "$(FIRMWARE_DIR)" ] && [ "$$(ls -A $(FIRMWARE_DIR) 2>/dev/null)" ]; then \
		find $(FIRMWARE_DIR) -name "*.uf2" -printf "  $(GREEN)%f$(NC)\n" 2>/dev/null || \
		ls $(FIRMWARE_DIR)/*.uf2 2>/dev/null | sed 's|.*/||' | sed 's/^/  $(GREEN)/' | sed 's/$$/$(NC)/'; \
	else \
		echo "  $(YELLOW)Aucun firmware trouvé. Utilisez 'make build' pour en générer.$(NC)"; \
	fi

# Vérifier la configuration
check:
	@echo "$(BLUE)[INFO]$(NC) Vérification de la configuration..."
	@if [ ! -f "build.yaml" ]; then \
		echo "$(RED)[ERROR]$(NC) Fichier build.yaml manquant"; \
		exit 1; \
	fi
	@if [ ! -d "$(CONFIG_DIR)" ]; then \
		echo "$(RED)[ERROR]$(NC) Dossier config/ manquant"; \
		exit 1; \
	fi
	@if [ ! -f "$(CONFIG_DIR)/corne.keymap" ]; then \
		echo "$(RED)[ERROR]$(NC) Fichier corne.keymap manquant"; \
		exit 1; \
	fi
	@if [ ! -f "$(CONFIG_DIR)/west.yml" ]; then \
		echo "$(RED)[ERROR]$(NC) Fichier west.yml manquant"; \
		exit 1; \
	fi
	@if command -v west >/dev/null 2>&1; then \
		echo "$(GREEN)[OK]$(NC) West est installé ($$(west --version))"; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) West n'est pas installé. Utilisez 'make install'"; \
	fi
	@if command -v yq >/dev/null 2>&1; then \
		echo "$(GREEN)[OK]$(NC) yq est installé ($$(yq --version))"; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) yq n'est pas installé (optionnel)"; \
	fi
	@echo "$(GREEN)[OK]$(NC) Configuration valide"

# Configuration initiale complète
setup: install check
	@echo "$(GREEN)[SUCCESS]$(NC) Configuration initiale terminée"
	@echo "$(BLUE)[INFO]$(NC) Vous pouvez maintenant utiliser 'make build'"

# Test de la configuration (sans build complet)
test:
	@echo "$(BLUE)[INFO]$(NC) Test de la configuration..."
	@$(MAKE) check
	@if command -v yq >/dev/null 2>&1; then \
		echo "$(BLUE)[INFO]$(NC) Test du parsing de build.yaml:"; \
		yq e '.include[] | [.board, .shield // "", .snippet // ""] | @csv' build.yaml | head -5; \
	else \
		echo "$(YELLOW)[WARNING]$(NC) yq non disponible, test de parsing limité"; \
	fi
	@echo "$(GREEN)[SUCCESS]$(NC) Test de configuration réussi"

# Vérifier la configuration ZMK overlay
verify-zmk-config:
	@echo "$(BLUE)[INFO]$(NC) Vérification de la configuration ZMK..."
	@if [ ! -f "config/zmk-overlay.conf" ]; then \
		echo "$(RED)[ERROR]$(NC) Fichier config/zmk-overlay.conf manquant"; \
		echo "$(BLUE)[INFO]$(NC) Exécutez 'make install' pour le créer automatiquement"; \
		exit 1; \
	fi
	@if ! grep -q "CONFIG_NEWLIB_LIBC=y" config/zmk-overlay.conf; then \
		echo "$(RED)[ERROR]$(NC) Configuration NEWLIB manquante dans zmk-overlay.conf"; \
		exit 1; \
	fi
	@if ! grep -q "CONFIG_NEWLIB_LIBC=y" scripts/build.sh; then \
		echo "$(RED)[ERROR]$(NC) Options de configuration manquantes dans build.sh"; \
		echo "$(BLUE)[INFO]$(NC) Exécutez 'make install' pour les ajouter automatiquement"; \
		exit 1; \
	fi
	@echo "$(GREEN)[OK]$(NC) Configuration ZMK valide"

# Nettoyer tous les fichiers générés
clean-all:
	@echo "$(BLUE)[INFO]$(NC) Nettoyage de tous les fichiers générés..."
	@if [ -d "build" ]; then \
		rm -rf build; \
		echo "$(GREEN)[OK]$(NC) Dossier build/ supprimé"; \
	fi
	@if [ -d ".west" ]; then \
		rm -rf .west; \
		echo "$(GREEN)[OK]$(NC) Configuration West supprimée"; \
	fi
	@if [ -d "$(FIRMWARE_DIR)" ]; then \
		rm -rf $(FIRMWARE_DIR); \
		echo "$(GREEN)[OK]$(NC) Dossier firmware/ supprimé"; \
	fi
	@if [ -d "zmk" ]; then \
		rm -rf zmk; \
		echo "$(GREEN)[OK]$(NC) Dossier zmk/ supprimé"; \
	fi
	@if [ -d "zephyr" ]; then \
		rm -rf zephyr; \
		echo "$(GREEN)[OK]$(NC) Dossier zephyr/ supprimé"; \
	fi
	@echo "$(GREEN)[SUCCESS]$(NC) Nettoyage terminé"

# Diagnostic complet de l'environnement
diagnose:
	@echo "$(BLUE)[INFO]$(NC) Diagnostic complet de l'environnement ZMK..."
	@$(DIAGNOSE_SCRIPT)

# Vérifier que les scripts existent
$(BUILD_SCRIPT):
	@echo "$(RED)[ERROR]$(NC) Script de build manquant: $@"
	@exit 1

$(INSTALL_SCRIPT):
	@echo "$(RED)[ERROR]$(NC) Script d'installation manquant: $@"
	@exit 1

$(DIAGNOSE_SCRIPT):
	@echo "$(RED)[ERROR]$(NC) Script de diagnostic manquant: $@"