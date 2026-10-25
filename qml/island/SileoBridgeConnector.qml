import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Shapes

// Sileo Liquid Geometry Addon Container
// Provides authentic Apple/Sileo liquid drop-down collar with G1 continuous concave fillets,
// flat orthogonal shoulders, elevation drop shadows, and synchronous spring animations.
Item {
    id: root

    property bool showCondition: false
    property real neckTargetWidth: 140
    property real neckTopY: 0
    property real neckTopR: 20
    property real maxFilletR: 14
    property real shoulderY: 48
    property real cardTargetW: 380
    property real cardTargetH: 84
    property real cardR: 20
    property color surfaceColor: Qt.rgba(0, 0, 0, 0.94)
    property color outlineColor: Qt.rgba(1, 1, 1, 0.12)
    property real outlineWidth: 1
    property color accentColor: "#60a5fa"
    property int openDuration: 280
    property int closeDuration: 200
    property real animProgress: 0
    readonly property real neckHalfW: neckTargetWidth / 2
    readonly property real curFilletR: maxFilletR * animProgress
    readonly property real curCardH: cardTargetH * animProgress
    readonly property real curCardBottomY: shoulderY + curCardH
    readonly property real curCardW: (neckHalfW * 2) + (cardTargetW - neckHalfW * 2) * animProgress
    readonly property real curCardHalfW: curCardW / 2
    readonly property real curCardR: Math.min(cardR, Math.max(cardR * animProgress, curCardH / 2))
    readonly property real cx: root.width / 2
    readonly property real nLeft: cx - neckHalfW
    readonly property real nRight: cx + neckHalfW
    readonly property real cLeft: cx - curCardHalfW
    readonly property real cRight: cx + curCardHalfW
    default property alias content: contentHost.data
    property alias contentItem: contentHost

    onShowConditionChanged: {
        if (showCondition) {
            closeAnim.stop();
            openAnim.from = root.animProgress;
            openAnim.restart();
        } else {
            openAnim.stop();
            closeAnim.from = root.animProgress;
            closeAnim.restart();
        }
    }
    Component.onCompleted: {
        root.animProgress = 0;
        if (showCondition) {
            openAnim.from = 0;
            openAnim.restart();
        }
    }

    NumberAnimation {
        id: openAnim

        target: root
        property: "animProgress"
        from: root.animProgress
        to: 1
        duration: root.openDuration
        easing.type: Easing.OutQuint
    }

    NumberAnimation {
        id: closeAnim

        target: root
        property: "animProgress"
        from: root.animProgress
        to: 0
        duration: root.closeDuration
        easing.type: Easing.OutCubic
    }

    // ── Ombre Eleganti Dynamic Island Card (Elevation Drop Shadows) ────────
    Item {
        id: shadowContainer

        readonly property real safeCornerRadius: Math.min(root.curCardR, Math.min(width, height) / 2)

        z: -1
        x: Math.round((root.width - root.curCardW) / 2)
        y: root.shoulderY
        width: root.curCardW
        height: root.curCardH
        visible: root.curCardH > 6 && root.animProgress > 0.05
        opacity: root.animProgress

        // 1. Ombra Diffusa Morbida (Ambient Soft Shadow)
        RectangularGlow {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: -6
            glowRadius: 20
            spread: 0.02
            color: Qt.rgba(0, 0, 0, 0.38)
            cornerRadius: shadowContainer.safeCornerRadius
        }

        // 2. Ombra Ravvicinata di Profondità (Direct Key Shadow)
        RectangularGlow {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -3
            glowRadius: 9
            spread: 0.04
            color: Qt.rgba(0, 0, 0, 0.44)
            cornerRadius: shadowContainer.safeCornerRadius
        }

        // 3. Delicato Glow Accento Dinamico (Subtle Tinted Rim Glow)
        RectangularGlow {
            anchors.fill: parent
            glowRadius: 7
            spread: 0
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
            cornerRadius: shadowContainer.safeCornerRadius
        }

    }

    // ── Sileo Liquid Shape Background (Clean 90° Fillets & Flat Horizontal Shoulders) ──
    Shape {
        id: sileoBgShape

        anchors.fill: parent
        asynchronous: false
        visible: root.animProgress > 0.001
        opacity: root.animProgress

        ShapePath {
            fillColor: root.surfaceColor
            strokeColor: root.outlineColor
            strokeWidth: root.outlineWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            // 1. Start at top-center of the neck
            startX: root.cx
            startY: root.neckTopY

            // 2. Line along top of neck to top-right corner
            PathLine {
                x: root.nRight - root.neckTopR
                y: root.neckTopY
            }

            PathArc {
                x: root.nRight
                y: root.neckTopY + root.neckTopR
                radiusX: root.neckTopR
                radiusY: root.neckTopR
            }

            // 3. Straight vertical line down right wall of neck to concave fillet
            PathLine {
                x: root.nRight
                y: root.shoulderY - root.curFilletR
            }

            // 4. Right concave liquid fillet (vertical tangent at neck -> horizontal tangent at shoulder)
            PathCubic {
                x: root.nRight + root.curFilletR
                y: root.shoulderY
                control1X: root.nRight
                control1Y: root.shoulderY - root.curFilletR * 0.5
                control2X: root.nRight
                control2Y: root.shoulderY
            }

            // 5. Card top-right horizontal shoulder (strictly flat horizontal, zero oblique lines!)
            PathLine {
                x: Math.max(root.nRight + root.curFilletR, root.cRight - root.curCardR)
                y: root.shoulderY
            }

            PathArc {
                x: root.cRight
                y: root.shoulderY + root.curCardR
                radiusX: root.curCardR
                radiusY: root.curCardR
            }

            // 6. Card right vertical edge
            PathLine {
                x: root.cRight
                y: Math.max(root.shoulderY + root.curCardR, root.curCardBottomY - root.curCardR)
            }

            PathArc {
                x: root.cRight - root.curCardR
                y: root.curCardBottomY
                radiusX: root.curCardR
                radiusY: root.curCardR
            }

            // 7. Card bottom horizontal edge
            PathLine {
                x: root.cLeft + root.curCardR
                y: root.curCardBottomY
            }

            PathArc {
                x: root.cLeft
                y: Math.max(root.shoulderY + root.curCardR, root.curCardBottomY - root.curCardR)
                radiusX: root.curCardR
                radiusY: root.curCardR
            }

            // 8. Card left vertical edge
            PathLine {
                x: root.cLeft
                y: root.shoulderY + root.curCardR
            }

            PathArc {
                x: root.cLeft + root.curCardR
                y: root.shoulderY
                radiusX: root.curCardR
                radiusY: root.curCardR
            }

            // 9. Card top-left horizontal shoulder
            PathLine {
                x: Math.max(root.cLeft + root.curCardR, root.nLeft - root.curFilletR)
                y: root.shoulderY
            }

            // 10. Left concave liquid fillet (horizontal tangent at shoulder -> vertical tangent at neck)
            PathCubic {
                x: root.nLeft
                y: root.shoulderY - root.curFilletR
                control1X: root.nLeft
                control1Y: root.shoulderY
                control2X: root.nLeft
                control2Y: root.shoulderY - root.curFilletR * 0.5
            }

            // 11. Straight vertical line up left wall of neck to top-left corner
            PathLine {
                x: root.nLeft
                y: root.neckTopY + root.neckTopR
            }

            PathArc {
                x: root.nLeft + root.neckTopR
                y: root.neckTopY
                radiusX: root.neckTopR
                radiusY: root.neckTopR
            }

            // 12. Return to top center
            PathLine {
                x: root.cx
                y: root.neckTopY
            }

        }

    }

    // ── Content Host: Dynamic Liquid Clipping Envelope matching wlogout ──
    Item {
        id: clipHost

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.shoulderY
        width: root.curCardW
        height: root.curCardH
        clip: true
        visible: opacity > 0.001
        opacity: Math.max(0, Math.min(1, (root.animProgress - 0.12) / 0.88))

        Item {
            id: contentHost

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: root.cardTargetW
            height: root.cardTargetH
            transformOrigin: Item.Top
            scale: 0.92 + 0.08 * root.animProgress

            transform: Translate {
                y: -6 * (1 - root.animProgress)
            }

        }

    }

}
