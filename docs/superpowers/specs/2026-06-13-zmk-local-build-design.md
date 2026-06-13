# ZMK Local Build Tooling — Design Spec

**Date**: 2026-06-13  
**Status**: Approved for implementation  
**Scope**: Local Docker-based build and flash tooling for ZMK firmware

---

## Context & Motivation

The current ZMK config repository (`zmk-config-flobsx`) relies entirely on GitHub Actions for building firmware. While this works, it creates friction:

- **Slow iteration loop**: Every keymap change requires a git push + CI wait (~5-10 min) before testing on hardware.
- **Limited experimentation**: Testing custom ZMK behaviors or module modifications is impractical without local build capability.

This design introduces a local Docker-based toolchain that enables:
1. **Rapid iteration**: Build firmware locally in ~30s (with cache) vs ~5-10 min in CI.
2. **Deep experimentation**: Foundation for future ZMK source-level development (custom behaviors, modules).

---

## Requirements

| Requirement | Priority | Notes |
|-------------|----------|-------|
| Docker-based build environment | Must | No native toolchain installation on host |
| Build both halves (left + right) in one command | Must | Single `make build` produces both `.uf2` files |
| Flash firmware to nice!nano via USB | Must | Auto-detect bootloader mode, copy `.uf2` |
| Persistent build cache | Must | West module cache survives container restarts |
| Linux host support | Must | Device passthrough for USB flash |
| Extensible to DFU flash method | Should | Architecture supports future `FLASH_METHOD=dfu` |
| Extensible to ZMK source dev | Should | Architecture supports future `ZMK_SOURCE=/path` bind-mount |
| Integrated in repo | Must | Tooling lives in `scripts/` within `zmk-config-flobsx` |

---

## Architecture

### File Structure

```
zmk-config-flobsx/
├── build.yaml              # (existing) GitHub Actions matrix
├── config/                 # (existing) keymap, conf, west.yml
├── scripts/
│   ├── Dockerfile          # ZMK build image + dfu-util
│   ├── setup.sh            # west init + west update (first time)
│   ├── build.sh            # west build for left + right shields
│   └── flash.sh            # USB detection + .uf2 copy
├── Makefile                # User interface: setup, build, flash, clean
└── .gitignore              # Ignore build/, .west/
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Host (Linux)                                                 │
│                                                              │
│  make setup ─────────────────────────────────────────┐      │
│  make build ──────┐                                  │      │
│  make flash ──────┤                                  ▼      │
│                   │                        ┌──────────────────┐
│                   │                        │ Docker Container │
│                   │                        │                  │
│                   ▼                        │  /zmk/workspace  │
│          ┌────────────────┐                │  (west cache)    │
│          │ Volume:        │◄───────────────┤                  │
│          │ zmk-cache      │                │  /zmk/config     │
│          └────────────────┘                │  (bind-mount)    │
│                                            │                  │
│  build/output/*.uf2 ◄──────────────────────┤  /zmk/build      │
│          │                                 │  (bind-mount)    │
│          │                                 │                  │
│          ▼                                 │  build.sh /      │
│   nice!nano USB ◄──────────────────────────┤  flash.sh        │
│   (bootloader)                             └──────────────────┘
└─────────────────────────────────────────────────────────────┘
```

### Docker Volumes

| Volume | Type | Purpose |
|--------|------|---------|
| `zmk-cache` | Named volume | West module cache (persists across builds) |
| `./config` | Bind-mount | ZMK config (keymap, conf, west.yml) |
| `./build` | Bind-mount | Build outputs (`.uf2` files) |
| `/media` | Bind-mount (ro) | USB mount points (for flash detection) |

---

## Components

### 1. Dockerfile

**Location**: `scripts/Dockerfile`

**Base image**: `zmkfirmware/zmk-build-arm:stable` (official ZMK image with Zephyr SDK, west, ARM toolchain).

**Additions**:
- `dfu-util` for future DFU flash support (~200 KB).
- Copy `setup.sh`, `build.sh`, `flash.sh` into `/usr/local/bin/`.

**No ENTRYPOINT**: The Makefile specifies which script to run via `docker run ... <script>.sh`.

**Future extension**: To enable ZMK source development (approach b), add a build arg `ZMK_SOURCE` and conditionally bind-mount ZMK source. No Dockerfile changes required now.

---

### 2. setup.sh

