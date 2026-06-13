# ZMK Local Build Tooling — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Docker-based local build and flash tooling for ZMK firmware, enabling rapid iteration on keymap changes without waiting for CI.

**Architecture:** Docker container based on official ZMK build image with west toolchain. Shell scripts handle build orchestration and USB flash detection. Makefile provides user-facing interface. Persistent west cache via Docker named volume for fast incremental builds.

**Tech Stack:** Docker, Bash, Make, west (Zephyr meta-tool), dfu-util

**Spec:** `docs/superpowers/specs/2026-06-13-zmk-local-build-design.md`

---

## File Structure

```
zmk-config-flobsx/
├── scripts/
│   ├── Dockerfile          # ZMK build image + dfu-util
│   ├── setup.sh            # west init + west update (first time)
│   ├── build.sh            # west build for left + right shields
│   └── flash.sh            # USB detection + .uf2 copy
├── Makefile                # User interface: setup, build, flash, clean, shell
└── .gitignore              # Ignore build/, .west/
```

---

## Task 1: Create scripts directory structure

**Files:**
- Create: `scripts/` directory

- [ ] **Step 1: Create scripts directory**

```bash
mkdir -p scripts
```

- [ ] **Step 2: Verify directory exists**

```bash
ls -la scripts/
```

Expected: Empty directory listing

- [ ] **Step 3: Commit directory creation**

```bash
git add scripts/
git commit -m "chore: add scripts directory for local build tooling"
```

---

## Task 2: Create Dockerfile

**Files:**
- Create: `scripts/Dockerfile`

- [ ] **Step 1: Create Dockerfile**

```dockerfile
FROM zmkfirmware/zmk-build-arm:stable

# Install flash tools
RUN apt-get update && apt-get install -y \
    dfu-util \
    && rm -rf /var/lib/apt/lists/*

# Copy build scripts
COPY setup.sh build.sh flash.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

WORKDIR /zmk
```

- [ ] **Step 2: Verify Dockerfile syntax**

```bash
docker build --check scripts/ 2>&1 || echo "Note: --check not supported, will validate on build"
```

Expected: Either passes or message about --check not supported (will validate in next step)

- [ ] **Step 3: Commit Dockerfile**

```bash
git add scripts/Dockerfile
git commit -m "feat: add Dockerfile for ZMK local build environment"
```

---

## Task 3: Create setup.sh script

**Files:**
- Create: `scripts/setup.sh`

- [ ] **Step 1: Create setup.sh**

```bash
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
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x scripts/setup.sh
```

- [ ] **Step 3: Validate shell syntax**

```bash
bash -n scripts/setup.sh && echo "Syntax OK"
```

Expected: "Syntax OK"

- [ ] **Step 4: Commit setup.sh**

```bash
git add scripts/setup.sh
git commit -m "feat: add setup.sh for west workspace initialization"
```

---

## Task 4: Create build.sh script

**Files:**
- Create: `scripts/build.sh`

- [ ] **Step 1: Create build.sh**

```bash
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
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x scripts/build.sh
```

- [ ] **Step 3: Validate shell syntax**

```bash
bash -n scripts/build.sh && echo "Syntax OK"
```

Expected: "Syntax OK"

- [ ] **Step 4: Commit build.sh**

```bash
git add scripts/build.sh
git commit -m "feat: add build.sh for building left + right firmware"
```

---

## Task 5: Create flash.sh script

**Files:**
- Create: `scripts/flash.sh`

- [ ] **Step 1: Create flash.sh**

