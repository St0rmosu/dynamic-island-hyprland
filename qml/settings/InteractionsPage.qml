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

        // ── Sezione 1: Azioni dei Click sull'Isola ─────────────────────
        SettingsHeader {
            text: I18n.tr("Azioni del Click del Mouse")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSegmented {
                title: I18n.tr("Click Sinistro (Principale)")
                description: I18n.tr("Azione quando premi sull'isola a riposo")
                model: [
                    { text: I18n.tr("Control Center"), value: "control_center" },
                    { text: I18n.tr("Media Player"), value: "player" },
                    { text: I18n.tr("Appunti"), value: "clipboard" }
                ]
                currentValue: root.config ? root.config.primaryClickAction : "control_center"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("primaryClickAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: I18n.tr("Click Destro (Secondario)")
                description: I18n.tr("Azione al tasto destro del mouse")
                model: [
                    { text: I18n.tr("Power Menu"), value: "power_menu" },
                    { text: I18n.tr("Control Center"), value: "control_center" },
                    { text: I18n.tr("App Launcher"), value: "apps" }
                ]
                currentValue: root.config ? root.config.secondaryClickAction : "power_menu"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("secondaryClickAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: I18n.tr("Click Rotella (Centrale)")
                description: I18n.tr("Azione alla pressione della rotellina del mouse")
                model: [
                    { text: I18n.tr("Appunti"), value: "clipboard" },
                    { text: I18n.tr("File Shelf"), value: "files" },
                    { text: I18n.tr("Power Menu"), value: "power_menu" }
                ]
                currentValue: root.config ? root.config.middleClickAction : "clipboard"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("middleClickAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: I18n.tr("Doppio Click")
                description: I18n.tr("Azione rapida al doppio click rapido")
                model: [
                    { text: I18n.tr("Nascondi Isola"), value: "toggle_island" },
                    { text: I18n.tr("Overview"), value: "overview" }
                ]
                currentValue: root.config ? root.config.doubleClickAction : "toggle_island"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("doubleClickAction", val); }
            }
        }

        // ── Sezione 2: Scorrimento Rotellina (Scroll) ───────────────────
        SettingsHeader {
            text: I18n.tr("Rotella del Mouse (Scroll sull'Isola)")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSegmented {
                title: I18n.tr("Scorrimento Verticale (Su / Giù)")
                description: I18n.tr("Regola al volo una funzione di sistema")
                model: [
                    { text: I18n.tr("Volume Audio"), value: "volume" },
                    { text: I18n.tr("Luminosità"), value: "brightness" }
                ]
                currentValue: root.config ? root.config.scrollVerticalAction : "volume"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("scrollVerticalAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: I18n.tr("Scorrimento Orizzontale (Sinistra / Destra)")
                description: I18n.tr("Spostamento laterale della rotellina")
                model: [
                    { text: I18n.tr("Cambia Canzone"), value: "track" },
                    { text: I18n.tr("Cambia Workspace"), value: "workspace" }
                ]
                currentValue: root.config ? root.config.scrollHorizontalAction : "track"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("scrollHorizontalAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSlider {
                title: I18n.tr("Passo di Regolazione Volume/Luminosità")
                description: I18n.tr("Percentuale per ogni scatto della rotellina")
                icon: "\uf1de" // sliders
                from: 1
                to: 10
                stepSize: 1
                suffix: "%"
                value: root.config ? root.config.scrollStep : 5
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("scrollStep", Math.round(val)); }
            }
        }

        // ── Sezione 3: Media & Notifiche Brani ──────────────────────────
        SettingsHeader {
            text: I18n.tr("Comportamento Media Player")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSwitch {
                title: I18n.tr("Disabilita Espansione al Cambio Canzone")
                description: I18n.tr("Evita che l'isola si apra da sola ogni volta che inizia un nuovo brano")
                icon: "\uf001" // music
                checked: root.config ? root.config.disableAutoExpandOnTrackChange : false
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("disableAutoExpandOnTrackChange", st); }
            }
        }
    }
}
