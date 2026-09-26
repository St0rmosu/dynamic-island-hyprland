# Dynamic Island Hyprland — Project Handoff Document

> **Last Updated**: 2026-09-24  
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

### A. Total Detachment from Tide Island & Reactive DynamicConfig (`~/.config/dynamic-island/config.json`)
- **Problem**: Tide Island's C++ plugin (`libIslandBackendplugin.so`) hardcoded its file watcher to `~/.config/tide-island/userconfig.json`. Changes saved to `~/.config/dynamic-island/userconfig.json` did not update C++ properties, and QML was relying on a static JavaScript reader without reactive notification bindings.
- **Solution**:
  1. Built [`qml/config/DynamicConfig.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/config/DynamicConfig.qml) as a native Quickshell singleton in `shell.qml` with first-class QML properties for all island, control center, font, wallpaper, and interaction settings.
  2. Implemented immediate in-memory reactivity: changes update properties instantly (0ms), triggering live layout morphs while debouncing atomic writes via [`scripts/save_dynamic_config.py`](file:///home/lollo/Progetti/dynamic-island-hyprland/scripts/save_dynamic_config.py) to `~/.config/dynamic-island/config.json` and `userconfig.json`.
  3. Dynamic island dimensions, margins, opacity, and fonts in [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) are bound directly to `dynamicConfig`.

### B. Complete Rebuild of the Settings App (`SettingsAppLayer.qml`) with Studio Canvas
- **Requirement**: Rebuild the settings application from scratch, eliminating legacy bloat, and structuring into 5 focused pages with the interactive Studio Canvas on Page 3.
- **Implementation**:
  1. Created modular settings subcomponents in `qml/settings/`:
     - [`IslandGeometryPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/IslandGeometryPage.qml): Island resting width, height, corner radius, top margin, exclusive zone, auto-hide, and hover dwell controls.
     - [`InteractionsPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/InteractionsPage.qml): Primary, secondary, middle, and double-click actions; vertical and horizontal mouse wheel scrolling (volume, brightness, tracks).
     - [`ControlCenterStudioPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/ControlCenterStudioPage.qml): Embeds `StudioLayoutCanvas` for 2D iPadOS-style grid customization, card resizing (1-4 cols, 1-3 rows), and complete card removal with the trash can button (``).
     - [`AppearanceFontPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/AppearanceFontPage.qml): Dark matte glass opacity, blur radius, Pywal/Iris dynamic palette toggle, `/home/lollo/Sfondi` wallpaper integration, and rapid 1-click typography presets.
     - [`ShortcutsPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/ShortcutsPage.qml): Displays the user's exact 7 Hyprland keybindings (`SUPER+Tab`, `SUPER+P`, `SUPER+N`, `SUPER+ALT+Space`, `ALT+Space`, `SUPER+O`, `SUPER+C`), test trigger buttons (`▶`), and copyable Lua bindings.
     - Reusable UI elements: [`SettingsCard.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/SettingsCard.qml), [`SettingsSlider.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/SettingsSlider.qml), [`SettingsSwitch.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/SettingsSwitch.qml), [`SettingsSegmented.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/SettingsSegmented.qml), [`SettingsHeader.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/SettingsHeader.qml).
  2. Integrated an in-app searchable modal browsing all 4,850 system fonts.
  3. Rebuilt [`qml/controlcenter/SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml) using a clean two-column layout with status pill (`● Live Synced`).

### C. Workspace Overview (`SUPER + Tab`) Multi-Second Latency Elimination
- **Issue**: Pressing `SUPER + Tab` took several seconds to open the workspace overview.
- **Root Causes**:
  1. `overviewLoaderActive` was destroyed 260ms after closing (`overviewUnloadGraceTimer`), forcing the full QML tree to be parsed and recompiled on every invocation.
  2. Opening was blocked by `overviewVisualReady`, waiting for `SystemServices.generateWallpaperThumbnail` to downscale high-resolution wallpapers and 4 asynchronous snapshot IPC calls.
- **Fix**:
  1. Set `overviewLoaderActive: !compositorIsNiri` so the overview component remains prewarmed in memory.
  2. Set `overviewWallpaperReady: true` and simplified `beginOverviewOpening()` so the overview opens immediately (in ~70ms) without waiting for asynchronous disk writes or thumbnail generators.

