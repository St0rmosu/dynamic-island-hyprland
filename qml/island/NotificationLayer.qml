import IslandBackend
import QtQuick
import QtQuick.Layouts

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
    property color surfaceColor: Qt.rgba(0, 0, 0, 0.94)
    property color outlineColor: Qt.rgba(root.appMeta.color.r, root.appMeta.color.g, root.appMeta.color.b, 0.28)
    property color irisBlue: "#95acd0"
    property color irisPurple: "#bb95d0"
    property color irisGreen: "#58b654"
    property color irisYellow: "#b7a558"
    property color irisRed: "#d0bf92"
    // Sileo liquid connector properties
    property real neckTargetWidth: 140
    // Resolved Clean Display Names
    readonly property string displayAppName: {
        if (appName && appName !== "" && appName !== "Notification" && appName !== "notify-send")
            return appName;

        return "";
    }
    readonly property string senderName: {
        const isWhatsapp = (appName + " " + summary + " " + body).toLowerCase().indexOf("whatsapp") !== -1;
        if (isWhatsapp && summary !== "" && summary.toLowerCase() !== "whatsapp")
            return summary;

        if (summary !== "" && body !== "")
            return summary;

        if (displayAppName !== "")
            return displayAppName;

        if (summary !== "")
            return summary;

        return "Notifica";
    }
    readonly property string messageContent: {
        if (body !== "" && summary !== "" && body !== summary)
            return body;

        if (body !== "")
            return body;

        if (summary !== "" && summary !== senderName)
            return summary;

        return "";
    }
    // App detection for icon and color tint
    readonly property var appMeta: {
        const s = (appName + " " + summary + " " + body).toLowerCase();
        if (s.indexOf("schermo") !== -1 || s.indexOf("screen") !== -1 || s.indexOf("trasmissione") !== -1 || s.indexOf("registrazione") !== -1 || s.indexOf("recording") !== -1) {
            const scColor = (root.iconColor && root.iconColor != "#f4f5f7") ? root.iconColor : root.accentColor;
            return {
                "icon": (root.iconText !== "" && !root.isImageIcon) ? root.iconText : "\uf0379",
                "color": scColor,
                "bg": Qt.rgba(scColor.r, scColor.g, scColor.b, 0.18),
                "badgeName": "Schermo"
            };
        }
        if (s.indexOf("whatsapp") !== -1)
            return {
            "icon": "\uf232",
            "color": "#25D366",
            "bg": Qt.rgba(37 / 255, 211 / 255, 102 / 255, 0.18),
            "badgeName": "WhatsApp"
        };

        if (s.indexOf("discord") !== -1 || s.indexOf("vesktop") !== -1 || s.indexOf("armcord") !== -1)
            return {
            "icon": "\uf392",
            "color": "#5865F2",
            "bg": Qt.rgba(88 / 255, 101 / 255, 242 / 255, 0.18),
            "badgeName": "Discord"
        };

        if (s.indexOf("telegram") !== -1)
            return {
            "icon": "\uf2c6",
            "color": "#229ED9",
            "bg": Qt.rgba(34 / 255, 158 / 255, 217 / 255, 0.18),
            "badgeName": "Telegram"
        };

        if (s.indexOf("spotify") !== -1)
            return {
            "icon": "\uf1bc",
            "color": "#1DB954",
            "bg": Qt.rgba(29 / 255, 185 / 255, 84 / 255, 0.18),
            "badgeName": "Spotify"
        };

        if (s.indexOf("slack") !== -1)
            return {
            "icon": "\uf198",
            "color": "#e01e5a",
            "bg": Qt.rgba(224 / 255, 30 / 255, 90 / 255, 0.18),
            "badgeName": "Slack"
        };

        if (s.indexOf("signal") !== -1)
            return {
            "icon": "\uf075",
            "color": "#3A76F0",
            "bg": Qt.rgba(58 / 255, 118 / 255, 240 / 255, 0.18),
            "badgeName": "Signal"
        };

        if (s.indexOf("thunderbird") !== -1 || s.indexOf("mail") !== -1)
            return {
            "icon": "\uf0e0",
            "color": "#0060df",
            "bg": Qt.rgba(0 / 255, 96 / 255, 223 / 255, 0.18),
            "badgeName": "Mail"
        };

        if (s.indexOf("satty") !== -1 || s.indexOf("screenshot") !== -1)
            return {
            "icon": "\uf030",
            "color": "#ff9f0a",
            "bg": Qt.rgba(255 / 255, 159 / 255, 10 / 255, 0.18),
            "badgeName": "Screenshot"
        };

        if (s.indexOf("wifi") !== -1 || s.indexOf("rete") !== -1)
            return {
            "icon": "\uf1eb",
            "color": "#30d158",
            "bg": Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.18),
            "badgeName": "Wi-Fi"
        };

        if (s.indexOf("bluetooth") !== -1)
            return {
            "icon": "\uf294",
            "color": "#0a84ff",
            "bg": Qt.rgba(10 / 255, 132 / 255, 255 / 255, 0.18),
            "badgeName": "Bluetooth"
        };

        const fallbackColor = (root.iconColor && root.iconColor != "#f4f5f7") ? root.iconColor : root.accentColor;
        return {
            "icon": (root.iconText !== "" && root.iconText !== "" && root.iconText !== "\uf0f3" && !root.isImageIcon) ? root.iconText : "\uf0f3",
            "color": fallbackColor,
            "bg": Qt.rgba(fallbackColor.r, fallbackColor.g, fallbackColor.b, 0.16),
            "badgeName": root.displayAppName !== "" ? root.displayAppName : "Notifica"
        };
    }
    readonly property bool isImageIcon: {
        const raw = String(root.iconText || "").trim();
        return raw.startsWith("/") || raw.startsWith("file://") || raw.endsWith(".png") || raw.endsWith(".jpg") || raw.endsWith(".jpeg") || raw.endsWith(".svg") || raw.endsWith(".webp");
    }
    readonly property string resolvedImageSource: {
        if (!isImageIcon)
            return "";

        const raw = String(root.iconText || "").trim();
        return raw.startsWith("file://") ? raw : ("file://" + raw);
    }
    readonly property bool hasDistinctBadge: {
        const badge = root.appMeta.badgeName.toLowerCase();
        const sName = root.senderName.toLowerCase();
        return badge !== "" && sName.indexOf(badge) === -1;
    }
    readonly property bool isLongMessage: bodyMetrics.advanceWidth > 260
    readonly property real preferredWidth: 420
    readonly property real preferredHeight: isLongMessage ? 84 : 74

    signal expansionToggleRequested()
    signal openSattyRequested(string path)
    signal openEditorRequested(string path)
    signal dismissRequested()
    signal imageSizeReady(real w, real h)

    anchors.fill: parent
    onShowConditionChanged: {
        if (showCondition) {
            notifProgress.width = notifProgressTrack.width;
            notifProgressAnim.restart();
        } else {
            notifProgressAnim.stop();
        }
    }

    // Dynamic measurements
    TextMetrics {
        id: bodyMetrics

        font.family: root.textFontFamily
        font.pixelSize: 12
        text: root.messageContent
    }

    MouseArea {
        id: cardHoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    SileoBridgeConnector {
        id: bridge

        anchors.fill: parent
        showCondition: root.showCondition
        neckTargetWidth: root.neckTargetWidth
        cardTargetW: root.preferredWidth
        cardTargetH: root.preferredHeight
        shoulderY: 48
        surfaceColor: root.surfaceColor
        outlineColor: root.outlineColor
        accentColor: root.appMeta.color

        // Content Area inside the Sileo Dropdown Card
        Item {
            anchors.fill: parent

            // Main Notification Row
            Row {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                anchors.topMargin: 10
                anchors.bottomMargin: 12
                spacing: 12

                // 1. App Icon Squircle (Left)
                Rectangle {
                    id: iconBadge

                    width: 40
                    height: 40
                    radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.isImageIcon ? Qt.rgba(255, 255, 255, 0.08) : root.appMeta.bg
                    border.width: 1
                    border.color: root.isImageIcon ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(root.appMeta.color.r, root.appMeta.color.g, root.appMeta.color.b, 0.45)
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
                        font.pixelSize: 18
                        antialiasing: true
                    }

                }

                // 2. Text Column (Center)
                Item {
                    width: parent.width - iconBadge.width - dismissBtn.width - parent.spacing * 2
                    height: parent.height

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        // Header line: Sender Name + optional App badge + "adesso"
                        Row {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: root.senderName
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.family: root.textFontFamily
                                font.letterSpacing: -0.15
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                Layout.maximumWidth: parent.width - (appBadgeRect.visible ? appBadgeRect.width + 6 : 0) - timeLabel.width - 12
                            }

                            // App Badge Pill (e.g. Telegram / WhatsApp)
                            Rectangle {
                                id: appBadgeRect

                                visible: root.hasDistinctBadge
                                anchors.verticalCenter: parent.verticalCenter
                                height: 16
                                width: appBadgeText.implicitWidth + 8
                                radius: 4
                                color: Qt.rgba(root.appMeta.color.r, root.appMeta.color.g, root.appMeta.color.b, 0.16)
                                border.width: 1
                                border.color: Qt.rgba(root.appMeta.color.r, root.appMeta.color.g, root.appMeta.color.b, 0.35)

                                Text {
                                    id: appBadgeText

                                    anchors.centerIn: parent
                                    text: root.appMeta.badgeName
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    font.family: root.textFontFamily
                                    color: root.appMeta.color
                                }

                            }

                            Text {
                                id: timeLabel

                                anchors.verticalCenter: parent.verticalCenter
                                text: "• adesso"
                                color: "#64748b"
                                font.pixelSize: 10
                                font.family: root.textFontFamily
                            }

                        }

                        // Body line: Message Text
                        Text {
                            width: parent.width
                            visible: root.messageContent !== ""
                            text: root.messageContent
                            color: "#cbd5e1"
                            font.pixelSize: 12
                            font.family: root.textFontFamily
                            wrapMode: Text.WordWrap
                            maximumLineCount: root.isLongMessage ? 2 : 1
                            elide: Text.ElideRight
                            lineHeight: 1.15
                        }

                    }

                }

                // 3. Dismiss Button (Right)
                Rectangle {
                    id: dismissBtn

                    width: 24
                    height: 24
                    radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: dismissMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1
                    border.color: dismissMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.28) : Qt.rgba(255, 255, 255, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: dismissMouse.containsMouse ? "#ffffff" : "#94a3b8"
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

            // Click anywhere to dismiss or view
            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissRequested()
            }

            // ── Auto-Dismiss Progress Bar ──
            Rectangle {
                id: notifProgressTrack

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                height: 2
                radius: 1
                width: Math.max(0, root.preferredWidth - 36)
                color: Qt.rgba(255, 255, 255, 0.06)

                Rectangle {
                    id: notifProgress

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: 1
                    color: root.appMeta.color
                    width: parent.width

                    PropertyAnimation {
                        id: notifProgressAnim

                        target: notifProgress
                        property: "width"
                        from: notifProgressTrack.width
                        to: 0
                        duration: 4200
                        easing.type: Easing.Linear
                        paused: cardHoverArea.containsMouse
                    }

                }

            }

        }

    }

}
