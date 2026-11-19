pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property alias pam: pamAuth
    property bool isPreview: false
    property bool previewMediaPlaying: false

    // Configurable options
    property bool showTopStatus: false
    property bool showProfilePhoto: false
    property bool showComplications: false
    property bool showDateAboveClock: false
    property bool enableMediaMode: true
    property bool showMediaButtons: true
    property bool depthEffectEnabled: false
    property string avatarPath: Quickshell.env("HOME") + "/Immagineprofilo/lollo.png"
    property string userClockFontFamily: ""

    FileView {
        id: userConfigFile
        path: Quickshell.env("HOME") + "/.config/dynamic-island/userconfig.json"
        watchChanges: true
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                let data = JSON.parse(text().trim());
                if (data.clockFontFamily) root.userClockFontFamily = String(data.clockFontFamily);
                else if (data.timeFontFamily) root.userClockFontFamily = String(data.timeFontFamily);
                else if (data.heroFontFamily) root.userClockFontFamily = String(data.heroFontFamily);
                else if (data.textFontFamily) root.userClockFontFamily = String(data.textFontFamily);

                if (data.wallpaperPath) root.wallpaperPath = String(data.wallpaperPath);

                if (data.lockDepthEffect !== undefined) root.depthEffectEnabled = Boolean(data.lockDepthEffect);
                if (data.lockShowProfilePhoto !== undefined) root.showProfilePhoto = Boolean(data.lockShowProfilePhoto);
                if (data.lockShowTopStatus !== undefined) root.showTopStatus = Boolean(data.lockShowTopStatus);
                if (data.lockShowComplications !== undefined) root.showComplications = Boolean(data.lockShowComplications);
                if (data.lockShowDate !== undefined) root.showDateAboveClock = Boolean(data.lockShowDate);
                if (data.lockEnableMediaMode !== undefined) root.enableMediaMode = Boolean(data.lockEnableMediaMode);
                if (data.lockShowMediaButtons !== undefined) root.showMediaButtons = Boolean(data.lockShowMediaButtons);
            } catch(e) {}
        }
    }

    readonly property string effectiveClockFontFamily: root.userClockFontFamily !== "" ? root.userClockFontFamily : AppleTokens.roundedFont

    FileView {
        id: irisColors
        path: Quickshell.env("HOME") + "/.cache/iris/colors.json"
        property string accentHex: ""
        onLoaded: {
            try {
                let c = JSON.parse(text().trim());
                if (c && c.accent) accentHex = c.accent;
            } catch(e) {}
        }
    }

    readonly property color dynamicClockColor: {
        if (irisColors.accentHex !== "") {
            let acc = Qt.color(irisColors.accentHex);
            // Harmonious luminescence: blends 42% crisp white with 58% wallpaper accent
            return Qt.tint(Qt.rgba(acc.r, acc.g, acc.b, 0.96), Qt.rgba(1.0, 1.0, 1.0, 0.42));
        }
        return Qt.rgba(1.0, 1.0, 1.0, 0.95);
    }

    signal unlockRequested()

    focus: true
    onActiveFocusChanged: {
        if (!activeFocus && !unlockAnim.running) {
            forceActiveFocus();
        }
    }

    readonly property var currentIdentity: topIslandCapsule

    function triggerUnlock(): void {
        if (unlockAnim.running) return;
        if (root.currentIdentity) root.currentIdentity.lockState = "unlocked";
        unlockAnim.start();
    }

    // PAM Authentication Backend
    PamAuth {
        id: pamAuth
        enabled: !root.isPreview

        onAuthenticated: {
            root.triggerUnlock();
        }

        onFailed: {
            if (root.currentIdentity) {
                root.currentIdentity.lockState = "failed";
                root.currentIdentity.triggerShake();
            }
        }

        onIsErrorChanged: {
            if (!isError && root.currentIdentity && root.currentIdentity.lockState === "failed") {
                root.currentIdentity.lockState = "locked";
            }
        }
    }

    // ── saneAspect Clock Drop Geometry ──
    readonly property real clockRestCenterY: root.height * 0.5 - Math.round(root.height * 0.055)
    readonly property real capsuleCenterY: topIslandCapsule.y + (topIslandCapsule.height > 0 ? topIslandCapsule.height / 2 : 14)
    readonly property real clockDropOffsetY: -(clockRestCenterY - capsuleCenterY)

    // ── Drop Animation (Clock emerges smoothly from top capsule down to center) ──
    ParallelAnimation {
        id: dropLockAnim

        NumberAnimation {
            target: normalClockGroup
            property: "animOffsetY"
            from: root.clockDropOffsetY
            to: 0.0
            duration: 380
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: normalClockGroup
            property: "animScale"
            from: 0.20
            to: 1.0
            duration: 380
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: normalClockGroup
            property: "animOpacity"
            from: 0.0
            to: 1.0
            duration: 160
            easing.type: Easing.OutQuad
        }
    }

    // ── Reset state function for reliable multi-lock lifecycle ──
    function resetToLockedState(): void {
        if (unlockAnim.running) unlockAnim.stop();
        if (dropLockAnim.running) dropLockAnim.stop();
        normalClockGroup.animOffsetY = root.clockDropOffsetY;
        normalClockGroup.animScale = 0.20;
        normalClockGroup.animOpacity = 0.0;
        topIslandCapsule.animOffsetY = 0.0;
        topIslandCapsule.opacity = 1.0;
        backgroundWrapper.opacity = 1.0;
        backgroundWrapper.scale = 1.0;
        if (root.currentIdentity) root.currentIdentity.lockState = "locked";
        pamAuth.clear();
        root.forceActiveFocus();
        dropLockAnim.restart();
    }

    // ── Unlock Exit Animation (Clock glides and shrinks back into the top capsule) ──
    SequentialAnimation {
        id: unlockAnim

        // Brief pause so the unlocked state is perceived in the capsule
        PauseAnimation {
            duration: 120
        }

        ParallelAnimation {
            // Clock glides and shrinks smoothly back into the top capsule
            NumberAnimation {
                target: normalClockGroup
                property: "animOffsetY"
                to: root.clockDropOffsetY
                duration: 220
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: normalClockGroup
                property: "animScale"
                to: 0.20
                duration: 220
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: normalClockGroup
                property: "animOpacity"
                to: 0.0
                duration: 170
                easing.type: Easing.InQuad
            }
        }

        ScriptAction {
            script: {
                root.unlockRequested();
            }
        }
    }

    // Time & Date Formatter (Exact iPadOS "Mar 20 ott" & "19:10")
    property var now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    readonly property string timeString: Qt.formatTime(root.now, "hh:mm")
    readonly property string ipadDateString: {
        const days = ["Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"];
        const months = ["gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic"];
        return days[root.now.getDay()] + " " + root.now.getDate() + " " + months[root.now.getMonth()];
    }

    // Battery info
    property int batteryLevel: 50
    property string batteryStatus: "Discharging"
    FileView {
        id: batCapFile
        path: "/sys/class/power_supply/BAT1/capacity"
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) root.batteryLevel = val;
        }
    }
    FileView {
        id: batStatFile
        path: "/sys/class/power_supply/BAT1/status"
        onLoaded: {
            let s = text().trim();
            if (s.length > 0) root.batteryStatus = s;
        }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: {
            batCapFile.reload();
            batStatFile.reload();
        }
    }

    // Wallpaper Path Resolver
    property string wallpaperPath: Quickshell.env("HOME") + "/Sfondi/Pixel Art Planet Asteroid Ring Space.png"
    FileView {
        id: walFile
        path: Quickshell.env("HOME") + "/.config/dynamic-island/current_wallpaper"
        watchChanges: true
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            let p = text().trim();
            if (p.length > 0) root.wallpaperPath = p;
        }
    }

    // Foreground cutout for Depth Effect
    readonly property string depthCutoutPath: {
        if (!root.depthEffectEnabled || root.wallpaperPath === "") return "";
        let dotIdx = root.wallpaperPath.lastIndexOf(".");
        if (dotIdx > 0) {
            return root.wallpaperPath.slice(0, dotIdx) + "_depth.png";
        }
        return "";
    }

    // MPRIS Active Player Tracker (Exact Island event-driven pattern for 0ms latency)
    property var lastValidPlayer: null
    property int mprisPulse: 0

    // Direct event listener on all MPRIS players - identical to Dynamic Island's IslandMprisController
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            ignoreUnknownSignals: true
            function onPlaybackStateChanged() { root.mprisPulse++; }
            function onTrackTitleChanged() { root.mprisPulse++; }
            function onTrackArtUrlChanged() { root.mprisPulse++; }
            function onMetadataChanged() { root.mprisPulse++; }
        }
        onObjectAdded: root.mprisPulse++
        onObjectRemoved: root.mprisPulse++
    }

    readonly property var activePlayer: {
        let _p = root.mprisPulse; // Re-evaluate instantly on event
        if (Mpris.players && Mpris.players.values) {
            for (let i = 0; i < Mpris.players.values.length; i++) {
                let p = Mpris.players.values[i];
                if (p && p.playbackState === MprisPlaybackState.Playing && (p.trackTitle || p.title || "").length > 0) {
                    root.lastValidPlayer = p;
                    return p;
                }
            }
            for (let j = 0; j < Mpris.players.values.length; j++) {
                let p2 = Mpris.players.values[j];
                if (p2 && (p2.trackTitle || p2.title || "").length > 0) {
                    root.lastValidPlayer = p2;
                    return p2;
                }
            }
        }
        if (root.lastValidPlayer) {
            return root.lastValidPlayer;
        }
        return null;
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.mprisPulse++; }
    }

    // Direct active artwork URL (reactive to active player and track transitions)
    readonly property string currentArtUrl: {
        let _p = root.mprisPulse;
        if (root.activePlayer) {
            let url = root.activePlayer.trackArtUrl || root.activePlayer.artUrl;
            if (!url && root.activePlayer.metadata) url = root.activePlayer.metadata["mpris:artUrl"];
            if (url && String(url).length > 0) return String(url);
        }
        if (root.isPreview && root.previewMediaPlaying) {
            return "file:///home/lollo/Progetti/dynamic-island-hyprland/lock/assets/sample_album_art.png";
        }
        return "";
    }

    // Instantaneous raw media activity
    readonly property bool rawMediaActive: {
        if (!root.enableMediaMode) return false;
        if (root.isPreview && root.previewMediaPlaying) return true;
        if (!root.activePlayer) return false;
        return root.activePlayer.playbackState === MprisPlaybackState.Playing;
    }

    // Debounced media mode: bridges gap between tracks so screen never flashes wallpaper when track ends
    property bool isMediaPlaying: rawMediaActive

    // ── Apple iPadOS Water Droplet Ripple Transition Mechanics ──
    property real rippleProgress: 1.0
    property bool isRippling: false

    readonly property real rippleOriginX: root.width / 2
    readonly property real rippleOriginY: (mediaLockGroup && mediaItem && mediaLockGroup.y > 0)
        ? (mediaLockGroup.y + mediaItem.y + 250)
        : (root.height * 0.44)

    readonly property real rippleCurrentSize: 250 + root.rippleProgress * 3550

    NumberAnimation {
        id: rippleAnim
        target: root
        property: "rippleProgress"
        from: 0.0
        to: 1.0
        duration: 750
        easing.type: Easing.OutCubic

        onFinished: {
            root.isRippling = false;
            if (bgAmbientAlbumArt.status === Image.Ready) {
                bgPrevAmbientArt.source = bgAmbientAlbumArt.source;
            }
        }
    }

    function startRippleTransition(): void {
        if (!root.isMediaPlaying) return;
        root.isRippling = true;
        rippleAnim.restart();
    }

    Timer {
        id: mediaGraceTimer
        interval: 2500 // 2.5s grace period to prevent collapsing media mode between songs
        repeat: false
        onTriggered: {
            if (!root.rawMediaActive) {
                root.isMediaPlaying = false;
            }
        }
    }

    onRawMediaActiveChanged: {
        if (rawMediaActive) {
            mediaGraceTimer.stop();
            root.isMediaPlaying = true;
        } else {
            mediaGraceTimer.restart();
        }
    }

    Component.onCompleted: {
        root.resetToLockedState();
        root.mprisPulse++;
    }

    // Keyboard capture: Keystrokes feed directly into pamAuth and Dynamic Island
    Keys.onPressed: function(event) {
        if (unlockAnim.running) {
            event.accepted = true;
            return;
        }

        if (pamAuth.authenticating) return;

        // Preview mode toggle
        if (root.isPreview && (event.key === Qt.Key_M || event.key === Qt.Key_Tab)) {
            root.previewMediaPlaying = !root.previewMediaPlaying;
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Escape) {
            pamAuth.clear();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (root.isPreview) {
                root.triggerUnlock();
            } else {
                if (pamAuth.buffer.length > 0) {
                    if (root.currentIdentity) root.currentIdentity.lockState = "verifying";
                    pamAuth.submitPassword();
                }
            }
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                pamAuth.clear();
            } else {
                pamAuth.backspace();
            }
            if (root.currentIdentity && root.currentIdentity.lockState === "failed") {
                root.currentIdentity.lockState = "locked";
            }
            event.accepted = true;
            return;
        }

        // Printable text feeds directly into Dynamic Island password buffer
        if (event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            pamAuth.appendChar(event.text);
            if (root.currentIdentity && root.currentIdentity.lockState === "failed") {
                root.currentIdentity.lockState = "locked";
            }
            event.accepted = true;
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // A. BACKGROUND WRAPPER (Wallpaper, Ambient glow, Scrims)
    // ──────────────────────────────────────────────────────────────────────────
    Item {
        id: backgroundWrapper
        anchors.fill: parent
        transformOrigin: Item.Center

        // 1. Solid opaque base
        Rectangle {
            anchors.fill: parent
            color: "#050507"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: false
                onClicked: root.forceActiveFocus()
            }
        }

        // 2. Wallpaper Layer: Sharp iPadOS Wallpaper (only visible when not playing media)
        Image {
            id: bgWallpaper
            anchors.fill: parent
            source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            visible: opacity > 0.001
            opacity: root.isMediaPlaying ? 0.0 : 1.0
            Behavior on opacity {
                NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
            }
        }

        // 3A. Previous Ambient Album Art (maintains diffuse atmospheric glow during track transitions)
        Image {
            id: bgPrevAmbientArt
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(240, 240)
            asynchronous: true
            visible: opacity > 0.001 && source !== ""
            opacity: root.isMediaPlaying ? 1.0 : 0.0

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                saturation: 0.3
                brightness: -0.18
            }
        }

        // 3B. Active Ambient Album Art Blurred Layer (Masked by Water Droplet Ripple)
        Image {
            id: bgAmbientAlbumArt
            anchors.fill: parent
            source: root.currentArtUrl
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(240, 240)
            asynchronous: true
            visible: opacity > 0.001
            opacity: (root.isMediaPlaying && status === Image.Ready) ? 1.0 : 0.0
            Behavior on opacity {
                enabled: !root.isRippling
                NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
            }

            onStatusChanged: {
                if (status === Image.Ready) {
                    if (bgPrevAmbientArt.source === "" || bgPrevAmbientArt.status !== Image.Ready) {
                        bgPrevAmbientArt.source = bgAmbientAlbumArt.source;
                    }
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                saturation: 0.3
                brightness: -0.18
                maskEnabled: root.isRippling
                maskSource: rippleMaskItem
            }
        }

        // Feathered Water Droplet Mask Source for bgAmbientAlbumArt
        // Feathered Water Droplet Mask Source for bgAmbientAlbumArt
        Item {
            id: rippleMaskItem
            anchors.fill: parent
            layer.enabled: true
            visible: false

            Image {
                x: root.rippleOriginX - width / 2
                y: root.rippleOriginY - height / 2
                width: root.rippleCurrentSize
                height: width
                source: Qt.resolvedUrl("assets/ripple_mask.png")
                fillMode: Image.Stretch
            }
        }

        // Atmospheric warm tint scrim over ambient art
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.06, 0.04, 0.07, 0.55) }
                GradientStop { position: 0.5; color: Qt.rgba(0.06, 0.04, 0.07, 0.35) }
                GradientStop { position: 1.0; color: Qt.rgba(0.06, 0.04, 0.07, 0.65) }
            }
            visible: opacity > 0.001
            opacity: root.isMediaPlaying ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
            }
        }

        // Visible Water Droplet Wave Crest 1 (Primary luminous liquid wave ring)
        Rectangle {
            visible: root.isRippling && opacity > 0.001
            x: root.rippleOriginX - width / 2
            y: root.rippleOriginY - height / 2
            width: root.rippleCurrentSize * 0.94
            height: width
            radius: width / 2
            color: "transparent"
            border.width: Math.max(2, 24 * (1.0 - root.rippleProgress))
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.75 * (1.0 - Math.pow(root.rippleProgress, 1.2)))

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.7
                blurMax: 32
            }
        }

        // Visible Water Droplet Wave Crest 2 (Trailing liquid refraction echo ring)
        Rectangle {
            visible: root.isRippling && opacity > 0.001
            x: root.rippleOriginX - width / 2
            y: root.rippleOriginY - height / 2
            width: Math.max(10, (root.rippleCurrentSize * 0.94) - 110 * (1.0 - root.rippleProgress * 0.3))
            height: width
            radius: width / 2
            color: "transparent"
            border.width: Math.max(1, 12 * (1.0 - root.rippleProgress))
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.45 * (1.0 - Math.pow(root.rippleProgress, 1.1)))

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.75
                blurMax: 24
            }
        }

        // Subtle iPad Scrim Gradients for 100% readability
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 140
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 180
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // B. FOREGROUND CONTENT WRAPPER (Widgets, Clock, Media Card, Dynamic Island)
    // ──────────────────────────────────────────────────────────────────────────
    Item {
        id: contentWrapper
        anchors.fill: parent
        transformOrigin: Item.Center

        // 4. Left Column: iPad Complications Stack (Battery/Pencil, Quick Apps, Connectivity)
        IpadComplicationsStack {
            id: complicationsStack
            anchors.left: parent.left
            anchors.leftMargin: 56
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -10
            batteryLevel: root.batteryLevel
            batteryStatus: root.batteryStatus
            visible: root.showComplications
            z: 20
        }

        // Optional Top-Right Status (hidden by default as requested by user)
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 32
            anchors.top: parent.top
            anchors.topMargin: 24
            spacing: 10
            visible: root.showTopStatus
            z: 30

            Text {
                text: "󰖩"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
            }

            Text {
                text: root.batteryLevel + "%"
                font.family: AppleTokens.roundedFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
            }
        }

        // 0. Top Dynamic Island Lock Capsule (Apple Dynamic Island Notch)
        DynamicIslandLockCapsule {
            id: topIslandCapsule
            property real animOffsetY: 0.0
            transform: Translate { y: topIslandCapsule.animOffsetY }
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            compactIdle: true
            z: 50

            buffer: pamAuth.buffer
            authenticating: pamAuth.authenticating
            isError: pamAuth.isError
            errorMessage: pamAuth.errorMessage

            onFocusRequested: root.forceActiveFocus()

            onSubmitRequested: function(pwd) {
                if (root.isPreview) {
                    root.triggerUnlock();
                } else {
                    if ((pwd && pwd.length > 0) || pamAuth.buffer.length > 0) {
                        topIslandCapsule.lockState = "verifying";
                        pamAuth.submitPassword(pwd);
                    }
                }
            }
        }

        // MODE A: Normal Idle Lockscreen (Aesthetic Giant Rounded Clock - saneAspect style)
        Item {
            id: normalClockGroup
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -Math.round(root.height * 0.055)
            width: clockText.implicitWidth
            height: clockText.implicitHeight
            z: 10
            transformOrigin: Item.Center

            property real animOffsetY: 0.0
            property real animScale: 1.0
            property real animOpacity: 1.0

            transform: [
                Translate { y: normalClockGroup.animOffsetY },
                Scale {
                    origin.x: normalClockGroup.width / 2
                    origin.y: normalClockGroup.height / 2
                    xScale: normalClockGroup.animScale
                    yScale: normalClockGroup.animScale
                }
            ]

            visible: opacity > 0.001
            opacity: normalClockGroup.animOpacity * (!root.isMediaPlaying ? 1.0 : 0.0)
            Behavior on opacity {
                enabled: !dropLockAnim.running && !unlockAnim.running
                NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
            }

            // Optional Subtle Date above clock (if user enables lockShowDate)
            Text {
                id: dateAboveClock
                anchors.bottom: clockText.top
                anchors.bottomMargin: 12
                anchors.horizontalCenter: clockText.horizontalCenter
                text: root.ipadDateString
                font.family: root.effectiveClockFontFamily
                font.pixelSize: 22
                font.weight: Font.DemiBold
                font.letterSpacing: -0.2
                color: root.dynamicClockColor
                visible: root.showDateAboveClock

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.45)
                    shadowBlur: 0.5
                    shadowVerticalOffset: 2
                }
            }

            // Centered Clock with SaneAspect Rounded Typography & Ambient Shadow
            Text {
                id: clockText
                anchors.centerIn: parent
                text: root.timeString
                font.family: root.effectiveClockFontFamily
                font.weight: Font.Bold
                font.pixelSize: Math.round(root.height * 0.165)
                font.letterSpacing: -1.5
                color: root.dynamicClockColor

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.45)
                    shadowBlur: 0.65
                    shadowVerticalOffset: 6
                }
            }
        }

        // 5B. Foreground Cutout Image for Depth Effect (renders in FRONT of the clock!)
        Image {
            id: depthCutoutImage
            anchors.fill: parent
            source: root.depthCutoutPath !== "" ? "file://" + root.depthCutoutPath : ""
            fillMode: Image.PreserveAspectCrop
            visible: root.depthEffectEnabled && status === Image.Ready
            asynchronous: true
            z: 12
        }

        // MODE B: Media Playing iPad Lockscreen (Screenshot 2: Compact Clock + Hero Album Art + Frosted Player Card + Avatar & Password Pill BELOW)
        ColumnLayout {
            id: mediaLockGroup
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 0
            spacing: 10
            z: 15

            visible: opacity > 0.001
            opacity: root.isMediaPlaying ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
            }

            // Compact Clock & Date Header (Screenshot 2: "19:10   Mar 20 ott")
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                Text {
                    text: root.timeString
                    font.family: root.effectiveClockFontFamily
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    font.letterSpacing: -0.2
                    color: AppleTokens.bodyOnDark

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.6)
                        shadowBlur: 0.4
                        shadowVerticalOffset: 1
                    }
                }

                Text {
                    text: root.ipadDateString
                    font.family: root.effectiveClockFontFamily
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    font.letterSpacing: -0.2
                    color: AppleTokens.bodyOnDark

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.6)
                        shadowBlur: 0.4
                        shadowVerticalOffset: 1
                    }
                }
            }

            // Hero Album Art + iPadOS Media Player Card
            IpadMediaPlayerCard {
                id: mediaItem
                activePlayer: root.activePlayer
                artUrl: root.currentArtUrl
                showMediaButtons: root.showMediaButtons
                isPreview: root.isPreview
                previewMediaPlaying: root.previewMediaPlaying
                Layout.alignment: Qt.AlignHCenter

                onRippleTriggered: {
                    root.startRippleTransition();
                }
            }
        }
    }
}
