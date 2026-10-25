import IslandBackend
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    readonly property var userConfig: UserConfig
    property bool showCondition: false
    property bool failed: false
    property string errorString: ""
    property color accentColor: failed ? "#f87171" : "#34d399"
    property color surfaceColor: Qt.rgba(0, 0, 0, 0.94)
    property color outlineColor: failed ? Qt.rgba(248 / 255, 113 / 255, 113 / 255, 0.32) : Qt.rgba(52 / 255, 211 / 255, 153 / 255, 0.28)
    property var configSource: null
    readonly property var activeConfig: configSource || userConfig
    property string iconFontFamily: activeConfig.iconFontFamily || "JetBrainsMono Nerd Font"
    property string textFontFamily: activeConfig.textFontFamily || "Google Sans Flex"
    property string heroFontFamily: activeConfig.heroFontFamily || "Google Sans Flex"
    // Sileo liquid connector properties
    property real neckTargetWidth: 140
    property real shoulderY: 48
    property bool copiedFeedback: false
    readonly property bool hasErrorDetails: failed && errorString !== ""
    readonly property var parsedErrorInfo: {
        if (!errorString || errorString === "")
            return {
            "location": "",
            "reason": ""
        };

        const raw = errorString.trim();
        // Pattern 1: file:///path/to/.../File.qml:line:col: message
        const fileMatch = raw.match(/(?:file:\/\/)?([^\s:]+\/[^\s:]+\.qml):(\d+(?::\d+)?):\s*(.*)/i);
        if (fileMatch) {
            const fullPath = fileMatch[1];
            const lineCol = fileMatch[2];
            const message = fileMatch[3] ? fileMatch[3].trim() : "";
            const fileName = fullPath.substring(fullPath.lastIndexOf('/') + 1);
            return {
                "location": fileName + ":" + lineCol,
                "reason": message !== "" ? message : raw
            };
        }
        // Pattern 2: Component.qml:line: message
        const simpleMatch = raw.match(/([a-zA-Z0-9_\-]+\.qml):(\d+(?::\d+)?):\s*(.*)/i);
        if (simpleMatch)
            return {
            "location": simpleMatch[1] + ":" + simpleMatch[2],
            "reason": simpleMatch[3] ? simpleMatch[3].trim() : raw
        };

        let clean = raw.replace(/^Cannot load QML:\s*/i, "").replace(/^Error:\s*/i, "");
        return {
            "location": "",
            "reason": clean
        };
    }
    readonly property string errorLocation: parsedErrorInfo.location
    readonly property string displayErrorReason: parsedErrorInfo.reason
    readonly property real cardTargetW: failed ? 460 : 420
    readonly property real cardTargetH: failed ? (displayErrorReason.length > 50 ? 104 : 92) : 74

    signal dismissRequested()

    anchors.fill: parent
    onShowConditionChanged: {
        if (showCondition) {
            if (!failed) {
                iconGlyphSuccess.rotation = 0;
                reloadRotationAnim.restart();
            }
            progressBar.width = progressBarTrack.width;
            progressBarAnim.restart();
        } else {
            reloadRotationAnim.stop();
            progressBarAnim.stop();
            root.copiedFeedback = false;
        }
    }

    Timer {
        id: copiedResetTimer

        interval: 2200
        repeat: false
        onTriggered: root.copiedFeedback = false
    }

    MouseArea {
        id: mainHoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    SileoBridgeConnector {
        id: bridge

        anchors.fill: parent
        showCondition: root.showCondition
        neckTargetWidth: root.neckTargetWidth
        cardTargetW: root.cardTargetW
        cardTargetH: root.cardTargetH
        shoulderY: root.shoulderY
        surfaceColor: root.surfaceColor
        outlineColor: root.outlineColor
        accentColor: root.accentColor

        Item {
            anchors.fill: parent

            // ── 1. Success State Layout (Cealestia Premium Sileo Card) ────────
            Item {
                visible: !root.failed
                anchors.fill: parent

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    anchors.topMargin: 10
                    anchors.bottomMargin: 12
                    spacing: 12

                    // Animated Reload / Check Squircle Badge (Left)
                    Rectangle {
                        id: iconBadgeSuccess

                        width: 40
                        height: 40
                        radius: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(52 / 255, 211 / 255, 153 / 255, 0.16)
                        border.color: Qt.rgba(52 / 255, 211 / 255, 153 / 255, 0.45)
                        border.width: 1

                        Text {
                            id: iconGlyphSuccess

                            anchors.centerIn: parent
                            text: ""
                            color: "#34d399"
                            font.pixelSize: 17
                            font.family: root.iconFontFamily
                            transformOrigin: Item.Center
                            antialiasing: true
                        }

                        RotationAnimation {
                            id: reloadRotationAnim

                            target: iconGlyphSuccess
                            property: "rotation"
                            from: 0
                            to: 360
                            duration: 650
                            direction: RotationAnimation.Clockwise
                            easing.type: Easing.OutCubic
                        }

                    }

                    // Content Column (Center)
                    Item {
                        width: parent.width - iconBadgeSuccess.width - dismissSuccessBtn.width - parent.spacing * 2
                        height: parent.height

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            // Header: Title + "Pronto" Badge + "• adesso"
                            Row {
                                width: parent.width
                                spacing: 6

                                Text {
                                    text: "Quickshell Ricaricato"
                                    color: "#ffffff"
                                    font.pixelSize: 13
                                    font.family: root.textFontFamily
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: -0.15
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 16
                                    width: statusText.implicitWidth + 8
                                    radius: 4
                                    color: Qt.rgba(52 / 255, 211 / 255, 153 / 255, 0.16)
                                    border.width: 1
                                    border.color: Qt.rgba(52 / 255, 211 / 255, 153 / 255, 0.35)

                                    Text {
                                        id: statusText

                                        anchors.centerIn: parent
                                        text: "Pronto"
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        font.family: root.textFontFamily
                                        color: "#34d399"
                                    }

                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "• adesso"
                                    color: "#64748b"
                                    font.pixelSize: 10
                                    font.family: root.textFontFamily
                                }

                            }

                            // Subtitle
                            Text {
                                width: parent.width
                                text: "Configurazione e script sincronizzati con successo"
                                color: "#cbd5e1"
                                font.pixelSize: 11
                                font.family: root.textFontFamily
                                elide: Text.ElideRight
                            }

                        }

                    }

                    // Dismiss Button (Right)
                    Rectangle {
                        id: dismissSuccessBtn

                        width: 24
                        height: 24
                        radius: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: dismissSuccessMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: dismissSuccessMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.28) : Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: dismissSuccessMouse.containsMouse ? "#ffffff" : "#94a3b8"
                            font.pixelSize: 10
                            font.family: root.iconFontFamily
                        }

                        MouseArea {
                            id: dismissSuccessMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dismissRequested()
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }

                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 140
                            }

                        }

                    }

                }

                // Click anywhere on card to dismiss
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissRequested()
                }

            }

            // ── 2. Failed State Layout (Refined Cealestia Error Card with Code Box) ───
            Item {
                visible: root.failed
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                anchors.topMargin: 10
                anchors.bottomMargin: 10

                Column {
                    anchors.fill: parent
                    spacing: 7

                    // Top Header Row
                    Row {
                        width: parent.width
                        height: 28
                        spacing: 8

                        // Danger Icon Badge
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(248 / 255, 113 / 255, 113 / 255, 0.18)
                            border.color: Qt.rgba(248 / 255, 113 / 255, 113 / 255, 0.55)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: "#f87171"
                                font.pixelSize: 15
                                font.family: root.iconFontFamily
                            }

                        }

                        // Title
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Errore di Ricarica"
                            color: "#fca5a5"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            font.family: root.textFontFamily
                            font.letterSpacing: -0.15
                        }

                        // Location Tag (e.g. FocusTimeLayer.qml:125)
                        Rectangle {
                            visible: root.errorLocation !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            height: 18
                            width: locRow.implicitWidth + 10
                            radius: 5
                            color: Qt.rgba(255, 255, 255, 0.07)
                            border.color: Qt.rgba(248 / 255, 113 / 255, 113 / 255, 0.35)
                            border.width: 1

                            Row {
                                id: locRow

                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: ""
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 9
                                    color: "#f87171"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: root.errorLocation
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: "#fca5a5"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                        }

                        Item {
                            width: 1
                            height: 1
                            Layout.fillWidth: true
                        }

                        // Copied Feedback Badge
                        Rectangle {
                            visible: root.copiedFeedback
                            anchors.verticalCenter: parent.verticalCenter
                            height: 18
                            width: copiedRow.implicitWidth + 10
                            radius: 5
                            color: Qt.rgba(52 / 255, 211 / 255, 153 / 255, 0.2)
                            border.color: "#34d399"
                            border.width: 1

                            Row {
                                id: copiedRow

                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: ""
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 9
                                    color: "#34d399"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Copiato!"
                                    font.family: root.textFontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: "#34d399"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                        }

                        // Dismiss Button (X)
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            anchors.verticalCenter: parent.verticalCenter
                            color: dismissMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.05)
                            border.width: 1
                            border.color: dismissMouse.containsMouse ? "#f87171" : Qt.rgba(255, 255, 255, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: dismissMouse.containsMouse ? "#ffffff" : "#fca5a5"
                                font.pixelSize: 10
                                font.family: root.iconFontFamily
                            }

                            MouseArea {
                                id: dismissMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dismissRequested()
                            }

                        }

                    }

                    // Inner Code/Error Box with Copy on click
                    Rectangle {
                        width: parent.width
                        height: parent.height - 28 - 7
                        radius: 8
                        color: copyMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.07) : Qt.rgba(255, 255, 255, 0.035)
                        border.width: 1
                        border.color: copyMouse.containsMouse ? Qt.rgba(248 / 255, 113 / 255, 113 / 255, 0.45) : Qt.rgba(255, 255, 255, 0.08)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - (copyHint.visible ? copyHint.width + 8 : 0)
                                text: root.displayErrorReason !== "" ? root.displayErrorReason : "Errore durante il reload di Quickshell"
                                color: "#f1f5f9"
                                font.pixelSize: 11
                                font.family: root.iconFontFamily
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                lineHeight: 1.15
                            }

                            // Small copy hint on right on hover
                            Row {
                                id: copyHint

                                anchors.verticalCenter: parent.verticalCenter
                                visible: copyMouse.containsMouse && !root.copiedFeedback
                                spacing: 4
                                opacity: 0.85

                                Text {
                                    text: ""
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 10
                                    color: "#94a3b8"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Copia"
                                    font.family: root.textFontFamily
                                    font.pixelSize: 10
                                    color: "#94a3b8"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                        }

                        MouseArea {
                            id: copyMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.errorString !== "") {
                                    Quickshell.execDetached(["wl-copy", root.errorString]);
                                    root.copiedFeedback = true;
                                    copiedResetTimer.restart();
                                }
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 150
                            }

                        }

                    }

                }

            }

            // ── 3. Auto-Dismiss Progress Bar ──────────
            Rectangle {
                id: progressBarTrack

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 2
                radius: 1
                width: Math.max(0, root.cardTargetW - 36)
                color: Qt.rgba(255, 255, 255, 0.06)

                Rectangle {
                    id: progressBar

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: 1
                    color: root.accentColor
                    width: parent.width

                    PropertyAnimation {
                        id: progressBarAnim

                        target: progressBar
                        property: "width"
                        from: progressBarTrack.width
                        to: 0
                        duration: root.failed ? 9000 : 4000
                        easing.type: Easing.Linear
                        paused: mainHoverArea.containsMouse
                    }

                }

            }

        }

    }

}
