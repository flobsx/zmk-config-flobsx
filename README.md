# ZMK Config — Wireless Corne Optimot Custom

ZMK firmware configuration for a **wireless split Corne keyboard** (Corne v2, 42-key variant)
with the **Optimot** French AZERTY layout. Local builds via `make`, no GitHub Actions required.

## Prerequisites

- [uv](https://docs.astral.sh/uv/getting-started/installation/) — Python package manager

## Quick start

```sh
make setup         # initialise ZMK workspace (run once)
make layout        # choose a layout (default: optimot)
make all           # build both halves
make copy          # flash left, then right (interactive)
```

## All commands

| Command | Description |
|---|---|
| `make` | Show help with available commands |
| `make setup` | Initialise ZMK workspace and Python environment |
| `make new` | Interactive wizard to scaffold a new layout |
| `make layout` | Select layout via fzf |
| `make LAYOUT=ergol left` | Build with a specific layout (one-shot) |
| `make left` | Build left half only |
| `make right` | Build right half only |
| `make all` | Build both halves |
| `make clean` | Remove build directories |
| `make copy` | Flash both halves (left, wait for switch, right) |
| `make copy-left` | Flash left half only |
| `make copy-right` | Flash right half only |
| `make flash-info` | Show manual flashing instructions |

## How it works

- Layouts live under `config/layouts/<name>/` — each is a self-contained folder with its own `corne.keymap` and layer files
- Shared layers (behaviours, tri-layer, mouse) are in `config/common/layers/`
- `config/corne.keymap` is generated from the selected layout — never edit it directly
- The build uses `west` (installed in `.venv` via `uv`)
- `make copy` auto-detects the nice!nano bootloader (`NICENANO` label), copies the `.uf2` file, and waits for the device to reboot

## Layouts

| Layout | Description |
|---|---|
| `optimot` | French AZERTY with home-row mods, combos for accents, OLED, mouse layer, tri-layer |

Use `make new` to scaffold a new layout, or create `config/layouts/<name>/corne.keymap` manually.

## Repository structure

```
.
├── Makefile                     # Local build orchestration
├── build.yaml                   # Build matrix (left + right)
├── config/
│   ├── corne.keymap             # GENERATED — copied from selected layout
│   ├── corne.conf               # ZMK runtime Kconfig (sleep, BT, debounce)
│   ├── west.yml                 # West manifest (ZMK firmware v0.3)
│   ├── zephyr/module.yml        # Zephyr module root declaration
│   ├── common/layers/           # Shared layers & behaviours
│   │   ├── behaviours.dtsi
│   │   ├── conditional.dtsi
│   │   ├── tri.dtsi
│   │   └── mouse.dtsi
│   └── layouts/
│       └── optimot/             # Optimot layout (current default)
│           ├── corne.keymap     # Layout source of truth
│           ├── corne.conf       # Layout-specific overrides
│           └── layers/
│               ├── combos.dtsi
│               ├── default.dtsi
│               ├── right.dtsi
│               └── left.dtsi
├── firmware/                    # Compiled .uf2 binaries
└── scripts/
    ├── box.sh                   # ANSI-coloured help display
    ├── copy-firmware.sh         # Bootloader auto-detection & flash
    └── new-layout.sh            # Interactive layout scaffold
```

## Useful links

- [ZMK Documentation](https://zmk.dev/docs/)
- [ZMK Config Reference](https://zmk.dev/docs/config/)
- [ZMK Studio](https://zmk.dev/docs/studio/)
- [Keymap Editor](https://nickcoutsos.github.io/keymap-editor/)
- [Keyboard Layout Editor](http://www.keyboard-layout-editor.com/)

## keyboard-layout-editor permalinks

| Layer | Link |
|---|---|
| Main | [KLE Permalink](https://keyboard-layout-editor.com/##@@_x:3&a:5&fa@:0&:0&:0&:0&:0&:0&:5%3B%3B&=%0A%C5%93%0A%0A%0A%0A%0Ao&_x:7&a:7&fa@:5%3B%3B&=l%3B&@_y:-0.75&x:2%3B&=j&_x:1%3B&=b&_x:5%3B&=d&_x:1%3B&=%E2%98%85%3B&@_y:-0.75&fa@:9%3B%3B&=%E2%90%9B&_fa@:5%3B%3B&=z&_x:3&a:5&fa@:5&:5&:0&:0&:0&:0&:0%3B%3B&=!%0A%3F&_x:3&a:7%3B&=f&_x:3%3B&=x&=%3B&@_y:-0.5&x:3%3B&=e&_x:7%3B&=s%3B&@_y:-0.75&x:2%3B&=i&_x:1%3B&=u&_x:5%3B&=t&_x:1%3B&=r%3B&@_y:-0.75&fa@:9%3B%3B&=%E2%86%B9&_fa@:5%3B%3B&=a&_x:3&a:5&fa@:0&:0&:0&:0&:0&:0&:5%3B%3B&=%2F%3B%0A%0A%0A%0A%0A%0A,&_x:3&a:7&fa@:5%3B%3B&=p&_x:3%3B&=n&=%3B&@_y:-0.5&x:3%3B&=q&_x:7%3B&=m%3B&@_y:-0.75&x:2%3B&=y&_x:1&a:5&fa@:0&:0&:0&:0&:0&:0&:5%3B%3B&=%2F:%0A%0A%0A%0A%0A%0A.&_x:5&a:7&fa@:5%3B%3B&=c&_x:1%3B&=h%3B&@_y:-0.75&fa@:9%3B%3B&=%E2%87%A7&_fa@:5%3B%3B&=k&_x:3%3B&=w&_x:3%3B&=g&_x:3%3B&=v&_fa@:9%3B%3B&=%E2%87%A7%3B&@_y:-0.04999999999999982&x:3.5&fa@:5%3B%3B&=%E2%9C%B4%EF%B8%8F&_x:6%3B&=%3B&@_r:15&rx:4.75&ry:3.75&y:-0.2999999999999998%3B&=%E2%8C%AB%3B&@_r:25&rx:5.75&y:-0.5499999999999998&x:0.25&fa@:9%3B&h:1.5%3B&=%E2%90%A3%3B&@_r:-25&rx:9.5&y:-0.6499999999999999&x:-1.4499999999999993&h:1.5%3B&=%E2%86%A9%3B&@_r:-15&rx:10.5&y:-0.3500000000000001&x:-1.25&fa@:5%3B%3B&=%E2%8C%A6>) |
