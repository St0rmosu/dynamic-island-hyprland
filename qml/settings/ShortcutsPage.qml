import QtQuick
import QtQuick.Controls
import Quickshell

Flickable {
    id: root

    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    contentWidth: width
    contentHeight: contentCol.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    readonly property var shortcutsList: [
        {
            title: "Workspace Overview",
            desc: "Visualizzatore interattivo di tutti i workspace e finestre aperte",
            icon: "\uf108",
            keys: ["SUPER", "Tab"],
            action: "overview"
        },
        {
            title: "Power Menu (Wlogout)",
            desc: "Menu rapido per Blocca, Esci, Sospendi, Riavvia, Spegni",
            icon: "\uf011",
            keys: ["SUPER", "P"],
            action: "power"
        },
        {
            title: "Notification Center",
            desc: "Pannello con cronologia notifiche e cancellazione",
            icon: "\uf0f3",
            keys: ["SUPER", "N"],
            action: "notifications"
        },
        {
            title: "Wallpaper Switcher",
            desc: "Selettore a schede per cambiare sfondo con animazione",
            icon: "\uf03e",
            keys: ["SUPER", "ALT", "Spazio"],
            action: "master-or-wallpaper"
        },
        {
            title: "Application Launcher",
            desc: "Ricerca rapida e avvio delle applicazioni installate",
            icon: "\uf135", // rocket
            keys: ["ALT", "Spazio"],
            action: "apps"
        },
        {
            title: "File Shelf",
            desc: "Cassetto rapido per trascinare e incollare file al volo",
            icon: "\uf07b",
            keys: ["SUPER", "O"],
            action: "files"
        },
        {
            title: "Clipboard History",
            desc: "Cronologia degli appunti con testi, codici e immagini",
            icon: "\uf0ea",
            keys: ["SUPER", "C"],
            action: "clipboard"
        }
    ]

    ScrollBar.vertical: ScrollBar {
        width: 4
        anchors.right: parent.right
        anchors.rightMargin: 2
        policy: ScrollBar.AsNeeded
    }

    Column {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        spacing: 20

        // ── Sezione 1: Scorciatoie Attive ──────────────────────────────
        SettingsHeader {
            text: "Scorciatoie Configurate in Hyprland"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            Repeater {
                model: root.shortcutsList

                Column {
                    width: parent.width
                    spacing: 10

                    Item {
                        width: parent.width
                        height: 52

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: actionControls.left
                            anchors.rightMargin: 16
                            spacing: 12

                            Rectangle {
                                width: 34
                                height: 34
                                radius: 8
                                color: Qt.rgba(255, 255, 255, 0.05)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: root.accentColor
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 14
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.title
                                    color: "#f2f4f8"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    font.family: root.textFontFamily
                                }

                                Text {
                                    text: modelData.desc
                                    color: "#7e889b"
                                    font.pixelSize: 11
                                    font.family: root.textFontFamily
                                }
                            }
                        }

                        Row {
                            id: actionControls
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            // Key Badge Chips
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Repeater {
                                    id: keysRepeater
                                    model: modelData.keys

                                    Row {
                                        spacing: 4
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            width: keyText.contentWidth + 16
                                            height: 24
                                            radius: 6
                                            color: Qt.rgba(255, 255, 255, 0.07)
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.12)

                                            Text {
                                                id: keyText
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: "#d8dce6"
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                                font.family: root.textFontFamily
                                            }
                                        }

                                        Text {
                                            visible: index < keysRepeater.count - 1
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "+"
                                            color: "#6c7280"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                            }

                            // Pulsante Prova Rapida [ ▶ ]
                            Rectangle {
                                width: 30
                                height: 26
                                radius: 6
                                color: testMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.30) : Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: testMouse.containsMouse ? root.accentColor : Qt.rgba(255, 255, 255, 0.10)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "▶"
                                    color: testMouse.containsMouse ? "#ffffff" : "#c2c7d4"
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: testMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "/home/lollo/.scripts/shell-dispatcher.sh " + modelData.action]);
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: index < root.shortcutsList.length - 1
                        width: parent.width
                        height: 1
                        color: Qt.rgba(255, 255, 255, 0.05)
                    }
                }
            }
        }

        // ── Sezione 2: Snippet di Configurazione Lua ────────────────────
        SettingsHeader {
            text: "Configurazione Hyprland (Lua)"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            Text {
                text: "I tasti sopra sono collegati a ~/.config/hypr/moduli/binds.lua tramite lo script shell-dispatcher.sh:"
                color: "#7e889b"
                font.pixelSize: 11
                font.family: root.textFontFamily
            }

            Rectangle {
                width: parent.width
                height: 120
                radius: 10
                color: "#080a0f"
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.06)

                Text {
                    anchors.fill: parent
                    anchors.margins: 10
                    text: 'hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh overview"))\n' +
                          'hl.bind(mainMod .. " + P",   hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh power"))\n' +
                          'hl.bind(mainMod .. " + N",   hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh notifications"))\n' +
                          'hl.bind(mainMod .. " + ALT + space", hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh master-or-wallpaper"))\n' +
                          'hl.bind("ALT + space",       hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh apps"))\n' +
                          'hl.bind(mainMod .. " + O",   hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh files"))\n' +
                          'hl.bind(mainMod .. " + C",   hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh clipboard"))'
                    color: "#a4b1cd"
                    font.family: root.iconFontFamily
                    font.pixelSize: 10
                    wrapMode: Text.WrapAnywhere
                }
            }
        }
    }
}
