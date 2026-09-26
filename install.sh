#!/usr/bin/env bash
# ==============================================================================
# Dynamic Island Hyprland — Installer & Setup Script
# ==============================================================================
# Builds and installs:
#   1. IslandBackend (Qt 6 C++ QML Plugin)
#   2. lyricsmpris (MPRIS synced lyrics helper daemon)
#   3. dynamic-island launcher script
#   4. Quickshell runtime config deployment
#   5. Hyprland autostart & modular config configuration
#   6. Wallpaper script setup with selectable backend (default: awww)
#   7. Screen sharing privacy layer rules (no_screen_share)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PREFIX="$HOME/.local"
INTERACTIVE=true
SETUP_WALLPAPER=true
WALLPAPER_BACKEND="awww"
SETUP_AUTOSTART=true

# Parse CLI options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --system)
            PREFIX="/usr"
            shift
            ;;
        -y|--yes|--non-interactive)
            INTERACTIVE=false
            shift
            ;;
        --wallpaper-backend)
            WALLPAPER_BACKEND="$2"
            shift 2
            ;;
        --no-wallpaper)
            SETUP_WALLPAPER=false
            shift
            ;;
        --no-autostart)
            SETUP_AUTOSTART=false
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./install.sh [--system] [-y|--yes] [--wallpaper-backend <awww|swww|hyprpaper|mpvpaper|swaybg|wpaperd>] [--no-wallpaper] [--no-autostart]"
            exit 1
            ;;
    esac
done

if [ "$(id -u)" -eq 0 ]; then
    PREFIX="/usr"
fi

echo "========================================================"
echo "         🏝️ Dynamic Island Hyprland Installer"
echo "========================================================"
echo "Prefix: ${PREFIX}"
echo "Source: ${SCRIPT_DIR}"
echo ""

