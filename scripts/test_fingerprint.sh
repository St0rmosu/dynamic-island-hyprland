#!/usr/bin/env bash
# Quick tester for Touch ID (Fingerprint) & Face ID in Dynamic Island

MODE="${1:-interactive}"

if [ "$MODE" = "success" ] || [ "$MODE" = "--success" ]; then
    echo "Simulazione Touch ID Impronta con successo..."
    quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island testFingerprintSuccess
elif [ "$MODE" = "password" ] || [ "$MODE" = "--password" ]; then
    echo "Apertura Polkit Password / Face ID..."
    quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island testPolkit
else
    echo "Apertura Polkit in modalità Touch ID Impronta..."
    echo "Puoi cliccare la scheda o premere 'Usa Password' per cambiare!"
    quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island testFingerprint
fi
