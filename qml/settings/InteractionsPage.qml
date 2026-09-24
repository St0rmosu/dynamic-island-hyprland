import QtQuick
import QtQuick.Controls

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
            text: "Azioni del Click del Mouse"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSegmented {
                title: "Click Sinistro (Principale)"
                description: "Azione quando premi sull'isola a riposo"
                model: [
                    { text: "Control Center", value: "control_center" },
                    { text: "Media Player", value: "player" },
                    { text: "Clipboard", value: "clipboard" }
                ]
                currentValue: root.config ? root.config.primaryClickAction : "control_center"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("primaryClickAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: "Click Destro (Secondario)"
                description: "Azione al tasto destro del mouse"
                model: [
                    { text: "Power Menu", value: "power_menu" },
                    { text: "Control Center", value: "control_center" },
                    { text: "App Launcher", value: "apps" }
                ]
                currentValue: root.config ? root.config.secondaryClickAction : "power_menu"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("secondaryClickAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: "Click Rotella (Centrale)"
                description: "Azione alla pressione della rotellina del mouse"
                model: [
                    { text: "Clipboard", value: "clipboard" },
                    { text: "File Shelf", value: "files" },
                    { text: "Power Menu", value: "power_menu" }
                ]
                currentValue: root.config ? root.config.middleClickAction : "clipboard"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("middleClickAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: "Doppio Click"
                description: "Azione rapida al doppio click rapido"
                model: [
                    { text: "Nascondi Isola", value: "toggle_island" },
                    { text: "Overview", value: "overview" }
                ]
                currentValue: root.config ? root.config.doubleClickAction : "toggle_island"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("doubleClickAction", val); }
            }
        }

        // ── Sezione 2: Scorrimento Rotellina (Scroll) ───────────────────
        SettingsHeader {
            text: "Rotella del Mouse (Scroll sull'Isola)"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSegmented {
                title: "Scorrimento Verticale (Su / Giù)"
                description: "Regola al volo una funzione di sistema"
                model: [
                    { text: "Volume Audio", value: "volume" },
                    { text: "Luminosità", value: "brightness" }
                ]
                currentValue: root.config ? root.config.scrollVerticalAction : "volume"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("scrollVerticalAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSegmented {
                title: "Scorrimento Orizzontale (Sinistra / Destra)"
                description: "Spostamento laterale della rotellina"
                model: [
                    { text: "Cambia Canzone", value: "track" },
                    { text: "Cambia Workspace", value: "workspace" }
                ]
                currentValue: root.config ? root.config.scrollHorizontalAction : "track"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("scrollHorizontalAction", val); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSlider {
                title: "Passo di Regolazione Volume/Luminosità"
                description: "Percentuale per ogni scatto della rotellina"
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
            text: "Comportamento Media Player"
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSwitch {
                title: "Disabilita Espansione al Cambio Canzone"
                description: "Evita che l'isola si apra da sola ogni volta che inizia un nuovo brano"
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
