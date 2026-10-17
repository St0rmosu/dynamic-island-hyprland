#!/usr/bin/env bash
# ==============================================================================
# Dynamic Island Hyprland — Wallpaper Backend Selector & Configurator
# ==============================================================================
# Allows choosing and switching the active wallpaper engine:
#   1) awww       (Modern Wayland daemon written in Rust, silky-smooth transitions)
#   2) swww       (High performance wallpaper daemon with animation shaders)
#   3) hyprpaper  (Official Hyprland lightweight paper utility)
#   4) mpvpaper   (Video and animated live wallpaper engine)
#   5) swaybg     (Minimalist, ultra-low resource background setter)
#   6) wpaperd    (Modern multi-monitor daemon with TOML config)
# ==============================================================================

set -e

# Terminal styling
STY_BOLD='\033[1m'
STY_GREEN='\033[32m'
STY_BLUE='\033[34m'
STY_CYAN='\033[36m'
STY_YELLOW='\033[33m'
STY_RED='\033[31m'
STY_RST='\033[0m'

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dynamic-island"
BACKEND_FILE="${CONFIG_DIR}/wallpaper_backend"
mkdir -p "${CONFIG_DIR}"

CURRENT_BACKEND="awww"
[ -f "${BACKEND_FILE}" ] && CURRENT_BACKEND=$(tr -d ' \n\r' < "${BACKEND_FILE}")

show_help() {
    echo -e "${STY_BOLD}Dynamic Island — Wallpaper Backend Selector${STY_RST}"
    echo "Usage: $0 [OPTIONS] [BACKEND_NAME]"
    echo ""
    echo "Options:"
    echo "  -b, --backend <name>   Set backend directly without interactive prompt"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Supported backends: awww, swww, hyprpaper, mpvpaper, swaybg, wpaperd"
}

TARGET_BACKEND=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--backend)
            TARGET_BACKEND="$2"
            shift 2
            ;;
        awww|swww|hyprpaper|mpvpaper|swaybg|wpaperd)
            TARGET_BACKEND="$1"
            shift
            ;;
        *)
            echo -e "${STY_RED}Errore: backend sconosciuto o non supportato: '$1'${STY_RST}"
            show_help
            exit 1
            ;;
    esac
done

# ── TUI Selector Engine (Zero dependencies, Pure Bash) ────────────────────────
tui_get_tty() {
    if [ -c /dev/tty ] && [ -r /dev/tty ] && [ -w /dev/tty ]; then
        echo "/dev/tty"
    elif [ -t 0 ] && [ -t 1 ]; then
        echo "/dev/tty"
    else
        echo ""
    fi
}

tui_select() {
    local prompt="$1"
    local default_idx="${2:-0}"
    shift 2
    local options=("$@")
    local count=${#options[@]}
    local selected="$default_idx"

    local tty_dev
    tty_dev=$(tui_get_tty)

    if [ -z "$tty_dev" ]; then
        TUI_RESULT="$selected"
        echo -e "  \033[1;32m✔\033[0m \033[1;37m${prompt}\033[0m \033[1;36m${options[selected]}\033[0m"
        return 0
    fi

    local old_stty
    old_stty=$(stty -g < "$tty_dev" 2>/dev/null || true)
    cleanup_tui() {
        [ -n "$old_stty" ] && stty "$old_stty" < "$tty_dev" 2>/dev/null || true
        printf "\033[?25h" > "$tty_dev" 2>/dev/null || true
    }
    trap cleanup_tui EXIT INT TERM

    stty -echo -icanon min 1 time 0 < "$tty_dev" 2>/dev/null || true
    printf "\033[?25l" > "$tty_dev"

    echo -e "  \033[1;36m? \033[1;37m${prompt}\033[0m \033[2m(↑/↓ o j/k per navigare, Invio per confermare)\033[0m" > "$tty_dev"
    for i in "${!options[@]}"; do
        if [ "$i" -eq "$selected" ]; then
            echo -e "    \033[1;36m➜ ◉ \033[1;37m${options[i]}\033[0m\033[K" > "$tty_dev"
        else
            echo -e "      \033[2m○ ${options[i]}\033[0m\033[K" > "$tty_dev"
        fi
    done

    while true; do
        local char=""
        IFS= read -rs -n 1 char < "$tty_dev"
        if [[ "$char" == $'\x1b' ]]; then
            local seq=""
            IFS= read -rs -n 2 -t 0.05 seq < "$tty_dev" || true
            if [[ "$seq" == "[A" ]]; then char="UP"; fi
            if [[ "$seq" == "[B" ]]; then char="DOWN"; fi
            if [[ "$seq" == "" ]]; then char="ENTER"; fi
        elif [[ "$char" == "" ]]; then
            char="ENTER"
        elif [[ "$char" == "k" || "$char" == "K" ]]; then
            char="UP"
        elif [[ "$char" == "j" || "$char" == "J" ]]; then
            char="DOWN"
        elif [[ "$char" =~ ^[1-9]$ ]]; then
            local num_val=$((char - 1))
            if [ "$num_val" -lt "$count" ]; then
                selected="$num_val"
                char="ENTER"
            fi
        fi

        case "$char" in
            UP)
                [ "$selected" -gt 0 ] && selected=$((selected - 1)) || selected=$((count - 1))
                ;;
            DOWN)
                [ "$selected" -lt $((count - 1)) ] && selected=$((selected + 1)) || selected=0
                ;;
            ENTER)
                break
                ;;
        esac

        printf "\033[%dA\r" "$count" > "$tty_dev"
        for i in "${!options[@]}"; do
            if [ "$i" -eq "$selected" ]; then
                echo -e "    \033[1;36m➜ ◉ \033[1;37m${options[i]}\033[0m\033[K" > "$tty_dev"
            else
                echo -e "      \033[2m○ ${options[i]}\033[0m\033[K" > "$tty_dev"
            fi
        done
    done

    cleanup_tui
    trap - EXIT INT TERM

    # Collapse cleanly
    printf "\033[%dA\r" "$((count + 1))" > "$tty_dev"
    echo -e "  \033[1;32m✔\033[0m \033[1;37m${prompt}\033[0m \033[1;36m${options[selected]}\033[0m\033[K" > "$tty_dev"
    for ((i=0; i<count; i++)); do
        printf "\033[2K\r" > "$tty_dev"
    done
    printf "\033[%dM" "$count" > "$tty_dev"

    TUI_RESULT="$selected"
    return 0
}

