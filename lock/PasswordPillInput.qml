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

    implicitWidth: 320
    implicitHeight: 74 // 44px pill + 30px label below

    Rectangle {
        id: pillBox
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: 44
        radius: height / 2

        color: AppleTokens.surfaceGlassInput
        border.width: root.hasFocusState ? 2 : 1
        border.color: {
            if (root.isError) return AppleTokens.errorRed;
            if (root.hasFocusState) return AppleTokens.primaryFocus;
            return AppleTokens.hairlineDark;
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.3)
            shadowBlur: 0.4
            shadowVerticalOffset: 2
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 6
            spacing: 10

            // Leading glyph
            Text {
                text: "󰌾"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: root.isError ? AppleTokens.errorRed : AppleTokens.inkMuted48
                Layout.alignment: Qt.AlignVCenter
            }

            // Password dots or placeholder
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                // Placeholder
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    visible: root.buffer.length === 0
                    text: "Inserisci password..."
                    font.family: AppleTokens.textFont
                    font.pixelSize: 15
                    font.weight: Font.Normal
                    font.letterSpacing: AppleTokens.letterSpacingBody
                    color: AppleTokens.inkMuted48
                }

                // Animated Dots
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    spacing: 7
                    visible: root.buffer.length > 0

                    Repeater {
                        model: root.buffer.length

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: root.isError ? AppleTokens.errorRed : AppleTokens.bodyOnDark

                            scale: 0
                            Component.onCompleted: {
                                dotAnim.start();
                            }

                            NumberAnimation on scale {
                                id: dotAnim
                                from: 0.2
                                to: 1.0
                                duration: 160
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }
            }

            // Action Blue Submit Button
            Rectangle {
                id: submitBtn
                width: 32
                height: 32
                radius: height / 2
                color: AppleTokens.primaryOnDark // #2997ff
                visible: root.buffer.length > 0 || root.authenticating

                scale: btnMouse.pressed ? AppleTokens.pressScale : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 100 }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.authenticating ? "󰑮" : "➔"
                    font.family: root.authenticating ? "JetBrainsMono Nerd Font" : AppleTokens.textFont
                    font.pixelSize: root.authenticating ? 14 : 15
                    font.weight: Font.DemiBold
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

    // Caption / Error Label
    Text {
        anchors.top: pillBox.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.isError ? (root.errorMessage || "Password non corretta. Riprova.") : "Premi Invio o tocca il sensore d'impronta"
        font.family: AppleTokens.textFont
        font.pixelSize: 13
        font.weight: Font.Normal
        font.letterSpacing: AppleTokens.letterSpacingBody
        color: root.isError ? AppleTokens.errorRed : AppleTokens.inkMuted48

        Behavior on color {
            ColorAnimation { duration: 180 }
        }
    }
}
