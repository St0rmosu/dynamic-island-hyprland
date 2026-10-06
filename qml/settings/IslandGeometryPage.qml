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

        // ── Sezione 2: Posizionamento & Pillola Workspace ───────────────
        SettingsHeader {
            text: I18n.tr("Posizionamento & Pillola Workspace")
            accentColor: root.accentColor
            textFontFamily: root.textFontFamily
        }

        SettingsCard {
            SettingsSwitch {
                title: I18n.tr("Blocca Orologio al Centro Morto")
                description: I18n.tr("Mantiene l'orologio principale esattamente al centro di tutti i monitor")
                icon: "\uf05b" // crosshairs
                checked: root.config ? (root.config.lockIslandCenter !== false) : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("lockIslandCenter", st); }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05) }

            SettingsSwitch {
                title: I18n.tr("Pillola Workspace Attivo")
                description: I18n.tr("Mostra una pillola satellite accanto all'orologio che indica il workspace corrente")
                icon: "\uf108" // desktop
                checked: root.config ? (root.config.enableWorkspacePill !== false) : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("enableWorkspacePill", st); }
            }

            Rectangle {
                visible: root.config && (root.config.enableWorkspacePill !== false)
                width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05)
            }

            SettingsSegmented {
                visible: root.config && (root.config.enableWorkspacePill !== false)
                title: I18n.tr("Posizione Pillola Workspace")
                description: I18n.tr("Scegli se posizionare la pillola workspace a destra o a sinistra dell'orologio")
                model: [
                    { text: I18n.tr("Destra (Predefinito)"), value: "right" },
                    { text: I18n.tr("Sinistra"), value: "left" }
                ]
                currentValue: root.config ? (root.config.workspacePillPosition || "right") : "right"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("workspacePillPosition", val); }
            }

            Rectangle {
                visible: root.config && (root.config.enableWorkspacePill !== false)
                width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05)
            }

            SettingsSwitch {
                visible: root.config && (root.config.enableWorkspacePill !== false)
                title: I18n.tr("Mostra Icone Applicazioni")
                description: I18n.tr("Visualizza le miniature delle icone (es. Discord, browser, terminale) nei workspace con finestre aperte")
                icon: "\uf109" // laptop / app
                checked: root.config ? (root.config.workspacePillShowAppIcons !== false) : true
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onToggled: function(st) { if (root.config) root.config.set("workspacePillShowAppIcons", st); }
            }

            Rectangle {
                visible: root.config && (root.config.enableWorkspacePill !== false)
                width: parent.width; height: 1; color: Qt.rgba(255, 255, 255, 0.05)
            }

            SettingsSegmented {
                visible: root.config && (root.config.enableWorkspacePill !== false)
                title: I18n.tr("Numero Workspace Mostrati")
                description: I18n.tr("Imposta quanti workspace visualizzare nella pillola (espande automaticamente se navighi oltre)")
                model: [
                    { text: "5", value: 5 },
                    { text: "8", value: 8 },
                    { text: "10 (Predefinito)", value: 10 }
                ]
                currentValue: root.config ? (root.config.workspacePillShownCount || 10) : 10
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
                onSelected: function(val) { if (root.config) root.config.set("workspacePillShownCount", val); }
            }
        }

        // ── Sezione 3: Auto-Hide & Comportamento ─────────────────────────
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
    }
}
