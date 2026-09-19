import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import IslandBackend
import "../common"

FocusScope {
    id: root

    signal closeRequested()

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property color accentColor: "#60a5fa"

    anchors.fill: parent
    focus: showCondition
    opacity: showCondition ? 1 : 0
    scale: showCondition ? 1.0 : 0.88
    transformOrigin: Item.Center

    Behavior on opacity {
        NumberAnimation {
            duration: root.showCondition ? 220 : 140
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.showCondition ? 260 : 160
            easing.type: Easing.OutBack
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        }
    }
    Keys.onEscapePressed: (event) => {
        root.closeRequested();
        event.accepted = true;
    }

    Process {
        id: lockProcess
        command: ["/home/lollo/.scripts/qslock-wrapper.sh"]
        running: false
    }

    Process {
        id: sleepProcess
        command: ["systemctl", "suspend"]
        running: false
    }

    Process {
        id: restartProcess
        command: ["systemctl", "reboot"]
        running: false
    }

    Process {
        id: shutdownProcess
        command: ["systemctl", "poweroff"]
        running: false
    }

    // Dismiss if background within capsule is clicked
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    HoverHandler {
        id: layerHoverHandler
    }

    Timer {
        id: autoCloseTimer
        interval: 4000
        repeat: false
        onTriggered: {
            if (!layerHoverHandler.hovered && root.showCondition)
                root.closeRequested();
        }
    }

    Connections {
        target: layerHoverHandler
        function onHoveredChanged() {
            if (!layerHoverHandler.hovered && root.showCondition) {
                autoCloseTimer.restart();
            } else {
                autoCloseTimer.stop();
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 20

        Repeater {
            model: [
                {
                    id: "lock",
                    glyph: "\uf023",
                    name: "Blocca",
                    accentColor: "#c084fc",
                    action: () => {
                        lockProcess.running = true;
                        root.closeRequested();
                    }
                },
                {
                    id: "sleep",
                    glyph: "\uf186",
                    name: "Sospendi",
                    accentColor: "#60a5fa",
                    action: () => {
                        sleepProcess.running = true;
                        root.closeRequested();
                    }
                },
                {
                    id: "restart",
                    glyph: "\uf021",
                    name: "Riavvia",
                    accentColor: "#fbbf24",
                    action: () => {
                        restartProcess.running = true;
                        root.closeRequested();
                    }
                },
                {
                    id: "shutdown",
                    glyph: "\uf011",
                    name: "Spegni",
                    accentColor: "#f87171",
                    action: () => {
                        shutdownProcess.running = true;
                        root.closeRequested();
                    }
                }
            ]

            delegate: Item {
                id: btnItem
                width: 54
                height: 54

                Rectangle {
                    id: btnBg
                    anchors.fill: parent
                    radius: width / 2
                    color: btnMouse.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.16)
                        : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: btnMouse.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.28)
                        : Qt.rgba(1, 1, 1, 0.12)
                    scale: btnMouse.pressed ? 0.92 : (btnMouse.containsMouse ? 1.08 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        font.pixelSize: 24
                        font.family: root.iconFontFamily
                        color: btnMouse.containsMouse ? modelData.accentColor : StyleTokens.textPrimary

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.action()
                }
            }
        }
    }
}
