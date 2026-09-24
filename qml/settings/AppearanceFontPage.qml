import QtQuick
import QtQuick.Controls

Flickable {
    id: root

    property var config: null
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string heroFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    contentWidth: width
    contentHeight: contentCol.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    signal openFontBrowser(string target)

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

        // ── Sezione 1: Stile Vetro & Trasparenza ────────────────────────
        SettingsHeader {
            text: "Stile Vetro & Trasparenza"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSlider {
                title: "Opacità Sfondo Isola"
                description: "Percentuale di copertura del vetro scuro matte"
                icon: "\uf043" // tint
                from: 30
                to: 100
                stepSize: 2
                suffix: "%"
                value: root.config ? root.config.islandBackgroundOpacity : 92
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("islandBackgroundOpacity", Math.round(val)); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSlider {
                title: "Sfocatura Vetro (Blur)"
                description: "Intensità dell'effetto frosted glass dietro i pannelli"
                icon: "\uf1fc" // magic/brush
                from: 8
                to: 48
                stepSize: 2
                suffix: "px"
                value: root.config ? root.config.blurRadius : 24
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("blurRadius", Math.round(val)); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: "Formato Orologio"
                description: "Visualizzazione delle ore nei moduli e nell'isola"
                model: [
                    { text: "24 Ore", value: "24h" },
                    { text: "12 Ore (AM/PM)", value: "12h" }
                ]
                currentValue: root.config ? root.config.clockFormat : "24h"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("clockFormat", val); }
            }
        }

        // ── Sezione 2: Colori & Temi Dinamici ───────────────────────────
        SettingsHeader {
            text: "Colori & Armonia Temi"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSwitch {
                title: "Palette Dinamica Pywal & Iris"
                description: "Estrae e sfuma i colori dell'accento in tempo reale dallo sfondo del desktop"
                icon: "\uf1fc" // paint-brush
                checked: root.config ? root.config.pywalEnabled : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("pywalEnabled", st); }
            }
        }

        // ── Sezione 3: Sfondo del Desktop ───────────────────────────────
        SettingsHeader {
            text: "Gestione Sfondi (Wallpaper)"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            Item {
                width: parent.width
                height: 48

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: Qt.rgba(255, 255, 255, 0.05)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "\uf03e" // image
                            color: root.accentColor
                            font.family: root.iconFontFamily
                            font.pixelSize: 14
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Cartella Raccolta Sfondi"
                            color: "#f2f4f8"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                        Text {
                            text: root.config ? root.config.wallpaperLibrary : "/home/lollo/Sfondi"
                            color: "#7e889b"
                            font.pixelSize: 11
                            font.family: root.textFontFamily
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 74
                    height: 28
                    radius: 6
                    color: Qt.rgba(255, 255, 255, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "Predefinito"
                        color: "#c2c7d4"
                        font.pixelSize: 11
                        font.family: root.textFontFamily
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            Item {
                width: parent.width
                height: 48

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: Qt.rgba(255, 255, 255, 0.05)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "\uf121" // terminal / code
                            color: root.accentColor
                            font.family: root.iconFontFamily
                            font.pixelSize: 14
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Comando Applicazione Sfondo"
                            color: "#f2f4f8"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                        Text {
                            text: root.config ? root.config.wallpaperCustomCommand : "/home/lollo/.scripts/apply-wallpaper.sh \"$1\""
                            color: "#7e889b"
                            font.pixelSize: 11
                            font.family: root.textFontFamily
                        }
                    }
                }
            }
        }

        // ── Sezione 4: Tipografia & Caratteri ───────────────────────────
        SettingsHeader {
            text: "Tipografia & Caratteri"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            // Preset Rapidi 1-Click
            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Preset Font Rapidi Globali (1 Click)"
                    color: "#9aa3b5"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.family: root.textFontFamily
                }

                Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: ["Google Sans Flex", "Inter", "JetBrains Mono", "Roboto", "Ubuntu", "Cantarell"]

                        Rectangle {
                            readonly property bool isCurrent: root.config && root.config.textFontFamily === modelData
                            width: chipText.contentWidth + 24
                            height: 28
                            radius: 14
                            color: isCurrent ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: isCurrent ? root.accentColor : Qt.rgba(255, 255, 255, 0.10)

                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: modelData
                                color: isCurrent ? "#ffffff" : "#c2c7d4"
                                font.pixelSize: 11
                                font.weight: isCurrent ? Font.DemiBold : Font.Normal
                                font.family: modelData
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.config) {
                                        root.config.set("textFontFamily", modelData);
                                        root.config.set("heroFontFamily", modelData);
                                        root.config.set("timeFontFamily", modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            // Font Testo
            Item {
                width: parent.width
                height: 48

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: Qt.rgba(255, 255, 255, 0.05)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "\uf031" // font
                            color: root.accentColor
                            font.family: root.iconFontFamily
                            font.pixelSize: 14
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Carattere Testo & Controlli"
                            color: "#f2f4f8"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                        Text {
                            text: root.config ? root.config.textFontFamily : "Google Sans Flex"
                            color: "#7e889b"
                            font.pixelSize: 11
                            font.family: root.textFontFamily
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 78
                    height: 28
                    radius: 6
                    color: fontBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.07)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "Sfoglia"
                        color: "#f2f4f8"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: root.textFontFamily
                    }

                    MouseArea {
                        id: fontBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openFontBrowser("text")
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            // Font Icone
            Item {
                width: parent.width
                height: 48

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: Qt.rgba(255, 255, 255, 0.05)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "\uf128" // icon question / symbols
                            color: root.accentColor
                            font.family: root.iconFontFamily
                            font.pixelSize: 14
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Carattere Icone & Glifi"
                            color: "#f2f4f8"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                        Text {
                            text: root.config ? root.config.iconFontFamily : "JetBrainsMono Nerd Font"
                            color: "#7e889b"
                            font.pixelSize: 11
                            font.family: root.textFontFamily
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 78
                    height: 28
                    radius: 6
                    color: fontIconBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.07)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "Sfoglia"
                        color: "#f2f4f8"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.family: root.textFontFamily
                    }

                    MouseArea {
                        id: fontIconBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openFontBrowser("icon")
                    }
                }
            }
        }
    }
}
