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

    property int activeIndex: 0

    anchors.fill: parent
    focus: showCondition
    opacity: showCondition ? 1 : 0
    scale: showCondition ? 1.0 : 0.90
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

    onShowConditionChanged: {
        if (showCondition) {
            root.activeIndex = 0;
            root.forceActiveFocus();
            autoCloseTimer.restart();
        } else {
            autoCloseTimer.stop();
        }
    }

    readonly property var powerActions: [
        {
            id: "lock",
            glyph: "\uf023",
            name: "Blocca",
            keyHint: "L",
            accentColor: "#c084fc",
            command: "/home/lollo/.scripts/qslock-wrapper.sh"
        },
        {
            id: "logout",
            glyph: "\uf2f5",
            name: "Esci",
            keyHint: "E",
            accentColor: "#34d399",
            command: "hyprctl dispatch exit"
        },
        {
            id: "sleep",
            glyph: "\uf186",
            name: "Sospendi",
            keyHint: "U",
            accentColor: "#60a5fa",
            command: "systemctl suspend"
        },
        {
            id: "restart",
            glyph: "\uf021",
            name: "Riavvia",
            keyHint: "R",
            accentColor: "#fbbf24",
            command: "systemctl reboot"
        },
        {
            id: "shutdown",
            glyph: "\uf011",
            name: "Spegni",
            keyHint: "S",
            accentColor: "#f87171",
            command: "systemctl poweroff"
        }
    ]

    function runCealestiaCommand(cmd) {
        var finalCmd = cmd.trim();
        var fullBash = "nohup setsid " + finalCmd + " >/dev/null 2>&1 &";
        try {
            Quickshell.execDetached(["bash", "-c", fullBash]);
        } catch(e) {
            console.warn("[PowerMenuLayer] execDetached bash failed, attempting direct exec:", e);
            try {
                Quickshell.execDetached(finalCmd.split(" "));
            } catch(e2) {
                console.warn("[PowerMenuLayer] direct execDetached failed:", e2);
            }
        }
    }

    function triggerAction(cmd) {
        runCealestiaCommand(cmd);
        root.closeRequested();
    }

    Keys.onPressed: (event) => {
        autoCloseTimer.restart();

        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            root.activeIndex = (root.activeIndex - 1 + powerActions.length) % powerActions.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            root.activeIndex = (root.activeIndex + 1) % powerActions.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Backtab) {
            root.activeIndex = (root.activeIndex - 1 + powerActions.length) % powerActions.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (root.activeIndex >= 0 && root.activeIndex < powerActions.length) {
                triggerAction(powerActions[root.activeIndex].command);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            triggerAction("/home/lollo/.scripts/qslock-wrapper.sh");
            event.accepted = true;
        } else if (event.key === Qt.Key_E) {
            triggerAction("hyprctl dispatch exit");
            event.accepted = true;
        } else if (event.key === Qt.Key_U) {
            triggerAction("systemctl suspend");
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            triggerAction("systemctl reboot");
            event.accepted = true;
        } else if (event.key === Qt.Key_S) {
            triggerAction("systemctl poweroff");
            event.accepted = true;
        }
    }

    Keys.onEscapePressed: (event) => {
        root.closeRequested();
        event.accepted = true;
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
        interval: 6000
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

    // Centered Row of Action Cards
    Row {
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: root.powerActions

            delegate: Item {
                id: cardItem
                required property int index
                required property var modelData

                readonly property bool isSelected: root.activeIndex === index
                readonly property bool isHovered: cardMouse.containsMouse

                width: 74
                height: 80

                Rectangle {
                    id: cardBg
                    anchors.fill: parent
                    radius: 18

                    color: {
                        if (cardItem.isSelected || cardItem.isHovered) {
                            return Qt.rgba(modelData.accentColor.r, modelData.accentColor.g, modelData.accentColor.b, 0.22);
                        }
                        return Qt.rgba(1, 1, 1, 0.05);
                    }

                    border.width: (cardItem.isSelected || cardItem.isHovered) ? 1.5 : 1
                    border.color: {
                        if (cardItem.isSelected || cardItem.isHovered) {
                            return modelData.accentColor;
                        }
                        return Qt.rgba(1, 1, 1, 0.10);
                    }

                    scale: cardMouse.pressed ? 0.94 : ((cardItem.isSelected || cardItem.isHovered) ? 1.05 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 140 }
                    }

                    // Key Hint Badge (Subtle top right letter badge)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 6
                        anchors.rightMargin: 6
                        width: 14
                        height: 14
                        radius: 4
                        color: (cardItem.isSelected || cardItem.isHovered)
                            ? Qt.rgba(modelData.accentColor.r, modelData.accentColor.g, modelData.accentColor.b, 0.35)
                            : Qt.rgba(1, 1, 1, 0.07)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.keyHint
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            color: (cardItem.isSelected || cardItem.isHovered) ? "#ffffff" : "#7c7f93"
                        }
                    }

                    // Card Content: Glyphs + Label
                    Column {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1
                        spacing: 6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.glyph
                            font.pixelSize: 22
                            font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                            color: (cardItem.isSelected || cardItem.isHovered) ? modelData.accentColor : "#e2e4ea"

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            font.pixelSize: 11
                            font.weight: (cardItem.isSelected || cardItem.isHovered) ? Font.DemiBold : Font.Normal
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            color: (cardItem.isSelected || cardItem.isHovered) ? "#ffffff" : "#9ca0b0"

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }
                        }
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        root.activeIndex = cardItem.index;
                        autoCloseTimer.restart();
                    }
                    onClicked: {
                        root.triggerAction(modelData.command);
                    }
                }
            }
        }
    }
}
