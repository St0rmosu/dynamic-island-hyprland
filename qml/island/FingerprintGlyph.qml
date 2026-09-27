pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property int size: 56
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

    // Success animation properties (matching Apple Face ID / Touch ID dynamics)
    property real successFingerprintOpacity: 1.0
    property real successFingerprintScale: 1.0
    property real sensorRingAlpha: 1.0
    property real gyroAlpha: 0.0
    property real gyroProgress: 0.0
    property real circleAlpha: 0.0
    property real checkmarkProgress: 0.0
    property real successPopScale: 1.0

    signal clicked()

    width: size
    height: size

    // Idle breathing pulsation
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

    // Authentic Apple Face ID / Touch ID Success Sequence (synchronized with Dynamic Island morph):
    // 1. Fingerprint dissolves & sensor ring transitions to 3D gyros (0 - 100ms)
    // 2. 3D perspective gyros orbit and spin, coalescing into circle at 320ms exactly as island morphs to circle.
    // 3. Circle outline establishes, and vector checkmark draws stroke-by-stroke (320ms - 580ms).
    // 4. Subtle Apple spring pop bounce settles verification (580ms - 860ms).
    SequentialAnimation {
        id: successAnim
        running: false

        // Phase 1: Fingerprint dissolve & transition to gyros (0 - 100ms)
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "successFingerprintOpacity"
                from: 1.0
                to: 0.0
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "successFingerprintScale"
                from: 1.0
                to: 0.65
                duration: 100
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "sensorRingAlpha"
                from: 1.0
                to: 0.0
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "gyroAlpha"
                from: 0.0
                to: 1.0
                duration: 80
                easing.type: Easing.OutQuad
            }
        }

        // Phase 2: Gyro 3D orbit & coalescence into circle (100ms - 320ms)
        NumberAnimation {
            target: root
            property: "gyroProgress"
            from: 0.0
            to: 1.0
            duration: 220
            easing.type: Easing.InOutCubic
        }

        // Seamless handoff to solid circle
        ScriptAction {
            script: {
                root.gyroAlpha = 0.0;
                root.circleAlpha = 1.0;
            }
        }

        // Phase 3: Checkmark stroke draws inside the circle (320ms - 580ms)
        NumberAnimation {
            target: root
            property: "checkmarkProgress"
            from: 0.0
            to: 1.0
            duration: 260
            easing.type: Easing.OutCubic
        }

        // Phase 4: Spring pop bounce on the glyph (580ms - 860ms)
        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "successPopScale"
                from: 1.0
                to: 1.12
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "successPopScale"
                from: 1.12
                to: 1.0
                duration: 180
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            }
        }
    }

    onScanProgressChanged: canvas.requestPaint()
    onBreathingScaleChanged: canvas.requestPaint()
    onBreathingAlphaChanged: canvas.requestPaint()
    onSensorRingAlphaChanged: canvas.requestPaint()
    onGyroAlphaChanged: canvas.requestPaint()
    onGyroProgressChanged: canvas.requestPaint()
    onCircleAlphaChanged: canvas.requestPaint()
    onCheckmarkProgressChanged: canvas.requestPaint()
    onSuccessPopScaleChanged: canvas.requestPaint()
    onShakeOffsetChanged: canvas.requestPaint()
    onStateModeChanged: {
        if (stateMode === "success") {
            successFingerprintOpacity = 1.0;
            successFingerprintScale = 1.0;
            sensorRingAlpha = 1.0;
            gyroAlpha = 0.0;
            gyroProgress = 0.0;
            circleAlpha = 0.0;
            checkmarkProgress = 0.0;
            successPopScale = 1.0;
            successAnim.restart();
        } else {
            successAnim.stop();
            successFingerprintOpacity = 1.0;
            successFingerprintScale = 1.0;
            sensorRingAlpha = 1.0;
            gyroAlpha = 0.0;
            gyroProgress = 0.0;
            circleAlpha = 0.0;
            checkmarkProgress = 0.0;
            successPopScale = 1.0;
            if (stateMode === "failed") {
                shakeAnim.restart();
            }
        }
        canvas.requestPaint();
    }

    // Central sensor pad disc background
    Rectangle {
        id: sensorBg
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.shakeOffset
        width: root.size
        height: root.size
        radius: root.size / 2
        scale: root.successPopScale
        color: (root.stateMode === "success")
            ? Qt.rgba(48/255, 209/255, 88/255, 0.16)
            : (sensorMouse.containsMouse ? "#1c202d" : "#141620")
        opacity: root.stateMode === "success" ? root.circleAlpha : 1.0

        Behavior on color { ColorAnimation { duration: 180 } }
    }

    // Fingerprint Glyph (Nerd Font \udb80\ude37)
    Text {
        id: fpIcon
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.shakeOffset
        text: "\udb80\ude37"
        font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "JetBrainsMono Nerd Font"
        font.pixelSize: Math.round(root.size * 0.52)
        color: (root.stateMode === "success")
            ? root.successColor
            : (root.stateMode === "failed"
                ? root.errorColor
                : (root.stateMode === "verifying" ? root.accentColor : root.glyphColor))

        opacity: root.successFingerprintOpacity * (root.stateMode === "idle" ? root.breathingAlpha : 1.0)
        scale: root.successFingerprintScale * (root.stateMode === "idle" ? root.breathingScale : 1.0) * root.successPopScale
        visible: opacity > 0

        Behavior on color { ColorAnimation { duration: 160 } }
    }

    // Canvas for dynamic vector rendering:
    // - Outer breathing halo & sensor ring border
    // - Scanning laser sweep beam
    // - 3D Gyro orbiting rings that coalesce into the circle
    // - Glowing green circular boundary
    // - Apple stroke-by-stroke vector checkmark
    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.horizontalCenterOffset: root.shakeOffset
        scale: root.successPopScale
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var w = width;
            var h = height;
            var cx = w / 2;
            var cy = h / 2;
            var s = Math.min(w, h);
            var scale = s / 56.0;
            var R = 23 * scale; // Radius of circular sensor / gyros

            var activeAccent = root.accentColor;
            if (root.stateMode === "success") {
                activeAccent = root.successColor;
            } else if (root.stateMode === "failed") {
                activeAccent = root.errorColor;
            }

            // 1. Draw Static / Idle / Verifying Sensor Border & Pulsing Halo
            if (root.sensorRingAlpha > 0.0) {
                ctx.save();
                ctx.globalAlpha = root.sensorRingAlpha;

                // Pulsing outer ambient halo
                if (root.stateMode === "idle" || root.stateMode === "verifying") {
                    ctx.save();
                    ctx.lineWidth = 1.4 * scale;
                    ctx.strokeStyle = activeAccent;
                    ctx.globalAlpha = root.sensorRingAlpha * (root.stateMode === "verifying" ? 0.35 : 0.18 * root.breathingAlpha);
                    var haloR = R + 5 * scale * root.breathingScale;
                    ctx.beginPath();
                    ctx.arc(cx, cy, haloR, 0, 2 * Math.PI);
                    ctx.stroke();
                    ctx.restore();
                }

                // Sensor main disc border
                ctx.lineWidth = (root.stateMode === "verifying") ? 2.2 * scale : 1.6 * scale;
                ctx.strokeStyle = activeAccent;
                ctx.shadowColor = Qt.rgba(activeAccent.r, activeAccent.g, activeAccent.b, 0.4);
                ctx.shadowBlur = (root.stateMode === "verifying") ? 6 * scale : 0;
                ctx.beginPath();
                ctx.arc(cx, cy, R, 0, 2 * Math.PI);
                ctx.stroke();

                // Scanning laser beam inside circle when verifying
                if (root.stateMode === "verifying") {
                    var scanY = cy - 0.65 * R + (root.scanProgress * 1.30 * R);
                    var beamHalfW = Math.sqrt(Math.max(0, R * R - (scanY - cy) * (scanY - cy))) * 0.92;
                    if (beamHalfW > 2) {
                        var grad = ctx.createLinearGradient(cx - beamHalfW, scanY, cx + beamHalfW, scanY);
                        grad.addColorStop(0, "rgba(10, 132, 255, 0)");
                        grad.addColorStop(0.5, "rgba(10, 132, 255, 0.95)");
                        grad.addColorStop(1, "rgba(10, 132, 255, 0)");
                        ctx.strokeStyle = grad;
                        ctx.lineWidth = 2.4 * scale;
                        ctx.beginPath();
                        ctx.moveTo(cx - beamHalfW, scanY);
                        ctx.lineTo(cx + beamHalfW, scanY);
                        ctx.stroke();
                    }
                }

                ctx.restore();
            }

            // 2. Draw 3D Gyro Orbiting Rings (Success Transition)
            if (root.gyroAlpha > 0.0) {
                ctx.save();
                ctx.globalAlpha = root.gyroAlpha;
                ctx.shadowColor = Qt.rgba(0.19, 0.82, 0.35, 0.35);
                ctx.shadowBlur = 4 * scale;
                ctx.lineWidth = 2.6 * scale;
                ctx.strokeStyle = root.successColor;

                var p = root.gyroProgress; // 0.0 to 1.0
                var rot = p * Math.PI * 2.2;

                // Ring 1 (tilted left, rotates and rounds out)
                var angle1 = (-0.45 + p * 1.2) * (1.0 - p);
                var minRatio1 = 0.38 + 0.62 * Math.pow(p, 1.5);
                var osc1 = Math.abs(Math.cos(rot));
                var ratio1 = osc1 * (1.0 - p) + minRatio1 * p;
                ratio1 = Math.min(1.0, Math.max(0.28, ratio1));

                ctx.save();
                ctx.translate(cx, cy);
                ctx.rotate(angle1);
                ctx.scale(1.0, ratio1);
                ctx.beginPath();
                ctx.arc(0, 0, R, 0, 2 * Math.PI);
                ctx.restore();
                ctx.stroke();

                // Ring 2 (tilted right, rotates and rounds out)
                var angle2 = (0.78 - p * 0.9) * (1.0 - p);
                var minRatio2 = 0.42 + 0.58 * Math.pow(p, 1.5);
                var osc2 = Math.abs(Math.sin(rot + 0.8));
                var ratio2 = osc2 * (1.0 - p) + minRatio2 * p;
                ratio2 = Math.min(1.0, Math.max(0.28, ratio2));

                ctx.save();
                ctx.translate(cx, cy);
                ctx.rotate(angle2);
                ctx.scale(1.0, ratio2);
                ctx.beginPath();
                ctx.arc(0, 0, R, 0, 2 * Math.PI);
                ctx.restore();
                ctx.stroke();

                ctx.restore();
            }

            // 3. Draw Crisp Final Circle & Animated Vector Checkmark
            if (root.circleAlpha > 0.0) {
                ctx.save();
                ctx.globalAlpha = root.circleAlpha;

                // Circular Outline with gentle Apple glow
                ctx.shadowColor = Qt.rgba(0.19, 0.82, 0.35, 0.45);
                ctx.shadowBlur = 6 * scale;
                ctx.lineWidth = 2.8 * scale;
                ctx.strokeStyle = root.successColor;
                ctx.beginPath();
                ctx.arc(cx, cy, R, 0, 2 * Math.PI);
                ctx.stroke();

                // Checkmark Draw (crisp white checkmark inside glowing green circle)
                if (root.checkmarkProgress > 0.0) {
                    ctx.shadowBlur = 0;
                    ctx.strokeStyle = "#ffffff";
                    ctx.lineWidth = 3.6 * scale;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    // Exact proportions from Apple Touch ID / Face ID
                    var p1x = cx - 0.38 * R;
                    var p1y = cy - 0.02 * R;
                    var p2x = cx - 0.12 * R;
                    var p2y = cy + 0.32 * R;
                    var p3x = cx + 0.42 * R;
                    var p3y = cy - 0.38 * R;

                    ctx.beginPath();
                    ctx.moveTo(p1x, p1y);

                    var split = 0.33;
                    if (root.checkmarkProgress <= split) {
                        var t1 = root.checkmarkProgress / split;
                        ctx.lineTo(p1x + (p2x - p1x) * t1, p1y + (p2y - p1y) * t1);
                    } else {
                        ctx.lineTo(p2x, p2y);
                        var t2 = (root.checkmarkProgress - split) / (1.0 - split);
                        ctx.lineTo(p2x + (p3x - p2x) * t2, p2y + (p3y - p2y) * t2);
                    }
                    ctx.stroke();
                }

                ctx.restore();
            }
        }
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