# ------------------------------------------------------------------------------
# 0. Check and Install Shell Dependencies
# ------------------------------------------------------------------------------
check_and_install_dependencies() {
    echo "=== [1/7] Checking Shell Dependencies ==="

    local CORE_PKGS=(
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
    )

    local MISSING_PKGS=()
    for pkg in "${CORE_PKGS[@]}"; do
        if ! pacman -Qi "${pkg}" >/dev/null 2>&1; then
            MISSING_PKGS+=("${pkg}")
        fi
    done

    local NEED_QUICKSHELL=false
    if ! command -v quickshell >/dev/null 2>&1; then
        NEED_QUICKSHELL=true
    fi

    local NEED_AWWW=false
    if [ "${SETUP_WALLPAPER}" = true ] && [ "${WALLPAPER_BACKEND}" = "awww" ]; then
        if ! command -v awww >/dev/null 2>&1; then
            NEED_AWWW=true
        fi
    fi

    local TOTAL_MISSING=$(( ${#MISSING_PKGS[@]} + (NEED_QUICKSHELL ? 1 : 0) + (NEED_AWWW ? 1 : 0) ))

    if [ "${TOTAL_MISSING}" -gt 0 ]; then
        echo "Dipendenze necessarie per la shell mancanti:"
        [ ${#MISSING_PKGS[@]} -gt 0 ] && echo " • Da repository ufficiali (pacman): ${MISSING_PKGS[*]}"
        [ "${NEED_QUICKSHELL}" = true ] && echo " • Da AUR: quickshell (o quickshell-git)"
        [ "${NEED_AWWW}" = true ] && echo " • Da AUR / GitHub: awww"

        local DO_INSTALL=true
        if [ "${INTERACTIVE}" = true ]; then
            read -r -p "Vuoi procedere all'installazione automatica dei pacchetti mancanti? [Y/n] " INSTALL_CONFIRM
            if [[ "${INSTALL_CONFIRM}" =~ ^[Nn] ]]; then
                DO_INSTALL=false
            fi
        fi

        if [ "${DO_INSTALL}" = true ]; then
            local AUR_HELPER=""
            if command -v yay >/dev/null 2>&1; then
                AUR_HELPER="yay"
            elif command -v paru >/dev/null 2>&1; then
                AUR_HELPER="paru"
            fi

            if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
                echo "Installazione pacchetti ufficiali in corso..."
                if [ -n "${AUR_HELPER}" ]; then
                    "${AUR_HELPER}" -S --needed --noconfirm "${MISSING_PKGS[@]}"
                else
                    sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}"
                fi
            fi

            if [ -n "${AUR_HELPER}" ]; then
                if [ "${NEED_QUICKSHELL}" = true ]; then
                    echo "Installazione quickshell da AUR..."
                    "${AUR_HELPER}" -S --needed --noconfirm quickshell-git || "${AUR_HELPER}" -S --needed --noconfirm quickshell
                fi
                if [ "${NEED_AWWW}" = true ]; then
                    echo "Installazione awww da AUR..."
                    "${AUR_HELPER}" -S --needed --noconfirm awww-bin || "${AUR_HELPER}" -S --needed --noconfirm awww || true
                fi
            else
                if [ "${NEED_QUICKSHELL}" = true ]; then
                    echo "⚠️  Nessun AUR helper trovato. Installa manualmente 'quickshell' da AUR (es. yay -S quickshell-git)."
                fi
                if [ "${NEED_AWWW}" = true ]; then
                    echo "⚠️  Nessun AUR helper trovato. Installa manualmente 'awww' da AUR o github.com/DarkElixir/awww."
                fi
            fi
        fi
    else
        echo "✓ Tutte le dipendenze essenziali per la shell sono installate e pronte!"
    fi
}

check_and_install_dependencies

# ------------------------------------------------------------------------------
# 1. Build and Install C++ Backend
# ------------------------------------------------------------------------------
echo ""
echo "=== [2/7] Building Dynamic Island Backend ==="
cmake -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    "${SCRIPT_DIR}"

cmake --build "${BUILD_DIR}" -j"$(nproc)"

echo ""
echo "=== [3/7] Installing Dynamic Island Backend to ${PREFIX} ==="
if [ "${PREFIX}" = "/usr" ] && [ "$(id -u)" -ne 0 ]; then
    echo "Administrative privileges required to install to /usr. Running sudo cmake --install..."
    sudo cmake --install "${BUILD_DIR}"
else
    cmake --install "${BUILD_DIR}"
fi

# ------------------------------------------------------------------------------
# 2. Install Launcher Script
# ------------------------------------------------------------------------------
echo ""
echo "=== [4/7] Installing Launcher Script ==="
BIN_DIR="${PREFIX}/bin"
mkdir -p "${BIN_DIR}"

if [ -f "${SCRIPT_DIR}/scripts/dynamic-island" ]; then
    cp -f "${SCRIPT_DIR}/scripts/dynamic-island" "${BIN_DIR}/dynamic-island"
    chmod +x "${BIN_DIR}/dynamic-island"
    echo "Installed launcher to ${BIN_DIR}/dynamic-island"
fi

# Ensure ~/.config/dynamic-island exists
mkdir -p "$HOME/.config/dynamic-island"
if [ ! -f "$HOME/.config/dynamic-island/userconfig.json" ]; then
    echo '{"dynamicIslandPrimaryAction":"toggleControlCenter"}' > "$HOME/.config/dynamic-island/userconfig.json"
fi

# ------------------------------------------------------------------------------
# 3. Deploy Runtime Config to ~/.config/quickshell/dynamic-island
# ------------------------------------------------------------------------------
echo ""
echo "=== [5/7] Deploying Quickshell Runtime Config ==="
QS_RUNTIME_DIR="$HOME/.config/quickshell/dynamic-island"
mkdir -p "${QS_RUNTIME_DIR}"

if [ "${SCRIPT_DIR}" != "${QS_RUNTIME_DIR}" ]; then
    echo "Syncing QML and assets to ${QS_RUNTIME_DIR}..."
    cp -rf "${SCRIPT_DIR}/shell.qml" "${QS_RUNTIME_DIR}/"
    cp -rf "${SCRIPT_DIR}/DynamicIslandWindow.qml" "${QS_RUNTIME_DIR}/"
    cp -rf "${SCRIPT_DIR}/qml" "${QS_RUNTIME_DIR}/"
    [ -d "${SCRIPT_DIR}/assets" ] && cp -rf "${SCRIPT_DIR}/assets" "${QS_RUNTIME_DIR}/"
    [ -d "${SCRIPT_DIR}/avatars" ] && cp -rf "${SCRIPT_DIR}/avatars" "${QS_RUNTIME_DIR}/"
    echo "Runtime files successfully synced."
else
    echo "Already inside runtime directory (${QS_RUNTIME_DIR}), skipping sync."
fi

# ------------------------------------------------------------------------------
# 4. Hyprland Autostart & Modular Config Detection (Requirement 1)
# ------------------------------------------------------------------------------
setup_hyprland_autostart() {
    echo ""
    echo "=== [6/7] Configuring Hyprland Autostart & Modules ==="
    HYPR_DIR="$HOME/.config/hypr"

    if [ ! -d "${HYPR_DIR}" ]; then
        echo "Hyprland directory not found at ${HYPR_DIR}. Skipping autostart injection."
        return
    fi

    local AUTOSTART_CMD="$HOME/.local/bin/dynamic-island -d"
    [ "${PREFIX}" = "/usr" ] && AUTOSTART_CMD="dynamic-island -d"

    # CASE A: Lua-based Hyprland configuration (hyprland.lua)
    if [ -f "${HYPR_DIR}/hyprland.lua" ]; then
        echo "Detected Lua Hyprland configuration (${HYPR_DIR}/hyprland.lua)"

        local MOD_DIR=""
        if [ -d "${HYPR_DIR}/moduli" ]; then
            MOD_DIR="${HYPR_DIR}/moduli"
        elif [ -d "${HYPR_DIR}/modules" ]; then
            MOD_DIR="${HYPR_DIR}/modules"
        fi

        if [ -n "${MOD_DIR}" ]; then
            echo "Detected MODULAR Lua structure at ${MOD_DIR}"

            # Check where autostarts live: misc.lua, autostart.lua, or startup.lua
            local TARGET_LUA=""
            for candidate in "misc.lua" "autostart.lua" "startup.lua" "exec.lua"; do
                if [ -f "${MOD_DIR}/${candidate}" ]; then
                    TARGET_LUA="${MOD_DIR}/${candidate}"
                    break
                fi
            done

            if [ -n "${TARGET_LUA}" ]; then
                echo "Found autostart candidate file: ${TARGET_LUA}"
                if grep -Eq "dynamic-island|apply-qs-bar\.sh" "${TARGET_LUA}"; then
                    echo "Dynamic Island autostart is already configured in ${TARGET_LUA}"
                else
                    echo "Adding Dynamic Island autostart to ${TARGET_LUA}..."
                    if grep -q 'hl\.on("hyprland\.start"' "${TARGET_LUA}"; then
                        sed -i '/hl\.on("hyprland\.start"/a \    hl.exec_cmd("'"${AUTOSTART_CMD}"'")' "${TARGET_LUA}"
                    else
                        echo "" >> "${TARGET_LUA}"
                        echo "-- Autostart Dynamic Island" >> "${TARGET_LUA}"
                        echo 'hl.on("hyprland.start", function()' >> "${TARGET_LUA}"
                        echo '    hl.exec_cmd("'"${AUTOSTART_CMD}"'")' >> "${TARGET_LUA}"
                        echo 'end)' >> "${TARGET_LUA}"
                    fi
                    echo "Configured autostart in ${TARGET_LUA}"
                fi
            else
                # Create a new modular autostart file
                local NEW_MOD="${MOD_DIR}/autostart.lua"
                echo "Creating new modular autostart file: ${NEW_MOD}..."
                cat << 'EOF' > "${NEW_MOD}"
-- Dynamic Island Hyprland autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("$HOME/.local/bin/dynamic-island -d")
end)
EOF
                if ! grep -q 'require(".*autostart")' "${HYPR_DIR}/hyprland.lua"; then
                    local MOD_NAME=$(basename "${MOD_DIR}")
                    echo "require(\"${MOD_NAME}.autostart\")" >> "${HYPR_DIR}/hyprland.lua"
                    echo "Linked ${NEW_MOD} in hyprland.lua"
                fi
            fi

            # Check and configure layer rules for screen share in rules.lua
            if [ -f "${MOD_DIR}/rules.lua" ]; then
                if ! grep -q "dynamic-island-no-screen-share" "${MOD_DIR}/rules.lua"; then
                    echo "Adding no_screen_share layer rule to ${MOD_DIR}/rules.lua..."
                    cat << 'EOF' >> "${MOD_DIR}/rules.lua"

-- quickshell / dynamic-island: escludi dalla condivisione schermo (privacy durante screenshare)
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
                fi
            fi
        else
            # Single non-modular hyprland.lua
            if grep -Eq "dynamic-island|apply-qs-bar\.sh" "${HYPR_DIR}/hyprland.lua"; then
                echo "Dynamic Island autostart is already configured in hyprland.lua"
            else
                echo "Adding Dynamic Island autostart to hyprland.lua..."
                cat << EOF >> "${HYPR_DIR}/hyprland.lua"

-- Dynamic Island Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("${AUTOSTART_CMD}")
end)
EOF
            fi
        fi

    # CASE B: Standard Hyprland configuration (hyprland.conf)
    elif [ -f "${HYPR_DIR}/hyprland.conf" ]; then
        echo "Detected Standard Hyprland configuration (${HYPR_DIR}/hyprland.conf)"

        # Check for modular configs (source = ..., conf.d, modules, etc.)
        local MODULAR_FILE=""
        for candidate in \
            "${HYPR_DIR}/autostart.conf" \
            "${HYPR_DIR}/conf.d/autostart.conf" \
            "${HYPR_DIR}/conf/autostart.conf" \
            "${HYPR_DIR}/configs/autostart.conf" \
            "${HYPR_DIR}/modules/autostart.conf" \
            "${HYPR_DIR}/exec.conf" \
            "${HYPR_DIR}/startup.conf"; do
            if [ -f "${candidate}" ]; then
                MODULAR_FILE="${candidate}"
                break
            fi
        done

        if [ -n "${MODULAR_FILE}" ]; then
            echo "Found modular autostart file: ${MODULAR_FILE}"
            if grep -q "dynamic-island" "${MODULAR_FILE}"; then
                echo "Dynamic Island autostart is already configured in ${MODULAR_FILE}"
            else
                echo "Adding autostart to ${MODULAR_FILE}..."
                echo "" >> "${MODULAR_FILE}"
                echo "# Autostart Dynamic Island" >> "${MODULAR_FILE}"
                echo "exec-once = ${AUTOSTART_CMD}" >> "${MODULAR_FILE}"
            fi
        elif [ -d "${HYPR_DIR}/conf.d" ]; then
            local CONF_D_FILE="${HYPR_DIR}/conf.d/dynamic-island.conf"
            echo "Detected modular directory conf.d/. Writing ${CONF_D_FILE}..."
            cat << EOF > "${CONF_D_FILE}"
# Dynamic Island Hyprland configuration
exec-once = ${AUTOSTART_CMD}
layerrule = no_screen_share, dynamic-island
layerrule = no_screen_share, quickshell
EOF
            if ! grep -Eq "conf\.d/\*|conf\.d/dynamic-island\.conf" "${HYPR_DIR}/hyprland.conf"; then
                echo "source = ${CONF_D_FILE}" >> "${HYPR_DIR}/hyprland.conf"
            fi
        else
            echo "Detected monolithic configuration in hyprland.conf"
            if grep -q "dynamic-island" "${HYPR_DIR}/hyprland.conf"; then
                echo "Dynamic Island autostart is already configured in hyprland.conf"
            else
                echo "Appending autostart to hyprland.conf..."
                cat << EOF >> "${HYPR_DIR}/hyprland.conf"

# Autostart Dynamic Island
exec-once = ${AUTOSTART_CMD}

# Escludi Dynamic Island dalla cattura e condivisione schermo
layerrule = no_screen_share, dynamic-island
layerrule = no_screen_share, quickshell
EOF
            fi
        fi

        # Ensure shortcuts source is present
        if [ -f "$HOME/.config/dynamic-island/hyprland-shortcuts.conf" ]; then
            if ! grep -q "hyprland-shortcuts.conf" "${HYPR_DIR}/hyprland.conf"; then
                echo "source = $HOME/.config/dynamic-island/hyprland-shortcuts.conf" >> "${HYPR_DIR}/hyprland.conf"
            fi
        fi
    fi

    # Configura xdph.conf con custom_picker_binary per eliminare la finestra grezza di hyprland-share-picker
    if [ -f "${SCRIPT_DIR}/scripts/island-share-picker.sh" ]; then
        mkdir -p "$HOME/.scripts"
        cp -f "${SCRIPT_DIR}/scripts/island-share-picker.sh" "$HOME/.scripts/island-share-picker.sh"
        chmod +x "$HOME/.scripts/island-share-picker.sh"

        if [ ! -f "${HYPR_DIR}/xdph.conf" ] || ! grep -q "custom_picker_binary" "${HYPR_DIR}/xdph.conf"; then
            echo "Configurazione custom_picker_binary in ${HYPR_DIR}/xdph.conf..."
            cat << EOF > "${HYPR_DIR}/xdph.conf"
# Configuration for xdg-desktop-portal-hyprland (XDPH)
# Replaces the default hyprland-share-picker dialog with a custom picker

screencopy {
    max_fps = 60
    allow_token_by_default = true
    custom_picker_binary = $HOME/.scripts/island-share-picker.sh
}
EOF
            systemctl --user restart xdg-desktop-portal-hyprland.service 2>/dev/null || true
            echo "xdg-desktop-portal-hyprland configurato con island-share-picker!"
        fi
    fi

    # Check if Hyprland is actively running to reload config
    if command -v hyprctl >/dev/null 2>&1 && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        echo "Reloading Hyprland configuration via hyprctl reload..."
        hyprctl reload >/dev/null 2>&1 || true
    fi
}

if [ "${SETUP_AUTOSTART}" = true ]; then
    setup_hyprland_autostart
fi

# ------------------------------------------------------------------------------
# 5. Wallpaper Script Generation & Selection (Requirement 2)
# ------------------------------------------------------------------------------
setup_wallpaper_script() {
    echo ""
    echo "=== [7/7] Wallpaper Script Setup ==="

    if [ "${INTERACTIVE}" = true ]; then
        echo "Vuoi configurare / creare lo script per la gestione dello sfondo? [Y/n]"
        read -r -p "> " CONFIRM_WP
        if [[ "${CONFIRM_WP}" =~ ^[Nn] ]]; then
            echo "Configurazione script sfondo saltata."
            return
        fi

        echo ""
        echo "Scegli il software per gestire lo sfondo (default: 1 - awww):"
        echo "  1) awww       (consigliato: demone Wayland moderno in Rust, transizioni fluide)"
        echo "  2) swww       (ottimo supporto per animazioni e transizioni)"
        echo "  3) hyprpaper  (utility leggera ufficiale del progetto Hyprland)"
        echo "  4) mpvpaper   (supporto per video e sfondi animati interattivi)"
        echo "  5) swaybg     (estremamente minimale e leggero, senza animazioni)"
        echo "  6) wpaperd    (demone moderno con supporto configurazione TOML per output)"
        read -r -p "Scelta [1-6, default: 1]: " WP_CHOICE

        case "${WP_CHOICE}" in
            2|swww)      WALLPAPER_BACKEND="swww" ;;
            3|hyprpaper) WALLPAPER_BACKEND="hyprpaper" ;;
            4|mpvpaper)  WALLPAPER_BACKEND="mpvpaper" ;;
            5|swaybg)    WALLPAPER_BACKEND="swaybg" ;;
            6|wpaperd)   WALLPAPER_BACKEND="wpaperd" ;;
            *)           WALLPAPER_BACKEND="awww" ;;
        esac
    fi

    echo "Backend sfondo selezionato: ${WALLPAPER_BACKEND}"

    # Verify if selected backend binary exists on system
    if ! command -v "${WALLPAPER_BACKEND}" >/dev/null 2>&1 && ! command -v "${WALLPAPER_BACKEND}-daemon" >/dev/null 2>&1; then
        echo "⚠️  Avviso: '${WALLPAPER_BACKEND}' non risulta installato nel PATH!"
        echo "   Puoi installarlo usando il tuo package manager (es: sudo pacman -S ${WALLPAPER_BACKEND} o yay -S ${WALLPAPER_BACKEND})"
    fi

    SCRIPTS_DIR="$HOME/.scripts"
    mkdir -p "${SCRIPTS_DIR}"

    # Generate apply-wallpaper.sh
    local APPLY_WP_SCRIPT="${SCRIPTS_DIR}/apply-wallpaper.sh"
    if [ -f "${APPLY_WP_SCRIPT}" ]; then
        cp -f "${APPLY_WP_SCRIPT}" "${APPLY_WP_SCRIPT}.bak"
    fi

    echo "Generazione ${APPLY_WP_SCRIPT} con backend ${WALLPAPER_BACKEND}..."
    cat << 'EOF' > "${APPLY_WP_SCRIPT}"
