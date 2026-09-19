# Dynamic Island Hyprland — Project Handoff Document

> **Generated**: 2026-09-18  
> **Repository**: `/home/lollo/Progetti/dynamic-island-hyprland` (Branch: `main`)  
> **Active Quickshell Config**: `/home/lollo/.config/quickshell/dynamic-island`  
> **OS & Environment**: Arch Linux, Hyprland (All-AMD), Waybar/Quickshell ('Cealestia' & 'Dynamic Island' themes), Pywal16 + Iris color scheme generation.

---

## 1. Executive Summary & Purpose

This project is a native, highly animated **Dynamic Island & Control Center** shell written in **QML / Quickshell (Qt 6)** for Hyprland. It provides an iOS-style dynamic pill in the top center of the screen that smoothly expands into various interactive modes:
- **Compact Bar / Capsule**: Normal clock, workspace status, battery, media pill.
- **Control Center (`control_center`)**: macOS / iOS styled Control Center with toggles, brightness, volume sliders, media card, and custom studio widgets.
- **Settings App (`settings_app`)**: Standalone, floating 980x680 settings customizer window with 5 categories (`Bar & Island`, `Control Center`, `Appearance`, `Motion & Animation`, `Modules`), live JSON persistence to `~/.config/tide-island/userconfig.json`.
- **Studio Layout Canvas**: Integrated within the Control Center category in Settings, allowing visual grid layout customization of cards (drag, drop, snap-to-grid, 4-corner resize handles).
- **Clipboard Manager (`clipboard`)**: Siri / Apple Intelligence masonry cards previewing text snippets and image thumbnails from `cliphist`.
- **Wallpaper Picker (`wallpaper_picker`)**: 3D coverflow carousel browsing `/home/lollo/Sfondi` with live thumbnail generation and pywal-driven theming.
- **Application Launcher & File Shelf**: Spotlight-style app search and drag-and-drop file staging shelf.

---

## 2. Recent Accomplishments & Key Fixes

### A. Studio Layout Canvas Embedded in Control Center Tab
- **Requirement**: Move Studio Canvas from a separate left-sidebar tab into the "Control Center" tab inside the Settings App (`qml/controlcenter/SettingsAppLayer.qml`), giving the user a segmented switcher between canvas customization and standard toggles.
- **Implementation**:
  - Cleaned up `categories` list model in `SettingsAppLayer.qml` to 5 primary tabs: `Bar & Island`, `Control Center`, `Appearance`, `Motion & Animation`, `Modules`.
  - Added top segmented pill switch in Control Center view: `[ 󰆧 Studio Canvas & Griglia ]` vs `[ 󰕮 Moduli & Interruttori ]`.
  - Integrated `StudioLayoutCanvas` seamlessly with active grid state, live synchronization, and drag-and-drop module layout.

### B. Settings App Geometry & Bottom-Left Clipping Fix
- **Requirement**: Enlarge the Settings App so it doesn't feel cramped, and fix the half-cut bottom-left badge ("Live Synced ↻").
- **Implementation**:
  - Resized window from **840x560** to **980x680** in both `DynamicIslandWindow.qml` (lines 2755, 2800) and `SettingsAppLayer.qml`.
  - Fixed sidebar layout: Replaced the bottom Column spacer with an explicitly anchored `sidebarFooter` (`anchors.bottom: parent.bottom; anchors.bottomMargin: 18; anchors.leftMargin: 16`), safely positioning the status badge well above the window's 32px rounded corner curve.

### C. Wallpaper Picker Execution Fix ("Coso per cambiare lo sfondo")
- **Issue**: Selecting a wallpaper in the Dynamic Island carousel did not reliably trigger `/home/lollo/.scripts/apply-wallpaper.sh`, leaving the wallpaper unchanged.
- **Root Causes Identified**:
  1. In `qml/island/WallpaperPickerLayer.qml`, `customApplyProcess` relied on QML dynamic property binding for its argument `command: ["/home/lollo/.scripts/apply-wallpaper.sh", wallpaperPath]`. In Quickshell, assigning `wallpaperPath = filePath` does not synchronously regenerate the QML Array binding before `running = true`, causing it to execute with an empty argument.
  2. When the Dynamic Island closed or unloaded the layer via `Loader { active: false }`, child `Process` items were terminated by Qt before `apply-wallpaper.sh` (which executes `iris`, `wal`, `hyprctl`, and `update_sddm.sh`) could complete.
