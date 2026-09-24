import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string title: ""
    property string description: ""
    property string icon: ""
    property bool checked: false
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    signal toggled(bool newState)

    width: parent ? parent.width : 500
    height: 48

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: switchItem.left
        anchors.rightMargin: 16
        spacing: 12

        Rectangle {
            visible: root.icon !== ""
            width: 32
            height: 32
            radius: 8
            color: Qt.rgba(255, 255, 255, 0.05)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.accentColor
                font.family: root.iconFontFamily
                font.pixelSize: 14
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.title
                color: "#f2f4f8"
                font.pixelSize: 13
                font.weight: Font.Medium
                font.family: root.textFontFamily
            }

            Text {
                visible: root.description !== ""
                text: root.description
                color: "#7e889b"
                font.pixelSize: 11
                font.family: root.textFontFamily
            }
        }
    }

    Rectangle {
        id: switchItem
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 24
        radius: 12
        color: root.checked ? root.accentColor : Qt.rgba(255, 255, 255, 0.12)

        Behavior on color {
            ColorAnimation { duration: 160 }
        }

        Rectangle {
            id: thumb
            width: 18
            height: 18
            radius: 9
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3

            Behavior on x {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.checked = !root.checked;
                root.toggled(root.checked);
            }
        }
    }
}
