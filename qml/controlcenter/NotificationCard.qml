import QtQuick
import QtQuick.Shapes
import IslandBackend

Rectangle {
    id: cardRoot

    signal notificationDismissed(int index)
    signal clearAllRequested()

    property var notificationModel: null
    property color accentColor: StyleTokens.accent
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property string textFontFamily: "Google Sans Flex"
    property string heroFontFamily: "Google Sans Flex"
    property bool expanded: true

    readonly property int itemCount: notificationModel ? notificationModel.count : 0
    readonly property bool hasNotifications: itemCount > 0

    function formatTimestamp(ts) {
        if (!ts) return "";
        try {
            let d = (ts instanceof Date) ? ts : new Date(ts);
            if (!isNaN(d.getTime())) {
                const hh = String(d.getHours()).padStart(2, '0');
                const mm = String(d.getMinutes()).padStart(2, '0');
                return hh + ":" + mm;
            }
        } catch(e) {}
        return String(ts);
    }

    readonly property real headerHeight: 38
    readonly property real itemHeight: 52
    readonly property real itemGap: 6
    readonly property int maxVisibleItems: 3
    readonly property real visibleListHeight: hasNotifications && expanded
        ? (Math.min(maxVisibleItems, itemCount) * itemHeight + Math.max(0, Math.min(maxVisibleItems, itemCount) - 1) * itemGap)
        : 0

    readonly property real targetHeight: {
        if (!hasNotifications) return 64;
        if (!expanded) return 64;
        return headerHeight + visibleListHeight + 10;
    }

    height: targetHeight
    radius: 20
    color: StyleTokens.clearBlack
    clip: true

    Behavior on height {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    MatteSurface {
        anchors.fill: parent
        radius: parent.radius
        hovered: headerArea.containsMouse
    }

    // --- Header Section ---
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: cardRoot.headerHeight

        MouseArea {
            id: headerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: cardRoot.hasNotifications ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (cardRoot.hasNotifications) {
                    cardRoot.expanded = !cardRoot.expanded;
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Bell icon
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "" // FontAwesome bell
                color: cardRoot.hasNotifications ? cardRoot.accentColor : StyleTokens.textMuted
                font.pixelSize: 13
                font.family: cardRoot.iconFontFamily
            }

            // Title
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifiche"
                color: cardRoot.hasNotifications ? StyleTokens.textPrimary : StyleTokens.textSecondary
                font.pixelSize: 13
                font.family: cardRoot.textFontFamily
                font.weight: Font.DemiBold
            }

            // Count badge
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: cardRoot.hasNotifications
                height: 18
                width: countText.implicitWidth + 12
                radius: 9
                color: Qt.rgba(cardRoot.accentColor.r, cardRoot.accentColor.g, cardRoot.accentColor.b, 0.22)
                border.width: 1
                border.color: Qt.rgba(cardRoot.accentColor.r, cardRoot.accentColor.g, cardRoot.accentColor.b, 0.45)

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: cardRoot.itemCount
                    color: cardRoot.accentColor
                    font.pixelSize: 10
                    font.family: cardRoot.textFontFamily
                    font.weight: Font.Bold
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // Clear All Trash Button (visible only when notifications exist)
            Rectangle {
                id: clearAllBtn
                visible: cardRoot.hasNotifications
                width: 26
                height: 26
                radius: 13
                color: clearMouse.pressed ? "#55ff453a" : (clearMouse.containsMouse ? "#26ff453a" : StyleTokens.transparent)
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "" // Trash can
                    font.pixelSize: 12
                    font.family: cardRoot.iconFontFamily
                    color: clearMouse.containsMouse ? "#ff453a" : StyleTokens.textDim
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cardRoot.clearAllRequested()
                }
            }

            // Chevron toggle (expand/collapse)
            Rectangle {
                id: chevronBtn
                visible: cardRoot.hasNotifications
                width: 24
                height: 24
                radius: 12
                color: StyleTokens.transparent
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: chevronGlyph
                    anchors.centerIn: parent
                    text: "" // Chevron down
                    font.pixelSize: 11
                    font.family: cardRoot.iconFontFamily
                    color: headerArea.containsMouse ? StyleTokens.textPrimary : StyleTokens.textDim
                    rotation: cardRoot.expanded ? 0 : -90

                    Behavior on rotation {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    // --- Empty State ---
    Item {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: !cardRoot.hasNotifications

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "" // Checkmark
                font.pixelSize: 11
                font.family: cardRoot.iconFontFamily
                color: "#5f626e"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Nessuna nuova notifica"
                font.pixelSize: 11
                font.family: cardRoot.textFontFamily
                font.weight: Font.Medium
                color: "#6f7280"
            }
        }
    }

    // --- Collapsed Preview Snippet (when notifications exist but collapsed) ---
    Item {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: cardRoot.hasNotifications && !cardRoot.expanded

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                width: parent.width - 60
                text: {
                    if (cardRoot.itemCount <= 0 || !cardRoot.notificationModel) return "";
                    const first = cardRoot.notificationModel.get(0);
                    return (first.appName ? (first.appName + ": ") : "") + (first.summary || "");
                }
                font.pixelSize: 11
                font.family: cardRoot.textFontFamily
                color: StyleTokens.textSecondary
                elide: Text.ElideRight
            }

            Text {
                visible: cardRoot.itemCount > 1
                text: "+" + (cardRoot.itemCount - 1)
                font.pixelSize: 10
                font.family: cardRoot.textFontFamily
                font.weight: Font.Bold
                color: cardRoot.accentColor
            }
        }
    }

    // --- Expanded Notifications ListView ---
    ListView {
        id: notifListView
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 8
        visible: cardRoot.hasNotifications && cardRoot.expanded
        clip: true
        interactive: cardRoot.itemCount > cardRoot.maxVisibleItems
        boundsBehavior: Flickable.StopAtBounds
        spacing: cardRoot.itemGap
        model: cardRoot.notificationModel

        remove: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: 160
                    easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    property: "scale"
                    to: 0.90
                    duration: 180
                    easing.type: Easing.InOutCubic
                }
            }
        }

        removeDisplaced: Transition {
            NumberAnimation {
                property: "y"
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        delegate: Rectangle {
            id: itemDelegate
            width: notifListView.width
            height: cardRoot.itemHeight
            radius: 14
            color: itemMouse.containsMouse ? "#1affffff" : "#0dffffff"
            border.width: 1
            border.color: itemMouse.containsMouse ? "#26ffffff" : "#10ffffff"

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            // App initial / glyph badge
            Rectangle {
                id: iconBadge
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 14
                color: Qt.rgba(cardRoot.accentColor.r, cardRoot.accentColor.g, cardRoot.accentColor.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (model.appName && model.appName.length > 0)
                            return model.appName.charAt(0).toUpperCase();
                        return "";
                    }
                    font.pixelSize: 11
                    font.family: cardRoot.textFontFamily
                    font.weight: Font.Bold
                    color: cardRoot.accentColor
                }
            }

            // Notification text content
            Column {
                anchors.left: iconBadge.right
                anchors.leftMargin: 10
                anchors.right: dismissBtn.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Row {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: (model.appName || "App").toUpperCase()
                        font.pixelSize: 9
                        font.family: cardRoot.textFontFamily
                        font.weight: Font.Bold
                        font.letterSpacing: 0.3
                        color: cardRoot.accentColor
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "•"
                        font.pixelSize: 9
                        color: "#4e515d"
                    }

                    Text {
                        text: cardRoot.formatTimestamp(model.timestamp)
                        font.pixelSize: 9
                        font.family: cardRoot.textFontFamily
                        color: "#6c6f7c"
                    }
                }

                Text {
                    width: parent.width
                    text: model.summary || "Notifica"
                    font.pixelSize: 12
                    font.family: cardRoot.textFontFamily
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    elide: Text.ElideRight
                }

                Text {
                    visible: model.body !== "" && model.body !== model.summary
                    width: parent.width
                    text: model.body || ""
                    font.pixelSize: 10
                    font.family: cardRoot.textFontFamily
                    color: "#9da0ad"
                    elide: Text.ElideRight
                }
            }

            // Quick Dismiss Trash Button
            Rectangle {
                id: dismissBtn
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                radius: 11
                color: dismissMouse.pressed ? "#66ff453a" : (dismissMouse.containsMouse ? "#33ff453a" : StyleTokens.transparent)

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.pixelSize: 11
                    font.family: cardRoot.iconFontFamily
                    color: dismissMouse.containsMouse ? "#ff453a" : "#727582"
                }

                MouseArea {
                    id: dismissMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cardRoot.notificationDismissed(index)
                }
            }

            MouseArea {
                id: itemMouse
                anchors.left: parent.left
                anchors.right: dismissBtn.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cardRoot.notificationDismissed(index)
            }
        }
    }
}
