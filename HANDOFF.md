# Dynamic Island Hyprland — Project Handoff Document

> **Last Updated**: 2026-09-23  
> **Repository**: `/home/lollo/Progetti/dynamic-island-hyprland` (Branch: `main`)  
> **Active Runtime Config**: `/home/lollo/.config/quickshell/dynamic-island`  
> **OS & Environment**: Arch Linux, Hyprland (All-AMD), Waybar ('Cealestia' theme) & Quickshell ('dynamic-island'), Pywal16 + Iris color scheme generation.

---

## 1. Executive Summary & Purpose

This project is a native, highly animated **Dynamic Island & Control Center** shell written in **QML / Quickshell (Qt 6)** for Hyprland on Arch Linux. It provides an iOS-style dynamic pill anchored at the top center of the screen that smoothly morphs across interactive modes:
- **Compact Bar / Resting Capsule**: Standard clock, workspace indicators, battery percentage, media playback pill, custom OSD.
- **Control Center (`control_center`)**: macOS/iOS-styled Control Center containing quick toggles, interactive volume & brightness sliders, media card, notifications, and custom modular widgets.
- **Settings App (`settings_app`)**: Standalone, floating 980x680 window with 5 categories (`Bar & Island`, `Control Center`, `Appearance`, `Motion & Animation`, `Modules`) and live JSON persistence to `~/.config/dynamic-island/userconfig.json`.
- **Studio Layout Canvas**: Visual drag-and-drop grid customizer embedded in the Settings App Control Center tab, allowing 4-corner resizing, single-click height adjustments, and real-time layout sync.
- **Power Menu / Wlogout (`power_menu`)**: Dedicated 340x92 pill capsule with 4 circular glass buttons (Lock, Sleep, Restart, Shutdown) featuring color-accented hover effects, tactile click feedback, and instant dismiss (`Escape` or click outside).
- **Clipboard Manager (`clipboard`)**: Apple Intelligence-style masonry grid previewing text snippets and image clips from `cliphist`.
- **Wallpaper Picker (`wallpaper_picker`)**: 3D coverflow carousel browsing `/home/lollo/Sfondi` with live thumbnail generation and Pywal16 color regeneration via `apply-wallpaper.sh`.
- **Application Launcher & File Shelf**: Spotlight-like fuzzy app launcher and drag-and-drop staging shelf.

---

## 2. Recent Accomplishments & Bug Fixes

### A. Dedicated Power Menu / Wlogout Layer & Animation Fix ("Coso del wlogout")
- **Issue**: Triggering the island power menu (`shell-dispatcher.sh power` / `togglePowerMenu`) resulted in a glitchy, jarring animation: the capsule would jump to full Control Center height (~420px), flash Control Center sliders and tiles for a brief moment, snap down to 150px, and abruptly vanish on close without smooth fading.
- **Root Causes Identified**:
  1. The power view was previously embedded as a boolean sub-view (`powerViewActive`) within the heavy `ControlCenterLayer.qml`.
  2. In `DynamicIslandWindow.qml`, `targetHeight` evaluated to 420px while the loader was initializing before switching to 150px, causing the height bounce.
  3. Closing the menu flipped `powerViewActive = false` before closing the capsule, causing the entire Control Center UI to flash into view.
  4. Buttons were housed in a 150px container with no opacity transition, popping in abruptly.
- **Fix Applied**:
  1. Built a dedicated, lightweight [`PowerMenuLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/PowerMenuLayer.qml) with smooth opacity/scale transitions, circular glass action buttons (Lock, Sleep, Restart, Shutdown), hover colors, Escape key dismissal, and auto-collapse timer.
  2. Promoted power menu to a first-class state (`islandState === "power_menu"`) in [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) with native 340x92 pill geometry and smooth `Easing.OutQuint` morph transitions directly to/from resting capsule.
  3. Cleaned up obsolete sub-view hacks from [`ControlCenterLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlCenterLayer.qml) and added `closeRequested` signal for Escape key dismissal.

