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
                title: "Palette Dinamica"
                description: "Estrae e sfuma i colori dell'accento in tempo reale dallo sfondo del desktop"
                icon: "\uf1fc" // paint-brush
                checked: root.config ? root.config.pywalEnabled : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("pywalEnabled", st); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: "Motore Palette Compatibile"
                description: "Scegli o rileva automaticamente il generatore di colori del tuo sistema"
                model: [
                    { text: "Auto", value: "auto" },
                    { text: "Pywal", value: "pywal" },
                    { text: "Wallust", value: "wallust" },
                    { text: "Iris", value: "iris" },
                    { text: "Matugen", value: "matugen" }
                ]
                currentValue: root.config ? (root.config.paletteEngine || "auto") : "auto"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("paletteEngine", val); }
            }
        }

        // ── Sezione 3: Sfondo del Desktop ───────────────────────────────
        SettingsHeader {
            text: "Gestione Sfondi (Wallpaper)"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            // Cartella Raccolta Sfondi
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
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
                            text: "Percorso directory da cui il carosello carica le anteprime"
                            color: "#7e889b"
                            font.pixelSize: 11
                            font.family: root.textFontFamily
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width - 90
                        height: 36
                        radius: 8
                        color: "#080a0f"
                        border.width: 1
                        border.color: wallDirInput.activeFocus ? root.accentColor : Qt.rgba(255, 255, 255, 0.08)

                        TextInput {
                            id: wallDirInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.config ? (root.config.wallpaperLibrary || "") : ""
                            color: "#e2e6ee"
                            font.pixelSize: 12
                            font.family: root.iconFontFamily
                            clip: true
                            onEditingFinished: {
                                if (root.config && text.trim() !== "") {
                                    root.config.set("wallpaperLibrary", text.trim());
                                    root.config.set("wallpaperLibraryPath", text.trim());
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 82
                        height: 36
                        radius: 8
                        color: resetDirMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "Predefinito"
                            color: "#c2c7d4"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }

                        MouseArea {
                            id: resetDirMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                const home = Quickshell.env("HOME") || "";
                                const defaultPath = home + "/Sfondi";
                                wallDirInput.text = defaultPath;
                                if (root.config) {
                                    root.config.set("wallpaperLibrary", defaultPath);
                                    root.config.set("wallpaperLibraryPath", defaultPath);
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            // Comando Applicazione Sfondo
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
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
                            text: "Script o comando eseguito passando il file come parametro $1"
                            color: "#7e889b"
                            font.pixelSize: 11
                            font.family: root.textFontFamily
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width - 90
                        height: 36
                        radius: 8
                        color: "#080a0f"
                        border.width: 1
                        border.color: cmdInput.activeFocus ? root.accentColor : Qt.rgba(255, 255, 255, 0.08)

                        TextInput {
                            id: cmdInput
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.config ? (root.config.wallpaperCustomCommand || "") : ""
                            color: "#e2e6ee"
                            font.pixelSize: 12
                            font.family: root.iconFontFamily
                            clip: true
                            onEditingFinished: {
                                if (root.config && text.trim() !== "") {
                                    root.config.set("wallpaperCustomCommand", text.trim());
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 82
                        height: 36
                        radius: 8
                        color: resetCmdMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "Predefinito"
                            color: "#c2c7d4"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }

                        MouseArea {
                            id: resetCmdMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                const home = Quickshell.env("HOME") || "";
                                const defaultCmd = home + "/.scripts/apply-wallpaper.sh \"$1\"";
                                cmdInput.text = defaultCmd;
                                if (root.config) {
                                    root.config.set("wallpaperCustomCommand", defaultCmd);
                                }
                            }
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
