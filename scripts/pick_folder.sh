#!/usr/bin/env bash
# ==============================================================================
# Dynamic Island Hyprland — Graphical Folder Picker Dialog
# ==============================================================================
# Opens a native GUI dialog (zenity, kdialog, or python) to let the user
# graphically browse and pick a folder. Outputs the selected path to stdout.
# ==============================================================================

INIT_DIR="${1:-$HOME}"
[ ! -d "$INIT_DIR" ] && INIT_DIR="$HOME"

# 1. Prova zenity (standard GNOME / GTK)
if command -v zenity >/dev/null 2>&1; then
    CHOSEN=$(zenity --file-selection --directory --filename="${INIT_DIR}/" --title="Seleziona Cartella Sfondi" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CHOSEN" ] && [ -d "$CHOSEN" ]; then
        echo "$CHOSEN"
        exit 0
    fi
    exit 1
fi

# 2. Prova kdialog (standard KDE / Qt)
if command -v kdialog >/dev/null 2>&1; then
    CHOSEN=$(kdialog --getexistingdirectory "${INIT_DIR}" --title "Seleziona Cartella Sfondi" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CHOSEN" ] && [ -d "$CHOSEN" ]; then
        echo "$CHOSEN"
        exit 0
    fi
    exit 1
fi

# 3. Fallback Python tkinter o xdg-desktop-portal
if command -v python3 >/dev/null 2>&1; then
    CHOSEN=$(python3 -c "
import sys
try:
    import tkinter as tk
    from tkinter import filedialog
    root = tk.Tk()
    root.withdraw()
    path = filedialog.askdirectory(initialdir='${INIT_DIR}', title='Seleziona Cartella Sfondi')
    if path:
        print(path)
        sys.exit(0)
except Exception:
    pass
sys.exit(1)
" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CHOSEN" ] && [ -d "$CHOSEN" ]; then
        echo "$CHOSEN"
        exit 0
    fi
fi

exit 1
