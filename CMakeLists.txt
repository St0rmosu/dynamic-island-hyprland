cmake_minimum_required(VERSION 3.16)
project(DynamicIsland VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

include(GNUInstallDirs)

option(DYNAMIC_ISLAND_WITH_NIRI "Build niri compositor integration" ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Network DBus Concurrent)
find_library(UDEV_LIB NAMES udev REQUIRED)

# ==============================================================================
# Main Backend Module (IslandBackend)
# ==============================================================================
qt_add_qml_module(IslandBackend
    URI IslandBackend
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/IslandBackend
    SOURCES
        backend/SysBackend.h
        backend/SysBackend.cpp
        backend/SystemServices.h
        backend/SystemServices.cpp
        backend/CompositorBackend.h
        backend/CompositorBackend.cpp
        backend/StyleTokensBackend.h
        backend/StyleTokensBackend.cpp
        backend/FileShelfModel.h
        backend/FileShelfModel.cpp
        backend/UserConfigBackend.h
        backend/UserConfigBackend.cpp
        backend/BluetoothPairingAgent.h
        backend/BluetoothPairingAgent.cpp
        backend/WifiController.h
        backend/WifiController.cpp
        backend/WifiNetworkModel.h
        backend/WifiNetworkModel.cpp
)

set_target_properties(IslandBackendplugin PROPERTIES
    INSTALL_RPATH "$ORIGIN/../../.."
)

target_include_directories(IslandBackend PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/backend
)

target_compile_definitions(IslandBackend PRIVATE
    DYNAMIC_ISLAND_WITH_NIRI=$<BOOL:${DYNAMIC_ISLAND_WITH_NIRI}>
    TIDE_ISLAND_WITH_NIRI=$<BOOL:${DYNAMIC_ISLAND_WITH_NIRI}>
)

target_link_libraries(IslandBackend PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Network
    Qt6::DBus
    Qt6::Concurrent
    ${UDEV_LIB}
)

# ==============================================================================
# Lyrics MPRIS Helper Executable
# ==============================================================================
add_executable(lyricsmpris
    lyricsmpris/main.cpp
    lyricsmpris/CjkVariantNormalizer.h
    lyricsmpris/CjkVariantNormalizer.cpp
    lyricsmpris/LyricsCore.h
    lyricsmpris/LyricsCore.cpp
    lyricsmpris/ProviderNetworkPolicy.h
    lyricsmpris/LyricsMprisApp.h
    lyricsmpris/LyricsMprisApp.cpp
)

target_include_directories(lyricsmpris PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/lyricsmpris
)

target_link_libraries(lyricsmpris PRIVATE
    Qt6::Core
    Qt6::Network
    Qt6::DBus
)

# ==============================================================================
# Installation Rules
# ==============================================================================
# 1. Backing shared library to system lib directory
install(TARGETS IslandBackend
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# 2. QML plugin binary
install(TARGETS IslandBackendplugin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/qml/IslandBackend
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# 3. QML metadata (qmldir, qmltypes)
install(FILES 
    ${CMAKE_CURRENT_BINARY_DIR}/IslandBackend/qmldir
    ${CMAKE_CURRENT_BINARY_DIR}/IslandBackend/IslandBackend.qmltypes
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/qml/IslandBackend
)

# 4. lyricsmpris helper binary
install(TARGETS lyricsmpris
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
