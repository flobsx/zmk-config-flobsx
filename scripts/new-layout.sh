#!/usr/bin/env bash
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────
BOLD=$'\033[1m'
RESET=$'\033[0m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
GRAY=$'\033[90m'

CONFIG_DIR="${1:-config}"

WIDTH=58

visible_len() {
    local s="$1"
    echo -n "$s" | sed 's/\x1b\[[0-9;]*m//g' | wc -m
}

box_line() {
    local text="$1"
    local len
    len=$(visible_len "$text")
    local pad=$(( WIDTH - len ))
    printf "${CYAN}║${RESET}  %s%*s  ${CYAN}║${RESET}\n" "$text" "$pad" ""
}

box_top()    { echo -e "${CYAN}╔$(printf '═%.0s' $(seq 1 $((WIDTH + 4))))╗${RESET}"; }
box_bottom() { echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $((WIDTH + 4))))╝${RESET}"; }

echo ""
box_top
box_line "${BOLD}Create a new keyboard layout${RESET}"
box_bottom
echo ""

read -rp "$(echo -e "${BOLD}Layout name${RESET} (e.g. ergol, bepo): ")" name

if [[ -z "$name" ]]; then
    echo -e "${RED}Error:${RESET} Layout name cannot be empty."
    exit 1
fi

if [[ -d "$CONFIG_DIR/layouts/$name" ]]; then
    echo -e "${RED}Error:${RESET} Layout '${BOLD}$name${RESET}' already exists."
    exit 1
fi

mkdir -p "$CONFIG_DIR/layouts/$name/layers"
cp "$CONFIG_DIR/corne.conf" "$CONFIG_DIR/layouts/$name/corne.conf"

cat > "$CONFIG_DIR/layouts/$name/corne.keymap" << 'EOF'
#include <behaviors.dtsi>
#include <dt-bindings/zmk/keys.h>
#include <dt-bindings/zmk/bt.h>
#include <dt-bindings/zmk/pointing.h>

// Layer IDs
#define BAZ 0
#define RIG 1
#define LEF 2
#define TRI 3
#define MOUSE 4

// Home row mods
#define HRML(k1,k2,k3,k4) &ht LSHIFT k1 &ht LALT k2 &ht LCTRL k3 &ht LGUI k4
#define HRMR(k1,k2,k3,k4) &ht RGUI k1 &ht RCTRL k2 &ht RALT k3 &ht RSHIFT k4

/ {
    behaviors {
        #include "common/layers/behaviours.dtsi"
    };

    combos {
        // Add your combos here, or create a combos.dtsi file
    };

    conditional_layers {
        #include "common/layers/conditional.dtsi"
    };

    keymap {
        compatible = "zmk,keymap";
        #include "layouts/LAYOUT_NAME/layers/default.dtsi"
        #include "layouts/LAYOUT_NAME/layers/right.dtsi"
        #include "layouts/LAYOUT_NAME/layers/left.dtsi"
        #include "common/layers/tri.dtsi"
        #include "common/layers/mouse.dtsi"
    };
};
EOF

sed -i "s/LAYOUT_NAME/$name/g" "$CONFIG_DIR/layouts/$name/corne.keymap"

cat > "$CONFIG_DIR/layouts/$name/layers/default.dtsi" << 'EOF'
    default_layer {
        display-name = "BASE";
        bindings = <
    //╭──────────┬──────────┬──────────┬──────────┬──────────┬──────────╮   ╭──────────┬──────────┬──────────┬──────────┬──────────┬──────────╮
    //│  ESC     │          │          │          │          │          │   │          │          │          │          │          │ BACKSPACE│
            &kp ESC     &trans     &trans     &trans     &trans     &trans         &trans     &trans     &trans     &trans     &trans     &kp BSPC
    //├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
    //│  TAB     │          │          │          │          │          │   │          │          │          │          │          │  DELETE  │
            &kp TAB     HRML( A,      S,         D,         F)      &trans         &trans     HRMR( J,      K,         L,    SEMI)     &kp DEL
    //├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
    //│          │          │          │          │          │          │   │          │          │          │          │          │          │
            &kp LSHIFT  &trans     &trans     &trans     &trans     &trans         &trans     &trans     &trans     &trans     &trans     &trans
    //╰──────────┴──────────┴──────────┴──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┴──────────┴──────────┴──────────╯
                                           &trans     &lt LEF BSPC &kp SPACE     &kp ENTER  &lt RIG ESC &trans
    //                                 ╰──────────┴──────────┴──────────╯   ╰──────────┴──────────┴──────────╯
        >;
    };
EOF

cat > "$CONFIG_DIR/layouts/$name/layers/right.dtsi" << 'EOF'
    right_layer {
        display-name = "^ Upper ^";
        bindings = <
    //╭──────────┬──────────┬──────────┬──────────┬──────────┬──────────╮   ╭──────────┬──────────┬──────────┬──────────┬──────────┬──────────╮
            &trans     &trans     &trans     &trans     &trans     &trans         &trans     &trans     &trans     &trans     &trans     &trans
    //├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
            &trans     &trans     &trans     &trans     &trans     &trans         &trans     &trans     &trans     &trans     &trans     &trans
    //├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
            &trans     &trans     &trans     &trans     &trans     &trans         &trans     &trans     &trans     &trans     &trans     &trans
    //╰──────────┴──────────┴──────────┴──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┴──────────┴──────────┴──────────╯
                                              &trans     &trans     &trans         &trans     &trans     &trans
    //                                 ╰──────────┴──────────┴──────────╯   ╰──────────┴──────────┴──────────╯
        >;
    };
EOF

cat > "$CONFIG_DIR/layouts/$name/layers/left.dtsi" << 'EOF'
    left_layer {
        display-name = "v Lower v";
        bindings = <
    //╭──────────┬──────────┬──────────┬──────────┬──────────┬──────────╮   ╭──────────┬──────────┬──────────┬──────────┬──────────┬──────────╮
            &trans     &trans     &trans     &trans     &trans     &trans         &trans     &trans     &trans     &trans     &trans     &trans
    //├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
            &trans     &trans     &trans     &trans     &trans     &trans         &trans     &trans     &trans     &trans     &trans     &trans
    //├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
            &trans     &trans     &trans     &trans     &trans     &trans         &trans     &trans     &trans     &trans     &trans     &trans
    //╰──────────┴──────────┴──────────┴──────────┼──────────┼──────────┤   ├──────────┼──────────┼──────────┴──────────┴──────────┴──────────╯
                                              &trans     &trans     &trans         &trans     &trans     &trans
    //                                 ╰──────────┴──────────┴──────────╯   ╰──────────┴──────────┴──────────╯
        >;
    };
EOF

echo ""
echo -e "${GREEN}==>${RESET} Layout ${BOLD}$name${RESET} created successfully!"
echo ""
echo -e "${CYAN}Next steps:${RESET}"
echo -e "  1. Edit ${CYAN}config/layouts/$name/layers/default.dtsi${RESET}"
echo -e "  2. Edit ${CYAN}config/layouts/$name/layers/right.dtsi${RESET}"
echo -e "  3. Edit ${CYAN}config/layouts/$name/layers/left.dtsi${RESET}"
echo -e "  4. Run ${GREEN}make layout${RESET} and select ${BOLD}$name${RESET}"
echo -e "  5. Run ${GREEN}make all${RESET} to build"
echo ""
