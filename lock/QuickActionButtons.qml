import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io

Row {
    id: root

    property int buttonSize: 48

    spacing: 0

    // Left Button: Night Light / Lamp
    Rectangle {
        id: leftBtn
        width: root.buttonSize
        height: root.buttonSize
        radius: height / 2
        color: AppleTokens.surfaceGlassInput
        border.width: 1
        border.color: AppleTokens.hairlineDark

        scale: leftMouse.pressed ? AppleTokens.pressScale : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowBlur: 0.4
            shadowVerticalOffset: 2
        }

        Text {
            anchors.centerIn: parent
            text: "󰌵"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: AppleTokens.bodyOnDark
        }

        MouseArea {
            id: leftMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // Toggle night light / gammastep / hyprsunset if available
                Quickshell.execDetached(["sh", "-c", "pkill -USR1 gammastep || pkill -USR1 wlsunset || hyprsunset --toggle || true"]);
            }
        }
    }

    Item {
        width: 10
        height: 1
    }

    // Right Button: Display Off (DPMS)
    Rectangle {
        id: rightBtn
        width: root.buttonSize
        height: root.buttonSize
        radius: height / 2
        color: AppleTokens.surfaceGlassInput
        border.width: 1
        border.color: AppleTokens.hairlineDark

        scale: rightMouse.pressed ? AppleTokens.pressScale : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.35)
            shadowBlur: 0.4
            shadowVerticalOffset: 2
        }

        Text {
            anchors.centerIn: parent
            text: "󰍹"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 19
            color: AppleTokens.bodyOnDark
        }

        MouseArea {
            id: rightMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "off"]);
            }
        }
    }
}