**Location**: `scripts/setup.sh`

**Purpose**: Initialize the west workspace (first-time only).

**Logic**:
```bash
#!/bin/bash
set -e

if [ ! -d "/zmk/workspace" ]; then
  west init -l /zmk/config
  west update
fi

echo "Setup complete. Workspace ready."
```

**Key points**:
- `west init -l` uses the local `config/west.yml` as the manifest.
- `west update` clones ZMK + modules into `/zmk/workspace` (on the named volume).
- Subsequent runs skip initialization (cache already exists).

**First-run time**: ~5-10 min (downloads ZMK + Zephyr + modules).  
**Subsequent runs**: Instant (cache hit).

---

### 3. build.sh

**Location**: `scripts/build.sh`

**Purpose**: Build firmware for both shields (left + right) and copy `.uf2` outputs.

**Logic**:
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
  echo "Building for shield: $SHIELD"
  west build -b "$BOARD" -d "/zmk/build/$SHIELD" -- \
    -DSHIELD="$SHIELD" \
    -DZMK_CONFIG="/zmk/config"
  
  # Copy .uf2 to output with clear name
  cp "/zmk/build/$SHIELD/zephyr/zmk.uf2" "$OUTPUT_DIR/${SHIELD%% *}.uf2"
done

echo "Build complete. UF2 files in $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
```

**Key points**:
- Loops over both shields (left + right).
- `-DZMK_CONFIG` points to the bind-mounted config directory.
- Outputs are copied to `build/output/` with names `corne_left.uf2` and `corne_right.uf2`.
- Build time with cache: ~30s per shield.

**Error handling**: `set -e` ensures immediate exit on build failure. West error messages are passed through to the user.

---

### 4. flash.sh

**Location**: `scripts/flash.sh`

**Purpose**: Detect nice!nano in bootloader mode and flash `.uf2` via USB mass storage.

**Logic**:
```bash
#!/bin/bash
set -e

