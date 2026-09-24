import QtQuick

Row {
    id: root

    property string text: ""
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"

    spacing: 8
    width: parent ? parent.width : 500

    Rectangle {
        width: 6
        height: 6
        radius: 3
        color: root.accentColor
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: root.text.toUpperCase()
        color: "#9aa3b5"
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        font.family: root.textFontFamily
        anchors.verticalCenter: parent.verticalCenter
    }
}
