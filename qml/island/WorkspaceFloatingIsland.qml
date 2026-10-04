import QtQuick
import QtQuick.Layouts
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
    property color accentColor: StyleTokens.accent

    readonly property string iconFontFamily: rootWindow ? rootWindow.iconFontFamily : "JetBrainsMono Nerd Font"
    readonly property string textFontFamily: rootWindow ? rootWindow.textFontFamily : "Google Sans Flex"

    // Proprietà configurabili
    readonly property bool isEnabled: dynamicConfig ? (dynamicConfig.enableWorkspacePill !== false) : true
    readonly property string positionSide: (dynamicConfig && dynamicConfig.workspacePillPosition) ? dynamicConfig.workspacePillPosition : "right"
    readonly property bool showAppIcons: dynamicConfig ? (dynamicConfig.workspacePillShowAppIcons !== false) : true

    // Esattamente 5 workspace fissi come richiesto
    readonly property int totalWorkspaces: 5

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

    // Posizionamento satellite a fianco dell'orologio (perfettamente allineato)
    anchors.left: (positionSide === "right") ? (targetCapsule ? targetCapsule.right : undefined) : undefined
    anchors.right: (positionSide === "left") ? (targetCapsule ? targetCapsule.left : undefined) : undefined
    anchors.leftMargin: (positionSide === "right") ? 8 : 0
    anchors.rightMargin: (positionSide === "left") ? 8 : 0
    anchors.top: targetCapsule ? targetCapsule.top : undefined

    visible: isEnabled && (!rootWindow || !rootWindow.overviewVisible) && opacity > 0.01
    opacity: isEnabled && (!rootWindow || !rootWindow.overviewVisible) ? (targetCapsule ? targetCapsule.opacity : 1.0) : 0.0
    scale: isEnabled ? 1.0 : 0.8

    clip: true
    color: Qt.rgba(14 / 255, 16 / 255, 22 / 255, (rootWindow ? rootWindow.effectiveIslandBackgroundOpacity : 92) / 100)
    border.width: 1
    border.color: pillHoverArea.containsMouse ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(255, 255, 255, 0.08)

    // Animazioni fluide
    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // ── Risoluzione Icone Applicazioni (Zen, Discord, Foot, etc.) ─────────────
    function resolveAppIcon(appClass) {
        if (!appClass || appClass === "") return "";
        const lower = appClass.toLowerCase();

        const overrides = {
            "zen": "zen-browser",
            "zen-alpha": "zen-browser",
            "foot": "foot",
            "footclient": "foot",
            "discord": "discord",
            "webcord": "discord",
            "vesktop": "discord",
            "spotify": "spotify",
            "code": "visual-studio-code",
            "code-url-handler": "visual-studio-code",
            "vscodium": "vscodium",
            "firefox": "firefox",
            "firefox-developer-edition": "firefox-developer-edition",
            "google-chrome": "google-chrome",
            "chromium": "chromium",
            "steam": "steam",
            "thunar": "system-file-manager",
            "nautilus": "org.gnome.Nautilus",
            "dolphin": "system-file-manager",
            "kitty": "kitty",
            "alacritty": "Alacritty",
            "wezterm": "org.wezfurlong.wezterm",
            "pavucontrol": "pavucontrol",
            "obs": "com.obsproject.Studio",
            "telegramdesktop": "telegram",
            "org.telegram.desktop": "telegram",
            "com.gabm.satty": "satty",
            "satty": "satty"
        };

        if (overrides[lower]) {
            const p = Quickshell.iconPath(overrides[lower]);
            if (p && p !== "") return p;
        }

        let p = Quickshell.iconPath(lower);
        if (p && p !== "") return p;

        p = Quickshell.iconPath(appClass);
        if (p && p !== "") return p;

        const parts = appClass.split(".");
        if (parts.length > 1) {
            const lastPart = parts[parts.length - 1].toLowerCase();
            p = Quickshell.iconPath(lastPart);
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
                        const existing = appMap[wsId];
                        if (!existing || area > existing.area) {
                            appMap[wsId] = {
                                clazz: appClass,
                                area: area,
                                icon: root.resolveAppIcon(appClass)
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
            if (wheel.angleDelta.y > 0) {
                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e-1"]);
            } else if (wheel.angleDelta.y < 0) {
                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e+1"]);
            }
        }
    }

    // ── Contenitore dei 5 Workspace ──────────────────────────────────────────
    Item {
        id: wsContainer
        anchors.centerIn: parent
        width: root.totalWorkspaces * root.itemSize + (root.totalWorkspaces - 1) * root.itemSpacing
        height: root.itemSize

        // ── 1. Capsule Background per Workspace Occupati (stile Logical Impulse) ─
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

                color: Qt.rgba(255, 255, 255, 0.08)
                topLeftRadius: prevOcc ? 0 : root.itemSize / 2
                bottomLeftRadius: prevOcc ? 0 : root.itemSize / 2
                topRightRadius: nextOcc ? 0 : root.itemSize / 2
                bottomRightRadius: nextOcc ? 0 : root.itemSize / 2
                z: 1
            }
        }

        // ── 2. Indicatore Workspace Attivo (Bolla Bianca Fluida) ───────────────────
        Rectangle {
            id: activeBubble
            width: root.itemSize
            height: root.itemSize
            radius: root.itemSize / 2
            color: "#ffffff"
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

                // Icona dell'Applicazione rotonda (ritagliata a cerchio perfetto anche per Foot, Satty, ecc.)
                ClippingRectangle {
                    id: slotAppIconFrame
                    anchors.centerIn: parent
                    width: Math.round(root.itemSize * 0.78)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    antialiasing: true
                    visible: wsSlot.hasAppIcon && !slotAppIcon.loadError

                    Image {
                        id: slotAppIcon
                        anchors.centerIn: parent
                        width: Math.round(slotAppIconFrame.width * 1.25)
                        height: width
                        source: wsSlot.appIconSource
                        sourceSize: Qt.size(width * 2, width * 2)
                        fillMode: Image.PreserveAspectCrop
                        mipmap: true
                        smooth: true
                        property bool loadError: false

                        onStatusChanged: {
                            if (status === Image.Error)
                                loadError = true;
                            else if (status === Image.Ready)
                                loadError = false;
                        }
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
                    color: wsSlot.isActive ? "#0b0d13" : "#f0f3fa"
                    visible: (!wsSlot.hasAppIcon || slotAppIcon.loadError) && (wsSlot.isActive || wsSlot.isOccupied)
                }

                // Puntino minimale per workspace vuoto / non occupato (esattamente come nello screenshot)
                Rectangle {
                    id: emptyDot
                    anchors.centerIn: parent
                    width: Math.round(root.itemSize * 0.20)
                    height: width
                    radius: width / 2
                    color: "#525766"
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
                            try {
                                Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsSlot.wsId + " })");
                            } catch (e) {
                                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsSlot.wsId)]);
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            if (rootWindow && rootWindow.openOverviewEverywhere) {
                                rootWindow.openOverviewEverywhere();
                            } else if (rootWindow && rootWindow.toggleOverviewEverywhere) {
                                rootWindow.toggleOverviewEverywhere();
                            }
                        }
                    }

                    onWheel: function(wheel) {
                        if (wheel.angleDelta.y > 0) {
                            try {
                                Hyprland.dispatch("hl.dsp.focus({ workspace = 'e-1' })");
                            } catch (e) {
                                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e-1"]);
                            }
                        } else if (wheel.angleDelta.y < 0) {
                            try {
                                Hyprland.dispatch("hl.dsp.focus({ workspace = 'e+1' })");
                            } catch (e) {
                                Quickshell.execDetached(["hyprctl", "dispatch", "workspace", "e+1"]);
                            }
                        }
                    }
                }
            }
        }
    }
}
