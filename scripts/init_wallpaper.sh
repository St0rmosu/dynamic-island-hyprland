#!/usr/bin/env bash
# ==============================================================================
# Dynamic Island Hyprland — Wallpaper Daemon Initializer & Restore
# ==============================================================================
# Starts the background wallpaper daemon and restores the previous wallpaper.
# Designed to be launched on compositor startup (hyprland autostart).
# ==============================================================================

export PATH="$HOME/.local/bin:$HOME/.spicetify:$PATH"
export LANG=C.UTF-8
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

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

case "${WALLPAPER_BACKEND}" in
    awww)
        if ! pgrep -x "awww-daemon" > /dev/null; then
            awww-daemon &
        fi
        while ! awww restore 2>/dev/null; do
            sleep 0.1
        done
        ;;
    swww)
        if ! pgrep -x "swww-daemon" > /dev/null; then
            swww-daemon &
        fi
        while ! swww restore 2>/dev/null; do
            sleep 0.1
        done
        ;;
    hyprpaper)
        if ! pgrep -x "hyprpaper" > /dev/null; then
            hyprpaper &
        fi
        ;;
    wpaperd)
        if ! pgrep -x "wpaperd" > /dev/null; then
            wpaperd &
        fi
        ;;
    mpvpaper|swaybg)
        # Managed via direct execution on wallpaper selection
        ;;
esac

# Trova wallpaper precedente per ripristinare il tema di sistema
WALLPAPER=""
if [ -f "${CONFIG_DIR}/current_wallpaper" ]; then
    CANDIDATE=$(cat "${CONFIG_DIR}/current_wallpaper" 2>/dev/null)
    [ -f "$CANDIDATE" ] && WALLPAPER="$CANDIDATE"
fi
if [ -z "$WALLPAPER" ] && [ -f "$HOME/.cache/wal/wal" ]; then
    CANDIDATE=$(cat "$HOME/.cache/wal/wal" 2>/dev/null)
    [ -f "$CANDIDATE" ] && WALLPAPER="$CANDIDATE"
fi
if [ -z "$WALLPAPER" ] && [ -L "$HOME/.cache/wal/current_wallpaper" ]; then
    TARGET=$(readlink "$HOME/.cache/wal/current_wallpaper")
    [ -f "$TARGET" ] && WALLPAPER="$TARGET"
fi
if [ -z "$WALLPAPER" ] && [ -f "$HOME/.cache/wal/wallpaper" ]; then
    CANDIDATE=$(cat "$HOME/.cache/wal/wallpaper" 2>/dev/null)
    [ -f "$CANDIDATE" ] && WALLPAPER="$CANDIDATE"
fi
if [ -z "$WALLPAPER" ] && [ -f "$HOME/.config/illogical-impulse/config.json" ]; then
    CANDIDATE=$(python3 -c "import json; print(json.load(open('$HOME/.config/illogical-impulse/config.json')).get('background', {}).get('wallpaperPath', ''))" 2>/dev/null)
    [ -f "$CANDIDATE" ] && WALLPAPER="$CANDIDATE"
fi
if [ -z "$WALLPAPER" ]; then
    for dir in "$HOME/Pictures/Wallpapers" "$HOME/Pictures/wallpapers" "$HOME/Pictures" "$HOME/Sfondi"; do
        if [ -d "$dir" ]; then
            WALLPAPER=$(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | head -1)
            [ -n "$WALLPAPER" ] && break
        fi
    done
fi

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    if [ -x "$HOME/.scripts/apply-iris.sh" ]; then
        "$HOME/.scripts/apply-iris.sh" "$WALLPAPER" >/dev/null 2>&1 || true
    elif command -v wal >/dev/null 2>&1; then
        wal -i "$WALLPAPER" -n -q >/dev/null 2>&1 || true
    fi
fi
