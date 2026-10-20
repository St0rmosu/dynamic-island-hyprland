pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris

ColumnLayout {
    id: root

    property var activePlayer: null
    property bool isPreview: false
    property bool previewMediaPlaying: false

    readonly property bool hasMedia: (activePlayer !== null && (activePlayer.trackTitle || "").length > 0) || (isPreview && previewMediaPlaying)
    readonly property bool isPlaying: {
        if (isPreview && previewMediaPlaying && !activePlayer) return true;
        return activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing;
    }

    readonly property string title: {
        if (activePlayer && (activePlayer.trackTitle || "").length > 0) return activePlayer.trackTitle;
        if (isPreview && previewMediaPlaying) return "Nevermind";
        return "";
    }

    readonly property string artist: {
        if (activePlayer && activePlayer.trackArtists && activePlayer.trackArtists.length > 0) {
            return activePlayer.trackArtists.join(", ");
        }
        if (isPreview && previewMediaPlaying) return "Phoneboy, Justin Magnaye";
        return "";
    }

    readonly property string artUrl: {
        if (activePlayer && activePlayer.trackImageUrl && activePlayer.trackImageUrl.length > 0) {
            return activePlayer.trackImageUrl;
        }
        if (isPreview && previewMediaPlaying) {
            return "file:///home/lollo/Progetti/dynamic-island-hyprland/lock/assets/sample_album_art.png";
        }
        return "";
    }

    // Positions in seconds
    property real currentPosSec: 24
    property real totalLengthSec: 210

    function parseMprisSec(val) {
        let num = Number(val);
        if (isNaN(num) || num <= 0) return 0;
        if (num < 10000) return num; // seconds
        if (num < 100000000) return num / 1000; // milliseconds
        return num / 1000000; // microseconds
    }

    function formatTime(seconds) {
        let s = Math.floor(Math.max(0, seconds));
        let m = Math.floor(s / 60);
        let remS = s % 60;
        return m + ":" + (remS < 10 ? "0" : "") + remS;
    }

    Timer {
        interval: 1000
        running: root.isPlaying
        repeat: true
        onTriggered: {
            if (root.activePlayer) {
                root.currentPosSec = root.parseMprisSec(root.activePlayer.position);
                let len = root.parseMprisSec(root.activePlayer.length);
                if (len <= 0 && root.activePlayer.metadata && root.activePlayer.metadata["mpris:length"]) {
                    len = root.parseMprisSec(root.activePlayer.metadata["mpris:length"]);
                }
                if (len > 0) root.totalLengthSec = len;
            } else if (root.isPreview && root.previewMediaPlaying) {
                root.currentPosSec = (root.currentPosSec + 1) % (root.totalLengthSec || 210);
            }
        }
    }

    spacing: 18
    Layout.alignment: Qt.AlignHCenter

    // 1. Hero Album Art Card (Exact iPadOS 440x440 floating card)
    Rectangle {
        id: albumArtCard
        Layout.alignment: Qt.AlignHCenter
        width: 440
        height: 440
        radius: 26
        color: AppleTokens.surfaceTile1
        border.width: 1.5
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.32)
        clip: true

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.58)
            shadowBlur: 0.65
            shadowVerticalOffset: 10
        }

        Image {
            id: artImage
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            asynchronous: true
        }

        // Fallback placeholder when no art
        Rectangle {
            anchors.fill: parent
            visible: artImage.status !== Image.Ready
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#3a2b3c" }
                GradientStop { position: 1.0; color: "#1a1622" }
            }

            Text {
                anchors.centerIn: parent
                text: "󰎈"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 84
                color: Qt.rgba(1.0, 1.0, 1.0, 0.35)
            }
        }
    }

    // 2. iPadOS Frosted Glass Media Control Card (Exact layout with centered typography)
    Rectangle {
        id: mediaPillCard
        Layout.alignment: Qt.AlignHCenter
        width: 480
        height: 124
        radius: 22
        color: Qt.rgba(0.22, 0.19, 0.23, 0.58)
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.18)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.45)
            shadowBlur: 0.55
            shadowVerticalOffset: 5
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 4

            // Top Header: Centered Track Title + Explicit tag & Right-aligned Equalizer
            Item {
                Layout.fillWidth: true
                height: 22

                // Centered Title & Explicit Badge
                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: root.title
                        font.family: AppleTokens.textFont
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: AppleTokens.bodyOnDark
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    // Explicit badge [E]
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        radius: 2.5
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.25)
                        visible: root.title.length > 0

                        Text {
                            anchors.centerIn: parent
                            text: "E"
                            font.family: AppleTokens.textFont
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: AppleTokens.bodyOnDark
                        }
                    }
                }

                // Animated Equalizer Sound Waves (iPadOS Live Activity style in top right)
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2.5

                    Repeater {
                        model: [0, 1, 2, 3]

                        Rectangle {
                            id: eqBar
                            required property int index
                            width: 3
                            height: 6
                            radius: 1.5
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
                            anchors.bottom: parent.bottom

                            SequentialAnimation on height {
                                running: root.isPlaying
                                loops: Animation.Infinite

                                NumberAnimation {
                                    from: 4
                                    to: (eqBar.index % 2 === 0) ? 14 : 9
                                    duration: 280 + eqBar.index * 70
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    from: (eqBar.index % 2 === 0) ? 14 : 9
                                    to: (eqBar.index === 1) ? 15 : 5
                                    duration: 320 + eqBar.index * 60
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    from: (eqBar.index === 1) ? 15 : 5
                                    to: 4
                                    duration: 260
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }
            }

            // Centered Artist Name
            Text {
                text: root.artist
                font.family: AppleTokens.textFont
                font.pixelSize: 13
                font.weight: Font.Normal
                color: Qt.rgba(1.0, 1.0, 1.0, 0.68)
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            // Scrubber Bar Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Current time elapsed
                Text {
                    text: root.formatTime(root.currentPosSec)
                    font.family: AppleTokens.textFont
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                }

                // Slider Track
                Item {
                    id: scrubberTrack
                    Layout.fillWidth: true
                    height: 12

                    readonly property real progress: root.totalLengthSec > 0 ? Math.max(0, Math.min(1.0, root.currentPosSec / root.totalLengthSec)) : 0

                    // Track Background
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 3.5
                        radius: 1.75
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.22)

                        // Filled bar
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(4, parent.width * scrubberTrack.progress)
                            radius: 1.75
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (root.totalLengthSec > 0) {
                                let ratio = Math.max(0, Math.min(1, mouse.x / width));
                                let newSec = ratio * root.totalLengthSec;
                                root.currentPosSec = newSec;
                                if (root.activePlayer && root.activePlayer.canSeek) {
                                    root.activePlayer.position = newSec;
                                }
                            }
                        }
                    }
                }

                // Time remaining (-M:SS)
                Text {
                    text: "-" + root.formatTime(Math.max(0, root.totalLengthSec - root.currentPosSec))
                    font.family: AppleTokens.textFont
                    font.pixelSize: 11
                    font.weight: Font.Normal
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                }
            }

            // Controls Row (Prev, Play/Pause, Next + AirPlay)
            Item {
                Layout.fillWidth: true
                height: 32

                // Centered Playback Controls
                Row {
                    anchors.centerIn: parent
                    spacing: 32

                    // Prev (⏮)
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰒮"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: prevMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                        scale: prevMouse.pressed ? AppleTokens.pressScale : 1.0

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer && root.activePlayer.canGoPrevious) {
                                    root.activePlayer.previous();
                                }
                            }
                        }
                    }

                    // Play/Pause (⏸ / ▶)
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isPlaying ? "󰏤" : "󰐊"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 26
                        color: playMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                        scale: playMouse.pressed ? AppleTokens.pressScale : 1.0

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer && root.activePlayer.canControl) {
                                    root.activePlayer.playPause();
                                } else if (root.isPreview) {
                                    root.previewMediaPlaying = !root.previewMediaPlaying;
                                }
                            }
                        }
                    }

                    // Next (⏭)
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰒭"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: nextMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                        scale: nextMouse.pressed ? AppleTokens.pressScale : 1.0

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer && root.activePlayer.canGoNext) {
                                    root.activePlayer.next();
                                }
                            }
                        }
                    }
                }

                // AirPlay / Speaker Output Icon (Right Corner)
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰡀"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.75)
                }
            }
        }
    }
}
