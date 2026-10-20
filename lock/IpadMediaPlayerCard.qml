pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

ColumnLayout {
    id: root

    property var activePlayer: null
    property bool isPreview: false
    property bool previewMediaPlaying: false
    property bool showMediaButtons: true

    Process {
        id: mprisCmd
        running: false
    }

    function cmdPlayPause() {
        if (root.activePlayer) {
            if (typeof root.activePlayer.togglePlaying === "function") {
                root.activePlayer.togglePlaying();
            } else if (typeof root.activePlayer.playPause === "function") {
                root.activePlayer.playPause();
            }
        }
        if (root.isPreview) {
            root.previewMediaPlaying = !root.previewMediaPlaying;
        }
        mprisCmd.command = ["playerctl", "play-pause"];
        mprisCmd.running = true;
    }

    function cmdNext() {
        if (root.activePlayer && typeof root.activePlayer.next === "function") {
            root.activePlayer.next();
        }
        mprisCmd.command = ["playerctl", "next"];
        mprisCmd.running = true;
    }

    function cmdPrevious() {
        if (root.activePlayer && typeof root.activePlayer.previous === "function") {
            root.activePlayer.previous();
        }
        mprisCmd.command = ["playerctl", "previous"];
        mprisCmd.running = true;
    }

    function cmdSeek(newSec) {
        root.currentPosSec = newSec;
        if (root.activePlayer && root.activePlayer.canSeek) {
            root.activePlayer.position = newSec;
        }
        mprisCmd.command = ["playerctl", "position", String(Math.floor(newSec))];
        mprisCmd.running = true;
    }

    readonly property bool hasMedia: (activePlayer !== null && (activePlayer.trackTitle || "").length > 0) || (isPreview && previewMediaPlaying)
    readonly property bool isPlaying: {
        if (isPreview && previewMediaPlaying && !activePlayer) return true;
        return activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing;
    }

    property string lastValidTitle: ""
    property string lastValidArtist: ""

    readonly property string title: {
        let t = "";
        if (activePlayer && (activePlayer.trackTitle || activePlayer.title || "").length > 0) {
            t = activePlayer.trackTitle || activePlayer.title;
        } else if (isPreview && previewMediaPlaying) {
            t = "Nevermind";
        }
        if (t !== "") {
            root.lastValidTitle = t;
            return t;
        }
        return root.lastValidTitle;
    }

    readonly property string artist: {
        let a = "";
        if (activePlayer) {
            let art = activePlayer.trackArtists !== undefined ? activePlayer.trackArtists : activePlayer.artist;
            if (!art && activePlayer.metadata) art = activePlayer.metadata["xesam:artist"];
            if (art) a = Array.isArray(art) ? art.join(", ") : String(art);
        } else if (isPreview && previewMediaPlaying) {
            a = "Phoneboy, Justin Magnaye";
        }
        if (a !== "") {
            root.lastValidArtist = a;
            return a;
        }
        return root.lastValidArtist;
    }

    property string artUrl: {
        if (activePlayer) {
            let url = activePlayer.trackArtUrl || activePlayer.artUrl;
            if (!url && activePlayer.metadata) url = activePlayer.metadata["mpris:artUrl"];
            if (url && String(url).length > 0) return String(url);
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

    spacing: 16
    Layout.alignment: Qt.AlignHCenter

    // 1. Hero Album Art Card (Apple squircle rounded floating card)
    Item {
        id: albumArtCard
        Layout.alignment: Qt.AlignHCenter
        width: 500
        height: 500

        // Soft signature Apple drop-shadow
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.58)
            shadowBlur: 0.68
            shadowVerticalOffset: 12
        }

        // Masked content wrapper (ensures images strictly respect radius 28)
        Item {
            id: cardContent
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: roundedMask
            }

            Item {
                id: roundedMask
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: 28
                    color: "black"
                }
            }

            // Fallback placeholder when no art
            Rectangle {
                anchors.fill: parent
                visible: opacity > 0.001
                opacity: (artImage.status === Image.Ready || prevArtImage.status === Image.Ready) ? 0.0 : 1.0
                Behavior on opacity {
                    NumberAnimation { duration: 340; easing.type: Easing.InOutQuad }
                }
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#3a2b3c" }
                    GradientStop { position: 1.0; color: "#1a1622" }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 96
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.35)
                }
            }

            // Underlying previous artwork for seamless crossfade between tracks
            Image {
                id: prevArtImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                visible: opacity > 0.001 && source !== ""
                opacity: status === Image.Ready ? 1.0 : 0.0
            }

            // Active track artwork fading in smoothly over previous artwork
            Image {
                id: artImage
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: opacity > 0.001
                opacity: status === Image.Ready ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 360; easing.type: Easing.InOutQuad }
                }

                onStatusChanged: {
                    if (status === Image.Ready) {
                        if (prevArtImage.source === "" || prevArtImage.status !== Image.Ready) {
                            prevArtImage.source = artImage.source;
                        } else {
                            prevArtTimer.restart();
                        }
                    }
                }
            }

            Timer {
                id: prevArtTimer
                interval: 380
                repeat: false
                onTriggered: {
                    if (artImage.status === Image.Ready) {
                        prevArtImage.source = artImage.source;
                    }
                }
            }
        }

        // Apple signature hairline border matching radius 28
        Rectangle {
            anchors.fill: parent
            radius: 28
            color: "transparent"
            border.width: 1.5
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.28)
        }
    }

    // 2. iPadOS Frosted Glass Media Control Card (Exact layout with centered typography)
    Rectangle {
        id: mediaPillCard
        Layout.alignment: Qt.AlignHCenter
        width: 500
        height: root.showMediaButtons ? 144 : 96
        radius: 26
        color: Qt.rgba(0.22, 0.19, 0.23, 0.58)
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.18)

        Behavior on height {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.48)
            shadowBlur: 0.58
            shadowVerticalOffset: 6
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 15
            anchors.bottomMargin: 15
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 6

            // Top Header: Centered Track Title + Explicit tag & Right-aligned Equalizer
            Item {
                Layout.fillWidth: true
                height: 24

                // Centered Title & Explicit Badge
                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: root.title
                        font.family: AppleTokens.textFont
                        font.pixelSize: 17
                        font.weight: Font.Bold
                        color: AppleTokens.bodyOnDark
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    // Explicit badge [E]
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 3.5
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.25)
                        visible: root.title.length > 0

                        Text {
                            anchors.centerIn: parent
                            text: "E"
                            font.family: AppleTokens.textFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: AppleTokens.bodyOnDark
                        }
                    }
                }

                // Animated Equalizer Sound Waves (iPadOS Live Activity style in top right)
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3.5

                    Repeater {
                        model: [0, 1, 2, 3]

                        Rectangle {
                            id: eqBar
                            required property int index
                            width: 4
                            height: 6
                            radius: 2
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
                            anchors.bottom: parent.bottom

                            SequentialAnimation on height {
                                running: root.isPlaying
                                loops: Animation.Infinite

                                NumberAnimation {
                                    from: 4
                                    to: (eqBar.index % 2 === 0) ? 17 : 11
                                    duration: 280 + eqBar.index * 70
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    from: (eqBar.index % 2 === 0) ? 17 : 11
                                    to: (eqBar.index === 1) ? 18 : 7
                                    duration: 320 + eqBar.index * 60
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    from: (eqBar.index === 1) ? 18 : 7
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
                font.pixelSize: 15
                font.weight: Font.Normal
                color: Qt.rgba(1.0, 1.0, 1.0, 0.70)
                elide: Text.ElideRight
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            // Scrubber Bar Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Current time elapsed
                Text {
                    text: root.formatTime(root.currentPosSec)
                    font.family: AppleTokens.textFont
                    font.pixelSize: 13
                    font.weight: Font.Normal
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                }

                // Slider Track
                Item {
                    id: scrubberTrack
                    Layout.fillWidth: true
                    height: 16

                    readonly property real progress: root.totalLengthSec > 0 ? Math.max(0, Math.min(1.0, root.currentPosSec / root.totalLengthSec)) : 0

                    // Track Background
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 4.5
                        radius: 2.25
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.22)

                        // Filled bar
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(4.5, parent.width * scrubberTrack.progress)
                            radius: 2.25
                            color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (root.totalLengthSec > 0) {
                                let ratio = Math.max(0, Math.min(1, mouse.x / width));
                                root.cmdSeek(ratio * root.totalLengthSec);
                            }
                        }
                    }
                }

                // Time remaining (-M:SS)
                Text {
                    text: "-" + root.formatTime(Math.max(0, root.totalLengthSec - root.currentPosSec))
                    font.family: AppleTokens.textFont
                    font.pixelSize: 13
                    font.weight: Font.Normal
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                }
            }

            // Controls Row (Prev, Play/Pause, Next + AirPlay)
            Item {
                Layout.fillWidth: true
                height: root.showMediaButtons ? 38 : 0
                visible: root.showMediaButtons
                clip: true

                // Centered Playback Controls (with Apple-standard 52px generous hitboxes & hover pill highlights)
                Row {
                    anchors.centerIn: parent
                    spacing: 24

                    // Prev Button
                    Item {
                        width: 52
                        height: 38
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 19
                            color: prevMouse.pressed ? Qt.rgba(1.0, 1.0, 1.0, 0.18) : (prevMouse.containsMouse ? Qt.rgba(1.0, 1.0, 1.0, 0.08) : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            color: prevMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                            scale: prevMouse.pressed ? AppleTokens.pressScale : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cmdPrevious()
                        }
                    }

                    // Play/Pause Button
                    Item {
                        width: 56
                        height: 38
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 19
                            color: playMouse.pressed ? Qt.rgba(1.0, 1.0, 1.0, 0.22) : (playMouse.containsMouse ? Qt.rgba(1.0, 1.0, 1.0, 0.10) : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.isPlaying ? "󰏤" : "󰐊"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 30
                            color: playMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                            scale: playMouse.pressed ? AppleTokens.pressScale : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cmdPlayPause()
                        }
                    }

                    // Next Button
                    Item {
                        width: 52
                        height: 38
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 19
                            color: nextMouse.pressed ? Qt.rgba(1.0, 1.0, 1.0, 0.18) : (nextMouse.containsMouse ? Qt.rgba(1.0, 1.0, 1.0, 0.08) : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            color: nextMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                            scale: nextMouse.pressed ? AppleTokens.pressScale : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cmdNext()
                        }
                    }
                }

                // AirPlay / Speaker Output Icon (Right Corner)
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰡀"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.75)
                }
            }
        }
    }
}
