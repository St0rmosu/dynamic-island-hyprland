pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property int size: 60
    property color glyphColor: "#ffffff"
    property color accentColor: "#0a84ff"
    property color successColor: "#30d158"
    property color errorColor: "#ff453a"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    property string stateMode: "idle" // "idle", "verifying", "success", "failed"
    property real breathingScale: 1.0
    property real breathingAlpha: 1.0
    property real scanProgress: 0.0
    property real shakeOffset: 0.0

    // Success animation properties (Apple Touch ID spring pop dynamics)
    property real successFingerprintOpacity: 1.0
    property real successFingerprintScale: 1.0
    property real checkmarkProgress: 0.0
    property real successPopScale: 1.0
    property real successCircleGlow: 0.0

    signal clicked()

    width: size
    height: size

    // Idle breathing pulsation for the outer halo and glyph
    SequentialAnimation {
        running: root.stateMode === "idle"
        loops: Animation.Infinite
        ParallelAnimation {
            NumberAnimation { target: root; property: "breathingScale"; from: 1.0; to: 1.05; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "breathingAlpha"; from: 0.82; to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "breathingScale"; from: 1.05; to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "breathingAlpha"; from: 1.0; to: 0.82; duration: 1500; easing.type: Easing.InOutSine }
        }
    }

    // Scanning wave sweep animation when verifying
    SequentialAnimation {
        running: root.stateMode === "verifying"
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "scanProgress"; from: 0.0; to: 1.0; duration: 550; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "scanProgress"; from: 1.0; to: 0.0; duration: 550; easing.type: Easing.InOutSine }
    }

    // Haptic Shake on failure
    SequentialAnimation {
        id: shakeAnim
        running: false
        NumberAnimation { target: root; property: "shakeOffset"; from: 0; to: -6; duration: 35; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; from: -6; to: 6; duration: 35; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; from: 6; to: -4; duration: 35; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; from: -4; to: 4; duration: 35; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; from: 4; to: 0; duration: 35; easing.type: Easing.InOutQuad }
    }

    // Apple Touch ID Success Sequence:
    // 1. Fingerprint dissolves smoothly (0 - 100ms)
    // 2. Outer circle glows bright emerald green (100ms - 220ms)
    // 3. Vector checkmark appears with spring pop (220ms - 500ms)
    // 4. Satisfying spring bounce settles verification (500ms - 800ms)
    SequentialAnimation {
        id: successAnim
        running: false

        // Phase 1: Dissolve fingerprint
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "successFingerprintOpacity"
                from: 1.0
                to: 0.0
                duration: 90
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "successFingerprintScale"
                from: 1.0
                to: 0.6
                duration: 90
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "successCircleGlow"
                from: 0.0
                to: 1.0
                duration: 120
                easing.type: Easing.OutQuad
            }
        }

        // Phase 2: Checkmark pop
        NumberAnimation {
            target: root
            property: "checkmarkProgress"
            from: 0.0
            to: 1.0
            duration: 240
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }

        // Phase 3: Spring bounce
        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "successPopScale"
                from: 1.0
                to: 1.12
                duration: 110
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "successPopScale"
                from: 1.12
                to: 1.0
                duration: 150
                easing.type: Easing.OutBounce
            }
        }
    }

    onStateModeChanged: {
        if (stateMode === "success") {
            successFingerprintOpacity = 1.0;
            successFingerprintScale = 1.0;
            checkmarkProgress = 0.0;
            successPopScale = 1.0;
            successCircleGlow = 0.0;
            successAnim.restart();
        } else {
            successAnim.stop();
            successFingerprintOpacity = 1.0;
            successFingerprintScale = 1.0;
            checkmarkProgress = 0.0;
            successPopScale = 1.0;
            successCircleGlow = 0.0;
            if (stateMode === "failed") {
                shakeAnim.restart();
            }
        }
    }

    // 1. Outer Pulsing Ambient Halo Ring (Circular ripple)
    Rectangle {
        id: outerHalo
        anchors.centerIn: parent
        width: root.size + 18 * (root.stateMode === "verifying" ? (1.0 + root.scanProgress * 0.35) : root.breathingScale)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: 1.5
        border.color: (root.stateMode === "success")
            ? root.successColor
            : (root.stateMode === "failed" ? root.errorColor : root.accentColor)
        opacity: (root.stateMode === "success")
            ? (0.4 * root.successCircleGlow)
            : (root.stateMode === "failed" ? 0.6 : (0.18 * root.breathingAlpha))

        Behavior on border.color { ColorAnimation { duration: 180 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // 2. Main Circular Sensor Disc (Round Pad)
    Rectangle {
        id: sensorDisc
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.shakeOffset
        width: root.size
        height: root.size
        radius: root.size / 2
        scale: root.successPopScale
        clip: true

        color: (root.stateMode === "success")
            ? Qt.rgba(48/255, 209/255, 88/255, 0.16)
            : (sensorMouse.containsMouse ? "#1c202d" : "#141620")

        border.width: (root.stateMode === "verifying" || root.stateMode === "success") ? 2.0 : 1.5
        border.color: (root.stateMode === "success")
            ? root.successColor
            : (root.stateMode === "failed"
                ? root.errorColor
                : (root.stateMode === "verifying"
                    ? root.accentColor
                    : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.50)))

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        // Scanning Laser Sweep Beam (Subtle vertical glow sweep inside circle during verification)
        Rectangle {
            id: scanBeam
            visible: root.stateMode === "verifying"
            width: parent.width * 0.82
            height: 2
            radius: 1
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.15 + (parent.height * 0.70) * root.scanProgress)
            color: root.accentColor
            opacity: 0.65
        }

        // 3. Rounded Fingerprint Glyph (\udb80\ude37 - mdi-fingerprint in Nerd Fonts)
        Text {
            id: fpIcon
            anchors.centerIn: parent
            text: "\udb80\ude37"
            font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: Math.round(root.size * 0.52)
            color: (root.stateMode === "success")
                ? root.successColor
                : (root.stateMode === "failed"
                    ? root.errorColor
                    : (root.stateMode === "verifying" ? root.accentColor : root.glyphColor))

            opacity: root.successFingerprintOpacity * (root.stateMode === "idle" ? root.breathingAlpha : 1.0)
            scale: root.successFingerprintScale * (root.stateMode === "idle" ? root.breathingScale : 1.0)

            Behavior on color { ColorAnimation { duration: 160 } }
        }

        // 4. Success Checkmark (\uf00c in JetBrainsMono Nerd Font)
        Text {
            id: checkIcon
            anchors.centerIn: parent
            text: "\uf00c"
            font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "JetBrainsMono Nerd Font"
            font.pixelSize: Math.round(root.size * 0.46)
            color: root.successColor
            opacity: root.checkmarkProgress
            scale: 0.5 + 0.5 * root.checkmarkProgress
        }

        // Interactive Click Sensor
        MouseArea {
            id: sensorMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
