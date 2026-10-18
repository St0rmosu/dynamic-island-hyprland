import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    property string buffer: ""
    property bool isError: false
    property string errorMessage: ""
    property bool authenticating: false
    property bool hasFocusState: true

    signal submitRequested(string password)

    implicitWidth: 210
    implicitHeight: 56 // 32px pill + 24px label below

    Rectangle {
        id: pillBox
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: 32
        radius: height / 2

        color: Qt.rgba(0.0, 0.0, 0.0, 0.4)
        border.width: 1
        border.color: {
            if (root.isError) return AppleTokens.errorRed;
            if (root.hasFocusState) return Qt.rgba(1.0, 1.0, 1.0, 0.45);
            return Qt.rgba(1.0, 1.0, 1.0, 0.22);
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowBlur: 0.3
            shadowVerticalOffset: 2
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 4
            spacing: 8

            // Password dots or placeholder
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // Placeholder (MacBook exact)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    visible: root.buffer.length === 0
                    text: "Inserisci la password"
                    font.family: AppleTokens.textFont
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.55)
                }

                // Animated Dots
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    spacing: 6
                    visible: root.buffer.length > 0

                    Repeater {
                        model: root.buffer.length

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: root.isError ? AppleTokens.errorRed : AppleTokens.bodyOnDark

                            scale: 0
                            Component.onCompleted: {
                                dotAnim.start();
                            }

                            NumberAnimation on scale {
                                id: dotAnim
                                from: 0.2
                                to: 1.0
                                duration: 140
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }
            }

            // Arrow Submit Button (MacBook circular icon)
            Rectangle {
                id: submitBtn
                width: 24
                height: 24
                radius: 12
                color: root.buffer.length > 0 ? Qt.rgba(1.0, 1.0, 1.0, 0.25) : "transparent"
                visible: root.buffer.length > 0 || root.authenticating

                scale: btnMouse.pressed ? AppleTokens.pressScale : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.authenticating ? "󰑮" : "➔"
                    font.family: root.authenticating ? "JetBrainsMono Nerd Font" : AppleTokens.textFont
                    font.pixelSize: root.authenticating ? 12 : 13
                    font.weight: Font.Normal
                    color: AppleTokens.bodyOnDark

                    RotationAnimation on rotation {
                        running: root.authenticating
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 800
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.authenticating && root.buffer.length > 0) {
                            root.submitRequested(root.buffer);
                        }
                    }
                }
            }
        }
    }

    // Subtitle / Error message (MacBook Touch ID hint)
    Text {
        anchors.top: pillBox.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.isError ? (root.errorMessage || "Password non corretta.") : "Usa Touch ID o inserisci la password"
        font.family: AppleTokens.textFont
        font.pixelSize: 11
        font.weight: Font.Normal
        color: root.isError ? AppleTokens.errorRed : Qt.rgba(1.0, 1.0, 1.0, 0.65)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.7)
            shadowBlur: 0.3
            shadowVerticalOffset: 1
        }
    }
}
