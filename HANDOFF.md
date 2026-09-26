# Dynamic Island Hyprland — Project Handoff Document

> **Last Updated**: 2026-09-26  
> **Repository**: `/home/lollo/Progetti/dynamic-island-hyprland` (Branch: `main`)  
> **Active Runtime Config**: `/home/lollo/.config/quickshell/dynamic-island`  
> **Config Directory**: `/home/lollo/.config/dynamic-island`  
> **OS & Environment**: Arch Linux, Hyprland (All-AMD), Waybar ('Cealestia' theme) & Quickshell ('dynamic-island'), Pywal16 + Iris color scheme generation.  
> **Strict Git Exclusion**: `ThemeFloatingIsland.qml` (private custom switcher pill) must NEVER be committed to GitHub. All other shell features, scripts, and installer enhancements are committed upstream.

---

## 1. Executive Summary & Purpose

This project is a native, highly animated **Dynamic Island & Control Center** shell written in **QML / Quickshell (Qt 6)** and native **C++** for Hyprland on Arch Linux. It provides an iOS-style dynamic pill anchored at the top center of the screen that smoothly morphs across interactive modes:
- **Compact Bar / Resting Capsule**: Standard clock, workspace indicators, battery percentage, media playback pill, custom OSD.
- **Control Center (`control_center`)**: macOS/iOS-styled Control Center containing quick toggles, interactive volume & brightness sliders, media card, notifications, and custom modular widgets.
- **Settings App (`settings_app`)**: Standalone, floating 980x680 window with 5 categories (`Bar & Island`, `Control Center`, `Appearance`, `Motion & Animation`, `Modules`) and live JSON persistence to `~/.config/dynamic-island/userconfig.json`.
- **Studio Layout Canvas**: Visual drag-and-drop grid customizer embedded in the Settings App Control Center tab, allowing 4-corner resizing, single-click height adjustments, and real-time layout sync.
- **Power Menu / Wlogout (`power_menu`)**: Dedicated 380x92 pill capsule with 5 circular glass buttons (Lock, Logout, Sleep, Restart, Shutdown) featuring color-accented hover effects, tactile click feedback, and instant dismiss (`Escape` or click outside).
- **Clipboard Manager (`clipboard`)**: Apple Intelligence-style masonry grid previewing text snippets and image clips from `cliphist`.
- **Wallpaper Picker (`wallpaper_picker`)**: 3D coverflow carousel browsing `/home/lollo/Sfondi` with live thumbnail generation and Pywal16 color regeneration via `apply-wallpaper.sh`.
- **System Tray Satellite Pill (`TrayFloatingIsland`)**: Independent floating pill positioned 8px directly below the Control Center, rendering background status notifier items with unread indicators and context menus.

---

## 2. Recent Major Accomplishments & Milestone Fixes (2026-09-26)

