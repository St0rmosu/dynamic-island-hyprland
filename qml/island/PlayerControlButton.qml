import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    signal buttonPressed()
    signal clicked()

    property string kind: "play"
    property string textFontFamily: ""
    readonly property bool down: controlArea.pressed
    readonly property string iconText: {
        if (kind === "previous") return "⏮";
        if (kind === "next") return "⏭";
        if (kind === "pause") return "⏸";
        return "▶";
    }

    width: 28
    height: 28
    scale: controlArea.pressed ? 0.86 : (controlArea.containsMouse ? 1.08 : 1.0)
    opacity: enabled ? 1.0 : 0.45

    Behavior on scale {
        NumberAnimation {
            duration: controlArea.pressed ? 80 : 180
            easing.type: controlArea.pressed ? Easing.OutQuad : Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.iconText
        color: controlArea.pressed ? "#888888" : "#ffffff"
        font.pixelSize: root.kind === "play" ? userConfig.iconFontSize + 7 : userConfig.iconFontSize + 5
        font.family: root.textFontFamily
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: controlArea
        anchors.fill: parent
        anchors.margins: -15
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        onPressed: function(mouse) {
            root.buttonPressed();
            mouse.accepted = true;
        }
        onClicked: root.clicked()
    }
}
