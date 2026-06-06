#!/usr/bin/env bash
# box.sh — Draws a nicely aligned box with ANSI-aware padding
set -euo pipefail

BOLD=$'\033[1m'
RESET=$'\033[0m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
GRAY=$'\033[90m'

# Width of the content area (between the two ║ spaces)
WIDTH=58

# Strip ANSI escape sequences to compute visible length
visible_len() {
    local s="$1"
    echo -n "$s" | sed 's/\x1b\[[0-9;]*m//g' | wc -m
}

# Print a line inside the box, left-aligned, padded to WIDTH
box_line() {
    local text="$1"
    local len
    len=$(visible_len "$text")
    local pad=$(( WIDTH - len ))
    printf "${CYAN}║${RESET}  %s%*s  ${CYAN}║${RESET}\n" "$text" "$pad" ""
}

# Print the header / footer borders
box_top()    { echo -e "${CYAN}╔$(printf '═%.0s' $(seq 1 $((WIDTH + 4))))╗${RESET}"; }
box_divider(){ echo -e "${CYAN}╠$(printf '═%.0s' $(seq 1 $((WIDTH + 4))))╣${RESET}"; }
box_bottom() { echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $((WIDTH + 4))))╝${RESET}"; }

# ── Main ─────────────────────────────────────────────────────────
box_top
box_line "${BOLD}ZMK Config — Local build helper${RESET}"
box_divider
box_line "Compiles firmware for a wireless split Corne keyboard"
box_line "using Zephyr / ZMK tooling."
box_divider
box_line "${BOLD}Available commands:${RESET}"
box_line "  ${GREEN}make setup${RESET}     initialise west workspace (run once)"
box_line "  ${GREEN}make new${RESET}       scaffold a new keyboard layout"
box_line "  ${GREEN}make layout${RESET}    choose layout via fzf (interactive)"
box_line "  ${GREEN}make left${RESET}      build left half"
box_line "  ${GREEN}make right${RESET}     build right half"
box_line "  ${GREEN}make all${RESET}       build both halves"
box_line "  ${GREEN}make clean${RESET}     remove build directories"
box_line "  ${GREEN}make flash-info${RESET}  show flashing instructions"
box_bottom

echo ""
echo -e "${YELLOW}Current layout:${RESET} ${BOLD}${LAYOUT:-optimot}${RESET}"
echo ""
echo -e "${GRAY}Build a specific layout:${RESET}"
echo "  make layout                 # interactive selection via fzf"
echo "  make LAYOUT=ergol all         # one-shot build with a layout"
echo ""
echo -e "${BOLD}Quick start:${RESET}"
echo "  1. make setup"
echo "  2. make new"
echo "  3. make layout"
echo "  4. make all          # or: make left / make right"
echo "  5. make flash-info"
