#!/usr/bin/env bash
# ==============================================================================
# Dynamic Island Hyprland — Interface Language Switcher
# ==============================================================================
# Allows changing the Dynamic Island UI language on the fly via CLI or interactive menu.
# Synchronizes ~/.config/dynamic-island/userconfig.json & dynamic_config.json,
# and notifies the running Quickshell instance via IPC for instant updates.
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
USER_CFG="${CONFIG_DIR}/userconfig.json"
DYNAMIC_CFG="${CONFIG_DIR}/dynamic_config.json"
QS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/dynamic-island"

mkdir -p "${CONFIG_DIR}"

CURRENT_LANG="auto"
if [ -f "${USER_CFG}" ] && command -v jq >/dev/null 2>&1; then
    CURRENT_LANG=$(jq -r '.language // "auto"' "${USER_CFG}" 2>/dev/null || echo "auto")
elif [ -f "${DYNAMIC_CFG}" ] && command -v jq >/dev/null 2>&1; then
    CURRENT_LANG=$(jq -r '.language // "auto"' "${DYNAMIC_CFG}" 2>/dev/null || echo "auto")
fi

show_help() {
    echo -e "${STY_BOLD}Dynamic Island — Language Selector${STY_RST}"
    echo "Usage: $0 [OPTIONS] [LANGUAGE_CODE]"
    echo ""
    echo "Options:"
    echo "  -l, --lang, --language <code >   Set language directly without prompt"
    echo "  -h, --help                       Show this help message"
    echo ""
    echo "Supported languages:"
    echo "  en   - English"
    echo "  it   - Italiano"
    echo "  es   - Español"
    echo "  de   - Deutsch"
    echo "  fr   - Français"
    echo "  auto - System default (auto-detect)"
}

TARGET_LANG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--lang|--language)
            TARGET_LANG="$2"
            shift 2
            ;;
        en|it|es|de|fr|auto)
            TARGET_LANG="$1"
            shift
            ;;
        english) TARGET_LANG="en"; shift ;;
        italiano|italian) TARGET_LANG="it"; shift ;;
        espanol|español|spanish) TARGET_LANG="es"; shift ;;
        deutsch|german) TARGET_LANG="de"; shift ;;
        francais|français|french) TARGET_LANG="fr"; shift ;;
        system) TARGET_LANG="auto"; shift ;;
        *)
            echo -e "${STY_RED}Errore: opzione o codice lingua sconosciuto: '$1'${STY_RST}"
            show_help
            exit 1
            ;;
    esac
done

if [ -z "${TARGET_LANG}" ]; then
    echo -e "${STY_CYAN}╔════════════════════════════════════════════════════════════════╗${STY_RST}"
    echo -e "${STY_CYAN}║     🌍 Dynamic Island — Selettore Lingua / Language Selector    ║${STY_RST}"
    echo -e "${STY_CYAN}╚════════════════════════════════════════════════════════════════╝${STY_RST}"
    echo -e "Lingua attualmente attiva: ${STY_BOLD}${CURRENT_LANG}${STY_RST}\n"
    echo "Scegli la lingua per l'interfaccia:"
    echo "  1) English (Default)"
    echo "  2) Italiano"
    echo "  3) Español"
    echo "  4) Deutsch"
    echo "  5) Français"
    echo "  6) System (Auto-detect)"
    echo ""
    read -r -p "Scelta / Selection [1-6, default: ${CURRENT_LANG}]: " USER_CHOICE

    case "${USER_CHOICE,,}" in
        1|en|english) TARGET_LANG="en" ;;
        2|it|italian|italiano) TARGET_LANG="it" ;;
        3|es|spanish|espanol|español) TARGET_LANG="es" ;;
        4|de|german|deutsch) TARGET_LANG="de" ;;
        5|fr|french|francais|français) TARGET_LANG="fr" ;;
        6|auto|system) TARGET_LANG="auto" ;;
        "") TARGET_LANG="${CURRENT_LANG:-en}" ;;
        *)
            echo -e "${STY_YELLOW}Scelta non valida, mantenuta la lingua attuale: ${CURRENT_LANG}${STY_RST}"
            TARGET_LANG="${CURRENT_LANG:-en}"
            ;;
    esac
fi

update_json() {
    local file="$1"
    local lang="$2"
    if [ ! -f "${file}" ]; then
        echo "{\"dynamicIslandPrimaryAction\":\"toggleControlCenter\",\"language\":\"${lang}\"}" > "${file}"
        return
    fi
    if command -v jq >/dev/null 2>&1; then
        jq --arg l "${lang}" '.language = $l' "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c "import json; p='${file}'; f=open(p); d=json.load(f); f.close(); d['language']='${lang}'; f=open(p,'w'); json.dump(d,f,indent=2); f.close()" 2>/dev/null || true
    fi
}

update_json "${USER_CFG}" "${TARGET_LANG}"
[ -f "${DYNAMIC_CFG}" ] && update_json "${DYNAMIC_CFG}" "${TARGET_LANG}"

# Notifica Quickshell tramite IPC se in esecuzione
if command -v quickshell >/dev/null 2>&1 && pgrep -u "$(id -u)" -f "quickshell.*dynamic-island" >/dev/null 2>&1; then
    quickshell ipc --any-display -p "${QS_DIR}" call island setLanguage "${TARGET_LANG}" >/dev/null 2>&1 || true
fi

echo -e "\n${STY_GREEN}✓ Lingua impostata con successo su: ${STY_BOLD}${TARGET_LANG}${STY_RST}"

# Desktop notification (non-blocking)
if command -v notify-send >/dev/null 2>&1; then
    (
        case "${TARGET_LANG}" in
            it) timeout 2 notify-send -a "Dynamic Island" "Lingua Aggiornata" "Interfaccia impostata su: Italiano" >/dev/null 2>&1 || true ;;
            es) timeout 2 notify-send -a "Dynamic Island" "Idioma Actualizado" "Interfaz configurada en: Español" >/dev/null 2>&1 || true ;;
            de) timeout 2 notify-send -a "Dynamic Island" "Sprache Aktualisiert" "Benutzeroberfläche: Deutsch" >/dev/null 2>&1 || true ;;
            fr) timeout 2 notify-send -a "Dynamic Island" "Langue Mise à Jour" "Interface configurée en: Français" >/dev/null 2>&1 || true ;;
            auto) timeout 2 notify-send -a "Dynamic Island" "Language Updated" "Interface language: System Auto" >/dev/null 2>&1 || true ;;
            *) timeout 2 notify-send -a "Dynamic Island" "Language Updated" "Interface language: English" >/dev/null 2>&1 || true ;;
        esac
    ) &
fi
