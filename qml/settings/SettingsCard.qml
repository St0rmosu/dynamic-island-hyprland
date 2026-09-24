import QtQuick

Rectangle {
    id: root

    default property alias content: contentColumn.data
    property alias spacing: contentColumn.spacing

    width: parent ? parent.width : 500
    implicitHeight: contentColumn.implicitHeight + 28
    radius: 16
    color: Qt.rgba(255, 255, 255, 0.04)
    border.width: 1
    border.color: Qt.rgba(255, 255, 255, 0.07)

    Column {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
    }
}
