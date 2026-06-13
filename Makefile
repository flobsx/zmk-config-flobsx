# ZMK Config — Local build Makefile
# Usage:
#   make          → show help and quick-start guide
#   make setup    → initialise west workspace (run once)
#   make left     → build left half only
#   make right    → build right half only
#   make all      → build both halves
#   make clean    → remove build directories
#   make flash-info → show flashing instructions
#   make copy     → flash both halves (interactive)
#   make copy-left  → flash left half only
#   make copy-right → flash right half only
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

# ── Environment ──────────────────────────────────────────────────
VENV         := .venv
WEST         := $(VENV)/bin/west
PYTHON       := $(VENV)/bin/python
export PATH  := $(VENV)/bin:$(PATH)
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

KEYMAP_SRC   := $(CONFIG_DIR)/layouts/$(LAYOUT)/corne.keymap
KEYMAP_DST   := $(CONFIG_DIR)/corne.keymap

.PHONY: help all left right setup clean flash-info download generate-keymap layout new copy copy-left copy-right

help:
	@LAYOUT="$(LAYOUT)" scripts/box.sh

layout:
	@echo "$(CYAN)==>$(RESET) Select a keyboard layout with $(BOLD)fzf$(RESET)..."
	@layout=$$(ls -1 $(CONFIG_DIR)/layouts/ | fzf --prompt "Layout> " --height ~10) && \
		echo "$$layout" > $(LAYOUT_FILE) && \
		echo "$(GREEN)==>$(RESET) Selected layout: $(BOLD)$$layout$(RESET)" || \
		{ echo "$(YELLOW)==>$(RESET) No layout selected. Keeping: $(BOLD)$(LAYOUT)$(RESET)"; }

all: left right
	@echo ""
	@echo "$(BOLD)$(GREEN)════════════════════════════════════════════════════$(RESET)"
	@echo "$(BOLD)$(GREEN)==> Build complete for layout: $(LAYOUT)$(RESET)"
	@echo "$(GREEN)==> Left firmware : $(CYAN)$(FIRMWARE_DIR)/$(LAYOUT)_corne_left.uf2$(RESET)"
	@echo "$(GREEN)==> Right firmware: $(CYAN)$(FIRMWARE_DIR)/$(LAYOUT)_corne_right.uf2$(RESET)"
	@echo "$(BOLD)$(GREEN)════════════════════════════════════════════════════$(RESET)"

generate-keymap:
	@echo "$(CYAN)==>$(RESET) Generating keymap for layout: $(BOLD)$(LAYOUT)$(RESET)"
	@cp $(KEYMAP_SRC) $(KEYMAP_DST)
	@echo "$(GREEN)==>$(RESET) Keymap ready: $(CYAN)$(KEYMAP_DST)$(RESET)"

setup-python:
	@echo "$(CYAN)==>$(RESET) Creating Python virtual environment with UV..."
	@uv venv $(VENV)
	@uv pip install -p $(VENV) pyelftools west protobuf setuptools
	@echo "$(GREEN)==>$(RESET) Python environment ready"

setup: setup-python
	@echo "$(CYAN)==>$(RESET) Initialising west workspace..."
	$(WEST) init -l $(CONFIG_DIR)
	$(WEST) update --fetch-opt=--filter=tree:0
	$(WEST) zephyr-export

$(LEFT_DIR): generate-keymap
	@echo "$(CYAN)==>$(RESET) Building $(BOLD)left$(RESET) half (layout: $(BOLD)$(LAYOUT)$(RESET))..."
	@$(WEST) build -s $(ZMK_APP) -d $(LEFT_DIR) -b $(BOARD) -S $(SNIPPET_LEFT) -- \
		-DZMK_CONFIG="$(PWD)/$(CONFIG_DIR)" \
		-DSHIELD=$(SHIELD_LEFT) 2>/dev/null || \
	(sed -i "1s|.*|#!$(PWD)/$(PYTHON)|" $(LEFT_DIR)/nanopb/generator/protoc-gen-nanopb 2>/dev/null && \
	 $(WEST) build -s $(ZMK_APP) -d $(LEFT_DIR) -b $(BOARD) -S $(SNIPPET_LEFT) -- \
		-DZMK_CONFIG="$(PWD)/$(CONFIG_DIR)" \
		-DSHIELD=$(SHIELD_LEFT))
	@mkdir -p $(FIRMWARE_DIR)
	@cp $(LEFT_DIR)/zephyr/zmk.uf2 $(FIRMWARE_DIR)/$(LAYOUT)_corne_left.uf2
	@echo "$(GREEN)==>$(RESET) Left firmware: $(CYAN)$(FIRMWARE_DIR)/$(LAYOUT)_corne_left.uf2$(RESET)"

$(RIGHT_DIR): generate-keymap
	@echo "$(CYAN)==>$(RESET) Building $(BOLD)right$(RESET) half (layout: $(BOLD)$(LAYOUT)$(RESET))..."
	@$(WEST) build -s $(ZMK_APP) -d $(RIGHT_DIR) -b $(BOARD) -- \
		-DZMK_CONFIG="$(PWD)/$(CONFIG_DIR)" \
		-DSHIELD=$(SHIELD_RIGHT) 2>/dev/null || \
	(sed -i "1s|.*|#!$(PWD)/$(PYTHON)|" $(RIGHT_DIR)/nanopb/generator/protoc-gen-nanopb 2>/dev/null && \
	 $(WEST) build -s $(ZMK_APP) -d $(RIGHT_DIR) -b $(BOARD) -- \
		-DZMK_CONFIG="$(PWD)/$(CONFIG_DIR)" \
		-DSHIELD=$(SHIELD_RIGHT))
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

download:
	@scripts/download-firmware.sh $(LAYOUT)

# ── Flash / Copy targets ──────────────────────────────────────────

copy:
	@$(MAKE) copy-left
	@echo ""
	@echo "$(CYAN)==>$(RESET) Left half done. $(BOLD)Switch USB cable to the RIGHT half now.${RESET}"
	@echo "$(YELLOW)==>$(RESET) Double-tap RESET on the right half, then press $(BOLD)ENTER${RESET} to continue..."
	@read -r _
	@$(MAKE) copy-right
	@echo ""
	@echo "$(BOLD)$(GREEN)════════════════════════════════════════════════════$(RESET)"
	@echo "$(BOLD)$(GREEN)==> Both halves flashed successfully!$(RESET)"
	@echo "$(BOLD)$(GREEN)════════════════════════════════════════════════════$(RESET)"

copy-left:
	@scripts/copy-firmware.sh left $(FIRMWARE_DIR)/$(LAYOUT)_corne_left.uf2

copy-right:
	@scripts/copy-firmware.sh right $(FIRMWARE_DIR)/$(LAYOUT)_corne_right.uf2

new:
	@scripts/new-layout.sh $(CONFIG_DIR)
