#!/usr/bin/env bash
# ==============================================================================
#  🏝️ Dynamic Island Hyprland — Installer & Setup Engine
#  Inspired by the modular architecture of Logical Impulse (dots-hyprland)
# ==============================================================================
# Subcommands:
#   install        (Predefinito) Installazione completa end-to-end
#   deps           Installa solo le dipendenze di sistema e da AUR
#   build          Compila e installa solo il backend C++ e lyricsmpris
#   lang           Configura o cambia la lingua dell'interfaccia
#   biometrics     Configura l'autenticazione biometrica (Face ID / Impronta)
#   wallpaper      Configura il motore sfondi e la sincronizzazione temi
#   autostart      Inietta l'avvio automatico e le regole di privacy in Hyprland
#   uninstall      Disinstalla la shell e rimuove i binari installati
# ==============================================================================

set -eo pipefail

# ── 1. Colori e Stili ANSI (Stile Logical Impulse) ───────────────────────────
STY_BOLD='\033[1m'
STY_FAINT='\033[2m'
STY_UNDERLINE='\033[4m'
STY_RED='\033[31m'
STY_GREEN='\033[32m'
STY_YELLOW='\033[33m'
STY_BLUE='\033[34m'
STY_PURPLE='\033[35m'
STY_CYAN='\033[36m'
STY_RST='\033[0m'

# ── 2. Variabili Globali e Directory ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/dynamic-island"
BUILD_LOG="/tmp/dynamic-island-install.log"
PREFIX="${HOME}/.local"
INTERACTIVE=true
VERBOSE=false
LANGUAGE_CHOICE=""
BIOMETRICS_CHOICE=""
WALLPAPER_BACKEND="awww"
SUDO_KEEPALIVE_PID=""

# ── 3. Supporto One-Liner (curl -sSL ... | bash o bash <(curl ...)) ──────────
# Se lo script viene eseguito fuori dalla repository clonata, clona automaticamente
# in ~/.config/quickshell/dynamic-island ed esegue il setup collegandosi a /dev/tty
bootstrap_if_not_cloned() {
    if [ ! -f "${SCRIPT_DIR}/CMakeLists.txt" ] || [ ! -d "${SCRIPT_DIR}/backend" ]; then
        echo -e "${STY_CYAN}==> Rilevata esecuzione autonoma (One-Liner). Bootstrap in corso...${STY_RST}"
        
        if ! command -v git >/dev/null 2>&1; then
            echo -e "${STY_YELLOW}git non trovato, installazione provvisoria necessaria...${STY_RST}"
            sudo pacman -S --needed --noconfirm git
        fi

        if [ -d "${TARGET_DIR}/.git" ]; then
            echo -e "${STY_BLUE}==>${STY_RST} Aggiornamento repository esistente in ${TARGET_DIR}..."
            git -C "${TARGET_DIR}" pull --ff-only || true
        else
            echo -e "${STY_BLUE}==>${STY_RST} Clonazione repository Dynamic Island in ${TARGET_DIR}..."
            mkdir -p "$(dirname "${TARGET_DIR}")"
            git clone https://github.com/St0rmosu/dynamic-island-hyprland.git "${TARGET_DIR}"
        fi

        cd "${TARGET_DIR}"
        # Riapre lo stdin su /dev/tty per garantire l'interattività dei prompt
        if [ -t 0 ]; then
            exec bash "${TARGET_DIR}/install.sh" "$@"
        else
            exec bash "${TARGET_DIR}/install.sh" "$@" </dev/tty
        fi
    fi
}

bootstrap_if_not_cloned "$@"

# ── 4. Controllo Root & Privilegi (prevent_sudo_or_root) ───────────────────────
prevent_sudo_or_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "${STY_RED}❌ ERRORE: Non eseguire questo script con sudo o come utente root.${STY_RST}"
        echo -e "${STY_YELLOW}Eseguilo come utente normale:${STY_RST} ./install.sh"
        echo -e "I privilegi sudo verranno richiesti automaticamente solo quando necessario.\n"
        exit 1
    fi
}

# ── 5. Gestione Sudo Keepalive (come in Logical Impulse) ───────────────────────
sudo_init_keepalive() {
    if ! command -v sudo >/dev/null 2>&1; then
        return 0
    fi
    if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        return 0
    fi
    echo -e "${STY_CYAN}[sudo]: Richiesta autorizzazione per operazioni di sistema...${STY_RST}"
    if ! sudo -v; then
        echo -e "${STY_RED}❌ Impossibile ottenere i permessi sudo. Annullamento.${STY_RST}"
        exit 1
    fi
    (
        while true; do
            sleep 50
            sudo -n true 2>/dev/null || exit 0
        done
    ) &
    SUDO_KEEPALIVE_PID=$!
}

sudo_stop_keepalive() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        unset SUDO_KEEPALIVE_PID
    fi
}

trap sudo_stop_keepalive EXIT INT TERM

