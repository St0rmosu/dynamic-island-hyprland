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
    property bool showProfilePhoto: true
    property bool showComplications: true
    property bool enableMediaMode: true
    property bool depthEffectEnabled: false
    property string avatarPath: Quickshell.env("HOME") + "/Immagineprofilo/lollo.png"

    FileView {
        id: userConfigFile
        path: Quickshell.env("HOME") + "/.config/dynamic-island/userconfig.json"
        onLoaded: {
            try {
                let data = JSON.parse(text().trim());
                if (data.lockDepthEffect !== undefined) root.depthEffectEnabled = Boolean(data.lockDepthEffect);
                if (data.lockShowProfilePhoto !== undefined) root.showProfilePhoto = Boolean(data.lockShowProfilePhoto);
                if (data.lockShowTopStatus !== undefined) root.showTopStatus = Boolean(data.lockShowTopStatus);
                if (data.lockShowComplications !== undefined) root.showComplications = Boolean(data.lockShowComplications);
                if (data.lockEnableMediaMode !== undefined) root.enableMediaMode = Boolean(data.lockEnableMediaMode);
            } catch(e) {}
        }
    }

    signal unlockRequested()

    focus: true

    // PAM Authentication Backend
    PamAuth {
        id: pamAuth
        enabled: !root.isPreview

        onAuthenticated: {
            islandCapsule.lockState = "unlocked";
            unlockTimer.start();
        }

        onFailed: {
            islandCapsule.lockState = "failed";
            islandCapsule.triggerShake();
        }
    }

    Timer {
        id: unlockTimer
        interval: 380
        repeat: false
        onTriggered: {
            root.unlockRequested();
        }
    }

    // Time & Date Formatter (Exact iPadOS "Mar 20 ott" & "01:19")
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
    property int batteryLevel: 62
    property string batteryStatus: "Discharging"
    FileView {
        path: "/sys/class/power_supply/BAT1/capacity"
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) root.batteryLevel = val;
        }
    }
    FileView {
        path: "/sys/class/power_supply/BAT1/status"
        onLoaded: {
            let s = text().trim();
            if (s.length > 0) root.batteryStatus = s;
        }
    }

    // Wallpaper Path Resolver
    property string wallpaperPath: ""
    FileView {
        id: walFile
        path: Quickshell.env("HOME") + "/.config/dynamic-island/current_wallpaper"
        onLoaded: {
            let p = text().trim();
            if (p.length > 0) root.wallpaperPath = p;
        }
    }

    // Foreground cutout for Depth Effect (e.g. wall_depth.png or Eragny's Garden_depth.png)
    readonly property string depthCutoutPath: {
        if (!root.depthEffectEnabled || root.wallpaperPath === "") return "";
        let dotIdx = root.wallpaperPath.lastIndexOf(".");
        if (dotIdx > 0) {
            return root.wallpaperPath.slice(0, dotIdx) + "_depth.png";
        }
        return "";
    }

    // MPRIS Active Player Tracker
    readonly property var activePlayer: {
        if (Mpris.players && Mpris.players.values) {
            for (let i = 0; i < Mpris.players.values.length; i++) {
                let p = Mpris.players.values[i];
                if (p && p.playbackState === MprisPlaybackState.Playing && (p.trackTitle || "").length > 0) return p;
            }
            for (let j = 0; j < Mpris.players.values.length; j++) {
                let p2 = Mpris.players.values[j];
                if (p2 && (p2.trackTitle || "").length > 0) return p2;
            }
        }
        return null;
    }

    // Mode determination: Media Playing (Screenshot 2) vs Normal Idle (Screenshot 1)
    readonly property bool isMediaPlaying: {
        if (!root.enableMediaMode) return false;
        if (root.isPreview && root.previewMediaPlaying) return true;
        return root.activePlayer !== null && root.activePlayer.playbackState === MprisPlaybackState.Playing;
    }

    Component.onCompleted: {
        forceActiveFocus();
        if (root.wallpaperPath === "") {
            root.wallpaperPath = Quickshell.env("HOME") + "/Sfondi/Eragny's Garden.jpg";
        }
    }

    // Keyboard capture: Keystrokes feed directly into pamAuth and Dynamic Island!
    Keys.onPressed: function(event) {
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
                islandCapsule.lockState = "unlocked";
                unlockTimer.start();
            } else {
                islandCapsule.lockState = "verifying";
                pamAuth.submitPassword();
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
            if (islandCapsule.lockState === "failed") {
                islandCapsule.lockState = "locked";
            }
            event.accepted = true;
            return;
        }

        // Printable text feeds directly into Dynamic Island password buffer
        if (event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            pamAuth.appendChar(event.text);
            if (islandCapsule.lockState === "failed") {
                islandCapsule.lockState = "locked";
            }
            event.accepted = true;
        }
    }

    // 1. Solid opaque base
    Rectangle {
        anchors.fill: parent
        color: "#050507"
    }

    // 2. Wallpaper Layer: Sharp iPadOS Wallpaper
    Image {
        id: bgWallpaper
        anchors.fill: parent
        source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        asynchronous: true
    }

    // 3. Ambient Album Art Blurred Layer (Screenshot 2: smooth diffuse atmospheric glow)
    Image {
        id: bgAmbientAlbumArt
        anchors.fill: parent
        source: mediaItem.artUrl
        sourceSize: Qt.size(16, 16)
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        asynchronous: true

        opacity: root.isMediaPlaying ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 420; easing.type: Easing.InOutQuad }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.3
            brightness: -0.18
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
        opacity: root.isMediaPlaying ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 420 }
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

    // 5. Top Center Hero: Profile Photo (Avatar) + Dynamic Island Password Capsule
    ColumnLayout {
        id: topCenterIdentityGroup
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10
        z: 30

        // Profile Picture Avatar (62x62 with subtle frosted ring)
        Item {
            id: avatarWrapper
            Layout.alignment: Qt.AlignHCenter
            width: 62
            height: 62
            visible: root.showProfilePhoto

            // Fallback circular base
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.rgba(0.12, 0.12, 0.14, 0.8)
                border.width: 1.5
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.35)
            }

            Text {
                anchors.centerIn: parent
                visible: pfpImg.status !== Image.Ready
                text: ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 26
                color: Qt.rgba(1.0, 1.0, 1.0, 0.6)
            }

            // Circular Mask
            Rectangle {
                id: maskShape
                anchors.fill: parent
                radius: width / 2
                color: "black"
                layer.enabled: true
                visible: false
            }

            // User Profile Image
            Image {
                id: pfpImg
                anchors.fill: parent
                source: root.avatarPath !== "" ? "file://" + root.avatarPath : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                asynchronous: true

                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: maskShape
                    maskSpreadAtMin: 1
                    maskThresholdMin: 0.5
                }
            }

            // Outer Hairline Ring & Drop Shadow
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 1.5
                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.45)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.55)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 2
                }
            }
        }

        // Dynamic Island Capsule (Expands directly as Password Input when typing!)
        DynamicIslandLockCapsule {
            id: islandCapsule
            Layout.alignment: Qt.AlignHCenter
            buffer: pamAuth.buffer
            authenticating: pamAuth.authenticating
            isError: pamAuth.isError
            errorMessage: pamAuth.errorMessage

            onSubmitRequested: function(pwd) {
                if (root.isPreview) {
                    islandCapsule.lockState = "unlocked";
                    unlockTimer.start();
                } else {
                    islandCapsule.lockState = "verifying";
                    pamAuth.submitPassword(pwd);
                }
            }
        }
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
            font.weight: Font.Bold
            color: Qt.rgba(1.0, 1.0, 1.0, 0.95)
        }
    }

    // 6. Center Hero Presentation: Smooth Crossfade between Normal (Screenshot 1) & Media (Screenshot 2)

    // MODE A: Normal iPad Lockscreen (Screenshot 1: Date + Giant 140px Clock)
    ColumnLayout {
        id: normalClockGroup
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 10
        spacing: 2
        z: 15

        visible: opacity > 0.001
        opacity: root.isMediaPlaying ? 0.0 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
        }

        // Date (SF Pro Rounded Bold 25px: "Mar 20 ott")
        Text {
            text: root.ipadDateString
            font.family: AppleTokens.roundedFont
            font.pixelSize: 25
            font.weight: Font.Bold
            font.letterSpacing: -0.2
            color: AppleTokens.bodyOnDark
            Layout.alignment: Qt.AlignHCenter

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.5
                shadowVerticalOffset: 2
            }
        }

        // Clock (SF Pro Rounded Bold 144px: "01:19")
        Text {
            text: root.timeString
            font.family: AppleTokens.roundedFont
            font.pixelSize: 144
            font.weight: Font.Bold
            font.letterSpacing: -2.5
            color: AppleTokens.bodyOnDark
            Layout.alignment: Qt.AlignHCenter

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 0.6
                shadowVerticalOffset: 4
            }
        }
    }

    // 6B. Foreground Cutout Image for Depth Effect (renders in FRONT of the clock!)
    Image {
        id: depthCutoutImage
        anchors.fill: parent
        source: root.depthCutoutPath !== "" ? "file://" + root.depthCutoutPath : ""
        fillMode: Image.PreserveAspectCrop
        visible: root.depthEffectEnabled && status === Image.Ready && !root.isMediaPlaying
        z: 16
        asynchronous: true
    }

    // MODE B: Media Playing iPad Lockscreen (Screenshot 2: Compact Clock + Large Album Art + Frosted Player Card)
    ColumnLayout {
        id: mediaLockGroup
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 48
        spacing: 12
        z: 15

        visible: opacity > 0.001
        opacity: root.isMediaPlaying ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
        }

        // Compact Clock & Date Header (Screenshot 2: "01:23   Mar 20 ott")
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Text {
                text: root.timeString
                font.family: AppleTokens.roundedFont
                font.pixelSize: 20
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
                font.family: AppleTokens.roundedFont
                font.pixelSize: 20
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
            isPreview: root.isPreview
            previewMediaPlaying: root.previewMediaPlaying
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
