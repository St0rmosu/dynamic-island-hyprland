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
        let s = Qt.formatDate(root.now, "dddd, d MMMM");
        return s.toUpperCase();
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

    // 1. Solid opaque base (prevents any window leakage)
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0c"
    }

    // 2. Wallpaper Layer with Apple Museum MultiEffect Blur
    Image {
        id: bgWallpaper
        anchors.fill: parent
        source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        asynchronous: true

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 0.9
            blurMax: 64
            saturation: 0.3
        }
    }

    // 3. Dark Museum Tint Overlay
    Rectangle {
        anchors.fill: parent
        color: AppleTokens.surfaceBlack
        opacity: 0.42
    }

    // 4. Dynamic Island Top Capsule (iOS Lockscreen style)
    DynamicIslandLockCapsule {
        id: islandCapsule
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        z: 10
    }

    // 5. Main Center Column (iOS 18 Layout)
    Item {
        anchors.fill: parent
        anchors.topMargin: 70
        anchors.bottomMargin: 90

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 24

            // --- iOS Hero Date & Clock ---
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                // Date above Clock (Authentic iOS)
                Text {
                    text: root.dateString
                    font.family: AppleTokens.textFont
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.82)
                    Layout.alignment: Qt.AlignHCenter

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.5)
                        shadowBlur: 0.3
                        shadowVerticalOffset: 1
                    }
                }

                // Massive Hero Time Digits
                Text {
                    text: root.timeString
                    font.family: AppleTokens.displayFont
                    font.pixelSize: 108
                    font.weight: Font.DemiBold
                    font.letterSpacing: -2.5
                    color: AppleTokens.bodyOnDark
                    Layout.alignment: Qt.AlignHCenter

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.55)
                        shadowBlur: 0.5
                        shadowVerticalOffset: 4
                    }
                }
            }

            // --- Media Live Activity Card ---
            MediaLiveActivityCard {
                id: mediaCard
                isPreview: root.isPreview
                Layout.alignment: Qt.AlignHCenter
            }

            // --- Password Input Pill ({component.search-input} style) ---
            PasswordPillInput {
                id: pwdInput
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
    }

    // 6. Bottom Quick Action Circular Buttons (Flashlight & Screen Off)
    Rectangle {
        id: leftActionBtn
        anchors.left: parent.left
        anchors.leftMargin: 52
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44
        width: 50
        height: 50
        radius: 25
        color: AppleTokens.surfaceGlassInput
        border.width: 1
        border.color: AppleTokens.hairlineDark

        scale: leftBtnMouse.pressed ? AppleTokens.pressScale : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 0.4
            shadowVerticalOffset: 2
        }

        Text {
            anchors.centerIn: parent
            text: "󰌵"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 21
            color: AppleTokens.bodyOnDark
        }

        MouseArea {
            id: leftBtnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(["sh", "-c", "pkill -USR1 gammastep || pkill -USR1 wlsunset || hyprsunset --toggle || true"]);
            }
        }
    }

    Rectangle {
        id: rightActionBtn
        anchors.right: parent.right
        anchors.rightMargin: 52
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44
        width: 50
        height: 50
        radius: 25
        color: AppleTokens.surfaceGlassInput
        border.width: 1
        border.color: AppleTokens.hairlineDark

        scale: rightBtnMouse.pressed ? AppleTokens.pressScale : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 0.4
            shadowVerticalOffset: 2
        }

        Text {
            anchors.centerIn: parent
            text: "󰍹"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: AppleTokens.bodyOnDark
        }

        MouseArea {
            id: rightBtnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "off"]);
            }
        }
    }
}