# ── 6. Esecutore Silenzioso con Spinner Elegante (Compilazione Pulita) ─────────
# Reindirizza il flusso verboso su /tmp/dynamic-island-install.log e mostra uno spinner
run_quiet() {
    local title="$1"
    shift

    if [ "${VERBOSE}" = true ]; then
        echo -e "${STY_BLUE}==>${STY_RST} ${title}..."
        "$@"
        return $?
    fi

    local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local pid

    # Esegui in background scrivendo su log
    "$@" >> "${BUILD_LOG}" 2>&1 &
    pid=$!

    local i=0
    while kill -0 "${pid}" 2>/dev/null; do
        printf "\r  ${STY_CYAN}%s${STY_RST} %s..." "${spin[i]}" "${title}"
        i=$(( (i + 1) % ${#spin[@]} ))
        sleep 0.08
    done

    wait "${pid}"
    local exit_code=$?

    if [ ${exit_code} -eq 0 ]; then
        printf "\r  ${STY_GREEN}✓${STY_RST} %s                            \n" "${title}"
        return 0
    else
        printf "\r  ${STY_RED}✗${STY_RST} %s (fallito!)                  \n" "${title}"
        echo -e "\n${STY_RED}❌ Si è verificato un errore durante: $*${STY_RST}"
        echo -e "${STY_YELLOW}Ultime righe del log (${BUILD_LOG}):${STY_RST}"
        echo "------------------------------------------------------------"
        tail -n 30 "${BUILD_LOG}" 2>/dev/null || true
        echo "------------------------------------------------------------"
        echo -e "Puoi consultare il log completo in: ${STY_UNDERLINE}${BUILD_LOG}${STY_RST}\n"
        return ${exit_code}
    fi
}

# ── 7. Banner Introduttivo ───────────────────────────────────────────────────
print_banner() {
    clear 2>/dev/null || true
    echo -e "${STY_CYAN}╔════════════════════════════════════════════════════════════════╗${STY_RST}"
    echo -e "${STY_CYAN}║     🏝️  Dynamic Island Hyprland — Installer & Setup            ║${STY_RST}"
    echo -e "${STY_CYAN}║         Fluid iOS-style Dynamic Pill & Control Center          ║${STY_RST}"
    echo -e "${STY_CYAN}╚════════════════════════════════════════════════════════════════╝${STY_RST}"
    echo -e "  ${STY_FAINT}Prefisso di installazione:${STY_RST} ${PREFIX}"
    echo -e "  ${STY_FAINT}Directory di lavoro:${STY_RST}       ${SCRIPT_DIR}"
    echo -e "  ${STY_FAINT}Log di compilazione:${STY_RST}       ${BUILD_LOG}"
    echo ""
}

# ── 8. Rilevatore / Installatore AUR Helper ───────────────────────────────────
detect_aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        echo "yay"
    elif command -v paru >/dev/null 2>&1; then
        echo "paru"
    else
        echo ""
    fi
}

ensure_aur_helper() {
    local helper
    helper=$(detect_aur_helper)
    if [ -n "${helper}" ]; then
        return 0
    fi

    echo -e "${STY_YELLOW}⚠️  Nessun gestore AUR (yay o paru) rilevato sul sistema.${STY_RST}"
    local DO_INSTALL=true
    if [ "${INTERACTIVE}" = true ]; then
        read -r -p "Vuoi che installi 'yay' automaticamente da AUR? [Y/n] " confirm
        [[ "${confirm,,}" =~ ^[Nn] ]] && DO_INSTALL=false
    fi

    if [ "${DO_INSTALL}" = true ]; then
        echo -e "${STY_BLUE}==>${STY_RST} Installazione automatica di yay-bin..."
        sudo pacman -S --needed --noconfirm base-devel git
        local TMP_YAY="/tmp/yay-bin-install"
        rm -rf "${TMP_YAY}"
        git clone https://aur.archlinux.org/yay-bin.git "${TMP_YAY}"
        (cd "${TMP_YAY}" && makepkg -si --noconfirm)
        rm -rf "${TMP_YAY}"
        echo -e "${STY_GREEN}✓ yay installato con successo!${STY_RST}\n"
    fi
}

# ── 9. Subcomando: DEPS (Dipendenze di Sistema e AUR) ─────────────────────────
cmd_deps() {
    echo -e "${STY_BOLD}${STY_CYAN}==> [1/6] Verifica e Installazione Dipendenze${STY_RST}"

    if ! command -v pacman >/dev/null 2>&1; then
        echo -e "${STY_YELLOW}Avviso: pacman non rilevato. Lo script è ottimizzato per Arch Linux.${STY_RST}"
        return 0
    fi

    local PACMAN_DEPS=(
        "cmake"
        "ninja"
        "qt6-base"
        "qt6-declarative"
        "jq"
        "socat"
        "libnotify"
        "brightnessctl"
        "playerctl"
        "wireplumber"
        "slurp"
        "grim"
        "bluez"
        "bluez-utils"
        "systemd"
    )

    local MISSING_PACMAN=()
    for pkg in "${PACMAN_DEPS[@]}"; do
        if ! pacman -Qi "${pkg}" >/dev/null 2>&1; then
            MISSING_PACMAN+=("${pkg}")
        fi
    done

    local NEED_QUICKSHELL=false
    if ! command -v quickshell >/dev/null 2>&1; then
        NEED_QUICKSHELL=true
    fi

    local NEED_AWWW=false
    if ! command -v awww >/dev/null 2>&1 && ! command -v swww >/dev/null 2>&1; then
        NEED_AWWW=true
    fi

    local TOTAL_MISSING=$(( ${#MISSING_PACMAN[@]} + (NEED_QUICKSHELL ? 1 : 0) + (NEED_AWWW ? 1 : 0) ))

    if [ "${TOTAL_MISSING}" -eq 0 ]; then
        echo -e "  ${STY_GREEN}✓${STY_RST} Tutte le dipendenze di base risultano già installate!"
        return 0
    fi

    echo -e "Dipendenze da installare trovate:"
    [ ${#MISSING_PACMAN[@]} -gt 0 ] && echo -e "  • ${STY_BOLD}Arch Ufficiali (pacman):${STY_RST} ${MISSING_PACMAN[*]}"
    [ "${NEED_QUICKSHELL}" = true ] && echo -e "  • ${STY_BOLD}AUR:${STY_RST} quickshell (o quickshell-git)"
    [ "${NEED_AWWW}" = true ]       && echo -e "  • ${STY_BOLD}AUR:${STY_RST} awww (motore sfondi consigliato)"
    echo ""

    local PROCEED=true
    if [ "${INTERACTIVE}" = true ]; then
        read -r -p "Procedere con l'installazione dei pacchetti mancanti? [Y/n] " ans
        [[ "${ans,,}" =~ ^[Nn] ]] && PROCEED=false
    fi

    if [ "${PROCEED}" = true ]; then
        sudo_init_keepalive
        ensure_aur_helper
        local HELPER
        HELPER=$(detect_aur_helper)

        if [ ${#MISSING_PACMAN[@]} -gt 0 ]; then
            echo -e "${STY_BLUE}==>${STY_RST} Installazione pacchetti pacman..."
            sudo pacman -S --needed --noconfirm "${MISSING_PACMAN[@]}"
        fi

        if [ "${NEED_QUICKSHELL}" = true ]; then
            echo -e "${STY_BLUE}==>${STY_RST} Installazione quickshell da AUR..."
            if [ -n "${HELPER}" ]; then
                "${HELPER}" -S --needed --noconfirm quickshell-git || "${HELPER}" -S --needed --noconfirm quickshell
            else
                echo -e "${STY_RED}Impossibile installare quickshell: nessun AUR helper disponibile.${STY_RST}"
            fi
        fi

        if [ "${NEED_AWWW}" = true ]; then
            echo -e "${STY_BLUE}==>${STY_RST} Installazione awww da AUR..."
            if [ -n "${HELPER}" ]; then
                "${HELPER}" -S --needed --noconfirm awww-bin || "${HELPER}" -S --needed --noconfirm awww || true
            fi
        fi
        echo -e "  ${STY_GREEN}✓${STY_RST} Dipendenze installate con successo!\n"
    fi
}

# ── 10. Subcomando: BUILD (Compilazione Silenziosa C++ & lyricsmpris) ──────────
cmd_build() {
    echo -e "${STY_BOLD}${STY_CYAN}==> [2/6] Compilazione Backend Nativo C++20 & Moduli Qt6${STY_RST}"
    echo -e "  ${STY_FAINT}(I log completi del compilatore sono reindirizzati in ${BUILD_LOG})${STY_RST}"

    local BUILD_DIR="${SCRIPT_DIR}/build"
    mkdir -p "${BUILD_DIR}"
    : > "${BUILD_LOG}"

    # 1. Configurazione CMake
    run_quiet "Configurazione progetto con CMake" \
        cmake -B "${BUILD_DIR}" \
              -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
              "${SCRIPT_DIR}"

    # 2. Compilazione Ninja / Make
    local CORES
    CORES=$(nproc 2>/dev/null || echo 4)
    run_quiet "Compilazione parallela C++ (${CORES} core) [IslandBackend & lyricsmpris]" \
        cmake --build "${BUILD_DIR}" -j"${CORES}"

    # 3. Installazione binari e plugin QML
    if [ "${PREFIX}" = "/usr" ] && [ "$(id -u)" -ne 0 ]; then
        sudo_init_keepalive
        run_quiet "Installazione moduli in ${PREFIX} (sudo)" \
            sudo cmake --install "${BUILD_DIR}"
    else
        run_quiet "Installazione moduli in ${PREFIX}" \
            cmake --install "${BUILD_DIR}"
    fi

    # 4. Installazione launcher dynamic-island
    mkdir -p "${PREFIX}/bin"
    if [ -f "${SCRIPT_DIR}/scripts/dynamic-island" ]; then
        cp -f "${SCRIPT_DIR}/scripts/dynamic-island" "${PREFIX}/bin/dynamic-island"
        chmod +x "${PREFIX}/bin/dynamic-island"
        echo -e "  ${STY_GREEN}✓${STY_RST} Launcher installato in: ${PREFIX}/bin/dynamic-island"
    fi
    echo ""
}

# ── 11. Subcomando: DEPLOY (Copia File Runtime Quickshell) ─────────────────────
cmd_deploy() {
    echo -e "${STY_BOLD}${STY_CYAN}==> [3/6] Sincronizzazione File Runtime Quickshell${STY_RST}"
    mkdir -p "${TARGET_DIR}"

    if [ "${SCRIPT_DIR}" != "${TARGET_DIR}" ]; then
        echo -e "  Sincronizzazione QML e asset in ${TARGET_DIR}..."
        cp -rf "${SCRIPT_DIR}/shell.qml" "${TARGET_DIR}/"
        cp -rf "${SCRIPT_DIR}/DynamicIslandWindow.qml" "${TARGET_DIR}/"
        cp -rf "${SCRIPT_DIR}/qml" "${TARGET_DIR}/"
        [ -d "${SCRIPT_DIR}/scripts" ] && cp -rf "${SCRIPT_DIR}/scripts" "${TARGET_DIR}/"
        [ -d "${SCRIPT_DIR}/assets" ] && cp -rf "${SCRIPT_DIR}/assets" "${TARGET_DIR}/"
        [ -d "${SCRIPT_DIR}/avatars" ] && cp -rf "${SCRIPT_DIR}/avatars" "${TARGET_DIR}/"
        echo -e "  ${STY_GREEN}✓${STY_RST} File sincronizzati con successo!"
    else
        echo -e "  ${STY_GREEN}✓${STY_RST} Esecuzione già all'interno di ${TARGET_DIR}."
    fi

    # Assicura la presenza della cartella configurazioni utente
    mkdir -p "$HOME/.config/dynamic-island"
    local USER_CFG="$HOME/.config/dynamic-island/userconfig.json"
    if [ ! -f "${USER_CFG}" ]; then
        echo '{"dynamicIslandPrimaryAction":"toggleControlCenter"}' > "${USER_CFG}"
    fi
    echo ""
}

# ── 12. Subcomando: LANG (Configurazione Lingua) ──────────────────────────────
cmd_lang() {
    echo -e "${STY_BOLD}${STY_CYAN}==> [4/6] Configurazione Lingua dell'Interfaccia${STY_RST}"
    local LANG_SCRIPT="${SCRIPT_DIR}/scripts/set-language.sh"
    [ ! -f "${LANG_SCRIPT}" ] && LANG_SCRIPT="${TARGET_DIR}/scripts/set-language.sh"

    if [ -f "${LANG_SCRIPT}" ]; then
        chmod +x "${LANG_SCRIPT}"
        if [ -n "${LANGUAGE_CHOICE}" ]; then
            "${LANG_SCRIPT}" --lang "${LANGUAGE_CHOICE}"
        elif [ "${INTERACTIVE}" = true ]; then
            "${LANG_SCRIPT}"
        fi
    else
        echo -e "${STY_YELLOW}Avviso: scripts/set-language.sh non trovato.${STY_RST}"
    fi
    echo ""
}

# ── 13. Subcomando: BIOMETRICS (Impronta e Windows Hello Face ID) ─────────────
cmd_biometrics() {
    echo -e "${STY_BOLD}${STY_CYAN}==> [5/6] Configurazione Biometrica (Impronta / Face ID)${STY_RST}"

    local HAS_FP=false
    local HAS_FACE=false
    local HELPER
    HELPER=$(detect_aur_helper)

    if [ -n "${BIOMETRICS_CHOICE}" ]; then
        case "${BIOMETRICS_CHOICE,,}" in
            fingerprint|fp) HAS_FP=true ;;
            face|faceid)    HAS_FACE=true ;;
            both|all)       HAS_FP=true; HAS_FACE=true ;;
            none|no)        HAS_FP=false; HAS_FACE=false ;;
        esac
    elif [ "${INTERACTIVE}" = true ]; then
        echo "Seleziona i metodi biometrici da abilitare su Dynamic Island:"
        echo "  1) Solo Lettore di Impronte Digitali (fprintd)"
        echo "  2) Solo Windows Hello Face ID (Telecamera IR / Howdy)"
        echo "  3) Entrambi (Impronta + Face ID con selettore dinamico)"
        echo "  4) Nessuno (Usa solo la password tradizionale)"
        echo ""
        read -r -p "Scelta [1-4, default: 4]: " BIO_INPUT
        case "${BIO_INPUT}" in
            1) HAS_FP=true ;;
            2) HAS_FACE=true ;;
            3) HAS_FP=true; HAS_FACE=true ;;
            *) HAS_FP=false; HAS_FACE=false ;;
        esac
    fi

    # Configurazione Fingerprint
    if [ "${HAS_FP}" = true ]; then
        if ! command -v fprintd-verify >/dev/null 2>&1; then
            echo -e "${STY_BLUE}==>${STY_RST} Installazione fprintd..."
            sudo pacman -S --needed --noconfirm fprintd || true
        fi
        echo -e "  ${STY_GREEN}✓${STY_RST} Lettore d'impronte abilitato."
    fi

    # Configurazione Face ID
    if [ "${HAS_FACE}" = true ]; then
        if ! command -v howdy >/dev/null 2>&1; then
            echo -e "${STY_BLUE}==>${STY_RST} Installazione howdy da AUR..."
            if [ -n "${HELPER}" ]; then
                "${HELPER}" -S --needed --noconfirm howdy || true
            fi
        fi
        if [ -n "${HELPER}" ] && ! command -v linux-enable-ir-emitter >/dev/null 2>&1; then
            echo -e "${STY_BLUE}==>${STY_RST} Installazione emettitore IR (linux-enable-ir-emitter)..."
            "${HELPER}" -S --needed --noconfirm linux-enable-ir-emitter || true
        fi
        echo -e "  ${STY_GREEN}✓${STY_RST} Windows Hello Face ID abilitato."
    fi

    # Salvataggio nel file di configurazione
    local USER_CFG="$HOME/.config/dynamic-island/userconfig.json"
    if [ -f "${USER_CFG}" ]; then
        if command -v jq >/dev/null 2>&1; then
            jq --argjson fp "${HAS_FP}" --argjson face "${HAS_FACE}" '.hasFingerprintReader = $fp | .hasFaceUnlock = $face' "${USER_CFG}" > "${USER_CFG}.tmp" && mv "${USER_CFG}.tmp" "${USER_CFG}"
        fi
    fi
    echo ""
}

# ── 14. Subcomando: WALLPAPER (Motore Sfondi & Sincronizzazione Temi) ─────────
cmd_wallpaper() {
    echo -e "${STY_BOLD}${STY_CYAN}==> [6/6] Configurazione Wallpaper Engine & Temi${STY_RST}"

    local WP_BACKEND_SCRIPT="${SCRIPT_DIR}/scripts/set-wallpaper-backend.sh"
    [ ! -f "${WP_BACKEND_SCRIPT}" ] && WP_BACKEND_SCRIPT="${TARGET_DIR}/scripts/set-wallpaper-backend.sh"

    if [ -f "${WP_BACKEND_SCRIPT}" ]; then
        chmod +x "${WP_BACKEND_SCRIPT}"
        if [ -n "${WALLPAPER_BACKEND}" ]; then
            "${WP_BACKEND_SCRIPT}" --backend "${WALLPAPER_BACKEND}"
        elif [ "${INTERACTIVE}" = true ]; then
            "${WP_BACKEND_SCRIPT}"
        fi
    fi

    # Assicura che gli script vengano installati in ~/.scripts/
    mkdir -p "$HOME/.scripts"
    for s in apply-wallpaper.sh init_wallpaper.sh island-share-picker.sh; do
        local src="${SCRIPT_DIR}/scripts/${s}"
        [ ! -f "${src}" ] && src="${TARGET_DIR}/scripts/${s}"
        if [ -f "${src}" ]; then
            cp -f "${src}" "$HOME/.scripts/${s}"
            chmod +x "$HOME/.scripts/${s}"
            echo -e "  ${STY_GREEN}✓${STY_RST} Script $s deployato in ~/.scripts/"
        fi
    done
    echo ""
}

# ── 15. Subcomando: AUTOSTART (Integrazione Hyprland e Layer Rules) ───────────
cmd_autostart() {
    echo -e "${STY_BOLD}${STY_CYAN}==> Integrazione Hyprland (Autostart & Screencopy Privacy)${STY_RST}"
    local HYPR_DIR="$HOME/.config/hypr"

    if [ ! -d "${HYPR_DIR}" ]; then
        echo -e "  ${STY_YELLOW}Cartella Hyprland non trovata in ${HYPR_DIR}. Salto iniezione autostart.${STY_RST}"
        return 0
    fi

    local AUTOSTART_CMD="$HOME/.local/bin/dynamic-island -d"
    [ "${PREFIX}" = "/usr" ] && AUTOSTART_CMD="dynamic-island -d"

    # Caso A: Configurazione Hyprland in Lua (hyprland.lua)
    if [ -f "${HYPR_DIR}/hyprland.lua" ]; then
        echo -e "  Rilevata configurazione Lua (${HYPR_DIR}/hyprland.lua)"

        local MOD_DIR=""
        [ -d "${HYPR_DIR}/moduli" ] && MOD_DIR="${HYPR_DIR}/moduli"
        [ -d "${HYPR_DIR}/modules" ] && MOD_DIR="${HYPR_DIR}/modules"

        if [ -n "${MOD_DIR}" ]; then
            local TARGET_LUA=""
            for candidate in "autostart.lua" "misc.lua" "startup.lua" "exec.lua"; do
                if [ -f "${MOD_DIR}/${candidate}" ]; then
                    TARGET_LUA="${MOD_DIR}/${candidate}"
                    break
                fi
            done

            if [ -n "${TARGET_LUA}" ]; then
                if grep -Eq "dynamic-island" "${TARGET_LUA}"; then
                    echo -e "  ${STY_GREEN}✓${STY_RST} Dynamic Island già configurato in ${TARGET_LUA}"
                else
                    echo "" >> "${TARGET_LUA}"
                    echo "-- Autostart Dynamic Island" >> "${TARGET_LUA}"
                    echo 'hl.on("hyprland.start", function()' >> "${TARGET_LUA}"
                    echo '    hl.exec_cmd("'"${AUTOSTART_CMD}"'")' >> "${TARGET_LUA}"
                    echo 'end)' >> "${TARGET_LUA}"
                    echo -e "  ${STY_GREEN}✓${STY_RST} Aggiunto autostart a ${TARGET_LUA}"
                fi
            fi

            # Inietta no_screen_share layerrule per privacy streaming
            if [ -f "${MOD_DIR}/rules.lua" ] && ! grep -q "dynamic-island-no-screen-share" "${MOD_DIR}/rules.lua"; then
                cat << 'EOF' >> "${MOD_DIR}/rules.lua"

-- dynamic-island: escludi dalla condivisione schermo (privacy durante streaming)
hl.layer_rule({
	name = "dynamic-island-no-screen-share",
	match = { namespace = "dynamic-island" },
	no_screen_share = true,
})
hl.layer_rule({
	name = "quickshell-no-screen-share",
	match = { namespace = "quickshell" },
	no_screen_share = true,
})
EOF
                echo -e "  ${STY_GREEN}✓${STY_RST} Aggiunte layerrule di privacy a ${MOD_DIR}/rules.lua"
            fi
        else
            # Configurazione non modulare Lua
            if ! grep -q "dynamic-island" "${HYPR_DIR}/hyprland.lua"; then
                cat << EOF >> "${HYPR_DIR}/hyprland.lua"

-- Dynamic Island Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("${AUTOSTART_CMD}")
end)
EOF
                echo -e "  ${STY_GREEN}✓${STY_RST} Aggiunto autostart a hyprland.lua"
            fi
        fi

    # Caso B: Configurazione standard Hyprland (hyprland.conf)
    elif [ -f "${HYPR_DIR}/hyprland.conf" ]; then
        echo -e "  Rilevata configurazione standard (${HYPR_DIR}/hyprland.conf)"

        if [ -d "${HYPR_DIR}/conf.d" ]; then
            local CONF_D_FILE="${HYPR_DIR}/conf.d/dynamic-island.conf"
            cat << EOF > "${CONF_D_FILE}"
# Dynamic Island Hyprland configuration
exec-once = ${AUTOSTART_CMD}
layerrule = no_screen_share, dynamic-island
layerrule = no_screen_share, quickshell
EOF
            if ! grep -Eq "conf\.d/\*|conf\.d/dynamic-island\.conf" "${HYPR_DIR}/hyprland.conf"; then
                echo "source = ${CONF_D_FILE}" >> "${HYPR_DIR}/hyprland.conf"
            fi
            echo -e "  ${STY_GREEN}✓${STY_RST} Creato e collegato ${CONF_D_FILE}"
        elif ! grep -q "dynamic-island" "${HYPR_DIR}/hyprland.conf"; then
            cat << EOF >> "${HYPR_DIR}/hyprland.conf"

# Autostart Dynamic Island & Privacy Masking
exec-once = ${AUTOSTART_CMD}
layerrule = no_screen_share, dynamic-island
layerrule = no_screen_share, quickshell
EOF
            echo -e "  ${STY_GREEN}✓${STY_RST} Autostart e regole privacy aggiunti a hyprland.conf"
        fi
    fi

    # Configura xdg-desktop-portal-hyprland con island-share-picker se disponibile
    if [ -f "$HOME/.scripts/island-share-picker.sh" ]; then
        if [ ! -f "${HYPR_DIR}/xdph.conf" ] || ! grep -q "custom_picker_binary" "${HYPR_DIR}/xdph.conf"; then
            cat << EOF > "${HYPR_DIR}/xdph.conf"
# Configuration for xdg-desktop-portal-hyprland (XDPH)
screencopy {
    max_fps = 60
    allow_token_by_default = true
    custom_picker_binary = $HOME/.scripts/island-share-picker.sh
}
EOF
            systemctl --user restart xdg-desktop-portal-hyprland.service 2>/dev/null || true
            echo -e "  ${STY_GREEN}✓${STY_RST} Screen share picker configurato in ${HYPR_DIR}/xdph.conf"
        fi
    fi

    # Ricarica Hyprland se attivo
    if command -v hyprctl >/dev/null 2>&1 && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        hyprctl reload >/dev/null 2>&1 || true
    fi
    echo ""
}

