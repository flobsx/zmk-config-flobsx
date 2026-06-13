# Configuration
IMAGE_NAME := zmk-local
BUILD_DIR := $(shell pwd)/build
CONFIG_DIR := $(shell pwd)/config
CACHE_VOLUME := zmk-cache

# Docker flags
DOCKER_FLAGS := --rm \
  -v $(CONFIG_DIR):/zmk/config \
  -v $(BUILD_DIR):/zmk/build \
  -v $(CACHE_VOLUME):/zmk/workspace

# Phony targets
.PHONY: setup build flash clean shell help

# Default target
help:
	@echo "ZMK Local Build Tooling"
	@echo ""
	@echo "Usage:"
	@echo "  make setup    - Initialize workspace (first time only)"
	@echo "  make build    - Build firmware for left + right halves"
	@echo "  make flash    - Build and flash firmware via USB"
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
	@echo "  FLASH_METHOD=dfu make flash  # (future)"

# Initialize workspace (first time)
setup:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME) scripts/
	@echo ""
	@echo "Initializing west workspace (this may take 5-10 min on first run)..."
	docker run $(DOCKER_FLAGS) $(IMAGE_NAME) setup.sh
	@echo ""
	@echo "✓ Setup complete. You can now run 'make build'."

# Build left + right
build:
	@echo "Building firmware..."
	docker run $(DOCKER_FLAGS) $(IMAGE_NAME) build.sh

# Flash via USB (default)
flash: build
	@echo ""
	@echo "Flashing firmware..."
	docker run $(DOCKER_FLAGS) \
	  --device=/dev/ttyACM0:/dev/ttyACM0 \
	  --device=/dev/sda:/dev/sda \
	  -v /media:/media:rw \
	  -e FLASH_METHOD=$(or $(FLASH_METHOD),usb) \
	  $(IMAGE_NAME) flash.sh

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
