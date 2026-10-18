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

    spacing: 14
    Layout.alignment: Qt.AlignHCenter

    // 1. Circular Avatar (88x88)
    Item {
        id: avatarWrapper
        Layout.alignment: Qt.AlignHCenter
        width: 88
        height: 88

        // Fallback placeholder circle
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
            font.pixelSize: 32
            color: Qt.rgba(1.0, 1.0, 1.0, 0.5)
        }

        // Mask shape with layer.enabled
        Rectangle {
            id: maskShape
            anchors.fill: parent
            radius: width / 2
            color: "black"
            layer.enabled: true
            visible: false
        }

        // Profile image masked into a perfect circle
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

        // Frosted Glass Border Ring
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.4)
            z: 5

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.5)
                shadowBlur: 0.5
                shadowVerticalOffset: 3
            }
        }
    }

    // 2. User Name
    Text {
        text: root.userName
        font.family: AppleTokens.displayFont
        font.pixelSize: 21
        font.weight: Font.DemiBold
        font.letterSpacing: AppleTokens.letterSpacingBody
        color: AppleTokens.bodyOnDark
        Layout.alignment: Qt.AlignHCenter

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.7)
            shadowBlur: 0.4
            shadowVerticalOffset: 2
        }
    }

    // 3. Password Input Pill
    PasswordPillInput {
        id: pwdInput
        Layout.alignment: Qt.AlignHCenter
        onSubmitRequested: function(pwd) {
            root.submitRequested(pwd);
        }
    }
}
