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

        // ── Sezione: Regolazione con la Rotellina del Mouse ─────────────
        SettingsHeader {
            text: I18n.tr("Rotella del Mouse (Scroll sull'Isola)")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSegmented {
                title: I18n.tr("Scorrimento Verticale (Su / Giù)")
                description: I18n.tr("Regola al volo il volume o la luminosità scorrendo sull'isola")
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

            SettingsSlider {
                title: I18n.tr("Passo di Regolazione Volume/Luminosità")
                description: I18n.tr("Percentuale per ogni scatto della rotellina del mouse")
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

        // ── Sezione: Comportamento Media Player ─────────────────────────
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
