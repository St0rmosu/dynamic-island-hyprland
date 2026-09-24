import QtQuick

Item {
    id: root

    property string title: ""
    property string description: ""
    property var model: [] // array of { text: "", value: "" }
    property var currentValue: ""
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"

    signal selected(var val)

    width: parent ? parent.width : 500
    height: 48

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: pillRow.left
        anchors.rightMargin: 16
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

    Rectangle {
        id: pillRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 32
        radius: 8
        color: Qt.rgba(255, 255, 255, 0.06)
        width: rowLayout.width + 6

        Row {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 3

            Repeater {
                model: root.model

                Rectangle {
                    readonly property bool isSelected: root.currentValue === modelData.value
                    width: btnText.contentWidth + 20
                    height: 26
                    radius: 6
                    color: isSelected ? root.accentColor : (btnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    Text {
                        id: btnText
                        anchors.centerIn: parent
                        text: modelData.text
                        font.pixelSize: 11
                        font.weight: isSelected ? Font.DemiBold : Font.Normal
                        font.family: root.textFontFamily
                        color: isSelected ? "#ffffff" : "#a2a8b8"
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.currentValue = modelData.value;
                            root.selected(modelData.value);
                        }
                    }
                }
            }
        }
    }
}
