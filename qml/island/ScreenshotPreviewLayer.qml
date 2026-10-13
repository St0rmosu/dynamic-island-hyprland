import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string screenshotPath: ""
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property string textFontFamily: "Google Sans Flex"
    property color accentColor: "#bdb6a6"
    property color textColor: "#c8c3b6"
    property color dimColor: "#606c75"
    property color surfaceColor: "#2e383f"
    property color irisBlue: "#95acd0"
    property color irisPurple: "#bb95d0"
    property color irisGreen: "#58b654"
    property color irisYellow: "#b7a558"
    property color irisRed: "#d0bf92"
    property string titleText: "Screenshot Catturato"
    property string subtitleText: "Copiato negli appunti"
    property bool showCondition: false
    property bool imageLanded: true
    property real screenshotAspect: 1.77

    signal openSattyRequested()
    signal openEditorRequested()
    signal dismissRequested()
    signal imageSizeReady(real w, real h)

    anchors.fill: parent
    opacity: showCondition ? 1 : 0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation {
            duration: root.showCondition ? 260 : 160
            easing.type: Easing.OutCubic
        }
    }

    property bool copiedFeedback: false
    property bool shareMenuOpen: false

    Timer {
        id: copiedResetTimer
        interval: 1500
        running: false
        repeat: false
        onTriggered: root.copiedFeedback = false
    }

    property bool controlsRevealed: root.imageLanded

    Timer {
        id: controlsRevealTimer
        interval: 110
        running: root.showCondition && !root.imageLanded
        repeat: false
        onTriggered: root.controlsRevealed = true
    }

    onShowConditionChanged: {
        if (!showCondition) {
            controlsRevealed = false;
        } else {
            root.forceActiveFocus();
        }
    }

    focus: true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.dismissRequested();
            event.accepted = true;
        }
    }

    property real controlsOpacity: (root.imageLanded || root.controlsRevealed) ? 1.0 : 0.0

    Behavior on controlsOpacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    property bool fileReady: false

    function refreshImage(path) {
        if (path && path !== "") {
            screenshotPath = path;
        }
        fileReady = true;
        previewImg.source = "";
        if (screenshotPath !== "") {
            previewImg.source = "file://" + screenshotPath;
        }
    }

    Component.onCompleted: {
        if (root.imageLanded && root.screenshotPath !== "") {
            refreshImage(root.screenshotPath);
        }
    }

    onImageLandedChanged: {
        if (imageLanded && previewImg.status !== Image.Ready && screenshotPath !== "") {
            refreshImage(screenshotPath);
        }
    }

    onScreenshotPathChanged: {
        if (screenshotPath !== "") {
            refreshImage(screenshotPath);
        }
    }

    function copyToClipboard() {
        if (!screenshotPath || screenshotPath === "") return
        const copyCmd = `wl-copy < '${screenshotPath}'`
        Quickshell.execDetached(["bash", "-c", copyCmd])
        root.copiedFeedback = true
        copiedResetTimer.restart()
    }

    function shareTo(appId) {
        if (!screenshotPath || screenshotPath === "") return
        let cmd = ""
        switch (appId) {
            case "satty":
                root.openSattyRequested()
                return
            case "discord":
                cmd = `discord '${screenshotPath}' 2>/dev/null || vesktop '${screenshotPath}' 2>/dev/null`
                break
            case "localsend":
                cmd = `localsend '${screenshotPath}' 2>/dev/null`
                break
            default:
                break
        }
        if (cmd !== "") {
            Quickshell.execDetached(["bash", "-c", cmd])
        }
        root.dismissRequested()
    }

    Item {
        anchors.fill: parent
        anchors.margins: 12

        // ── 1. Top Header Row ───────────────────────────────────────────
        Row {
            id: headerRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 32
            spacing: 8
            opacity: root.controlsOpacity
            transform: Translate {
                y: (1.0 - root.controlsOpacity) * -6
            }

            // Icona Camera in badge circolare
            Rectangle {
                width: 28
                height: 28
                radius: 14
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
                border.width: 1
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)

                Text {
                    anchors.centerIn: parent
                    text: "\uf030"
                    color: root.accentColor
                    font.family: root.iconFontFamily
                    font.pixelSize: 12
                }
            }

            // Info testo
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                width: parent.width - 28 - 26 - 16

                Text {
                    text: root.titleText
                    color: root.textColor
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.family: root.textFontFamily
                    elide: Text.ElideRight
                }

                Row {
                    spacing: 4
                    Text {
                        text: "\uf00c"
                        color: root.accentColor
                        font.family: root.iconFontFamily
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: root.subtitleText
                        color: root.dimColor
                        font.pixelSize: 10
                        font.family: root.textFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                    }
                }
            }

            // Pulsante Chiudi
            Rectangle {
                width: 26
                height: 26
                radius: 13
                anchors.verticalCenter: parent.verticalCenter
                color: maClose.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    color: maClose.containsMouse ? root.accentColor : root.dimColor
                    font.family: root.iconFontFamily
                    font.pixelSize: 11
                }

                MouseArea {
                    id: maClose
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissRequested()
                }
            }
        }

        // ── 2. Box Anteprima Immagine Adattivo ─────────────────────────
        Rectangle {
            id: imageBox
            anchors.top: headerRow.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(50, Math.min(220, Math.round(width / Math.max(0.4, root.screenshotAspect))))
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.75)
            border.width: 1
            border.color: maImage.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.10)
            clip: true
            opacity: (root.imageLanded || root.controlsRevealed) ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Behavior on border.color {
                ColorAnimation { duration: 160 }
            }

            Image {
                id: previewImg
                anchors.fill: parent
                anchors.margins: 4
                source: (root.fileReady && root.screenshotPath !== "") ? ("file://" + root.screenshotPath) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
                opacity: root.imageLanded ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                }

                onStatusChanged: {
                    if (status === Image.Ready && implicitWidth > 0 && implicitHeight > 0) {
                        root.imageSizeReady(implicitWidth, implicitHeight)
                    }
                }
            }

            // Hover indicator overlay: Pill con icona e solo "Modifica"
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.28)
                opacity: maImage.containsMouse ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 160 }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: pillRow.implicitWidth + 22
                    height: 28
                    radius: 14
                    color: Qt.rgba(14 / 255, 14 / 255, 14 / 255, 0.88)
                    border.width: 1
                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)

                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "\uf040"
                            color: root.accentColor
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Modifica"
                            color: root.textColor
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.family: root.textFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            MouseArea {
                id: maImage
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openEditorRequested()
            }
        }

        // ── 3. Bottom Action Bar (Copia, Modifica nell'Isola, Condividi) ──
        Row {
            id: buttonBar
            anchors.top: imageBox.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: 32
            spacing: 8
            opacity: root.controlsOpacity
            transform: Translate {
                y: (1.0 - root.controlsOpacity) * 6
            }

            // Pulsante: Copia Negli Appunti
            Rectangle {
                height: 32
                width: (buttonBar.width - 16) * 0.32
                radius: 8
                color: root.copiedFeedback ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25) : (maCopyBtn.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.08))
                border.width: 1
                border.color: root.copiedFeedback ? root.accentColor : (maCopyBtn.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.12))

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: root.copiedFeedback ? "\uf00c" : "\uf0c5"
                        color: root.copiedFeedback ? root.irisGreen : (maCopyBtn.containsMouse ? root.accentColor : root.accentColor)
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.copiedFeedback ? "Copiato!" : "Copia"
                        color: root.copiedFeedback ? root.irisGreen : root.textColor
                        font.pixelSize: 11
                        font.bold: true
                        font.family: root.textFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: maCopyBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.copyToClipboard()
                }
            }

            // Pulsante: Modifica nell'Isola (espande la dynamic island!)
            Rectangle {
                height: 32
                width: (buttonBar.width - 16) * 0.36
                radius: 8
                color: maEditBtn.containsMouse ? root.accentColor : Qt.rgba(root.irisBlue.r, root.irisBlue.g, root.irisBlue.b, 0.18)
                border.width: 1
                border.color: maEditBtn.containsMouse ? root.accentColor : root.irisBlue

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "\uf040"
                        color: maEditBtn.containsMouse ? "#000000" : root.irisBlue
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Modifica"
                        color: maEditBtn.containsMouse ? "#000000" : root.textColor
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.family: root.textFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: maEditBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openEditorRequested()
                }
            }

            // Pulsante: Condividi con l'App Desiderata (Telegram, Discord, File...)
            Rectangle {
                height: 32
                width: (buttonBar.width - 16) * 0.32
                radius: 8
                color: root.shareMenuOpen ? root.irisPurple : (maShareBtn.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.08))
                border.width: 1
                border.color: root.shareMenuOpen ? root.irisPurple : (maShareBtn.containsMouse ? root.irisPurple : Qt.rgba(255, 255, 255, 0.12))

                Row {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "\uf1e0"
                        color: root.shareMenuOpen ? "#000000" : (maShareBtn.containsMouse ? root.irisPurple : root.irisPurple)
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Invia a..."
                        color: root.shareMenuOpen ? "#000000" : root.textColor
                        font.pixelSize: 11
                        font.family: root.textFontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: maShareBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shareMenuOpen = !root.shareMenuOpen
                }
            }
        }

        // ── Menu Popup Condividi ──────────────────────────────────────────────────
        Rectangle {
        id: sharePopup
        visible: root.shareMenuOpen
        anchors.bottom: buttonBar.top
        anchors.bottomMargin: 8
        anchors.right: buttonBar.right
        anchors.rightMargin: 12
        width: 180
        height: colShareOptions.height + 14
        radius: 10
        color: Qt.rgba(14 / 255, 14 / 255, 14 / 255, 0.96)
        border.width: 1
        border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
        z: 99

        Column {
            id: colShareOptions
            anchors.centerIn: parent
            width: parent.width - 14
            spacing: 3

            Repeater {
                model: [
                    { id: "satty", icon: "\uf040", name: "Apri in Satty", tint: root.irisBlue },
                    { id: "discord", icon: "\uf392", name: "Invia su Discord", tint: root.irisPurple },
                    { id: "localsend", icon: "\uf1d8", name: "Invia con LocalSend", tint: root.irisGreen }
                ]

                Rectangle {
                    width: parent.width
                    height: 26
                    radius: 6
                    color: maItem.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.20) : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        spacing: 8

                        Text {
                            text: modelData.icon
                            color: modelData.tint || root.accentColor
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.name
                            color: root.textColor
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: maItem
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.shareMenuOpen = false
                            root.shareTo(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
}


