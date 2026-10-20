pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

ColumnLayout {
    id: root

    property alias buffer: islandCapsule.buffer
    property alias authenticating: islandCapsule.authenticating
    property alias isError: islandCapsule.isError
    property alias errorMessage: islandCapsule.errorMessage
    property alias lockState: islandCapsule.lockState

    property bool showProfilePhoto: true
    property string avatarPath: ""
    property int avatarSize: 56

    signal submitRequested(string password)

    function triggerShake(): void {
        islandCapsule.triggerShake();
    }

    spacing: 9
    Layout.alignment: Qt.AlignHCenter

    // 1. Circular User Profile Picture Avatar
    Item {
        id: avatarWrapper
        Layout.alignment: Qt.AlignHCenter
        width: root.avatarSize
        height: root.avatarSize
        visible: root.showProfilePhoto

        // Fallback base
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
            font.pixelSize: root.avatarSize * 0.42
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

        // User Photo
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

        // Outer Ring & Drop Shadow
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

    // 2. Dynamic Island Password Input Capsule
    DynamicIslandLockCapsule {
        id: islandCapsule
        Layout.alignment: Qt.AlignHCenter

        onSubmitRequested: function(pwd) {
            root.submitRequested(pwd);
        }
    }
}
