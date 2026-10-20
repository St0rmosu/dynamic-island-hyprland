import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris

Rectangle {
    id: root

    property bool isPreview: false
    readonly property var activePlayer: {
        if (Mpris.players && Mpris.players.values) {
            for (let i = 0; i < Mpris.players.values.length; i++) {
                let p = Mpris.players.values[i];
                if (p && p.playbackState === MprisPlaybackState.Playing) return p;
            }
            if (Mpris.players.values.length > 0) return Mpris.players.values[0];
        }
        return null;
    }

    readonly property bool hasMedia: isPreview || (activePlayer !== null && activePlayer.trackTitle !== "")
    readonly property bool isPlaying: isPreview ? true : (activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing)
    readonly property string title: isPreview ? "Starboy" : (activePlayer ? activePlayer.trackTitle : "")
    readonly property string artist: {
        if (activePlayer) {
            let a = activePlayer.trackArtists !== undefined ? activePlayer.trackArtists : activePlayer.artist;
            if (!a && activePlayer.metadata) a = activePlayer.metadata["xesam:artist"];
            if (a) return Array.isArray(a) ? a.join(", ") : String(a);
        }
        return isPreview ? "The Weeknd ft. Daft Punk" : "";
    }
    readonly property string artUrl: {
        if (activePlayer) {
            let url = activePlayer.trackArtUrl || activePlayer.artUrl;
            if (!url && activePlayer.metadata) url = activePlayer.metadata["mpris:artUrl"];
            if (url && String(url).length > 0) return String(url);
        }
        return isPreview ? "" : "";
    }

    implicitWidth: 350
    implicitHeight: 82
    radius: AppleTokens.radiusLg

    color: Qt.rgba(0.07, 0.07, 0.1, 0.82)
    border.width: 1
    border.color: Qt.rgba(1.0, 1.0, 1.0, 0.18)

    visible: hasMedia
    opacity: hasMedia ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation { duration: AppleTokens.animDurationNormal }
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.45)
        shadowBlur: 0.5
        shadowVerticalOffset: 3
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // 50x50 Album Artwork (rounded 8px)
        Rectangle {
            width: 50
            height: 50
            radius: AppleTokens.radiusSm
            color: AppleTokens.surfaceTile1
            border.width: 1
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
            clip: true

            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: root.artUrl === ""
                text: "󰎈"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: Qt.rgba(1.0, 1.0, 1.0, 0.5)
            }
        }

        // Info & Scrubber & Controls
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: root.title
                        font.family: AppleTokens.textFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.letterSpacing: AppleTokens.letterSpacingBody
                        color: AppleTokens.bodyOnDark
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.artist
                        font.family: AppleTokens.textFont
                        font.pixelSize: 12
                        font.weight: Font.Normal
                        font.letterSpacing: AppleTokens.letterSpacingBody
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.6)
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Controls Row
                Row {
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // Prev
                    Text {
                        text: "󰒮"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: prevMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                        scale: prevMouse.pressed ? AppleTokens.pressScale : 1.0

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
                        }
                    }

                    // Play/Pause
                    Text {
                        text: root.isPlaying ? "󰏤" : "󰐊"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 19
                        color: playMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                        scale: playMouse.pressed ? AppleTokens.pressScale : 1.0

                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activePlayer && root.activePlayer.canControl) {
                                    root.activePlayer.playPause();
                                }
                            }
                        }
                    }

                    // Next
                    Text {
                        text: "󰒭"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: nextMouse.pressed ? AppleTokens.primaryOnDark : AppleTokens.bodyOnDark
                        scale: nextMouse.pressed ? AppleTokens.pressScale : 1.0

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
                        }
                    }
                }
            }

            // Scrubber Bar
            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: 1.5
                color: Qt.rgba(1.0, 1.0, 1.0, 0.15)

                Rectangle {
                    width: parent.width * 0.45
                    height: parent.height
                    radius: parent.radius
                    color: AppleTokens.primaryOnDark // #2997ff
                }
            }
        }
    }
}
