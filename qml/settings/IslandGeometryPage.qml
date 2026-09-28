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

        // ── Sezione 1: Geometria & Dimensioni ───────────────────────────
        SettingsHeader {
            text: I18n.tr("Geometria Isola & Schermo")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSlider {
                title: I18n.tr("Larghezza a Riposo")
                description: I18n.tr("Larghezza minima della capsula prima delle espansioni")
                icon: "\uf07e" // arrows-alt-h
                from: 90
                to: 320
                stepSize: 2
                suffix: "px"
                value: root.config ? root.config.islandWidth : 140
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("islandWidth", Math.round(val)); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSlider {
                title: I18n.tr("Altezza a Riposo")
                description: I18n.tr("Altezza base della capsula con orologio")
                icon: "\uf07d" // arrows-alt-v
                from: 28
                to: 60
                stepSize: 2
                suffix: "px"
                value: root.config ? root.config.islandHeight : 40
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("islandHeight", Math.round(val)); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSlider {
                title: I18n.tr("Raggio di Curvatura")
                description: I18n.tr("Morbidezza degli angoli (squircle arrotondato)")
                icon: "\uf111" // circle
                from: 12
                to: 40
                stepSize: 1
                suffix: "px"
                value: root.config ? root.config.islandCornerRadius : 32
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("islandCornerRadius", Math.round(val)); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSlider {
                title: I18n.tr("Margine Superiore")
                description: I18n.tr("Distanza dal bordo alto dello schermo")
                icon: "\uf062" // arrow-up
                from: 0
                to: 32
                stepSize: 1
                suffix: "px"
                value: root.config ? root.config.islandTopMargin : 8
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("islandTopMargin", Math.round(val)); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSlider {
                title: I18n.tr("Zona Riservata (Exclusive Zone)")
                description: I18n.tr("Spazio che spinge in basso le finestre delle app")
                icon: "\uf2d0" // window-maximize
                from: 0
                to: 60
                stepSize: 1
                suffix: "px"
                value: root.config ? root.config.islandExclusiveZone : 0
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("islandExclusiveZone", Math.round(val)); }
            }
        }

        // ── Sezione 2: Auto-Hide & Comportamento ─────────────────────────
        SettingsHeader {
            text: I18n.tr("Auto-Nascondimento (Auto-Hide)")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSwitch {
                title: I18n.tr("Nascondi Isola in Inattività")
                description: I18n.tr("Ritira l'isola verso l'alto quando non ci sono alert o musica")
                icon: "\uf070" // eye-slash
                checked: root.config ? root.config.autoHideEnabled : false
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("islandAutoHideEnabled", st); }
            }

            Rectangle {
                visible: root.config && root.config.autoHideEnabled
                width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05)
            }

            SettingsSlider {
                visible: root.config && root.config.autoHideEnabled
                title: I18n.tr("Ritardo Inattività")
                description: I18n.tr("Tempo prima di nascondere l'isola in assenza di attività")
                icon: "\uf017" // clock
                from: 500
                to: 5000
                stepSize: 250
                suffix: "ms"
                value: root.config ? root.config.autoHideDelayMs : 2000
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("islandAutoHideDelayMs", Math.round(val)); }
            }

            Rectangle {
                visible: root.config && root.config.autoHideEnabled
                width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05)
            }

            SettingsSwitch {
                visible: root.config && root.config.autoHideEnabled
                title: I18n.tr("Mostra Workspace in Auto-Hide")
                description: I18n.tr("Mostra un piccolo indicatore del desktop quando l'isola è nascosta")
                icon: "\uf108" // desktop
                checked: root.config ? root.config.showWorkspaceOnAutoHide : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("islandShowWorkspaceOnAutoHide", st); }
            }
        }

        // ── Sezione 3: Passaggio del Mouse (Hover) ───────────────────────
        SettingsHeader {
            text: I18n.tr("Interazione Hover (Mouse)")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSwitch {
                title: I18n.tr("Espandi al Passaggio del Mouse")
                description: I18n.tr("Apre automaticamente l'isola quando il puntatore si sofferma sopra")
                icon: "\uf245" // mouse-pointer
                checked: root.config ? root.config.hoverExpandEnabled : false
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("hoverExpandEnabled", st); }
            }

            Rectangle {
                visible: root.config && root.config.hoverExpandEnabled
                width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05)
            }

            SettingsSegmented {
                visible: root.config && root.config.hoverExpandEnabled
                title: I18n.tr("Cosa Aprire all'Hover")
                description: I18n.tr("Scegli il pannello che appare all'espansione")
                model: [
                    { text: I18n.tr("Control Center"), value: 2 },
                    { text: I18n.tr("Media Player"), value: 1 }
                ]
                currentValue: root.config ? root.config.hoverExpandAction : 2
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("hoverExpandAction", val); }
            }

            Rectangle {
                visible: root.config && root.config.hoverExpandEnabled
                width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05)
            }

            SettingsSlider {
                visible: root.config && root.config.hoverExpandEnabled
                title: I18n.tr("Ritardo Espansione Hover")
                description: I18n.tr("Tempo di permanenza del cursore prima dell'apertura")
                icon: "\uf252" // hourglass-half
                from: 50
                to: 600
                stepSize: 25
                suffix: "ms"
                value: root.config ? root.config.hoverExpandDelayMs : 200
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onValueModified: function(val) { if (root.config) root.config.set("hoverExpandDelayMs", Math.round(val)); }
            }
        }
    }
}
