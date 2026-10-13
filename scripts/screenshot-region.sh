#!/usr/bin/env bash
# ==============================================================================
# Selettore screenshot integrato nella Dynamic Island di Quickshell
# ==============================================================================

mkdir -p "$HOME/Pictures/Screenshots"

# Chiama direttamente l'azione IPC del demone nativo Dynamic Island
quickshell ipc -p "$HOME/.config/quickshell/dynamic-island" call island startScreenshot
