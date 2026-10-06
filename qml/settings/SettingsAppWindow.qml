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
    readonly property color accentColor: (dynamicConfig && dynamicConfig.customAccentColor && dynamicConfig.customAccentColor !== "") ? dynamicConfig.customAccentColor : "#0a84ff"
    readonly property string iconFontFamily: (dynamicConfig && dynamicConfig.iconFontFamily !== "") ? dynamicConfig.iconFontFamily : "JetBrainsMono Nerd Font"
    readonly property string textFontFamily: (dynamicConfig && dynamicConfig.textFontFamily !== "") ? dynamicConfig.textFontFamily : "Google Sans Flex"

    ClippingRectangle {
        id: bgRect
        anchors.fill: parent
        radius: settingsWin.windowCornerRadius
        color: "#0c0e14"
        border.width: settingsWin.maximized ? 0 : 1
        border.color: Qt.rgba(255, 255, 255, 0.1)
        antialiasing: true

        // ── Barra del Titolo Nativa Hyprland / Finestra ───────────────────
        Rectangle {
            id: titlebar
            width: parent.width
            height: 44
            color: "#080a0f"
            border.width: 0
            topLeftRadius: settingsWin.windowCornerRadius
            topRightRadius: settingsWin.windowCornerRadius
            bottomLeftRadius: 0
            bottomRightRadius: 0
            antialiasing: true

            // Linea divisoria inferiore sottile
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(255, 255, 255, 0.06)
            }

            // Area trascinabile per spostare la finestra nativamente con Hyprland
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: settingsWin.startSystemMove()
                onDoubleClicked: settingsWin.maximized = !settingsWin.maximized
            }

            // Titolo della Finestra a Sinistra con icona
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf013" // cog icon
                    color: settingsWin.accentColor
                    font.family: settingsWin.iconFontFamily
                    font.pixelSize: 14
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("Dynamic Island — Impostazioni")
                    color: "#d0d4dc"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: settingsWin.textFontFamily
                }
            }

            // Pulsante Chiudi minimale a Destra (senza semaforo)
            Rectangle {
                id: closeBtn
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 6
                color: closeHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: closeHover.containsMouse ? "#ffffff" : "#808696"
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWin.visible = false
                }
            }
        }

        // ── Corpo dell'Applicazione Impostazioni ───────────────────────────
        SettingsAppLayer {
            id: appContent
            anchors.top: titlebar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            dynamicConfig: settingsWin.dynamicConfig
            accentColor: settingsWin.accentColor
            textFontFamily: settingsWin.textFontFamily
            iconFontFamily: settingsWin.iconFontFamily
            isEmbeddedInWindow: true
            cornerRadius: settingsWin.windowCornerRadius
            onCloseRequested: settingsWin.visible = false
        }
    }
}
