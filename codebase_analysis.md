# Comprehensive Codebase Analysis

## 1. Project Overview

- **Project Type**: ZMK (Zephyr Microkernel for Keyboards) Configuration
- **Tech Stack and Frameworks**: ZMK Firmware, Zephyr RTOS, Devicetree (DTS), C preprocessor macros
- **Architecture Pattern**: Hardware configuration with declarative keymap definitions
- **Language(s) and Versions**: Devicetree syntax with C preprocessor macros, YAML for CI/build configuration

## 2. Detailed Directory Structure Analysis

### Root Directory
- **Purpose**: Contains build configuration, local build scripts, and project documentation
- **Key Files**:
  - `build.yaml`: Defines the local build matrix for different board/shield combinations
  - `.gitignore`: Excludes `.vscode` directory and build artifacts from version control
  - `README.md`: Project documentation with links to ZMK resources and build instructions
  - `Makefile`: Local build orchestration with west

### `config/` Directory
- **Purpose**: Core keyboard configuration files
- **Key Files**:
  - `corne.conf`: Zephyr/ZMK configuration options (Bluetooth power, debouncing, Studio support)
  - `corne.keymap`: Main keymap definition with French AZERTY layout, layers, and behaviors
  - `west.yml`: West manifest for dependency management (ZMK firmware source)

### `scripts/` Directory
- **Purpose**: Helper scripts for local development
- **Key Files**:
  - `box.sh`: Colored output helpers for Makefile
  - `new-layout.sh`: Interactive wizard to scaffold new keyboard layouts

### `.vscode/` Directory
- **Purpose**: IDE helpers and development utilities (not version-controlled)
- **Key Files**:
  - `lib/helper.h`: ZMK helper macros for behaviors, layers, combos, and unicode
  - `lib/keymap_french.h`: French AZERTY keycode definitions
  - `lib/french_unicode.dtsi`: Unicode character definitions for French special characters
  - `lib/mouse.h`: Mouse/pointing device configuration

### `boards/` Directory
- **Purpose**: Custom board definitions (currently empty, using upstream shields)

### `firmware/` Directory
- **Purpose**: Compiled firmware binaries (`.uf2` files for left and right halves)

### `zephyr/` Directory
- **Purpose**: Zephyr module configuration
- **Key Files**:
  - `module.yml`: Defines the board root for the Zephyr build system

## 3. File-by-File Breakdown

### Core Application Files
- **`config/corne.keymap`**: Main keymap file defining all keyboard layers and behaviors
  - Defines 5 layers: default, right, left, tri, and mouse
  - Includes French AZERTY keycode mappings
  - Implements home row modifiers (HRM) for efficient typing
  - Defines combo behaviors for special characters (é, è, ê)
  - Configures hold-tap behavior with custom timing parameters

- **`.vscode/lib/helper.h`**: Comprehensive helper macros for ZMK configuration
  - Simplifies behavior definitions (hold-tap, tap-dance, sticky keys, etc.)
  - Provides layer and combo creation macros
  - Implements Unicode input macros for special characters
  - Defines home row modifier macros (HRML/HRMR)

- **`.vscode/lib/keymap_french.h`**: Complete French AZERTY keycode mapping
  - Maps standard US QWERTY positions to French characters
  - Includes shifted and AltGr symbols
  - Provides visual keyboard layout reference in comments

- **`.vscode/lib/french_unicode.dtsi`**: Unicode character definitions
  - Uses ZMK_UNICODE_PAIR/SINGLE macros for French special characters
  - Defines characters like à, è, é, ç, œ, etc.

- **`.vscode/lib/mouse.h`**: Mouse movement and scroll configuration
  - Sets default movement value (600) and scroll value (10)

### Configuration Files
- **`build.yaml`**: Build matrix configuration
  - Defines two build targets: left and right halves
  - Uses `nice_nano_v2` board with `corne_left`/`corne_right` shields
  - Includes `nice_view_adapter` and `nice_view` for OLED display support
  - Adds `studio-rpc-usb-uart` snippet for ZMK Studio support

- **`config/west.yml`**: West manifest
  - Points to ZMK firmware repository (v0.3)
  - Includes the ZMK application west configuration

