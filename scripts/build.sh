#!/bin/bash
set -e

SHIELDS=(
  "corne_left nice_view_adapter nice_futurama_sus"
  "corne_right nice_view_adapter nice_futurama_sus"
)
BOARD="nice_nano_v2"
OUTPUT_DIR="/zmk/build/output"

mkdir -p "$OUTPUT_DIR"

for SHIELD in "${SHIELDS[@]}"; do
  echo "=========================================="
  echo "Building for shield: $SHIELD"
  echo "=========================================="
  
  west build -b "$BOARD" -d "/zmk/build/$SHIELD" -- \
    -DSHIELD="$SHIELD" \
    -DZMK_CONFIG="/zmk/config"
  
  # Copy .uf2 to output with clear name
  UF2_NAME="${SHIELD%% *}.uf2"
  cp "/zmk/build/$SHIELD/zephyr/zmk.uf2" "$OUTPUT_DIR/$UF2_NAME"
  echo "Copied: $OUTPUT_DIR/$UF2_NAME"
done

echo ""
echo "=========================================="
echo "Build complete. UF2 files:"
echo "=========================================="
ls -lh "$OUTPUT_DIR"
