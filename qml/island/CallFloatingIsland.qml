import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import IslandBackend
import "../common"

Rectangle {
    id: root

    property var targetCapsule: null
    property var headphonesFloatingIsland: null
    property var rootWindow: null
    property var userConfig: UserConfig
    property real islandTopMargin: 4
    property color accentColor: StyleTokens.accent

    property string callerName: "Discord Call"
    property string subtitle: "In chiamata..."
    property string avatarUrl: ""
    property bool hasCall: false
    property bool ongoing: false
    property int callSeconds: 0
    property bool isExpanded: false
    property string islandState: ""
    property int currentWs: 1

    property string iconFontFamily: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
    property string textFontFamily: userConfig ? userConfig.textFontFamily : "Sans Serif"
    property string heroFontFamily: userConfig ? userConfig.heroFontFamily : "Sans Serif"

    signal accepted()
    signal declined()
    signal callerClicked()

    readonly property real compactHeight: userConfig ? userConfig.islandHeight : 38
    readonly property real compactWidth: compactHeight
    readonly property real expandedWidth: 350
    readonly property real expandedHeight: 88

    width: isExpanded ? expandedWidth : compactWidth
    height: isExpanded ? expandedHeight : compactHeight
    radius: isExpanded ? 28 : compactHeight / 2

    anchors.left: (headphonesFloatingIsland && headphonesFloatingIsland.visible)
        ? headphonesFloatingIsland.right
        : (targetCapsule ? targetCapsule.right : undefined)
    anchors.leftMargin: 7
    anchors.top: targetCapsule ? targetCapsule.top : undefined

    readonly property bool shouldShow: hasCall && (islandState !== "discord_call" || isExpanded)

    visible: shouldShow && opacity > 0.01
    opacity: shouldShow ? (targetCapsule ? targetCapsule.opacity : 1.0) : 0.0
    scale: shouldShow ? 1.0 : 0.82

    clip: true
    color: "#000000"
    border.width: isExpanded ? 0 : 1
    border.color: isExpanded ? "transparent" : (hoverArea.containsMouse ? "#30d158" : "#1a2e1d")

    Behavior on width {
        NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
    }
    Behavior on height {
        NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
    }
    Behavior on radius {
        NumberAnimation { duration: 380; easing.type: Easing.OutQuint }
    }
    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    onHasCallChanged: {
        if (!hasCall) {
            isExpanded = false;
            callSeconds = 0;
        }
    }

    onCurrentWsChanged: {
        isExpanded = false;
    }

    Timer {
        id: callSecondsTimer
        interval: 1000
        repeat: true
        running: root.hasCall && root.ongoing
        onTriggered: root.callSeconds++
    }

    function formatTime(totalSeconds) {
        const m = Math.floor(totalSeconds / 60);
        const s = totalSeconds % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ==========================================
    // 1. STATO COMPATTO (Mini Circle con cornetta stile iPhone)
    // ==========================================
    Item {
        id: compactContainer
        anchors.fill: parent
        visible: !root.isExpanded
        opacity: root.isExpanded ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        // Pulsing outer halo when ringing or active
        Rectangle {
            anchors.centerIn: parent
            width: Math.round(root.compactHeight * 0.76)
            height: width
            radius: width / 2
            color: "transparent"
            border.color: "#30d158"
            border.width: 1.5
            opacity: root.ongoing ? 0.35 : 0.8

            SequentialAnimation on scale {
                running: root.hasCall && !root.isExpanded
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.18; duration: root.ongoing ? 1200 : 700; easing.type: Easing.OutQuad }
                NumberAnimation { from: 1.18; to: 1.0; duration: root.ongoing ? 1200 : 700; easing.type: Easing.InQuad }
            }
        }

        // Green Circular Icon Container
        ClippingRectangle {
            anchors.centerIn: parent
            width: Math.round(root.compactHeight * 0.64)
            height: width
            radius: width / 2
            color: "#30d158"
            antialiasing: true

            Text {
                anchors.centerIn: parent
                text: "\uf095"
                font.family: root.iconFontFamily
                font.pixelSize: 13
                color: "#ffffff"
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isExpanded = true
        }
    }

    // ==========================================
    // 2. STATO ESPANSO (Call Banner Card)
    // ==========================================
    Item {
        id: expandedContainer
        anchors.fill: parent
        visible: root.isExpanded
        opacity: root.isExpanded ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        // Background click collapses the card
        MouseArea {
            anchors.fill: parent
            onClicked: root.isExpanded = false
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            // Left: Avatar + Caller Information
            Row {
                id: callerInfoRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Item {
                    width: 42
                    height: 42
                    anchors.verticalCenter: parent.verticalCenter

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 21
                        color: root.ongoing ? "#23a55a" : "#5865F2"
                        antialiasing: true

                        Image {
                            id: callerAvatarImg
                            visible: root.avatarUrl !== ""
                            anchors.fill: parent
                            source: root.avatarUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            cache: false
                        }

                        Image {
                            visible: root.avatarUrl === "" || callerAvatarImg.status === Image.Error
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: "file:///usr/share/icons/hicolor/256x256/apps/discord.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    // Little green phone badge
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: -2
                        width: 14
                        height: 14
                        radius: 7
                        color: "#30d158"
                        border.color: "#000000"
                        border.width: 1.5

                        Text {
                            anchors.centerIn: parent
                            text: "\uf095"
                            font.family: root.iconFontFamily
                            font.pixelSize: 8
                            color: "#ffffff"
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: 130

                    Text {
                        text: root.callerName
                        color: "#ffffff"
                        font.family: root.textFontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: root.ongoing ? root.formatTime(root.callSeconds) : root.subtitle
                        color: root.ongoing ? "#30d158" : "#8e8e93"
                        font.family: root.heroFontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                // Click on caller info focuses Discord
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.callerClicked()
                }
            }

            // Center: Animated Audio Waveform Bars
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 24

                Row {
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            id: barRect
                            width: 3
                            property real barH: 8
                            height: barH
                            radius: 1.5
                            color: "#30d158"
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on barH {
                                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                            }

                            Timer {
                                interval: 100
                                running: root.hasCall && root.isExpanded
                                repeat: true
                                onTriggered: barRect.barH = 5 + Math.random() * 16
                            }
                        }
                    }
                }
            }

            // Right side: Action Buttons
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: root.ongoing ? 36 : 80
                height: 36

                // State A: Ongoing call -> End Call Button (Red phone)
                Rectangle {
                    visible: root.ongoing
                    anchors.centerIn: parent
                    width: 36
                    height: 36
                    radius: 18
                    color: endCallMouse.pressed ? "#d70015" : "#ff3b30"
                    scale: endCallMouse.containsMouse ? 1.08 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf095"
                        color: "#ffffff"
                        font.family: root.iconFontFamily
                        font.pixelSize: 15
                        rotation: 135
                    }

                    MouseArea {
                        id: endCallMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.isExpanded = false;
                            root.declined();
                        }
                    }
                }

                // State B: Incoming call -> Decline (Red) + Accept (Green)
                Row {
                    visible: !root.ongoing
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: declineIncomingMouse.pressed ? "#d70015" : "#ff3b30"
                        scale: declineIncomingMouse.containsMouse ? 1.06 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            id: declineIncomingMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.isExpanded = false;
                                root.declined();
                            }
                        }
                    }

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: acceptIncomingMouse.pressed ? "#248a3d" : "#34c759"
                        scale: acceptIncomingMouse.containsMouse ? 1.06 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf095"
                            color: "#ffffff"
                            font.family: root.iconFontFamily
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: acceptIncomingMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.accepted();
                            }
                        }
                    }
                }
            }
        }
    }

    // Auto-collasso quando il cursore esce dall'isola
    HoverHandler {
        id: islandHoverHandler
        onHoveredChanged: {
            if (!hovered) {
                if (root.isExpanded) autoCollapseTimer.restart();
                if (rootWindow && rootWindow.autoHideEnabled) {
                    rootWindow.autoHidePointerInside = false;
                    rootWindow.scheduleAutoHide();
                }
            } else {
                autoCollapseTimer.stop();
                if (rootWindow && rootWindow.autoHideEnabled) {
                    rootWindow.autoHidePointerInside = true;
                    rootWindow.showAutoHiddenIsland("edge");
                }
            }
        }
    }

    Timer {
        id: autoCollapseTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (root.isExpanded && !islandHoverHandler.hovered) {
                root.isExpanded = false;
            }
        }
    }

    onIsExpandedChanged: {
        autoCollapseTimer.stop();
    }
}
