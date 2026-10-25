import "../common"
import IslandBackend
import QtCore
import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

FocusScope {
    id: root

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property color accentColor: "#60a5fa"
    property color surfaceColor: "#000000"
    property color outlineColor: "#22ffffff"
    property real outlineWidth: 1.0
    property int activeIndex: 0

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    // ── Sileo Liquid Geometry (Exact Island Alignment, Orthogonal Edges & Smooth Concave Fillets) ──
    property real neckTargetWidth: 140
    readonly property real neckHalfW: neckTargetWidth / 2
    readonly property real neckTopY: 0
    readonly property real neckTopR: 20
    readonly property real maxFilletR: 14
    readonly property real shoulderY: 48
    readonly property real cardTargetW: 376
    readonly property real cardTargetH: 84
    readonly property real cardR: 20

    // Initialize at 0.0 so entrance animation ALWAYS plays on load
    property real animProgress: 0.0

    NumberAnimation {
        id: openAnim
        target: root
        property: "animProgress"
        from: root.animProgress
        to: 1.0
        duration: 280
        easing.type: Easing.OutQuint
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "animProgress"
        from: root.animProgress
        to: 0.0
        duration: 200
        easing.type: Easing.OutCubic
    }

    Component.onCompleted: {
        root.animProgress = 0.0;
        if (root.showCondition) {
            root.activeIndex = 0;
            root.forceActiveFocus();
            autoCloseTimer.restart();
            openAnim.from = 0.0;
            openAnim.restart();
        }
    }

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

    readonly property var powerActions: [{
        "id": "lock",
        "glyph": "",
        "accentColor": irisColors.accentHex !== "" ? irisColors.accentHex : root.accentColor,
        "command": root.homeDir + "/.scripts/qslock-wrapper.sh"
    }, {
        "id": "logout",
        "glyph": "",
        "accentColor": irisColors.accentHex !== "" ? irisColors.accentHex : root.accentColor,
        "command": "hyprctl dispatch exit"
    }, {
        "id": "sleep",
        "glyph": "",
        "accentColor": irisColors.accentHex !== "" ? irisColors.accentHex : root.accentColor,
        "command": "systemctl suspend"
    }, {
        "id": "restart",
        "glyph": "",
        "accentColor": irisColors.accentHex !== "" ? irisColors.accentHex : root.accentColor,
        "command": "systemctl reboot"
    }, {
        "id": "shutdown",
        "glyph": "",
        "accentColor": "#ef4444",
        "command": "systemctl poweroff"
    }]

    signal closeRequested()

    function runCealestiaCommand(cmd) {
        var finalCmd = cmd.trim();
        var fullBash = "nohup setsid " + finalCmd + " >/dev/null 2>&1 &";
        try {
            Quickshell.execDetached(["bash", "-c", fullBash]);
        } catch (e) {
            console.warn("[PowerMenuLayer] execDetached bash failed, attempting direct exec:", e);
            try {
                Quickshell.execDetached(finalCmd.split(" "));
            } catch (e2) {
                console.warn("[PowerMenuLayer] direct execDetached failed:", e2);
            }
        }
    }

    Timer {
        id: actionTimer
        property string pendingCmd: ""
        interval: 220
        repeat: false
        onTriggered: {
            if (pendingCmd !== "") {
                root.runCealestiaCommand(pendingCmd);
                pendingCmd = "";
            }
        }
    }

    function triggerAction(cmd) {
        actionTimer.pendingCmd = cmd;
        actionTimer.restart();
        root.closeRequested();
    }

    anchors.fill: parent
    focus: showCondition
    onShowConditionChanged: {
        if (showCondition) {
            root.activeIndex = 0;
            root.forceActiveFocus();
            autoCloseTimer.restart();
            closeAnim.stop();
            openAnim.from = root.animProgress;
            openAnim.restart();
        } else {
            autoCloseTimer.stop();
            openAnim.stop();
            closeAnim.from = root.animProgress;
            closeAnim.restart();
        }
    }

    Keys.onPressed: (event) => {
        autoCloseTimer.restart();
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            root.activeIndex = (root.activeIndex - 1 + powerActions.length) % powerActions.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            root.activeIndex = (root.activeIndex + 1) % powerActions.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Backtab) {
            root.activeIndex = (root.activeIndex - 1 + powerActions.length) % powerActions.length;
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (root.activeIndex >= 0 && root.activeIndex < powerActions.length)
                triggerAction(powerActions[root.activeIndex].command);
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            triggerAction(root.homeDir + "/.scripts/qslock-wrapper.sh");
            event.accepted = true;
        } else if (event.key === Qt.Key_E) {
            triggerAction("hyprctl dispatch exit");
            event.accepted = true;
        } else if (event.key === Qt.Key_U) {
            triggerAction("systemctl suspend");
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            triggerAction("systemctl reboot");
            event.accepted = true;
        } else if (event.key === Qt.Key_S) {
            triggerAction("systemctl poweroff");
            event.accepted = true;
        }
    }

    Keys.onEscapePressed: (event) => {
        root.closeRequested();
        event.accepted = true;
    }

    FileView {
        id: irisColors

        property string accentHex: ""
        property string redHex: ""
        property string greenHex: ""
        property string yellowHex: ""
        property string purpleHex: ""
        property string blueHex: ""
        property string fgHex: ""
        property string bgHex: ""
        property string surfaceHex: ""

        path: root.homeDir + "/.cache/iris/colors.json"
        watchChanges: true
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text());
                if (d) {
                    accentHex = d.accent || "";
                    redHex = d.red || d.syntax_param || "";
                    greenHex = d.green || d.syntax_const || "";
                    yellowHex = d.yellow || d.syntax_operator || "";
                    purpleHex = d.syntax_type || d.syntax_keyword || "";
                    blueHex = d.syntax_func || d.accent || "";
                    fgHex = d.fg || "";
                    bgHex = d.bg || "";
                    surfaceHex = d.surface || "";
                }
            } catch (e) {
            }
        }
    }

    // Dismiss if click is inside this layer but outside the card buttons
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.closeRequested()
    }

    HoverHandler {
        id: layerHoverHandler
    }

    Timer {
        id: autoCloseTimer
        interval: 6000
        repeat: false
        onTriggered: {
            if (!layerHoverHandler.hovered && root.showCondition)
                root.closeRequested();
        }
    }

    Connections {
        function onHoveredChanged() {
            if (!layerHoverHandler.hovered && root.showCondition)
                autoCloseTimer.restart();
            else
                autoCloseTimer.stop();
        }
        target: layerHoverHandler
    }

    // ── Ombre Eleganti Dynamic Island Card (Elevation Drop Shadows) ────────
    Item {
        id: cardShadowContainer
        z: -1
        x: Math.round((root.width - root.curCardW) / 2)
        y: root.shoulderY
        width: root.curCardW
        height: root.curCardH
        visible: root.curCardH > 6 && root.animProgress > 0.05
        opacity: root.animProgress

        readonly property real safeCornerRadius: Math.min(root.curCardR, Math.min(width, height) / 2)

        // 1. Ombra Diffusa Morbida (Ambient Soft Shadow)
        RectangularGlow {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: -6
            glowRadius: 20
            spread: 0.02
            color: Qt.rgba(0, 0, 0, 0.38)
            cornerRadius: cardShadowContainer.safeCornerRadius
        }

        // 2. Ombra Ravvicinata di Profondità (Direct Key Shadow)
        RectangularGlow {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -3
            glowRadius: 9
            spread: 0.04
            color: Qt.rgba(0, 0, 0, 0.44)
            cornerRadius: cardShadowContainer.safeCornerRadius
        }

        // 3. Delicato Glow Accento Dinamico (Subtle Tinted Rim Glow)
        RectangularGlow {
            anchors.fill: parent
            glowRadius: 7
            spread: 0.0
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
            cornerRadius: cardShadowContainer.safeCornerRadius
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
            strokeColor: (layerHoverHandler && layerHoverHandler.hovered) ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45) : root.outlineColor
            strokeWidth: root.outlineWidth
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            // 1. Start at top-center of the neck
            startX: root.cx
            startY: root.neckTopY

            // 2. Line along top of neck to top-right corner
            PathLine { x: root.nRight - root.neckTopR; y: root.neckTopY }
            PathArc {
                x: root.nRight
                y: root.neckTopY + root.neckTopR
                radiusX: root.neckTopR
                radiusY: root.neckTopR
            }

            // 3. Straight vertical line down right wall of neck to concave fillet
            PathLine { x: root.nRight; y: root.shoulderY - root.curFilletR }

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
            PathLine { x: Math.max(root.nRight + root.curFilletR, root.cRight - root.curCardR); y: root.shoulderY }
            PathArc {
                x: root.cRight
                y: root.shoulderY + root.curCardR
                radiusX: root.curCardR
                radiusY: root.curCardR
            }

            // 6. Right vertical edge of card
            PathLine { x: root.cRight; y: Math.max(root.shoulderY + root.curCardR, root.curCardBottomY - root.curCardR) }
            PathArc {
                x: root.cRight - root.curCardR
                y: root.curCardBottomY
                radiusX: root.curCardR
                radiusY: root.curCardR
            }

            // 7. Bottom horizontal edge of card
            PathLine { x: root.cLeft + root.curCardR; y: root.curCardBottomY }
            PathArc {
                x: root.cLeft
                y: Math.max(root.shoulderY + root.curCardR, root.curCardBottomY - root.curCardR)
                radiusX: root.curCardR
                radiusY: root.curCardR
            }

            // 8. Left vertical edge of card
            PathLine { x: root.cLeft; y: root.shoulderY + root.curCardR }
            PathArc {
                x: root.cLeft + root.curCardR
                y: root.shoulderY
                radiusX: root.curCardR
                radiusY: root.curCardR
            }

            // 9. Card top-left horizontal shoulder (strictly flat horizontal, zero oblique lines!)
            PathLine { x: Math.max(root.cLeft + root.curCardR, root.nLeft - root.curFilletR); y: root.shoulderY }

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
            PathLine { x: root.nLeft; y: root.neckTopY + root.neckTopR }
            PathArc {
                x: root.nLeft + root.neckTopR
                y: root.neckTopY
                radiusX: root.neckTopR
                radiusY: root.neckTopR
            }

            // 12. Top edge back to start
            PathLine { x: root.cx; y: root.neckTopY }
        }
    }

    // ── Action Buttons inside Card Area ─────────────────────────────────
    Item {
        id: cardContent
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.shoulderY
        width: root.curCardW
        height: root.curCardH
        clip: true
        visible: opacity > 0.001
        opacity: Math.max(0.0, Math.min(1.0, (root.animProgress - 0.12) / 0.88))

        Row {
            anchors.centerIn: parent
            spacing: 14
            scale: 0.88 + 0.12 * root.animProgress
            transform: Translate {
                y: -10 * (1.0 - root.animProgress)
            }

            Repeater {
                model: root.powerActions

                delegate: Item {
                    id: cardItem

                    required property int index
                    required property var modelData
                    readonly property bool isSelected: root.activeIndex === index
                    readonly property bool isHovered: cardMouse.containsMouse

                    width: 54
                    height: 54

                    Rectangle {
                        id: cardBg

                        anchors.centerIn: parent
                        width: 54
                        height: 54
                        radius: 17
                        color: {
                            if (cardItem.isSelected || cardItem.isHovered)
                                return Qt.rgba(modelData.accentColor.r, modelData.accentColor.g, modelData.accentColor.b, 0.22);
                            return Qt.rgba(1, 1, 1, 0.06);
                        }
                        border.width: (cardItem.isSelected || cardItem.isHovered) ? 1.5 : 1
                        border.color: {
                            if (cardItem.isSelected || cardItem.isHovered)
                                return modelData.accentColor;
                            return Qt.rgba(1, 1, 1, 0.1);
                        }
                        scale: cardMouse.pressed ? 0.94 : ((cardItem.isSelected || cardItem.isHovered) ? 1.06 : 1)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            font.pixelSize: 22
                            font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                            color: (cardItem.isSelected || cardItem.isHovered) ? modelData.accentColor : "#dcdfe8"

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 160
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        Behavior on border.color {
                            ColorAnimation { duration: 140 }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            root.activeIndex = cardItem.index;
                            autoCloseTimer.restart();
                        }
                        onClicked: {
                            root.triggerAction(modelData.command);
                        }
                    }
                }
            }
        }
    }
}