#!/usr/bin/env bash
# ==============================================================================
# Dynamic Island — Wallpaper Applier Script
# ==============================================================================
export PATH="$HOME/.local/bin:$HOME/.spicetify:$PATH"
export LANG=C.UTF-8

FULL_PATH="$1"
if [ -z "$FULL_PATH" ] || [ ! -f "$FULL_PATH" ]; then
    echo "Errore: wallpaper non valido o non trovato: $FULL_PATH" >&2
    exit 1
fi
CHOICE=$(basename "$FULL_PATH" | sed 's/\.[^.]*$//')

notify-send -a "Dynamic Island" "Wallpaper" "Applicato: $CHOICE"

EOF

    # Inject backend-specific application command
    case "${WALLPAPER_BACKEND}" in
        awww)
            cat << 'EOF' >> "${APPLY_WP_SCRIPT}"
awww img "$FULL_PATH" --transition-type any --transition-pos 0.9,0.9 --transition-step 45 --transition-fps 60
EOF
            ;;
        swww)
            cat << 'EOF' >> "${APPLY_WP_SCRIPT}"
swww img "$FULL_PATH" --transition-type any --transition-pos 0.9,0.9 --transition-step 45 --transition-fps 60
EOF
            ;;
        hyprpaper)
            cat << 'EOF' >> "${APPLY_WP_SCRIPT}"
