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
    property bool showPasswordInput: false

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
        if (root.isPreview && root.previewMediaPlaying) return true;
        return root.activePlayer !== null && root.activePlayer.playbackState === MprisPlaybackState.Playing;
    }

    Component.onCompleted: {
        forceActiveFocus();
        if (root.wallpaperPath === "") {
            root.wallpaperPath = Quickshell.env("HOME") + "/Sfondi/Eragny's Garden.jpg";
        }
    }

    // Keyboard capture
    Keys.onPressed: function(event) {
        if (pamAuth.authenticating) return;

        // Preview toggles
        if (root.isPreview && (event.key === Qt.Key_M || event.key === Qt.Key_Tab)) {
            root.previewMediaPlaying = !root.previewMediaPlaying;
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Escape) {
            pamAuth.clear();
            root.showPasswordInput = false;
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

        // Printable characters
        if (event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            root.showPasswordInput = true;
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

    // 3. Ambient Album Art Blurred Layer (Screenshot 2: smooth atmospheric glow matching album art)
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

    // 4. iPadOS Top Bar
    Item {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 48
        z: 30

        // Top-Left: "Tocca per sbloccare"
        Item {
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.verticalCenter: parent.verticalCenter
            width: unlockText.implicitWidth
            height: unlockText.implicitHeight

            Text {
                id: unlockText
                anchors.centerIn: parent
                text: "Tocca per sbloccare"
                font.family: AppleTokens.textFont
                font.pixelSize: 14
                font.weight: Font.Normal
                color: Qt.rgba(1.0, 1.0, 1.0, 0.9)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 1
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.showPasswordInput = !root.showPasswordInput;
                    root.forceActiveFocus();
                }
            }
        }

        // Top-Center: Apple Dynamic Island Capsule
        DynamicIslandLockCapsule {
            id: islandCapsule
            anchors.centerIn: parent
        }

        // Top-Right: iPad Status (Wi-Fi + Battery Level & Capsule Pill)
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 32
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Wi-Fi Icon
            Text {
                text: "󰖩"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: Qt.rgba(1.0, 1.0, 1.0, 0.95)

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 1
                }
            }

            // iPad Battery Group (Percentage + Capsule Pill)
            RowLayout {
                spacing: 6

                Text {
                    text: root.batteryLevel + ""
                    font.family: AppleTokens.roundedFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.95)

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.6)
                        shadowBlur: 0.4
                        shadowVerticalOffset: 1
                    }
                }

                // Apple Battery Capsule Pill
                Item {
                    width: 27
                    height: 13

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 24
                        radius: 3.5
                        color: "transparent"
                        border.width: 1.2
                        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.65)

                        // Inner fill level
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 1.5
                            width: Math.max(2, (parent.width - 3) * (root.batteryLevel / 100))
                            radius: 2
                            color: root.batteryStatus === "Charging" ? AppleTokens.successGreen : (root.batteryLevel < 20 ? AppleTokens.errorRed : AppleTokens.bodyOnDark)
                        }

                        // Charging bolt inside battery if charging
                        Text {
                            anchors.centerIn: parent
                            visible: root.batteryStatus === "Charging"
                            text: "⚡"
                            font.family: AppleTokens.textFont
                            font.pixelSize: 8
                            color: AppleTokens.bodyOnDark
                        }
                    }

                    // Battery Terminal Nipple
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 5
                        radius: 1
                        color: Qt.rgba(1.0, 1.0, 1.0, 0.6)
                    }
                }
            }
        }
    }

    // 5. Left Column: iPad Complications Stack (Battery/Pencil, Quick Apps, Connectivity)
    IpadComplicationsStack {
        id: complicationsStack
        anchors.left: parent.left
        anchors.leftMargin: 56
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -10
        batteryLevel: root.batteryLevel
        batteryStatus: root.batteryStatus
        z: 20
    }

    // 6. Center Hero Presentation: Smooth Crossfade between Normal (Screenshot 1) & Media (Screenshot 2)

    // MODE A: Normal iPad Lockscreen (Screenshot 1: Date + Giant 140px Clock)
    ColumnLayout {
        id: normalClockGroup
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 2
        z: 15

        visible: opacity > 0.001
        opacity: root.isMediaPlaying ? 0.0 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
        }

        // Date (SF Pro Rounded Bold 24px: "Mar 20 ott")
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

        // Clock (SF Pro Rounded Bold 142px: "01:19")
        Text {
            text: root.timeString
            font.family: AppleTokens.roundedFont
            font.pixelSize: 142
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

        // Password Input Pill (Centered under normal clock)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            width: pwdInputNormal.implicitWidth
            height: pwdInputNormal.implicitHeight
            visible: opacity > 0.001
            opacity: (root.showPasswordInput || pamAuth.buffer.length > 0 || pamAuth.authenticating || pamAuth.isError) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            PasswordPillInput {
                id: pwdInputNormal
                buffer: pamAuth.buffer
                isError: pamAuth.isError
                errorMessage: pamAuth.errorMessage
                authenticating: pamAuth.authenticating
                anchors.centerIn: parent

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
    }

    // MODE B: Media Playing iPad Lockscreen (Screenshot 2: Compact Clock + Large Album Art + Frosted Player Card)
    ColumnLayout {
        id: mediaLockGroup
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
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

        // Password Input Pill (Visible when typing in media mode)
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            width: pwdInputMedia.implicitWidth
            height: pwdInputMedia.implicitHeight
            visible: opacity > 0.001
            opacity: (root.showPasswordInput || pamAuth.buffer.length > 0 || pamAuth.authenticating || pamAuth.isError) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            PasswordPillInput {
                id: pwdInputMedia
                buffer: pamAuth.buffer
                isError: pamAuth.isError
                errorMessage: pamAuth.errorMessage
                authenticating: pamAuth.authenticating
                anchors.centerIn: parent

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
    }

    // 7. Apple Home Bar Indicator (Bottom Center horizontal pill)
    Rectangle {
        id: homeBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: 140
        height: 5
        radius: 2.5
        color: Qt.rgba(1.0, 1.0, 1.0, 0.7)
        z: 30

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 0.3
            shadowVerticalOffset: 1
        }
    }
}
