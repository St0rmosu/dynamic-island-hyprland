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

    signal submitRequested(string password)

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
                if (root.lockState === "unlocked") return 160;
                if (root.lockState === "verifying" || root.authenticating) return 160;
                if (root.lockState === "failed" || root.isError) return 180;
                if (root.isTyping) return Math.min(290, Math.max(180, 110 + root.buffer.length * 13));
                return 120;
            }
            height: 38
            radius: height / 2
            color: AppleTokens.surfaceBlack

            border.width: 1
            border.color: {
                if (root.lockState === "failed" || root.isError) return AppleTokens.errorRed;
                if (root.lockState === "unlocked") return AppleTokens.successGreen;
                if (root.isTyping) return Qt.rgba(1.0, 1.0, 1.0, 0.45);
                return AppleTokens.hairlineDark;
            }

            Behavior on width {
                NumberAnimation {
                    duration: AppleTokens.animDurationNormal
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.12
                }
            }

            Behavior on border.color {
                ColorAnimation { duration: 200 }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.6
                shadowVerticalOffset: 3
            }

            // 1. Idle Locked State: Padlock + "Bloccato"
            RowLayout {
                anchors.centerIn: parent
                spacing: 7
                visible: !root.isTyping && !root.authenticating && root.lockState !== "verifying" && root.lockState !== "failed" && !root.isError && root.lockState !== "unlocked"

                Text {
                    text: "󰌾"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: AppleTokens.bodyOnDark
                }

                Text {
                    text: "Bloccato"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: AppleTokens.letterSpacingBody
                    color: AppleTokens.bodyOnDark
                }
            }

            // 2. Typing State: Lock Icon + Password Dots + Submit Arrow
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8
                visible: root.isTyping

                Text {
                    text: "󰌾"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.6)
                }

                // Password dots
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        spacing: 6

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
                                    duration: 130
                                    easing.type: Easing.OutBack
                                }
                            }
                        }
                    }
                }

                // Submit Arrow Button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.25)
                    scale: btnMouse.pressed ? AppleTokens.pressScale : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    Text {
                        anchors.centerIn: parent
                        text: "➔"
                        font.family: AppleTokens.textFont
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: AppleTokens.bodyOnDark
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.buffer.length > 0) {
                                root.submitRequested(root.buffer);
                            }
                        }
                    }
                }
            }

            // 3. Verifying / Authenticating State
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: root.authenticating || root.lockState === "verifying"

                Text {
                    text: "󰑮"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
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
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: AppleTokens.bodyOnDark
                }
            }

            // 4. Failed State (Shake + Error)
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: (root.lockState === "failed" || root.isError) && !root.authenticating

                Text {
                    text: "󰌾"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: AppleTokens.errorRed
                }

                Text {
                    text: "Password errata"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: AppleTokens.errorRed
                }
            }

            // 5. Unlocked State (Success Green)
            RowLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: root.lockState === "unlocked"

                Text {
                    text: "󰌿"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: AppleTokens.successGreen
                }

                Text {
                    text: "Sbloccato"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: AppleTokens.successGreen
                }
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