```bash
#!/bin/bash
set -e

OUTPUT_DIR="/zmk/build/output"
METHOD="${FLASH_METHOD:-usb}"
UF2_FILES=("$OUTPUT_DIR"/*.uf2)

# Check if UF2 files exist
if [ ${#UF2_FILES[@]} -eq 0 ] || [ ! -e "${UF2_FILES[0]}" ]; then
  echo "ERROR: No UF2 files found in $OUTPUT_DIR"
  echo "Run 'make build' first."
  exit 1
fi

# Flash via USB mass storage (mount point detection)
flash_usb() {
  local UF2=$1
  local SIDE=$2
  
  echo "Waiting for nice!nano ($SIDE) in bootloader mode..."
  while true; do
    MOUNT_POINT=$(find /media -name "NICE_NANO" -type d 2>/dev/null | head -1)
    if [ -n "$MOUNT_POINT" ]; then
      echo "  Detected: $MOUNT_POINT"
      cp "$UF2" "$MOUNT_POINT/"
      sync
      echo "  ✓ Flashed $SIDE via USB"
      sleep 2  # Wait for reboot
      return 0
    fi
    echo "  → Press reset on nice!nano ($SIDE)..."
    sleep 1
  done
}

# Flash via dfu-util (future extension)
flash_dfu() {
  local UF2=$1
  local SIDE=$2
  echo "ERROR: DFU method not yet implemented."
  echo "Use USB method (default): make flash"
  exit 1
}

echo "=========================================="
echo "Flashing ${#UF2_FILES[@]} device(s) via $METHOD method"
echo "=========================================="

# Loop over UF2 files
for UF2 in "${UF2_FILES[@]}"; do
  if [ ! -e "$UF2" ]; then
    continue
  fi
  
  SIDE=$(basename "$UF2" .uf2)
  echo ""
  echo "Device: $SIDE"
  
  case "$METHOD" in
    usb) flash_usb "$UF2" "$SIDE" ;;
    dfu) flash_dfu "$UF2" "$SIDE" ;;
    *) 
      echo "ERROR: Unknown flash method: $METHOD"
      echo "Supported methods: usb, dfu"
      exit 1 
      ;;
  esac
done

echo ""
echo "=========================================="
echo "✓ All devices flashed successfully."
echo "=========================================="
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x scripts/flash.sh
```

- [ ] **Step 3: Validate shell syntax**

```bash
bash -n scripts/flash.sh && echo "Syntax OK"
```

Expected: "Syntax OK"

- [ ] **Step 4: Commit flash.sh**

```bash
git add scripts/flash.sh
git commit -m "feat: add flash.sh for USB firmware flashing"
```

---

## Task 6: Create Makefile

**Files:**
- Create: `Makefile` (repo root)

- [ ] **Step 1: Create Makefile**

```makefile
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
```

- [ ] **Step 2: Verify Makefile syntax**

```bash
make -n help 2>&1 | head -5
```

Expected: Dry-run output showing help target commands

- [ ] **Step 3: Test help target**

```bash
make help
```

Expected: Help message showing all targets and options

- [ ] **Step 4: Commit Makefile**

```bash
git add Makefile
git commit -m "feat: add Makefile for user-facing build interface"
```

---

## Task 7: Update .gitignore

