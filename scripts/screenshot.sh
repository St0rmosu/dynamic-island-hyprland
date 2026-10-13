#!/usr/bin/env bash
# ==============================================================================
# Script unificato screenshot per Hyprland & Cealestia
# Supporta: full (schermo intero), region (selettore quickshell), satty (editor)
# ==============================================================================

MODE="${1:-region}"
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SAVE_DIR"
TIMESTAMP="$(date +'%Y-%m-%d-%H%M%S')"
FILENAME="$SAVE_DIR/Screenshot_${TIMESTAMP}.png"

case "$MODE" in
    full)
        # Cattura lo schermo intero del monitor attivo
        MONITOR=$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.monitor // empty')
        if [ -n "$MONITOR" ]; then
            grim -o "$MONITOR" "$FILENAME"
        else
            grim "$FILENAME"
        fi
        if [ -f "$FILENAME" ]; then
            wl-copy < "$FILENAME" 2>/dev/null
            notify-send -a "Screenshot" -i "$FILENAME" "Screenshot Catturato" "Schermo intero salvato in:\n$FILENAME\ne copiato negli appunti" 2>/dev/null
        fi
        ;;

    satty)
        # Selezione regione con slurp e apertura immediata nell'editor Satty
        GEOM=$(slurp 2>/dev/null)
        if [ -n "$GEOM" ]; then
            sleep 0.1
            grim -g "$GEOM" - | satty --filename - --copy-command wl-copy --output-filename "$FILENAME"
        fi
        ;;

    region|*)
        # Selettore Quickshell con lente, anteprima dimensioni e capsule toolbar
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -x "$SCRIPT_DIR/screenshot-region.sh" ]; then
            exec "$SCRIPT_DIR/screenshot-region.sh"
        else
            exec "$HOME/.scripts/screenshot-region.sh"
        fi
        ;;
esac
