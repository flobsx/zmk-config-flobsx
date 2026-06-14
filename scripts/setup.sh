#!/bin/bash
set -e

WORKSPACE="/zmk/workspace"
CONFIG_DIR="$WORKSPACE/config"

# Initialize west workspace if not exists
if [ ! -d "$WORKSPACE/.west" ]; then
  echo "Initializing west workspace in $WORKSPACE..."
  west init -l "$CONFIG_DIR"
  west update
  west zephyr-export
  echo "West workspace initialized and Zephyr exported."
else
  echo "West workspace already exists in $WORKSPACE. Skipping initialization."
fi

echo "Setup complete. Workspace ready."