- **Fix Applied**:
  - In `qml/island/WallpaperPickerLayer.qml`, updated `applyWallpaper(filePath)` to execute via `Quickshell.execDetached(["/home/lollo/.scripts/apply-wallpaper.sh", filePath])`. This executes as a detached OS process independent of QML component lifecycles.
  - Added path validation in `/home/lollo/.scripts/apply-wallpaper.sh` (`[ -z "$FULL_PATH" ] || [ ! -f "$FULL_PATH" ]`).
  - Backgrounded `sudo update_sddm.sh &` inside `apply-wallpaper.sh` so desktop theming updates immediately without blocking.
  - Also synchronized the Quickshell `theme-switcher` (`~/.config/quickshell/theme-switcher/shell.qml`) to use `Quickshell.execDetached` directly.

### D. IPC Dispatcher & Methods Alignment
- Added `toggleSettingsApp`, `showSettingsApp`, `setSettingsCategory`, and `setSettingsSubView` to both `IpcHandler { target: "island" }` and `IpcHandler { target: "tide" }` in `shell.qml`.
- Ensured `/home/lollo/.scripts/shell-dispatcher.sh settings` reliably invokes `call_island tide toggleSettingsApp`.

### E. Fully Dynamic Studio Canvas Control Center Layout & Instant Sliders
- Replaced the hardcoded static `Column` in `ControlCenterLayer.qml` with a reactive `Flow` and modular `Component` loaders for all 9 modules (`header`, `wifi`, `bluetooth`, `brightness`, `volume`, `notifications`, `battery`, `toggles`, `quickactions`).
- Removed `Behavior on displayedBrightness` and `Behavior on displayedVolume` to eliminate slider lag/animation, giving crisp and instantaneous slider tracking.
- Implemented interactive drag-and-drop live reordering in `StudioLayoutCanvas.qml`.

### F. Free Form Sizing, Height Adjustment Fix, & Token-Saving Skills
- **Removed Fixed Presets**: Removed "Compatto (420) / Ampio (540)" segmented toggle from `StudioLayoutCanvas.qml` top bar. Users can freely arrange modules and adjust dimensions without rigid preset constraints.
- **Fixed Module Height Resizing**:
  - Identified root cause of resize handle bug: `onPositionChanged` in `topHandleMouse` / `bottomHandleMouse` was measuring local coordinates against a moving handle and lacked a fixed reference frame, causing jitter and exponential jumps.
  - Fixed by mapping coordinates to static `stageContainer` via `mapToItem(stageContainer, mouse.x, mouse.y).y`.
  - Relaxed `maxHeight` restrictions (from 80px up to 260–320px) across all module defaults and `initializeFromConfig()`.
  - Added dedicated `−` and `+` single-click height adjustment buttons in the floating `infoPill` for fast, accurate nudging.
  - Updated `ControlCenterLayer.qml` (`slotHeight`, `wifiComponent`, `bluetoothComponent`, `batteryComponent`) and `ControlSliderCard.qml` to adapt gracefully and dynamically to custom heights without clipping.
- **Installed Skills for Token Optimization**:
  - `caveman` (`~/.agents/skills/caveman/SKILL.md`): Ultra-concise, filler-free communication mode that saves 60-70% conversation output tokens while preserving 100% technical fidelity, code correctness, and clickable links.
  - `ponytail` (`~/.agents/skills/ponytail/SKILL.md`): Pragmatic senior developer mindset emphasizing the "Laziness Ladder" (YAGNI, standard platform primitives, minimal diffs, anti-overengineering).

### G. Wlogout / Power Menu Animation Fix ("Coso del wlogout della isola")
- **Issue**: Toggling the island's power/wlogout menu (`shell-dispatcher.sh power` / `togglePowerMenu`) produced a glitchy, bouncing animation where the capsule momentarily expanded to full Control Center height (~420px), flashed Control Center tiles/sliders, jerked down to 150px, and abruptly disappeared on close.
- **Root Causes**:
  1. The power view was embedded as a subview (`powerViewActive`) within the heavy `ControlCenterLayer.qml`.
  2. In `DynamicIslandWindow.qml`, `targetHeight` fell back to `420` before the loader initialized, triggering a bounce from 420px to 150px.
  3. Closing the menu flipped `powerViewActive = false` before closing the capsule, flashing Control Center cards on screen.
  4. The 4 buttons were in a 150px tall container with no opacity fade, causing abrupt pop-in.
- **Fix Applied**:
  1. Created a dedicated lightweight [`PowerMenuLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/PowerMenuLayer.qml) with smooth fade/scale transitions, circular glass action buttons (Lock, Sleep, Restart, Shutdown), hover colors, Escape key dismissal, and auto-collapse timer.
  2. Promoted power menu to a first-class island state (`islandState === "power_menu"`) in [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) with native 340x92 pill geometry and smooth `Easing.OutQuint` morph animations.
  3. Cleaned up dead subview hacks from [`ControlCenterLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlCenterLayer.qml) and added `closeRequested` signal for Escape key dismissal.

