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

    implicitWidth: pillContainer.implicitWidth
    implicitHeight: 18
    width: active ? implicitWidth : 0
    height: 18
    opacity: active ? contentOpacity : 0
    visible: active || opacity > 0.01
    clip: true

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

    Rectangle {
        id: pillContainer
        anchors.centerIn: parent
        implicitWidth: contentRow.implicitWidth + 8
        height: 18
        radius: 9
        color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)
        border.width: 1
        border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: root.iconText
                color: root.accentColor
                font.pixelSize: 11
                font.family: root.iconFontFamily
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                id: core
                width: 4
                height: 4
                radius: 2
                color: root.dotColor
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: root.active
                    loops: Animation.Infinite

                    PauseAnimation { duration: 110 }
                    NumberAnimation {
                        to: 0.35
                        duration: 800
                        easing.type: Easing.InOutSine
                    }
                    PauseAnimation { duration: 120 }
                    NumberAnimation {
                        to: 1.0
                        duration: 800
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }
}
