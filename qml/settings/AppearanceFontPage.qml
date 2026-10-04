import QtQuick
import QtQuick.Controls
import IslandBackend
import Quickshell
import Quickshell.Io

Flickable {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    function resolveDefaultWallpaperDirectory() {
        return root.homeDir + "/Pictures/Wallpapers";
    }

    Process {
        id: pickFolderProcess
        command: [
            "bash",
            root.homeDir + "/.config/quickshell/dynamic-island/scripts/pick_folder.sh",
            root.resolveDefaultWallpaperDirectory()
        ]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                const trimmed = data.trim();
                if (trimmed !== "") {
                    wallDirInput.text = trimmed;
                    if (root.config) {
                        root.config.set("wallpaperLibrary", trimmed);
                        root.config.set("wallpaperLibraryPath", trimmed);
                    }
                }
            }
        }
    }

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

        // ── Sezione 1: Lingua & Localizzazione ─────────────────────────
        SettingsHeader {
            text: I18n.tr("Lingua & Localizzazione")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSegmented {
                title: I18n.tr("Lingua dell'Interfaccia")
                description: I18n.tr("Lingua visualizzata nella shell e nell'isola dinamica (rilevata automaticamente dal sistema)")
                stacked: true
                model: [
                    { text: I18n.tr("Sistema (Auto)"), value: "auto" },
                    { text: "English", value: "en" },
                    { text: "Italiano", value: "it" },
                    { text: "Español", value: "es" },
                    { text: "Deutsch", value: "de" },
                    { text: "Français", value: "fr" }
                ]
                currentValue: root.config ? (root.config.language || "auto") : "auto"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) {
                    if (root.config) {
                        root.config.set("language", val);
                    }
                    if (typeof I18n !== "undefined" && I18n) {
                        I18n.language = val;
                    }
                }
            }
        }

        // ── Sezione 2: Stile Vetro & Trasparenza ────────────────────────
        SettingsHeader {
            text: I18n.tr("Stile Vetro & Trasparenza")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSlider {
                title: I18n.tr("Opacità Sfondo Isola")
                description: I18n.tr("Percentuale di copertura del vetro scuro matte")
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
                title: I18n.tr("Sfocatura Vetro (Blur)")
                description: I18n.tr("Intensità dell'effetto frosted glass dietro i pannelli")
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
                title: I18n.tr("Formato Orologio")
                description: I18n.tr("Visualizzazione delle ore nei moduli e nell'isola")
                model: [
                    { text: I18n.tr("24 Ore"), value: "24h" },
                    { text: I18n.tr("12 Ore (AM/PM)"), value: "12h" }
                ]
                currentValue: root.config ? root.config.clockFormat : "24h"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("clockFormat", val); }
            }
        }

        // ── Sezione 2: Colori & Temi Dinamici ───────────────────────────
        SettingsHeader {
            text: I18n.tr("Colori & Armonia Temi")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSwitch {
                title: I18n.tr("Palette Dinamica")
                description: I18n.tr("Estrae e sfuma i colori dell'accento in tempo reale dallo sfondo del desktop")
                icon: "\uf1fc" // paint-brush
                checked: root.config ? root.config.pywalEnabled : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("pywalEnabled", st); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: I18n.tr("Motore Palette Compatibile")
                description: I18n.tr("Scegli o rileva automaticamente il generatore di colori del tuo sistema")
                stacked: true
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
            text: I18n.tr("Gestione Sfondi (Wallpaper)")
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
                            text: I18n.tr("Cartella Raccolta Sfondi")
                            color: "#f2f4f8"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                        Text {
                            text: I18n.tr("Percorso directory da cui il carosello carica le anteprime")
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
                        width: parent.width - 274
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
                            text: {
                                if (root.config && root.config.wallpaperLibrary && !root.config.wallpaperLibrary.endsWith("/Sfondi")) {
                                    return root.config.wallpaperLibrary;
                                }
                                return root.resolveDefaultWallpaperDirectory();
                            }
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

                    // Tasto Sfoglia (apre selettore cartella con file manager grafico)
                    Rectangle {
                        width: 90
                        height: 36
                        radius: 8
                        color: browseDirMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)

                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: "\uf07c" // folder-open
                                color: root.accentColor
                                font.family: root.iconFontFamily
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: I18n.tr("Sfoglia")
                                color: "#f2f4f8"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                font.family: root.textFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: browseDirMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                const cur = (wallDirInput.text && wallDirInput.text.trim() !== "") ? wallDirInput.text.trim() : root.resolveDefaultWallpaperDirectory();
                                pickFolderProcess.command = [
                                    "bash",
                                    root.homeDir + "/.config/quickshell/dynamic-island/scripts/pick_folder.sh",
                                    cur
                                ];
                                pickFolderProcess.running = false;
                                pickFolderProcess.running = true;
                            }
                        }
                    }

                    // Tasto Apri (apre nel File Manager del sistema es. Nautilus/Dolphin)
                    Rectangle {
                        width: 74
                        height: 36
                        radius: 8
                        color: openDirMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)

                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "\uf06e" // eye / open
                                color: "#9aa3b5"
                                font.family: root.iconFontFamily
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: I18n.tr("Apri")
                                color: "#c2c7d4"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                font.family: root.textFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: openDirMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                const targetPath = wallDirInput.text || root.resolveDefaultWallpaperDirectory();
                                Quickshell.execDetached(["xdg-open", targetPath]);
                            }
                        }
                    }

                    // Tasto Predefinito
                    Rectangle {
                        width: 82
                        height: 36
                        radius: 8
                        color: resetDirMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: I18n.tr("Predefinito")
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
                                const defaultPath = root.resolveDefaultWallpaperDirectory();
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

            // Sfondo Integrato Quickshell (Stile Logical Impulse)
            SettingsSwitch {
                title: I18n.tr("Sfondo Integrato nella Shell")
                description: I18n.tr("Lo sfondo viene gestito da Quickshell; chiudendo la shell lo sfondo scompare come su Logical Impulse")
                checked: root.config ? (root.config.enableQuickshellWallpaper !== false) : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onToggled: function(val) {
                    if (root.config) {
                        root.config.set("enableQuickshellWallpaper", val);
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
                            text: I18n.tr("Comando Applicazione Sfondo")
                            color: "#f2f4f8"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                        Text {
                            text: I18n.tr("Script o comando eseguito passando il file come parametro $1")
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
                            text: {
                                const defaultCmd = root.homeDir + "/.config/quickshell/dynamic-island/scripts/apply-wallpaper.sh \"$1\"";
                                if (root.config && root.config.wallpaperCustomCommand) {
                                    const c = root.config.wallpaperCustomCommand;
                                    if (c.indexOf("/.scripts/apply-wallpaper.sh") === -1)
                                        return c;
                                }
                                return defaultCmd;
                            }
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
                            text: I18n.tr("Predefinito")
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
                                const defaultCmd = root.homeDir + "/.config/quickshell/dynamic-island/scripts/apply-wallpaper.sh \"$1\"";
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
            text: I18n.tr("Tipografia & Caratteri")
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
                            text: I18n.tr("Carattere Testo & Controlli")
                            color: "#f2f4f8"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                        Text {
                            text: (root.config && root.config.textFontFamily) ? root.config.textFontFamily : root.textFontFamily
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
                        text: I18n.tr("Sfoglia")
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
                            text: I18n.tr("Carattere Icone & Glifi")
                            color: "#f2f4f8"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                        Text {
                            text: (root.config && root.config.iconFontFamily) ? root.config.iconFontFamily : root.iconFontFamily
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
                        text: I18n.tr("Sfoglia")
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