hyprctl hyprpaper preload "$FULL_PATH"
hyprctl hyprpaper wallpaper ",$FULL_PATH"
hyprctl hyprpaper unload all
EOF
            ;;
        mpvpaper)
            cat << 'EOF' >> "${APPLY_WP_SCRIPT}"
pkill -x mpvpaper 2>/dev/null || true
mpvpaper '*' "$FULL_PATH" -o "no-audio loop" &
EOF
            ;;
        swaybg)
            cat << 'EOF' >> "${APPLY_WP_SCRIPT}"
pkill -x swaybg 2>/dev/null || true
swaybg -i "$FULL_PATH" -m fill &
EOF
            ;;
        wpaperd)
            cat << 'EOF' >> "${APPLY_WP_SCRIPT}"
wpaperctl set-wallpaper "$FULL_PATH"
EOF
            ;;
    esac

    # Theming hooks (GTK3, GTK4, Qt5, Qt6, Hyprland, Iris/Pywal)
    cat << 'EOF' >> "${APPLY_WP_SCRIPT}"

# ==============================================================================
# Sincronizzazione Temi & Colori Coerenti: GTK3, GTK4, Qt5, Qt6, Hyprland
# ==============================================================================

# 1. Estrazione Palette Colori
if [ -x "$HOME/.scripts/apply-iris.sh" ]; then
    "$HOME/.scripts/apply-iris.sh" "$FULL_PATH"
