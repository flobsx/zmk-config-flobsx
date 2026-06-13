# Project Overview

ZMK firmware configuration for a **Corne split keyboard** (choc v2 /
v3) using the **Ergo-L** French ergonomic layout. The keyboard runs on
two **nice!nano v2** controllers with **nice_futurama_sus** OLED
displays. Build and flash are handled by GitHub Actions via the ZMK
toolchain — no local build environment is required for normal use.

## Repository Structure

- **`build.yaml`** — GitHub Actions build matrix defining board/shield
  combinations (corne_left + corne_right with nice_futurama_sus).
- **`config/`** — All ZMK configuration files:
  - `corne.conf` — Kconfig options (BT power, debounce, display,
    ZMK Studio toggle).
  - `corne.keymap` — Keymap definition with Ergo-L base layer, French
    AZERTY macro mappings, five layers, combos, and conditional
    (tri-)layers.
  - `west.yml` — West manifest declaring ZMK v0.3 and the
    nice-futurama-sus display module as dependencies.

## Build & Development Commands

This repo uses ZMK's cloud build pipeline. There is **no local build**
unless you set up the full Zephyr/ZMK toolchain.

```bash
# Trigger a build: push to main or open a PR — GitHub Actions handles it
git push origin main

# Firmware artifacts appear in the Actions tab as downloadable ZIPs
# containing .uf2 files for each half (left/right)
```

To flash locally (if you have the ZMK dev environment):

```bash
# West-based build (requires Zephyr SDK + toolchain)
west build -b nice_nano_v2 -d build/left \
  -- -DSHIELD="corne_left nice_view_adapter nice_futurama_sus"
west build -b nice_nano_v2 -d build/right \
  -- -DSHIELD="corne_right nice_view_adapter nice_futurama_sus"

# Flash via UF2 (copy .uf2 to the mounted drive)
cp build/left/zephyr/zmk.uf2 /media/<NICE_NANO>/
cp build/right/zephyr/zmk.uf2 /media/<NICE_NANO>/
```

## Code Style & Conventions

- **Keymap syntax**: ZMK devicetree (`.keymap`, `.conf`, `.yml`).
- **French key macros**: All AZERTY mappings use `FR_` prefix
  (e.g. `FR_EACU`, `FR_CCED`). Define new French keys at the top of
  `corne.keymap` following the same pattern.
- **Layer naming**: Layers are `#define`'d as uppercase constants
  (`BASE`, `RIG`, `LEF`, `TRI`, `MOUSE`). Use these constants — never
  raw numbers — in bindings.
- **Indentation**: 4-space indent inside keymap `bindings` blocks;
  align columns for readability.
- **Commit messages**: Short imperative (`fix`, `Update keymap`,
  `Add combo`). No strict linter enforced.

## Architecture Notes

```
┌─────────────────────────────────────────────────────┐
│                   GitHub Actions                     │
│  build.yaml → ZMK toolchain → .uf2 per half         │
└──────────────────────┬──────────────────────────────┘
                       │ flash
        ┌──────────────┴──────────────┐
        ▼                              ▼
  ┌───────────┐                  ┌───────────┐
  │ Corne Left │  BLE split      │ Corne Right│
  │ nice!nano  │◄──────────────►│ nice!nano  │
  │ v2 + OLED  │   (central)     │ v2 + OLED  │
  └───────────┘                  └───────────┘
```

**Layers** (activated via hold-tap on thumb keys):

| Layer | Index | Activation | Purpose |
|-------|-------|------------|---------|
| Base | 0 | Default | Ergo-L French layout |
| Right (RIG) | 1 | Hold right thumb | Symbols, navigation, arrows |
| Left (LEF) | 2 | Hold left thumb | Numbers, brackets, punctuation |
| Tri-layer (TRI) | 3 | Both thumbs held | F-keys, BT switch, media |
| Mouse | 4 | Combo (Space+Enter) | Mouse movement, scroll, clicks |

