# Configuration
IMAGE_NAME := zmk-local
BUILD_DIR := $(shell pwd)/build
CONFIG_DIR := $(shell pwd)/config
CACHE_VOLUME := zmk-cache

# Docker flags
DOCKER_FLAGS := --rm \
  -v $(CONFIG_DIR):/zmk/workspace/config \
  -v $(BUILD_DIR):/zmk/build \
  -v $(CACHE_VOLUME):/zmk/workspace \
  -v $(shell pwd)/build.yaml:/zmk/workspace/config/build.yaml:ro

# Phony targets
.PHONY: setup build flash clean shell help build-left build-right flash-left flash-right

# Default target
help:
	@echo "ZMK Local Build Tooling"
	@echo ""
	@echo "Usage:"
	@echo "  make setup    - Initialize workspace (first time only)"
	@echo "  make build    - Build firmware for left + right halves"
	@echo "  make flash    - Build and flash firmware via USB"
	@echo "  make flash-only - Flash all firmware (no rebuild)"
	@echo "  make build-left  - Build left half only"
	@echo "  make build-right - Build right half only"
	@echo "  make flash-left  - Build and flash left half only"
	@echo "  make flash-right - Build and flash right half only"
	@echo "  make clean    - Remove build artifacts and cache"
	@echo "  make shell    - Interactive shell for debugging"
	@echo ""
	@echo "Options:"
	@echo "  FLASH_METHOD=usb|dfu  - Flash method (default: usb)"
	@echo ""
	@echo "Examples:"
	@echo "  make setup"
	@echo "  make build"
	@echo "  make flash"
	@echo "  make flash-only"
	@echo "  FLASH_METHOD=dfu make flash  # (future)"

# Initialize workspace (first time)
setup:
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║                    ZMK LOCAL BUILD SETUP                       ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo -e "\033[1;33m⚠  PRÉREQUIS :\033[0m"
	@echo ""
	@echo -e "  \033[1;36m1.\033[0m Docker installé et running"
	@echo -e "  \033[1;36m2.\033[0m Utilisateur dans le groupe \033[1mdialout\033[0m ou \033[1mplugdev\033[0m (pour accès USB)"
	@echo ""
	@echo -e "\033[1;33m   Pour ajouter votre utilisateur au groupe :\033[0m"
	@echo -e "   \033[1;37msudo usermod -aG dialout $$USER\033[0m"
	@echo -e "   \033[1;33mPuis déconnectez-vous et reconnectez-vous.\033[0m"
	@echo ""
	@echo "──────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "Vérification des prérequis..."
	@command -v docker >/dev/null 2>&1 || { echo -e "\033[1;31m✗ Docker n'est pas installé\033[0m"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo -e "\033[1;31m✗ Docker n'est pas running\033[0m"; exit 1; }
	@echo -e "\033[1;32m✓ Docker est installé et running\033[0m"
	@if groups $$USER | grep -qE '\b(dialout|plugdev)\b'; then \
		echo -e "\033[1;32m✓ Utilisateur dans le groupe dialout/plugdev\033[0m"; \
	else \
		echo -e "\033[1;33m⚠  Utilisateur PAS dans dialout/plugdev (flash USB peut échouer)\033[0m"; \
		echo -e "\033[1;33m   Exécutez: sudo usermod -aG dialout $$USER\033[0m"; \
		echo -e "\033[1;33m   Puis déconnectez-vous et reconnectez-vous.\033[0m"; \
	fi
	@echo ""
	@echo "──────────────────────────────────────────────────────────────────"
	@echo ""
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME) scripts/
	@echo ""
	@echo "Initializing west workspace (this may take 5-10 min on first run)..."
	docker run $(DOCKER_FLAGS) $(IMAGE_NAME) setup.sh
	@echo ""
	@echo -e "\033[1;32m╔════════════════════════════════════════════════════════════════╗\033[0m"
	@echo -e "\033[1;32m║              ✓ SETUP COMPLETE                                  ║\033[0m"
	@echo -e "\033[1;32m╚════════════════════════════════════════════════════════════════╝\033[0m"
	@echo ""
	@echo -e "Vous pouvez maintenant exécuter: \033[1;36mmake build\033[0m"
	@echo ""

# Mount local build.sh so staged/uncommitted changes are used inside the container
BUILD_SCRIPT_MOUNT := -v $(shell pwd)/scripts/build.sh:/usr/local/bin/build.sh

# Build left + right
build:
	@echo "Building firmware..."
	docker run $(BUILD_SCRIPT_MOUNT) $(DOCKER_FLAGS) $(IMAGE_NAME) build.sh

# Build left half only
build-left:
	@echo "Building left half firmware..."
	docker run -e SHIELD_FILTER=corne_left $(BUILD_SCRIPT_MOUNT) $(DOCKER_FLAGS) $(IMAGE_NAME) build.sh

# Build right half only
build-right:
	@echo "Building right half firmware..."
	docker run -e SHIELD_FILTER=corne_right $(BUILD_SCRIPT_MOUNT) $(DOCKER_FLAGS) $(IMAGE_NAME) build.sh

# Build and flash left half only
flash-left: build-left
	@echo ""
	@echo "Flashing left half..."
	./scripts/flash-local.sh corne_left

# Build and flash right half only
flash-right: build-right
	@echo ""
	@echo "Flashing right half..."
	./scripts/flash-local.sh corne_right

# Flash via USB (default)
flash: build
	@echo ""
	@echo "Flashing firmware..."
	./scripts/flash-local.sh

# Flash without rebuilding (use existing UF2 files)
flash-only:
	@echo ""
	@echo "Flashing firmware (no rebuild)..."
	./scripts/flash-local.sh

# Interactive shell (debug)
shell:
	@echo "Starting interactive shell..."
	docker run -it $(DOCKER_FLAGS) $(IMAGE_NAME) /bin/bash

# Clean builds + cache
clean:
	@echo "Removing build artifacts..."
	rm -rf build/
	@echo "Removing west cache volume..."
	docker volume rm $(CACHE_VOLUME) 2>/dev/null || true
	@echo "✓ Clean complete."
