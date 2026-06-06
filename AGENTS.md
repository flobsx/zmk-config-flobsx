# Project Overview

This repository is a **ZMK firmware configuration** for a wireless split Corne keyboard
(Corne v2, 42-key variant). It defines the keymap, hardware
behaviours, Bluetooth settings, and OLED display configuration. Pushing to GitHub triggers
an Actions workflow that compiles `.uf2` firmware images for the left and right halves.
Local builds are also supported via a `Makefile` that calls `west build` directly.

---

## Repository Structure

```
.
├── .github/workflows/build.yml   # CI: calls the upstream ZMK reusable workflow
├── build.yaml                    # Build-matrix: left/right half + nice_view shields
├── config/
│   ├── corne.keymap              # GENERATED — do not edit (copied from layouts/<name>/corne.keymap)
│   ├── corne.conf                # Zephyr / ZMK runtime Kconfig (sleep, BT power, debounce, Studio)
│   ├── west.yml                  # West manifest: pins ZMK firmware v0.3
│   ├── common/                   # Shared layers & behaviours used by all layouts
│   │   └── layers/
│   │       ├── behaviours.dtsi   # Hold-tap behaviour definition
│   │       ├── conditional.dtsi  # Tri-layer conditional rule
│   │       ├── tri.dtsi          # Adjust layer (F-keys, BT, media)
│   │       └── mouse.dtsi        # Mouse / pointing layer
│   └── layouts/                  # One folder per keyboard layout
│       └── optimot/              # French AZERTY Optimot layout (current default)
│           ├── corne.keymap      # Layout master: defines which includes to use
│           ├── corne.conf        # Layout-specific Kconfig overrides
│           └── layers/
│               ├── combos.dtsi   # Combos (é, è, ê, toggle mouse)
│               ├── default.dtsi  # Base layer
│               ├── right.dtsi    # Upper layer (symbols / nav)
│               └── left.dtsi     # Lower layer (French AZERTY accents)
├── .vscode/
│   ├── lib/
│   │   ├── helper.h              # Re-usable macros (hold-tap, combos, layers, unicode)
│   │   ├── keymap_french.h       # French AZERTY → US-QWERTY position mappings
│   │   ├── french_unicode.dtsi   # Unicode pair/single definitions for French special chars
│   │   └── mouse.h               # Pointing-device settings (move / scroll values)
│   └── helpers/                  # > TODO: verify contents if any
├── boards/shields/               # Custom shield definitions (empty; using upstream Corne shields)
├── firmware/                     # Compiled `.uf2` binaries (left & right halves) – do NOT commit new ones
├── zephyr/module.yml             # Zephyr module root declaration
└── README.md                     # Human docs: links, layout editor permalinks, local-build hints
```

**Key take-away for agents:**
- `config/layouts/<name>/corne.keymap` is the **source of truth** for each layout. It decides which `#include` to pull (from `common/` or from its own `layers/`).
- `config/corne.keymap` is **generated** by `make` (copied from the chosen layout). **Never edit it directly.**
- To add a new layout (e.g. `ergol`), create `config/layouts/ergol/` with its own `corne.keymap` and `layers/`.

---

## Build & Development Commands

### Remote build (GitHub Actions)
```bash
# Push to any branch — GitHub Actions compiles both halves automatically.
git push origin <branch>
# Artefacts appear under the workflow run summary.
```

### Local build (Makefile)
```bash
# 1. First time only — initialise the Zephyr workspace
make setup

# 2. Create a new layout
make new          # interactive wizard to scaffold a new layout

# 3. Select layout (default: optimot)
make layout       # interactive selection via fzf
make LAYOUT=ergol # one-shot build with a specific layout

# 4. Build
make left     # left half only
make right    # right half only
make all      # both halves
make clean    # remove build artefacts

# 5. Flash
make flash-info   # show copy-paste flashing instructions
# Then copy firmware/<layout>_corne_left.uf2 or firmware/<layout>_corne_right.uf2
# to the USB mass-storage drive that appears after double-tap RESET.

### Prerequisites
- `uv` (Python package manager): https://docs.astral.sh/uv/getting-started/installation/
- `west` is installed automatically in the `.venv` by the Makefile
```

### Manual west build (experts)
```bash
# 1. Generate the keymap first
make generate-keymap LAYOUT=optimot

# 2. Build
west build -s zmk/app -d build/left -b nice_nano_v2 -S studio-rpc-usb-uart -- \
  -DZMK_CONFIG="$(pwd)/config" \
  -DSHIELD="corne_left nice_view_adapter nice_view" \
  -DZMK_EXTRA_MODULES="$(pwd)"

west build -s zmk/app -d build/right -b nice_nano_v2 -- \
  -DZMK_CONFIG="$(pwd)/config" \
  -DSHIELD="corne_right nice_view_adapter nice_view" \
  -DZMK_EXTRA_MODULES="$(pwd)"
```

---

## Code Style & Conventions

* **Language:** Devicetree syntax with C-preprocessor macros; YAML for CI/build files.
* **Indentation:** 4 spaces in `.keymap` / `.dtsi`; 2 spaces in YAML.
* **Comments:** Use **English** only in code comments and documentation files.
* **Keymap layout diagrams:** Keep ASCII art comments above each `bindings = <...>` block so
the layout stays human-readable.
* **Macro naming:** UPPER_SNAKE_CASE for `#define` macros; descriptive prefix (`FR_` for French
keys, `HRML` / `HRMR` for home-row mods).
* **Layer IDs:** Numeric defines (`#define BAZ 0`, `#define RIG 1`, …) used by layer-tap behaviours.
* **No type system:** Devicetree is untyped; validate by compiling – there is no linter.

---

