import QtQuick
import QtQuick.Layouts
import IslandBackend

Item {
    id: root

    property string statusText: I18n.tr("Clicca finestra o trascina")
    property bool sattyDirectMode: false
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property color accentColor: "#bdb6a6"
    property color textColor: "#c8c3b6"
    property color dimColor: "#606c75"
    property color surfaceColor: "#2e383f"

    signal fullscreenRequested()
    signal sattyToggleRequested()
    signal cancelRequested()

    anchors.fill: parent

    readonly property bool isDraggingArea: root.statusText.indexOf("×") !== -1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 8

        // 1. Badge Fotocamera mini
        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            radius: 12
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
            border.width: 1
            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)

            Text {
                anchors.centerIn: parent
                text: "\uf030"
                color: root.accentColor
                font.family: root.iconFontFamily
                font.pixelSize: 11
            }
        }

        // 2. Info Testo compatto adattivo
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                text: root.isDraggingArea ? root.statusText : (root.sattyDirectMode ? I18n.tr("Modifica diretta") : I18n.tr("Cattura schermo"))
                color: root.isDraggingArea || root.sattyDirectMode ? root.accentColor : root.textColor
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.family: root.textFontFamily
                elide: Text.ElideRight
            }
        }

        // 3. Mini Pulsanti rapidi circolari
        RowLayout {
            id: btnRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            // Pulsante: Cattura Schermo Intero (Fullscreen)
            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                color: maFull.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: maFull.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: "\uf108"
                    color: maFull.containsMouse ? root.accentColor : root.textColor
                    font.family: root.iconFontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: maFull
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.fullscreenRequested()
                }
            }

            // Pulsante: Toggle Modalità Editor In-Island
            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                color: root.sattyDirectMode ? root.accentColor : (maEditor.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22) : Qt.rgba(255, 255, 255, 0.08))
                border.width: 1
                border.color: root.sattyDirectMode ? root.accentColor : (maEditor.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.12))

                Text {
                    anchors.centerIn: parent
                    text: "\uf040"
                    color: root.sattyDirectMode ? "#000000" : (maEditor.containsMouse ? root.accentColor : root.textColor)
                    font.family: root.iconFontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: maEditor
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sattyToggleRequested()
                }
            }

            // Pulsante: Annulla (Esc)
            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                color: maClose.containsMouse ? Qt.rgba(208/255, 191/255, 146/255, 0.25) : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: maClose.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    color: maClose.containsMouse ? root.accentColor : root.dimColor
                    font.family: root.iconFontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: maClose
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancelRequested()
                }
            }
        }
    }
}
