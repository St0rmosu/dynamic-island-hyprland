pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: previewWin
        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "apple-lockscreen-preview"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"

        LockContent {
            id: content
            anchors.fill: parent
            isPreview: true
            previewMediaPlaying: true

            onUnlockRequested: {
                console.log("Preview unlocked successfully!");
                Qt.quit();
            }
        }

        // Floating Control Bar for Safe Preview Testing
        Row {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 12
            z: 100

            // Toggle Music Mode Button
            Rectangle {
                width: toggleText.implicitWidth + 24
                height: 36
                radius: 18
                color: content.previewMediaPlaying ? AppleTokens.primaryFocus : Qt.rgba(0.12, 0.12, 0.14, 0.8)
                border.width: 1
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.25)

                Text {
                    id: toggleText
                    anchors.centerIn: parent
                    text: content.previewMediaPlaying ? "󰓇 Modalità Spotify Attiva" : "󰓇 Simula Spotify (iPadOS)"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: AppleTokens.bodyOnDark
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        content.previewMediaPlaying = !content.previewMediaPlaying;
                        content.forceActiveFocus();
                    }
                }
            }

            // Floating Close Button
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: Qt.rgba(0.12, 0.12, 0.14, 0.8)
                border.width: 1
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.25)

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 14
                    color: AppleTokens.bodyOnDark
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: content.triggerUnlock()
                }
            }
        }
    }
}
