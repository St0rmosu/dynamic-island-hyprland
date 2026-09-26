import QtQuick

Item {
    id: root

    property string timeText: ""
    property color color: "#ffffff"
    property string fontFamily: "Google Sans Flex"
    property int fontPixelSize: 15
    property int fontWeight: Font.Bold
    property real fontLetterSpacing: -0.25
    property int animationDuration: 380

    implicitWidth: digitsRow.implicitWidth
    implicitHeight: Math.ceil(fontPixelSize * 1.5)

    Row {
        id: digitsRow

        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.timeText.length

            Item {
                id: digitItem

                readonly property int digitIndex: index
                readonly property string targetChar: (index < root.timeText.length) ? root.timeText.charAt(index) : ""
                property string displayedChar: ""
                property string departingChar: ""
                property bool initialized: false
                readonly property real slideDistance: Math.max(14, Math.round(charMetrics.height * 0.9))

                width: Math.max(charMetrics.advanceWidth, 1)
                height: Math.ceil(charMetrics.height + 4)
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                onTargetCharChanged: {
                    if (!initialized) {
                        displayedChar = targetChar;
                        initialized = true;
                        return ;
                    }
                    if (targetChar === displayedChar)
                        return ;

                    departingChar = displayedChar;
                    displayedChar = targetChar;
                    // If it's a static separator (colon or space), update without animation
                    if (targetChar === ":" || targetChar === " " || departingChar === ":" || departingChar === " ") {
                        currentLabel.anchors.verticalCenterOffset = 0;
                        currentLabel.opacity = 1;
                        currentLabel.scale = 1;
                        departingLabel.opacity = 0;
                        return ;
                    }
                    flipAnim.stop();
                    flipAnim.start();
                }
                Component.onCompleted: {
                    displayedChar = targetChar;
                    initialized = true;
                }

                TextMetrics {
                    id: charMetrics

                    font.family: root.fontFamily
                    font.pixelSize: root.fontPixelSize
                    font.weight: root.fontWeight
                    font.letterSpacing: root.fontLetterSpacing
                    text: digitItem.targetChar !== "" ? digitItem.targetChar : "0"
                }

                Text {
                    id: departingLabel

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 0
                    text: digitItem.departingChar
                    color: root.color
                    font.family: root.fontFamily
                    font.pixelSize: root.fontPixelSize
                    font.weight: root.fontWeight
                    font.letterSpacing: root.fontLetterSpacing
                    opacity: 0
                    visible: opacity > 0.01

                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }

                    }

                }

                Text {
                    id: currentLabel

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 0
                    text: digitItem.displayedChar
                    color: root.color
                    font.family: root.fontFamily
                    font.pixelSize: root.fontPixelSize
                    font.weight: root.fontWeight
                    font.letterSpacing: root.fontLetterSpacing
                    opacity: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }

                    }

                }

                ParallelAnimation {
                    id: flipAnim

                    onFinished: {
                        departingLabel.opacity = 0;
                        departingLabel.text = "";
                    }

                    NumberAnimation {
                        target: departingLabel
                        property: "anchors.verticalCenterOffset"
                        from: 0
                        to: -digitItem.slideDistance
                        duration: root.animationDuration
                        easing.type: Easing.OutQuint
                    }

                    NumberAnimation {
                        target: departingLabel
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: Math.round(root.animationDuration * 0.65)
                        easing.type: Easing.InQuad
                    }

                    NumberAnimation {
                        target: departingLabel
                        property: "scale"
                        from: 1
                        to: 0.82
                        duration: root.animationDuration
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: currentLabel
                        property: "anchors.verticalCenterOffset"
                        from: digitItem.slideDistance
                        to: 0
                        duration: root.animationDuration
                        easing.type: Easing.OutQuint
                    }

                    NumberAnimation {
                        target: currentLabel
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Math.round(root.animationDuration * 0.75)
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        target: currentLabel
                        property: "scale"
                        from: 0.82
                        to: 1
                        duration: root.animationDuration
                        easing.type: Easing.OutQuint
                    }

                }

            }

        }

    }

}