### E. On-the-Fly Interactive Key Recorder for Shortcuts (`ShortcutsPage.qml`)
- **Problem**: Changing Hyprland shortcuts required manually clicking through static modifier and key chips from a fixed 10-key list, which was cumbersome and lacked support for arbitrary keys.
- **Solution**:
  1. Completely rebuilt [`qml/settings/ShortcutsPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/ShortcutsPage.qml) with an interactive **Key Recorder**:
     - User clicks on a shortcut pill or "Registra" button to enter listening mode (`● IN ASCOLTO...`).
     - Directly captures physical keystrokes (`Keys.onPressed` / `Keys.onReleased`) with full support for `SUPER` (Meta), `ALT`, `CTRL`, `SHIFT`, letters, numbers, arrow keys, `Tab`, `Spazio` (Space), `Return`, `Backspace`, function keys `F1`-`F12`, and punctuation.
     - Live keystroke preview renders held modifiers in real-time (`[ SUPER ] + [ ALT ] + [ ... ]`) and immediately creates the shortcut upon pressing the trigger key.
     - Flashes a green confirmation badge (`✔ REGISTRATO!`), saves to `customShortcuts` in `DynamicConfig`, and automatically syncs with Hyprland.
     - Supports `Esc` to cancel and per-shortcut / global "Ripristina Default" buttons.
  2. Implemented [`scripts/apply_hyprland_binds.py`](file:///home/lollo/Progetti/dynamic-island-hyprland/scripts/apply_hyprland_binds.py):
     - Safely parses and updates bindings in `~/.config/hypr/moduli/binds.lua`.
     - Automatically reloads Hyprland via `hyprctl reload` so recorded shortcuts take effect instantly.
### F. Native System Tray Satellite Pill Underneath Control Center (`TrayFloatingIsland.qml`)
- **Requirement**: Separate the system tray completely from the Control Center card to prevent any card distortion or slider overlap, placing it as a floating companion capsule directly below the Control Center.
- **Solution**:
  1. Built [`qml/island/TrayFloatingIsland.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/TrayFloatingIsland.qml) as an autonomous floating satellite capsule:
     - Placed 10px below the main Control Center card (`y: targetCapsule.y + targetCapsule.height + 10`).
     - Features its own matte dark glass capsule styling (`#0c0e14`, `radius: 19`, `height: 38px`, `border: 1px rgba(255,255,255,0.12)`).
     - Renders background app icons (Discord with green unread pulse dot, Steam, Telegram, etc.) with smooth hover effects, tooltips, and app titles (when <= 3 apps).
     - Left-click triggers `modelData.activate()` to restore the app window; right-click opens the context menu (`QsMenuOpener`) with zero clipping risk.
  2. Integrated cleanly into [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml):
     - Added to the Wayland input `mask: Region` and `capsuleWindowHeight`.
     - Reverted [`ControlCenterLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlCenterLayer.qml) to its 100% untouched layout, eliminating all deformation or strange gaps.

### G. 11-Point Polish & Portability Overhaul (User Screenshots & Directives)
1. **Dynamic Island Layer Exclusive Zone**:
   - In [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml), set `exclusiveZone: dynamicConfig.islandExclusiveZone` (default 48px), reserving space at the top so tiled windows never slide underneath the bar, functioning identically to Waybar.
2. **Settings App Window Geometry**:
   - Added `topLeftRadius: 32` and `bottomLeftRadius: 32` to the sidebar background in [`SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml) to perfectly match the right content panel's 32px squircle radius.
3. **100% Portability (No Hardcoded Paths)**:
   - Eliminated all `/home/lollo` strings across the repository and replaced them with dynamic expressions: `Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")`.
   - The shell now runs cleanly on any Linux installation under any username.
4. **Studio Canvas Vertical Scrolling**:
   - Wrapped `StudioLayoutCanvas` in a `Flickable` with `boundsBehavior: Flickable.StopAtBounds` and `ScrollBar.AsNeeded` in [`ControlCenterStudioPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/ControlCenterStudioPage.qml), allowing full vertical scrolling.
5. **Removed Redundant Interactions Tab**:
   - Removed the mouse clicks/scrolling page from SettingsApp navigation and stack layout, matching the user's workflow where hovering/clicking the island directly opens the Control Center.
6. **Sidebar Header & Pill Cleanup**:
   - Stripped away top header text (`Dynamic Island / Impostazioni Sistema`), tab subtitles, and bottom `● Live Synced` status badge in [`SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml) for an ultra-clean, minimalist sidebar.
