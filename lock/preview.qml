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

            onUnlockRequested: {
                console.log("Preview unlocked successfully!");
                Qt.quit();
            }
        }

        // Floating Close Button for Safe Preview
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 20
            width: 36
            height: 36
            radius: 18
            color: AppleTokens.surfaceGlassInput
            border.width: 1
            border.color: AppleTokens.hairlineDark
            z: 100

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
                onClicked: Qt.quit()
            }
        }
    }
}
