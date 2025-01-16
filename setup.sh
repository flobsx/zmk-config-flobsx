#!/bin/bash

# Copyright (c) 2020 The ZMK Contributors
# SPDX-License-Identifier: MIT

set -e

check_exists() {
    command_to_run=$1
    error_message=$2
    local __resultvar=$3

    if ! eval "$command_to_run" &> /dev/null; then
        if [[ "$__resultvar" != "" ]]; then
            eval $__resultvar="'false'"
        else
            printf "%s\n" "$error_message"
            exit 1
        fi
    else
        if [[ "$__resultvar" != "" ]]; then
            eval $__resultvar="'true'"
        fi
    fi
}

check_exists "command -v git" "git is not installed, and is required for this script!"
check_exists "command -v curl" "curl is not installed, and is required for this script!" curl_exists
check_exists "command -v wget" "wget is not installed, and is required for this script!" wget_exists

check_exists "git config user.name" "Git username not set!\nRun: git config --global user.name 'My Name'"
check_exists "git config user.email" "Git email not set!\nRun: git config --global user.email 'example@myemail.com'"

# Check to see if the user has write permissions in this directory to prevent a cryptic error later on
if [ ! -w `pwd` ]; then
    echo 'Sorry, you do not have write permissions in this directory.';
    echo 'Please try running this script again from a directory that you do have write permissions for.';
    exit 1
fi

# Parse all commandline options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -w|--wget) force_wget="true"; break;;
        *) echo "Unknown parameter: $1"; exit 1;;
    esac
    shift
done

if [[ $curl_exists == "true" && $wget_exists == "true" ]]; then
    if [[ $force_wget == "true" ]]; then
        download_command="wget "
    else
        download_command="curl -fsOL "
    fi
elif [[ $curl_exists == "true" ]]; then
    download_command="curl -fsOL "
elif [[ $wget_exists == "true" ]]; then
    download_command="wget "
else
    echo 'Neither curl nor wget are installed. One of the two is required for this script!'
    exit 1
fi

repo_path="https://github.com/zmkfirmware/unified-zmk-config-template.git"
title="ZMK Config Setup:"

