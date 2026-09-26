import "../common"
import IslandBackend
import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

FocusScope {
    id: root

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property color accentColor: "#60a5fa"
    property int activeIndex: 0
    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")
    readonly property var powerActions: [{
        "id": "lock",
        "glyph": "\uf023",
        "accentColor": irisColors.purpleHex !== "" ? irisColors.purpleHex : "#c084fc",
        "command": root.homeDir + "/.scripts/qslock-wrapper.sh"
    }, {
        "id": "logout",
        "glyph": "\uf2f5",
        "accentColor": irisColors.greenHex !== "" ? irisColors.greenHex : "#34d399",
        "command": "hyprctl dispatch exit"
    }, {
        "id": "sleep",
        "glyph": "\uf186",
        "accentColor": irisColors.blueHex !== "" ? irisColors.blueHex : (irisColors.accentHex !== "" ? irisColors.accentHex : "#60a5fa"),
        "command": "systemctl suspend"
    }, {
        "id": "restart",
        "glyph": "\uf021",
        "accentColor": irisColors.yellowHex !== "" ? irisColors.yellowHex : "#fbbf24",
        "command": "systemctl reboot"
    }, {
        "id": "shutdown",
        "glyph": "\uf011",
        "accentColor": irisColors.redHex !== "" ? irisColors.redHex : "#f87171",
        "command": "systemctl poweroff"
    }]

    signal closeRequested()

    function runCealestiaCommand(cmd) {
        var finalCmd = cmd.trim();
        var fullBash = "nohup setsid " + finalCmd + " >/dev/null 2>&1 &";
        try {
            Quickshell.execDetached(["bash", "-c", fullBash]);
        } catch (e) {
            console.warn("[PowerMenuLayer] execDetached bash failed, attempting direct exec:", e);
            try {
                Quickshell.execDetached(finalCmd.split(" "));
            } catch (e2) {
                console.warn("[PowerMenuLayer] direct execDetached failed:", e2);
            }
        }
    }

    function triggerAction(cmd) {
        runCealestiaCommand(cmd);
        root.closeRequested();
    }

    anchors.fill: parent
    focus: showCondition
    opacity: showCondition ? 1 : 0
    scale: showCondition ? 1 : 0.9
    transformOrigin: Item.Center
    onShowConditionChanged: {
        if (showCondition) {
            root.activeIndex = 0;
            root.forceActiveFocus();
            autoCloseTimer.restart();
        } else {
            autoCloseTimer.stop();
        }
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
            if (root.activeIndex >= 0 && root.activeIndex < powerActions.length)
                triggerAction(powerActions[root.activeIndex].command);

            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            triggerAction(root.homeDir + "/.scripts/qslock-wrapper.sh");
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

    FileView {
        id: irisColors

        property string accentHex: ""
        property string redHex: ""
        property string greenHex: ""
        property string yellowHex: ""
        property string purpleHex: ""
        property string blueHex: ""
        property string fgHex: ""
        property string bgHex: ""
        property string surfaceHex: ""

        path: root.homeDir + "/.cache/iris/colors.json"
        watchChanges: true
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text());
                if (d) {
                    accentHex = d.accent || "";
                    redHex = d.red || d.syntax_param || "";
                    greenHex = d.green || d.syntax_const || "";
                    yellowHex = d.yellow || d.syntax_operator || "";
                    purpleHex = d.syntax_type || d.syntax_keyword || "";
                    blueHex = d.syntax_func || d.accent || "";
                    fgHex = d.fg || "";
                    bgHex = d.bg || "";
                    surfaceHex = d.surface || "";
                }
            } catch (e) {
            }
        }
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
        function onHoveredChanged() {
            if (!layerHoverHandler.hovered && root.showCondition)
                autoCloseTimer.restart();
            else
                autoCloseTimer.stop();
        }

        target: layerHoverHandler
    }

    // Centered Row of Minimal Glass Action Buttons
    Row {
        anchors.centerIn: parent
        spacing: 14

        Repeater {
            model: root.powerActions

            delegate: Item {
                id: cardItem

                required property int index
                required property var modelData
                readonly property bool isSelected: root.activeIndex === index
                readonly property bool isHovered: cardMouse.containsMouse

                width: 56
                height: 56

                Rectangle {
                    id: cardBg

                    anchors.fill: parent
                    radius: 18
                    color: {
                        if (cardItem.isSelected || cardItem.isHovered)
                            return Qt.rgba(modelData.accentColor.r, modelData.accentColor.g, modelData.accentColor.b, 0.22);

                        return Qt.rgba(1, 1, 1, 0.06);
                    }
                    border.width: (cardItem.isSelected || cardItem.isHovered) ? 1.5 : 1
                    border.color: {
                        if (cardItem.isSelected || cardItem.isHovered)
                            return modelData.accentColor;

                        return Qt.rgba(1, 1, 1, 0.1);
                    }
                    scale: cardMouse.pressed ? 0.94 : ((cardItem.isSelected || cardItem.isHovered) ? 1.08 : 1)

                    // Centered Icon
                    Text {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        font.pixelSize: 24
                        font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                        color: (cardItem.isSelected || cardItem.isHovered) ? modelData.accentColor : "#dcdfe8"

                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }

                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 140
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

}
