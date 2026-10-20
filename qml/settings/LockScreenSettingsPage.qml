import QtQuick
import QtQuick.Controls
import IslandBackend

Flickable {
    id: root

    property var config: null
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    contentWidth: width
    contentHeight: contentCol.implicitHeight + 40
    clip: true
    boundsBehavior: Flickable.StopAtBounds

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

        // ── Sezione: Stile Schermata di Blocco (iPadOS) ─────────────
        SettingsHeader {
            text: I18n.tr("Schermata di Blocco & Stile iPadOS")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            // Switch: Effetto Profondità Orologio
            SettingsSwitch {
                title: I18n.tr("Effetto Profondità Orologio (Depth Effect)")
                description: I18n.tr("Consente al soggetto dello sfondo (cutout/maschera) di sovrapporsi tridimensionalmente alle cifre dell'orologio")
                icon: "\uf06e" // eye
                checked: root.config ? (root.config.lockDepthEffect !== undefined ? root.config.lockDepthEffect : false) : false
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("lockDepthEffect", st); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            // Switch: Foto Profilo Utente sopra l'Isola
            SettingsSwitch {
                title: I18n.tr("Foto Profilo sopra la Dynamic Island")
                description: I18n.tr("Visualizza l'avatar circolare dell'utente sopra la capsula password dell'isola dinamica")
                icon: "\uf007" // user
                checked: root.config ? (root.config.lockShowProfilePhoto !== undefined ? root.config.lockShowProfilePhoto : true) : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("lockShowProfilePhoto", st); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            // Switch: Widget Complicazioni a Sinistra
            SettingsSwitch {
                title: I18n.tr("Colonna Widget iPad a Sinistra")
                description: I18n.tr("Mostra il pannello sinistro con Apple Pencil, scorciatoie Notion/Spotify e stato rete")
                icon: "\uf009" // th-large
                checked: root.config ? (root.config.lockShowComplications !== undefined ? root.config.lockShowComplications : true) : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("lockShowComplications", st); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            // Switch: Icone Stato in Alto a Destra
            SettingsSwitch {
                title: I18n.tr("Icone di Stato in Alto a Destra (Wi-Fi e Batteria)")
                description: I18n.tr("Mostra o nascondi la capsula della batteria e l'icona Wi-Fi nell'angolo superiore destro")
                icon: "\uf240" // battery-full
                checked: root.config ? (root.config.lockShowTopStatus !== undefined ? root.config.lockShowTopStatus : false) : false
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("lockShowTopStatus", st); }
            }
        }

        // ── Sezione: Esperienza Multimediale Spotify ─────────────────
        SettingsHeader {
            text: I18n.tr("Esperienza Multimediale Spotify")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSwitch {
                title: I18n.tr("Modalità Media & Copertina Espansa (iPadOS)")
                description: I18n.tr("Quando Spotify è in riproduzione, mostra la grande copertina con sfondo ambient color glow e card satinata")
                icon: "\uf001" // music
                checked: root.config ? (root.config.lockEnableMediaMode !== undefined ? root.config.lockEnableMediaMode : true) : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("lockEnableMediaMode", st); }
            }
        }
    }
}