echo ""
echo "Keyboard Selection:"
PS3="Pick a keyboard: "
options=("2% Milk" "A. Dux" "Advantage 360 Pro" "BAT43" "BDN9 Rev2" "BFO-9000" "Boardsource 3x4 Macropad" "Boardsource 5x12" "BT60 V1 Hotswap" "BT60 V1 Soldered" "BT60 V2" "BT65" "BT75 V1" "Chalice" "Clog" "Contra" "Corne" "Corneish Zen v1" "Corneish Zen v2" "Cradio/Sweep" "CRBN Featherlight" "eek!" "Elephant42" "Ergodash" "Eternal Keypad" "Eternal Keypad Lefty" "Ferris 0.2" "Fourier Rev. 1" "Glove80" "Helix" "Hummingbird" "Iris" "Jian" "Jiran" "Jorne" "KBDfans Tofu65 2.0" "Knob Goblin" "Kyria" "Kyria Rev2" "Kyria Rev3" "Leeloo" "Leeloo v2" "Leeloo-Micro" "Lily58" "Lotus58" "MakerDiary m60" "Microdox" "Microdox V2" "MurphPad" "Naked60" "Nibble" "nice!60" "nice!view" "nice!view adapter" "Osprette" "Pancake" "Planck Rev6" "Preonic Rev3" "QAZ" "Quefrency Rev. 1" "Redox" "REVIUNG34" "REVIUNG41" "REVIUNG5" "REVIUNG53" "Romac Macropad" "Romac+ Macropad" "S40NC" "SNAP" "Sofle" "splitkb.com Aurora Corne" "splitkb.com Aurora Helix" "splitkb.com Aurora Lily58" "splitkb.com Aurora Sofle" "splitkb.com Aurora Sweep" "Splitreus62" "TesterProMicro" "TesterXiao" "TG4x" "Tidbit Numpad" "Waterfowl" "ZMK Uno" "Zodiark" )
keyboards_id=("two_percent_milk" "a_dux" "adv360pro" "bat43" "bdn9_rev2" "bfo9000" "boardsource3x4" "boardsource5x12" "bt60_v1_hs" "bt60_v1" "bt60_v2" "bt65_v1" "bt75_v1" "chalice" "clog" "contra" "corne" "corneish_zen_v1" "corneish_zen_v2" "cradio" "crbn" "eek" "elephant42" "ergodash" "eternal_keypad" "eternal_keypad_lefty" "ferris_rev02" "fourier" "glove80" "helix" "hummingbird" "iris" "jian" "jiran" "jorne" "kbdfans_tofu65_v2" "knob_goblin" "kyria" "kyria_rev2" "kyria_rev3" "leeloo" "leeloo_rev2" "leeloo_micro" "lily58" "lotus58" "m60" "microdox" "microdox_v2" "murphpad" "naked60" "nibble" "nice60" "nice_view" "nice_view_adapter" "osprette" "pancake" "planck_rev6" "preonic_rev3" "qaz" "quefrency" "redox" "reviung34" "reviung41" "reviung5" "reviung53" "romac" "romac_plus" "s40nc" "snap" "sofle" "splitkb_aurora_corne" "splitkb_aurora_helix" "splitkb_aurora_lily58" "splitkb_aurora_sofle" "splitkb_aurora_sweep" "splitreus62" "tester_pro_micro" "tester_xiao" "tg4x" "tidbit" "waterfowl" "zmk_uno" "zodiark" )
keyboards_type=("shield" "shield" "board" "shield" "board" "shield" "shield" "shield" "board" "board" "board" "board" "board" "shield" "shield" "shield" "shield" "board" "board" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "board" "shield" "board" "shield" "shield" "shield" "shield" "shield" "shield" "board" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "board" "shield" "shield" "shield" "shield" "board" "board" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "board" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" "shield" )
keyboards_arch=("" "" "arm" "" "arm" "" "" "" "arm" "arm" "arm" "arm" "arm" "" "" "" "" "arm" "arm" "" "" "" "" "" "" "" "arm" "" "arm" "" "" "" "" "" "" "arm" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "arm" "" "" "" "" "arm" "arm" "" "" "" "" "" "" "" "" "" "arm" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" )
keyboards_basedir=("two_percent_milk" "a_dux" "adv360pro" "bat43" "bdn9" "bfo9000" "boardsource3x4" "boardsource5x12" "bt60" "bt60" "ckp" "ckp" "ckp" "chalice" "clog" "contra" "corne" "corneish_zen" "corneish_zen" "cradio" "crbn" "eek" "elephant42" "ergodash" "eternal_keypad" "eternal_keypad" "ferris" "fourier" "glove80" "helix" "hummingbird" "iris" "jian" "jiran" "jorne" "kbdfans_tofu65" "knob_goblin" "kyria" "kyria" "kyria" "leeloo" "leeloo" "leeloo_micro" "lily58" "lotus58" "m60" "microdox" "microdox" "murphpad" "naked60" "nibble" "nice60" "nice_view" "nice_view_adapter" "osprette" "pancake" "planck" "preonic" "qaz" "quefrency" "redox" "reviung34" "reviung41" "reviung5" "reviung53" "romac" "romac_plus" "s40nc" "snap" "sofle" "splitkb_aurora_corne" "splitkb_aurora_helix" "splitkb_aurora_lily58" "splitkb_aurora_sofle" "splitkb_aurora_sweep" "splitreus62" "tester_pro_micro" "tester_xiao" "tg4x" "tidbit" "waterfowl" "zmk_uno" "zodiark" )
keyboards_split=("n" "y" "n" "n" "n" "y" "n" "n" "n" "n" "n" "n" "n" "n" "y" "n" "y" "n" "n" "y" "n" "n" "y" "y" "n" "n" "n" "y" "n" "y" "n" "y" "y" "y" "y" "n" "n" "y" "y" "y" "y" "y" "y" "y" "y" "n" "y" "y" "n" "n" "n" "n" "n" "n" "n" "n" "n" "n" "n" "y" "y" "n" "n" "n" "n" "n" "n" "n" "y" "y" "y" "y" "y" "y" "y" "y" "n" "n" "n" "n" "y" "n" "y" )
keyboards_shield=("y" "y" "n" "y" "n" "y" "y" "y" "n" "n" "n" "n" "n" "y" "y" "y" "y" "n" "n" "y" "y" "y" "y" "y" "y" "y" "n" "y" "n" "y" "y" "y" "y" "y" "y" "n" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "n" "y" "y" "y" "y" "n" "n" "y" "y" "y" "y" "y" "y" "y" "y" "y" "n" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" "y" )

a_dux_siblings=("a_dux_left" "a_dux_right" )
adv360pro_siblings=("adv360pro_left" "adv360pro_right" )
bfo9000_siblings=("bfo9000_left" "bfo9000_right" )
clog_siblings=("clog_left" "clog_right" )
corne_siblings=("corne_left" "corne_right" )
corneish_zen_v1_siblings=("corneish_zen_v1_left" "corneish_zen_v1_right" )
corneish_zen_v2_siblings=("corneish_zen_v2_left" "corneish_zen_v2_right" )
cradio_siblings=("cradio_left" "cradio_right" )
elephant42_siblings=("elephant42_left" "elephant42_right" )
ergodash_siblings=("ergodash_left" "ergodash_right" )
fourier_siblings=("fourier_left" "fourier_right" )
glove80_siblings=("glove80_lh" "glove80_rh" )
helix_siblings=("helix_left" "helix_right" )
iris_siblings=("iris_left" "iris_right" )
jian_siblings=("jian_left" "jian_right" )
jiran_siblings=("jiran_left" "jiran_right" )
jorne_siblings=("jorne_left" "jorne_right" )
kyria_siblings=("kyria_left" "kyria_right" )
kyria_rev2_siblings=("kyria_rev2_left" "kyria_rev2_right" )
kyria_rev3_siblings=("kyria_rev3_left" "kyria_rev3_right" )
leeloo_siblings=("leeloo_left" "leeloo_right" )
leeloo_rev2_siblings=("leeloo_rev2_left" "leeloo_rev2_right" )
leeloo_micro_siblings=("leeloo_micro_left" "leeloo_micro_right" )
lily58_siblings=("lily58_left" "lily58_right" )
lotus58_siblings=("lotus58_left" "lotus58_right" )
microdox_siblings=("microdox_left" "microdox_right" )
microdox_v2_siblings=("microdox_v2_left" "microdox_v2_right" )
quefrency_siblings=("quefrency_left" "quefrency_right" )
redox_siblings=("redox_left" "redox_right" )
snap_siblings=("snap_left" "snap_right" )
sofle_siblings=("sofle_left" "sofle_right" )
splitkb_aurora_corne_siblings=("splitkb_aurora_corne_left" "splitkb_aurora_corne_right" )
splitkb_aurora_helix_siblings=("splitkb_aurora_helix_left" "splitkb_aurora_helix_right" )
splitkb_aurora_lily58_siblings=("splitkb_aurora_lily58_left" "splitkb_aurora_lily58_right" )
splitkb_aurora_sofle_siblings=("splitkb_aurora_sofle_left" "splitkb_aurora_sofle_right" )
splitkb_aurora_sweep_siblings=("splitkb_aurora_sweep_left" "splitkb_aurora_sweep_right" )
splitreus62_siblings=("splitreus62_left" "splitreus62_right" )
waterfowl_siblings=("waterfowl_left" "waterfowl_right" )
zodiark_siblings=("zodiark_left" "zodiark_right" )

select opt in "${options[@]}" "Quit"; do
    case "$REPLY" in
        ''|*[!0-9]*) echo "Invalid option. Try another one."; continue;;

        $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit 1;;
        *)
            if [ $REPLY -gt $(( ${#options[@]}+1 )) ] || [ $REPLY -lt 0 ]; then
                echo "Invalid option. Try another one."
                continue
            fi
            keyboard_index=$(( $REPLY-1 ))
            keyboard=${keyboards_id[$keyboard_index]}
            keyboard_arch=${keyboards_arch[$keyboard_index]}
            keyboard_basedir=${keyboards_basedir[$keyboard_index]}
            keyboard_title=${options[$keyboard_index]}
            keyboard_sibling_var=${keyboard}_siblings[@]
            keyboard_sibling_first=${keyboard}_siblings[0]
            if [ -n "${!keyboard_sibling_first}" ]; then
                keyboard_siblings=${!keyboard_sibling_var}
            else
                keyboard_siblings=( "${keyboard}" )
            fi
            split=${keyboards_split[$keyboard_index]}
            keyboard_shield=${keyboards_shield[$keyboard_index]}
            break
        ;;

    esac
done

if [ "$keyboard_shield" == "y" ]; then
    shields=$keyboard_siblings
    shield=${keyboard}
    shield_title=${keyboard_title}

    prompt="Pick an MCU board:"
    options=("Adafruit KB2040" "Adafruit QT Py RP2040" "BlackPill F401CC" "BlackPill F401CE" "BlackPill F411CE" "BlueMicro840 v1" "BoardSource blok" "Mikoto" "nice!nano v1" "nice!nano v2" "Nordic nRF52840 DK" "Nordic nRF5340 DK" "nRF52840 M.2 Module" "nRFMicro 1.1 (flipped)" "nRFMicro 1.1/1.2" "nRFMicro 1.3/1.4" "nRFMicro 1.3/1.4 (nRF52833)" "PillBug" "Puchi-BLE V1" "QMK Proton-C" "Seeeduino XIAO" "Seeeduino XIAO BLE" "Seeeduino XIAO RP2040" "SparkFun Pro Micro RP2040" )
    board_ids=("adafruit_kb2040" "adafruit_qt_py_rp2040" "blackpill_f401cc" "blackpill_f401ce" "blackpill_f411ce" "bluemicro840_v1" "boardsource_blok" "mikoto" "nice_nano" "nice_nano_v2" "nrf52840dk_nrf52840" "nrf5340dk_nrf5340_cpuapp" "nrf52840_m2" "nrfmicro_11_flipped" "nrfmicro_11" "nrfmicro_13" "nrfmicro_13_52833" "pillbug" "puchi_ble_v1" "proton_c" "seeeduino_xiao" "seeeduino_xiao_ble" "seeeduino_xiao_rp2040" "sparkfun_pro_micro_rp2040" )
    boards_usb_only=("y" "y" "y" "y" "y" "n" "y" "n" "n" "n" "n" "n" "n" "n" "n" "n" "n" "n" "n" "y" "y" "n" "y" "y" )

    boards_revisions=("" "" "" "" "" "" "" "5.20 6.1 6.3 7.2 " "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" )
    boards_default_revision=("" "" "" "" "" "" "" "5.20" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" )

    echo ""
    echo "MCU Board Selection:"
    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do
        case "$REPLY" in
            ''|*[!0-9]*) echo "Invalid option. Try another one."; continue;;

            $(( ${#options[@]}+1 )) ) echo "Goodbye!"; exit 1;;
            *)
                if [ $REPLY -gt $(( ${#options[@]}+1 )) ] || [ $REPLY -lt 0 ]; then
                    echo "Invalid option. Try another one."
                    continue
                fi

                board_index=$(( $REPLY-1 ))

                if [ -n "${!keyboard_sibling_first}" ] && [ "${boards_usb_only[$board_index]}" = "y" ] ; then
                    echo "Wired split is not yet supported by ZMK."
                    exit 1
                fi

                board=${board_ids[$board_index]}
                board_title=${options[$board_index]}
                boards=( "${board}" )
                break
            ;;

        esac
    done

    if [ -n "${boards_revisions[$board_index]}" ]; then
        read -a _valid_revisions <<< "${boards_revisions[$board_index]}"

        _rev_choices=("${_valid_revisions[@]}")
        for (( _i=0; _i<${#_valid_revisions}; _i++ )); do
            if [ "${boards_default_revision[board_index]}" = "${_valid_revisions[_i]}" ]; then
                _rev_choices[_i]+=" (default)"
            fi
        done

        echo ""
        echo "MCU Board Revision:"
        select opt in "${_rev_choices[@]}" "Quit"; do
            case "$REPLY" in
                ''|*[!0-9]*) echo "Invalid option. Try another one."; continue;;

                $(( ${#_valid_revisions[@]}+1 )) ) echo "Goodbye!"; exit 1;;
                *)
                    if [ $REPLY -gt $(( ${#_valid_revisions[@]}+1 )) ] || [ $REPLY -lt 0 ]; then
                        echo "Invalid option. Try another one."
                        continue
                    fi

                    _rev_index=$(( $REPLY-1 ))
                    board="${board_ids[$board_index]}@${_valid_revisions[_rev_index]}"
                    boards=( "${board}" )
                    break
                ;;
            esac
        done
    fi
else
    board=${keyboard}
    boards=$keyboard_siblings
fi

read -r -e -p "Copy in the stock keymap for customization? [Yn]: " copy_keymap

if [ -z "$copy_keymap" ] || [ "$copy_keymap" == "Y" ] || [ "$copy_keymap" == "y" ]; then copy_keymap="yes"; fi

read -r -e -p "GitHub Username (leave empty to skip GitHub repo creation): " github_user
if [ -n "$github_user" ]; then
    read -r -p "GitHub Repo Name [zmk-config]: " repo_name
    if [ -z "$repo_name" ]; then repo_name="zmk-config"; fi

    read -r -p "GitHub Repo [https://github.com/${github_user}/${repo_name}.git]: " github_repo

    if [ -z "$github_repo" ]; then github_repo="https://github.com/${github_user}/${repo_name}.git"; fi
else
    repo_name="zmk-config"
fi

echo ""
echo "Preparing a user config for:"
if [ "$keyboard_shield" == "y" ]; then
    echo "* MCU Board: ${boards}"
    echo "* Shield(s): ${shields}"
else
    echo "* Board(s): ${boards}"
fi

if [ "$copy_keymap" == "yes" ]; then
    echo "* Copy Keymap?: ✓"
else
    echo "* Copy Keymap?: ❌"
fi

if [ -n "$github_repo" ]; then
    echo "* GitHub Repo To Push (please create this in GH first!): ${github_repo}"
fi

echo ""
read -r -p "Continue? [Yn]: " do_it

if [ -n "$do_it" ] && [ "$do_it" != "y" ] && [ "$do_it" != "Y" ]; then
    echo "Aborting..."
    exit 1
fi

git clone --single-branch $repo_path ${repo_name}
cd ${repo_name}

pushd config

if [ "$keyboard_shield" == "y" ]; then
    url_base="https://raw.githubusercontent.com/zmkfirmware/zmk/main/app/boards/shields/${keyboard_basedir}"
else
    url_base="https://raw.githubusercontent.com/zmkfirmware/zmk/main/app/boards/${keyboard_arch}/${keyboard_basedir}"
fi

echo "Downloading config file (${url_base}/${keyboard}.conf)"
if ! $download_command "${url_base}/${keyboard}.conf"; then
    echo "Could not find it, falling back to ${url_base}/${keyboard_basedir}.conf"
    $download_command "${url_base}/${keyboard_basedir}.conf" || echo "# Put configuration options here" > "${keyboard}.conf"
fi

if [ "$copy_keymap" == "yes" ]; then
    echo "Downloading keymap file (${url_base}/${keyboard}.keymap)"
    if ! $download_command "${url_base}/${keyboard}.keymap"; then
        echo "Could not find it, falling back to ${url_base}/${keyboard_basedir}.keymap"
        $download_command "${url_base}/${keyboard_basedir}.keymap" || echo "Warning: Could not find a keymap file to download!"
    fi
fi

popd

echo "include:" >> build.yaml

for b in ${boards}; do
    if [ -n "${shields}" ];
    then
        for s in ${shields}; do
            echo "  - board: ${b}" >> build.yaml
            echo "    shield: ${s}" >> build.yaml
        done
    else
        echo "  - board: ${b}" >> build.yaml
    fi
done

rm -rf .git
git init .
git add .
git commit -m "Initial User Config."

if [ -n "$github_repo" ]; then
    git remote add origin "$github_repo"
    git push --set-upstream origin "$(git symbolic-ref --short HEAD)"
    push_return_code=$?

    # If push failed, assume that the origin was incorrect and give instructions on fixing.
    if [ ${push_return_code} -ne 0 ]; then
        echo "Remote repository $github_repo not found..."
        echo "Check GitHub URL, and try adding again."
        echo "Run the following: "
        echo "    git remote rm origin"
        echo "    git remote add origin FIXED_URL"
        echo "    git push --set-upstream origin $(git symbolic-ref --short HEAD)"
        echo "Once pushed, your firmware should be available from GitHub Actions at: ${github_repo%.git}/actions"
        exit 1
    fi

    # TODO: Support determining the actions URL when non-https:// repo URL is used.
    if [ "${github_repo}" != "${github_repo#https://}" ]; then
        echo "Your firmware should be available from GitHub Actions shortly: ${github_repo%.git}/actions"
    fi
fi
