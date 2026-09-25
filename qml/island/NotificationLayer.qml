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

    signal expansionToggleRequested()

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
        return {
            icon: (root.iconText !== "" && root.iconText !== "" && root.iconText !== "\uf0f3") ? root.iconText : "\uf0f3",
            color: "#64d2ff",
            bg: Qt.rgba(100/255, 210/255, 255/255, 0.18)
        };
    }

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

    readonly property real minimumWidth: 290
    readonly property real maximumWidth: 480
    readonly property bool isLongMessage: bodyMetrics.advanceWidth > 260
    readonly property bool isVeryLongMessage: bodyMetrics.advanceWidth > 520

    // Dynamic width based on sender + body length
    readonly property real preferredWidth: {
        let maxTextW = Math.max(senderMetrics.advanceWidth, Math.min(340, bodyMetrics.advanceWidth));
        // Add margins (18 + 18) + spacing (14) + circular icon (42)
        let calcW = maxTextW + 36 + 14 + 42;
        return Math.max(minimumWidth, Math.min(maximumWidth, calcW));
    }

    // Dynamic height: adapts between 56px (single line), 66px (2 lines), 82px (3 lines)
    readonly property real preferredHeight: {
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

    // ── Notification Layout (Mockup: Text Left, Circular Badge Right) ──
    Row {
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
            color: root.appMeta.bg
            border.width: 1
            border.color: Qt.rgba(root.appMeta.color.r, root.appMeta.color.g, root.appMeta.color.b, 0.45)

            Text {
                anchors.centerIn: parent
                text: root.appMeta.icon
                color: root.appMeta.color
                font.family: root.iconFontFamily
                font.pixelSize: 19
            }
        }
    }

    TapHandler {
        acceptedButtons: root.toggleButton
        onTapped: root.expansionToggleRequested()
    }
}
