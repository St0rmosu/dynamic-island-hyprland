import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import IslandBackend

Rectangle {
    id: root

    property var targetCapsule: null
    property var rootWindow: null
    property var mprisController: null
    property var userConfig: UserConfig
    property real islandTopMargin: 4
    property color accentColor: StyleTokens.accent

    readonly property var activePlayer: mprisController ? mprisController.activePlayer : null
    readonly property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property bool hasTrack: Boolean(activePlayer && mprisController.currentTrack !== "" && mprisController.currentTrack !== "Unknown")
    readonly property string trackTitle: mprisController ? mprisController.currentTrack : ""
    readonly property string artistName: mprisController ? mprisController.currentArtist : ""
    readonly property string artUrl: mprisController ? mprisController.currentArtUrl : ""
    readonly property real trackProgress: mprisController ? mprisController.trackProgress : 0
    readonly property string timePlayed: mprisController ? mprisController.timePlayed : "0:00"
    readonly property string timeTotal: mprisController ? mprisController.timeTotal : "0:00"

    property bool isExpanded: false

    // Dimensioni:
    // A riposo: cerchio perfetto identico alla foto 2 (width = height = islandHeight)
    // Espanso: player nativo della barra (410x165) identico alla foto 0
    readonly property real compactHeight: userConfig ? userConfig.islandHeight : 38
    readonly property real compactWidth: compactHeight
    readonly property real expandedWidth: 410
    readonly property real expandedHeight: 165

    width: isExpanded ? expandedWidth : compactWidth
    height: isExpanded ? expandedHeight : compactHeight
    radius: isExpanded ? 40 : compactHeight / 2

    // Ancoraggio solido al lato sinistro della capsula principale:
    // Il bordo destro della pillola resta fisso a 12px da mainCapsule,
    // espandendosi con fluidità verso sinistra senza mai sovrapporsi!
    anchors.right: targetCapsule ? targetCapsule.left : undefined
    anchors.rightMargin: 7
    anchors.top: targetCapsule ? targetCapsule.top : undefined

    visible: hasTrack && opacity > 0.01
    opacity: hasTrack ? (targetCapsule ? targetCapsule.opacity : 1.0) : 0.0
    scale: hasTrack ? 1.0 : 0.82

    clip: true
    color: "#000000"
    border.width: isExpanded ? 0 : 1
    border.color: isExpanded ? "transparent" : (hoverArea.containsMouse ? "#2a2a2a" : "#141414")

    // Animazioni fluide stile iOS Dynamic Island
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

    onHasTrackChanged: {
        if (!hasTrack) isExpanded = false;
    }

    // ==========================================
    // 1. STATO COMPATTO (Mini Circle come foto 2)
    // ==========================================
    Item {
        id: compactContainer
        anchors.fill: parent
        visible: !root.isExpanded
        opacity: root.isExpanded ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        // Miniatura circolare centrata nel cerchio nero
        ClippingRectangle {
            anchors.centerIn: parent
            width: Math.round(root.compactHeight * 0.62)
            height: width
            radius: width / 2
            color: "#1c1c1e"
            antialiasing: true

            Image {
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                visible: root.artUrl !== ""
            }

            Text {
                anchors.centerIn: parent
                visible: root.artUrl === ""
                text: "󰝚"
                font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                color: root.accentColor
            }
        }
    }

    // ==========================================
    // 2. STATO ESPANSO (Player nativo come foto 0)
    // ==========================================
    ExpandedPlayerLayer {
        id: nativePlayer
        anchors.fill: parent
        visible: root.isExpanded
        showCondition: root.isExpanded
        accentColor: root.accentColor
        currentArtUrl: root.artUrl
        currentTrack: root.trackTitle
        currentArtist: root.artistName
        timePlayed: root.timePlayed
        timeTotal: root.timeTotal
        trackProgress: root.trackProgress
        activePlayer: root.activePlayer
        lyricsActive: rootWindow ? rootWindow.lyricsActive : false
        iconFontFamily: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
        textFontFamily: userConfig ? userConfig.textFontFamily : "Sans Serif"
        onControlPressed: {}
        onBackgroundClicked: root.isExpanded = false
        onCloseRequested: root.isExpanded = false
        onLyricsToggleRequested: {
            root.isExpanded = false;
            if (rootWindow) {
                rootWindow.toggleLyricsWindow();
            }
        }
        onPreviousRequested: {
            if (mprisController) mprisController.previous();
            else if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous();
        }
    }

    // Click sullo stato compatto per espandere
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: !root.isExpanded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.isExpanded = true;
        }
        onEntered: {
            if (rootWindow && rootWindow.autoHideEnabled) {
                rootWindow.autoHidePointerInside = true;
                rootWindow.showAutoHiddenIsland("edge");
            }
        }
        onExited: {
            if (rootWindow && rootWindow.autoHideEnabled) {
                rootWindow.autoHidePointerInside = false;
                rootWindow.scheduleAutoHide();
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