**Files:**
- Modify: `.gitignore` (create if doesn't exist)

- [ ] **Step 1: Check if .gitignore exists**

```bash
ls -la .gitignore 2>&1 || echo "File does not exist"
```

- [ ] **Step 2: Create or update .gitignore**

If `.gitignore` exists, append these lines. If not, create it:

```gitignore
# ZMK local build tooling
build/
.west/

# Docker
.docker/
```

- [ ] **Step 3: Verify .gitignore**

```bash
cat .gitignore
```

Expected: Shows build/, .west/, .docker/ entries

- [ ] **Step 4: Commit .gitignore**

```bash
git add .gitignore
git commit -m "chore: add build artifacts to .gitignore"
```

---

## Task 8: Update AGENTS.md with local build documentation

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Read current AGENTS.md**

```bash
cat AGENTS.md
```

- [ ] **Step 2: Add local build section to AGENTS.md**

Append this section before "## Further Reading" (or at end if section doesn't exist):

```markdown
## Local Build Tooling

Local Docker-based build and flash tooling is available for rapid iteration:

### Prerequisites

- Docker installed and running
- User in `dialout` or `plugdev` group (for USB access): `sudo usermod -aG dialout $USER`
- Log out and back in after group change

### Quick Start

```bash
# First time: initialize workspace (5-10 min)
make setup

# Build firmware (~30s with cache)
make build

# Build and flash to nice!nano via USB
make flash

# Interactive shell for debugging
make shell

# Clean everything
make clean
```

### How It Works

- **Docker container**: Based on `zmkfirmware/zmk-build-arm` with dfu-util added
- **Persistent cache**: West modules cached in Docker volume `zmk-cache`
- **Outputs**: `build/output/corne_left.uf2` and `build/output/corne_right.uf2`
- **Flash method**: USB mass storage (detects `NICE_NANO` mount point)

### Flash Procedure

1. Run `make flash`
2. When prompted, press reset button on first nice!nano
3. Wait for flash to complete and device to reboot
4. When prompted, press reset on second nice!nano
5. Wait for completion

### Troubleshooting

- **USB permissions**: Ensure user is in `dialout` group
- **Build fails**: Check `config/corne.keymap` syntax
- **Flash not detected**: Verify nice!nano is in bootloader mode (double-tap reset)
- **Cache issues**: Run `make clean` then `make setup`

### Future Extensions

- `FLASH_METHOD=dfu make flash` — DFU flash method (not yet implemented)
- `ZMK_SOURCE=/path` — Bind-mount ZMK source for firmware development (not yet implemented)
```

- [ ] **Step 3: Verify AGENTS.md update**

```bash
grep -A 5 "Local Build Tooling" AGENTS.md
```

Expected: Shows the new section header and first few lines

- [ ] **Step 4: Commit AGENTS.md update**

```bash
git add AGENTS.md
git commit -m "docs: add local build tooling documentation to AGENTS.md"
```

---

## Task 9: Validate complete setup

**Files:**
- Test: All created files

- [ ] **Step 1: Verify all files exist**

```bash
ls -lh scripts/
ls -lh Makefile
ls -lh .gitignore
```

Expected:
- `scripts/Dockerfile`
- `scripts/setup.sh` (executable)
- `scripts/build.sh` (executable)
- `scripts/flash.sh` (executable)
- `Makefile`
- `.gitignore`

- [ ] **Step 2: Validate all shell scripts**

```bash
for script in scripts/*.sh; do
  echo "Checking $script..."
  bash -n "$script" && echo "  ✓ Syntax OK"
done
```

Expected: All scripts pass syntax check

- [ ] **Step 3: Test Makefile help**

```bash
make help
```

Expected: Help message displays correctly

- [ ] **Step 4: Verify git status**

```bash
git status
```

Expected: All files committed, clean working tree

- [ ] **Step 5: Create summary**

```bash
cat << 'EOF'
========================================
✓ ZMK Local Build Tooling Complete
========================================

Files created:
  - scripts/Dockerfile
  - scripts/setup.sh
  - scripts/build.sh
  - scripts/flash.sh
  - Makefile
  - .gitignore (updated)
  - AGENTS.md (updated)

Next steps:
  1. Run 'make setup' to initialize workspace (5-10 min first time)
  2. Run 'make build' to build firmware (~30s with cache)
  3. Run 'make flash' to build and flash to nice!nano

Documentation:
  - See AGENTS.md "Local Build Tooling" section
  - See docs/superpowers/specs/2026-06-13-zmk-local-build-design.md

========================================
EOF
```

---

## Execution Summary

**Total tasks:** 9  
**Estimated time:** 30-45 minutes (excluding first-time `make setup` which takes 5-10 min)

**Task breakdown:**
- Tasks 1-5: Create scripts (Dockerfile + 3 shell scripts)
- Task 6: Create Makefile
- Task 7: Update .gitignore
- Task 8: Update documentation
- Task 9: Validate complete setup

**Validation checkpoints:**
- After Task 3: `bash -n scripts/setup.sh` passes
- After Task 4: `bash -n scripts/build.sh` passes
- After Task 5: `bash -n scripts/flash.sh` passes
- After Task 6: `make help` displays correctly
- After Task 9: All files exist, all scripts pass syntax check

**Success criteria:**
- ✅ All files created with correct permissions
- ✅ All shell scripts pass syntax validation
- ✅ Makefile help target works
- ✅ Git repository clean (all changes committed)
- ✅ User can run `make setup` → `make build` → `make flash` workflow