OUTPUT_DIR="/zmk/build/output"
METHOD="${FLASH_METHOD:-usb}"  # Default: usb, extensible to dfu
UF2_FILES=("$OUTPUT_DIR"/*.uf2)

if [ ${#UF2_FILES[@]} -eq 0 ]; then
  echo "No UF2 files found. Run build first."
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
      cp "$UF2" "$MOUNT_POINT/"
      echo "  Flashed $SIDE via USB"
      sleep 2  # Wait for reboot
      return 0
    fi
    echo "  Press reset on nice!nano ($SIDE)..."
    sleep 1
  done
}

# Flash via dfu-util (future extension)
flash_dfu() {
  local UF2=$1
  local SIDE=$2
  echo "DFU method not yet implemented. Use USB method for now."
  exit 1
}

# Loop over UF2 files
for UF2 in "${UF2_FILES[@]}"; do
  SIDE=$(basename "$UF2" .uf2)
  
  case "$METHOD" in
    usb) flash_usb "$UF2" "$SIDE" ;;
    dfu) flash_dfu "$UF2" "$SIDE" ;;
    *) echo "Unknown method: $METHOD"; exit 1 ;;
  esac
done

echo "All devices flashed."
```

**Key points**:
- `FLASH_METHOD` environment variable (default `usb`) allows future DFU support.
- `flash_usb()` polls `/media` for `NICE_NANO` mount point (appears when nice!nano is in bootloader).
- User is prompted to press reset on each nice!nano sequentially.
- `flash_dfu()` is a stub for future implementation.

**Error handling**:
- No `.uf2` files → exit with message.
- Mount point not found → infinite loop with user prompt (manual timeout via Ctrl+C).

---

### 5. Makefile

**Location**: `Makefile` (repo root)

**Purpose**: User-facing interface for all operations.

**Targets**:

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
.PHONY: setup build flash clean shell

# Initialize workspace (first time)
setup:
	docker build -t $(IMAGE_NAME) scripts/
	docker run $(DOCKER_FLAGS) $(IMAGE_NAME) setup.sh

# Build left + right
build:
	docker run $(DOCKER_FLAGS) $(IMAGE_NAME) build.sh

# Flash via USB (default)
flash: build
	docker run $(DOCKER_FLAGS) \
	  --device=/dev/ttyACM0:/dev/ttyACM0 \
	  --device=/dev/sda:/dev/sda \
	  -v /media:/media:ro \
	  -e FLASH_METHOD=usb \
	  $(IMAGE_NAME) flash.sh

# Interactive shell (debug)
shell:
	docker run -it $(DOCKER_FLAGS) $(IMAGE_NAME) /bin/bash

# Clean builds + cache
clean:
	rm -rf build/
	docker volume rm $(CACHE_VOLUME) 2>/dev/null || true
```

**Key points**:
- `setup`: Builds Docker image + initializes west workspace.
- `build`: Runs `build.sh` in container. Outputs to `build/output/`.
- `flash`: Depends on `build`, passes USB devices + `/media` for mount detection.
- `shell`: Interactive mode for manual west commands (debug).
- `clean`: Removes build artifacts + west cache volume.

**Usage**:
```bash
make setup          # First time only
make build          # After keymap changes (~30s with cache)
make flash          # Build + flash auto
make clean          # Reset everything
```

**Extensibility**:
- `FLASH_METHOD=dfu make flash` → uses DFU method (when implemented).
- Future: `ZMK_SOURCE=/path/to/zmk` → bind-mount ZMK source for firmware dev.

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| **Build fails** (syntax error, missing module) | `set -e` in `build.sh` → immediate exit, west error message displayed. Makefile propagates non-zero exit code. |
| **No `.uf2` after build** | `flash.sh` checks `ls *.uf2` → "No UF2 files found" + exit 1. |
| **nice!nano not detected** | `flash_usb()` loops with "Press reset..." prompt every second. Manual timeout via Ctrl+C. |
| **Corrupted west cache** | `make clean` removes volume. `make setup` rebuilds from scratch. |
| **Docker image outdated** (ZMK updated) | `make setup` rebuilds image (`docker build` detects Dockerfile changes). |
| **USB permissions** | User must be in `dialout` or `plugdev` group. Not handled by tooling (system config). |

---

## Success Criteria

The tooling is considered functional when:

1. ✅ `make setup` completes without error (image built + workspace initialized).
2. ✅ `make build` produces `build/output/corne_left.uf2` and `build/output/corne_right.uf2`.
3. ✅ `make flash` detects a nice!nano in bootloader and successfully copies the `.uf2`.
4. ✅ Subsequent builds (after cache warm-up) complete in < 1 min.
5. ✅ `make clean` resets the environment without leaving residual files/volumes.

---

## Future Extensions

### 1. DFU Flash Method

**Trigger**: User requests `FLASH_METHOD=dfu`.

**Implementation**:
- Install `dfu-util` in Dockerfile (already included).
- Implement `flash_dfu()` in `flash.sh` using `dfu-util -a 0 -D <file.uf2>`.
- Detect nice!nano in DFU mode via `lsusb` or `dfu-util -l`.

### 2. ZMK Source Development (Approach b)

**Trigger**: User needs to modify ZMK firmware itself (custom behaviors, modules).

**Implementation**:
- Add `ZMK_SOURCE` variable to Makefile.
- Conditionally bind-mount ZMK source: `-v $(ZMK_SOURCE):/zmk/zmk-source`.
- Modify `build.sh` to use local ZMK source instead of cached version.

### 3. Auto-detect Shields from build.yaml

**Trigger**: User adds more shields to `build.yaml` and wants `build.sh` to auto-detect them.

**Implementation**:
- Parse `build.yaml` in `build.sh` using `yq` or `python -c 'import yaml; ...'`.
- Extract shield combinations dynamically.
- **Trade-off**: Adds complexity for a repo with only 2 shields. Defer until needed.

---

## Out of Scope

- **CI/CD changes**: GitHub Actions workflow remains unchanged. Local tooling is complementary.
- **Windows/macOS support**: Tooling targets Linux only. Cross-platform support would require USB passthrough abstractions (e.g., `usbip` for macOS).
- **Automated testing**: No unit tests for shell scripts. Validation is manual (hardware testing).
- **ZMK Studio integration**: `CONFIG_ZMK_STUDIO=n` remains disabled. Enabling it is a separate task.

---

## References

- [ZMK Documentation](https://zmk.dev/docs)
- [ZMK Build Setup](https://zmk.dev/docs/development/setup)
- [West Meta-tool](https://docs.zephyrproject.org/latest/develop/west/)
- [nice!nano Bootloader](https://nicekeyboards.com/docs/nice-nano/getting-started#flashing-firmware)
