import QtQuick
import QtQuick.Shapes
import IslandBackend
import "../island"

Item {
    id: notificationCenter

    signal clearAllRequested()

    property var notificationModel: null
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily

    readonly property bool hasNotifications: notificationModel && notificationModel.count > 0
    readonly property real contentHeight: 218
    readonly property real verticalPadding: 10
    readonly property real horizontalPadding: 22

    NotificationHistory {
        id: notificationHistory

        anchors.fill: parent
        anchors.topMargin: notificationCenter.verticalPadding
        anchors.bottomMargin: notificationCenter.verticalPadding
        anchors.leftMargin: notificationCenter.horizontalPadding
        anchors.rightMargin: notificationCenter.horizontalPadding
        notificationModel: notificationCenter.notificationModel
        iconFontFamily: notificationCenter.iconFontFamily
        textFontFamily: notificationCenter.textFontFamily
        heroFontFamily: notificationCenter.heroFontFamily
    }

    // Keep the action inside the first notification card so it does not create
    // a separate black toolbar above the list.
    Item {
        id: clearButton

        z: 100
        opacity: notificationCenter.hasNotifications ? 1 : 0.5
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: notificationCenter.verticalPadding + 3
        anchors.rightMargin: notificationCenter.horizontalPadding + 2
        width: 26
        height: 26

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: trashBg

            anchors.fill: parent
            radius: width / 2
            color: clearMouse.pressed ? "#55ff453a" : (clearMouse.containsMouse ? "#26ff453a" : StyleTokens.transparent)
            border.width: 1
            border.color: clearMouse.containsMouse ? "#55ff453a" : "#14ffffff"
            scale: clearMouse.pressed ? 0.90 : (clearMouse.containsMouse ? 1.05 : 1.0)

            Behavior on scale {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.centerIn: parent
                text: "\uf1f8"
                font.pixelSize: 12
                font.family: notificationCenter.iconFontFamily
                color: clearMouse.containsMouse ? "#ff453a" : StyleTokens.textDim

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }

        MouseArea {
            id: clearMouse

            anchors.fill: parent
            enabled: notificationCenter.hasNotifications
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: notificationCenter.clearAllRequested()
        }
    }
}