## Architecture Notes

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   Git Push / PR     │────▶│  GitHub Actions     │────▶│  Firmware artefacts │
│                     │     │  build-user-config  │     │  (*.uf2 left/right) │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────────────┐
                    │  build.yaml matrix                    │
                    │  nice_nano_v2 + corne_left/right      │
                    │  + nice_view_adapter + nice_view      │
                    │  + studio-rpc-usb-uart (left only)    │
                    └───────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────────────┐
                    │  config/corne.keymap                  │
                    │  ├─ behaviours (hold-tap)             │
                    │  ├─ combos (é, è, ê, toggle mouse)   │
                    │  ├─ conditional_layers (tri-layer)     │
                    │  └─ 5 layers: default | right | left  │
                    │              | tri | mouse             │
                    │  (each lives in its own .dtsi file)  │
                    └───────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────────────┐
                    │  .vscode/lib/helper.h                 │
                    │  .vscode/lib/keymap_french.h          │
                    │  .vscode/lib/french_unicode.dtsi      │
                    └───────────────────────────────────────┘
```

### Major components
1. **Keymap (`corne.keymap`)** – Declares all keyboard layers, combos, and behaviours.
2. **Helpers (`helper.h`)** – Macros that reduce boilerplate for hold-tap, combos, conditional
layers, and unicode entry.
3. **French mapping (`keymap_french.h`, `french_unicode.dtsi`)** – Translates physical key
positions to French AZERTY output, including dead keys and AltGr symbols.
4. **Build matrix (`build.yaml`)** – Tells the ZMK CI which board + shield combinations to build.

---

## Testing Strategy

* **No automated tests exist in this repo.**
* **Validation method:** Push a branch and let the upstream ZMK GitHub Actions workflow compile
  the firmware; a successful run proves the Devicetree syntax is valid.
* **Manual QA:** Flash the new `.uf2` to each half and verify:
  1. All layers switch correctly.
  2. Home-row modifiers work as both tap (character) and hold (modifier).
  3. Combos produce the expected French characters.
  4. Bluetooth profile switching works.
  5. OLED display shows the custom status screen.

> TODO: add a CI step that runs `west build --sysbuild` locally or in a container so
> keymap errors are caught before pushing.

---

## Security & Compliance

* **No secrets** are stored in this repository.
* **Bluetooth pairing** is handled entirely by the ZMK firmware; no keys or passcodes are
  configurable here.
* **Firmware binaries** (`firmware/*.uf2`) are tracked in git (≈ 1.4 MB). They contain only
  the compiled open-source ZMK codebase plus this public configuration.
* **License:** MIT (SPDX-License-Identifier present in `corne.keymap`).

---

## Agent Guardrails

| Rule | Rationale |
|------|-----------|
| **Never delete or overwrite `config/corne.keymap` without a backup.** | This is the single source of truth for the layout. |
| **Never delete `config/corne.conf` keys blindly** – comment out with `#` instead. | The owner toggles features (sleep, logging, BT power) regularly. |
| **Do NOT commit new `.uf2` binaries.** | Use GitHub Actions artefacts; binaries bloat the repo. |
| **Do NOT move or rename `.vscode/lib/` files without updating `#include` paths in `corne.keymap`.** | The project currently relies on this gitignored directory. |
| **When editing a layer, modify the matching `.dtsi` in `config/layers/` — never inline it back into `corne.keymap`.** | The split-file layout is intentional for maintainability. |
| **Keep layer file names in sync with their node names** (e.g. `default.dtsi` ↔ `default_layer`). | Makes it obvious which file to open for a given layer. |
| **Do NOT edit `config/corne.keymap` directly.** | It is generated by `make` from `config/layouts/<name>/corne.keymap`. Always edit the source. |
| **Always preserve the ASCII layout comments** inside each layer definition. | They are the only human-readable reference of the layout. |
| **When adding a new layer**, follow the existing pattern: numeric `#define`, `display-name`, ASCII art header, then bindings. | Keeps the file consistent and readable. |
| **Verify Devicetree syntax after edits.** | A missing `&` or `>` silently breaks the firmware. |
| **Do NOT invent new build commands** unless a `Makefile` or `west` wrapper is actually added. | Currently only GitHub Actions is guaranteed to work. |

---

## Extensibility Hooks

* **New layer:** Add a `#define` (e.g. `#define GAME 5`), create a new node under `keymap { }`,
  and wire layer-tap keys in existing layers to reach it.
* **New combo:** Add a node under `combos { }` in `corne.keymap`; use `key-positions = <A B>;`
  and `bindings = <&kp FR_EACU>;`.
* **New French unicode character:** Use the `ZMK_UNICODE_PAIR` or `ZMK_UNICODE_SINGLE` macros
  from `helper.h` in `french_unicode.dtsi`.
* **Feature flags (Kconfig):** Toggle in `config/corne.conf` – e.g. `# CONFIG_ZMK_SLEEP=y`.
* **Display customisation:** The `CONFIG_ZMK_DISPLAY_STATUS_SCREEN_CUSTOM=y` flag enables a
  custom screen; the actual widget definitions live in the ZMK firmware tree (not this repo).
  > TODO: document how to override/customise the status screen if the owner adds local widgets.

---

## Further Reading

* [`README.md`](./README.md) – Links to ZMK docs, Studio, keymap editors, and layout permalink.
* [`codebase_analysis.md`](./codebase_analysis.md) – Deeper architectural analysis of the
  project (generated by an earlier agent pass).
* [ZMK Documentation](https://zmk.dev/docs/)
* [ZMK Config Reference](https://zmk.dev/docs/config/)
* [ZMK Studio](https://zmk.dev/docs/studio/)
* [Keymap Editor](https://nickcoutsos.github.io/keymap-editor/)
* [Keyboard Layout Editor](http://www.keyboard-layout-editor.com/)
