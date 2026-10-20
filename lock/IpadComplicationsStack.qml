pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root

    property int batteryLevel: 100
    property string batteryStatus: "Full"
    property string deviceName: "Apple Pencil Pro"
    property string connectionStatus: "Disconnesso"
    property string connectionSub: "Connessione rapida"
    property bool isConnected: false

    spacing: 22
    Layout.alignment: Qt.AlignLeft

    // Read wifi status
    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^sì:' | cut -d: -f2 | head -n 1"]
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

    // 1. Stylus / Battery Complication (Exact iPadOS style)
    ColumnLayout {
        spacing: 5

        RowLayout {
            spacing: 6

            // Stylus / Pencil icon
            Text {
                text: "󰏫"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 1
                }
            }

            // Lightning Bolt
            Text {
                text: "⚡"
                font.family: AppleTokens.textFont
                font.pixelSize: 13
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)

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

        // Device / Pencil Label
        Text {
            text: root.deviceName
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
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
            }
        }
    }

    // 2. Circular Quick Actions Row (Notion & Spotify)
    RowLayout {
        spacing: 16

        // Notion Circle
        Rectangle {
            id: notionCircle
            width: 54
            height: 54
            radius: 27
            color: Qt.rgba(0.12, 0.12, 0.14, 0.55)
            border.width: 1
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.22)

            scale: notionMouse.pressed ? AppleTokens.pressScale : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 0.5
                shadowVerticalOffset: 2
            }

            Image {
                anchors.centerIn: parent
                width: 26
                height: 26
                source: "file:///usr/share/icons/hicolor/256x256/apps/notion.png"
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !notionCircle.children[0].visible
                text: "N"
                font.family: AppleTokens.displayFont
                font.pixelSize: 22
                font.weight: Font.Bold
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
            }

            MouseArea {
                id: notionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["sh", "-c", "notion-app || notion || flatpak run notion || true"]);
                }
            }
        }

        // Spotify Circle
        Rectangle {
            id: spotifyCircle
            width: 54
            height: 54
            radius: 27
            color: Qt.rgba(0.12, 0.12, 0.14, 0.55)
            border.width: 1
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.22)

            scale: spotifyMouse.pressed ? AppleTokens.pressScale : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 0.5
                shadowVerticalOffset: 2
            }

            Text {
                anchors.centerIn: parent
                text: "󰓇"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 30
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
            }

            MouseArea {
                id: spotifyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["sh", "-c", "spotify || flatpak run com.spotify.Client || true"]);
                }
            }
        }
    }

    // 3. Connectivity Status Complication
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
