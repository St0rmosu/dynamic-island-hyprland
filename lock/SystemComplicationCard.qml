import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    implicitWidth: 270
    implicitHeight: 82
    radius: AppleTokens.radiusLg

    color: Qt.rgba(0.07, 0.07, 0.1, 0.82)
    border.width: 1
    border.color: Qt.rgba(1.0, 1.0, 1.0, 0.18)

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.45)
        shadowBlur: 0.5
        shadowVerticalOffset: 3
    }

    property int batteryLevel: 47
    property string batteryStatus: "Discharging"

    FileView {
        id: batCapFile
        path: "/sys/class/power_supply/BAT1/capacity"
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) root.batteryLevel = val;
        }
    }

    FileView {
        id: batStatFile
        path: "/sys/class/power_supply/BAT1/status"
        onLoaded: {
            let s = text().trim();
            if (s.length > 0) root.batteryStatus = s;
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: {
            batCapFile.reload();
            batStatFile.reload();
        }
    }

    readonly property string batteryGlyph: {
        let isCharging = (root.batteryStatus === "Charging" || root.batteryStatus === "Full");
        if (isCharging) return "󰂄";
        if (root.batteryLevel > 80) return "󰂂";
        if (root.batteryLevel > 50) return "󰂀";
        if (root.batteryLevel > 30) return "󰁾";
        if (root.batteryLevel > 15) return "󰁼";
        return "󰁺";
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Circular Icon Badge (46x46)
        Rectangle {
            width: 48
            height: 48
            radius: AppleTokens.radiusSm
            color: Qt.rgba(1.0, 1.0, 1.0, 0.06)
            border.width: 1
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.1)

            Text {
                anchors.centerIn: parent
                text: root.batteryGlyph
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: root.batteryStatus === "Charging" ? AppleTokens.successGreen : (root.batteryLevel < 20 ? AppleTokens.errorRed : AppleTokens.primaryOnDark)
            }
        }

        // Details Column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                spacing: 8

                Text {
                    text: root.batteryLevel + "%"
                    font.family: AppleTokens.displayFont
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    font.letterSpacing: AppleTokens.letterSpacingBody
                    color: AppleTokens.bodyOnDark
                }

                Text {
                    text: root.batteryStatus === "Charging" ? "In carica" : "Batteria"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    font.letterSpacing: AppleTokens.letterSpacingBody
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.6)
                }
            }

            Text {
                text: "Arch Linux • Hyprland • AMD"
                font.family: AppleTokens.textFont
                font.pixelSize: 11
                font.weight: Font.Normal
                font.letterSpacing: AppleTokens.letterSpacingBody
                color: Qt.rgba(1.0, 1.0, 1.0, 0.45)
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