- **`config/corne.conf`**: Runtime configuration
  - Enables Bluetooth power increase for better wireless range
  - Configures debouncing (1ms press, 10ms release)
  - Enables ZMK Studio for real-time keymap editing
  - Enables custom display status screen
  - Disables Studio locking for easier access

- **`zephyr/module.yml`**: Zephyr module configuration
  - Sets board root to current directory

### Build Tools
- **`Makefile`**: Local build orchestration
  - Manages Python virtual environment with UV
  - Calls west build for both left and right halves
  - Generates keymap from selected layout before building

## 4. API Endpoints Analysis

Not applicable - This is a firmware configuration project, not a web application or API service.

## 5. Architecture Deep Dive

### Overall Application Architecture
This project follows the ZMK firmware architecture pattern:
- **Declarative Configuration**: Uses Devicetree syntax to define hardware behaviors
- **Layer-based Keymapping**: Implements multiple layers for different keyboard modes
- **Behavior-driven Design**: Uses ZMK behaviors (hold-tap, combos, etc.) for advanced functionality

### Data Flow and Request Lifecycle
1. **Build Process**:
   - `make setup` initialises the west workspace and Python environment
   - `make all` generates the keymap and compiles both halves
   - Zephyr build system produces `.uf2` files ready for flashing

2. **Runtime Behavior**:
   - Key presses are processed through the ZMK behavior system
   - Hold-tap logic determines if a key is being held (modifier) or tapped (character)
   - Layer switching occurs via layer-tap behaviors
   - Combos trigger special characters when multiple keys are pressed simultaneously

### Key Design Patterns Used
- **Home Row Modifiers (HRM)**: Modifiers are placed on home row keys, activated when held
- **Layer-tap**: Keys act as layer switches when held, regular keys when tapped
- **Combos**: Multiple keys pressed together produce special outputs
- **Conditional Layers**: Layer 3 (TRI) activates when both Layer 1 (RIG) and Layer 2 (LEF) are active

### Dependencies Between Modules
```
corne.keymap
├── behaviors.dtsi (ZMK built-in)
├── dt-bindings/zmk/keys.h (ZMK built-in)
├── dt-bindings/zmk/bt.h (ZMK built-in)
├── dt-bindings/zmk/pointing.h (ZMK built-in)
├── helper.h (local)
├── keymap_french.h (local)
└── french_unicode.dtsi (local)
```

## 6. Environment & Setup Analysis

### Required Environment Variables
- None specifically required for this project

### Installation and Setup Process
1. Install `uv` Python package manager
2. Run `make setup` to initialise west workspace and Python environment
3. Select layout: `make layout` (or `make LAYOUT=optimot`)
4. Build firmware: `make all`

### Development Workflow
1. Edit keymap in `config/layouts/<name>/corne.keymap` (never edit `config/corne.keymap` directly)
2. Adjust settings in `config/corne.conf` if needed
3. Run `make all` to build locally
4. Flash firmware to keyboard halves using `make flash-info`

### Production Deployment Strategy
- Local builds via `make all`
- Firmware binaries stored in `firmware/` directory
- Manual flashing required (USB mass storage bootloader)
- No over-the-air update mechanism

## 7. Technology Stack Breakdown

### Runtime Environment
- **Zephyr RTOS**: Real-time operating system for embedded devices
- **ZMK Firmware**: Keyboard-specific firmware built on Zephyr

### Frameworks and Libraries
- **ZMK**: Keyboard firmware framework providing behaviors, keycodes, and Bluetooth support
- **Zephyr Devicetree**: Hardware description and configuration
- **West**: Zephyr's meta-tool for project management

### Build Tools
- **West**: Project and dependency management
- **Zephyr CMake/Ninja**: Build system
- **Makefile**: Local build orchestration

### Hardware
- **Nice!Nano v2**: Wireless microcontroller board (nRF52840)
- **Corne Keyboard**: Split ergonomic keyboard
- **Nice!View**: OLED display module

