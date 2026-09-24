import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string title: ""
    property string description: ""
    property string icon: ""
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    property string suffix: ""
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    signal valueModified(real newValue)

    width: parent ? parent.width : 500
    height: 48

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: sliderControl.left
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

    Row {
        id: sliderControl
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Slider {
            id: slider
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            anchors.verticalCenter: parent.verticalCenter
            width: 140

            onMoved: {
                root.value = value;
                root.valueModified(value);
            }

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 140
                implicitHeight: 6
                width: slider.availableWidth
                height: 6
                radius: 3
                color: Qt.rgba(255, 255, 255, 0.12)

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: root.accentColor
                    radius: 3
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: "#ffffff"
                border.width: 2
                border.color: root.accentColor
                scale: slider.pressed ? 1.2 : (slider.hovered ? 1.1 : 1.0)

                Behavior on scale {
                    NumberAnimation { duration: 120 }
                }
            }
        }

        Rectangle {
            width: 58
            height: 26
            radius: 6
            color: Qt.rgba(255, 255, 255, 0.06)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: Math.round(root.value * 10) / 10 + (root.suffix !== "" ? " " + root.suffix : "")
                color: "#e2e6ee"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.family: root.textFontFamily
            }
        }
    }
}