tui_confirm() {
    local prompt="$1"
    local default_yes="${2:-true}"
    local tty_dev
    tty_dev=$(tui_get_tty)

    if [ -z "$tty_dev" ]; then
        [ "$default_yes" = true ] && return 0 || return 1
    fi

    local selected=0
    [ "$default_yes" != true ] && selected=1

    local old_stty
    old_stty=$(stty -g < "$tty_dev" 2>/dev/null || true)
    cleanup_confirm() {
        [ -n "$old_stty" ] && stty "$old_stty" < "$tty_dev" 2>/dev/null || true
        printf "\033[?25h" > "$tty_dev" 2>/dev/null || true
    }
    trap cleanup_confirm EXIT INT TERM

    stty -echo -icanon min 1 time 0 < "$tty_dev" 2>/dev/null || true
    printf "\033[?25l" > "$tty_dev"

    render_confirm() {
        if [ "$selected" -eq 0 ]; then
            echo -en "\r  \033[1;36m? \033[1;37m${prompt}\033[0m   \033[1;30;46m  Sì  \033[0m  \033[2m  No  \033[0m\033[K" > "$tty_dev"
        else
            echo -en "\r  \033[1;36m? \033[1;37m${prompt}\033[0m   \033[2m  Sì  \033[0m  \033[1;30;46m  No  \033[0m\033[K" > "$tty_dev"
        fi
    }

    render_confirm

    while true; do
        local char=""
        IFS= read -rs -n 1 char < "$tty_dev"
        if [[ "$char" == $'\x1b' ]]; then
            local seq=""
            IFS= read -rs -n 2 -t 0.05 seq < "$tty_dev" || true
            if [[ "$seq" == "[C" || "$seq" == "[D" ]]; then char="TOGGLE"; fi
        elif [[ "$char" == "" ]]; then
            char="ENTER"
        elif [[ "$char" == $'\t' || "$char" == " " || "$char" == "h" || "$char" == "l" ]]; then
            char="TOGGLE"
        elif [[ "$char" == "y" || "$char" == "Y" || "$char" == "s" || "$char" == "S" ]]; then
            selected=0; break
        elif [[ "$char" == "n" || "$char" == "N" ]]; then
            selected=1; break
        fi

        case "$char" in
            TOGGLE)
                selected=$(( 1 - selected ))
                render_confirm
                ;;
            ENTER)
                break
                ;;
        esac
    done

    cleanup_confirm
    trap - EXIT INT TERM

    if [ "$selected" -eq 0 ]; then
        echo -e "\r  \033[1;32m✔\033[0m \033[1;37m${prompt}\033[0m \033[1;32m[Sì]\033[0m\033[K" > "$tty_dev"
        return 0
    else
        echo -e "\r  \033[1;33mℹ\033[0m \033[1;37m${prompt}\033[0m \033[1;33m[No]\033[0m\033[K" > "$tty_dev"
        return 1
    fi
}