# ── 16. Subcomando: UNINSTALL (Rimozione Pulita) ──────────────────────────────
cmd_uninstall() {
    echo -e "${STY_BOLD}${STY_RED}==> Disinstallazione Dynamic Island${STY_RST}"
    prevent_sudo_or_root

    read -r -p "Sei sicuro di voler disinstallare Dynamic Island? [y/N] " confirm
    [[ ! "${confirm,,}" =~ ^[Yy] ]] && { echo "Disinstallazione annullata."; exit 0; }

    # Arresta istanze attive
    pkill -f "quickshell.*dynamic-island" >/dev/null 2>&1 || true
    pkill -x "lyricsmpris" >/dev/null 2>&1 || true

    # Rimuovi file binari e librerie
    rm -f "${PREFIX}/bin/dynamic-island"
    rm -f "${PREFIX}/bin/lyricsmpris"
    rm -rf "${PREFIX}/lib/qt6/qml/IslandBackend"
    rm -f "${PREFIX}/lib/libIslandBackend.so"
    echo -e "  ${STY_GREEN}✓${STY_RST} Binari e moduli rimossi da ${PREFIX}"

    # Chiedi per file di configurazione
    read -r -p "Vuoi rimuovere anche la configurazione utente (~/.config/dynamic-island)? [y/N] " rm_cfg
    if [[ "${rm_cfg,,}" =~ ^[Yy] ]]; then
        rm -rf "$HOME/.config/dynamic-island"
        echo -e "  ${STY_GREEN}✓${STY_RST} Configurazione rimossa."
    fi

    echo -e "\n${STY_GREEN}🎉 Disinstallazione completata con successo!${STY_RST}"
}

