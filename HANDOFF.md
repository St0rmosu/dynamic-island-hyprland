# Dynamic Island Hyprland — Project Handoff Document

> **Last Updated**: 2026-09-27  
> **Repository**: `/home/lollo/Progetti/dynamic-island-hyprland` (Branch: `main`)  
> **Active Runtime Config**: `/home/lollo/.config/quickshell/dynamic-island`  
> **Config Directory**: `/home/lollo/.config/dynamic-island`  
> **OS & Environment**: Arch Linux, Hyprland (All-AMD), Waybar ('Cealestia' theme) & Quickshell ('dynamic-island'), Pywal16 + Iris color scheme generation.  
> **Strict Git Exclusion**: `ThemeFloatingIsland.qml` (private custom switcher pill) must NEVER be committed to GitHub. All other shell features, scripts, and installer enhancements are committed upstream.

---

## 1. Executive Summary & Purpose

This project is a native, highly animated **Dynamic Island & Control Center** shell written in **QML / Quickshell (Qt 6)** and native **C++** for Hyprland on Arch Linux. It provides an iOS-style dynamic pill anchored at the top center of the screen that smoothly morphs across interactive modes:
- **Compact Bar / Resting Capsule**: Standard clock, workspace indicators, battery percentage, media playback pill, Bluetooth peripheral satellite, custom OSD.
- **Control Center (`control_center`)**: macOS/iOS-styled Control Center containing quick toggles, interactive volume & brightness sliders, media card, notifications, and custom modular widgets.
- **Settings App (`settings_app`)**: Standalone, floating 980x680 window with 5 categories (`Bar & Island`, `Control Center`, `Appearance`, `Motion & Animation`, `Modules`) and live JSON persistence to `~/.config/dynamic-island/userconfig.json`.
- **Studio Layout Canvas**: Visual drag-and-drop grid customizer embedded in the Settings App Control Center tab, allowing 4-corner resizing, single-click height adjustments, and real-time layout sync.
- **Power Menu / Wlogout (`power_menu`)**: Dedicated 420x96 pill capsule with 5 circular glass buttons (Lock, Logout, Sleep, Restart, Shutdown) featuring Iris palette hover effects, tactile click feedback, and instant dismiss (`Escape` or click outside).
- **Clipboard Manager (`clipboard`)**: Apple Intelligence-style masonry grid previewing text snippets and image clips from `cliphist`.
- **Wallpaper Picker (`wallpaper_picker`)**: 3D coverflow carousel browsing `/home/lollo/Sfondi` with live thumbnail generation and Pywal16 color regeneration via `apply-wallpaper.sh`.
- **System Tray Satellite Pill (`TrayFloatingIsland`)**: Independent floating pill positioned 8px directly below the Control Center, rendering background status notifier items with unread indicators and context menus.
- **Nothing Ear (a) Peripheral Card (`HeadphonesFloatingIsland`)**: Compact docked satellite pill with connection indicator and full expandable management card with per-earbud/case battery levels, ANC modes, LDAC codec, and Bass Boost.
- **Expanded Media Player & Synced Lyrics**: Concentric player card with live MPRIS album art, progress scrubber, and real-time synced lyrics powered by the native `lyricsmpris` C++ daemon.

---

## 2. Recent Major Accomplishments & Milestone Fixes (2026-09-27)