### B. Studio Layout Canvas Embedded in Control Center Tab
- **Requirement**: Move Studio Canvas from a separate left-sidebar tab into the "Control Center" tab inside the Settings App ([`SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml)), giving the user a segmented switcher between canvas customization and standard toggles.
- **Implementation**:
  - Cleaned up `categories` list model in `SettingsAppLayer.qml` to 5 primary tabs: `Bar & Island`, `Control Center`, `Appearance`, `Motion & Animation`, `Modules`.
  - Added top segmented pill switch in Control Center view: `[ 󰆧 Studio Canvas & Griglia ]` vs `[ 󰕮 Moduli & Interruttori ]`.
  - Integrated `StudioLayoutCanvas` seamlessly with active grid state, live synchronization, and drag-and-drop module layout.

### C. Settings App Geometry & Bottom-Left Clipping Fix
- **Requirement**: Enlarge the Settings App so it doesn't feel cramped, and fix the half-cut bottom-left badge ("Live Synced ↻").
- **Implementation**:
  - Resized window from **840x560** to **980x680** in both [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) and [`SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml).
  - Fixed sidebar layout: Replaced bottom Column spacer with an explicitly anchored `sidebarFooter` (`anchors.bottom: parent.bottom; anchors.bottomMargin: 18; anchors.leftMargin: 16`), positioning the status badge safely above the window's 32px corner radius.

### D. Wallpaper Picker Execution Fix ("Coso per cambiare lo sfondo")
- **Issue**: Selecting a wallpaper in the Dynamic Island carousel did not reliably trigger `/home/lollo/.scripts/apply-wallpaper.sh`, leaving the wallpaper unchanged.
- **Root Causes & Fix**:
  - In `qml/island/WallpaperPickerLayer.qml`, dynamic QML array binding for `Process.command` didn't re-evaluate before process launch, and unloading the layer terminated child `Process` objects.
  - Replaced with `Quickshell.execDetached(["/home/lollo/.scripts/apply-wallpaper.sh", filePath])`.
  - Added path validation in `/home/lollo/.scripts/apply-wallpaper.sh` and backgrounded `sudo update_sddm.sh &`.

### E. IPC Dispatcher & Methods Alignment
- Synchronized `toggleSettingsApp`, `showSettingsApp`, `togglePowerMenu`, `showPowerMenu`, `setSettingsCategory`, and `setSettingsSubView` across both `IpcHandler { target: "island" }` and `IpcHandler { target: "tide" }` in [`shell.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/shell.qml).
- Ensured `/home/lollo/.scripts/shell-dispatcher.sh` reliably invokes the proper IPC methods.

### F. Dynamic Grid Flow, Instant Sliders & Free-Form Sizing
- Replaced the hardcoded static `Column` in `ControlCenterLayer.qml` with a reactive `Flow` and modular `Component` loaders for all 9 modules (`header`, `wifi`, `bluetooth`, `brightness`, `volume`, `notifications`, `battery`, `toggles`, `quickactions`).
- Removed `Behavior on displayedBrightness` and `displayedVolume` to eliminate slider lag and provide zero-latency tracking.
- Fixed module height resize jitter by mapping handle coordinates to static `stageContainer`.
- Added dedicated `−` and `+` single-click height adjustment buttons in the floating `infoPill`.

### G. Clipboard Empty State, Liquid Glass Image Scrim & Trash Can Icons
- **Clipboard Empty State**: Removed the circular tag icon and the lengthy "Siri Cards" subtitle from [`ClipboardLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ClipboardLayer.qml), replacing it with clean, minimal text ("Nessun elemento copiato" / "Nessun risultato trovato").
- **Liquid Glass Gradient for Images**: Image cards in [`ClipboardLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ClipboardLayer.qml) now fill the card surface smoothly with a dedicated dark `#0f1117` liquid glass multi-stop gradient rising from the bottom up to several pixels above the file title, ensuring high contrast and seamless Apple Intelligence styling.
- **Trash Can Icon Standardization**: Replaced legacy `✕` and rotated plus delete markers across the system with the clean FontAwesome / Nerd Font trash can glyph (`\uf2ed` / ``):
  - In [`ClipboardLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ClipboardLayer.qml) card hover delete button.
  - In [`FileShelfLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/FileShelfLayer.qml) staged file delete button.
  - In [`NotificationCard.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/NotificationCard.qml) quick dismiss action.
### H. Dedicated Power Menu Cealestia Execution Fix & 5-Action Parity
- **Root Cause Identified**: `PowerMenuLayer.qml` previously used short-lived QML `Process` elements. When clicking a button, `root.closeRequested()` immediately unloaded the layer, terminating the child processes before the OS kernel or systemd received the commands.
- **Cealestia Detached Execution**: Ported the exact execution paradigm from Cealestia's `shell.qml` using `Quickshell.execDetached(["bash", "-c", "nohup setsid " + cmd + " >/dev/null 2>&1 &"])`, ensuring commands run detached in the background without being affected by QML component lifecycle.
- **5 Cealestia Actions**:
  1. `Blocca`: `/home/lollo/.scripts/qslock-wrapper.sh` (Key: `L`)
  2. `Esci`: `hyprctl dispatch exit` (Key: `E`)
  3. `Sospendi`: `systemctl suspend` (Key: `U`)
  4. `Riavvia`: `systemctl reboot` (Key: `R`)
  5. `Spegni`: `systemctl poweroff` (Key: `S`)
- **Geometry**: Adjusted pill width from `340px` to `380px` in [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) to perfectly accommodate all 5 glass buttons with balanced padding and micro-interactions.

---

## 3. Architecture & File Structure

| File Path | Description |
| :--- | :--- |
| [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) | Core layer-shell window, state machine (`islandState`), size calculations, morph animations, and dynamic component loaders. |
| [`qml/island/PowerMenuLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/PowerMenuLayer.qml) | Dedicated 5-button power & session menu (Lock, Logout, Sleep, Restart, Shutdown) with Cealestia detached execution, keyboard hotkeys, and glass styling. |
| [`qml/controlcenter/SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml) | Standalone 980x680 Settings App with category sidebar, segmented Studio switcher, and JSON IO. |
| [`qml/controlcenter/StudioLayoutCanvas.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/StudioLayoutCanvas.qml) | Visual drag/drop grid canvas for sizing and positioning Control Center cards. |
| [`qml/controlcenter/ControlCenterLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlCenterLayer.qml) | Expanded Control Center overlay with cards, volume/brightness sliders, and network controls. |
| [`qml/island/WallpaperPickerLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/WallpaperPickerLayer.qml) | PathView 3D coverflow carousel browsing wallpapers with instant thumbnail caching and pywal triggers. |
| [`qml/island/ClipboardLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ClipboardLayer.qml) | Apple Intelligence-style masonry cards previewing `cliphist` text and image clips. |
| [`qml/island/ApplicationLauncherLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ApplicationLauncherLayer.qml) | Fast desktop application search and launcher. |
| [`qml/island/FileShelfLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/FileShelfLayer.qml) | Drag-and-drop file staging area. |
| [`shell.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/shell.qml) | Root shell definitions, IPC handlers (`overview`, `island`, `tide`), and reload watchers. |
| `/home/lollo/.scripts/shell-dispatcher.sh` | Bash dispatcher translating global Hyprland keybinds into Quickshell IPC calls. |
| `/home/lollo/.scripts/apply-wallpaper.sh` | Main script applying wallpaper via `awww`, updating `iris`, `wal`, `gtk`, `qt6ct`, `swaync`, and `sddm`. |
| `/home/lollo/.scripts/apply-qs-bar.sh` | Hot switcher and clean reloader for `dynamic-island`. |

---

## 4. Keybindings & IPC Cheatsheet

All actions are mapped in `/home/lollo/.config/hypr/moduli/binds.lua` and dispatched via `/home/lollo/.scripts/shell-dispatcher.sh`:

| Action | Hyprland Keybind / Trigger | Dispatcher / IPC Call |
| :--- | :--- | :--- |
| **Power Menu (Wlogout)** | `shell-dispatcher.sh power` | `quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island togglePowerMenu` |
| **Control Center** | `SUPER + SHIFT + C` | `shell-dispatcher.sh control-center` (`call tide toggleControlCenter`) |
| **Settings App** | `shell-dispatcher.sh settings` | `quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call island toggleSettingsApp` |
| **Wallpaper Carousel** | `SUPER + ALT + space` | `shell-dispatcher.sh master-or-wallpaper` (`call tide toggleWallpaperPicker`) |
| **Clipboard History** | `SUPER + C` | `shell-dispatcher.sh clipboard` (`call tide toggleClipboard`) |
| **Theme Switcher** | `SUPER + T` | `/home/lollo/.scripts/qs-theme-switcher.sh` |
| **Toggle Island Bar** | `SUPER + W` or `SUPER + F` | `/home/lollo/.scripts/shell-dispatcher.sh toggle-bar` |
| **Reload Island Bar** | Terminal command | `/home/lollo/.scripts/apply-qs-bar.sh dynamic-island` |

---

## 5. Working Rules & Critical Constraints

1. **Repository Synchronization**:
   Always keep files in sync between the git repository (`/home/lollo/Progetti/dynamic-island-hyprland/`) and the active runtime config directory (`~/.config/quickshell/dynamic-island/`). Whenever changes are made in the repo, copy them over and test:
   ```bash
   cp -v DynamicIslandWindow.qml ~/.config/quickshell/dynamic-island/
   cp -v qml/island/PowerMenuLayer.qml ~/.config/quickshell/dynamic-island/qml/island/
   cp -v qml/controlcenter/ControlCenterLayer.qml ~/.config/quickshell/dynamic-island/qml/controlcenter/
   /home/lollo/.scripts/apply-qs-bar.sh dynamic-island
   ```
2. **Quickshell Reloading**:
   To cleanly reload without leaving orphan background processes, invoke:
   ```bash
   /home/lollo/.scripts/apply-qs-bar.sh dynamic-island
   ```
3. **Detached Process Execution**:
   Never use short-lived QML `Process` items for tasks that outlive the active QML layer (such as applying themes or system changes). Always use `Quickshell.execDetached([...])`.
4. **Visual Language**:
   Maintain the dark matte glass aesthetic (`#0c0e14`, `#12151f`, 32px-36px corner radius, Pywal accent borders, FontAwesome / JetBrains Mono NF glyphs).

---

## 6. Pending User Directives & Future Tasks

1. **Upcoming App Redesign**:
   - The user noted: *"poi dobbiamo rifare un redesign dell'app di nuovo ma non adesso"* (we need to do a redesign of the app again, but not right now).
   - Wait for explicit user instructions before modifying the visual styling or layout paradigms of the Settings App or Control Center.
2. **Removal of Legacy Tide References & Symlink**:
   - The user requested: *"togli il symlink voglio solo che sia quella nostra tutto cio che sta di tide toglilo ma aspetta che devo fare alcuni screenshot dell'app che mi servono a rifare l'app"*.
   - **Status**: The `tide-island -> dynamic-island` symlink is currently preserved while the user takes screenshots. Once the user confirms they are ready, clean up legacy `tide-island` symlinks and references.

---

## 7. Recommended Skills for Subsequent Agents

- **`codebase-design`**: Use when designing new modular components, refining QML seams, or updating the Studio Layout Canvas.
- **`diagnosing-bugs`**: Use if layout warnings, IPC timeouts, or state mismatches occur.
- **`writing-for-agents`**: Use when updating `HANDOFF.md`, skills, or documentation.
- **`caveman`** & **`ponytail`**: Channel concise communication and minimal, robust solutions adhering to standard platform primitives.