---

## 3. Architecture & File Reference

| File Path | Description |
| :--- | :--- |
| `DynamicIslandWindow.qml` | Core layer-shell window, state machine (`islandState`), size calculations, morph animations, and dynamic component loaders. |
| `qml/controlcenter/SettingsAppLayer.qml` | The 980x680 Settings App. Contains sidebar navigation, live controls, JSON config IO, and the embedded Studio Canvas switcher. |
| `qml/controlcenter/StudioLayoutCanvas.qml` | The visual drag/drop grid canvas for positioning Control Center cards. |
| `qml/controlcenter/ControlCenterLayer.qml` | The expanded Control Center overlay with cards, volume/brightness sliders, and network controls. |
| `qml/island/WallpaperPickerLayer.qml` | PathView 3D coverflow carousel browsing wallpapers with instant thumbnail caching and pywal triggers. |
| `qml/island/ClipboardLayer.qml` | Apple Intelligence-style masonry cards previewing `cliphist` text and image clips. |
| `qml/island/ApplicationLauncherLayer.qml` | Fast desktop application search and launcher. |
| `qml/island/FileShelfLayer.qml` | Drag-and-drop file staging area. |
| `shell.qml` | Root shell definitions, IPC handlers (`overview`, `island`, `tide`), and reload watchers. |
| `/home/lollo/.scripts/shell-dispatcher.sh` | Bash dispatcher translating global Hyprland keybinds into Quickshell IPC calls. |
| `/home/lollo/.scripts/apply-wallpaper.sh` | Main script applying wallpaper via `awww`, updating `iris`, `wal`, `gtk`, `qt6ct`, `swaync`, and `sddm`. |
| `/home/lollo/.scripts/apply-qs-bar.sh` | Hot switcher between `dynamic-island` and `cealestia` bars. |

---

## 4. Keybindings & IPC Cheatsheet

All actions are mapped in `/home/lollo/.config/hypr/moduli/binds.lua` and dispatched via `/home/lollo/.scripts/shell-dispatcher.sh`:

- **Settings App**: `shell-dispatcher.sh settings` or `quickshell ipc --any-display -p ~/.config/quickshell/dynamic-island call tide toggleSettingsApp`
- **Wallpaper Carousel**: `SUPER + ALT + space` -> `shell-dispatcher.sh master-or-wallpaper` -> `call tide toggleWallpaperPicker`
- **Theme Switcher Modal**: `SUPER + T` -> `/home/lollo/.scripts/qs-theme-switcher.sh`
- **Clipboard History**: `SUPER + C` -> `shell-dispatcher.sh clipboard` -> `call tide toggleClipboard`
- **Control Center**: `SUPER + SHIFT + C` -> `shell-dispatcher.sh control-center` -> `call tide toggleControlCenter`
- **Bar Switcher / Reload**: `/home/lollo/.scripts/apply-qs-bar.sh dynamic-island`
- **Toggle Island Bar**: `SUPER + W` or `SUPER + F`

---

## 5. Working Rules & Critical Constraints

1. **Repository Synchronization**:
   Always keep files in sync between the git repository (`/home/lollo/Progetti/dynamic-island-hyprland/`) and the active runtime config directory (`~/.config/quickshell/dynamic-island/`). Any edits made in one must be mirrored to the other.
2. **Quickshell Reloading**:
   To cleanly reload without orphan processes, invoke:
   ```bash
   /home/lollo/.scripts/apply-qs-bar.sh dynamic-island
   ```
3. **Detached Process Execution**:
   Never use short-lived QML `Process` objects for tasks that outlive the active QML layer (such as applying themes or launching background scripts). Always use `Quickshell.execDetached([...])`.
4. **Visual Language**:
   Maintain the dark matte glass aesthetic (`#0c0e14`, `#12151f`, 32px corner radius, Pywal accent borders, FontAwesome / JetBrains Mono NF icons).

---

## 6. Suggested Skills for the Next Agent

When picking up the next session, invoke the following skills based on the task:
- **`codebase-design`**: Use when modifying module seams, extending the Studio Layout Canvas serialization, or adding new modular cards to the Dynamic Island.
- **`diagnosing-bugs`**: Use if any IPC handler fails to trigger or if any Quickshell layout warnings appear in `journalctl` / console logs.
- **`writing-for-agents`**: Use when writing or updating documentation, guidelines, or skill configurations for agent workflows.