# ── 17. Aggiornamento Rapido (Update Engine) ──────────────────────────────────
cmd_update() {
    print_banner
    echo -e "${STY_BLUE}==>${STY_RST} ${STY_BOLD}Controllo aggiornamenti da GitHub...${STY_RST}"

    # ── Protezione & Backup Automatico delle Impostazioni Utente ───────────────
    local config_dir="$HOME/.config/dynamic-island"
    if [ -d "$config_dir" ]; then
        local backup_dir="$config_dir/backups"
        mkdir -p "$backup_dir"
        local timestamp
        timestamp="$(date +%Y%m%d_%H%M%S)"
        if tar -czf "${backup_dir}/config_backup_${timestamp}.tar.gz" -C "$config_dir" --exclude="backups" . 2>/dev/null; then
            # Mantieni gli ultimi 5 backup di sicurezza
            (ls -t "${backup_dir}"/config_backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f) 2>/dev/null || true
            echo -e "  ${STY_GREEN}✓${STY_RST} ${STY_BOLD}Impostazioni utente al sicuro (backup creato):${STY_RST}"
            echo -e "    ${STY_FAINT}${backup_dir}/config_backup_${timestamp}.tar.gz${STY_RST}\n"
        fi
    fi

    local git_dir=""
    if [ -d "${TARGET_DIR}/.git" ]; then
        git_dir="${TARGET_DIR}"
    elif [ -d "${SCRIPT_DIR}/.git" ]; then
        git_dir="${SCRIPT_DIR}"
    elif [ -d "$HOME/dynamic-island-hyprland/.git" ]; then
        git_dir="$HOME/dynamic-island-hyprland"
    fi

    if [ -z "$git_dir" ]; then
        echo -e "${STY_YELLOW}Nessuna repository Git locale rilevata. Clonazione in ${TARGET_DIR}...${STY_RST}"
        mkdir -p "$(dirname "${TARGET_DIR}")"
        git clone https://github.com/St0rmosu/dynamic-island-hyprland.git "${TARGET_DIR}"
        git_dir="${TARGET_DIR}"
    fi

    cd "$git_dir"
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"
    if [ "$current_branch" = "HEAD" ]; then
        current_branch="main"
    fi

    local current_hash
    current_hash="$(git rev-parse HEAD 2>/dev/null || echo "")"

    echo -e "${STY_CYAN}==>${STY_RST} Recupero ultimi commit da origin/${current_branch}..."
    if ! git fetch origin "$current_branch" 2>&1; then
        echo -e "${STY_RED}❌ Impossibile collegarsi a GitHub. Verifica la connessione Internet.${STY_RST}"
        return 1
    fi

    local remote_hash
    remote_hash="$(git rev-parse "origin/${current_branch}" 2>/dev/null || echo "")"

    if [ "$current_hash" = "$remote_hash" ] && [ -n "$current_hash" ]; then
        echo -e "${STY_GREEN}✨ Sei già all'ultima versione disponibile (${current_branch} @ ${current_hash:0:7})!${STY_RST}"
    else
        local commit_count
        commit_count="$(git rev-list --count "${current_hash}..origin/${current_branch}" 2>/dev/null || echo "0")"
        echo -e "${STY_YELLOW}⚡ Rilevati ${commit_count} nuovi commit disponibili:${STY_RST}"
        git log --oneline --color "${current_hash}..origin/${current_branch}" | head -n 10
        echo ""

        echo -e "${STY_BLUE}==>${STY_RST} Scaricamento e applicazione aggiornamenti..."
        local has_stash=false
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            echo -e "${STY_FAINT}Salvataggio modifiche locali temporanee (stash)...${STY_RST}"
            git stash push -m "Auto-stash before dynamic-island update" >/dev/null 2>&1 || true
            has_stash=true
        fi

        if ! git pull --rebase origin "$current_branch"; then
            echo -e "${STY_RED}❌ Conflitto o errore durante il pull Git. Annullamento rebase...${STY_RST}"
            git rebase --abort 2>/dev/null || true
            [ "$has_stash" = true ] && git stash pop >/dev/null 2>&1 || true
            return 1
        fi

        [ "$has_stash" = true ] && git stash pop >/dev/null 2>&1 || true
        echo -e "${STY_GREEN}✔ Codice sorgente aggiornato!${STY_RST}"

        # Verifica se i file C++ o CMake sono cambiati
        local build_changed=false
        if git diff --name-only "$current_hash" "$remote_hash" 2>/dev/null | grep -qE "^(backend/|lyricsmpris/|CMakeLists\.txt)"; then
            build_changed=true
        fi

        if [ "$build_changed" = true ]; then
            echo -e "${STY_YELLOW}⚙️  Rilevate modifiche al backend C++. Ricompilazione rapida in corso...${STY_RST}"
            cmd_build
            cmd_deploy
        else
            echo -e "${STY_CYAN}⚡ Backend C++ invariato: ricompilazione saltata (aggiornamento istantaneo)!${STY_RST}"
            cmd_deploy
        fi
    fi

    # Rende sempre eseguibili gli script
    chmod +x "${git_dir}/scripts/"* "${git_dir}/install.sh" 2>/dev/null || true

    # Aggiorna launcher in ~/.local/bin
    mkdir -p "${PREFIX}/bin"
    cp -f "${git_dir}/scripts/dynamic-island" "${PREFIX}/bin/dynamic-island"
    chmod +x "${PREFIX}/bin/dynamic-island"

    # Se git_dir != TARGET_DIR, sincronizza in TARGET_DIR
    if [ "${git_dir}" != "${TARGET_DIR}" ]; then
        echo -e "${STY_BLUE}==>${STY_RST} Sincronizzazione file in ${TARGET_DIR}..."
        rsync -a --exclude='.git' --exclude='build' "${git_dir}/" "${TARGET_DIR}/"
    fi

    # Ricarica la shell
    echo -e "${STY_BLUE}==>${STY_RST} Ricaricamento della Dynamic Island in corso..."
    "${PREFIX}/bin/dynamic-island" --reload -d >/dev/null 2>&1 || true

    command -v notify-send >/dev/null 2>&1 && notify-send -a "Dynamic Island" -i "system-software-update" "Dynamic Island" "Shell aggiornata con successo all'ultima versione!" 2>/dev/null || true

    echo -e "\n${STY_GREEN}╔════════════════════════════════════════════════════════════════╗${STY_RST}"
    echo -e "${STY_GREEN}║     🎉 Dynamic Island aggiornata con successo!                 ║${STY_RST}"
    echo -e "${STY_GREEN}╚════════════════════════════════════════════════════════════════╝${STY_RST}\n"
}

