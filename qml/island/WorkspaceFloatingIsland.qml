import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Hyprland
import IslandBackend

Rectangle {
    id: root

    property var targetCapsule: null
    property var rootWindow: null
    property var dynamicConfig: null
    property var userConfig: UserConfig
    property color accentColor: (rootWindow && rootWindow.themeAccent) ? rootWindow.themeAccent : StyleTokens.accent
    property color textColor: (rootWindow && rootWindow.themeFg) ? rootWindow.themeFg : "#c8c3b6"
    property color dimColor: (rootWindow && rootWindow.themeDim) ? rootWindow.themeDim : "#606c75"
    property color surfaceColor: (rootWindow && rootWindow.themeSurface) ? rootWindow.themeSurface : "#2e383f"

    readonly property string iconFontFamily: rootWindow ? rootWindow.iconFontFamily : "JetBrainsMono Nerd Font"
    readonly property string textFontFamily: rootWindow ? rootWindow.textFontFamily : "Google Sans Flex"

    // Proprietà configurabili
    readonly property bool isEnabled: dynamicConfig ? (dynamicConfig.enableWorkspacePill !== false) : true
    readonly property string positionSide: (dynamicConfig && dynamicConfig.workspacePillPosition) ? dynamicConfig.workspacePillPosition : "right"
    readonly property bool showAppIcons: dynamicConfig ? (dynamicConfig.workspacePillShowAppIcons !== false) : true

    // Workspace configurabili (5, 8 o 10 da impostazioni)
    readonly property int totalWorkspaces: (dynamicConfig && dynamicConfig.workspacePillShownCount > 0) ? dynamicConfig.workspacePillShownCount : 5

    // Tracciamento workspace corrente dal monitor attivo
    readonly property int currentWorkspace: {
        if (rootWindow && rootWindow.currentMonitorWorkspaceId !== undefined && rootWindow.currentMonitorWorkspaceId > 0)
            return rootWindow.currentMonitorWorkspaceId;
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace)
            return Hyprland.focusedMonitor.activeWorkspace.id;
        return 1;
    }

    // Mappa client e stato occupato
    property var wsAppMap: ({})
    property var occupiedSet: ({})

    // Dimensioni uniformi con il resto della barra e dell'isola (stessa altezza e curvatura dell'orologio)
    readonly property real compactHeight: rootWindow ? rootWindow.effectiveIslandHeight : (userConfig ? userConfig.islandHeight : 40)
    readonly property real itemSize: Math.round(compactHeight * 0.70)
    readonly property real itemSpacing: 5
    readonly property real paddingH: 8

    implicitWidth: paddingH * 2 + totalWorkspaces * itemSize + (totalWorkspaces - 1) * itemSpacing
    implicitHeight: compactHeight
    width: implicitWidth
    height: compactHeight
    radius: compactHeight / 2

    property var musicPill: null
    property bool _switchingPositionSide: false

    Timer {
        id: switchPositionTimer
        interval: 320
        repeat: false
        onTriggered: root._switchingPositionSide = false
    }

    onPositionSideChanged: {
        root._switchingPositionSide = true;
        switchPositionTimer.restart();
    }

    // Posizionamento satellite a fianco dell'orologio (privo di conflitti di ancoraggio mutuo)
    x: {
        if (!targetCapsule) return 0;
        if (positionSide === "left") {
            if (musicPill && musicPill.visible && musicPill.opacity > 0.05) {
                return musicPill.x - width - 8;
            }
            return targetCapsule.x - width - 8;
        } else {
            return targetCapsule.x + targetCapsule.width + 8;
        }
    }
    y: targetCapsule ? targetCapsule.y : 0

    Behavior on x {
        enabled: root._switchingPositionSide
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutQuint
        }
    }

    readonly property bool isAutoHidden: rootWindow && rootWindow.autoHideEnabled && !rootWindow.autoHideTargetVisible
    readonly property bool showOnAutoHide: dynamicConfig ? (dynamicConfig.showWorkspaceOnAutoHide !== false) : true
    readonly property bool modalOrSnipping: rootWindow && (rootWindow.isScreenshotModeActive || rootWindow.screenshotSnippingActive || (rootWindow.islandContainer && rootWindow.islandContainer.islandState === "settings_app"))

    visible: isEnabled && (!rootWindow || !rootWindow.overviewVisible) && !modalOrSnipping && opacity > 0.01
    opacity: isEnabled && (!rootWindow || (!rootWindow.overviewVisible && !modalOrSnipping)) ? ((isAutoHidden && showOnAutoHide) ? 1.0 : (targetCapsule ? targetCapsule.opacity : 1.0)) : 0.0
    scale: 1.0

    clip: true
    color: Qt.rgba(0, 0, 0, (rootWindow ? rootWindow.effectiveIslandBackgroundOpacity : 92) / 100)
    border.width: 1
    border.color: pillHoverArea.containsMouse ? root.accentColor : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)

    // Animazioni fluide
    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
    Behavior on opacity {
        NumberAnimation {
            duration: (rootWindow && rootWindow.screenshotCapturing) ? 0 : 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // ── Risoluzione Icone Applicazioni (Zen, Discord, Foot, OBS, etc.) ─────────────
    function resolveAppIcon(appClass) {
        if (!appClass || appClass === "") return "";
        const lower = appClass.toLowerCase();

        // Supporto dedicato OBS Studio
        if (lower.indexOf("obs") !== -1) {
            return Quickshell.iconPath("com.obsproject.Studio") || Quickshell.iconPath("obs") || "";
        }

        const overrides = {
            "zen": "zen-browser",
            "zen-alpha": "zen-browser",
            "zen-browser": "zen-browser",
            "foot": "foot",
            "footclient": "foot",
            "discord": "discord",
            "webcord": "discord",
            "vesktop": "discord",
            "spotify": "spotify",
            "code": "vscode",
            "code-url-handler": "vscode",
            "com.microsoft.vscode": "vscode",
            "visual-studio-code": "vscode",
            "vscodium": "vscodium",
            "draw-io": "drawio",
            "drawio": "drawio",
            "draw.io": "drawio",
            "firefox": "firefox",
            "firefox-developer-edition": "firefox-developer-edition",
            "google-chrome": "google-chrome",
            "google-chrome-stable": "google-chrome",
            "chromium": "chromium",
            "steam": "steam",
            "thunar": "system-file-manager",
            "nautilus": "org.gnome.Nautilus",
            "org.gnome.nautilus": "org.gnome.Nautilus",
            "dolphin": "system-file-manager",
            "kitty": "kitty",
            "alacritty": "Alacritty",
            "wezterm": "org.wezfurlong.wezterm",
            "org.wezfurlong.wezterm": "org.wezfurlong.wezterm",
            "pavucontrol": "pavucontrol",
            "org.pulseaudio.pavucontrol": "pavucontrol",
            "obs": "com.obsproject.Studio",
            "obs-studio": "com.obsproject.Studio",
            "com.obsproject.studio": "com.obsproject.Studio",
            "telegramdesktop": "telegram",
            "org.telegram.desktop": "telegram",
            "telegram": "telegram",
            "com.gabm.satty": "satty",
            "satty": "satty",
            "localsend": "localsend",
            "localsend_app": "localsend",
            "teams": "teams-for-linux",
            "teams-for-linux": "teams-for-linux",
            "whatsapp": "whatsapp-linux-desktop",
            "whatsapp-linux-desktop": "whatsapp-linux-desktop",
            "zathura": "org.pwmt.zathura",
            "org.pwmt.zathura": "org.pwmt.zathura",
            "mpv": "mpv",
            "btop": "btop",
            "yazi": "yazi",
            "scrcpy": "scrcpy",
            "notion": "notion"
        };

        function tryIcon(name) {
            if (!name || name === "") return "";
            if (Array.isArray(name)) {
                for (var i = 0; i < name.length; i++) {
                    var res = Quickshell.iconPath(name[i]);
                    if (res && res !== "") return res;
                }
                return "";
            }
            return Quickshell.iconPath(name) || "";
        }

        if (overrides[lower]) {
            const p = tryIcon(overrides[lower]);
            if (p && p !== "") return p;
        }

        if (overrides[appClass]) {
            const p = tryIcon(overrides[appClass]);
            if (p && p !== "") return p;
        }

        let p = tryIcon(appClass);
        if (p && p !== "") return p;

        p = tryIcon(lower);
        if (p && p !== "") return p;

        const parts = appClass.split(".");
        if (parts.length > 1) {
            const lastPart = parts[parts.length - 1];
            p = tryIcon(lastPart) || tryIcon(lastPart.toLowerCase());
            if (p && p !== "") return p;
        }

        return "";
    }

    // ── Recupero Client e Workspace da Hyprland ────────────────────────────────
    Process {
        id: fetchClientsProcess
        command: ["hyprctl", "clients", "-j"]
        running: false

        stdout: StdioCollector {
            onDataChanged: {
                if (!data) return;
                try {
                    const parsed = JSON.parse(data);
                    const appMap = {};
                    const occMap = {};

                    for (let i = 0; i < parsed.length; i++) {
                        const win = parsed[i];
                        if (!win.mapped || !win.workspace) continue;
                        const wsId = win.workspace.id;
                        if (wsId < 1 || wsId > root.totalWorkspaces) continue;

                        occMap[wsId] = true;

                        const appClass = String(win.class || win.initialClass || "").trim();
                        if (appClass === "") continue;

                        const area = (win.size && win.size.length >= 2) ? (win.size[0] * win.size[1]) : 0;
                        const iconRes = root.resolveAppIcon(appClass);
                        const existing = appMap[wsId];
                        if (!existing || area > existing.area) {
                            appMap[wsId] = {
                                clazz: appClass,
                                area: area,
                                icon: iconRes
                            };
                        }
                    }

                    if (Hyprland.workspaces && Hyprland.workspaces.values) {
                        const hws = Hyprland.workspaces.values;
                        for (let j = 0; j < hws.length; j++) {
                            const hid = hws[j].id;
                            if (hid >= 1 && hid <= root.totalWorkspaces) {
                                occMap[hid] = true;
                            }
                        }
                    }

                    root.wsAppMap = appMap;
                    root.occupiedSet = occMap;
                } catch (e) {
                    console.log("[WorkspaceFloatingIsland] Parse error:", e);
                }
            }
        }
    }

    Timer {
        id: refreshDebounce
        interval: 80
        repeat: false
        onTriggered: {
            if (!fetchClientsProcess.running) {
                fetchClientsProcess.running = true;
            }
        }
    }

    function triggerRefresh() {
        refreshDebounce.restart();
    }

    Component.onCompleted: {
        triggerRefresh();
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event) return;
            const ev = event.name;
            if (ev === "openwindow" || ev === "closewindow" || ev === "movewindow" || 
                ev === "workspace" || ev === "workspacev2" || ev === "focusedmon" || 
                ev === "focusedmonv2" || ev === "createworkspace" || ev === "destroyworkspace") {
                root.triggerRefresh();
            }
        }
        function onFocusedWorkspaceChanged() {
            root.triggerRefresh();
        }
    }

    property int _wheelAccumulator: 0
    property bool _scrollCooldown: false

    Timer {
        id: wheelResetTimer
        interval: 350
        repeat: false
        onTriggered: root._wheelAccumulator = 0
    }

    Timer {
        id: scrollCooldownTimer
        interval: 160
        repeat: false
        onTriggered: root._scrollCooldown = false
    }

    function handleWheelScroll(wheel) {
        if (!wheel) return;
        let delta = wheel.angleDelta.y;
        if (delta === 0 && wheel.angleDelta.x !== 0) {
            delta = -wheel.angleDelta.x;
        }
        if (delta === 0) return;

        root._wheelAccumulator += delta;
        wheelResetTimer.restart();

        // 60 threshold accommodates standard mouse notches (120) and trackpad swipes
        if (Math.abs(root._wheelAccumulator) >= 60 && !root._scrollCooldown) {
            const isUp = root._wheelAccumulator > 0;
            root._wheelAccumulator = 0;
            root._scrollCooldown = true;
            scrollCooldownTimer.restart();
            // Up/left = previous workspace (-1), Down/right = next workspace (+1)
            root.scrollStep(isUp ? -1 : 1);
        }
    }

    function scrollStep(direction) {
        let cur = root.currentWorkspace;
        let target = cur + direction;
        if (target < 1) target = 1;
        if (target > root.totalWorkspaces) target = root.totalWorkspaces;
        if (target === cur) return;

        root.switchToWorkspace(target);
    }

    function switchToWorkspace(wsId) {
        if (wsId < 1 || wsId > root.totalWorkspaces) return;
        try {
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })");
        } catch (e) {}

        try {
            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsId + " })"]);
        } catch (e2) {
            Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsId)]);
        }
    }

    // ── MouseArea Globale per Scroll e RightClick ─────────────────────────────
    MouseArea {
        id: pillHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (rootWindow && rootWindow.openOverviewEverywhere) {
                    rootWindow.openOverviewEverywhere();
                } else if (rootWindow && rootWindow.toggleOverviewEverywhere) {
                    rootWindow.toggleOverviewEverywhere();
                }
            }
        }
        onWheel: function(wheel) {
            root.handleWheelScroll(wheel);
            wheel.accepted = true;
        }
    }

    // ── Contenitore dei 5 Workspace ──────────────────────────────────────────
    Item {
        id: wsContainer
        anchors.centerIn: parent
        width: root.totalWorkspaces * root.itemSize + (root.totalWorkspaces - 1) * root.itemSpacing
        height: root.itemSize

        // ── 1. Capsule Background per Workspace Occupati ─────────────────────────
        Repeater {
            model: root.totalWorkspaces
            delegate: Rectangle {
                id: occupiedBgSlice
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isOcc: (root.occupiedSet[wsId] === true || wsId === root.currentWorkspace)
                readonly property bool prevOcc: (index > 0 && (root.occupiedSet[wsId - 1] === true || (wsId - 1) === root.currentWorkspace))
                readonly property bool nextOcc: (index < root.totalWorkspaces - 1 && (root.occupiedSet[wsId + 1] === true || (wsId + 1) === root.currentWorkspace))

                x: index * (root.itemSize + root.itemSpacing)
                y: 0
                width: root.itemSize + (nextOcc ? root.itemSpacing : 0)
                height: root.itemSize
                visible: isOcc

                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                topLeftRadius: prevOcc ? 0 : root.itemSize / 2
                bottomLeftRadius: prevOcc ? 0 : root.itemSize / 2
                topRightRadius: nextOcc ? 0 : root.itemSize / 2
                bottomRightRadius: nextOcc ? 0 : root.itemSize / 2
                z: 1
            }
        }

        // ── 2. Indicatore Workspace Attivo (Bolla Iris Accent Fluida) ───────────────────
        Rectangle {
            id: activeBubble
            width: root.itemSize
            height: root.itemSize
            radius: root.itemSize / 2
            color: root.accentColor
            z: 2

            visible: root.currentWorkspace >= 1 && root.currentWorkspace <= root.totalWorkspaces
            x: (root.currentWorkspace >= 1 && root.currentWorkspace <= root.totalWorkspaces) 
               ? (root.currentWorkspace - 1) * (root.itemSize + root.itemSpacing) 
               : 0
            y: 0

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ── 3. Slot Workspace (Icona App / Bolla / Puntino) ───────────────────────
        Repeater {
            model: root.totalWorkspaces
            delegate: Item {
                id: wsSlot
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: (wsId === root.currentWorkspace)
                readonly property bool isOccupied: (root.occupiedSet[wsId] === true || isActive)
                readonly property var appInfo: root.wsAppMap[wsId]
                readonly property string appIconSource: appInfo ? (appInfo.icon || "") : ""
                readonly property bool hasAppIcon: root.showAppIcons && appIconSource !== ""

                x: index * (root.itemSize + root.itemSpacing)
                y: 0
                width: root.itemSize
                height: root.itemSize
                z: 3

                // Icona dell'Applicazione tonda con tinta dinamica M3/Iris
                ClippingRectangle {
                    id: slotAppIconFrame
                    anchors.centerIn: parent
                    width: Math.round(root.itemSize * 0.82)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    antialiasing: true
                    clip: true
                    visible: wsSlot.hasAppIcon && !slotAppIcon.loadError

                    Image {
                        id: slotAppIcon
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: wsSlot.appIconSource
                        sourceSize: Qt.size(width * 2, width * 2)
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        smooth: true
                        visible: false
                        property bool loadError: false

                        onStatusChanged: {
                            if (status === Image.Error) {
                                loadError = true;
                            } else if (status === Image.Ready) {
                                loadError = false;
                            }
                        }
                    }

                    MultiEffect {
                        anchors.fill: slotAppIcon
                        source: slotAppIcon
                        colorization: 0.50
                        colorizationColor: root.accentColor
                        brightness: 0.0
                        visible: !slotAppIcon.loadError
                    }
                }

                // Numero del Workspace (mostrato solo se non c'è icona app o se l'immagine fallisce)
                Text {
                    id: slotText
                    anchors.centerIn: parent
                    text: String(wsSlot.wsId)
                    font.family: root.textFontFamily
                    font.pixelSize: Math.round(root.itemSize * 0.44)
                    font.weight: wsSlot.isActive ? Font.Bold : Font.DemiBold
                    color: wsSlot.isActive ? "#000000" : root.textColor
                    visible: (!wsSlot.hasAppIcon || slotAppIcon.loadError) && (wsSlot.isActive || wsSlot.isOccupied)
                }

                // Puntino minimale per workspace vuoto / non occupato (esattamente come nello screenshot)
                Rectangle {
                    id: emptyDot
                    anchors.centerIn: parent
                    width: Math.round(root.itemSize * 0.20)
                    height: width
                    radius: width / 2
                    color: root.dimColor
                    visible: !wsSlot.isActive && !wsSlot.isOccupied
                }

                // Clic sul singolo workspace per commutare
                MouseArea {
                    id: itemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            root.switchToWorkspace(wsSlot.wsId);
                        } else if (mouse.button === Qt.RightButton) {
                            if (rootWindow && rootWindow.openOverviewEverywhere) {
                                rootWindow.openOverviewEverywhere();
                            } else if (rootWindow && rootWindow.toggleOverviewEverywhere) {
                                rootWindow.toggleOverviewEverywhere();
                            }
                        }
                    }

                    onWheel: function(wheel) {
                        root.handleWheelScroll(wheel);
                        wheel.accepted = true;
                    }
                }
            }
        }
    }
}
