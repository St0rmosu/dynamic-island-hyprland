import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root

    property bool sattyDirectMode: false
    property color accentColor: "#bdb6a6"
    property color textColor: "#c8c3b6"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property var targetScreen: null
    property real islandCenterX: root.width / 2
    property real islandTopMargin: 8
    property real islandHeight: 40

    // raggio angoli allineato a decoration:rounding di Hyprland (fallback 18)
    property int windowRadius: 18

    Process {
        id: roundingProc
        command: ["hyprctl", "getoption", "decoration:rounding", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const v = JSON.parse(text).int
                    if (v >= 0) root.windowRadius = v
                } catch (e) {}
            }
        }
    }

    signal snipRequested(real x, real y, real w, real h, bool isSatty)
    signal dragUpdated(real w, real h)
    signal cancelRequested()

    anchors.fill: parent

    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(targetScreen)
    readonly property real monitorOffsetX: hyprlandMonitor ? hyprlandMonitor.x : 0
    readonly property real monitorOffsetY: hyprlandMonitor ? hyprlandMonitor.y : 0
    readonly property int activeWorkspaceId: (hyprlandMonitor && hyprlandMonitor.activeWorkspace) ? hyprlandMonitor.activeWorkspace.id : 1

    property var windowRegions: []
    property var hoveredRegion: null

    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property bool dragging: false
    property var mouseButton: Qt.LeftButton

    readonly property real regionWidth: Math.abs(draggingX - dragStartX)
    readonly property real regionHeight: Math.abs(draggingY - dragStartY)
    readonly property real regionX: Math.min(dragStartX, draggingX)
    readonly property real regionY: Math.min(dragStartY, draggingY)

    // 1. Dimming di base dello schermo intero (overlay fluido senza artefatti di screencopy)
    Rectangle {
        anchors.fill: parent
        color: "#45000000"
    }

    // 3. Highlight della finestra sotto il cursore (stile ii TargetRegion)
    Item {
        id: windowHighlight
        visible: !root.dragging && root.hoveredRegion !== null
        z: 2
        x: root.hoveredRegion ? root.hoveredRegion.x : 0
        y: root.hoveredRegion ? root.hoveredRegion.y : 0
        width: root.hoveredRegion ? root.hoveredRegion.w : 0
        height: root.hoveredRegion ? root.hoveredRegion.h : 0

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
            border.color: root.accentColor
            border.width: 2.5
            radius: root.windowRadius
        }

        // Badge con nome applicazione / classe finestra
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 10
            color: Qt.rgba(0, 0, 0, 0.88)
            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)
            border.width: 1
            radius: 7
            height: 24
            width: rowBadge.width + 16

            Row {
                id: rowBadge
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "\uf2d0"
                    color: root.accentColor
                    font.family: root.iconFontFamily
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.hoveredRegion ? (root.hoveredRegion.class + (root.hoveredRegion.title ? (" • " + root.hoveredRegion.title) : "")) : ""
                    color: root.textColor
                    font.family: root.textFontFamily
                    font.pixelSize: 11
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(paintedWidth, 320)
                }
            }
        }
    }

    // 4. Rettangolo di selezione durante il trascinamento (Drag)
    Item {
        id: selectionBox
        visible: root.dragging && root.regionWidth > 2 && root.regionHeight > 2
        z: 3
        x: root.regionX
        y: root.regionY
        width: root.regionWidth
        height: root.regionHeight

        // Bordo selezione accent
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08)
            border.color: root.accentColor
            border.width: 2
            radius: root.windowRadius
        }

        // Badge dimensioni (W × H px)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 6
            color: Qt.rgba(0, 0, 0, 0.88)
            border.color: root.accentColor
            border.width: 1
            radius: 6
            height: 22
            width: txtDim.width + 12

            Text {
                id: txtDim
                anchors.centerIn: parent
                text: Math.round(root.regionWidth) + " × " + Math.round(root.regionHeight) + " px"
                color: root.textColor
                font.family: root.textFontFamily
                font.pixelSize: 10
                font.bold: true
            }
        }
    }

    // 5. Rilevamento finestre con hyprctl clients -j
    Process {
        id: fetchClients
        command: ["hyprctl", "clients", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text)
                    const arr = []
                    const wid = root.activeWorkspaceId
                    const ox = root.monitorOffsetX
                    const oy = root.monitorOffsetY
                    for (const w of list) {
                        if (!w.mapped || w.hidden) continue
                        if (w.workspace && w.workspace.id !== wid) continue
                        arr.push({
                            x: w.at[0] - ox,
                            y: w.at[1] - oy,
                            w: w.size[0],
                            h: w.size[1],
                            floating: !!w.floating,
                            class: w.class || w.initialClass || "Finestra",
                            title: w.title || ""
                        })
                    }
                    arr.sort((a, b) => (a.floating === b.floating ? 0 : (a.floating ? -1 : 1)))
                    root.windowRegions = arr
                } catch (e) {}
            }
        }
    }

    // 6. Area mouse a schermo intero
    MouseArea {
        id: screenMouseArea
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        focus: true
        Component.onCompleted: screenMouseArea.forceActiveFocus()

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.cancelRequested()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                const sw = root.width > 0 ? root.width : 1920
                const sh = root.height > 0 ? root.height : 1080
                root.snipRequested(0, 0, sw, sh, root.sattyDirectMode)
                event.accepted = true
            }
        }

        onPressed: (mouse) => {
            // Se il click è all'interno dell'isola in alto, non iniziare drag per consentire i tasti
            const capsuleMaxY = root.islandTopMargin + root.islandHeight + 16
            if (mouse.y <= capsuleMaxY && Math.abs(mouse.x - root.islandCenterX) <= 160) {
                mouse.accepted = false
                return
            }

            root.dragStartX = mouse.x
            root.dragStartY = mouse.y
            root.draggingX = mouse.x
            root.draggingY = mouse.y
            root.dragging = true
            root.mouseButton = mouse.button
        }

        onPositionChanged: (mouse) => {
            if (!root.dragging) {
                // Se il mouse è nell'area dell'isola in alto, non evidenziare la finestra sottostante
                const capsuleMaxY = root.islandTopMargin + root.islandHeight + 16
                if (mouse.y <= capsuleMaxY && Math.abs(mouse.x - root.islandCenterX) <= 160) {
                    root.hoveredRegion = null
                    return
                }

                let found = null
                for (const r of root.windowRegions) {
                    if (mouse.x >= r.x && mouse.x <= r.x + r.w && mouse.y >= r.y && mouse.y <= r.y + r.h) {
                        found = r
                        break
                    }
                }
                root.hoveredRegion = found
            } else {
                root.draggingX = mouse.x
                root.draggingY = mouse.y
                root.dragUpdated(root.regionWidth, root.regionHeight)
            }
        }

        onReleased: (mouse) => {
            if (!root.dragging) return
            root.dragging = false

            const sw = root.width > 0 ? root.width : 1920
            const sh = root.height > 0 ? root.height : 1080
            const isClick = Math.abs(root.draggingX - root.dragStartX) < 6 && Math.abs(root.draggingY - root.dragStartY) < 6
            const isSatty = root.sattyDirectMode || (root.mouseButton === Qt.RightButton)

            let targetX = 0, targetY = 0, targetW = 0, targetH = 0

            if (isClick) {
                if (root.hoveredRegion) {
                    targetX = root.hoveredRegion.x
                    targetY = root.hoveredRegion.y
                    targetW = root.hoveredRegion.w
                    targetH = root.hoveredRegion.h
                } else {
                    targetX = 0
                    targetY = 0
                    targetW = sw
                    targetH = sh
                }
            } else {
                if (root.regionWidth < 4 || root.regionHeight < 4) {
                    root.cancelRequested()
                    return
                }
                targetX = root.regionX
                targetY = root.regionY
                targetW = root.regionWidth
                targetH = root.regionHeight
            }

            root.visible = false
            root.snipRequested(targetX, targetY, targetW, targetH, isSatty)
        }
    }
}
