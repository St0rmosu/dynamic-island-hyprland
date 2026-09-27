import QtQuick

Item {
    id: root

    property string title: ""
    property string description: ""
    property var model: [] // array of { text: "", value: "" }
    property var currentValue: ""
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property var stacked: undefined

    readonly property bool isStacked: (stacked !== undefined && stacked !== null)
        ? Boolean(stacked)
        : ((model && model.length > 3) || (rowLayout.implicitWidth > 320))

    signal selected(var val)

    width: parent ? parent.width : 500
    implicitHeight: isStacked ? (textCol.implicitHeight + pillRow.height + 16) : 48
    height: implicitHeight

    Column {
        id: textCol
        anchors.left: parent.left
        anchors.right: root.isStacked ? parent.right : pillRow.left
        anchors.rightMargin: root.isStacked ? 0 : 16
        anchors.top: root.isStacked ? parent.top : undefined
        anchors.topMargin: root.isStacked ? 2 : 0
        anchors.verticalCenter: root.isStacked ? undefined : parent.verticalCenter
        spacing: 3

        Text {
            id: titleText
            text: root.title
            color: "#f2f4f8"
            font.pixelSize: 13
            font.weight: Font.Medium
            font.family: root.textFontFamily
            width: parent.width
            elide: Text.ElideRight
        }

        Text {
            id: descText
            visible: root.description !== ""
            text: root.description
            color: "#7e889b"
            font.pixelSize: 11
            font.family: root.textFontFamily
            wrapMode: root.isStacked ? Text.WordWrap : Text.NoWrap
            width: parent.width
            elide: root.isStacked ? Text.ElideNone : Text.ElideRight
        }
    }

    Rectangle {
        id: pillRow
        anchors.left: root.isStacked ? parent.left : undefined
        anchors.right: root.isStacked ? undefined : parent.right
        anchors.top: root.isStacked ? textCol.bottom : undefined
        anchors.topMargin: root.isStacked ? 10 : 0
        anchors.verticalCenter: root.isStacked ? undefined : parent.verticalCenter
        height: 32
        radius: 8
        color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.05)
        width: Math.min(rowLayout.implicitWidth + 6, parent ? parent.width : 500)
        clip: true

        Flickable {
            anchors.fill: parent
            contentWidth: rowLayout.implicitWidth + 6
            contentHeight: height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick

            Row {
                id: rowLayout
                anchors.verticalCenter: parent.verticalCenter
                x: 3
                spacing: 3

                Repeater {
                    model: root.model

                    Rectangle {
                        readonly property bool isSelected: root.currentValue === modelData.value
                        width: btnText.contentWidth + 20
                        height: 26
                        radius: 6
                        color: isSelected ? root.accentColor : (btnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")
                        border.width: isSelected ? 1 : 0
                        border.color: isSelected ? Qt.rgba(255, 255, 255, 0.25) : "transparent"

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
}
