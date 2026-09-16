import QtQuick
import IslandBackend
import Quickshell.Widgets

Item {
    id: root

    readonly property var userConfig: UserConfig

    property string callerName: "Discord Call"
    property string subtitle: "Chiamata in arrivo..."
    property string avatarUrl: ""
    property bool ongoing: false
    property int callSeconds: 0
    property bool showCondition: true
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property string iconFontFamily: userConfig.iconFontFamily

    signal accepted()
    signal declined()

    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: callTimer
        interval: 1000
        repeat: true
        running: root.showCondition && root.ongoing
        onTriggered: root.callSeconds++
    }

    function formatTime(totalSeconds) {
        const m = Math.floor(totalSeconds / 60);
        const s = totalSeconds % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        // Left: Avatar + Caller Information
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Item {
                width: 38
                height: 38
                anchors.verticalCenter: parent.verticalCenter

                // Pulsing ring when incoming
                Rectangle {
                    visible: !root.ongoing
                    anchors.centerIn: parent
                    width: parent.width + 6
                    height: parent.height + 6
                    radius: width / 2
                    color: "transparent"
                    border.color: "#5865F2"
                    border.width: 1.5
                    opacity: 0.7

                    SequentialAnimation on scale {
                        running: !root.ongoing && root.showCondition
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.15; duration: 800; easing.type: Easing.OutQuad }
                        NumberAnimation { from: 1.15; to: 1.0; duration: 800; easing.type: Easing.InQuad }
                    }
                }

                // Circular Discord Avatar
                ClippingRectangle {
                    anchors.fill: parent
                    radius: 19
                    color: root.ongoing ? "#23a55a" : "#5865F2"
                    antialiasing: true

                    Image {
                        id: callerAvatar
                        visible: !root.ongoing && root.avatarUrl !== ""
                        anchors.fill: parent
                        source: root.avatarUrl
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        cache: false
                    }

                    Image {
                        id: defaultDiscordIcon
                        visible: !root.ongoing && (root.avatarUrl === "" || callerAvatar.status === Image.Error)
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: "file:///usr/share/icons/hicolor/256x256/apps/discord.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Text {
                        visible: root.ongoing
                        anchors.centerIn: parent
                        text: "\uf095"
                        color: "#ffffff"
                        font.family: root.iconFontFamily
                        font.pixelSize: 18
                    }
                }
            }

            // Name + Status / Timer
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: root.callerName
                    color: "#ffffff"
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.2
                    elide: Text.ElideRight
                    width: root.ongoing ? 130 : 160
                }

                Text {
                    text: root.ongoing ? root.formatTime(root.callSeconds) : root.subtitle
                    color: root.ongoing ? "#30d158" : "#8e8e93"
                    font.family: root.heroFontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }

        // Right side: Incoming Call Action Buttons (Decline & Accept)
        Row {
            visible: !root.ongoing
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Decline Button (Red)
            Rectangle {
                id: declineBtn
                width: 36
                height: 36
                radius: 18
                color: declineMouse.pressed ? "#d70015" : "#ff3b30"
                scale: declineMouse.containsMouse ? 1.06 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "#ffffff"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: declineMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.declined()
                }
            }

            // Accept Button (Green)
            Rectangle {
                id: acceptBtn
                width: 36
                height: 36
                radius: 18
                color: acceptMouse.pressed ? "#248a3d" : "#34c759"
                scale: acceptMouse.containsMouse ? 1.06 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf095" // Phone pickup
                    color: "#ffffff"
                    font.family: root.iconFontFamily
                    font.pixelSize: 15
                }

                MouseArea {
                    id: acceptMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.accepted()
                }
            }
        }

        // Right side when ongoing: Animated Audio Waveform + Hangup
        Row {
            visible: root.ongoing
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            // Waveform bars
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: 5
                    delegate: Rectangle {
                        width: 3
                        height: 6 + Math.sin((index * 1.2) + (Date.now() / 150)) * 6
                        radius: 1.5
                        color: "#30d158"
                        anchors.verticalCenter: parent.verticalCenter

                        Timer {
                            interval: 50
                            running: root.ongoing && root.showCondition
                            repeat: true
                            onTriggered: parent.height = 4 + Math.random() * 14
                        }
                    }
                }
            }

            // End Call Button
            Rectangle {
                id: endBtn
                width: 32
                height: 32
                radius: 16
                color: endMouse.pressed ? "#d70015" : "#ff3b30"
                scale: endMouse.containsMouse ? 1.06 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf095"
                    color: "#ffffff"
                    font.family: root.iconFontFamily
                    font.pixelSize: 13
                    rotation: 135
                }

                MouseArea {
                    id: endMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.declined()
                }
            }
        }
    }
}
