#!/usr/bin/env bash
# ==============================================================================
# Dynamic Island Hyprland — Wallpaper Applier & Color Palette Sync
# ==============================================================================
# Applies the selected wallpaper using the configured backend (awww, swww,
# hyprpaper, mpvpaper, swaybg, wpaperd) and synchronizes colors across:
#   - GTK 3.0 & GTK 4.0 (Libadwaita)
#   - Qt5 & Qt6 (kdeglobals & qt5ct/qt6ct)
#   - Pywal, Matugen, Adwaita-colors, Spicetify
#   - Hyprland border colors
# ==============================================================================

export PATH="$HOME/.local/bin:$HOME/.spicetify:$PATH"
export LANG=C.UTF-8

FULL_PATH="$1"
if [ -z "$FULL_PATH" ] || [ ! -f "$FULL_PATH" ]; then
    echo "Errore: wallpaper non valido o non trovato: $FULL_PATH" >&2
    exit 1
fi

CHOICE=$(basename "$FULL_PATH" | sed 's/\.[^.]*$//')

# 1. Rileva o leggi il backend impostato
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dynamic-island"
BACKEND_FILE="${CONFIG_DIR}/wallpaper_backend"
WALLPAPER_BACKEND="awww"

if [ -f "${BACKEND_FILE}" ]; then
    WALLPAPER_BACKEND=$(tr -d ' \n\r' < "${BACKEND_FILE}")
elif command -v awww >/dev/null 2>&1; then
    WALLPAPER_BACKEND="awww"
elif command -v swww >/dev/null 2>&1; then
    WALLPAPER_BACKEND="swww"
elif command -v hyprpaper >/dev/null 2>&1; then
    WALLPAPER_BACKEND="hyprpaper"
elif command -v mpvpaper >/dev/null 2>&1; then
    WALLPAPER_BACKEND="mpvpaper"
elif command -v swaybg >/dev/null 2>&1; then
    WALLPAPER_BACKEND="swaybg"
elif command -v wpaperctl >/dev/null 2>&1; then
    WALLPAPER_BACKEND="wpaperd"
fi

# 2. Rileva tipo di transizione
TRANSITION_TYPE="${2:-}"
if [ -z "$TRANSITION_TYPE" ] && [ -f "${CONFIG_DIR}/config.json" ]; then
    TRANSITION_TYPE=$(jq -r '.wallpaperTransitionType // .wallpaperTransition // empty' "${CONFIG_DIR}/config.json" 2>/dev/null)
fi
TRANSITION_TYPE="${TRANSITION_TYPE:-random}"

# 3. Applica lo sfondo con il backend scelto
case "${WALLPAPER_BACKEND}" in
    awww)
        if ! pgrep -x "awww-daemon" >/dev/null 2>&1; then
            awww-daemon >/dev/null 2>&1 &
            sleep 0.2
        fi
        awww img "$FULL_PATH" --transition-type "${TRANSITION_TYPE}" --transition-pos 0.9,0.9 --transition-step 45 --transition-fps 60 2>/dev/null || true
        ;;
    swww)
        if ! pgrep -x "swww-daemon" >/dev/null 2>&1; then
            swww-daemon >/dev/null 2>&1 &
            sleep 0.2
        fi
        swww img "$FULL_PATH" --transition-type "${TRANSITION_TYPE}" --transition-pos 0.9,0.9 --transition-step 45 --transition-fps 60 2>/dev/null || true
        ;;
    hyprpaper)
        if ! pgrep -x "hyprpaper" >/dev/null 2>&1; then
            hyprpaper >/dev/null 2>&1 &
            sleep 0.2
        fi
        hyprctl hyprpaper preload "$FULL_PATH" >/dev/null 2>&1 || true
        hyprctl hyprpaper wallpaper ",$FULL_PATH" >/dev/null 2>&1 || true
        hyprctl hyprpaper unload all >/dev/null 2>&1 || true
        ;;
    mpvpaper)
        pkill -x mpvpaper 2>/dev/null || true
        mpvpaper '*' "$FULL_PATH" -o "no-audio loop" >/dev/null 2>&1 &
        ;;
    swaybg)
        pkill -x swaybg 2>/dev/null || true
        swaybg -i "$FULL_PATH" -m fill >/dev/null 2>&1 &
        ;;
    wpaperd)
        if ! pgrep -x "wpaperd" >/dev/null 2>&1; then
            wpaperd >/dev/null 2>&1 &
            sleep 0.2
        fi
        wpaperctl set-wallpaper "$FULL_PATH" >/dev/null 2>&1 || true
        ;;
    *)
        if command -v awww >/dev/null 2>&1; then
            awww img "$FULL_PATH" --transition-type any 2>/dev/null || true
        elif command -v swww >/dev/null 2>&1; then
            swww img "$FULL_PATH" --transition-type any 2>/dev/null || true
        fi
        ;;
esac

# 3. Notifica desktop
if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Dynamic Island" "Wallpaper" "Applicato: $CHOICE" 2>/dev/null || true
fi

# Salva wallpaper corrente per Dynamic Island e Quickshell
mkdir -p "$HOME/.cache/wal" "$CONFIG_DIR"
echo "$FULL_PATH" > "$HOME/.cache/wal/wal"
echo "$FULL_PATH" > "$HOME/.cache/wal/wallpaper"
echo "$FULL_PATH" > "$CONFIG_DIR/current_wallpaper"

# 4. Estrazione Palette Colori Dinamica (Iris / Pywal / Matugen)
if [ -x "$HOME/.scripts/apply-iris.sh" ]; then
    "$HOME/.scripts/apply-iris.sh" "$FULL_PATH" 2>/dev/null || true
elif command -v wal >/dev/null 2>&1; then
    wal -i "$FULL_PATH" -n -q -t 2>/dev/null || true
elif command -v matugen >/dev/null 2>&1; then
    matugen image "$FULL_PATH" 2>/dev/null || true
fi

# 5. Lettura dei colori
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

# 6. Sincronizzazione GTK-3.0 e GTK-4.0 (Libadwaita / Flatpak)
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

# 7. Sincronizzazione Qt5 e Qt6 (kdeglobals, qt5ct, qt6ct)
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

# 8. Esecuzione script di terze parti (Adwaita-colors, pywal-theme, refresh)
[ -x "$HOME/.scripts/adwaita-matugen.sh" ] && "$HOME/.scripts/adwaita-matugen.sh" >/dev/null 2>&1 &
[ -x "$HOME/.scripts/pywal-theme.sh" ] && "$HOME/.scripts/pywal-theme.sh" "$FULL_PATH" >/dev/null 2>&1 &
[ -x "$HOME/.scripts/refresh_gtk.sh" ] && "$HOME/.scripts/refresh_gtk.sh" >/dev/null 2>&1 &

# 9. Ricarica Hyprland
command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
