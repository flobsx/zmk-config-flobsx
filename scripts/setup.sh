#!/bin/bash
set -e

# Initialize west workspace if not exists
if [ ! -d "/zmk/workspace" ]; then
  echo "Initializing west workspace..."
  west init -l /zmk/config
  west update
  echo "West workspace initialized."
else
  echo "West workspace already exists. Skipping initialization."
fi

echo "Setup complete. Workspace ready."
