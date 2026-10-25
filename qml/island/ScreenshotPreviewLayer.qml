import IslandBackend
import QtQuick
import Quickshell
import Quickshell.Io

FocusScope {
    id: root

    property string screenshotPath: ""
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property string textFontFamily: "Google Sans Flex"
    property color accentColor: "#60a5fa"
    property color textColor: "#ffffff"
    property color dimColor: "#a6b0c3"
    property color surfaceColor: Qt.rgba(0, 0, 0, 0.94)
    property color outlineColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
    property color irisBlue: "#95acd0"
    property color irisPurple: "#bb95d0"
    property color irisGreen: "#58b654"
    property color irisYellow: "#b7a558"
    property color irisRed: "#d0bf92"
    property string titleText: I18n.tr("Screenshot catturato")
    property string subtitleText: I18n.tr("Copiato negli appunti")
    property bool showCondition: false
    property bool imageLanded: true
    property real screenshotAspect: 1.77
    // Sileo liquid connector properties
    property real neckTargetWidth: 140
    property real shoulderY: 48
    readonly property real cardTargetW: 420
    readonly property real imageBoxH: Math.max(60, Math.min(140, Math.round((cardTargetW - 24) / Math.max(0.4, root.screenshotAspect))))
    readonly property real cardTargetH: 32 + 8 + imageBoxH + 8 + 32 + 24
    property bool copiedFeedback: false
    property bool shareMenuOpen: false
    property bool controlsRevealed: root.imageLanded
    property real controlsOpacity: (root.imageLanded || root.controlsRevealed || previewImg.status === Image.Ready) ? 1 : 0
    readonly property bool fileReady: screenshotPath !== ""

    signal openSattyRequested()
    signal openEditorRequested()
    signal dismissRequested()
    signal imageSizeReady(real w, real h)

    function refreshImage(path) {
        if (path && path !== "")
            screenshotPath = path;

        previewImg.source = "";
        if (screenshotPath !== "")
            previewImg.source = "file://" + screenshotPath;

    }

    function copyToClipboard() {
        if (!screenshotPath || screenshotPath === "")
            return ;

        const copyCmd = `wl-copy < '${screenshotPath}'`;
        Quickshell.execDetached(["bash", "-c", copyCmd]);
        root.copiedFeedback = true;
        copiedResetTimer.restart();
    }

    function shareTo(appId) {
        if (!screenshotPath || screenshotPath === "")
            return ;

        let cmd = "";
        switch (appId) {
        case "satty":
            root.openSattyRequested();
            return ;
        case "discord":
            cmd = `discord '${screenshotPath}' 2>/dev/null || vesktop '${screenshotPath}' 2>/dev/null`;
            break;
        case "localsend":
            cmd = `localsend '${screenshotPath}' 2>/dev/null`;
            break;
        default:
            break;
        }
        if (cmd !== "")
            Quickshell.execDetached(["bash", "-c", cmd]);

        root.dismissRequested();
    }

    anchors.fill: parent
    focus: showCondition
    onShowConditionChanged: {
        if (!showCondition)
            controlsRevealed = false;
        else
            root.forceActiveFocus();
    }
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.dismissRequested();
            event.accepted = true;
        }
    }
    Component.onCompleted: {
        if (root.imageLanded && root.screenshotPath !== "")
            refreshImage(root.screenshotPath);

        if (showCondition)
            root.forceActiveFocus();

    }
    onImageLandedChanged: {
        if (imageLanded && previewImg.status !== Image.Ready && screenshotPath !== "")
            refreshImage(screenshotPath);

    }
    onScreenshotPathChanged: {
        if (screenshotPath !== "")
            refreshImage(screenshotPath);

    }

    Timer {
        id: copiedResetTimer

        interval: 1500
        running: false
        repeat: false
        onTriggered: root.copiedFeedback = false
    }

    Timer {
        id: controlsRevealTimer

        interval: 110
        running: root.showCondition && !root.imageLanded
        repeat: false
        onTriggered: root.controlsRevealed = true
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

                // Camera icon circle badge
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
                    border.width: 1
                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf030"
                        color: root.accentColor
                        font.family: root.iconFontFamily
                        font.pixelSize: 12
                    }

                }

                // Title & Subtitle Info
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
                            color: root.irisGreen
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

                // Close Button
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

                transform: Translate {
                    y: (1 - root.controlsOpacity) * -6
                }

            }

            // ── 2. Box Anteprima Immagine Adattivo ─────────────────────────
            Rectangle {
                id: imageBox

                anchors.top: headerRow.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.imageBoxH
                radius: 10
                color: Qt.rgba(0, 0, 0, 0.75)
                border.width: 1
                border.color: maImage.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.1)
                clip: true
                opacity: (root.imageLanded || root.controlsRevealed) ? 1 : 0

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
                    opacity: (root.imageLanded || root.controlsRevealed || status === Image.Ready) ? 1 : 0
                    onStatusChanged: {
                        if (status === Image.Ready && implicitWidth > 0 && implicitHeight > 0)
                            root.imageSizeReady(implicitWidth, implicitHeight);

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 80
                            easing.type: Easing.OutQuad
                        }

                    }

                }

                // Hover indicator overlay: Pill con icona e "Modifica"
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.28)
                    opacity: maImage.containsMouse ? 1 : 0

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
                                text: I18n.tr("Modifica")
                                color: root.textColor
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.family: root.textFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }

                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
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

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 160
                    }

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

                // Button: Copia
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
                            color: root.copiedFeedback ? root.irisGreen : root.accentColor
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

                // Button: Modifica / Edit
                Rectangle {
                    height: 32
                    width: (buttonBar.width - 16) * 0.36
                    radius: 8
                    color: maEditBtn.containsMouse ? root.accentColor : Qt.rgba(root.irisBlue.r, root.irisBlue.g, root.irisBlue.b, 0.18)
                    border.width: 1
                    border.color: maEditBtn.containsMouse ? root.accentColor : root.irisBlue

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
                            text: I18n.tr("Edit")
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

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }

                    }

                }

                // Button: Condividi / Send to...
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
                            color: root.shareMenuOpen ? "#000000" : root.irisPurple
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: I18n.tr("Send to...")
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

                transform: Translate {
                    y: (1 - root.controlsOpacity) * 6
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
                        model: [{
                            "id": "satty",
                            "icon": "\uf040",
                            "name": "Apri in Satty",
                            "tint": root.irisBlue
                        }, {
                            "id": "discord",
                            "icon": "\uf392",
                            "name": "Invia su Discord",
                            "tint": root.irisPurple
                        }, {
                            "id": "localsend",
                            "icon": "\uf1d8",
                            "name": "Invia con LocalSend",
                            "tint": root.irisGreen
                        }]

                        Rectangle {
                            width: parent.width
                            height: 26
                            radius: 6
                            color: maItem.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2) : "transparent"

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
                                    text: I18n.tr(modelData.name)
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
                                    root.shareMenuOpen = false;
                                    root.shareTo(modelData.id);
                                }
                            }

                        }

                    }

                }

            }

        }

    }

    Behavior on controlsOpacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }

    }

}