### A. Nothing Ear (a) Bluetooth Satellite & Expanded Control Card
- **Implementation**:
  - Integrated [`qml/island/HeadphonesFloatingIsland.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/HeadphonesFloatingIsland.qml) supporting Nothing Ear (a) Bluetooth earbuds via BlueZ and `~/.scripts/nothing-ear-ctl.py`.
  - **Compact State**: 38x38 circular satellite pill docked to the right of the clock (`anchors.left: targetCapsule.right`, `margin: 7`) with a custom earbuds icon and accent connection dot.
  - **Automatic Satellite Balancing**: Evaluates cluster extent and recalculates center of mass to slide the island horizontally by ~22.5px, maintaining visual symmetry at 50% screen center.
  - **Expanded State**: 380px wide card with hero image, Left/Right/Case battery gauges, ANC switch (Off, Noise Cancellation, Transparency), Bass Boost (levels 1-5), and Low Latency Game Mode.
  - Added IPC controls `toggleHeadphones` and `setHeadphonesHidden` in [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) and [`shell.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/shell.qml).
  - Captured clean 60 FPS showcase assets: [`assets/gifs/headphones_compact_island.gif`](file:///home/lollo/Progetti/dynamic-island-hyprland/assets/gifs/headphones_compact_island.gif) and [`assets/gifs/expanded_headphones.gif`](file:///home/lollo/Progetti/dynamic-island-hyprland/assets/gifs/expanded_headphones.gif).

### B. Screencopy & Screen Recording Fix (`no_screen_share`)
- **Problem**: When capturing screenshots (`grim`) or recording video (`wf-recorder`), the island appeared as a solid black rectangle or was missing entirely.
- **Root Cause**: In [`~/.config/hypr/moduli/rules.lua`](file:///home/lollo/.config/hypr/moduli/rules.lua), `no_screen_share = true` is set for `dynamic-island` to protect privacy during screen shares. This rule deliberately clears layer-shell buffers from `wlr-screencopy`.
- **Solution**: Automated in Python scripts: temporarily toggling `no_screen_share = false` during recording runs within a `try...finally` block, ensuring `no_screen_share = true` is 100% restored after execution.

### C. Expanded Media Player Centering & Concentric Button Refinement
- **Problem**: The expanded media player GIF previously appeared cropped and "storta" (missing cover art and artist name on the left), and the lyrics toggle button right edge had an abrupt angular boundary.
- **Fix**:
  - `MusicFloatingIsland` anchors to the left of the main capsule, expanding from ~470px to ~880px X coordinate. The recording geometry was recalibrated to `440,0 660x200` to capture the entire player, album art, timeline scrubber, and adjacent clock capsule.
  - Refined the lyrics toggle button right corner radius to match concentric card curves.
  - Removed arbitrary lyric line truncation (`...`), ensuring full sentences are legible in live MPRIS lyrics mode.

### D. Hardware Alerts & Notifications Regeneration (No Spotify Artifacts)
- **Problem**: In earlier recording batches, Spotify was playing in the background to showcase media features, causing the music visualizer bubble to appear docked on the left of every hardware alert (Charging, Low Battery, Silent, Ring, Volume, Brightness) and notification.
- **Fix**:
  - Created [`scripts/record_clean_alerts.py`](file:///home/lollo/Progetti/dynamic-island-hyprland/scripts/record_clean_alerts.py) with Spotify terminated, `setHeadphonesHidden(true)`, and cursor parked off-screen (`hl.dsp.cursor.move({ x = 0, y = 1000 })`).
  - Regenerated all 11 alert and notification assets at 60 FPS:
    - Hardware: `charging_demo`, `charging.png`, `low_battery`, `silent_mode`, `ring_mode`, `osd_volume`, `osd_brightness`.
    - System & Communications: `workspace_switch`, `wifi_disconnect`, `desktop_notification`, `discord_call_incoming`, `discord_call_ongoing`.
  - All alerts now appear as isolated, centered, authentic Apple Dynamic Island capsules.

### E. README & Asset Hygiene
- **Countdown Timer**: Completely removed from the README and Git repository (`assets/gifs/countdown_timer.gif`, `assets/screenshots/countdown_timer.png`).
- **Custom Info Row**: Removed `custom_info_date.gif` and `custom_info_date.png` from Section 1 of the README, replacing them with the Nothing Ear satellite pill and expanded manager showcase.
- **Section 6 (Media Player)**: Updated to display the expanded player at full width (100%) and compact music pill / live lyrics at 50/50 width.

---

## 3. Architecture & File Structure

| File Path | Description |
| :--- | :--- |
| [`CMakeLists.txt`](file:///home/lollo/Progetti/dynamic-island-hyprland/CMakeLists.txt) | Root CMake build configuration registering Qt6 QML module `IslandBackend` and `lyricsmpris`. |
| [`install.sh`](file:///home/lollo/Progetti/dynamic-island-hyprland/install.sh) | Build and installation script supporting rootless user install (`~/.local/`) and system install (`/usr/`). |
| [`backend/`](file:///home/lollo/Progetti/dynamic-island-hyprland/backend/) | C++ source code for `IslandBackend` (Qt6 C++ plugin for window tracking, system state, bluetooth, user config). |
| [`lyricsmpris/`](file:///home/lollo/Progetti/dynamic-island-hyprland/lyricsmpris/) | C++ daemon for real-time synchronized karaoke-style MPRIS lyrics. |
| [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) | Core layer-shell window, state machine (`islandState`), size calculations, morph animations, and dynamic component loaders. |
| [`qml/island/HeadphonesFloatingIsland.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/HeadphonesFloatingIsland.qml) | Nothing Ear (a) satellite pill and expandable 380px management card with battery, ANC, and codec controls. |
| [`qml/island/TrayFloatingIsland.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/TrayFloatingIsland.qml) | Floating system tray satellite pill underneath Control Center with synchronous opening animation and continuous hover bridge. |
| [`qml/island/PowerMenuLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/PowerMenuLayer.qml) | Dedicated 5-button power & session menu (Lock, Logout, Sleep, Restart, Shutdown) with detached execution and Iris colors. |
| [`qml/controlcenter/SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml) | Standalone 980x680 Settings App with category sidebar, segmented Studio switcher, and JSON IO. |
| [`qml/controlcenter/StudioLayoutCanvas.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/StudioLayoutCanvas.qml) | Visual drag/drop grid canvas for sizing and positioning Control Center cards. |
| [`qml/controlcenter/ControlCenterLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlCenterLayer.qml) | Expanded Control Center overlay with cards, volume/brightness sliders, and network controls. |
| [`qml/island/ScreenSharePickerLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ScreenSharePickerLayer.qml) | Native 620x220 screen share picker dialog with Iris palette, restore token support, and window search. |
| [`qml/island/WallpaperPickerLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/WallpaperPickerLayer.qml) | PathView 3D coverflow carousel browsing wallpapers with instant thumbnail caching and pywal triggers. |
| [`qml/island/ClipboardLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ClipboardLayer.qml) | Apple Intelligence-style masonry cards previewing `cliphist` text and image clips. |
| [`qml/island/ApplicationLauncherLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ApplicationLauncherLayer.qml) | Fast desktop application search and launcher. |
| [`qml/island/FileShelfLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/FileShelfLayer.qml) | Drag-and-drop file staging area. |
| [`shell.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/shell.qml) | Root shell definitions, IPC handlers (`overview`, `island`, `dynamic-island`), and reload watchers. |
| [`scripts/record_headphones.py`](file:///home/lollo/Progetti/dynamic-island-hyprland/scripts/record_headphones.py) | 60 FPS recording utility for compact and expanded Nothing Ear (a) assets. |
| [`scripts/record_clean_alerts.py`](file:///home/lollo/Progetti/dynamic-island-hyprland/scripts/record_clean_alerts.py) | 60 FPS recording utility for hardware alerts and notifications without background media. |

---

## 4. Keybindings & IPC Cheatsheet

All actions are mapped in `~/.config/hypr/moduli/binds.lua` and dispatched via `~/.scripts/shell-dispatcher.sh`:

| Action | Hyprland Keybind / Trigger | Dispatcher / IPC Call |
| :--- | :--- | :--- |
| **Power Menu (Wlogout)** | `shell-dispatcher.sh power` | `quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island togglePowerMenu` |
| **Control Center** | `SUPER + SHIFT + C` | `shell-dispatcher.sh control-center` (`call island toggleControlCenter`) |
| **Settings App** | `shell-dispatcher.sh settings` | `quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island toggleSettingsApp` |
| **Toggle Headphones Card** | CLI / IPC | `quickshell -p ~/.config/quickshell/dynamic-island ipc call island toggleHeadphones` |
| **Wallpaper Carousel** | `SUPER + ALT + space` | `shell-dispatcher.sh master-or-wallpaper` (`call island toggleWallpaperPicker`) |
| **Clipboard History** | `SUPER + C` | `shell-dispatcher.sh clipboard` (`call island toggleClipboard`) |
| **Toggle Island Bar** | `SUPER + W` or `SUPER + F` | `shell-dispatcher.sh toggle-bar` |
| **Reload Island Bar** | Terminal command | `~/.scripts/apply-qs-bar.sh dynamic-island` |

---

## 5. Working Rules & Critical Constraints

1. **Repository Cleanliness**:
   - `ThemeFloatingIsland.qml` is private and must NEVER be committed to upstream git.
2. **Repository & Runtime Config Synchronization**:
   Always keep files in sync between the git repository (`/home/lollo/Progetti/dynamic-island-hyprland/`) and the active runtime config directory (`~/.config/quickshell/dynamic-island/`). Whenever changes are made, copy them over and test:
   ```bash
   cp -v DynamicIslandWindow.qml ~/.config/quickshell/dynamic-island/
   cp -v shell.qml ~/.config/quickshell/dynamic-island/
   cp -v qml/island/HeadphonesFloatingIsland.qml ~/.config/quickshell/dynamic-island/qml/island/
   ~/.scripts/apply-qs-bar.sh dynamic-island
   ```
3. **Screen Sharing Rule Awareness**:
   `no_screen_share = true` in `~/.config/hypr/moduli/rules.lua` obscures the island from screencopy tools. Always toggle it to `false` during asset generation and restore it to `true` when finished.
4. **Moving the Cursor via Hyprland Lua**:
   Hyprland uses a Lua dispatcher. To move the cursor away during recordings:
   ```bash
   hyprctl dispatch 'hl.dsp.cursor.move({ x = 0, y = 1000 })'
   ```
5. **Compiling & Updating the C++ Backend**:
   If changes are made to `backend/` or `lyricsmpris/`:
   ```bash
   cd /home/lollo/Progetti/dynamic-island-hyprland
   ./install.sh # installs rootless to ~/.local
   ~/.scripts/apply-qs-bar.sh dynamic-island
   ```
6. **Detached Process Execution**:
   Never use short-lived QML `Process` items for tasks that outlive the active QML layer (such as applying themes or system changes). Always use `Quickshell.execDetached([...])`.
7. **Visual Language**:
   Maintain the dark matte glass aesthetic (`#0c0e14`, `#12151f`, 32px-36px corner radius, Pywal accent borders, FontAwesome / JetBrains Mono NF glyphs).
