import QtQuick
import Qt5Compat.GraphicalEffects
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
    readonly property bool pressed: isVertical ? verticalMouse.pressed : sliderArea.pressed
    readonly property bool isCompact: root.height < 56
    property bool isVertical: root.height >= 110 && root.width < 160

    function clamp01(nextValue) {
        return Math.max(0, Math.min(1, nextValue));
    }

    radius: Math.min(20, Math.max(14, root.height / 2))
    color: StyleTokens.clearBlack
    clip: true

    MatteSurface {
        anchors.fill: parent
        radius: root.radius
        hovered: root.isVertical ? verticalMouse.containsMouse : sliderArea.containsMouse
        pressed: root.pressed
        visible: !root.isVertical
    }

    // --- VERTICAL SLIDER (iOS Style: pillola alta con scorrimento verticale su/giù) ---
    Item {
        id: verticalContainer
        anchors.fill: parent
        visible: root.isVertical

        Rectangle {
            id: verticalTrack
            anchors.fill: parent
            radius: root.radius
            color: "#16181f"
            border.width: 1
            border.color: verticalMouse.containsMouse ? "#3d4149" : Qt.rgba(255, 255, 255, 0.08)

            Item {
                id: trackContent
                anchors.fill: parent
                anchors.margins: 1
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: trackMask
                }

                // Riempimento dal basso verso l'alto perfettamente mascherato nella curva
                Rectangle {
                    id: fillRect
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: root.value <= 0.001 ? 0 : Math.max(0, Math.min(parent.height, parent.height * root.value))
                    color: "#eceef2"
                    visible: root.value > 0.001
                }
            }

            Rectangle {
                id: trackMask
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(0, root.radius - 1)
                visible: false
            }

            // Percentuale in alto
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 10
                text: Math.round(root.value * 100) + "%"
                font.pixelSize: 11
                font.family: root.textFontFamily
                font.weight: Font.Bold
                color: (root.value > 0.85) ? "#111214" : (root.value > 0.01 ? "#e2e6ee" : "#7e889b")
                z: 4
            }

            // Icona in basso
            Item {
                id: iconArea
                width: parent.width
                height: 44
                anchors.bottom: parent.bottom
                z: 4

                Text {
                    anchors.centerIn: parent
                    text: root.iconText
                    font.pixelSize: 18
                    font.family: root.iconFontFamily
                    color: (root.value > 0.22) ? "#111214" : "#ffffff"

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }
            }

            MouseArea {
                id: verticalMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function update(mouseY) {
                    let padding = 12;
                    let effectiveH = height - (padding * 2);
                    let relY = mouseY - padding;
                    let ratio = 1.0 - (relY / effectiveH);
                    root.valueMoved(root.clamp01(ratio));
                }

                onPressed: function(mouse) {
                    root.interactionStarted();
                    update(mouse.y);
                }
                onPositionChanged: function(mouse) {
                    if (pressed) update(mouse.y);
                }
                onReleased: root.commitRequested()
                onCanceled: root.cancelRequested()
            }
        }
    }

    // --- HORIZONTAL SLIDER (Disposizione classica orizzontale) ---
    Item {
        anchors.fill: parent
        visible: !root.isVertical
        anchors.margins: root.isCompact ? 6 : Math.min(12, Math.max(6, (root.height - 48) / 2))

        Row {
            id: headerRow
            anchors.left: parent.left
            anchors.top: parent.top
            spacing: 7
            height: 18
            visible: !root.isCompact

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
            anchors.bottom: root.isCompact ? undefined : parent.bottom
            anchors.verticalCenter: root.isCompact ? parent.verticalCenter : undefined
            height: root.isCompact ? Math.min(28, Math.max(20, root.height - 12)) : Math.min(24, Math.max(18, root.height - 46))
            radius: height / 2
            color: "#1d1f24"
            border.width: 1
            border.color: "#30333a"
            clip: true

            Rectangle {
                width: root.value <= 0.001
                    ? 0
                    : Math.max(root.isCompact ? 20 : 34, Math.min(sliderTrack.width, sliderTrack.width * root.value + 1))
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

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconText
                color: root.value > 0.25 ? "#111214" : root.textSecondary
                font.pixelSize: 13
                font.family: root.iconFontFamily
                visible: root.isCompact && root.iconText !== ""
                z: 2
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
