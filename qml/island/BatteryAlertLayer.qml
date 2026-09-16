import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    property string mode: "charging" // "charging" | "low_battery"
    property int capacity: 100
    property bool showCondition: true
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    property string iconFontFamily: userConfig.iconFontFamily

    readonly property color themeColor: mode === "charging" ? "#30d158" : "#ff453a"
    readonly property string labelText: mode === "charging" ? "Charging" : "Low Battery"

    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18

        // Left: "Charging" or "Low Battery" text
        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.labelText
            color: "#ffffff"
            font.family: root.textFontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.letterSpacing: -0.2
        }

        // Right: Percentage + Apple-styled Battery Pill + Lightning
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Percentage Text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.capacity + "%"
                color: root.themeColor
                font.family: root.heroFontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                font.letterSpacing: -0.2
            }

            // Battery Outline & Fill
            Item {
                width: 28
                height: 14
                anchors.verticalCenter: parent.verticalCenter

                // Battery Body
                Rectangle {
                    width: 25
                    height: 13
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    radius: 3.5
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.themeColor

                    // Battery Fill Level
                    Rectangle {
                        x: 2
                        y: 2
                        height: parent.height - 4
                        width: Math.max(2, Math.min(parent.width - 4, (parent.width - 4) * (root.capacity / 100.0)))
                        radius: 1.5
                        color: root.themeColor

                        Behavior on width {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutBack
                            }
                        }
                    }

                    // Lightning bolt icon inside battery if charging
                    Text {
                        anchors.centerIn: parent
                        visible: root.mode === "charging"
                        text: "⚡"
                        color: root.capacity > 45 ? "#000000" : root.themeColor
                        font.pixelSize: 8
                    }

                    // Exclamation mark inside battery if low battery
                    Text {
                        anchors.centerIn: parent
                        visible: root.mode === "low_battery"
                        text: "!"
                        color: root.capacity > 45 ? "#000000" : "#ffffff"
                        font.family: root.heroFontFamily
                        font.weight: Font.Black
                        font.pixelSize: 9
                    }
                }

                // Battery Terminal Tip (+ pole)
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 25
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 5
                    radius: 1
                    color: root.themeColor
                }
            }
        }
    }
}