elif command -v wal >/dev/null 2>&1; then
    wal -i "$FULL_PATH" -n -q -t
elif command -v matugen >/dev/null 2>&1; then
    matugen image "$FULL_PATH"
fi

# Lettura dei colori estratti
WAL_COLORS="$HOME/.cache/wal/colors.sh"
if [ -f "$WAL_COLORS" ]; then
    source "$WAL_COLORS"
else
    color0="#0e1118"
    color1="#e06c75"
    color2="#98c379"
    color3="#e5c07b"
    color4="#61afef"
    color5="#c678dd"
    color6="#56b6c2"
    color7="#abb2bf"
    color8="#282c34"
    color15="#ffffff"
fi

ACCENT="${color4:-#3584e4}"
BG="${color0:-#0e1118}"
SURFACE="${color8:-#1e222b}"
FG="${color15:-#ffffff}"

# 2. Sincronizzazione GTK-3.0 e GTK-4.0 (Libadwaita / Adwaita / Flatpak)
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cat << 'CSS_EOF' > "$HOME/.config/gtk-3.0/gtk.css"
/* Auto-generated by Dynamic Island Wallpaper Engine */
@define-color accent_color ACCENT_PLACEHOLDER;
@define-color accent_bg_color ACCENT_PLACEHOLDER;
@define-color accent_fg_color #ffffff;
@define-color window_bg_color BG_PLACEHOLDER;
@define-color window_fg_color FG_PLACEHOLDER;
@define-color view_bg_color BG_PLACEHOLDER;
@define-color view_fg_color FG_PLACEHOLDER;
@define-color headerbar_bg_color SURFACE_PLACEHOLDER;
@define-color headerbar_fg_color FG_PLACEHOLDER;
@define-color card_bg_color SURFACE_PLACEHOLDER;
@define-color card_fg_color FG_PLACEHOLDER;
@define-color dialog_bg_color SURFACE_PLACEHOLDER;
@define-color dialog_fg_color FG_PLACEHOLDER;
@define-color popover_bg_color SURFACE_PLACEHOLDER;
@define-color popover_fg_color FG_PLACEHOLDER;
CSS_EOF
sed -i "s|ACCENT_PLACEHOLDER|${ACCENT}|g; s|BG_PLACEHOLDER|${BG}|g; s|SURFACE_PLACEHOLDER|${SURFACE}|g; s|FG_PLACEHOLDER|${FG}|g" "$HOME/.config/gtk-3.0/gtk.css"
cp -f "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
fi
[ -x "$HOME/.scripts/refresh_gtk.sh" ] && "$HOME/.scripts/refresh_gtk.sh"

