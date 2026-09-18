import QtQuick
import IslandBackend

Rectangle {
    id: root

    signal interactionStarted()
    signal valueMoved(real value)
    signal commitRequested()
    signal cancelRequested()

    property string title: ""
    property string iconText: ""
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property real value: 0
    property real knobSize: 24
    property color moduleColor: StyleTokens.module
    property color moduleHover: StyleTokens.moduleHover
    property color trackColor: StyleTokens.track
    property color textPrimary: StyleTokens.textPrimary
    property color textSecondary: StyleTokens.textSecondary
    readonly property bool pressed: sliderArea.pressed

    function clamp01(nextValue) {
        return Math.max(0, Math.min(1, nextValue));
    }

    radius: 24
    color: StyleTokens.clearBlack
    clip: true

    MatteSurface {
        anchors.fill: parent
        radius: root.radius
        hovered: sliderArea.containsMouse
        pressed: sliderArea.pressed
    }

    Item {
        anchors.fill: parent
        anchors.margins: Math.min(12, Math.max(6, (root.height - 48) / 2))

        Row {
            id: headerRow
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 7
            height: 18

            Text {
                text: root.iconText
                color: root.textSecondary
                font.pixelSize: 15
                font.family: root.iconFontFamily
                anchors.verticalCenter: parent.verticalCenter
                visible: root.iconText !== ""
            }

            Text {
                text: root.title
                color: root.textPrimary
                font.pixelSize: 13
                font.family: root.textFontFamily
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            id: sliderTrack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(24, Math.max(18, root.height - 46))
            radius: height / 2
            color: "#1d1f24"
            border.width: 1
            border.color: "#30333a"
            clip: true

            Rectangle {
                width: root.value <= 0.001
                    ? 0
                    : Math.max(34, Math.min(sliderTrack.width, sliderTrack.width * root.value + 1))
                height: parent.height
                radius: parent.radius
                color: "#eceef2"
            }

            Rectangle {
                x: Math.max(0, Math.min(parent.width - width, parent.width * root.value - width / 2))
                y: (sliderTrack.height - height) / 2
                width: Math.min(root.knobSize, sliderTrack.height + 2)
                height: width
                radius: width / 2
                border.width: 1
                border.color: "#b8ffffff"
                color: "#f4f5f7"
            }

            MouseArea {
                id: sliderArea
                anchors.fill: parent
                hoverEnabled: true

                function update(mouseX) {
                    root.valueMoved(root.clamp01(mouseX / width));
                }

                onPressed: function(mouse) {
                    root.interactionStarted();
                    update(mouse.x);
                }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        update(mouse.x);
                }
                onReleased: root.commitRequested()
                onCanceled: root.cancelRequested()
            }
        }
    }
}
