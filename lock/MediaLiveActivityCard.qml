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
    readonly property string artist: isPreview ? "The Weeknd ft. Daft Punk" : (activePlayer ? activePlayer.trackArtists.join(", ") : "")
    readonly property string artUrl: isPreview ? "" : (activePlayer ? activePlayer.trackImageUrl : "")

    implicitWidth: 380
    implicitHeight: 88
    radius: AppleTokens.radiusLg

    color: AppleTokens.surfaceGlassDark
    border.width: 1
    border.color: AppleTokens.hairlineDark

    visible: hasMedia
    opacity: hasMedia ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation { duration: AppleTokens.animDurationNormal }
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.4)
        shadowBlur: 0.5
        shadowVerticalOffset: 3
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14

        // 52x52 Album Artwork (rounded 8px)
        Rectangle {
            width: 52
            height: 52
            radius: AppleTokens.radiusSm
            color: AppleTokens.surfaceTile1
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
                color: AppleTokens.inkMuted48
            }
        }

        // Info & Scrubber & Controls
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.title
                        font.family: AppleTokens.textFont
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        font.letterSpacing: AppleTokens.letterSpacingBody
                        color: AppleTokens.bodyOnDark
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.artist
                        font.family: AppleTokens.textFont
                        font.pixelSize: 13
                        font.weight: Font.Normal
                        font.letterSpacing: AppleTokens.letterSpacingBody
                        color: AppleTokens.inkMuted48
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
                        font.pixelSize: 16
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
                        font.pixelSize: 20
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
                        font.pixelSize: 16
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