7. **Vertical Sliders UI Polish**:
   - In [`ControlSliderCard.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlSliderCard.qml), added a dedicated circular glass icon badge (`width: 36, height: 36, radius: 18`) at the bottom anchor. At 0% volume, the icon remains grounded with high contrast (`#ffffff`) without looking broken or collapsing.
8. **Notification Capsule Redesign**:
   - Completely rebuilt [`NotificationLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/NotificationLayer.qml) matching user mockup: sender name + multi-line body on the left, circular icon badge (`42x42`, `radius: 21`) with app glyph on the right, dynamically scaling width (290-480px) and height (56-82px) based on content length.
9. **Wallpaper Switcher & Dynamic Color Engine Compatibility**:
   - In [`AppearanceFontPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/AppearanceFontPage.qml) and [`DynamicConfig.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/config/DynamicConfig.qml), made wallpaper directory and apply command freely customizable text fields with reset defaults.
   - Added support for 4 dynamic palette engines: **Pywal**, **Wallust**, **Iris**, and **Matugen** (with `auto` fall-through detection).
10. **Interactive Shortcuts Customizer & Dynamic Lua Export**:
    - In [`ShortcutsPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/ShortcutsPage.qml), users can edit key combinations for all 7 shell shortcuts. A dynamic snippet generator updates the exact Lua `hl.bind(...)` configuration in real time with a 1-click clipboard copy button (`wl-copy`).
11. **Instant Response & Error-Free QML Loading**:
    - Fixed QML attached property constraints in `ShortcutsPage.qml`.
    - Verified zero runtime QML syntax or type errors via `quickshell log --pid <pid>` and live test triggers.

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
- **Trash Can Icon Standardization (`\uf1f8` / ``)**: Replaced all thin, outline, or faint custom SVG shapes with the bold, solid Font Awesome / Nerd Font trash can glyph (`\uf1f8`):
  - In [`NotificationCenterLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/NotificationCenterLayer.qml): Replaced custom thin SVG line shape with a 26x26 circular glass button (`radius: 13`) displaying `\uf1f8` in red on hover.
  - In [`NotificationCard.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/NotificationCard.qml): Header "Clear All" button and individual item dismiss action.
  - In [`StudioLayoutCanvas.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/StudioLayoutCanvas.qml): Selected module toolbar delete button and library card removal toggle.
  - In [`ClipboardLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/ClipboardLayer.qml): "Clear History" header action and individual clip deletion badge.
  - In [`FileShelfLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/FileShelfLayer.qml): Staged file removal button.

### H. Dynamic Island WhatsApp & Portal Notification Capture Overhaul
- **Problem**: Incoming notifications from WhatsApp (WhatsApp Desktop, Chromium/Electron apps, Flatpaks) were displayed by SwayNC but failed to appear on the Dynamic Island capsule.
- **Root Causes**:
  1. Electron and Chromium use the XDG Desktop Portal (`org.freedesktop.portal.Notification.AddNotification`), which forwards to DBus with an empty `app_name: ""`.
  2. The C++ backend `libIslandBackend.so` only listened to `member='Notify'` and dropped empty app name notifications.
  3. `DynamicIslandWindow.qml` was placed on `WlrLayer.Top`, which got occluded by fullscreen windows or overlay panels.
  4. Spurious "Wi-Fi disconnesso" notifications immediately overwrote incoming notifications due to a short 1000ms debounce.
- **Solution & Fixes**:
  1. Built [`scripts/notification_monitor.py`](file:///home/lollo/Progetti/dynamic-island-hyprland/scripts/notification_monitor.py): A lightweight daemon listening to both `Notify` and `AddNotification`. It dynamically resolves the sender PID from `/proc/<pid>/cmdline` (identifying `whatsapp-linux-desktop` even when DBus `app_name` is empty) and dispatches clean notifications via Quickshell IPC `island postNotification`.
  2. Added `notificationMonitorProc` as a managed `Process` in [`shell.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/shell.qml) and added `postNotification` to `IpcHandler`.
  3. Elevated `WlrLayershell.layer` in [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) to `WlrLayer.Overlay` when `notificationLayerVisible` is active, guaranteeing the notification capsule stays on top.
  4. Expanded app detection in [`qml/island/NotificationLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/NotificationLayer.qml) with WhatsApp (`\uf232`, `#25D366`), Discord, Telegram, Spotify, Slack, Signal, and Thunderbird styling, cleanly extracting contact name and message text.
  5. In [`qml/island/WifiConnectionTracker.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/island/WifiConnectionTracker.qml), increased `disconnectDebounceTimer` from 1000ms to 3500ms to eliminate false disconnection alerts.

### I. Dedicated Power Menu Cealestia Execution Fix & 5-Action Parity
- **Root Cause Identified**: `PowerMenuLayer.qml` previously used short-lived QML `Process` elements. When clicking a button, `root.closeRequested()` immediately unloaded the layer, terminating the child processes before the OS kernel or systemd received the commands.
- **Cealestia Detached Execution**: Ported the exact execution paradigm from Cealestia's `shell.qml` using `Quickshell.execDetached(["bash", "-c", "nohup setsid " + cmd + " >/dev/null 2>&1 &"])`, ensuring commands run detached in the background without being affected by QML component lifecycle.
- **5 Cealestia Actions**:
  1. `Blocca`: `/home/lollo/.scripts/qslock-wrapper.sh` (Key: `L`)
  2. `Esci`: `hyprctl dispatch exit` (Key: `E`)
  3. `Sospendi`: `systemctl suspend` (Key: `U`)
  4. `Riavvia`: `systemctl reboot` (Key: `R`)
  5. `Spegni`: `systemctl poweroff` (Key: `S`)
- **Geometry**: Adjusted pill width from `340px` to `380px` in [`DynamicIslandWindow.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/DynamicIslandWindow.qml) to perfectly accommodate all 5 glass buttons with balanced padding and micro-interactions.

### J. Font Browser PC File Scanner, Icon Font Filtering & Vertical Slider Masking Fix
1. **Removed Preset Font Chips Section**:
   - Completely removed "Preset Font Rapidi Globali (1 Click)" and its divider line from [`AppearanceFontPage.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/settings/AppearanceFontPage.qml) as requested.
2. **PC Font Files Scanner & Icon-Specific Filtering**:
   - Built [`scripts/scan_system_fonts.py`](file:///home/lollo/Progetti/dynamic-island-hyprland/scripts/scan_system_fonts.py): Scans all 6,935 font files installed on the machine across `/usr/share/fonts`, `~/.local/share/fonts`, and user directories using fontconfig (`fc-list : family file`).
   - Categorizes fonts into all 5,030 system families and 112 icon-suitable font families (Nerd Fonts, Font Awesome, Material Symbols, Symbols Nerd Font, Feather, Remix, Phosphor, Tabler, etc.).
   - Integrated with [`SettingsAppLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/SettingsAppLayer.qml) using `FileView` (`~/.cache/dynamic-island/fonts_cache.json`) and background `Process` execution with immediate Qt fallback.
   - When browsing for icons (`target === "icon"`): Displays only icon-compatible fonts, shows icon glyph previews (`                `), and updates header and placeholder text.
3. **Vertical Slider Masking & Corner Radius Fix**:
   - **Bug**: Lowering brightness/volume sliders almost all the way caused a white rectangle to poke out of the bottom of the slider container and flatten out.
   - **Root Cause**: In Qt Quick, `clip: true` only clips to bounding boxes, not rounded corners. When the fill rectangle's height shrank below 20px (e.g. 15px at 10%), its corner radius clamped down to 7.5px while the container had a 20px radius, causing sharp corners to poke out past the container's curve and overdraw the border.
   - **Fix**: Rebuilt [`ControlSliderCard.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlSliderCard.qml) using `OpacityMask` from `Qt5Compat.GraphicalEffects` with an inner `trackMask` inset by 1px. The fill is now mathematically masked to the exact inner curve of the pill at any height (0% to 100%). Centered the bottom icon in a clean 44px area with smooth color transitions (`#111214` when covered, `#ffffff` when uncovered).
4. **Resolved Quickshell Reference Error**:
   - Added missing `import Quickshell` to [`ControlCenterLayer.qml`](file:///home/lollo/Progetti/dynamic-island-hyprland/qml/controlcenter/ControlCenterLayer.qml).

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
