#!/usr/bin/env bash
# Dynamic Island Apple Lock Screen Test & Runner Script

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_DIR="${DIR}/lock"

usage() {
    echo "Uso: $0 [preview|lock|unlock|status]"
    echo ""
    echo "Comandi:"
    echo "  preview   Apri il lockscreen in modalità anteprima (sicura, con pulsante di chiusura)"
    echo "  lock      Blocca realmente la sessione con Quickshell WlSessionLock e PAM"
    echo "  unlock    Invia segnale di sblocco via IPC"
    echo "  status    Verifica se il demone di blocco è attivo"
    exit 1
}

ACTION="${1:-preview}"

case "$ACTION" in
    preview)
        echo "Lancio anteprima Apple Lock Screen..."
        quickshell -p "${LOCK_DIR}/preview.qml"
        ;;
    lock)
        echo "Avvio Apple Lock Screen in modalità sessione sicura..."
        if ! pgrep -f "quickshell.*${LOCK_DIR}" > /dev/null 2>&1; then
            quickshell -p "${LOCK_DIR}" -d
            for _ in $(seq 30); do
                quickshell ipc -p "${LOCK_DIR}" call lock isLocked > /dev/null 2>&1 && break
                sleep 0.1
            done
        fi
        quickshell ipc -p "${LOCK_DIR}" call lock lock
        ;;
    unlock)
        quickshell ipc -p "${LOCK_DIR}" call lock unlock
        ;;
    status)
        quickshell ipc -p "${LOCK_DIR}" call lock isLocked
        ;;
    *)
        usage
        ;;
esac
