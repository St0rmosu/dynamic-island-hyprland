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

if [ -z "${TARGET_BACKEND}" ]; then
    echo -e "${STY_CYAN}╔════════════════════════════════════════════════════════════════╗${STY_RST}"
    echo -e "${STY_CYAN}║    🖼️  Dynamic Island — Configurazione Wallpaper Engine        ║${STY_RST}"
    echo -e "${STY_CYAN}╚════════════════════════════════════════════════════════════════╝${STY_RST}"
    echo -e "Backend attuale: ${STY_BOLD}${CURRENT_BACKEND}${STY_RST}\n"
    echo "Seleziona il software desiderato per gestire lo sfondo:"
    echo "  1) awww       (Consigliato: demone Wayland moderno in Rust, transizioni fluide)"
    echo "  2) swww       (Supporto completo ad animazioni, fps configurabili)"
    echo "  3) hyprpaper  (Utility ufficiale ultra-leggera del progetto Hyprland)"
    echo "  4) mpvpaper   (Supporto per video, GIF e sfondi animati interattivi)"
    echo "  5) swaybg     (Estremamente minimale e leggero, statico)"
    echo "  6) wpaperd    (Demone moderno con gestione multi-monitor)"
    echo ""
    read -r -p "Scelta [1-6, default: ${CURRENT_BACKEND}]: " USER_CHOICE

    case "${USER_CHOICE,,}" in
        1|awww) TARGET_BACKEND="awww" ;;
        2|swww) TARGET_BACKEND="swww" ;;
        3|hyprpaper) TARGET_BACKEND="hyprpaper" ;;
        4|mpvpaper) TARGET_BACKEND="mpvpaper" ;;
        5|swaybg) TARGET_BACKEND="swaybg" ;;
        6|wpaperd) TARGET_BACKEND="wpaperd" ;;
        "") TARGET_BACKEND="${CURRENT_BACKEND:-awww}" ;;
        *)
            echo -e "${STY_YELLOW}Scelta non valida, mantenuto il backend attuale: ${CURRENT_BACKEND}${STY_RST}"
            TARGET_BACKEND="${CURRENT_BACKEND:-awww}"
            ;;
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

    read -r -p "Vuoi tentare l'installazione automatica di '${TARGET_BACKEND}'? [Y/n] " DO_INSTALL
    if [[ ! "${DO_INSTALL,,}" =~ ^[Nn] ]]; then
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
