pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property int size: 48
    property color glyphColor: "#ffffff"
    property color accentColor: "#0a84ff"
    property color successColor: "#30d158"
    property color errorColor: "#ff453a"

    property string stateMode: "idle" // "idle", "verifying", "success", "failed"
    property real scanProgress: 0.0
    property real breathingScale: 1.0
    property real breathingAlpha: 1.0
    property real shakeOffset: 0.0

    // Success animation properties (matching Apple Touch ID & Face ID dynamics)
    property real successFingerprintOpacity: 1.0
    property real successFingerprintScale: 1.0
    property real ringAlpha: 1.0
    property real gyroAlpha: 0.0
    property real gyroProgress: 0.0
    property real circleAlpha: 0.0
    property real checkmarkProgress: 0.0
    property real successPopScale: 1.0

    width: size
    height: size

    // Idle breathing pulsation
    SequentialAnimation {
        running: root.stateMode === "idle"
        loops: Animation.Infinite
        ParallelAnimation {
            NumberAnimation { target: root; property: "breathingScale"; from: 1.0; to: 1.04; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "breathingAlpha"; from: 0.85; to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "breathingScale"; from: 1.04; to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "breathingAlpha"; from: 1.0; to: 0.85; duration: 1600; easing.type: Easing.InOutSine }
        }
    }

    // Scanning wave sweep animation when verifying
    SequentialAnimation {
        running: root.stateMode === "verifying"
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "scanProgress"; from: 0.0; to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "scanProgress"; from: 1.0; to: 0.0; duration: 600; easing.type: Easing.InOutSine }
    }

    // Haptic Shake on failure
    SequentialAnimation {
        id: shakeAnim
        running: false
        NumberAnimation { target: root; property: "shakeOffset"; from: 0; to: -6; duration: 40; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; from: -6; to: 6; duration: 40; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; from: 6; to: -4; duration: 40; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; from: -4; to: 4; duration: 40; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; from: 4; to: 0; duration: 40; easing.type: Easing.InOutQuad }
    }

    // Authentic Apple Touch ID Success Sequence:
    // 1. Fingerprint ridges fade out & shrink as 3D gyros awaken (0 - 100ms)
    // 2. 3D perspective rings spin and coalesce into circle (100ms - 320ms)
    // 3. Apple green circle outline establishes and vector checkmark draws inside (320ms - 580ms)
    // 4. Subtle Apple spring pop bounce settles the verification (580ms - 860ms)
    SequentialAnimation {
        id: successAnim
        running: false

        // Phase 1: Dissolve fingerprint & activate gyro rings (0 - 100ms)
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
                property: "ringAlpha"
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

        // Phase 2: Gyro 3D Orbit & Coalesce into Circle (100ms - 320ms)
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "gyroProgress"
                from: 0.0
                to: 1.0
                duration: 220
                easing.type: Easing.InOutCubic
            }
            SequentialAnimation {
                PauseAnimation { duration: 160 }
                NumberAnimation {
                    target: root
                    property: "gyroAlpha"
                    from: 1.0
                    to: 0.0
                    duration: 60
                    easing.type: Easing.OutQuad
                }
            }
            SequentialAnimation {
                PauseAnimation { duration: 170 }
                NumberAnimation {
                    target: root
                    property: "circleAlpha"
                    from: 0.0
                    to: 1.0
                    duration: 50
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Phase 3: Checkmark Dynamic Draw inside Circle (320ms - 580ms)
        NumberAnimation {
            target: root
            property: "checkmarkProgress"
            from: 0.0
            to: 1.0
            duration: 260
            easing.type: Easing.OutCubic
        }

        // Phase 4: Apple Spring Pop Bounce (580ms - 860ms)
        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "successPopScale"
                from: 1.0
                to: 1.10
                duration: 120
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            }
            NumberAnimation {
                target: root
                property: "successPopScale"
                from: 1.10
                to: 1.0
                duration: 160
                easing.type: Easing.OutBounce
            }
        }
    }

    onScanProgressChanged: canvas.requestPaint()
    onBreathingScaleChanged: canvas.requestPaint()
    onBreathingAlphaChanged: canvas.requestPaint()
    onShakeOffsetChanged: canvas.requestPaint()
    onSuccessFingerprintOpacityChanged: canvas.requestPaint()
    onSuccessFingerprintScaleChanged: canvas.requestPaint()
    onRingAlphaChanged: canvas.requestPaint()
    onGyroAlphaChanged: canvas.requestPaint()
    onGyroProgressChanged: canvas.requestPaint()
    onCircleAlphaChanged: canvas.requestPaint()
    onCheckmarkProgressChanged: canvas.requestPaint()
    onSuccessPopScaleChanged: canvas.requestPaint()
    onAccentColorChanged: canvas.requestPaint()
    onGlyphColorChanged: canvas.requestPaint()

    onStateModeChanged: {
        if (stateMode === "success") {
            successFingerprintOpacity = 1.0;
            successFingerprintScale = 1.0;
            ringAlpha = 1.0;
            gyroAlpha = 0.0;
            gyroProgress = 0.0;
            circleAlpha = 0.0;
            checkmarkProgress = 0.0;
            successPopScale = 1.0;
            successAnim.restart();
        } else {
            successAnim.stop();
            ringAlpha = 1.0;
            gyroAlpha = 0.0;
            gyroProgress = 0.0;
            circleAlpha = 0.0;
            checkmarkProgress = 0.0;
            successFingerprintOpacity = 1.0;
            successFingerprintScale = 1.0;
            successPopScale = 1.0;
            if (stateMode === "failed") {
                shakeAnim.restart();
            }
        }
        canvas.requestPaint();
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var w = width;
            var h = height;
            var cx = w / 2 + root.shakeOffset;
            var cy = h / 2;
            var s = Math.min(w, h);
            var scale = s / 54.0;
            var R = 21 * scale; // Radius of outer ring / circle

            var activeColor = root.glyphColor;
            var activeRing = root.accentColor;

            if (root.stateMode === "success") {
                activeColor = root.successColor;
                activeRing = root.successColor;
            } else if (root.stateMode === "failed") {
                activeColor = root.errorColor;
                activeRing = root.errorColor;
            }

            ctx.save();
            ctx.translate(cx, cy);
            ctx.scale(root.successPopScale, root.successPopScale);
            ctx.translate(-cx, -cy);

            // 1. Draw Outer Touch Sensor Ring
            if (root.ringAlpha > 0.0) {
                ctx.save();
                ctx.globalAlpha = root.ringAlpha * (root.stateMode === "idle" ? 0.45 : 0.85);
                ctx.lineWidth = 1.8 * scale;
                ctx.strokeStyle = activeRing;
                ctx.beginPath();
                ctx.arc(cx, cy, R + 2 * scale, 0, 2 * Math.PI);
                ctx.stroke();
                ctx.restore();
            }

            // 2. Draw Fingerprint Vector Concentric Ridges
            var effectiveRidgeAlpha = (root.stateMode === "success")
                ? root.successFingerprintOpacity
                : (root.stateMode === "idle" ? root.breathingAlpha : 1.0);

            if (effectiveRidgeAlpha > 0.0) {
                ctx.save();
                ctx.globalAlpha = effectiveRidgeAlpha;

                var fScale = (root.stateMode === "success")
                    ? root.successFingerprintScale
                    : (root.stateMode === "idle" ? root.breathingScale : 1.0);

                ctx.translate(cx, cy);
                ctx.scale(fScale, fScale);
                ctx.translate(-cx, -cy);

                ctx.strokeStyle = activeColor;
                ctx.lineWidth = 2.0 * scale;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                // Verifying scanning glow effect
                if (root.stateMode === "verifying") {
                    ctx.shadowColor = root.accentColor;
                    ctx.shadowBlur = 6 * scale;
                }

                // Helper to draw a parabolic arch ridge with smooth rounded top
                function drawRidge(rx, topY, botY, curveSpread) {
                    ctx.beginPath();
                    // Left leg: curves up towards apex
                    ctx.moveTo(cx - rx, cy + botY);
                    ctx.bezierCurveTo(
                        cx - rx - curveSpread, cy + (botY + topY) * 0.45,
                        cx - rx * 0.8, cy + topY,
                        cx, cy + topY
                    );
                    // Right leg: curves smoothly down
                    ctx.bezierCurveTo(
                        cx + rx * 0.8, cy + topY,
                        cx + rx + curveSpread, cy + (botY + topY) * 0.45,
                        cx + rx, cy + botY
                    );
                    ctx.stroke();
                }

                // Ridge 1 (Central vertical core loop)
                ctx.beginPath();
                ctx.moveTo(cx - 2.5 * scale, cy + 6 * scale);
                ctx.lineTo(cx - 2.5 * scale, cy - 2 * scale);
                ctx.arc(cx, cy - 2 * scale, 2.5 * scale, Math.PI, 0, false);
                ctx.lineTo(cx + 2.5 * scale, cy + 6 * scale);
                ctx.stroke();

                // Ridge 2 (Inner loop 2)
                drawRidge(6.5 * scale, -7.5 * scale, 10 * scale, 0.5 * scale);

                // Ridge 3 (Mid loop 3)
                drawRidge(11.0 * scale, -12.5 * scale, 13.5 * scale, 1.0 * scale);

                // Ridge 4 (Upper mid loop 4)
                drawRidge(15.5 * scale, -17.5 * scale, 16.5 * scale, 1.5 * scale);

                // Ridge 5 (Outer crest arch)
                ctx.beginPath();
                ctx.moveTo(cx - 18.5 * scale, cy + 13 * scale);
                ctx.bezierCurveTo(
                    cx - 20 * scale, cy - 14 * scale,
                    cx - 12 * scale, cy - 22 * scale,
                    cx, cy - 22 * scale
                );
                ctx.bezierCurveTo(
                    cx + 12 * scale, cy - 22 * scale,
                    cx + 20 * scale, cy - 14 * scale,
                    cx + 18.5 * scale, cy + 13 * scale
                );
                ctx.stroke();

                // Lateral delta loops (subtle finger edge whorls)
                ctx.beginPath();
                ctx.moveTo(cx - 13.5 * scale, cy + 8 * scale);
                ctx.quadraticCurveTo(cx - 17 * scale, cy + 14 * scale, cx - 12 * scale, cy + 18 * scale);
                ctx.stroke();

                ctx.beginPath();
                ctx.moveTo(cx + 13.5 * scale, cy + 8 * scale);
                ctx.quadraticCurveTo(cx + 17 * scale, cy + 14 * scale, cx + 11 * scale, cy + 18 * scale);
                ctx.stroke();

                // Active scanning laser beam across fingerprint in verifying mode
                if (root.stateMode === "verifying") {
                    var scanY = (cy - 20 * scale) + (root.scanProgress * 38 * scale);
                    var grad = ctx.createLinearGradient(cx - 20 * scale, scanY, cx + 20 * scale, scanY);
                    grad.addColorStop(0, "rgba(10, 132, 255, 0)");
                    grad.addColorStop(0.5, "rgba(255, 255, 255, 0.95)");
                    grad.addColorStop(1, "rgba(10, 132, 255, 0)");
                    ctx.strokeStyle = grad;
                    ctx.lineWidth = 2.4 * scale;
                    ctx.beginPath();
                    ctx.moveTo(cx - 18 * scale, scanY);
                    ctx.lineTo(cx + 18 * scale, scanY);
                    ctx.stroke();
                }

                ctx.restore();
            }

            // 3. Draw 3D Gyro Orbiting Rings (Success Transition)
            if (root.gyroAlpha > 0.0) {
                ctx.save();
                ctx.globalAlpha = root.gyroAlpha;
                ctx.shadowColor = Qt.rgba(0.19, 0.82, 0.35, 0.35);
                ctx.shadowBlur = 4 * scale;
                ctx.lineWidth = 2.6 * scale;
                ctx.strokeStyle = root.successColor;

                var p = root.gyroProgress;
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

            // 4. Draw Crisp Final Circle & Animated Checkmark
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

                // Checkmark Draw
                if (root.checkmarkProgress > 0.0) {
                    ctx.shadowBlur = 0;
                    ctx.strokeStyle = "#ffffff";
                    ctx.lineWidth = 3.6 * scale;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

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

            ctx.restore();
        }
    }
}
