import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    property bool showCondition: false
    property bool failed: false
    property string errorString: ""
    property color accentColor: "#34d399"
    property var configSource: null
    readonly property var activeConfig: configSource || userConfig
    property string iconFontFamily: activeConfig.iconFontFamily
    property string textFontFamily: activeConfig.textFontFamily
    property string heroFontFamily: activeConfig.heroFontFamily

    signal dismissRequested()

    readonly property real preferredWidth: failed
        ? (errorString !== "" ? 380 : 280)
        : 295

    readonly property real preferredHeight: failed && errorString !== ""
        ? 56
        : Math.max(userConfig.islandHeight, 38)

    readonly property real preferredRadius: preferredHeight / 2

    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 140
            easing.type: Easing.InOutQuad
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 4
        anchors.bottomMargin: 4

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: statusIconRight.left
            anchors.rightMargin: 10
            spacing: 11

            // Icon badge with animated rotation on success
            Rectangle {
                id: iconBadge
                width: 26
                height: 26
                radius: 13
                anchors.verticalCenter: parent.verticalCenter
                color: root.failed ? "#3d1417" : Qt.rgba(0.2, 0.8, 0.5, 0.15)
                border.color: root.failed ? "#f87171" : "#34d399"
                border.width: 1

                Text {
                    id: iconGlyph
                    anchors.centerIn: parent
                    text: root.failed ? "" : ""
                    color: root.failed ? "#f87171" : "#34d399"
                    font.pixelSize: 13
                    font.family: root.iconFontFamily

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 650
                        direction: RotationAnimation.Clockwise
                        easing.type: Easing.OutCubic
                        running: root.showCondition && !root.failed
                    }
                }
            }

            // Text column
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - iconBadge.width - parent.spacing
                spacing: 2

                Text {
                    text: root.failed ? "Reload Fallito" : "Quickshell Ricaricato"
                    color: root.failed ? "#fca5a5" : "#ffffff"
                    font.pixelSize: userConfig.bodyFontSize
                    font.family: root.textFontFamily
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.15
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    visible: root.failed && root.errorString !== ""
                    text: root.errorString
                    color: "#9ca3af"
                    font.pixelSize: Math.max(9, userConfig.bodyFontSize - 3)
                    font.family: root.textFontFamily
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    width: parent.width
                }
            }
        }

        // Small indicator on the right
        Text {
            id: statusIconRight
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.failed ? "" : ""
            color: root.failed ? "#f87171" : "#34d399"
            font.pixelSize: 12
            font.family: root.iconFontFamily
            opacity: 0.85
        }
    }

    // Auto-dismiss progress bar
    Rectangle {
        id: progressBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        height: 2
        radius: 1
        color: root.failed ? "#f87171" : "#34d399"
        opacity: 0.6
        width: Math.max(0, parent.width - 28)

        PropertyAnimation on width {
            from: Math.max(0, root.width - 28)
            to: 0
            duration: root.failed ? 8000 : 2500
            running: root.showCondition
        }
    }

    TapHandler {
        onTapped: root.dismissRequested()
    }
}
