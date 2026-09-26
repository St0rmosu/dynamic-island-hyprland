#!/usr/bin/env bash
# ==============================================================================
# Island Share Picker — Native Dynamic Island Screencopy Integration
# ==============================================================================
# For Cealestia / standard shells: uses the default hyprland-share-picker.
# For Dynamic Island: invokes the native embedded Apple-style Dynamic Island picker.
# Fallback: hyprland-share-picker if Dynamic Island is unreachable.
# ==============================================================================

set -e

QS_DIR="${HOME}/.config/quickshell"
CURRENT_BAR=""
if [ -f "${QS_DIR}/current_bar" ]; then
    CURRENT_BAR=$(cat "${QS_DIR}/current_bar" 2>/dev/null | tr -d '[:space:]')
fi

# 1. If Cealestia (or any other non-Dynamic Island shell) is active, preserve default hyprland-share-picker
if [ "$CURRENT_BAR" != "dynamic-island" ]; then
    if [ -x /usr/bin/hyprland-share-picker ]; then
        exec /usr/bin/hyprland-share-picker "$@"
    fi
fi

# 2. Dynamic Island is active: Check if IPC is available
if ! quickshell -c dynamic-island ipc show >/dev/null 2>&1; then
    # Dynamic Island is not currently responding to IPC -> fallback to default picker
    if [ -x /usr/bin/hyprland-share-picker ]; then
        exec /usr/bin/hyprland-share-picker "$@"
    fi
    exit 1
fi

# 3. Detect restore token argument from XDPH
ALLOW_TOKEN=true
for arg in "$@"; do
    if [ "$arg" = "--allow-token" ]; then
        ALLOW_TOKEN=true
    fi
done

# 4. Save XDPH window list if provided in environment
if [ -n "$XDPH_WINDOW_SHARING_LIST" ]; then
    echo "$XDPH_WINDOW_SHARING_LIST" > /tmp/island_xdph_windows.txt
fi

# 5. Create communication FIFO
FIFO=$(mktemp -u /tmp/island-share-picker-XXXXXX.fifo)
mkfifo "$FIFO"
chmod 600 "$FIFO"

cleanup() {
    exec 3>&- 2>/dev/null || true
    rm -f "$FIFO"
}
trap cleanup EXIT INT TERM

# Open FIFO read-write to avoid blocking open() call
exec 3<>"$FIFO"

# 6. Request Dynamic Island to present the custom picker UI
if ! quickshell -c dynamic-island ipc call island promptScreenShareSelection "$FIFO" 2>/dev/null; then
    # IPC failed -> fallback
    exec 3>&-
    rm -f "$FIFO"
    if [ -x /usr/bin/hyprland-share-picker ]; then
        exec /usr/bin/hyprland-share-picker "$@"
    fi
    exit 1
fi

# 7. Wait for selection from the Dynamic Island UI (timeout 90 seconds)
CHOICE=""
if read -t 90 -u 3 CHOICE; then
    exec 3>&-
    CHOICE=$(echo "$CHOICE" | tr -d '\r\n')
    if [ -n "$CHOICE" ] && [ "$CHOICE" != "cancel" ]; then
        # Format output: if restore token is enabled, XDPH expects '[SELECTION]r/<type>:<id>'
        if [[ "$CHOICE" == r/* ]]; then
            echo "[SELECTION]${CHOICE}"
        elif [ "$ALLOW_TOKEN" = "true" ]; then
            CLEAN_CHOICE="${CHOICE#/}"
            echo "[SELECTION]r/${CLEAN_CHOICE}"
        else
            CLEAN_CHOICE="${CHOICE#/}"
            echo "[SELECTION]/${CLEAN_CHOICE}"
        fi
        exit 0
    fi
fi

# User canceled or selection timed out
exit 1
