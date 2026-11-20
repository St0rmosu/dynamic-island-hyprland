import QtQuick
import IslandBackend

Item {
    id: root

    property bool active: false
    property real contentOpacity: 1
    property color accentColor: StyleTokens.accent
    property color dotColor: "#ff453a"
    property string iconText: "\u{F0379}"
    property string iconFontFamily: "Font Awesome 6 Free, JetBrainsMono Nerd Font, sans-serif"

    implicitWidth: active ? 10 : 0
    implicitHeight: 10
    width: active ? implicitWidth : 0
    height: 10
    opacity: active ? contentOpacity : 0
    visible: active || opacity > 0.01

    Behavior on width {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.active ? 180 : 220
            easing.type: Easing.InOutQuad
        }
    }

    // Sleek Apple-style minimal pulsating privacy indicator dot
    Rectangle {
        id: halo
        anchors.centerIn: parent
        width: 12
        height: 12
        radius: 6
        color: Qt.rgba(root.dotColor.r, root.dotColor.g, root.dotColor.b, 0.28)
        scale: 1.0

        SequentialAnimation on scale {
            running: root.active
            loops: Animation.Infinite

            NumberAnimation {
                to: 1.25
                duration: 900
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 1.0
                duration: 900
                easing.type: Easing.InOutSine
            }
        }
    }

    Rectangle {
        id: core
        anchors.centerIn: parent
        width: 6.5
        height: 6.5
        radius: 3.25
        color: root.dotColor

        SequentialAnimation on opacity {
            running: root.active
            loops: Animation.Infinite

            NumberAnimation {
                to: 0.45
                duration: 900
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 1.0
                duration: 900
                easing.type: Easing.InOutSine
            }
        }
    }
}
