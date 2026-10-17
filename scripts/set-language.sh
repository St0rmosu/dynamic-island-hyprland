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

if [ -z "${TARGET_LANG}" ]; then
    echo -e "${STY_CYAN}╭────────────────────────────────────────────────────────────────╮${STY_RST}"
    echo -e "${STY_CYAN}│${STY_RST}     ${STY_BOLD}🌍 Dynamic Island — Selettore Lingua / Language Selector${STY_RST}   ${STY_CYAN}│${STY_RST}"
    echo -e "${STY_CYAN}╰────────────────────────────────────────────────────────────────╯${STY_RST}"
    echo -e "  ${STY_FAINT}Lingua attualmente attiva:${STY_RST} ${STY_BOLD}${CURRENT_LANG}${STY_RST}\n"

    DEF_IDX=0
    case "${CURRENT_LANG,,}" in
        it*) DEF_IDX=1 ;;
        es*) DEF_IDX=2 ;;
        de*) DEF_IDX=3 ;;
        fr*) DEF_IDX=4 ;;
        auto*) DEF_IDX=5 ;;
        *) DEF_IDX=0 ;;
    esac

    tui_select "Scegli la lingua per l'interfaccia:" "$DEF_IDX" \
        "English (Default)" \
        "Italiano" \
        "Español" \
        "Deutsch" \
        "Français" \
        "System (Auto-detect)"

    case "${TUI_RESULT:-0}" in
        0) TARGET_LANG="en" ;;
        1) TARGET_LANG="it" ;;
        2) TARGET_LANG="es" ;;
        3) TARGET_LANG="de" ;;
        4) TARGET_LANG="fr" ;;
        5) TARGET_LANG="auto" ;;
        *) TARGET_LANG="en" ;;
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
