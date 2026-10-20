pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root

    property int batteryLevel: 100
    property string batteryStatus: "Discharging"
    readonly property bool isCharging: batteryStatus === "Charging" || batteryStatus === "Full"
    property string deviceName: "Batteria"
    property string connectionStatus: "Disconnesso"
    property string connectionSub: "Connessione rapida"
    property bool isConnected: false

    spacing: 24
    Layout.alignment: Qt.AlignLeft

    // Read Wi-Fi SSID and connection status via nmcli
    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep -E '^(sì|yes):' | cut -d: -f2 | head -n 1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let ssid = data.trim();
                if (ssid.length > 0) {
                    root.isConnected = true;
                    root.connectionStatus = ssid;
                    root.connectionSub = "Connesso";
                } else {
                    root.isConnected = false;
                    root.connectionStatus = "Disconnesso";
                    root.connectionSub = "Connessione rapida";
                }
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: wifiProc.running = true
    }

    // 1. Laptop / System Battery Complication (iPadOS Style)
    ColumnLayout {
        spacing: 5

        RowLayout {
            spacing: 6

            // Battery Icon (adaptive based on charge level & charging status)
            Text {
                text: {
                    if (root.isCharging) return "󰂄";
                    if (root.batteryLevel >= 90) return "󰁹";
                    if (root.batteryLevel >= 75) return "󰂁";
                    if (root.batteryLevel >= 50) return "󰁿";
                    if (root.batteryLevel >= 25) return "󰁽";
                    return "󰁻";
                }
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: root.batteryLevel <= 20 && !root.isCharging ? AppleTokens.errorRed : Qt.rgba(1.0, 1.0, 1.0, 0.95)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 1
                }
            }

            // Percentage
            Text {
                text: root.batteryLevel + "%"
                font.family: AppleTokens.roundedFont
                font.pixelSize: 14
                font.weight: Font.Bold
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 1
                }
            }
        }

        // Battery Label ("In carica" or "Batteria")
        Text {
            text: root.isCharging ? "In carica" : "Batteria"
            font.family: AppleTokens.textFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Qt.rgba(1.0, 1.0, 1.0, 0.95)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.6)
                shadowBlur: 0.4
                shadowVerticalOffset: 1
            }
        }

        // Progress Bar (iOS style white pill)
        Rectangle {
            id: barTrack
            width: 145
            height: 5
            radius: 2.5
            color: Qt.rgba(1.0, 1.0, 1.0, 0.3)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.3
                shadowVerticalOffset: 1
            }

            Rectangle {
                width: Math.max(0, Math.min(barTrack.width, barTrack.width * (root.batteryLevel / 100)))
                height: barTrack.height
                radius: barTrack.radius
                color: root.batteryLevel <= 20 && !root.isCharging ? AppleTokens.errorRed : Qt.rgba(1.0, 1.0, 1.0, 0.95)
            }
        }
    }

    // 2. Connectivity Status Complication (Wi-Fi)
    RowLayout {
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignTop
            text: root.isConnected ? "󰖩" : "󰤮"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: Qt.rgba(1.0, 1.0, 1.0, 0.95)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.6)
                shadowBlur: 0.4
                shadowVerticalOffset: 1
            }
        }

        ColumnLayout {
            spacing: 1

            Text {
                text: root.connectionStatus
                font.family: AppleTokens.textFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 1
                }
            }

            Text {
                text: root.connectionSub
                font.family: AppleTokens.textFont
                font.pixelSize: 11
                font.weight: Font.Normal
                color: Qt.rgba(1.0, 1.0, 1.0, 0.7)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 1
                }
            }
        }
    }
}
