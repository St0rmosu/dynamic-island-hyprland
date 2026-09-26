#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

PREFIX="$HOME/.local"
if [ "$1" = "--system" ] || [ "$(id -u)" -eq 0 ]; then
    PREFIX="/usr"
fi

echo "=== Building Dynamic Island Backend ==="
cmake -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    "${SCRIPT_DIR}"

cmake --build "${BUILD_DIR}" -j"$(nproc)"

echo ""
echo "=== Installing Dynamic Island Backend to ${PREFIX} ==="
if [ "${PREFIX}" = "/usr" ] && [ "$(id -u)" -ne 0 ]; then
    echo "Administrative privileges required to install to /usr. Running sudo cmake --install..."
    sudo cmake --install "${BUILD_DIR}"
else
    cmake --install "${BUILD_DIR}"
fi

echo ""
echo "=== Backend Installation Complete! ==="
echo "Module IslandBackend is installed to ${PREFIX}/lib/qt6/qml/IslandBackend"
echo "Helper lyricsmpris is installed to ${PREFIX}/bin/lyricsmpris"
