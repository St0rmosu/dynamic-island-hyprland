import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: bgWindow

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "dynamic-island:background"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: true

    property var shellRootController: null
    property var dynamicConfig: null

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    // Hyprland monitor geometry and margins
    readonly property HyprlandMonitor hyprMonitor: Hyprland.monitorFor(bgWindow.screen)
    readonly property real reservedTop: (hyprMonitor && hyprMonitor.reserved && hyprMonitor.reserved.length > 1) ? hyprMonitor.reserved[1] : 48
    readonly property real underTopMargin: reservedTop + 7
    readonly property real underLeftMargin: 7
    readonly property real underRightMargin: 7
    readonly property real underBottomMargin: 7
    readonly property real underRadius: 20

    // Iris Dynamic Colors FileView
    FileView {
        id: irisColorsFile
        path: bgWindow.homeDir + "/.cache/iris/colors.json"
        watchChanges: true
        printErrors: false
        property string accentHex: ""
        property string bgHex: ""
        property string surfaceHex: ""
        property string fgHex: ""
        property string dimHex: ""
        property string blueHex: ""
        property string purpleHex: ""
        property string greenHex: ""
        property string yellowHex: ""
        property string redHex: ""

        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d) {
                    if (d.accent) accentHex = d.accent;
                    if (d.bg) bgHex = d.bg;
                    if (d.surface) surfaceHex = d.surface;
                    if (d.fg) fgHex = d.fg;
                    if (d.dim) dimHex = d.dim;
                    if (d.syntax_operator || d.syntax_func) blueHex = d.syntax_operator || d.syntax_func;
                    if (d.syntax_const || d.syntax_type || d.syntax_keyword) purpleHex = d.syntax_const || d.syntax_type || d.syntax_keyword;
                    if (d.green) greenHex = d.green;
                    if (d.yellow) yellowHex = d.yellow;
                    if (d.red) redHex = d.red;
                }
            } catch(e) {}
        }
    }

    FileView {
        id: wallustColorsFile
        path: bgWindow.homeDir + "/.cache/wallust/colors.json"
        watchChanges: true
        printErrors: false
        property string accentHex: ""
        property string bgHex: ""
        property string surfaceHex: ""
        property string fgHex: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d) {
                    if (d.colors && (d.colors.color4 || d.colors.color2))
                        accentHex = d.colors.color4 || d.colors.color2;
                    if (d.special && d.special.background)
                        bgHex = d.special.background;
                    if (d.special && d.special.foreground)
                        fgHex = d.special.foreground;
                    if (d.colors && d.colors.color0)
                        surfaceHex = d.colors.color0;
                }
            } catch (e) {}
        }
    }

    FileView {
        id: matugenColorsFile
        path: bgWindow.homeDir + "/.config/matugen/colors.json"
        watchChanges: true
        printErrors: false
        property string accentHex: ""
        property string bgHex: ""
        property string surfaceHex: ""
        property string fgHex: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.colors) {
                    if (d.colors.primary && d.colors.primary.default && d.colors.primary.default.hex)
                        accentHex = d.colors.primary.default.hex;
                    else if (typeof d.colors.primary === "string")
                        accentHex = d.colors.primary;
                    if (d.colors.background && d.colors.background.default && d.colors.background.default.hex)
                        bgHex = d.colors.background.default.hex;
                    else if (typeof d.colors.background === "string")
                        bgHex = d.colors.background;
                    if (d.colors.surface && d.colors.surface.default && d.colors.surface.default.hex)
                        surfaceHex = d.colors.surface.default.hex;
                    else if (typeof d.colors.surface === "string")
                        surfaceHex = d.colors.surface;
                    if (d.colors.on_background && d.colors.on_background.default && d.colors.on_background.default.hex)
                        fgHex = d.colors.on_background.default.hex;
                    else if (typeof d.colors.on_background === "string")
                        fgHex = d.colors.on_background;
                }
            } catch (e) {}
        }
    }

    // File watchers per tracciare lo sfondo attivo in tempo reale
    FileView {
        id: walCurrentFile
        path: bgWindow.homeDir + "/.cache/wal/wal"
        watchChanges: true
        preload: true
        printErrors: false
        property string wallpaper: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: wallpaper = text().trim()
    }

    FileView {
        id: pywalColorsFile
        path: bgWindow.homeDir + "/.cache/wal/colors.json"
        watchChanges: true
        preload: true
        printErrors: false
        property string wallpaper: ""
        property string accentHex: ""
        property string bgHex: ""
        property string fgHex: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d) {
                    if (d.wallpaper) wallpaper = d.wallpaper.trim();
                    if (d.colors && (d.colors.color4 || d.colors.color2))
                        accentHex = d.colors.color4 || d.colors.color2;
                    if (d.special && d.special.background)
                        bgHex = d.special.background;
                    if (d.special && d.special.foreground)
                        fgHex = d.special.foreground;
                }
            } catch(e) {}
        }
    }

    readonly property color themeAccent: {
        if (irisColorsFile.accentHex !== "") return irisColorsFile.accentHex;
        if (matugenColorsFile.accentHex !== "") return matugenColorsFile.accentHex;
        if (wallustColorsFile.accentHex !== "") return wallustColorsFile.accentHex;
        if (pywalColorsFile.accentHex !== "") return pywalColorsFile.accentHex;
        return "#bdb6a6";
    }
    readonly property color themeBg: {
        if (irisColorsFile.bgHex !== "") return irisColorsFile.bgHex;
        if (matugenColorsFile.bgHex !== "") return matugenColorsFile.bgHex;
        if (wallustColorsFile.bgHex !== "") return wallustColorsFile.bgHex;
        if (pywalColorsFile.bgHex !== "") return pywalColorsFile.bgHex;
        return "#2e383f";
    }
    readonly property color themeSurface: {
        if (irisColorsFile.surfaceHex !== "") return irisColorsFile.surfaceHex;
        if (matugenColorsFile.surfaceHex !== "") return matugenColorsFile.surfaceHex;
        if (wallustColorsFile.surfaceHex !== "") return wallustColorsFile.surfaceHex;
        return "#3d4a54";
    }
    readonly property color themeFg: {
        if (irisColorsFile.fgHex !== "") return irisColorsFile.fgHex;
        if (matugenColorsFile.fgHex !== "") return matugenColorsFile.fgHex;
        if (wallustColorsFile.fgHex !== "") return wallustColorsFile.fgHex;
        if (pywalColorsFile.fgHex !== "") return pywalColorsFile.fgHex;
        return "#c8c3b6";
    }

    FileView {
        id: configCurrentFile
        path: bgWindow.homeDir + "/.config/dynamic-island/current_wallpaper"
        watchChanges: true
        preload: true
        printErrors: false
        property string wallpaper: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: wallpaper = text().trim()
    }

    FileView {
        id: iiConfigFile
        path: bgWindow.homeDir + "/.config/illogical-impulse/config.json"
        watchChanges: true
        preload: true
        printErrors: false
        property string wallpaper: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.background && d.background.wallpaperPath) {
                    wallpaper = d.background.wallpaperPath.trim();
                }
            } catch(e) {}
        }
    }

    readonly property string effectiveWallpaperPath: {
        if (dynamicConfig && dynamicConfig.wallpaperPath && dynamicConfig.wallpaperPath !== "")
            return dynamicConfig.wallpaperPath;
        if (configCurrentFile.wallpaper !== "")
            return configCurrentFile.wallpaper;
        if (walCurrentFile.wallpaper !== "")
            return walCurrentFile.wallpaper;
        if (pywalColorsFile.wallpaper !== "")
            return pywalColorsFile.wallpaper;
        if (iiConfigFile.wallpaper !== "")
            return iiConfigFile.wallpaper;
        return "";
    }

    readonly property string effectiveWallpaperUrl: {
        const wp = effectiveWallpaperPath;
        if (wp === "") return "";
        return wp.startsWith("file://") ? wp : ("file://" + encodeURI(wp));
    }

    // Sfondo wallpaper opzionale sotto le finestre
    Image {
        id: bgImage
        anchors.fill: parent
        source: bgWindow.effectiveWallpaperUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        visible: (dynamicConfig ? Boolean(dynamicConfig.enableQuickshellWallpaper) : false) && bgWindow.effectiveWallpaperUrl !== ""

        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }
    }

    // ── Under-Window Coordinator Properties ──────────────────────────
    readonly property bool snippingActive: shellRootController ? !!shellRootController.screenshotSnippingUnderActive : false
    readonly property bool flightActive: shellRootController ? !!shellRootController.screenshotFlyingUnderActive : false
    readonly property bool surfaceActive: snippingActive || flightActive

    property real flightCurrentX: 0
    property real flightCurrentY: 0
    property real flightCurrentW: 100
    property real flightCurrentH: 100
    property real flightCurrentRadius: 8
    property real flightCurrentOpacity: 0.0

    ParallelAnimation {
        id: underFlightAnim

        NumberAnimation {
            id: animX
            target: bgWindow
            property: "flightCurrentX"
            duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: animY
            target: bgWindow
            property: "flightCurrentY"
            duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: animW
            target: bgWindow
            property: "flightCurrentW"
            duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: animH
            target: bgWindow
            property: "flightCurrentH"
            duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: animRadius
            target: bgWindow
            property: "flightCurrentRadius"
            duration: 260
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            NumberAnimation {
                target: bgWindow
                property: "flightCurrentOpacity"
                to: 1.0
                duration: 40
            }
            PauseAnimation { duration: 180 }
            NumberAnimation {
                target: bgWindow
                property: "flightCurrentOpacity"
                to: 0.0
                duration: 40
                easing.type: Easing.InQuad
            }
        }

        onFinished: {
            if (shellRootController && shellRootController.notifySnipFlightFinished) {
                shellRootController.notifySnipFlightFinished();
            }
        }
    }

    function startUnderFlight() {
        if (!shellRootController) return;
        const sx = shellRootController.screenshotSnipX;
        const sy = shellRootController.screenshotSnipY;
        const sw = Math.max(16, shellRootController.screenshotSnipW);
        const sh = Math.max(16, shellRootController.screenshotSnipH);

        const tx = shellRootController.screenshotTargetX;
        const ty = shellRootController.screenshotTargetY;
        const tw = Math.max(16, shellRootController.screenshotTargetW);
        const th = Math.max(16, shellRootController.screenshotTargetH);

        flightCurrentX = sx;
        flightCurrentY = sy;
        flightCurrentW = sw;
        flightCurrentH = sh;
        flightCurrentRadius = 8;
        flightCurrentOpacity = 0.95;

        animX.from = sx; animX.to = tx;
        animY.from = sy; animY.to = ty;
        animW.from = sw; animW.to = tw;
        animH.from = sh; animH.to = th;
        animRadius.from = 8; animRadius.to = 16;

        underFlightImg.source = "";
        underFlightAnim.restart();
    }

    function refreshUnderFlightImage(path) {
        if (underFlightImg && path && path !== "") {
            underFlightImg.source = "file://" + path;
        }
    }

    Connections {
        target: shellRootController
        function onScreenshotFlyingUnderActiveChanged() {
            if (shellRootController && shellRootController.screenshotFlyingUnderActive) {
                bgWindow.startUnderFlight();
            }
        }
    }

    // ── 2. Layer sotto le finestre (Disattivato per richiesta utente: zero animazioni trasparenti)
    Rectangle {
        id: underWindowCanvas
        anchors.fill: parent
        anchors.leftMargin: bgWindow.underLeftMargin
        anchors.rightMargin: bgWindow.underRightMargin
        anchors.bottomMargin: bgWindow.underBottomMargin
        anchors.topMargin: bgWindow.underTopMargin
        radius: bgWindow.underRadius
        clip: true
        color: "transparent"
        visible: false
    }

    // Card che si porta direttamente con sé lo screen verso l'isola (disattivata)
    Item {
        id: underCarryingCard
        visible: false
        z: 10
        x: bgWindow.flightCurrentX
        y: bgWindow.flightCurrentY
        width: bgWindow.flightCurrentW
        height: bgWindow.flightCurrentH
        opacity: bgWindow.flightCurrentOpacity

        Rectangle {
            anchors.fill: parent
            radius: bgWindow.flightCurrentRadius
            color: Qt.rgba(bgWindow.themeSurface.r, bgWindow.themeSurface.g, bgWindow.themeSurface.b, 0.90)
            border.width: 1.5
            border.color: bgWindow.themeAccent
            clip: true

            Text {
                anchors.centerIn: parent
                text: "\uf030"
                color: bgWindow.themeAccent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Math.max(14, Math.min(28, Math.round(parent.height * 0.25)))
                visible: underFlightImg.status !== Image.Ready
            }

            Image {
                id: underFlightImg
                anchors.fill: parent
                anchors.margins: 2
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
                opacity: status === Image.Ready ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 70 }
                }
            }
        }
    }
}
