import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

ColumnLayout {
    id: root

    property alias buffer: pwdInput.buffer
    property alias isError: pwdInput.isError
    property alias errorMessage: pwdInput.errorMessage
    property alias authenticating: pwdInput.authenticating
    property string userName: "Lorenzo"
    property string avatarPath: Quickshell.env("HOME") + "/Immagineprofilo/lollo.png"

    signal submitRequested(string password)

    spacing: 10
    Layout.alignment: Qt.AlignHCenter

    // 1. MacBook Circular Avatar (68x68)
    Item {
        id: avatarWrapper
        Layout.alignment: Qt.AlignHCenter
        width: 68
        height: 68

        // Fallback circle
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: AppleTokens.surfaceTile1
            border.width: 1
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.15)
        }

        Text {
            anchors.centerIn: parent
            visible: pfpImg.status !== Image.Ready
            text: ""
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 26
            color: Qt.rgba(1.0, 1.0, 1.0, 0.5)
        }

        // Circular mask with layer.enabled
        Rectangle {
            id: maskShape
            anchors.fill: parent
            radius: width / 2
            color: "black"
            layer.enabled: true
            visible: false
        }

        // Profile picture
        Image {
            id: pfpImg
            anchors.fill: parent
            source: root.avatarPath !== "" ? "file://" + root.avatarPath : ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: maskShape
                maskSpreadAtMin: 1
                maskThresholdMin: 0.5
            }
        }

        // Thin Hairline Border
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1.5
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.35)
            z: 5

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowBlur: 0.4
                shadowVerticalOffset: 2
            }
        }
    }

    // 2. User Name (MacBook exact size 15-16px)
    Text {
        text: root.userName
        font.family: AppleTokens.displayFont
        font.pixelSize: 16
        font.weight: Font.DemiBold
        color: AppleTokens.bodyOnDark
        Layout.alignment: Qt.AlignHCenter

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.6)
            shadowBlur: 0.3
            shadowVerticalOffset: 1
        }
    }

    // 3. Compact Password Input Pill
    PasswordPillInput {
        id: pwdInput
        Layout.alignment: Qt.AlignHCenter
        onSubmitRequested: function(pwd) {
            root.submitRequested(pwd);
        }
    }
}
