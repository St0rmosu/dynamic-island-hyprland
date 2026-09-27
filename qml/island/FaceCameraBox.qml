import QtQuick
import QtQuick.Controls
import QtMultimedia

Rectangle {
    id: root

    width: 140
    height: 140
    radius: 18
    color: "#0a0e14"
    border.color: root.isSuccess
        ? "#30d158"
        : (root.isFailed ? "#ff453a" : Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.35))
    border.width: root.isSuccess ? 2 : 1.5
    clip: true

    property bool active: true
    property bool isSuccess: false
    property bool isFailed: false
    property color accentColor: "#30d158"
    property string iconFontFamily: "Symbols Nerd Font"
    property string textFontFamily: "Inter"

    signal clicked()

    Behavior on border.color {
        ColorAnimation { duration: 180 }
    }

    Behavior on border.width {
        NumberAnimation { duration: 180 }
    }

    // Hardware camera detection and stream
    MediaDevices {
        id: mediaDevices
    }

    readonly property bool hasCamera: mediaDevices.videoInputs.length > 0
    readonly property string cameraLabel: {
        if (hasCamera && mediaDevices.defaultVideoInput) {
            const desc = mediaDevices.defaultVideoInput.description || "";
            return desc.split(":")[0].trim() || "Webcam";
        }
        return "IR Camera";
    }

    CaptureSession {
        id: captureSession
        camera: Camera {
            id: camera
            active: root.active && root.hasCamera && !root.isSuccess
        }
        videoOutput: videoOutput
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root.hasCamera && camera.active && !root.isSuccess
    }

    // Biometric scanner fallback silhouette when no physical camera is attached
    Item {
        anchors.fill: parent
        visible: !root.hasCamera || !camera.active

        Rectangle {
            anchors.centerIn: parent
            width: 70
            height: 70
            radius: 35
            color: Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.08)
            border.width: 1
            border.color: Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.25)

            Text {
                anchors.centerIn: parent
                text: "\udb80\ude37" // fallback biometric glyph
                font.family: root.iconFontFamily
                font.pixelSize: 36
                color: Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.5)
            }
        }
    }

    // Subtle dark vignette for high-tech HUD contrast
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Qt.rgba(255, 255, 255, 0.08)
        border.width: 1
        radius: parent.radius
    }

    // Biometric Target Reticle (Central Oval Guide)
    Rectangle {
        id: targetReticle
        anchors.centerIn: parent
        width: 68
        height: 88
        radius: 34
        color: "transparent"
        border.width: 1
        border.color: root.isSuccess
            ? "#30d158"
            : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)
        opacity: root.isSuccess ? 0 : 0.85

        Behavior on opacity {
            NumberAnimation { duration: 160 }
        }
    }

    // High-tech Corner Brackets HUD [  ]
    // Top-Left
    Rectangle { x: 8; y: 8; width: 12; height: 2; color: root.accentColor }
    Rectangle { x: 8; y: 8; width: 2; height: 12; color: root.accentColor }

    // Top-Right
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; y: 8; width: 12; height: 2; color: root.accentColor }
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; y: 8; width: 2; height: 12; color: root.accentColor }

    // Bottom-Left
    Rectangle { x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: 12; height: 2; color: root.accentColor }
    Rectangle { x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: 2; height: 12; color: root.accentColor }

    // Bottom-Right
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: 12; height: 2; color: root.accentColor }
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 8; width: 2; height: 12; color: root.accentColor }

    // Live Laser Beam Scanner
    Rectangle {
        id: scanLine
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 20
        height: 2
        color: root.accentColor
        opacity: root.active && !root.isSuccess ? 0.9 : 0
        visible: opacity > 0

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 12
            opacity: 0.3
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.accentColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        SequentialAnimation on y {
            running: root.active && !root.isSuccess
            loops: Animation.Infinite
            NumberAnimation { from: 12; to: root.height - 16; duration: 1500; easing.type: Easing.InOutSine }
            NumberAnimation { from: root.height - 16; to: 12; duration: 1500; easing.type: Easing.InOutSine }
        }
    }

    // Top Live Camera Indicator Badge
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        height: 18
        width: liveBadgeRow.width + 14
        radius: 9
        color: Qt.rgba(0, 0, 0, 0.72)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.15)
        opacity: root.isSuccess ? 0 : 1

        Row {
            id: liveBadgeRow
            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: root.accentColor

                SequentialAnimation on opacity {
                    running: root.active && !root.isSuccess
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.cameraLabel
                font.family: root.textFontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: "#ffffff"
            }
        }
    }

    MouseArea {
        id: boxMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