### A. 100% Standalone C++ Backend (`IslandBackend`) & Lyrics Helper (`lyricsmpris`)
- **Problem**: The shell previously depended on the external Arch Linux / AUR package `tide-island` to provide `/usr/lib/libIslandBackend.so` and the Qt6 QML module `/usr/lib/qt6/qml/IslandBackend/`. Without that package, Quickshell crashed with `module "IslandBackend" is not installed`. Furthermore, the upstream C++ code had hardcoded paths pointing to `~/.config/tide-island/userconfig.json`.
- **Solution & Implementation**:
  1. Extracted and integrated the full C++ backend source code directly into the repository under [`backend/`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/) and [`lyricsmpris/`](file:///home/lollo/Progetti/dynamic-island-hyprland/lyricsmpris/).
  2. Built a clean, standard [`CMakeLists.txt`](file:///home/lollo/Progetti/dynamic-island-hyprland/CMakeLists.txt) compiling both `IslandBackend` (Qt6 QML module) and `lyricsmpris` (MPRIS synced lyrics executable).
  3. Created [`install.sh`](file:///home/lollo/Progetti/dynamic-island-hyprland/install.sh) with dual-mode installation:
     - **Rootless user install (default)**: Installs directly to `~/.local/lib/`, `~/.local/lib/qt6/qml/IslandBackend/`, and `~/.local/bin/lyricsmpris` with zero sudo or root requirements.
     - **System install (`--system`)**: Installs to `/usr/lib/` and `/usr/bin/` with `sudo`.
  4. Patched all hardcoded paths in C++:
     - [`backend/UserConfigBackend.cpp`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/UserConfigBackend.cpp): Dynamically resolves `~/.config/dynamic-island/userconfig.json` first, keeping legacy `tide-island` as a fallback.
     - [`backend/BluetoothPairingAgent.cpp`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/BluetoothPairingAgent.cpp) & [`backend/WifiController.cpp`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/WifiController.cpp): Updated D-Bus object paths to `/com/dynamicisland/IslandBackend/...`.
     - [`backend/CompositorBackend.cpp`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/CompositorBackend.cpp): Checks `DYNAMIC_ISLAND_COMPOSITOR` environment variable first.
     - [`backend/SysBackend.cpp`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/SysBackend.cpp): Updated candidates to look for `lyricsmpris` in dynamic-island config and `~/.local/bin` first.
     - [`backend/SystemServices.cpp`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/SystemServices.cpp): Renamed dialog title to "Dynamic Island" and looks for `dynamic-island-config-app`.
  5. Updated launcher [`~/.local/bin/dynamic-island`](file:///home/lollo/.local/bin/dynamic-island) to export `QML_IMPORT_PATH` and `LD_LIBRARY_PATH` pointing to `~/.local/lib/qt6/qml` and `~/.local/lib`.
  6. **Live Verification**: Verified via `/proc/<pid>/maps` that the running Quickshell process actively loads our newly compiled local backend (`~/.local/lib/libIslandBackend.so`), making the package `tide-island` 100% safe to remove via `sudo pacman -R tide-island`.
  7. Committed clean backend code and build configuration to GitHub (`0917d1c`).

### B. Frame-by-Frame System Tray Pill Synchronization (`TrayFloatingIsland.qml`)
- **Problem**: Opening the Control Center resulted in a jarring two-step animation: the Control Center expanded to its full 420px height, stopped, and *then* the system tray satellite pill slid down underneath it with an awkward delay.
- **Root Cause**: In [`qml/island/TrayFloatingIsland.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/TrayFloatingIsland.qml), `x` and `y` had their own `Behavior on x` and `Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }`. Because `mainCapsule.height` was already smoothly animating with `duration: 400` (`Easing.OutQuint`), the second-order smoothing filter in `TrayFloatingIsland` caused a 250ms trailing lag behind `mainCapsule`.
- **Solution**: Removed `Behavior on x` and `Behavior on y`. `y` is now directly bound to `Math.round(targetCapsule.y + targetCapsule.height + 8)`. The tray pill now moves in 100% lockstep frame-by-frame with the bottom lip of the Control Center, expanding and collapsing synchronously.

### C. Decoupling Hyprland Shortcuts & System Configuration
- Switched `~/.config/hypr/hyprland.conf` from sourcing `/home/lollo/.config/tide-island/hyprland-shortcuts.conf` to `source = /home/lollo/.config/dynamic-island/hyprland-shortcuts.conf`.
- Synced launcher scripts (`apply-qs-bar.sh dynamic-island`, `shell-dispatcher.sh`).

### E. Wallpaper Picker Runtime Bug Fix
- **Problem**: `WallpaperPickerLayer.qml` threw runtime `ReferenceError: Quickshell is not defined` on line 16 and in `applyWallpaper`, breaking wallpaper application.
- **Root Cause**: `import Quickshell` was missing at the top of the file (it only had `import Quickshell.Io` and `import Quickshell.Widgets`).
- **Fix**: Added `import Quickshell` to [`qml/island/WallpaperPickerLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/WallpaperPickerLayer.qml), resolving all path evaluations and `Quickshell.execDetached` calls.

### F. Intelligent Hyprland Modular Autostart & Wallpaper Generator (`install.sh`)
- **Autostart Injection**:
  - `install.sh` automatically inspects `~/.config/hypr/` and detects whether the configuration is **modular** or **monolithic**.
  - **Lua Hyprland**: Detects `moduli/` or `modules/` (e.g. `misc.lua` or `autostart.lua`). Safely injects `hl.exec_cmd("$HOME/.local/bin/dynamic-island -d")` without duplication.
  - **Standard Hyprland**: Inspects `hyprland.conf` for `source = ` directives, modular directories (`conf.d/`), or candidate autostart files (`autostart.conf`, `exec.conf`), falling back to monolithic append.
- **Wallpaper Backend Generator**:
  - Lets user choose wallpaper software during setup (1: `awww` [default], 2: `swww`, 3: `hyprpaper`, 4: `mpvpaper`, 5: `swaybg`, 6: `wpaperd`).
  - Generates or updates `~/.scripts/init_wallpaper.sh` and `~/.scripts/apply-wallpaper.sh` with seamless daemon management, transitions, and Pywal16/Iris color extraction hooks.

### G. Native Screen Sharing Indicator & Privacy Exclusion (`no_screen_share`)
- **In-Island Screen Sharing Pill**:
  - When a screen share/recording session begins (detected automatically by `SystemServices` via PipeWire and `org.freedesktop.portal.ScreenCast`), the island triggers an animated banner (`[ 󰍹 Condivisione Schermo ]`) and displays an Apple-style glowing capsule with a pulsing live transmission dot (`RecordingIndicator.qml`).
- **Zero Stream Leakage (`no_screen_share`)**:
  - Configured `layerrule = no_screen_share, dynamic-island` and `layerrule = no_screen_share, quickshell` in both `rules.lua` and `hyprland.conf`.
  - While the user sees the island on their physical display, Hyprland's compositor completely omits the layer from screencopy buffers (Discord, OBS, Google Meet, Zoom), preventing notifications, controls, or the island itself from appearing on stream.

### H. Native Screen Share Picker & XDPH Custom Picker Routing
- **Context & Requirement**:
  - The default `hyprland-share-picker` dialog clashed with the Dynamic Island design.
  - The user requested an enlarged, native screen share picker matching the Dynamic Island aesthetic, with full dynamic **Iris color palette** integration for both the picker and the power menu (wlogout), and support for the **restore token** so screen sharing activates reliably without getting blocked by applications.
  - The default `hyprland-share-picker` remains strictly intact when running `cealestia`.
- **Solution & Implementation**:
  1. **UI Layer ([`ScreenSharePickerLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ScreenSharePickerLayer.qml))**:
     - **Enlarged Geometry**:
       - Main View: expanded to **620x220px** with 104px tall cards, 32px icons, and clear typography.
       - Windows Selection View: expanded to **700x480px** with 52px tall window items, app icons, and responsive search/scroll.
     - **Iris Colors Integration**:
       - Dynamic live loading of `~/.cache/iris/colors.json` via `FileView`.
       - Schermo card: Iris blue (`irisColors.blueHex`).
       - Finestra card: Iris purple/magenta (`irisColors.purpleHex`).
       - Regione card: Iris green (`irisColors.greenHex`).
       - Surface, text, and hover states strictly follow Iris `surface`, `fg`, and `dim` tones.
     - **Restore Token Checkbox (`allowToken`)**:
       - Embedded toggle pill: `[ 󰄬 ] Consenti token di ripristino (ricorda autorizzazione app)` active by default.
       - Outputs the required `r/` flag when selected (`r/screen:...`, `r/window:...`, `r/region:...`).
  2. **Power Menu Iris Integration ([`PowerMenuLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/PowerMenuLayer.qml))**:
     - Replaced hardcoded colors with live Iris palette: Lock (Iris purple), Logout (Iris green), Sleep (Iris blue), Restart (Iris yellow), Shutdown (Iris red).
     - Expanded capsule dimensions (420x96px) with 58x58px tactile glass buttons.
  3. **Custom Picker Wrapper & Protocol Matching ([`~/.scripts/island-share-picker.sh`](file:///home/lollo/.scripts/island-share-picker.sh))**:
     - Configured in `~/.config/hypr/xdph.conf` under `screencopy.custom_picker_binary`.
     - When `cealestia` is active: transparently executes `/usr/bin/hyprland-share-picker "$@"`.
     - When `dynamic-island` is active:
       - Captures `XDPH_WINDOW_SHARING_LIST` and extracts `handleLo` identifiers for flawless window targeting.
       - Captures slurp region formatted as `<output>@<x>,<y>,<w>,<h>`.
       - Formats stdout as `[SELECTION]r/<type>:<id>` to satisfy XDPH's restore token parser.
       - Automatic fallback to `/usr/bin/hyprland-share-picker` if IPC is unavailable.

### I. Automatic Satellite Centering & Island Balancing
- **Problem**: When Discord calls (`CallFloatingIsland.qml`) or Bluetooth headphones (`HeadphonesFloatingIsland.qml`) were active, their satellite pills docked on the right side (+45px) of the main capsule. Because no media pill was active on the left, the visual cluster was skewed 22.5px to the right of the screen center, looking off-center to the user.
- **Solution & Implementation**:
  1. **Dynamic Cluster Extent Calculation ([`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml))**:
     - Computes real-time `satelliteLeftExtent` (Music pill + margin, File shelf bubble).
     - Computes real-time `satelliteRightExtent` (Headphones pill, Discord call pill, Timer bubble).
     - Derives `satelliteBalanceOffset = (satelliteLeftExtent - satelliteRightExtent) / 2.0`.
  2. **Smooth Fluid Gliding Animation**:
     - Bound to `animatedBalanceOffset` with `Behavior on animatedBalanceOffset { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }`.
     - When a call begins or headphones connect, the capsule smoothly glides by ~22px to keep the overall visual center of mass perfectly at `1920 / 2 = 960px`.
     - When expanding to full panels (Control Center, Settings, App Launcher), balancing suspends automatically so large panels remain centered at 50%.
  3. **Configuration & Persistence**:
     - Toggleable via `"autoBalanceSatellites": true` in `~/.config/dynamic-island/userconfig.json` (active by default).

### J. Flip Clock Rolling Digit Animation (`FlipClockText.qml`)
- **Requirement**: When the clock time advances (e.g. minute rolls over), the digits must animate upwards in a mechanical vertical flip-clock / rolling odometer effect.
- **Solution & Implementation**:
  1. **Component Architecture ([`qml/island/FlipClockText.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/FlipClockText.qml))**:
     - Decomposes the time string into individual character cells (`TextMetrics` advance-width measurement).
     - Each cell is clipped (`clip: true`) with vertical centering.
     - Detects per-digit changes: unchanged characters (e.g. the hours digits or colons `:`) remain completely motionless.
     - Changed digits trigger a synchronized upward roll:
       - Departing digit slides UP from `0` to `-slideDistance` with scale down (1.0 -> 0.82) and fade out (1 -> 0).
       - Arriving digit slides IN FROM BELOW from `+slideDistance` to `0` with scale up (0.82 -> 1.0) and fade in (0 -> 1).
       - Driven by `Easing.OutQuint` over 380ms for a physics-based mechanical flip sensation.
  2. **Layer Integration**:
     - Integrated seamlessly into both [`SwipeLyricsLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/SwipeLyricsLayer.qml) and [`SwipeCustomInfoLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/SwipeCustomInfoLayer.qml).
     - Preserves full color animation support (`root.accentColor` transitions) and `RecordingIndicator` alignment.

### K. Minimal Shell Installer & Unified GTK/Qt Theming Engine (`install.sh`)
- **Strict Shell Dependency Verification**:
  - `install.sh` verifies and installs strictly and exclusively the essential packages required for the Dynamic Island shell to run (`quickshell`, `cmake`, `ninja`, `qt6-base`, `qt6-declarative`, `jq`, `socat`, `libnotify`, `brightnessctl`, `playerctl`, `wireplumber`, `slurp`, `grim`, `bluez`, `bluez-utils`, and wallpaper engine `awww`).
- **Unified GTK3, GTK4, Qt5 & Qt6 Theming**:
  - The generated `apply-wallpaper.sh` template automatically propagates the wallpaper color palette across:
    - **GTK-3.0** (`~/.config/gtk-3.0/gtk.css`) and **GTK-4.0 / Libadwaita** (`~/.config/gtk-4.0/gtk.css`) using CSS variables (`@define-color accent_color`, `window_bg_color`, `card_bg_color`).
    - **Qt5 & Qt6** via `~/.config/kdeglobals` (`[Colors:Window]`, `[Colors:Selection]`, `[Colors:Button]`) and `qt5ct`/`qt6ct` palettes (`dynamic_island.conf`).
  - Ensures seamless visual coherence across native desktop applications.

---

## 3. Architecture & File Structure

| File Path | Description |
| :--- | :--- |
| [`CMakeLists.txt`](file:///home/lollo/Progetti/dynamic-island-hyprland/CMakeLists.txt) | Root CMake build configuration registering Qt6 QML module `IslandBackend` and `lyricsmpris`. |
| [`install.sh`](file:///home/lollo/Progetti/dynamic-island-hyprland/install.sh) | Build and installation script supporting rootless user install (`~/.local/`) and system install (`/usr/`). |
| [`backend/`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/) | C++ source code for `IslandBackend` (Qt6 C++ plugin for window tracking, system state, bluetooth, user config). |
| [`lyricsmpris/`](file:///home/lollo/Progetti/dynamic-island-hyprland/lyricsmpris/) | C++ daemon for real-time synchronized karaoke-style MPRIS lyrics. |
| [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) | Core layer-shell window, state machine (`islandState`), size calculations, morph animations, and dynamic component loaders. |
| [`qml/island/TrayFloatingIsland.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/TrayFloatingIsland.qml) | Floating system tray satellite pill underneath Control Center with synchronous opening animation and continuous hover bridge. |
| [`qml/island/PowerMenuLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/PowerMenuLayer.qml) | Dedicated 5-button power & session menu (Lock, Logout, Sleep, Restart, Shutdown) with detached execution. |
| [`qml/controlcenter/SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml) | Standalone 980x680 Settings App with category sidebar, segmented Studio switcher, and JSON IO. |
| [`qml/controlcenter/StudioLayoutCanvas.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/StudioLayoutCanvas.qml) | Visual drag/drop grid canvas for sizing and positioning Control Center cards. |
| [`qml/controlcenter/ControlCenterLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlCenterLayer.qml) | Expanded Control Center overlay with cards, volume/brightness sliders, and network controls. |
| [`qml/island/WallpaperPickerLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/WallpaperPickerLayer.qml) | PathView 3D coverflow carousel browsing wallpapers with instant thumbnail caching and pywal triggers. |
| [`qml/island/ClipboardLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ClipboardLayer.qml) | Apple Intelligence-style masonry cards previewing `cliphist` text and image clips. |
| [`qml/island/ApplicationLauncherLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ApplicationLauncherLayer.qml) | Fast desktop application search and launcher. |
| [`qml/island/FileShelfLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/FileShelfLayer.qml) | Drag-and-drop file staging area. |
| [`shell.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/shell.qml) | Root shell definitions, IPC handlers (`overview`, `island`, `tide`), and reload watchers. |
| [`~/.local/bin/dynamic-island`](file:///home/lollo/.local/bin/dynamic-island) | Primary shell launcher setting up `QML_IMPORT_PATH` and running Quickshell. |
| [`~/.scripts/apply-qs-bar.sh`](file:///home/lollo/.scripts/apply-qs-bar.sh) | Hot switcher and clean reloader for `dynamic-island` and `cealestia`. |
| [`~/.scripts/shell-dispatcher.sh`](file:///home/lollo/.scripts/shell-dispatcher.sh) | Bash dispatcher translating global Hyprland keybinds into Quickshell IPC calls. |

---

## 4. Keybindings & IPC Cheatsheet

All actions are mapped in `~/.config/hypr/moduli/binds.lua` and dispatched via `~/.scripts/shell-dispatcher.sh`:

| Action | Hyprland Keybind / Trigger | Dispatcher / IPC Call |
| :--- | :--- | :--- |
| **Power Menu (Wlogout)** | `shell-dispatcher.sh power` | `quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island togglePowerMenu` |
| **Control Center** | `SUPER + SHIFT + C` | `shell-dispatcher.sh control-center` (`call tide toggleControlCenter`) |
| **Settings App** | `shell-dispatcher.sh settings` | `quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island toggleSettingsApp` |
| **Wallpaper Carousel** | `SUPER + ALT + space` | `shell-dispatcher.sh master-or-wallpaper` (`call tide toggleWallpaperPicker`) |
| **Clipboard History** | `SUPER + C` | `shell-dispatcher.sh clipboard` (`call tide toggleClipboard`) |
| **Toggle Island Bar** | `SUPER + W` or `SUPER + F` | `shell-dispatcher.sh toggle-bar` |
| **Reload Island Bar** | Terminal command | `~/.scripts/apply-qs-bar.sh dynamic-island` |

---

## 5. Working Rules & Critical Constraints

1. **Repository Cleanliness**:
   - Ensure personal custom local files are excluded from git.
2. **Repository & Runtime Config Synchronization**:
   Always keep files in sync between the git repository (`/home/lollo/Progetti/dynamic-island-hyprland/`) and the active runtime config directory (`~/.config/quickshell/dynamic-island/`). Whenever changes are made, copy them over and test:
   ```bash
   cp -v DynamicIslandWindow.qml ~/.config/quickshell/dynamic-island/
   cp -v qml/island/TrayFloatingIsland.qml ~/.config/quickshell/dynamic-island/qml/island/
   ~/.scripts/apply-qs-bar.sh dynamic-island
   ```
3. **Compiling & Updating the C++ Backend**:
   If changes are made to `backend/` or `lyricsmpris/`:
   ```bash
   cd /home/lollo/Progetti/dynamic-island-hyprland
   ./install.sh # installs rootless to ~/.local
   ~/.scripts/apply-qs-bar.sh dynamic-island
   ```
4. **Detached Process Execution**:
   Never use short-lived QML `Process` items for tasks that outlive the active QML layer (such as applying themes or system changes). Always use `Quickshell.execDetached([...])`.
5. **Visual Language**:
   Maintain the dark matte glass aesthetic (`#0c0e14`, `#12151f`, 32px-36px corner radius, Pywal accent borders, FontAwesome / JetBrains Mono NF glyphs).