# ── 18. Guida / Help Globale ──────────────────────────────────────────────────
show_help() {
    echo -e "${STY_BOLD}${STY_CYAN}Uso:${STY_RST} $0 [SOTTOCAMANDO] [OPZIONI]"
    echo ""
    echo -e "${STY_BOLD}Sottocomandi disponibili:${STY_RST}"
    echo -e "  ${STY_GREEN}install${STY_RST}        (Predefinito) Esegue l'installazione completa end-to-end"
    echo -e "  ${STY_GREEN}update${STY_RST}         Aggiorna la shell da GitHub, ricompila solo se necessario e ricarica"
    echo -e "  ${STY_GREEN}deps${STY_RST}           Verifica e installa solo le dipendenze di sistema e AUR"
    echo -e "  ${STY_GREEN}build${STY_RST}          Compila e installa solo il backend C++ e lyricsmpris"
    echo -e "  ${STY_GREEN}lang${STY_RST}           Configura la lingua dell'interfaccia (it, en, es, de, fr, auto)"
    echo -e "  ${STY_GREEN}biometrics${STY_RST}     Configura autenticazione con impronta digitale o Face ID"
    echo -e "  ${STY_GREEN}wallpaper${STY_RST}      Configura il motore sfondi (awww, swww, hyprpaper, ecc.)"
    echo -e "  ${STY_GREEN}autostart${STY_RST}      Configura autostart e regole privacy in Hyprland"
    echo -e "  ${STY_GREEN}uninstall${STY_RST}      Disinstalla la shell e rimuove i binari da ${PREFIX}"
    echo -e "  ${STY_GREEN}help${STY_RST}           Mostra questa guida"
    echo ""
    echo -e "${STY_BOLD}Opzioni generali:${STY_RST}"
    echo -e "  ${STY_CYAN}-y, --yes${STY_RST}                 Modalità non interattiva (accetta impostazioni predefinite)"
    echo -e "  ${STY_CYAN}-v, --verbose${STY_RST}             Mostra l'output completo del compilatore C++/CMake a schermo"
    echo -e "  ${STY_CYAN}--system${STY_RST}                  Installa a livello di sistema in /usr anziché in ~/.local"
    echo -e "  ${STY_CYAN}--lang <code>${STY_RST}             Imposta codice lingua (en, it, es, de, fr, auto)"
    echo -e "  ${STY_CYAN}--biometrics <mode>${STY_RST}       Imposta biometria (fingerprint, face, both, none)"
    echo -e "  ${STY_CYAN}--wallpaper-backend <app>${STY_RST} Seleziona motore sfondi (awww, swww, hyprpaper...)"
    echo ""
    echo -e "${STY_BOLD}Installazione Rapida (One-Liner):${STY_RST}"
    echo -e "  bash <(curl -sSL https://raw.githubusercontent.com/St0rmosu/dynamic-island-hyprland/main/install.sh)"
}