# 3. Sincronizzazione Qt5 e Qt6 (kdeglobals & qt5ct / qt6ct)
hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}
RGB_BG=$(hex_to_rgb "${BG}")
RGB_FG=$(hex_to_rgb "${FG}")
RGB_ACCENT=$(hex_to_rgb "${ACCENT}")
RGB_SURFACE=$(hex_to_rgb "${SURFACE}")

mkdir -p "$HOME/.config"
cat << 'KDE_EOF' > "$HOME/.config/kdeglobals"
[Colors:Button]
BackgroundNormal=RGB_SURFACE_P
ForegroundNormal=RGB_FG_P

[Colors:Selection]
BackgroundNormal=RGB_ACCENT_P
ForegroundNormal=255,255,255

[Colors:View]
BackgroundNormal=RGB_BG_P
ForegroundNormal=RGB_FG_P

[Colors:Window]
BackgroundNormal=RGB_BG_P
ForegroundNormal=RGB_FG_P

[General]
ColorScheme=DynamicIsland
Name=DynamicIsland
KDE_EOF
sed -i "s|RGB_SURFACE_P|${RGB_SURFACE}|g; s|RGB_FG_P|${RGB_FG}|g; s|RGB_ACCENT_P|${RGB_ACCENT}|g; s|RGB_BG_P|${RGB_BG}|g" "$HOME/.config/kdeglobals"

