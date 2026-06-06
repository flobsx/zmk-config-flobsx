# ZMK Config — Local build Makefile
# Usage:
#   make          → show help and quick-start guide
#   make setup    → initialise west workspace (run once)
#   make left     → build left half only
#   make right    → build right half only
#   make all      → build both halves
#   make clean    → remove build directories
#   make flash-info → show flashing instructions
#
# To build a specific layout (default: optimot):
#   make LAYOUT=optimot all
#   make LAYOUT=ergol left

# ── Colours ───────────────────────────────────────────────────────
BOLD   := \033[1m
RESET  := \033[0m
CYAN   := \033[36m
GREEN  := \033[32m
YELLOW := \033[33m
RED    := \033[31m
GRAY   := \033[90m

BOARD        := nice_nano_v2
CONFIG_DIR   := config
ZMK_APP      := zmk/app
LEFT_DIR     := build/left
RIGHT_DIR    := build/right
FIRMWARE_DIR := firmware

LAYOUT_FILE  := .selected_layout
LAYOUT       ?= $(shell cat $(LAYOUT_FILE) 2>/dev/null || echo optimot)

SHIELD_LEFT  := "corne_left nice_view_adapter nice_view"
SHIELD_RIGHT := "corne_right nice_view_adapter nice_view"
SNIPPET_LEFT := studio-rpc-usb-uart

EXTRA_MODULES := $(PWD)

KEYMAP_SRC   := $(CONFIG_DIR)/layouts/$(LAYOUT)/corne.keymap
KEYMAP_DST   := $(CONFIG_DIR)/corne.keymap

.PHONY: help all left right setup clean flash-info generate-keymap layout new

help:
	@LAYOUT="$(LAYOUT)" scripts/box.sh

layout:
	@echo "$(CYAN)==>$(RESET) Select a keyboard layout with $(BOLD)fzf$(RESET)..."
	@layout=$$(ls -1 $(CONFIG_DIR)/layouts/ | fzf --prompt "Layout> " --height ~10) && \
		echo "$$layout" > $(LAYOUT_FILE) && \
		echo "$(GREEN)==>$(RESET) Selected layout: $(BOLD)$$layout$(RESET)" || \
		{ echo "$(YELLOW)==>$(RESET) No layout selected. Keeping: $(BOLD)$(LAYOUT)$(RESET)"; }

all: left right

generate-keymap:
	@echo "$(CYAN)==>$(RESET) Generating keymap for layout: $(BOLD)$(LAYOUT)$(RESET)"
	@cp $(KEYMAP_SRC) $(KEYMAP_DST)
	@echo "$(GREEN)==>$(RESET) Keymap ready: $(CYAN)$(KEYMAP_DST)$(RESET)"

setup:
	@echo "$(CYAN)==>$(RESET) Initialising west workspace..."
	west init -l $(CONFIG_DIR)
	west update --fetch-opt=--filter=tree:0
	west zephyr-export

$(LEFT_DIR): generate-keymap
	@echo "$(CYAN)==>$(RESET) Building $(BOLD)left$(RESET) half (layout: $(BOLD)$(LAYOUT)$(RESET))..."
	west build -s $(ZMK_APP) -d $(LEFT_DIR) -b $(BOARD) -S $(SNIPPET_LEFT) -- \
		-DZMK_CONFIG="$(PWD)/$(CONFIG_DIR)" \
		-DSHIELD=$(SHIELD_LEFT) \
		-DZMK_EXTRA_MODULES="$(EXTRA_MODULES)"
	@mkdir -p $(FIRMWARE_DIR)
	@cp $(LEFT_DIR)/zephyr/zmk.uf2 $(FIRMWARE_DIR)/$(LAYOUT)_corne_left.uf2
	@echo "$(GREEN)==>$(RESET) Left firmware: $(CYAN)$(FIRMWARE_DIR)/$(LAYOUT)_corne_left.uf2$(RESET)"

$(RIGHT_DIR): generate-keymap
	@echo "$(CYAN)==>$(RESET) Building $(BOLD)right$(RESET) half (layout: $(BOLD)$(LAYOUT)$(RESET))..."
	west build -s $(ZMK_APP) -d $(RIGHT_DIR) -b $(BOARD) -- \
		-DZMK_CONFIG="$(PWD)/$(CONFIG_DIR)" \
		-DSHIELD=$(SHIELD_RIGHT) \
		-DZMK_EXTRA_MODULES="$(EXTRA_MODULES)"
	@mkdir -p $(FIRMWARE_DIR)
	@cp $(RIGHT_DIR)/zephyr/zmk.uf2 $(FIRMWARE_DIR)/$(LAYOUT)_corne_right.uf2
	@echo "$(GREEN)==>$(RESET) Right firmware: $(CYAN)$(FIRMWARE_DIR)/$(LAYOUT)_corne_right.uf2$(RESET)"

left: setup-check $(LEFT_DIR)

right: setup-check $(RIGHT_DIR)

setup-check:
	@if [ ! -d "zmk" ]; then \
		echo "$(RED)Error:$(RESET) ZMK workspace not initialised. Run $(BOLD)make setup$(RESET) first."; \
		exit 1; \
	fi

clean:
	@echo "$(YELLOW)==>$(RESET) Cleaning build directories..."
	@rm -rf $(LEFT_DIR) $(RIGHT_DIR)

flash-info:
	@echo "$(CYAN)==>$(RESET) Flashing instructions:"
	@echo "  1. Double-tap the $(BOLD)RESET$(RESET) button on the half you want to flash."
	@echo "  2. A $(BOLD)USB mass-storage$(RESET) drive should appear."
	@echo "  3. Copy the matching $(BOLD).uf2$(RESET) file to that drive:"
	@echo "     $(GREEN)→$(RESET) Left half : $(CYAN)$(FIRMWARE_DIR)/$(LAYOUT)_corne_left.uf2$(RESET)"
	@echo "     $(GREEN)→$(RESET) Right half: $(CYAN)$(FIRMWARE_DIR)/$(LAYOUT)_corne_right.uf2$(RESET)"

new:
	@scripts/new-layout.sh $(CONFIG_DIR)
