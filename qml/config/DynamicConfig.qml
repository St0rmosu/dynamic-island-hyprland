import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")
    readonly property string configDir: homeDir + "/.config/dynamic-island"
    readonly property string configPath: configDir + "/config.json"
    readonly property string fallbackPath: configDir + "/userconfig.json"

    // ── 1. Isola & Geometria ───────────────────────────────────────────
    property int islandWidth: 140
    property int islandHeight: 40
    property int islandCornerRadius: 32
    property int islandTopMargin: 8
    property int islandExclusiveZone: 48
    property int islandPositionX: 50
    property int islandBackgroundOpacity: 92

    // Auto-hide & Hover
    property bool autoHideEnabled: false
    property int autoHideDelayMs: 2000
    property bool showWorkspaceOnAutoHide: true
    property bool hoverExpandEnabled: false
    property int hoverExpandAction: 2 // 0: disabled, 1: media player, 2: control center
    property int hoverExpandDelayMs: 200
    property int hoverCollapseDelayMs: 300
    property bool disableAutoExpandOnTrackChange: false

    // ── 2. Interazioni & Mouse ─────────────────────────────────────────
    property string primaryClickAction: "control_center"
    property string secondaryClickAction: "power_menu"
    property string middleClickAction: "clipboard"
    property string doubleClickAction: "toggle_island"
    property string scrollVerticalAction: "volume"
    property string scrollHorizontalAction: "track"
    property int scrollStep: 5

    // ── 3. Control Center & Studio Canvas ──────────────────────────────
    property string controlCenterOrientation: "vertical"
    property int controlCenterWidth: 420
    property var controlCenterCanvasLayout: [
        { id: "header", name: "Orologio & Batteria", icon: "\uf017", col: 0, row: -1, colSpan: 4, rowSpan: 1, height: 32, active: true },
        { id: "wifi", name: "Scheda Wi-Fi", icon: "\uf1eb", col: 0, row: 0, colSpan: 2, rowSpan: 1, height: 80, active: true },
        { id: "bluetooth", name: "Scheda Bluetooth", icon: "\uf294", col: 0, row: 1, colSpan: 2, rowSpan: 1, height: 80, active: true },
        { id: "brightness", name: "Luminosità Display", icon: "\uf185", col: 2, row: 0, colSpan: 1, rowSpan: 2, height: 160, active: true },
        { id: "volume", name: "Controllo Volume", icon: "\uf028", col: 3, row: 0, colSpan: 1, rowSpan: 2, height: 160, active: true },
        { id: "notifications", name: "Centro Notifiche", icon: "\uf0f3", col: 0, row: 2, colSpan: 4, rowSpan: 2, height: 160, active: true },
        { id: "toggles", name: "Luce Notturna & Focus", icon: "\uf186", col: 0, row: 4, colSpan: 2, rowSpan: 1, height: 80, active: false },
        { id: "battery", name: "Profilo Batteria TLP", icon: "\uf0e7", col: 0, row: 5, colSpan: 2, rowSpan: 1, height: 80, active: false },
        { id: "quickactions", name: "Barra & Appunti", icon: "\uf108", col: 2, row: 4, colSpan: 2, rowSpan: 1, height: 80, active: false }
    ]

    // ── 4. Aspetto, Sfondi & Font ──────────────────────────────────────
    property real blurRadius: 24
    property real borderWidth: 1.0
    property bool pywalEnabled: true
    property string paletteEngine: "auto" // auto, pywal, wallust, iris, matugen
    property string customAccentColor: ""
    property string wallpaperPath: ""
    property string wallpaperLibrary: homeDir + "/Sfondi"
    property string wallpaperCustomCommand: homeDir + "/.scripts/apply-wallpaper.sh \"$1\""
    property string wallpaperTransition: "random"
    property string clockFormat: "24h"

    // ── 5. Scorciatoie Personalizzate ──────────────────────────────────
    property var customShortcuts: [
        { id: "overview", title: "Workspace Overview", desc: "Visualizzatore interattivo di tutti i workspace e finestre", icon: "\uf108", keys: ["SUPER", "Tab"], action: "overview" },
        { id: "power", title: "Power Menu (Wlogout)", desc: "Menu rapido per Blocca, Esci, Sospendi, Riavvia, Spegni", icon: "\uf011", keys: ["SUPER", "P"], action: "power" },
        { id: "notifications", title: "Notification Center", desc: "Pannello con cronologia notifiche e cancellazione", icon: "\uf0f3", keys: ["SUPER", "N"], action: "notifications" },
        { id: "wallpaper", title: "Wallpaper Switcher", desc: "Selettore a schede per cambiare sfondo con animazione", icon: "\uf03e", keys: ["SUPER", "ALT", "Spazio"], action: "master-or-wallpaper" },
        { id: "apps", title: "Application Launcher", desc: "Ricerca rapida e avvio delle applicazioni installate", icon: "\uf135", keys: ["ALT", "Spazio"], action: "apps" },
        { id: "files", title: "File Shelf", desc: "Cassetto rapido per trascinare e incollare file al volo", icon: "\uf07b", keys: ["SUPER", "O"], action: "files" },
        { id: "clipboard", title: "Clipboard History", desc: "Cronologia degli appunti con testi, codici e immagini", icon: "\uf0ea", keys: ["SUPER", "C"], action: "clipboard" }
    ]

    property string textFontFamily: "Google Sans Flex"
    property string heroFontFamily: "Google Sans Flex"
    property string timeFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property int bodyFontSize: 13
    property int titleFontSize: 16
    property int iconFontSize: 18

    // ── 5. Motion & Animazioni ─────────────────────────────────────────
    property int transitionDuration: 280
    property int animationFps: 60
    property string motionProfile: "snappy"

    // ── Internals & State ──────────────────────────────────────────────
    property var rawMap: ({})
    property bool isLoaded: false
    property bool isSaving: false
    property string saveStatus: "Live Synced"

    signal configSaved()
    signal configReloaded()

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        preload: true
        printErrors: false

        Component.onCompleted: root.loadFromDisk()
        onFileChanged: root.loadFromDisk()
    }

    // ── Palette Engine Watchers (Pywal, Wallust, Iris, Matugen) ────────
    FileView {
        id: pywalColorsFile
        path: root.homeDir + "/.cache/wal/colors.json"
        watchChanges: true
        preload: true
        printErrors: false
        property string accent: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.colors) accent = d.colors.color4 || d.colors.color2 || "";
            } catch(e) {}
        }
    }

    FileView {
        id: wallustColorsFile
        path: root.homeDir + "/.cache/wallust/colors.json"
        watchChanges: true
        preload: true
        printErrors: false
        property string accent: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.colors) accent = d.colors.color4 || d.colors.color2 || "";
            } catch(e) {}
        }
    }

    FileView {
        id: irisColorsFile
        path: root.homeDir + "/.cache/iris/colors.json"
        watchChanges: true
        preload: true
        printErrors: false
        property string accent: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.accent) accent = d.accent;
            } catch(e) {}
        }
    }

    FileView {
        id: matugenColorsFile
        path: root.homeDir + "/.config/matugen/colors.json"
        watchChanges: true
        preload: true
        printErrors: false
        property string accent: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.colors && d.colors.primary) {
                    accent = (typeof d.colors.primary === "object" && d.colors.primary.default)
                        ? d.colors.primary.default.hex
                        : String(d.colors.primary);
                }
            } catch(e) {}
        }
    }

    readonly property color effectiveAccentColor: {
        if (root.customAccentColor !== "" && !root.pywalEnabled)
            return root.customAccentColor;

        if (root.paletteEngine === "iris" && irisColorsFile.accent !== "")
            return irisColorsFile.accent;
        if (root.paletteEngine === "wallust" && wallustColorsFile.accent !== "")
            return wallustColorsFile.accent;
        if (root.paletteEngine === "matugen" && matugenColorsFile.accent !== "")
            return matugenColorsFile.accent;
        if (root.paletteEngine === "pywal" && pywalColorsFile.accent !== "")
            return pywalColorsFile.accent;

        // Auto mode: check Iris, Pywal, Wallust, Matugen in order
        if (irisColorsFile.accent !== "") return irisColorsFile.accent;
        if (pywalColorsFile.accent !== "") return pywalColorsFile.accent;
        if (wallustColorsFile.accent !== "") return wallustColorsFile.accent;
        if (matugenColorsFile.accent !== "") return matugenColorsFile.accent;

        return "#0a84ff";
    }

    FileView {
        id: fallbackFile
        path: root.fallbackPath
        watchChanges: false
        preload: true
        printErrors: false
    }

    function loadFromDisk() {
        let content = "";
        try {
            content = configFile.text();
        } catch(e) {}

        if (!content || content.trim() === "") {
            try {
                content = fallbackFile.text();
            } catch(e) {}
        }

        if (!content || content.trim() === "") {
            root.isLoaded = true;
            return;
        }

        try {
            const data = JSON.parse(content);
            if (!data || typeof data !== "object") return;
            root.rawMap = data;

            // Geometry
            if (data.islandWidth !== undefined) root.islandWidth = Number(data.islandWidth) || 140;
            if (data.islandHeight !== undefined) root.islandHeight = Number(data.islandHeight) || 40;
            if (data.islandCornerRadius !== undefined) root.islandCornerRadius = Number(data.islandCornerRadius) || 32;
            if (data.islandTopMargin !== undefined) root.islandTopMargin = Number(data.islandTopMargin) >= 0 ? Number(data.islandTopMargin) : 8;
            if (data.islandExclusiveZone !== undefined) root.islandExclusiveZone = Number(data.islandExclusiveZone) >= 0 ? Number(data.islandExclusiveZone) : 48;
            if (data.islandPositionX !== undefined) root.islandPositionX = Number(data.islandPositionX) || 50;
            if (data.islandBackgroundOpacity !== undefined) root.islandBackgroundOpacity = Number(data.islandBackgroundOpacity) || 92;

            // Auto-hide & Hover
            if (data.islandAutoHideEnabled !== undefined) root.autoHideEnabled = Boolean(data.islandAutoHideEnabled);
            if (data.islandAutoHideDelayMs !== undefined) root.autoHideDelayMs = Number(data.islandAutoHideDelayMs) || 2000;
            if (data.islandShowWorkspaceOnAutoHide !== undefined) root.showWorkspaceOnAutoHide = Boolean(data.islandShowWorkspaceOnAutoHide);
            if (data.hoverExpandEnabled !== undefined) root.hoverExpandEnabled = Boolean(data.hoverExpandEnabled);
            if (data.hoverExpandAction !== undefined) root.hoverExpandAction = Number(data.hoverExpandAction) || 2;
            if (data.hoverExpandDelayMs !== undefined) root.hoverExpandDelayMs = Number(data.hoverExpandDelayMs) || 200;
            if (data.hoverCollapseDelayMs !== undefined) root.hoverCollapseDelayMs = Number(data.hoverCollapseDelayMs) || 300;
            if (data.disableAutoExpandOnTrackChange !== undefined) root.disableAutoExpandOnTrackChange = Boolean(data.disableAutoExpandOnTrackChange);

            // Mouse Interactions
            if (data.primaryClickAction !== undefined) root.primaryClickAction = String(data.primaryClickAction);
            if (data.secondaryClickAction !== undefined) root.secondaryClickAction = String(data.secondaryClickAction);
            if (data.middleClickAction !== undefined) root.middleClickAction = String(data.middleClickAction);
            if (data.doubleClickAction !== undefined) root.doubleClickAction = String(data.doubleClickAction);
            if (data.scrollVerticalAction !== undefined) root.scrollVerticalAction = String(data.scrollVerticalAction);
            if (data.scrollHorizontalAction !== undefined) root.scrollHorizontalAction = String(data.scrollHorizontalAction);
            if (data.scrollStep !== undefined) root.scrollStep = Number(data.scrollStep) || 5;

            // Control Center Canvas
            if (Array.isArray(data.controlCenterCanvasLayout) && data.controlCenterCanvasLayout.length > 0) {
                root.controlCenterCanvasLayout = data.controlCenterCanvasLayout;
            }
            if (data.controlCenterOrientation !== undefined) root.controlCenterOrientation = String(data.controlCenterOrientation);
            if (data.controlCenterWidth !== undefined) root.controlCenterWidth = Number(data.controlCenterWidth) || 420;

            // Appearance & Fonts
            if (data.pywalEnabled !== undefined) root.pywalEnabled = Boolean(data.pywalEnabled);
            if (data.wallpaperPywalEnabled !== undefined) root.pywalEnabled = Boolean(data.wallpaperPywalEnabled);
            if (data.paletteEngine !== undefined) root.paletteEngine = String(data.paletteEngine);
            if (data.customAccentColor !== undefined) root.customAccentColor = String(data.customAccentColor);
            if (data.wallpaperPath !== undefined) root.wallpaperPath = String(data.wallpaperPath);
            if (data.wallpaperLibraryPath !== undefined) root.wallpaperLibrary = String(data.wallpaperLibraryPath);
            if (data.wallpaperCustomCommand !== undefined) root.wallpaperCustomCommand = String(data.wallpaperCustomCommand);
            if (data.clockFormat !== undefined) root.clockFormat = String(data.clockFormat);

            // Shortcuts
            if (Array.isArray(data.customShortcuts) && data.customShortcuts.length > 0) {
                root.customShortcuts = data.customShortcuts;
            }

            if (data.textFontFamily !== undefined) root.textFontFamily = String(data.textFontFamily);
            if (data.heroFontFamily !== undefined) root.heroFontFamily = String(data.heroFontFamily);
            if (data.timeFontFamily !== undefined) root.timeFontFamily = String(data.timeFontFamily);
            if (data.iconFontFamily !== undefined) root.iconFontFamily = String(data.iconFontFamily);
            if (data.bodyFontSize !== undefined) root.bodyFontSize = Number(data.bodyFontSize) || 13;
            if (data.titleFontSize !== undefined) root.titleFontSize = Number(data.titleFontSize) || 16;
            if (data.iconFontSize !== undefined) root.iconFontSize = Number(data.iconFontSize) || 18;

            // Motion
            if (data.transitionDuration !== undefined) root.transitionDuration = Number(data.transitionDuration) || 280;
            if (data.animationFps !== undefined) root.animationFps = Number(data.animationFps) || 60;
            if (data.motionProfile !== undefined) root.motionProfile = String(data.motionProfile);

            root.isLoaded = true;
            root.configReloaded();
        } catch(e) {
            console.warn("[DynamicConfig] Error parsing config:", e);
        }
    }

    function set(key, value) {
        if (root[key] !== undefined) {
            root[key] = value;
        }
        root.rawMap[key] = value;
        root.saveStatus = "Saving...";
        saveDebounceTimer.restart();
    }

    function get(key, fallback) {
        if (root[key] !== undefined) return root[key];
        if (root.rawMap[key] !== undefined) return root.rawMap[key];
        return fallback;
    }

    Timer {
        id: saveDebounceTimer
        interval: 100
        repeat: false
        onTriggered: root.dispatchSave()
    }

    function dispatchSave() {
        root.isSaving = true;
        try {
            // Snapshot current state
            const payload = {
                islandWidth: root.islandWidth,
                islandHeight: root.islandHeight,
                islandCornerRadius: root.islandCornerRadius,
                islandTopMargin: root.islandTopMargin,
                islandExclusiveZone: root.islandExclusiveZone,
                islandPositionX: root.islandPositionX,
                islandBackgroundOpacity: root.islandBackgroundOpacity,

                islandAutoHideEnabled: root.autoHideEnabled,
                islandAutoHideDelayMs: root.autoHideDelayMs,
                islandShowWorkspaceOnAutoHide: root.showWorkspaceOnAutoHide,
                hoverExpandEnabled: root.hoverExpandEnabled,
                hoverExpandAction: root.hoverExpandAction,
                hoverExpandDelayMs: root.hoverExpandDelayMs,
                hoverCollapseDelayMs: root.hoverCollapseDelayMs,
                disableAutoExpandOnTrackChange: root.disableAutoExpandOnTrackChange,

                primaryClickAction: root.primaryClickAction,
                secondaryClickAction: root.secondaryClickAction,
                middleClickAction: root.middleClickAction,
                doubleClickAction: root.doubleClickAction,
                scrollVerticalAction: root.scrollVerticalAction,
                scrollHorizontalAction: root.scrollHorizontalAction,
                scrollStep: root.scrollStep,

                controlCenterOrientation: root.controlCenterOrientation,
                controlCenterWidth: root.controlCenterWidth,
                controlCenterCanvasLayout: root.controlCenterCanvasLayout,

                pywalEnabled: root.pywalEnabled,
                wallpaperPywalEnabled: root.pywalEnabled,
                paletteEngine: root.paletteEngine,
                customAccentColor: root.customAccentColor,
                wallpaperPath: root.wallpaperPath,
                wallpaperLibraryPath: root.wallpaperLibrary,
                wallpaperCustomCommand: root.wallpaperCustomCommand,
                clockFormat: root.clockFormat,
                customShortcuts: root.customShortcuts,

                textFontFamily: root.textFontFamily,
                heroFontFamily: root.heroFontFamily,
                timeFontFamily: root.timeFontFamily,
                iconFontFamily: root.iconFontFamily,
                bodyFontSize: root.bodyFontSize,
                titleFontSize: root.titleFontSize,
                iconFontSize: root.iconFontSize,

                transitionDuration: root.transitionDuration,
                animationFps: root.animationFps,
                motionProfile: root.motionProfile
            };

            const jsonStr = JSON.stringify(payload);
            const scriptPath = root.homeDir + "/.config/quickshell/dynamic-island/scripts/save_dynamic_config.py";
            Quickshell.execDetached(["python3", scriptPath, jsonStr]);
            root.saveStatus = "Live Synced";
            root.isSaving = false;
            root.configSaved();
        } catch(e) {
            console.error("[DynamicConfig] Save failed:", e);
            root.saveStatus = "Save Error";
            root.isSaving = false;
        }
    }
}