for ct in qt5ct qt6ct; do
    mkdir -p "$HOME/.config/${ct}/colors"
    cat << 'CT_EOF' > "$HOME/.config/${ct}/colors/dynamic_island.conf"
[ColorScheme]
active_colors=RGB_SURFACE_P, RGB_BG_P, RGB_ACCENT_P, 255,255,255, RGB_BG_P, RGB_SURFACE_P, RGB_FG_P, 255,255,255, RGB_FG_P, RGB_BG_P, RGB_SURFACE_P, RGB_ACCENT_P, RGB_ACCENT_P, 255,255,255, RGB_ACCENT_P, 255,0,0, RGB_BG_P, RGB_FG_P, RGB_SURFACE_P, RGB_FG_P, 128,128,128
inactive_colors=RGB_SURFACE_P, RGB_BG_P, RGB_ACCENT_P, 255,255,255, RGB_BG_P, RGB_SURFACE_P, RGB_FG_P, 255,255,255, RGB_FG_P, RGB_BG_P, RGB_SURFACE_P, RGB_ACCENT_P, RGB_ACCENT_P, 255,255,255, RGB_ACCENT_P, 255,0,0, RGB_BG_P, RGB_FG_P, RGB_SURFACE_P, RGB_FG_P, 128,128,128
disabled_colors=40,40,40, 20,20,20, 50,50,50, 100,100,100, 20,20,20, 30,30,30, 120,120,120, 150,150,150, 120,120,120, 20,20,20, 30,30,30, 50,50,50, 50,50,50, 100,100,100, 50,50,50, 200,0,0, 20,20,20, 120,120,120, 30,30,30, 120,120,120, 80,80,80
CT_EOF
    sed -i "s|RGB_SURFACE_P|${RGB_SURFACE}|g; s|RGB_BG_P|${RGB_BG}|g; s|RGB_ACCENT_P|${RGB_ACCENT}|g; s|RGB_FG_P|${RGB_FG}|g" "$HOME/.config/${ct}/colors/dynamic_island.conf"
    if [ -f "$HOME/.config/${ct}/${ct}.conf" ]; then
        sed -i 's|^color_scheme_path=.*|color_scheme_path='"$HOME/.config/${ct}/colors/dynamic_island.conf"'|' "$HOME/.config/${ct}/${ct}.conf" 2>/dev/null || true
    fi
done

# 4. Ricarica Compositor & Componenti
command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true

# Notifiche e OSD refresh se presenti
if pgrep -x swaync >/dev/null 2>&1; then
    pkill swaync && sleep 0.2 && swaync >/dev/null 2>&1 &
fi
if pgrep -x swayosd-server >/dev/null 2>&1; then
    killall swayosd-server 2>/dev/null && swayosd-server >/dev/null 2>&1 &
fi
if [ -x "$HOME/.scripts/update_sddm.sh" ]; then
    sudo "$HOME/.scripts/update_sddm.sh" "$FULL_PATH" >/dev/null 2>&1 &
