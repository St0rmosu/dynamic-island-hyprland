import QtQuick
import QtQuick.Layouts
import Quickshell
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    property bool showCondition: false
    property bool failed: false
    property string errorString: ""
    property color accentColor: "#34d399"
    property var configSource: null
    readonly property var activeConfig: configSource || userConfig
    property string iconFontFamily: activeConfig.iconFontFamily || "JetBrainsMono Nerd Font"
    property string textFontFamily: activeConfig.textFontFamily || "Google Sans Flex"
    property string heroFontFamily: activeConfig.heroFontFamily || "Google Sans Flex"

    signal dismissRequested()

    property bool copiedFeedback: false
    Timer {
        id: copiedResetTimer
        interval: 2200
        repeat: false
        onTriggered: root.copiedFeedback = false
    }

    readonly property bool hasErrorDetails: failed && errorString !== ""

    readonly property var parsedErrorInfo: {
        if (!errorString || errorString === "") return { location: "", reason: "" };
        const raw = errorString.trim();

        // Pattern 1: file:///path/to/.../File.qml:line:col: message
        const fileMatch = raw.match(/(?:file:\/\/)?([^\s:]+\/[^\s:]+\.qml):(\d+(?::\d+)?):\s*(.*)/i);
        if (fileMatch) {
            const fullPath = fileMatch[1];
            const lineCol = fileMatch[2];
            const message = fileMatch[3] ? fileMatch[3].trim() : "";
            const fileName = fullPath.substring(fullPath.lastIndexOf('/') + 1);
            return {
                location: fileName + ":" + lineCol,
                reason: message !== "" ? message : raw
            };
        }

        // Pattern 2: Component.qml:line: message
        const simpleMatch = raw.match(/([a-zA-Z0-9_\-]+\.qml):(\d+(?::\d+)?):\s*(.*)/i);
        if (simpleMatch) {
            return {
                location: simpleMatch[1] + ":" + simpleMatch[2],
                reason: simpleMatch[3] ? simpleMatch[3].trim() : raw
            };
        }

        // Clean up common prefixes like "Cannot load QML: " or "Error: "
        let clean = raw.replace(/^Cannot load QML:\s*/i, "").replace(/^Error:\s*/i, "");
        return {
            location: "",
            reason: clean
        };
    }

    readonly property string errorLocation: parsedErrorInfo.location
    readonly property string displayErrorReason: parsedErrorInfo.reason

    readonly property real preferredWidth: failed
        ? (errorString !== "" ? 510 : 320)
        : 300

    readonly property real preferredHeight: failed
        ? (errorString !== "" ? (displayErrorReason.length > 50 ? 98 : 88) : 46)
        : Math.max(userConfig ? userConfig.islandHeight : 38, 42)

    readonly property real preferredRadius: (failed && errorString !== "") ? 24 : preferredHeight / 2

    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 220 : 140
            easing.type: Easing.InOutQuad
        }
    }

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

    MouseArea {
        id: mainHoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // ── 1. Success State Layout (Elegant compact pill) ────────────────────────
    Item {
        visible: !root.failed
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 4
        anchors.bottomMargin: 4

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 12

            // Icon badge with smooth rotation
            Rectangle {
                id: iconBadgeSuccess
                width: 28
                height: 28
                radius: 14
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(52/255, 211/255, 153/255, 0.15)
                border.color: "#34d399"
                border.width: 1

                Text {
                    id: iconGlyphSuccess
                    anchors.centerIn: parent
                    text: ""
                    color: "#34d399"
                    font.pixelSize: 13
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

            // Text column
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - iconBadgeSuccess.width - 24 - 12 - 8
                spacing: 1

                Text {
                    text: "Quickshell Ricaricato"
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.family: root.textFontFamily
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.15
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: "Configurazione applicata"
                    color: "#94a3b8"
                    font.pixelSize: 10
                    font.family: root.textFontFamily
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // Check badge on the right
            Rectangle {
                width: 22
                height: 22
                radius: 11
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(52/255, 211/255, 153/255, 0.18)
                border.color: Qt.rgba(52/255, 211/255, 153/255, 0.45)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: ""
                    color: "#34d399"
                    font.pixelSize: 11
                    font.family: root.iconFontFamily
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dismissRequested()
        }
    }

    // ── 2. Failed State Layout (Refined Apple/Cealestia card with code box) ───
    Item {
        visible: root.failed
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 10

        Column {
            anchors.fill: parent
            spacing: 6

            // Top Header Row
            Row {
                width: parent.width
                height: 26
                spacing: 9

                // Danger Icon Badge
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(248/255, 113/255, 113/255, 0.18)
                    border.color: Qt.rgba(248/255, 113/255, 113/255, 0.55)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: "#f87171"
                        font.pixelSize: 13
                        font.family: root.iconFontFamily
                    }
                }

                // Title
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reload Fallito"
                    color: "#fca5a5"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.family: root.textFontFamily
                }

                // Location Tag (e.g. FocusTimeLayer.qml:125)
                Rectangle {
                    visible: root.errorLocation !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    height: 19
                    width: locRow.implicitWidth + 12
                    radius: 6
                    color: Qt.rgba(255, 255, 255, 0.08)
                    border.color: Qt.rgba(248/255, 113/255, 113/255, 0.3)
                    border.width: 1

                    Row {
                        id: locRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: ""
                            font.family: root.iconFontFamily
                            font.pixelSize: 10
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
                    height: 20
                    width: copiedRow.implicitWidth + 10
                    radius: 6
                    color: Qt.rgba(52/255, 211/255, 153/255, 0.2)
                    border.color: "#34d399"
                    border.width: 1

                    Row {
                        id: copiedRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: ""
                            font.family: root.iconFontFamily
                            font.pixelSize: 10
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
                    width: 22
                    height: 22
                    radius: 11
                    anchors.verticalCenter: parent.verticalCenter
                    color: dismissMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.06)
                    border.width: 1
                    border.color: dismissMouse.containsMouse ? "#f87171" : Qt.rgba(255, 255, 255, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: dismissMouse.containsMouse ? "#ffffff" : "#fca5a5"
                        font.pixelSize: 11
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
                height: parent.height - 26 - 6
                radius: 8
                color: copyMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                border.width: 1
                border.color: copyMouse.containsMouse ? Qt.rgba(248/255, 113/255, 113/255, 0.45) : Qt.rgba(255, 255, 255, 0.08)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (copyHint.visible ? copyHint.width + 6 : 0)
                        text: root.displayErrorReason !== "" ? root.displayErrorReason : "Errore durante il reload di Quickshell"
                        color: "#e2e8f0"
                        font.pixelSize: 11
                        font.family: root.iconFontFamily
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        lineHeight: 1.15
                    }

                    // Small copy icon on right on hover
                    Row {
                        id: copyHint
                        anchors.verticalCenter: parent.verticalCenter
                        visible: copyMouse.containsMouse && !root.copiedFeedback
                        spacing: 4
                        opacity: 0.85

                        Text {
                            text: ""
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
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
            }
        }
    }

    // ── 3. Auto-Dismiss Progress Bar (with track and pause on hover) ──────────
    Rectangle {
        id: progressBarTrack
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        height: 3
        radius: 1.5
        width: Math.max(0, root.preferredWidth - 32)
        color: root.failed ? Qt.rgba(248/255, 113/255, 113/255, 0.18) : Qt.rgba(52/255, 211/255, 153/255, 0.18)

        Rectangle {
            id: progressBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: 1.5
            color: root.failed ? "#f87171" : "#34d399"
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