**Key mechanisms**:
- **Combos**: Space+Enter toggles Mouse layer (with idle guard).
- **Conditional layers**: RIG + LEF held simultaneously → TRI layer.
- **Hold-tap**: `&lt LEF BSPC` (left thumb = tap=Space, hold=Left layer),
  `&lt RIG ESC` (right thumb = tap=Enter, hold=Right layer).

## Testing Strategy

> TODO: No automated tests exist for ZMK keymap configs.

Validation is manual:

1. Push changes → GitHub Actions builds `.uf2` files.
2. Flash both halves → verify on physical keyboard.
3. Check each layer, combo, and hold-tap behavior.
4. Verify OLED display renders correctly (Futurama theme).

For local syntax validation before pushing:

```bash
# Check devicetree syntax (requires ZMK dev environment)
west build -b nice_nano_v2 -- -DSHIELD=corne_left
# Build errors indicate syntax issues in .keymap or .conf
```

## Security & Compliance

- **No secrets** are stored in this repo. Bluetooth pairing is handled
  at runtime via key combos (`BT_CLR`, `BT_SEL`).
- **Dependencies**: ZMK firmware (MIT license) pulled via `west.yml`
  from `zmkfirmware/zmk` at tag `v0.3`. The display module
  `nice-futurama-sus` is pulled from `whoop-t` on `main` branch —
  pin to a specific commit for reproducibility.
- **License**: Keymap header declares MIT (SPDX).

## Agent Guardrails

- **Do NOT modify** `build.yaml` without understanding the GitHub
  Actions matrix — incorrect shield/board combos will break CI builds.
- **Do NOT change** `west.yml` remotes or revisions without testing
  the build locally first.
- **Do NOT remove** the `FR_` macro definitions — they are the
  foundation of the French layout mapping.
- **Always preserve** the layer index constants (`BASE` through
  `MOUSE`) — renaming them requires updating every binding reference.
- **Test combos and tri-layers** on hardware before committing — these
  are the most error-prone ZMK features.
- **Require human review** for any change to `corne.keymap` base layer
  bindings (Ergo-L muscle memory is hard to retrain).

## Extensibility Hooks

- **ZMK Studio**: Disabled in `corne.conf` (`CONFIG_ZMK_STUDIO=n`).
  Set to `y` and add the `studio-rpc-usb-uart` snippet to `build.yaml`
  to enable real-time keymap editing over USB/BLE.
- **Deep sleep**: Commented out in `corne.conf` (`CONFIG_ZMK_SLEEP=y`).
  Enable for battery savings on the nice!nano.
- **USB logging**: Commented out (`CONFIG_ZMK_USB_LOGGING=y`). Enable
  for debugging — remember to disable after (increases power draw).
- **BT range**: `CONFIG_BT_CTLR_TX_PWR_PLUS_8=y` is active for
  increased wireless range.
- **New layers**: Add a `#define` at the top of `corne.keymap`, then
  add a named block inside the `keymap {}` node.
- **New combos**: Add entries inside the `combos {}` node. Use
  `require-prior-idle-ms` to prevent accidental triggers.
- **Display themes**: The `nice-futurama-sus` module provides the OLED
  widget. Swap or extend by changing the remote/revision in `west.yml`.

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

## Further Reading

- [ZMK Documentation](https://zmk.dev/docs)
- [ZMK Keymap Behaviors](https://zmk.dev/docs/behaviors)
- [ZMK Combos](https://zmk.dev/docs/features/combos)
- [ZMK Conditional Layers](https://zmk.dev/docs/features/conditional-layers)
- [Ergo-L Layout](https://ergol.org)
- [Corne Keyboard](https://github.com/foostan/crkbd)
- [nice!nano](https://nicekeyboards.com/nice-nano)
- [nice-futurama-sus Display Module](https://github.com/whoop-t/nice-futurama-sus)
