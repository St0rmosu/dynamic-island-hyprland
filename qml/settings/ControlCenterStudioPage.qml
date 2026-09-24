import QtQuick
import QtQuick.Controls
import "../controlcenter"

Item {
    id: root

    property var config: null
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string heroFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    readonly property color accentSoft: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.16)
    readonly property color accentBorder: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.42)
    readonly property color accentGlow: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.28)

    signal requestReloadQuickshell()

    StudioLayoutCanvas {
        id: canvasItem
        anchors.fill: parent
        anchors.margins: 16

        accentColor: root.accentColor
        accentSoft: root.accentSoft
        accentBorder: root.accentBorder
        accentGlow: root.accentGlow

        textPrimary: "#f2f4f8"
        textSecondary: "#9aa3b5"
        textMuted: "#656f82"
        bgCard: Qt.rgba(255, 255, 255, 0.045)
        borderCard: Qt.rgba(255, 255, 255, 0.08)

        iconFontFamily: root.iconFontFamily
        textFontFamily: root.textFontFamily
        heroFontFamily: root.heroFontFamily

        controlCenterOrientation: root.config ? root.config.controlCenterOrientation : "vertical"
        controlCenterWidth: root.config ? root.config.controlCenterWidth : 420
        rawConfig: root.config ? { controlCenterCanvasLayout: root.config.controlCenterCanvasLayout } : ({})

        onRequestReloadQuickshell: root.requestReloadQuickshell()

        onLayoutChanged: function(layoutArray) {
            if (root.config) {
                root.config.set("controlCenterCanvasLayout", layoutArray);
            }
        }

        onRequestOrientationChange: function(ori) {
            if (root.config) {
                root.config.set("controlCenterOrientation", ori);
            }
        }

        onRequestWidthChange: function(w) {
            if (root.config) {
                root.config.set("controlCenterWidth", w);
            }
        }
    }
}