# ── 19. Routing Argomenti e Dispatcher ───────────────────────────────────────
prevent_sudo_or_root

SUBCOMMAND="install"
case "${1:-}" in
    install|update|deps|build|lang|language|biometrics|wallpaper|autostart|uninstall)
        SUBCOMMAND="$1"
        shift
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
esac

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|--non-interactive)
            INTERACTIVE=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --system)
            PREFIX="/usr"
            shift
            ;;
        --lang|--language)
            LANGUAGE_CHOICE="$2"
            shift 2
            ;;
        --biometrics)
            BIOMETRICS_CHOICE="$2"
            shift 2
            ;;
        --wallpaper-backend)
            WALLPAPER_BACKEND="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${STY_RED}Opzione sconosciuta: $1${STY_RST}"
            show_help
            exit 1
            ;;
    esac
done

# ── 19. Esecuzione del Sottocomando Richiesto ─────────────────────────────────
case "${SUBCOMMAND}" in
    update)
        cmd_update
        ;;
    deps)
        print_banner
        cmd_deps
        ;;
    build)
        print_banner
        cmd_build
        ;;
    lang|language)
        cmd_lang
        ;;
    biometrics)
        cmd_biometrics
        ;;
    wallpaper)
        cmd_wallpaper
        ;;
    autostart)
        cmd_autostart
        ;;
    uninstall)
        cmd_uninstall
        ;;
    install)
        print_banner
        cmd_deps
        cmd_build
        cmd_deploy
        cmd_lang
        cmd_biometrics
        cmd_wallpaper
        cmd_autostart

        echo -e "${STY_CYAN}╔════════════════════════════════════════════════════════════════╗${STY_RST}"
        echo -e "${STY_CYAN}║     🎉 Dynamic Island installata e pronta all'uso!             ║${STY_RST}"
        echo -e "${STY_CYAN}╚════════════════════════════════════════════════════════════════╝${STY_RST}"
        echo -e "  • ${STY_BOLD}Modulo Qt6:${STY_RST}          ${PREFIX}/lib/qt6/qml/IslandBackend"
        echo -e "  • ${STY_BOLD}Daemon testi:${STY_RST}        ${PREFIX}/bin/lyricsmpris"
        echo -e "  • ${STY_BOLD}Launcher:${STY_RST}            ${PREFIX}/bin/dynamic-island"
        echo -e "  • ${STY_BOLD}Configurazione:${STY_RST}      $HOME/.config/dynamic-island/userconfig.json"
        echo -e "  • ${STY_BOLD}Hyprland Autostart:${STY_RST}  Configurato"
        echo -e "  • ${STY_BOLD}Privacy Screenshare:${STY_RST} Regole no_screen_share applicate"
        echo ""
        echo -e "Puoi avviare subito la Dynamic Island lanciando:"
        echo -e "  ${STY_BOLD}${STY_GREEN}dynamic-island -d${STY_RST}"
        echo ""
        ;;
esac
