import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    property bool showCondition: false
    property string appName: ""
    property string summary: ""
    property string body: ""
    property string iconText: ""
    property color iconColor: "#f4f5f7"
    property bool expanded: false
    property int toggleButton: Qt.LeftButton
    property var configSource: null
    readonly property var activeConfig: configSource || userConfig
    property string iconFontFamily: activeConfig.iconFontFamily || "JetBrainsMono Nerd Font"
    property string textFontFamily: activeConfig.textFontFamily || "Google Sans Flex"
    property string heroFontFamily: activeConfig.heroFontFamily || "Google Sans Flex"

    property string screenshotPath: ""
    property real screenshotAspect: 1.77
    property color accentColor: "#ff9f0a"
    property color textColor: "#ffffff"
    property color dimColor: "#a6b0c3"
    property color surfaceColor: "#2e383f"
    property color irisBlue: "#95acd0"
    property color irisPurple: "#bb95d0"
    property color irisGreen: "#58b654"
    property color irisYellow: "#b7a558"
    property color irisRed: "#d0bf92"

    signal expansionToggleRequested()
    signal openSattyRequested(string path)
    signal openEditorRequested(string path)
    signal dismissRequested()
    signal imageSizeReady(real w, real h)

    // Title / Sender name
    readonly property string senderName: {
        const isWhatsapp = (appName + " " + summary + " " + body).toLowerCase().indexOf("whatsapp") !== -1;
        if (isWhatsapp && summary !== "" && summary.toLowerCase() !== "whatsapp") return summary;
        if (summary !== "" && body !== "") return summary;
        if (appName !== "" && appName !== "Notification") return appName;
        if (summary !== "") return summary;
        return "Nuova Notifica";
    }

    // Body content
    readonly property string messageContent: {
        if (body !== "" && summary !== "" && body !== summary) return body;
        if (body !== "") return body;
        if (summary !== "") return summary;
        return "";
    }

    // App detection for icon and color tint
    readonly property var appMeta: {
        const s = (appName + " " + summary + " " + body).toLowerCase();
        if (s.indexOf("schermo") !== -1 || s.indexOf("screen") !== -1 || s.indexOf("trasmissione") !== -1 || s.indexOf("registrazione") !== -1 || s.indexOf("recording") !== -1) {
            const scColor = (root.iconColor && root.iconColor != "#f4f5f7") ? root.iconColor : root.accentColor;
            return {
                icon: (root.iconText !== "" && !root.isImageIcon) ? root.iconText : "\uf0379",
                color: scColor,
                bg: Qt.rgba(scColor.r, scColor.g, scColor.b, 0.22)
            };
        }
        if (s.indexOf("whatsapp") !== -1)
            return { icon: "\uf232", color: "#25D366", bg: Qt.rgba(37/255, 211/255, 102/255, 0.22) };
        if (s.indexOf("discord") !== -1 || s.indexOf("vesktop") !== -1 || s.indexOf("armcord") !== -1)
            return { icon: "\uf392", color: "#5865F2", bg: Qt.rgba(88/255, 101/255, 242/255, 0.22) };
        if (s.indexOf("telegram") !== -1)
            return { icon: "\uf2c6", color: "#229ED9", bg: Qt.rgba(34/255, 158/255, 217/255, 0.22) };
        if (s.indexOf("spotify") !== -1)
            return { icon: "\uf1bc", color: "#1DB954", bg: Qt.rgba(29/255, 185/255, 84/255, 0.22) };
        if (s.indexOf("slack") !== -1)
            return { icon: "\uf198", color: "#4A154B", bg: Qt.rgba(74/255, 21/255, 75/255, 0.25) };
        if (s.indexOf("signal") !== -1)
            return { icon: "\uf075", color: "#3A76F0", bg: Qt.rgba(58/255, 118/255, 240/255, 0.25) };
        if (s.indexOf("thunderbird") !== -1 || s.indexOf("mail") !== -1)
            return { icon: "\uf0e0", color: "#0060df", bg: Qt.rgba(0/255, 96/255, 223/255, 0.22) };
        if (s.indexOf("satty") !== -1 || s.indexOf("screenshot") !== -1)
            return { icon: "\uf030", color: "#ff9f0a", bg: Qt.rgba(255/255, 159/255, 10/255, 0.22) };
        if (s.indexOf("wifi") !== -1 || s.indexOf("rete") !== -1)
            return { icon: "\uf1eb", color: "#30d158", bg: Qt.rgba(48/255, 209/255, 88/255, 0.22) };
        if (s.indexOf("bluetooth") !== -1)
            return { icon: "\uf294", color: "#0a84ff", bg: Qt.rgba(10/255, 132/255, 255/255, 0.22) };
        const fallbackColor = (root.iconColor && root.iconColor != "#f4f5f7") ? root.iconColor : root.accentColor;
        return {
            icon: (root.iconText !== "" && root.iconText !== "" && root.iconText !== "\uf0f3" && !root.isImageIcon) ? root.iconText : "\uf0f3",
            color: fallbackColor,
            bg: Qt.rgba(fallbackColor.r, fallbackColor.g, fallbackColor.b, 0.20)
        };
    }

    readonly property bool isImageIcon: {
        const raw = String(root.iconText || "").trim();
        return raw.startsWith("/") || raw.startsWith("file://") ||
               raw.endsWith(".png") || raw.endsWith(".jpg") || raw.endsWith(".jpeg") ||
               raw.endsWith(".svg") || raw.endsWith(".webp");
    }

    readonly property string resolvedImageSource: {
        if (!isImageIcon) return "";
        const raw = String(root.iconText || "").trim();
        return raw.startsWith("file://") ? raw : ("file://" + raw);
    }

    readonly property string resolvedScreenshotPath: {
        if (screenshotPath !== "") return screenshotPath;
        const rawIcon = String(root.iconText || "").trim();
        if ((rawIcon.startsWith("/") || rawIcon.startsWith("file://")) &&
            (rawIcon.endsWith(".png") || rawIcon.endsWith(".jpg") || rawIcon.endsWith(".jpeg") || rawIcon.endsWith(".webp"))) {
            return rawIcon.replace(/^file:\/\//, "");
        }
        const combined = root.appName + " " + root.summary + " " + root.body;
        const m = combined.match(/(?:\/[^\s\n\r"']+\.(?:png|jpg|jpeg|webp))/);
        return m ? m[0] : "";
    }

    readonly property bool isScreenshot: {
        if (screenshotPath !== "") return true;
        const combined = (root.appName + " " + root.summary + " " + root.body).toLowerCase();
        return combined.indexOf("screenshot") !== -1 || combined.indexOf("satty") !== -1;
    }

    readonly property bool hasScreenshotPreview: isScreenshot && resolvedScreenshotPath !== ""

    // Measurements for dynamic sizing
    TextMetrics {
        id: senderMetrics
        font.family: root.textFontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
        text: root.senderName
    }

    TextMetrics {
        id: bodyMetrics
        font.family: root.textFontFamily
        font.pixelSize: 11
        text: root.messageContent
    }

    readonly property real minimumWidth: hasScreenshotPreview ? 280 : 290
    readonly property real maximumWidth: 480
    readonly property bool isLongMessage: bodyMetrics.advanceWidth > 260
    readonly property bool isVeryLongMessage: bodyMetrics.advanceWidth > 520

    // Dynamic width based on sender + body length or screenshot preview
    readonly property real preferredWidth: {
        if (hasScreenshotPreview) {
            const asp = screenshotAspect || 1.77;
            if (asp >= 1.6) return 400;
            if (asp >= 1.1) return 360;
            if (asp >= 0.8) return 320;
            return 280;
        }
        let maxTextW = Math.max(senderMetrics.advanceWidth, Math.min(340, bodyMetrics.advanceWidth));
        // Add margins (18 + 18) + spacing (14) + circular icon (42)
        let calcW = maxTextW + 36 + 14 + 42;
        return Math.max(minimumWidth, Math.min(maximumWidth, calcW));
    }

    // Dynamic height: adapts between 56px (single line), 66px (2 lines), 82px (3 lines) or rich screenshot preview
    readonly property real preferredHeight: {
        if (hasScreenshotPreview) {
            const asp = Math.max(0.4, Math.min(6.0, screenshotAspect || 1.77));
            const w = preferredWidth;
            const contentW = Math.max(200, w - 24);
            const imgH = Math.max(50, Math.min(220, Math.round(contentW / asp)));
            return imgH + 106;
        }
        if (messageContent === "") return 56;
        if (isVeryLongMessage) return 82;
        if (isLongMessage) return 68;
        return 58;
    }

    anchors.fill: parent
    anchors.margins: 0
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 280 : 140
            easing.type: Easing.InOutQuad
        }
    }

    // ── Rich Screenshot Notification Preview (Interactive Editor & Copy Actions) ──
    ScreenshotPreviewLayer {
        id: screenshotPreview
        anchors.fill: parent
        visible: root.hasScreenshotPreview
        screenshotPath: root.resolvedScreenshotPath
        screenshotAspect: root.screenshotAspect
        titleText: (root.senderName !== "" && root.senderName !== "Nuova Notifica") ? root.senderName : "Screenshot Catturato"
        subtitleText: root.messageContent !== "" ? root.messageContent : "Copiato negli appunti"
        iconFontFamily: root.iconFontFamily
        textFontFamily: root.textFontFamily
        accentColor: root.accentColor
        textColor: root.textColor
        dimColor: root.dimColor
        surfaceColor: root.surfaceColor
        irisBlue: root.irisBlue
        irisPurple: root.irisPurple
        irisGreen: root.irisGreen
        irisYellow: root.irisYellow
        irisRed: root.irisRed
        showCondition: root.showCondition && root.hasScreenshotPreview
        imageLanded: true
        onOpenSattyRequested: root.openSattyRequested(root.resolvedScreenshotPath)
        onOpenEditorRequested: root.openEditorRequested(root.resolvedScreenshotPath)
        onImageSizeReady: (w, h) => root.imageSizeReady(w, h)
        onDismissRequested: root.dismissRequested()
    }

    // ── Notification Layout (Mockup: Text Left, Circular Badge Right) ──
    Row {
        visible: !root.hasScreenshotPreview
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 16
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 14

        // ── Left: Sender & Message Body ────────────────────────────
        Item {
            width: parent.width - 44 - 14 // minus circle width and spacing
            height: parent.height

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                // Sender / Title (e.g. WhatsApp, Discord, Satty)
                Text {
                    width: parent.width
                    text: root.senderName
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: root.textFontFamily
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // Message Body (multi-line, wrapping cleanly based on content)
                Text {
                    width: parent.width
                    visible: root.messageContent !== ""
                    text: root.messageContent
                    color: "#a6b0c3"
                    font.pixelSize: 11
                    font.family: root.textFontFamily
                    wrapMode: Text.WordWrap
                    maximumLineCount: root.isVeryLongMessage ? 3 : (root.isLongMessage ? 2 : 1)
                    elide: Text.ElideRight
                    lineHeight: 1.05
                }
            }
        }

        // ── Right: Circular Squircle Icon Container ────────────────
        Rectangle {
            width: 42
            height: 42
            radius: 21
            anchors.verticalCenter: parent.verticalCenter
            color: root.isImageIcon ? Qt.rgba(0, 0, 0, 0.40) : root.appMeta.bg
            border.width: 1
            border.color: root.isImageIcon ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(root.appMeta.color.r, root.appMeta.color.g, root.appMeta.color.b, 0.45)
            clip: true

            Image {
                id: notifImageItem
                anchors.fill: parent
                anchors.margins: 1
                visible: root.isImageIcon
                source: root.resolvedImageSource
                fillMode: Image.PreserveAspectCrop
                mipmap: true
                smooth: true
            }

            Text {
                visible: !root.isImageIcon || notifImageItem.status !== Image.Ready
                anchors.centerIn: parent
                text: root.appMeta.icon
                color: root.appMeta.color
                font.family: root.iconFontFamily
                font.pixelSize: 19
            }
        }
    }

    TapHandler {
        enabled: !root.hasScreenshotPreview
        acceptedButtons: root.toggleButton
        onTapped: root.expansionToggleRequested()
    }
}
