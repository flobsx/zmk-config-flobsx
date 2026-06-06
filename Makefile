# ZMK Config — Local build Makefile
# Usage:
#   make          → build both halves
#   make left     → build left half only
#   make right    → build right half only
#   make clean    → remove build directories
#   make setup    → initialise west workspace (run once)

BOARD        := nice_nano_v2
CONFIG_DIR   := config
ZMK_APP      := zmk/app
LEFT_DIR     := build/left
RIGHT_DIR    := build/right
FIRMWARE_DIR := firmware

SHIELD_LEFT  := "corne_left nice_view_adapter nice_view"
SHIELD_RIGHT := "corne_right nice_view_adapter nice_view"
SNIPPET_LEFT := studio-rpc-usb-uart

EXTRA_MODULES := $(PWD)

.PHONY: help all left right setup clean flash-info

help:
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║  ZMK Config — Local build helper                                 ║"
	@echo "╠══════════════════════════════════════════════════════════════════╣"
	@echo "║  This Makefile compiles the firmware for a wireless split      ║"
	@echo "║  Corne keyboard using Zephyr / ZMK tooling.                    ║"
	@echo "║                                                                  ║"
	@echo "║  Available commands:                                             ║"
	@echo "║    make setup      initialise the Zephyr workspace (run once)    ║"
	@echo "║    make left       build firmware for the left half              ║"
	@echo "║    make right      build firmware for the right half             ║"
	@echo "║    make all        build both halves                             ║"
	@echo "║    make clean      remove build directories                      ║"
	@echo "║    make flash-info show flashing instructions                    ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Quick start:"
	@echo "  1. make setup"
	@echo "  2. make"
	@echo "  3. make flash-info"

all: left right

setup:
	@echo "==> Initialising west workspace..."
	west init -l $(CONFIG_DIR)
	west update --fetch-opt=--filter=tree:0
	west zephyr-export

$(LEFT_DIR):
	@echo "==> Building left half..."
	west build -s $(ZMK_APP) -d $(LEFT_DIR) -b $(BOARD) -S $(SNIPPET_LEFT) -- \
		-DZMK_CONFIG="$(PWD)/$(CONFIG_DIR)" \
		-DSHIELD=$(SHIELD_LEFT) \
		-DZMK_EXTRA_MODULES="$(EXTRA_MODULES)"
	@mkdir -p $(FIRMWARE_DIR)
	@cp $(LEFT_DIR)/zephyr/zmk.uf2 $(FIRMWARE_DIR)/corne_left.uf2
	@echo "==> Left firmware: $(FIRMWARE_DIR)/corne_left.uf2"

$(RIGHT_DIR):
	@echo "==> Building right half..."
	west build -s $(ZMK_APP) -d $(RIGHT_DIR) -b $(BOARD) -- \
		-DZMK_CONFIG="$(PWD)/$(CONFIG_DIR)" \
		-DSHIELD=$(SHIELD_RIGHT) \
		-DZMK_EXTRA_MODULES="$(EXTRA_MODULES)"
	@mkdir -p $(FIRMWARE_DIR)
	@cp $(RIGHT_DIR)/zephyr/zmk.uf2 $(FIRMWARE_DIR)/corne_right.uf2
	@echo "==> Right firmware: $(FIRMWARE_DIR)/corne_right.uf2"

left: setup-check $(LEFT_DIR)

right: setup-check $(RIGHT_DIR)

setup-check:
	@if [ ! -d "zmk" ]; then \
		echo "Error: ZMK workspace not initialised. Run 'make setup' first."; \
		exit 1; \
	fi

clean:
	@echo "==> Cleaning build directories..."
	@rm -rf $(LEFT_DIR) $(RIGHT_DIR)

flash-info:
	@echo "==> Flashing instructions:"
	@echo "  1. Double-tap the RESET button on the half you want to flash."
	@echo "  2. A USB mass-storage drive should appear."
	@echo "  3. Copy the matching .uf2 file to that drive:"
	@echo "     - Left half : $(FIRMWARE_DIR)/corne_left.uf2"
	@echo "     - Right half: $(FIRMWARE_DIR)/corne_right.uf2"
