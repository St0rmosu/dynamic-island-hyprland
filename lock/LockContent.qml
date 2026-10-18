import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: root

    property alias pam: pamAuth
    property bool isPreview: false
    signal unlockRequested()

    focus: true

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

    // Time & Date
    property var now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    readonly property string timeString: Qt.formatTime(root.now, "hh:mm")
    readonly property string dateString: {
        let s = Qt.formatDate(root.now, "dddd d MMMM");
        return s.charAt(0).toUpperCase() + s.slice(1);
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

    Component.onCompleted: {
        forceActiveFocus();
        if (root.wallpaperPath === "") {
            root.wallpaperPath = Quickshell.env("HOME") + "/Sfondi/Wet-Road.jpg";
        }
    }

    // Capture Keys
    Keys.onPressed: function(event) {
        if (pamAuth.authenticating) return;

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

        // Printable text
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

    // 2. Wallpaper Layer: Sharp photography with smooth focus-pull blur on typing
    Image {
        id: bgWallpaper
        anchors.fill: parent
        source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        asynchronous: true

        readonly property real targetBlur: pamAuth.buffer.length > 0 ? 0.45 : 0.0
        property real currentBlur: targetBlur
        Behavior on currentBlur {
            NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }

        layer.enabled: currentBlur > 0.01
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: bgWallpaper.currentBlur
            blurMax: 32
            saturation: 0.15
        }
    }

    // 3. Cinematic Vignette (Soft top/bottom gradients for 100% legibility)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 0.25; color: Qt.rgba(0, 0, 0, 0.15) }
            GradientStop { position: 0.7; color: Qt.rgba(0, 0, 0, 0.2) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }

    // 4. Dynamic Island Top Capsule (iOS / macOS status)
    DynamicIslandLockCapsule {
        id: islandCapsule
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        z: 20
    }

    // 5. Center Hero Column (macOS Sequoia Desktop Layout)
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -24
        spacing: 20
        z: 10

        // Clock & Date Group
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2

            // Date above Clock
            Text {
                text: root.dateString
                font.family: AppleTokens.textFont
                font.pixelSize: 16
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
                color: Qt.rgba(1.0, 1.0, 1.0, 0.88)
                Layout.alignment: Qt.AlignHCenter

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.4
                    shadowVerticalOffset: 1
                }
            }

            // Hero Clock Digits
            Text {
                text: root.timeString
                font.family: AppleTokens.displayFont
                font.pixelSize: 88
                font.weight: Font.DemiBold
                font.letterSpacing: -2.2
                color: AppleTokens.bodyOnDark
                Layout.alignment: Qt.AlignHCenter

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.6)
                    shadowBlur: 0.5
                    shadowVerticalOffset: 3
                }
            }
        }

        // Spacing between Clock and User
        Item {
            height: 8
            width: 1
        }

        // User Identity Card (Avatar + Name + Password Pill)
        UserIdentityCard {
            id: userCard
            buffer: pamAuth.buffer
            isError: pamAuth.isError
            errorMessage: pamAuth.errorMessage
            authenticating: pamAuth.authenticating
            Layout.alignment: Qt.AlignHCenter

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

    // 6. Bottom-Left: Concentric Media Live Activity
    MediaLiveActivityCard {
        id: mediaCard
        isPreview: root.isPreview
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        z: 15
    }

    // 7. Bottom-Right: System & Battery Complication Card
    SystemComplicationCard {
        id: systemCard
        anchors.right: parent.right
        anchors.rightMargin: 36
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        z: 15
    }
}
