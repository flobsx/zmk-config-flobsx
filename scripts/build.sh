#!/bin/bash
set -e

WORKSPACE="/zmk/workspace"

# Verify workspace exists
if [ ! -d "$WORKSPACE/.west" ]; then
  echo -e "\033[1;31mERROR: West workspace not found in $WORKSPACE\033[0m"
  echo -e "\033[1;33mRun 'make setup' first to initialize the workspace.\033[0m"
  exit 1
fi

cd "$WORKSPACE"

# Export Zephyr CMake package (required for each build)
west zephyr-export

OUTPUT_DIR="/zmk/build/output"
BUILD_YAML="/zmk/workspace/config/build.yaml"

mkdir -p "$OUTPUT_DIR"

# Clean old UF2 files to avoid stale artifacts from previous builds
rm -f "$OUTPUT_DIR"/*.uf2

# Parse build.yaml to extract board/shield combinations
# Format: each entry in include[] has board and shield fields
if [ ! -f "$BUILD_YAML" ]; then
  echo -e "\033[1;31mERROR: build.yaml not found at $BUILD_YAML\033[0m"
  exit 1
fi

# Extract board and shield pairs from build.yaml
# Using yq to parse YAML - extract all include entries
NUM_ENTRIES=$(yq '.include | length' "$BUILD_YAML")

if [ "$NUM_ENTRIES" -eq 0 ] || [ "$NUM_ENTRIES" = "null" ]; then
  echo -e "\033[1;31mERROR: No entries found in build.yaml include section\033[0m"
  exit 1
fi

echo -e "\033[1;33mFound $NUM_ENTRIES build configuration(s) in build.yaml\033[0m"
echo ""

for i in $(seq 0 $((NUM_ENTRIES - 1))); do
  BOARD=$(yq ".include[$i].board" "$BUILD_YAML")
  SHIELD=$(yq ".include[$i].shield" "$BUILD_YAML")
  
  if [ -z "$BOARD" ] || [ "$BOARD" = "null" ]; then
    echo -e "\033[1;33m⚠  Skipping entry $i: no board specified\033[0m"
    continue
  fi
  
  if [ -z "$SHIELD" ] || [ "$SHIELD" = "null" ]; then
    echo -e "\033[1;33m⚠  Skipping entry $i: no shield specified\033[0m"
    continue
  fi

  # Optional filter: if SHIELD_FILTER is set, only build entries whose shield
  # name contains the filter value (e.g., SHIELD_FILTER=corne_left)
  if [ -n "$SHIELD_FILTER" ]; then
    if ! echo "$SHIELD" | grep -q "$SHIELD_FILTER"; then
      echo -e "\033[0;33m  ⚠  Skipping $SHIELD (doesn't match filter: $SHIELD_FILTER)\033[0m"
      continue
    fi
  fi
  
  echo ""
  echo -e "\033[1;36m╔════════════════════════════════════════════════════════════════╗\033[0m"
  echo -e "\033[1;36m║  Building for board: $BOARD\033[0m"
  echo -e "\033[1;36m║  Shield(s): $SHIELD\033[0m"
  echo -e "\033[1;36m╚════════════════════════════════════════════════════════════════╝\033[0m"
  echo ""
  
  # Use underscore instead of space for build directory name
  BUILD_DIR_NAME="${BOARD}_${SHIELD// /_}"
  
  west build -s /zmk/workspace/zmk/app -b "$BOARD" -d "/zmk/build/$BUILD_DIR_NAME" -- \
    -DSHIELD="$SHIELD" \
    -DZMK_CONFIG="/zmk/workspace/config"
  
  # Copy .uf2 to output with clear name (use first shield as filename)
  FIRST_SHIELD="${SHIELD%% *}"
  UF2_NAME="${FIRST_SHIELD}.uf2"
  cp "/zmk/build/$BUILD_DIR_NAME/zephyr/zmk.uf2" "$OUTPUT_DIR/$UF2_NAME"
  echo -e "\033[1;32m✓ Copied:\033[0m $OUTPUT_DIR/$UF2_NAME"
done

echo ""
echo -e "\033[1;32m╔════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;32m║                    BUILD COMPLETE                                ║\033[0m"
echo -e "\033[1;32m╚════════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[1;33mUF2 files:\033[0m"
ls -lh "$OUTPUT_DIR"
