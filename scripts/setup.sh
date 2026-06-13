#!/bin/bash
set -e

WORKSPACE="/zmk/workspace"

# Initialize west workspace if not exists
if [ ! -d "$WORKSPACE/.west" ]; then
  echo "Initializing west workspace in $WORKSPACE..."
  mkdir -p "$WORKSPACE"
  cd "$WORKSPACE"
  west init -l /zmk/config
  west update
  echo "West workspace initialized."
else
  echo "West workspace already exists in $WORKSPACE. Skipping initialization."
fi

echo "Setup complete. Workspace ready."
