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
        height: 34
        radius: 17
        color: Qt.rgba(255, 255, 255, 0.06)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.08)
        width: Math.min(rowContainer.width + 6, parent ? parent.width : 500)
        clip: true

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 3
            contentWidth: rowContainer.width
            contentHeight: height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick

            Item {
                id: rowContainer
                width: rowLayout.implicitWidth
                height: flick.height

                // Pillola scorrevole fluida a slider (stile iOS / Nothing Ear)
                Rectangle {
                    id: slidingIndicator
                    y: 0
                    height: flick.height
                    radius: 14
                    color: root.accentColor
                    visible: width > 0
                    z: 1

                    property real targetX: 0
                    property real targetWidth: 0

                    x: targetX
                    width: targetWidth

                    Behavior on x {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutQuint
                        }
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutQuint
                        }
                    }
                }

                Row {
                    id: rowLayout
                    anchors.verticalCenter: parent.verticalCenter
                    x: 0
                    spacing: 3
                    z: 2

                    Repeater {
                        id: btnRepeater
                        model: root.model

                        Item {
                            id: btnItem
                            readonly property bool isSelected: String(root.currentValue) === String(modelData.value)
                            width: btnText.contentWidth + 22
                            height: flick.height

                            function updateIndicator() {
                                if (isSelected) {
                                    slidingIndicator.targetX = btnItem.x;
                                    slidingIndicator.targetWidth = btnItem.width;
                                    ensureVisible();
                                }
                            }

                            function ensureVisible() {
                                if (flick.contentWidth <= flick.width) return;
                                var absX = btnItem.x;
                                if (absX < flick.contentX) {
                                    flick.contentX = Math.max(0, absX - 6);
                                } else if (absX + btnItem.width > flick.contentX + flick.width) {
                                    flick.contentX = Math.min(flick.contentWidth - flick.width, absX + btnItem.width - flick.width + 6);
                                }
                            }

                            onIsSelectedChanged: updateIndicator()
                            Component.onCompleted: updateIndicator()
                            onXChanged: if (isSelected) updateIndicator()
                            onWidthChanged: if (isSelected) updateIndicator()

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: (btnMouse.containsMouse && !btnItem.isSelected) ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                id: btnText
                                anchors.centerIn: parent
                                text: modelData.text
                                font.pixelSize: 11
                                font.weight: btnItem.isSelected ? Font.DemiBold : Font.Normal
                                font.family: root.textFontFamily
                                color: btnItem.isSelected ? "#ffffff" : "#a2a8b8"
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            MouseArea {
                                id: btnMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    root.currentValue = modelData.value;
                                    root.selected(modelData.value);
                                    btnItem.updateIndicator();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    onCurrentValueChanged: {
        for (var i = 0; i < btnRepeater.count; i++) {
            var it = btnRepeater.itemAt(i);
            if (it && it.isSelected) {
                it.updateIndicator();
                break;
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            for (var i = 0; i < btnRepeater.count; i++) {
                var it = btnRepeater.itemAt(i);
                if (it && it.isSelected) {
                    it.updateIndicator();
                    break;
                }
            }
        });
    }
}
