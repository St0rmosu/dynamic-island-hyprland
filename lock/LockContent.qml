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

    // Battery info for top-right macOS menu bar
    property int batteryLevel: 45
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

    // 2. Wallpaper Layer: 100% sharp, pure Apple photography presentation
    Image {
        id: bgWallpaper
        anchors.fill: parent
        source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        asynchronous: true
    }

    // 3. Subtle macOS Scrim Gradients (Top & Bottom)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 120
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.4) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 200
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
        }
    }

    // 4. macOS Top Bar
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 38
        z: 20

        // Top-Center: Discreet Dynamic Island Capsule
        DynamicIslandLockCapsule {
            id: islandCapsule
            anchors.centerIn: parent
        }

        // Top-Right: macOS Menu Bar Status
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryLevel + "%"
                font.family: AppleTokens.textFont
                font.pixelSize: 12
                font.weight: Font.Normal
                color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.batteryStatus === "Charging" ? "󰂄" : "󰂀"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰖩"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "IT"
                font.family: AppleTokens.textFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Qt.rgba(1.0, 1.0, 1.0, 0.85)
            }
        }
    }

    // 5. Upper Third: MacBook Clock & Date
    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: 120
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        z: 10

        // Time (SF Pro Display, Light 300, 80px)
        Text {
            text: root.timeString
            font.family: AppleTokens.displayFont
            font.pixelSize: 82
            font.weight: Font.Light
            font.letterSpacing: -1.5
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

        // Date (SF Pro Text, Normal, 17px)
        Text {
            text: root.dateString
            font.family: AppleTokens.textFont
            font.pixelSize: 17
            font.weight: Font.Normal
            font.letterSpacing: 0.2
            color: Qt.rgba(1.0, 1.0, 1.0, 0.9)
            Layout.alignment: Qt.AlignHCenter

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.4
                shadowVerticalOffset: 1
            }
        }
    }

    // 6. Lower Third: MacBook User Login (Avatar + Name + Compact Pill)
    UserIdentityCard {
        id: userCard
        buffer: pamAuth.buffer
        isError: pamAuth.isError
        errorMessage: pamAuth.errorMessage
        authenticating: pamAuth.authenticating
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 110
        anchors.horizontalCenter: parent.horizontalCenter
        z: 10

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