if [ -z "${TARGET_BACKEND}" ]; then
    echo -e "${STY_CYAN}╭────────────────────────────────────────────────────────────────╮${STY_RST}"
    echo -e "${STY_CYAN}│${STY_RST}     ${STY_BOLD}🖼️  Dynamic Island — Configurazione Wallpaper Engine${STY_RST}       ${STY_CYAN}│${STY_RST}"
    echo -e "${STY_CYAN}╰────────────────────────────────────────────────────────────────╯${STY_RST}"
    echo -e "  ${STY_FAINT}Backend attualmente attivo:${STY_RST} ${STY_BOLD}${CURRENT_BACKEND}${STY_RST}\n"

    DEF_IDX=0
    case "${CURRENT_BACKEND,,}" in
        awww) def_idx=0 ;;
        swww) def_idx=1 ;;
        hyprpaper) def_idx=2 ;;
        mpvpaper) def_idx=3 ;;
        swaybg) def_idx=4 ;;
        wpaperd) def_idx=5 ;;
        *) def_idx=0 ;;
    esac

    tui_select "Seleziona il software desiderato per gestire lo sfondo:" "$def_idx" \
        "awww       (Consigliato: demone Wayland moderno in Rust, transizioni fluide)" \
        "swww       (Supporto completo ad animazioni, fps configurabili)" \
        "hyprpaper  (Utility ufficiale ultra-leggera del progetto Hyprland)" \
        "mpvpaper   (Supporto per video, GIF e sfondi animati interattivi)" \
        "swaybg     (Estremamente minimale e leggero, statico)" \
        "wpaperd    (Demone moderno con gestione multi-monitor)"

    case "${TUI_RESULT:-0}" in
        0) TARGET_BACKEND="awww" ;;
        1) TARGET_BACKEND="swww" ;;
        2) TARGET_BACKEND="hyprpaper" ;;
        3) TARGET_BACKEND="mpvpaper" ;;
        4) TARGET_BACKEND="swaybg" ;;
        5) TARGET_BACKEND="wpaperd" ;;
        *) TARGET_BACKEND="awww" ;;
    esac
fi

# Controlla se il binario è presente nel sistema
BIN_NAME="${TARGET_BACKEND}"
[ "${TARGET_BACKEND}" = "wpaperd" ] && BIN_NAME="wpaperctl"

if ! command -v "${BIN_NAME}" >/dev/null 2>&1 && ! command -v "${TARGET_BACKEND}-daemon" >/dev/null 2>&1; then
    echo -e "\n${STY_YELLOW}⚠️  Il binario '${TARGET_BACKEND}' non risulta installato nel PATH.${STY_RST}"
    
    AUR_HELPER=""
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    fi

    if tui_confirm "Vuoi tentare l'installazione automatica di '${TARGET_BACKEND}'?" true; then
        if [ -n "${AUR_HELPER}" ]; then
            echo -e "${STY_BLUE}==>${STY_RST} Installazione tramite ${AUR_HELPER}..."
            "${AUR_HELPER}" -S --needed --noconfirm "${TARGET_BACKEND}" || "${AUR_HELPER}" -S --needed --noconfirm "${TARGET_BACKEND}-bin" || true
        elif command -v pacman >/dev/null 2>&1; then
            echo -e "${STY_BLUE}==>${STY_RST} Installazione tramite sudo pacman..."
            sudo pacman -S --needed --noconfirm "${TARGET_BACKEND}" || true
        fi
    fi
fi

# Salva configurazione
echo "${TARGET_BACKEND}" > "${BACKEND_FILE}"
echo -e "\n${STY_GREEN}✓ Wallpaper backend impostato su: ${STY_BOLD}${TARGET_BACKEND}${STY_RST}"

# Assicura la presenza degli script in ~/.scripts/
mkdir -p "$HOME/.scripts"
SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_SOURCE_DIR}/apply-wallpaper.sh" ]; then
    cp -f "${SCRIPT_SOURCE_DIR}/apply-wallpaper.sh" "$HOME/.scripts/apply-wallpaper.sh"
    chmod +x "$HOME/.scripts/apply-wallpaper.sh"
fi
if [ -f "${SCRIPT_SOURCE_DIR}/init_wallpaper.sh" ]; then
    cp -f "${SCRIPT_SOURCE_DIR}/init_wallpaper.sh" "$HOME/.scripts/init_wallpaper.sh"
    chmod +x "$HOME/.scripts/init_wallpaper.sh"
fi
