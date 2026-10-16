import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import IslandBackend
import "../controlcenter"

FloatingWindow {
    id: settingsWin

    title: I18n.tr("Dynamic Island — Impostazioni")
    implicitWidth: 980
    implicitHeight: 680
    minimumSize: Qt.size(760, 520)
    color: "transparent"
    visible: false

    property var dynamicConfig: null
    readonly property real windowCornerRadius: settingsWin.maximized ? 0 : 20
    readonly property color accentColor: (dynamicConfig && dynamicConfig.effectiveAccentColor) ? dynamicConfig.effectiveAccentColor : "#0a84ff"
    readonly property string iconFontFamily: (dynamicConfig && dynamicConfig.iconFontFamily !== "") ? dynamicConfig.iconFontFamily : "JetBrainsMono Nerd Font"
    readonly property string textFontFamily: (dynamicConfig && dynamicConfig.textFontFamily !== "") ? dynamicConfig.textFontFamily : "Google Sans Flex"

    function setCategory(catIndex) {
        if (appContent) {
            appContent.selectedCategoryIndex = catIndex;
        }
    }

    ClippingRectangle {
        id: bgRect
        anchors.fill: parent
        radius: settingsWin.windowCornerRadius
        color: "#0c0e14"
        border.width: settingsWin.maximized ? 0 : 1
        border.color: Qt.rgba(255, 255, 255, 0.1)
        antialiasing: true

        SettingsAppLayer {
            id: appContent
            anchors.fill: parent
            dynamicConfig: settingsWin.dynamicConfig
            accentColor: settingsWin.accentColor
            textFontFamily: settingsWin.textFontFamily
            iconFontFamily: settingsWin.iconFontFamily
            isEmbeddedInWindow: true
            cornerRadius: settingsWin.windowCornerRadius
            onCloseRequested: settingsWin.visible = false
            onStartMoveRequested: settingsWin.startSystemMove()
            onToggleMaximizeRequested: settingsWin.maximized = !settingsWin.maximized
        }
    }
}
