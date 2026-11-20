pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    property string lockState: "locked" // "locked", "verifying", "failed", "unlocked"
    property string buffer: ""
    property bool authenticating: false
    property bool isError: false
    property string errorMessage: ""
    property bool compactIdle: false
    property string currentTime: ""
    property string clockFontFamily: ""
    property int islandHeight: 40
    property int restingIslandWidth: 140

    signal submitRequested(string password)
    signal focusRequested()

    readonly property bool isTyping: buffer.length > 0 && !authenticating && lockState !== "verifying" && lockState !== "unlocked"

    implicitWidth: capsuleBg.width
    implicitHeight: capsuleBg.height

    Item {
        id: shakeContainer
        anchors.centerIn: parent
        width: capsuleBg.width
        height: capsuleBg.height

        Rectangle {
            id: capsuleBg
            anchors.centerIn: parent
            width: {
                if (root.lockState === "unlocked") return root.restingIslandWidth;
                if (root.lockState === "verifying" || root.authenticating) return 140;
                if (root.lockState === "failed" || root.isError) return 180;
                if (root.isTyping) return Math.min(280, Math.max(64, 32 + root.buffer.length * 15));
                if (root.compactIdle) return 56;
                return root.restingIslandWidth;
            }
            height: root.islandHeight > 0 ? root.islandHeight : 40
            radius: height / 2
            color: AppleTokens.surfaceBlack

            border.width: 1.0
            border.color: {
                if (root.lockState === "failed" || root.isError) return AppleTokens.errorRed;
                if (root.isTyping) return Qt.rgba(1.0, 1.0, 1.0, 0.25);
                return Qt.rgba(1.0, 1.0, 1.0, 0.12);
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                hoverEnabled: false
                cursorShape: Qt.IBeamCursor
                onClicked: root.focusRequested()
            }

            Behavior on width {
                NumberAnimation {
                    duration: AppleTokens.animDurationNormal
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.12
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: AppleTokens.animDurationNormal
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.08
                }
            }

            Behavior on border.color {
                ColorAnimation { duration: 200 }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.55)
                shadowBlur: 0.65
                shadowVerticalOffset: 4
            }

            // 1. Idle Locked State: Compact Padlock Pill (saneAspect style) or Padlock + "Bloccato"
            RowLayout {
                anchors.centerIn: parent
                spacing: root.compactIdle ? 0 : 9
                visible: !root.isTyping && !root.authenticating && root.lockState !== "verifying" && root.lockState !== "failed" && !root.isError && root.lockState !== "unlocked"

                Text {
                    text: "󰌾"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: root.compactIdle ? 13 : 18
                    color: AppleTokens.bodyOnDark
                    Layout.alignment: Qt.AlignCenter
                }

                Text {
                    text: "Bloccato"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.letterSpacing: AppleTokens.letterSpacingBody
                    color: AppleTokens.bodyOnDark
                    visible: !root.compactIdle
                }
            }

            // 2. Typing State: Minimal Centered Dots (saneAspect style)
            Row {
                anchors.centerIn: parent
                spacing: 8
                visible: root.isTyping

                Repeater {
                    model: root.buffer.length

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: AppleTokens.bodyOnDark

                        scale: 0
                        Component.onCompleted: dotAnim.start()

                        NumberAnimation on scale {
                            id: dotAnim
                            from: 0.2
                            to: 1.0
                            duration: 120
                            easing.type: Easing.OutBack
                        }
                    }
                }
            }

            // 3. Verifying / Authenticating State
            RowLayout {
                anchors.centerIn: parent
                spacing: 9
                visible: (root.authenticating || root.lockState === "verifying") && root.lockState !== "unlocked"

                Text {
                    text: "󰑮"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: AppleTokens.bodyOnDark

                    RotationAnimation on rotation {
                        running: root.authenticating || root.lockState === "verifying"
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 850
                    }
                }

                Text {
                    text: "Verifico..."
                    font.family: AppleTokens.textFont
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: AppleTokens.bodyOnDark
                }
            }

            // 4. Failed State (Shake + Error)
            RowLayout {
                anchors.centerIn: parent
                spacing: 9
                visible: (root.lockState === "failed" || root.isError) && !root.authenticating && root.lockState !== "unlocked"

                Text {
                    text: "󰌾"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: AppleTokens.errorRed
                }

                Text {
                    text: "Password errata"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: AppleTokens.errorRed
                }
            }

            // 5. Unlocked State: Empty resting pill waiting for clock to glide inside (saneAspect style)
            Item {
                anchors.centerIn: parent
                visible: root.lockState === "unlocked"
            }
        }
    }

    function triggerShake(): void {
        shakeAnim.restart();
    }

    SequentialAnimation {
        id: shakeAnim
        loops: 1

        NumberAnimation { target: shakeContainer; property: "x"; to: -12; duration: 45; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 12; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: -8; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 8; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: -4; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 0; duration: 45; easing.type: Easing.OutQuad }
    }
}
