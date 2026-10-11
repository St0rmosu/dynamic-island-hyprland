import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string screenshotPath: ""
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property color accentColor: "#bdb6a6"
    property color textColor: "#c8c3b6"
    property color dimColor: "#606c75"
    property color surfaceColor: "#2e383f"
    property var customColorPalette: []

    signal closeRequested()
    signal openSattyRequested()
    signal screenshotSaved(string path)

    anchors.fill: parent
    focus: true

    Keys.onEscapePressed: root.closeRequested()
    Keys.onPressed: (event) => {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Z) {
            root.undo()
            event.accepted = true
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C) {
            root.saveAndCopy("")
            event.accepted = true
        }
    }

    readonly property string screenshotFileUrl: root.screenshotPath !== "" ? ("file://" + root.screenshotPath) : ""

    function refreshImage(path) {
        if (path && path !== "") {
            screenshotPath = path;
        }
        imgHelper.source = "";
        if (screenshotFileUrl !== "") {
            imgHelper.source = screenshotFileUrl;
        }
    }

    // Stato editor
    property string currentTool: "pen" // "pen", "arrow", "rect", "highlighter", "blackout"
    property color currentColor: root.accentColor
    property real currentLineWidth: 4
    property var strokes: []
    property var currentStroke: null

    // Palette colori coerente con il sistema di temi Iris
    readonly property var colorPalette: customColorPalette.length > 0 
        ? customColorPalette 
        : [root.accentColor, "#d0bf92", "#58b654", "#b7a558", "#95acd0", "#ffffff", "#000000"]

    // Dimensioni immagine e proporzioni
    property real imageOriginalWidth: 1920
    property real imageOriginalHeight: 1080
    readonly property real imageAspect: imageOriginalWidth / Math.max(1, imageOriginalHeight)

    property bool shareMenuOpen: false
    property bool copiedFeedback: false

    Timer {
        id: copiedResetTimer
        interval: 1500
        running: false
        repeat: false
        onTriggered: root.copiedFeedback = false
    }

    onScreenshotPathChanged: {
        strokes = []
        if (screenshotFileUrl !== "") {
            editorCanvas.loadImage(screenshotFileUrl)
        }
    }

    Component.onCompleted: {
        if (screenshotFileUrl !== "") {
            editorCanvas.loadImage(screenshotFileUrl)
        }
    }

    function undo() {
        if (strokes.length > 0) {
            strokes.pop()
            editorCanvas.requestPaint()
        }
    }

    function clearAll() {
        strokes = []
        editorCanvas.requestPaint()
    }

    function saveAndCopy(openApp) {
        if (screenshotPath === "") {
            root.closeRequested()
            return
        }

        let finalPath = screenshotPath

        if (strokes.length > 0) {
            const editedPath = screenshotPath.replace(/\.png$/, "_edited.png")
            const saved = editorCanvas.save(editedPath)
            if (saved) {
                finalPath = editedPath
            }
        }

        // Copia negli appunti
        const copyCmd = `wl-copy < '${finalPath}'`
        Quickshell.execDetached(["bash", "-c", copyCmd])

        if (openApp && openApp !== "") {
            let launchCmd = ""
            switch (openApp) {
                case "satty":
                    launchCmd = `satty --filename '${finalPath}' --copy-command wl-copy --output-filename '${finalPath}'`
                    break
                case "discord":
                    launchCmd = `discord '${finalPath}' 2>/dev/null || vesktop '${finalPath}' 2>/dev/null`
                    break
                case "localsend":
                    launchCmd = `localsend '${finalPath}' 2>/dev/null`
                    break
                default:
                    break
            }
            if (launchCmd !== "") {
                Quickshell.execDetached(["bash", "-c", launchCmd])
            }
        }

        root.screenshotSaved(finalPath)
        root.closeRequested()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── 1. Top Header & Toolbar ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 8

            // Badge Editor
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 14
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
                border.width: 1
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)

                Text {
                    anchors.centerIn: parent
                    text: "\uf040"
                    color: root.accentColor
                    font.family: root.iconFontFamily
                    font.pixelSize: 12
                }
            }

            Text {
                text: "Modifica Screenshot"
                color: root.textColor
                font.family: root.textFontFamily
                font.pixelSize: 12
                font.bold: true
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                color: Qt.rgba(255, 255, 255, 0.12)
                Layout.leftMargin: 4
                Layout.rightMargin: 4
            }

            // Strumenti di disegno: Penna, Freccia, Rettangolo, Evidenziatore, Censura
            Row {
                spacing: 4

                Repeater {
                    model: [
                        { id: "pen", icon: "\uf304", name: "Penna" },
                        { id: "arrow", icon: "\uf061", name: "Freccia" },
                        { id: "rect", icon: "\uf096", name: "Riquadro" },
                        { id: "highlighter", icon: "\uf5ad", name: "Evidenziatore" },
                        { id: "blackout", icon: "\uf070", name: "Censura" }
                    ]

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 7
                        color: root.currentTool === modelData.id 
                            ? root.accentColor 
                            : (maTool.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.08))
                        border.width: 1
                        border.color: root.currentTool === modelData.id ? root.accentColor : Qt.rgba(255, 255, 255, 0.12)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: root.currentTool === modelData.id 
                                ? "#000000" 
                                : (maTool.containsMouse ? root.textColor : root.dimColor)
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: maTool
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTool = modelData.id
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                color: Qt.rgba(255, 255, 255, 0.12)
                Layout.leftMargin: 4
                Layout.rightMargin: 4
            }

            // Palette Colori
            Row {
                spacing: 5

                Repeater {
                    model: root.colorPalette

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: modelData
                        border.width: root.currentColor === modelData ? 2.5 : 1
                        border.color: root.currentColor === modelData 
                            ? (modelData === "#ffffff" ? "#000000" : "#ffffff") 
                            : Qt.rgba(255, 255, 255, 0.20)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentColor = modelData
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Undo, Clear & Close
            Row {
                spacing: 5

                // Undo
                Rectangle {
                    width: 28
                    height: 28
                    radius: 7
                    color: maUndo.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf0e2"
                        color: root.strokes.length > 0 
                            ? (maUndo.containsMouse ? root.textColor : root.dimColor) 
                            : Qt.rgba(255, 255, 255, 0.2)
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: maUndo
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.undo()
                    }
                }

                // Clear
                Rectangle {
                    width: 28
                    height: 28
                    radius: 7
                    color: maClear.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1
                    border.color: maClear.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf2ed"
                        color: maClear.containsMouse ? root.accentColor : root.dimColor
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: maClear
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearAll()
                    }
                }

                // Close (Esc)
                Rectangle {
                    width: 28
                    height: 28
                    radius: 7
                    color: maClose.containsMouse ? Qt.rgba(255, 69, 58, 0.25) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1
                    border.color: maClose.containsMouse ? "#ff453a" : Qt.rgba(255, 255, 255, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: maClose.containsMouse ? "#ff453a" : root.dimColor
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: maClose
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }
        }

        // ── 2. Canvas di disegno interattivo centrale ──────────────────────────
        Rectangle {
            id: canvasContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.75)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.10)
            clip: true

            Image {
                id: imgHelper
                source: root.screenshotFileUrl
                visible: false
                onStatusChanged: {
                    if (status === Image.Ready) {
                        root.imageOriginalWidth = implicitWidth
                        root.imageOriginalHeight = implicitHeight
                        editorCanvas.loadImage(root.screenshotFileUrl)
                    }
                }
            }

            // Calcolo dimensioni canvas proporzionato all'immagine reale
            readonly property real renderWidth: {
                const availW = Math.max(10, width - 16)
                const availH = Math.max(10, height - 16)
                const scaleW = availW / Math.max(1, root.imageOriginalWidth)
                const scaleH = availH / Math.max(1, root.imageOriginalHeight)
                const scale = Math.min(scaleW, scaleH)
                return Math.max(10, Math.round(root.imageOriginalWidth * scale))
            }
            readonly property real renderHeight: {
                const availW = Math.max(10, width - 16)
                const availH = Math.max(10, height - 16)
                const scaleW = availW / Math.max(1, root.imageOriginalWidth)
                const scaleH = availH / Math.max(1, root.imageOriginalHeight)
                const scale = Math.min(scaleW, scaleH)
                return Math.max(10, Math.round(root.imageOriginalHeight * scale))
            }

            Canvas {
                id: editorCanvas
                anchors.centerIn: parent
                width: canvasContainer.renderWidth
                height: canvasContainer.renderHeight
                renderTarget: Canvas.Image

                onImageLoaded: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()

                    // 1. Sfondo: disegna l'immagine catturata
                    if (root.screenshotFileUrl !== "" && isImageLoaded(root.screenshotFileUrl)) {
                        ctx.drawImage(root.screenshotFileUrl, 0, 0, width, height)
                    }

                    // 2. Disegna tutti i tratti confermati
                    for (let i = 0; i < root.strokes.length; ++i) {
                        drawStroke(ctx, root.strokes[i])
                    }

                    // 3. Disegna il tratto attualmente in corso di trascinamento
                    if (root.currentStroke !== null) {
                        drawStroke(ctx, root.currentStroke)
                    }
                }

                function drawStroke(ctx, s) {
                    if (!s) return
                    ctx.save()
                    ctx.strokeStyle = s.color
                    ctx.fillStyle = s.color
                    ctx.lineWidth = s.width
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"

                    if (s.tool === "highlighter") {
                        ctx.globalAlpha = 0.35
                        ctx.lineWidth = s.width * 3
                    } else if (s.tool === "blackout") {
                        ctx.globalAlpha = 1.0
                        ctx.fillStyle = "#000000"
                    }

                    if (s.tool === "pen" || s.tool === "highlighter") {
                        if (s.points && s.points.length > 0) {
                            ctx.beginPath()
                            ctx.moveTo(s.points[0].x, s.points[0].y)
                            for (let p = 1; p < s.points.length; ++p) {
                                ctx.lineTo(s.points[p].x, s.points[p].y)
                            }
                            ctx.stroke()
                        }
                    } else if (s.tool === "rect") {
                        const rx = Math.min(s.startX, s.endX)
                        const ry = Math.min(s.startY, s.endY)
                        const rw = Math.abs(s.endX - s.startX)
                        const rh = Math.abs(s.endY - s.startY)
                        ctx.beginPath()
                        ctx.strokeRect(rx, ry, rw, rh)
                    } else if (s.tool === "blackout") {
                        const rx = Math.min(s.startX, s.endX)
                        const ry = Math.min(s.startY, s.endY)
                        const rw = Math.abs(s.endX - s.startX)
                        const rh = Math.abs(s.endY - s.startY)
                        ctx.fillRect(rx, ry, rw, rh)
                    } else if (s.tool === "arrow") {
                        // Disegna linea
                        ctx.beginPath()
                        ctx.moveTo(s.startX, s.startY)
                        ctx.lineTo(s.endX, s.endY)
                        ctx.stroke()

                        // Calcola punta freccia
                        const angle = Math.atan2(s.endY - s.startY, s.endX - s.startX)
                        const headLen = Math.max(12, s.width * 3)
                        ctx.beginPath()
                        ctx.moveTo(s.endX, s.endY)
                        ctx.lineTo(s.endX - headLen * Math.cos(angle - Math.PI / 6), s.endY - headLen * Math.sin(angle - Math.PI / 6))
                        ctx.lineTo(s.endX - headLen * Math.cos(angle + Math.PI / 6), s.endY - headLen * Math.sin(angle + Math.PI / 6))
                        ctx.closePath()
                        ctx.fill()
                    }
                    ctx.restore()
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.CrossCursor

                    onPressed: (mouse) => {
                        if (root.currentTool === "pen" || root.currentTool === "highlighter") {
                            root.currentStroke = {
                                tool: root.currentTool,
                                color: root.currentColor,
                                width: root.currentLineWidth,
                                points: [{ x: mouse.x, y: mouse.y }]
                            }
                        } else {
                            root.currentStroke = {
                                tool: root.currentTool,
                                color: root.currentColor,
                                width: root.currentLineWidth,
                                startX: mouse.x,
                                startY: mouse.y,
                                endX: mouse.x,
                                endY: mouse.y
                            }
                        }
                        editorCanvas.requestPaint()
                    }

                    onPositionChanged: (mouse) => {
                        if (!root.currentStroke) return
                        if (root.currentTool === "pen" || root.currentTool === "highlighter") {
                            root.currentStroke.points.push({ x: mouse.x, y: mouse.y })
                        } else {
                            root.currentStroke.endX = mouse.x
                            root.currentStroke.endY = mouse.y
                        }
                        editorCanvas.requestPaint()
                    }

                    onReleased: {
                        if (root.currentStroke) {
                            root.strokes.push(root.currentStroke)
                            root.currentStroke = null
                            editorCanvas.requestPaint()
                        }
                    }
                }
            }
        }

        // ── 3. Bottom Action Bar ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            // Opzione: Apri in Satty esterno se desiderato
            Rectangle {
                Layout.preferredHeight: 30
                Layout.preferredWidth: rowExtSatty.width + 16
                radius: 8
                color: maSattyExt.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: maSattyExt.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.12)

                Row {
                    id: rowExtSatty
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "\uf08e"
                        color: maSattyExt.containsMouse ? root.accentColor : root.dimColor
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Apri in Satty"
                        color: maSattyExt.containsMouse ? root.textColor : root.dimColor
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: maSattyExt
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.saveAndCopy("satty")
                }
            }

            Item { Layout.fillWidth: true }

            // Pulsante Condividi / Invia a...
            Rectangle {
                Layout.preferredHeight: 30
                Layout.preferredWidth: rowShare.width + 16
                radius: 8
                color: root.shareMenuOpen ? root.accentColor : (maShare.containsMouse ? Qt.rgba(255, 255, 255, 0.14) : Qt.rgba(255, 255, 255, 0.08))
                border.width: 1
                border.color: root.shareMenuOpen ? root.accentColor : (maShare.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.12))

                Row {
                    id: rowShare
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "\uf1e0"
                        color: root.shareMenuOpen ? "#000000" : (maShare.containsMouse ? root.accentColor : root.dimColor)
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Invia a..."
                        color: root.shareMenuOpen ? "#000000" : root.textColor
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                        font.bold: root.shareMenuOpen
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: maShare
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shareMenuOpen = !root.shareMenuOpen
                }
            }

            // Pulsante Copia negli Appunti (Azione Primaria)
            Rectangle {
                Layout.preferredHeight: 30
                Layout.preferredWidth: rowCopy.width + 20
                radius: 8
                color: maCopy.containsMouse ? Qt.lighter(root.accentColor, 1.1) : root.accentColor

                Row {
                    id: rowCopy
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "\uf0c5"
                        color: "#000000"
                        font.family: root.iconFontFamily
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Copia negli appunti"
                        color: "#000000"
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: maCopy
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.saveAndCopy("")
                }
            }
        }
    }

    // ── Menu Popup Condividi ──────────────────────────────────────────────────
    Rectangle {
        id: sharePopup
        visible: root.shareMenuOpen
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48
        anchors.right: parent.right
        anchors.rightMargin: 150
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
                    { id: "satty", icon: "\uf040", name: "Apri in Satty" },
                    { id: "discord", icon: "\uf392", name: "Invia con Discord" },
                    { id: "localsend", icon: "\uf1d8", name: "Invia con LocalSend" }
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
                            color: root.accentColor
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
                            root.saveAndCopy(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
