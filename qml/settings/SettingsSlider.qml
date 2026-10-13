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
            id: badgeRect
            property bool isEditing: false

            function commitEdit() {
                if (!isEditing) return;
                var raw = editInput.text.trim();
                var parsed = parseFloat(raw);
                if (!isNaN(parsed)) {
                    var clamped = Math.max(root.from, Math.min(root.to, parsed));
                    if (root.stepSize >= 1) {
                        clamped = Math.round(clamped);
                    } else if (root.stepSize > 0) {
                        var precision = Math.round(1 / root.stepSize);
                        clamped = Math.round(clamped * precision) / precision;
                    }
                    root.value = clamped;
                    root.valueModified(clamped);
                }
                isEditing = false;
            }

            function cancelEdit() {
                isEditing = false;
            }

            width: Math.max(58, badgeContent.width + 16)
            height: 26
            radius: 6
            color: isEditing
                ? Qt.rgba(255, 255, 255, 0.12)
                : (badgeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.06))
            border.width: 1
            border.color: isEditing
                ? root.accentColor
                : (badgeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : "transparent")
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            Item {
                id: badgeContent
                anchors.centerIn: parent
                width: badgeRect.isEditing ? editInput.implicitWidth : badgeLabel.implicitWidth
                height: parent.height

                Text {
                    id: badgeLabel
                    visible: !badgeRect.isEditing
                    anchors.centerIn: parent
                    text: (Math.round(root.value * 10) / 10) + (root.suffix !== "" ? " " + root.suffix : "")
                    color: "#e2e6ee"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: root.textFontFamily
                }

                TextInput {
                    id: editInput
                    visible: badgeRect.isEditing
                    anchors.centerIn: parent
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.family: root.textFontFamily
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    inputMethodHints: Qt.ImhFormattedNumbersOnly

                    onAccepted: {
                        badgeRect.commitEdit();
                    }

                    Keys.onEscapePressed: {
                        badgeRect.cancelEdit();
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus && badgeRect.isEditing) {
                            badgeRect.commitEdit();
                        }
                    }
                }
            }

            MouseArea {
                id: badgeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: badgeRect.isEditing ? Qt.IBeamCursor : Qt.PointingHandCursor
                onClicked: {
                    if (!badgeRect.isEditing) {
                        badgeRect.isEditing = true;
                        editInput.text = String(Math.round(root.value * 10) / 10);
                        editInput.forceActiveFocus();
                        editInput.selectAll();
                    }
                }
            }
        }
    }
}
