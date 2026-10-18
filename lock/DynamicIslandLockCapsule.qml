import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    property string lockState: "locked" // "locked", "verifying", "failed", "unlocked"
    property string statusText: ""
    property bool hasBiometrics: false

    implicitWidth: capsuleBg.width
    implicitHeight: 38

    Item {
        id: shakeContainer
        anchors.centerIn: parent
        width: capsuleBg.width
        height: capsuleBg.height

        Rectangle {
            id: capsuleBg
            anchors.centerIn: parent
            width: {
                if (root.lockState === "unlocked") return 164;
                if (root.lockState === "verifying") return 150;
                if (root.lockState === "failed") return 140;
                return 112;
            }
            height: 38
            radius: height / 2
            color: AppleTokens.surfaceBlack

            border.width: 1
            border.color: {
                if (root.lockState === "failed") return AppleTokens.errorRed;
                if (root.lockState === "unlocked") return AppleTokens.successGreen;
                return AppleTokens.hairlineDark;
            }

            Behavior on width {
                NumberAnimation {
                    duration: AppleTokens.animDurationNormal
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.15
                }
            }

            Behavior on border.color {
                ColorAnimation { duration: 200 }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 0.6
                shadowVerticalOffset: 3
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                // Dynamic icon
                Text {
                    id: lockGlyph
                    text: {
                        if (root.lockState === "unlocked") return "󰌿";
                        if (root.lockState === "verifying") return "󰑮";
                        if (root.lockState === "failed") return "󰌾";
                        return "󰌾";
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: {
                        if (root.lockState === "unlocked") return AppleTokens.successGreen;
                        if (root.lockState === "failed") return AppleTokens.errorRed;
                        return AppleTokens.bodyOnDark;
                    }

                    RotationAnimation on rotation {
                        running: root.lockState === "verifying"
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                }

                Text {
                    id: labelText
                    text: {
                        if (root.lockState === "unlocked") return "Sbloccato";
                        if (root.lockState === "verifying") return "Verifico...";
                        if (root.lockState === "failed") return "Riprova";
                        return "Bloccato";
                    }
                    font.family: AppleTokens.textFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: AppleTokens.letterSpacingBody
                    color: {
                        if (root.lockState === "unlocked") return AppleTokens.successGreen;
                        if (root.lockState === "failed") return AppleTokens.errorRed;
                        return AppleTokens.bodyOnDark;
                    }
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

        NumberAnimation { target: shakeContainer; property: "x"; to: -12; duration: 50; easing.type: Easing.OutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 12; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: -8; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 8; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: -4; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: shakeContainer; property: "x"; to: 0; duration: 50; easing.type: Easing.OutQuad }
    }
}
