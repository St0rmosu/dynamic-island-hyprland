pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property int size: 50
    property color glyphColor: "#ffffff"
    property color bracketColor: "#0a84ff"
    property color successColor: "#30d158"
    property color errorColor: "#ff453a"

    property string stateMode: "idle" // "idle", "verifying", "success", "failed"
    property real scanProgress: 0.0
    property real eyeHeightScale: 1.0
    property real bracketScale: 1.0

    // Success animation properties (matching Apple Face ID video dynamics)
    property real successFaceOpacity: 1.0
    property real successFaceScale: 1.0
    property real bracketAlpha: 1.0
    property real gyroAlpha: 0.0
    property real gyroProgress: 0.0
    property real circleAlpha: 0.0
    property real checkmarkProgress: 0.0
    property real successPopScale: 1.0

    width: size
    height: size

    // Eye blink animation when idle
    SequentialAnimation {
        running: root.stateMode === "idle"
        loops: Animation.Infinite
        PauseAnimation { duration: 3200 }
        NumberAnimation { target: root; property: "eyeHeightScale"; from: 1.0; to: 0.15; duration: 75; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "eyeHeightScale"; from: 0.15; to: 1.0; duration: 85; easing.type: Easing.InOutQuad }
    }

    // Scanning sweep animation when verifying
    SequentialAnimation {
        running: root.stateMode === "verifying"
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "scanProgress"; from: 0.0; to: 1.0; duration: 550; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "scanProgress"; from: 1.0; to: 0.0; duration: 550; easing.type: Easing.InOutSine }
    }

    // Breathing bracket animation when idle
    SequentialAnimation {
        running: root.stateMode === "idle"
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "bracketScale"; from: 1.0; to: 1.05; duration: 1400; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "bracketScale"; from: 1.05; to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
    }

    // Authentic Apple Face ID Success Sequence (synchronized with Dynamic Island morph):
    // 1. Face features shrink and fade out; brackets morph into 3D gyros (0 - 100ms).
    // 2. Two 3D perspective rings spin and orbit, coalescing into circle at 320ms exactly as the island finishes morphing to circle.
    // 3. Circle outline establishes, and vector checkmark draws inside (320ms - 580ms).
    // 4. Subtle Apple spring pop bounce settles the lock (580ms - 860ms).
    SequentialAnimation {
        id: successAnim
        running: false

        // Phase 1: Face dissolve & bracket transition (0 - 100ms)
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "successFaceOpacity"
                from: 1.0
                to: 0.0
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "successFaceScale"
                from: 1.0
                to: 0.65
                duration: 100
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root
                property: "bracketAlpha"
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

    onEyeHeightScaleChanged: canvas.requestPaint()
    onScanProgressChanged: canvas.requestPaint()
    onBracketScaleChanged: canvas.requestPaint()
    onSuccessFaceOpacityChanged: canvas.requestPaint()
    onSuccessFaceScaleChanged: canvas.requestPaint()
    onBracketAlphaChanged: canvas.requestPaint()
    onGyroAlphaChanged: canvas.requestPaint()
    onGyroProgressChanged: canvas.requestPaint()
    onCircleAlphaChanged: canvas.requestPaint()
    onCheckmarkProgressChanged: canvas.requestPaint()
    onSuccessPopScaleChanged: canvas.requestPaint()
    onBracketColorChanged: canvas.requestPaint()
    onGlyphColorChanged: canvas.requestPaint()
    onStateModeChanged: {
        if (stateMode === "success") {
            successFaceOpacity = 1.0;
            successFaceScale = 1.0;
            bracketAlpha = 1.0;
            gyroAlpha = 0.0;
            gyroProgress = 0.0;
            circleAlpha = 0.0;
            checkmarkProgress = 0.0;
            successPopScale = 1.0;
            successAnim.restart();
        } else {
            successAnim.stop();
            bracketAlpha = 1.0;
            gyroAlpha = 0.0;
            gyroProgress = 0.0;
            circleAlpha = 0.0;
            checkmarkProgress = 0.0;
            successFaceOpacity = 1.0;
            successFaceScale = 1.0;
            successPopScale = 1.0;
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
            var cx = w / 2;
            var cy = h / 2;
            var s = Math.min(w, h);
            var scale = s / 54.0;
            var R = 21 * scale; // Radius of the bounding circle / rings

            var activeColor = root.glyphColor;
            var activeBracket = root.bracketColor;

            if (root.stateMode === "success") {
                activeColor = root.successColor;
                activeBracket = root.successColor;
            } else if (root.stateMode === "failed") {
                activeColor = root.errorColor;
                activeBracket = root.errorColor;
            }

            ctx.save();
            ctx.translate(cx, cy);
            ctx.scale(root.successPopScale, root.successPopScale);
            ctx.translate(-cx, -cy);

            // 1. Draw Corner Brackets
            if (root.bracketAlpha > 0.0) {
                ctx.save();
                ctx.globalAlpha = root.bracketAlpha;
                ctx.translate(cx, cy);
                ctx.scale(root.bracketScale, root.bracketScale);
                ctx.translate(-cx, -cy);

                ctx.lineWidth = 2.4 * scale;
                ctx.lineCap = "round";
                ctx.strokeStyle = activeBracket;

                var bPad = 6 * scale;
                var bLen = 10 * scale;
                var bRad = 5 * scale;

                // Top-Left
                ctx.beginPath();
                ctx.moveTo(bPad, bPad + bLen);
                ctx.lineTo(bPad, bPad + bRad);
                ctx.arcTo(bPad, bPad, bPad + bRad, bPad, bRad);
                ctx.lineTo(bPad + bLen, bPad);
                ctx.stroke();

                // Top-Right
                ctx.beginPath();
                ctx.moveTo(w - bPad - bLen, bPad);
                ctx.lineTo(w - bPad - bRad, bPad);
                ctx.arcTo(w - bPad, bPad, w - bPad, bPad + bRad, bRad);
                ctx.lineTo(w - bPad, bPad + bLen);
                ctx.stroke();

                // Bottom-Left
                ctx.beginPath();
                ctx.moveTo(bPad, h - bPad - bLen);
                ctx.lineTo(bPad, h - bPad - bRad);
                ctx.arcTo(bPad, h - bPad, bPad + bRad, h - bPad, bRad);
                ctx.lineTo(bPad + bLen, h - bPad);
                ctx.stroke();

                // Bottom-Right
                ctx.beginPath();
                ctx.moveTo(w - bPad - bLen, h - bPad);
                ctx.lineTo(w - bPad - bRad, h - bPad);
                ctx.arcTo(w - bPad, h - bPad, w - bPad, h - bPad - bRad, bRad);
                ctx.lineTo(w - bPad, h - bPad - bLen);
                ctx.stroke();

                ctx.restore();
            }

            // 2. Draw Face Features (Eyes, Nose, Smile)
            var effectiveFaceAlpha = (root.stateMode === "success") ? root.successFaceOpacity : 1.0;
            if (effectiveFaceAlpha > 0.0) {
                ctx.save();
                ctx.globalAlpha = effectiveFaceAlpha;

                var fScale = (root.stateMode === "success") ? root.successFaceScale : 1.0;
                ctx.translate(cx, cy);
                ctx.scale(fScale, fScale);
                ctx.translate(-cx, -cy);

                ctx.fillStyle = activeColor;
                ctx.strokeStyle = activeColor;
                ctx.lineWidth = 2.4 * scale;
                ctx.lineCap = "round";

                // Eyes: Two vertical capsules
                var eyeW = 3.2 * scale;
                var eyeH = 6.4 * scale * root.eyeHeightScale;
                var eyeY = (20.5 * scale) - (eyeH / 2);
                var eyeX1 = 19.5 * scale - (eyeW / 2);
                var eyeX2 = 34.5 * scale - (eyeW / 2);

                ctx.beginPath();
                if (ctx.roundRect) {
                    ctx.roundRect(eyeX1, eyeY, eyeW, Math.max(1, eyeH), eyeW / 2);
                    ctx.roundRect(eyeX2, eyeY, eyeW, Math.max(1, eyeH), eyeW / 2);
                } else {
                    ctx.rect(eyeX1, eyeY, eyeW, Math.max(1, eyeH));
                    ctx.rect(eyeX2, eyeY, eyeW, Math.max(1, eyeH));
                }
                ctx.fill();

                // Nose: Vertical line going down, then curving smoothly to the left (matching Apple Face ID)
                ctx.beginPath();
                ctx.moveTo(27 * scale, 19.5 * scale);
                ctx.lineTo(27 * scale, 27 * scale);
                ctx.arcTo(27 * scale, 29.5 * scale, 23.5 * scale, 29.5 * scale, 2.5 * scale);
                ctx.lineTo(23.5 * scale, 29.5 * scale);
                ctx.stroke();

                // Smile: Gentle arc
                ctx.beginPath();
                ctx.moveTo(19.5 * scale, 35 * scale);
                ctx.quadraticCurveTo(27 * scale, 40 * scale, 34.5 * scale, 35 * scale);
                ctx.stroke();

                // Scanning Laser Beam when verifying
                if (root.stateMode === "verifying") {
                    var scanY = (13 + (root.scanProgress * 28)) * scale;
                    var grad = ctx.createLinearGradient(12 * scale, scanY, 42 * scale, scanY);
                    grad.addColorStop(0, "rgba(10, 132, 255, 0)");
                    grad.addColorStop(0.5, "rgba(10, 132, 255, 0.95)");
                    grad.addColorStop(1, "rgba(10, 132, 255, 0)");
                    ctx.strokeStyle = grad;
                    ctx.lineWidth = 2.4 * scale;
                    ctx.beginPath();
                    ctx.moveTo(12 * scale, scanY);
                    ctx.lineTo(42 * scale, scanY);
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

                // Checkmark Draw (crisp white checkmark inside glowing green circle)
                if (root.checkmarkProgress > 0.0) {
                    ctx.shadowBlur = 0;
                    ctx.strokeStyle = "#ffffff";
                    ctx.lineWidth = 3.6 * scale;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    // Exact proportions from Apple Face ID
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

            ctx.restore(); // restores popScale
        }
    }
}