## 8. Visual Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        ZMK CONFIG PROJECT                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Source Code   │────▶│  make all       │────▶│  Firmware .uf2  │
│  (config/)      │     │  (west build)   │     │  binaries       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CONFIGURATION FILES                            │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  corne.keymap   │   corne.conf    │      build.yaml             │
│  (Key Layout)   │  (Settings)     │   (Build Matrix)            │
└─────────────────┴─────────────────┴─────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      KEYMAP LAYERS                              │
├──────────┬──────────┬──────────┬──────────┬──────────────────┤
│ Default  │  Right   │  Left    │   Tri    │     Mouse        │
│ (Base)   │ (Upper)  │ (Lower)  │ (Adjust) │    (Pointer)     │
└──────────┴──────────┴──────────┴──────────┴──────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BEHAVIOR SYSTEM                                │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  Hold-Tap       │    Combos       │   Conditional Layers        │
│  (Home Row Mods)│ (Special Chars) │   (Tri-Layer)               │
└─────────────────┴─────────────────┴─────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     HARDWARE TARGET                               │
├─────────────────┬─────────────────┬─────────────────────────────┤
│ Left Half       │  Right Half     │    Nice!View Display        │
│ + Nice!Nano v2  │  + Nice!Nano v2 │    (OLED Status)            │
└─────────────────┴─────────────────┴─────────────────────────────┘
```

### File Structure Hierarchy

```
zmk-config/
├── Makefile                   # Local build orchestration
├── build.yaml                 # Build matrix
├── config/
│   ├── corne.conf             # ZMK runtime configuration
│   ├── corne.keymap           # Main keymap definition
│   └── west.yml               # Dependency manifest
├── .vscode/
│   └── lib/
│       ├── helper.h            # ZMK helper macros
│       ├── keymap_french.h     # French AZERTY keycodes
│       ├── french_unicode.dtsi # Unicode definitions
│       └── mouse.h             # Mouse configuration
├── boards/
│   └── shields/                # Custom shield definitions (empty)
├── firmware/
│   ├── *.uf2                   # Compiled firmware binaries
└── zephyr/
    └── module.yml              # Zephyr module configuration
```

## 9. Key Insights & Recommendations

### Code Quality Assessment
- **Strengths**:
  - Well-documented keymap with extensive comments
  - Clear layer naming and visual keyboard layout diagrams
  - Modular helper macros for maintainability
  - Comprehensive French character support

- **Areas for Improvement**:
  - Inconsistent comment language (mix of English and French)
  - `.vscode` directory contains important library files but is gitignored
  - No automated testing or validation of keymap configuration
  - Build outputs (firmware files) are tracked in git (1.4MB binary files)

### Potential Improvements
1. **Move library files**: The `.vscode/lib/` directory contains essential configuration files but is gitignored. Consider moving to a `lib/` or `include/` directory at project root.
2. **Add keymap validation**: Implement pre-commit hook to validate keymap syntax before building
3. **Remove binaries**: Add `firmware/` to `.gitignore` and keep binaries locally only
4. **Documentation**: Add troubleshooting guide and flashing instructions
5. **Layer documentation**: Document the purpose and usage of each layer more thoroughly

### Security Considerations
- No sensitive data in repository
- Bluetooth pairing is handled by ZMK firmware (not configurable here)
- Firmware signing not implemented (standard for hobbyist keyboard firmware)

### Performance Optimization Opportunities
- Debouncing values (1ms press, 10ms release) are quite aggressive; monitor for chatter
- Bluetooth transmission power is set to maximum (+8dBm), which may impact battery life
- Consider enabling deep sleep (`CONFIG_ZMK_SLEEP=y`) for better battery life

### Maintainability Suggestions
1. **Version pinning**: Currently uses ZMK v0.3; consider documenting upgrade procedures
2. **Modular keymaps**: Consider splitting layers into separate files for easier maintenance
3. **Comments consistency**: Standardize on English for all comments
4. **Add license**: Currently no explicit license file in repository
5. **Documentation links**: Add direct links to Keyboard Layout Editor saves for each layer
6. **Layer indicators**: Consider adding LED or display indicators for active layer

### Development Workflow Improvements
- Add pre-commit hooks for keymap validation
- Consider using ZMK Studio for real-time keymap editing (already enabled in config)
- Document the combo system usage for new users
- Add a CHANGELOG for tracking keymap modifications

### Notable Features
- **Home Row Modifiers**: Efficient modifier key placement on home row
- **French Optimot Layout**: Custom layout optimized for French language typing
- **Combos for Accents**: Smart combos for é, è, ê characters
- **Mouse Layer**: Dedicated layer for mouse control and scrolling
- **ZMK Studio Support**: Real-time keymap editing capability
- **Nice!View Display**: OLED status display with custom screen support