fi
EOF
    chmod +x "${APPLY_WP_SCRIPT}"

    # Generate init_wallpaper.sh (startup restore & daemon init)
    local INIT_WP_SCRIPT="${SCRIPTS_DIR}/init_wallpaper.sh"
    if [ -f "${INIT_WP_SCRIPT}" ]; then
        cp -f "${INIT_WP_SCRIPT}" "${INIT_WP_SCRIPT}.bak"
    fi

    echo "Generazione ${INIT_WP_SCRIPT} con backend ${WALLPAPER_BACKEND}..."
    cat << 'EOF' > "${INIT_WP_SCRIPT}"
#!/usr/bin/env bash
# ==============================================================================
# Dynamic Island — Wallpaper Initializer Script
# ==============================================================================
export PATH="$HOME/.local/bin:$HOME/.spicetify:$PATH"
export LANG=C.UTF-8
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

EOF

    # Backend startup logic in init_wallpaper.sh
    case "${WALLPAPER_BACKEND}" in
        awww)
            cat << 'EOF' >> "${INIT_WP_SCRIPT}"
if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon &
fi
while ! awww restore 2>/dev/null; do
    sleep 0.1
done
EOF
            ;;
        swww)
            cat << 'EOF' >> "${INIT_WP_SCRIPT}"
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww-daemon &
fi
while ! swww restore 2>/dev/null; do
    sleep 0.1
done
EOF
            ;;
        hyprpaper)
            cat << 'EOF' >> "${INIT_WP_SCRIPT}"
if ! pgrep -x "hyprpaper" > /dev/null; then
    hyprpaper &
fi
EOF
            ;;
        mpvpaper)
            cat << 'EOF' >> "${INIT_WP_SCRIPT}"
# mpvpaper non usa demone di restore, caricherà il wallpaper trovato sotto
EOF
            ;;
        swaybg)
            cat << 'EOF' >> "${INIT_WP_SCRIPT}"
# swaybg caricherà il wallpaper trovato sotto
EOF
            ;;
        wpaperd)
            cat << 'EOF' >> "${INIT_WP_SCRIPT}"
if ! pgrep -x "wpaperd" > /dev/null; then
    wpaperd &
fi
EOF
            ;;
    esac

    # Wallpaper fallback & theming restore
    cat << 'EOF' >> "${INIT_WP_SCRIPT}"

# Ricerca del wallpaper attuale (cache pywal, cache utente, o fallback cartella Sfondi)
WALLPAPER=""
if [ -L "$HOME/.cache/wal/current_wallpaper" ]; then
    TARGET=$(readlink "$HOME/.cache/wal/current_wallpaper")
    [ -f "$TARGET" ] && WALLPAPER="$TARGET"
fi
if [ -z "$WALLPAPER" ] && [ -f "$HOME/.cache/wal/wallpaper" ]; then
    WALLPAPER=$(cat "$HOME/.cache/wal/wallpaper" 2>/dev/null)
fi
if [ -z "$WALLPAPER" ]; then
    for dir in "$HOME/Sfondi" "$HOME/Pictures/Wallpapers" "$HOME/Pictures/wallpapers" "$HOME/Pictures"; do
        if [ -d "$dir" ]; then
            WALLPAPER=$(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | head -1)
            [ -n "$WALLPAPER" ] && break
        fi
    done
fi

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    if [ -x "$HOME/.scripts/apply-iris.sh" ]; then
        "$HOME/.scripts/apply-iris.sh" "$WALLPAPER"
    elif command -v wal >/dev/null 2>&1; then
        wal -i "$WALLPAPER" -n -q
    fi
fi
EOF
    chmod +x "${INIT_WP_SCRIPT}"
    echo "Script sfondi configurati con successo in ${SCRIPTS_DIR}!"
}

if [ "${SETUP_WALLPAPER}" = true ]; then
    setup_wallpaper_script
fi

echo ""
echo "========================================================"
echo "      🎉 Dynamic Island Installation Complete!"
echo "========================================================"
echo "• Backend Qt6 module: ${PREFIX}/lib/qt6/qml/IslandBackend"
echo "• Lyrics daemon:     ${PREFIX}/bin/lyricsmpris"
echo "• Shell launcher:    ${PREFIX}/bin/dynamic-island"
echo "• Runtime config:    ${QS_RUNTIME_DIR}"
echo "• User config:       $HOME/.config/dynamic-island/userconfig.json"
echo "• Hyprland autostart: Ready"
echo "• Screen share rule: no_screen_share layerrule configured"
echo ""
echo "Puoi avviare subito la Dynamic Island con:"
echo "  dynamic-island -d"
echo "========================================================"
