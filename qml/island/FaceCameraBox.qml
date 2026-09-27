import QtQuick
import QtQuick.Controls
import QtMultimedia
import Qt5Compat.GraphicalEffects

Item {
    id: root

    width: 140
    height: 140
    property real radius: 22

    property bool active: true
    property bool isSuccess: false
    property bool isFailed: false
    property color accentColor: "#30d158"
    property string iconFontFamily: "Symbols Nerd Font"
    property string textFontFamily: "Inter"

    signal clicked()

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

    // Mask for true rounded corners on the camera view
    Rectangle {
        id: cameraMask
        width: root.width
        height: root.height
        radius: root.radius
        visible: false
    }

    // Rounded camera content container masked with OpacityMask
    Item {
        id: videoContainer
        anchors.fill: parent
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: cameraMask
        }

        // Deep dark background
        Rectangle {
            anchors.fill: parent
            color: "#0a0e14"
        }

        // Live Video Feed from Webcam / IR camera
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
                width: 68
                height: 68
                radius: 34
                color: Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.25)

                Text {
                    anchors.centerIn: parent
                    text: "\udb80\ude37"
                    font.family: root.iconFontFamily
                    font.pixelSize: 34
                    color: Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.55)
                }
            }
        }

        // Subtle dark vignette for high-tech HUD contrast
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Qt.rgba(255, 255, 255, 0.06)
            border.width: 1
            radius: root.radius
        }

        // Biometric Target Reticle (Central Oval Guide)
        Rectangle {
            id: targetReticle
            anchors.centerIn: parent
            width: 66
            height: 86
            radius: 33
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

        // Live Laser Beam Scanner
        Rectangle {
            id: scanLine
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 24
            height: 2
            color: root.accentColor
            opacity: root.active && !root.isSuccess ? 0.9 : 0
            visible: opacity > 0

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 14
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
                NumberAnimation { from: 14; to: root.height - 18; duration: 1500; easing.type: Easing.InOutSine }
                NumberAnimation { from: root.height - 18; to: 14; duration: 1500; easing.type: Easing.InOutSine }
            }
        }
    }

    // Outer Rounded Border Overlay with dynamic glow
    Rectangle {
        id: roundedBorder
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: root.isSuccess
            ? "#30d158"
            : (root.isFailed ? "#ff453a" : Qt.rgba(48 / 255, 209 / 255, 88 / 255, 0.45))
        border.width: root.isSuccess ? 2.5 : 1.8
        z: 2

        Behavior on border.color {
            ColorAnimation { duration: 180 }
        }

        Behavior on border.width {
            NumberAnimation { duration: 180 }
        }
    }

    // High-tech Corner Brackets HUD [  ] sitting comfortably inside the rounded corner
    // Top-Left
    Rectangle { x: 13; y: 13; width: 11; height: 2; radius: 1; color: root.accentColor; z: 3 }
    Rectangle { x: 13; y: 13; width: 2; height: 11; radius: 1; color: root.accentColor; z: 3 }

    // Top-Right
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 13; y: 13; width: 11; height: 2; radius: 1; color: root.accentColor; z: 3 }
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 13; y: 13; width: 2; height: 11; radius: 1; color: root.accentColor; z: 3 }

    // Bottom-Left
    Rectangle { x: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 13; width: 11; height: 2; radius: 1; color: root.accentColor; z: 3 }
    Rectangle { x: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 13; width: 2; height: 11; radius: 1; color: root.accentColor; z: 3 }

    // Bottom-Right
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 13; width: 11; height: 2; radius: 1; color: root.accentColor; z: 3 }
    Rectangle { anchors.right: parent.right; anchors.rightMargin: 13; anchors.bottom: parent.bottom; anchors.bottomMargin: 13; width: 2; height: 11; radius: 1; color: root.accentColor; z: 3 }

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
        z: 3

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
        z: 4
        onClicked: root.clicked()
    }
}
