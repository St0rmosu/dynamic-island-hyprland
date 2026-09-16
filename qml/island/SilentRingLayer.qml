import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    property bool isMuted: true
    property bool showCondition: true
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property string iconFontFamily: userConfig.iconFontFamily

    readonly property color themeColor: isMuted ? "#ff453a" : "#f5f5f7"
    readonly property string labelText: isMuted ? "Silenzioso" : "Suoneria"

    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20

        // Left: Animated Bell Icon
        Item {
            id: bellContainer
            width: 24
            height: 24
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            transformOrigin: Item.Top

            // Bell glyph
            Text {
                id: bellGlyph
                anchors.centerIn: parent
                text: "\uf0f3" // FontAwesome bell
                color: root.themeColor
                font.family: root.iconFontFamily
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            // Diagonal slash line across bell when muted
            Rectangle {
                id: slashLine
                visible: root.isMuted
                width: 20
                height: 2.2
                radius: 1
                color: "#ff453a"
                anchors.centerIn: parent
                rotation: -45
            }

            // Bell ring/shake animation upon appear
            SequentialAnimation {
                id: ringAnimation
                running: root.showCondition
                loops: 1

                NumberAnimation { target: bellContainer; property: "rotation"; from: 0; to: -16; duration: 60; easing.type: Easing.OutQuad }
                NumberAnimation { target: bellContainer; property: "rotation"; from: -16; to: 14; duration: 80; easing.type: Easing.InOutQuad }
                NumberAnimation { target: bellContainer; property: "rotation"; from: 14; to: -10; duration: 70; easing.type: Easing.InOutQuad }
                NumberAnimation { target: bellContainer; property: "rotation"; from: -10; to: 6; duration: 60; easing.type: Easing.InOutQuad }
                NumberAnimation { target: bellContainer; property: "rotation"; from: 6; to: 0; duration: 50; easing.type: Easing.OutQuad }
            }
        }

        // Right: Mode Label ("Silenzioso" in red or "Suoneria" in white)
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.labelText
            color: root.themeColor
            font.family: root.textFontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.letterSpacing: -0.2
        }
    }
}
