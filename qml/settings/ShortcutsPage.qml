import QtQuick
import QtQuick.Controls
import Quickshell

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

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    readonly property var defaultShortcuts: [
        { id: "overview", title: "Workspace Overview", desc: "Visualizzatore interattivo di tutti i workspace e finestre", icon: "\uf108", keys: ["SUPER", "Tab"], action: "overview" },
        { id: "power", title: "Power Menu (Wlogout)", desc: "Menu rapido per Blocca, Esci, Sospendi, Riavvia, Spegni", icon: "\uf011", keys: ["SUPER", "P"], action: "power" },
        { id: "notifications", title: "Notification Center", desc: "Pannello con cronologia notifiche e cancellazione", icon: "\uf0f3", keys: ["SUPER", "N"], action: "notifications" },
        { id: "wallpaper", title: "Wallpaper Switcher", desc: "Selettore a schede per cambiare sfondo con animazione", icon: "\uf03e", keys: ["SUPER", "ALT", "Spazio"], action: "master-or-wallpaper" },
        { id: "apps", title: "Application Launcher", desc: "Ricerca rapida e avvio delle applicazioni installate", icon: "\uf135", keys: ["ALT", "Spazio"], action: "apps" },
        { id: "files", title: "File Shelf", desc: "Cassetto rapido per trascinare e incollare file al volo", icon: "\uf07b", keys: ["SUPER", "O"], action: "files" },
        { id: "clipboard", title: "Clipboard History", desc: "Cronologia degli appunti con testi, codici e immagini", icon: "\uf0ea", keys: ["SUPER", "C"], action: "clipboard" }
    ]

    readonly property var currentShortcuts: {
        if (root.config && Array.isArray(root.config.customShortcuts) && root.config.customShortcuts.length > 0)
            return root.config.customShortcuts;
        return defaultShortcuts;
    }

    // State for editing a shortcut
    property int editingIndex: -1
    property var editKeys: []

    function startEdit(idx) {
        if (idx >= 0 && idx < currentShortcuts.length) {
            editingIndex = idx;
            editKeys = currentShortcuts[idx].keys.slice();
        }
    }

    function toggleEditModifier(mod) {
        let keys = editKeys.slice();
        let idx = keys.indexOf(mod);
        if (idx !== -1) {
            keys.splice(idx, 1);
        } else {
            // Keep SUPER/ALT/CTRL/SHIFT at the beginning
            let modOrder = ["SUPER", "CTRL", "ALT", "SHIFT"];
            let newKeys = [];
            for (let m of modOrder) {
                if (keys.indexOf(m) !== -1 || m === mod) {
                    newKeys.push(m);
                }
            }
            for (let k of keys) {
                if (modOrder.indexOf(k) === -1) {
                    newKeys.push(k);
                }
            }
            keys = newKeys;
        }
        editKeys = keys;
    }

    function setEditKey(k) {
        let modOrder = ["SUPER", "CTRL", "ALT", "SHIFT"];
        let newKeys = [];
        for (let item of editKeys) {
            if (modOrder.indexOf(item) !== -1) {
                newKeys.push(item);
            }
        }
        newKeys.push(k);
        editKeys = newKeys;
    }

    function saveEdit() {
        if (editingIndex >= 0 && editingIndex < currentShortcuts.length && editKeys.length > 0) {
            let updated = JSON.parse(JSON.stringify(currentShortcuts));
            updated[editingIndex].keys = editKeys;
            if (root.config) {
                root.config.set("customShortcuts", updated);
            }
        }
        editingIndex = -1;
    }

    function cancelEdit() {
        editingIndex = -1;
    }

    function generateLuaSnippet() {
        let lines = [];
        lines.push('-- Incolla queste righe nel tuo ~/.config/hypr/moduli/binds.lua :');
        for (let item of currentShortcuts) {
            let keyParts = item.keys || [];
            let hasSuper = keyParts.indexOf("SUPER") !== -1;
            let otherKeys = keyParts.filter(k => k !== "SUPER").map(k => k === "Spazio" ? "space" : k);

            let keyStr = "";
            if (hasSuper) {
                if (otherKeys.length > 0) {
                    keyStr = 'mainMod .. " + ' + otherKeys.join(" + ") + '"';
                } else {
                    keyStr = 'mainMod';
                }
            } else {
                keyStr = '"' + keyParts.map(k => k === "Spazio" ? "space" : k).join(" + ") + '"';
            }

            lines.push('hl.bind(' + keyStr + ', hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh ' + item.action + '"))');
        }
        return lines.join("\n");
    }

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
        Row {
            width: parent.width
            spacing: 12

            SettingsHeader {
                text: "Scorciatoie Configurate (Clicca sui tasti per modificare)"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
            }
        }

        SettingsCard {
            Repeater {
                model: root.currentShortcuts

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

                            // Key Badge Chips (Clickable to edit!)
                            Rectangle {
                                height: 30
                                width: keysRow.width + 12
                                radius: 8
                                color: (root.editingIndex === index)
                                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)
                                    : (badgeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.05))
                                border.width: 1
                                border.color: (root.editingIndex === index) ? root.accentColor : Qt.rgba(255, 255, 255, 0.10)

                                Row {
                                    id: keysRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Repeater {
                                        id: keysRepeater
                                        model: modelData.keys

                                        Row {
                                            spacing: 4
                                            anchors.verticalCenter: parent.verticalCenter

                                            Rectangle {
                                                width: keyText.contentWidth + 14
                                                height: 22
                                                radius: 5
                                                color: Qt.rgba(255, 255, 255, 0.08)

                                                Text {
                                                    id: keyText
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    color: "#ffffff"
                                                    font.pixelSize: 10
                                                    font.weight: Font.DemiBold
                                                    font.family: root.textFontFamily
                                                }
                                            }

                                            Text {
                                                visible: index < keysRepeater.count - 1
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "+"
                                                color: "#7e889b"
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: badgeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.editingIndex === index) root.cancelEdit();
                                        else root.startEdit(index);
                                    }
                                }
                            }

                            // Pulsante Prova Rapida [ ▶ ]
                            Rectangle {
                                width: 30
                                height: 30
                                radius: 8
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
                                        Quickshell.execDetached(["bash", "-c", "$HOME/.scripts/shell-dispatcher.sh " + modelData.action]);
                                    }
                                }
                            }
                        }
                    }

                    // Inline Editor Box (When editing this specific shortcut)
                    Rectangle {
                        visible: root.editingIndex === index
                        width: parent.width
                        height: 96
                        radius: 12
                        color: "#0c0f16"
                        border.width: 1
                        border.color: root.accentColor

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Row {
                                spacing: 8
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Modificatori:"
                                    color: "#9aa3b5"
                                    font.pixelSize: 11
                                    font.family: root.textFontFamily
                                }

                                Repeater {
                                    model: ["SUPER", "ALT", "CTRL", "SHIFT"]
                                    Rectangle {
                                        readonly property bool isSelected: root.editKeys.indexOf(modelData) !== -1
                                        width: modText.contentWidth + 16
                                        height: 26
                                        radius: 6
                                        color: isSelected ? root.accentColor : Qt.rgba(255, 255, 255, 0.08)

                                        Text {
                                            id: modText
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: isSelected ? "#ffffff" : "#c2c7d4"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            font.family: root.textFontFamily
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleEditModifier(modelData)
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 6
                                anchors.horizontalCenter: parent.horizontalCenter

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Tasto:"
                                    color: "#9aa3b5"
                                    font.pixelSize: 11
                                    font.family: root.textFontFamily
                                }

                                Repeater {
                                    model: ["Tab", "Spazio", "P", "N", "O", "C", "Return", "D", "M", "Esc"]
                                    Rectangle {
                                        readonly property bool isSelected: root.editKeys.indexOf(modelData) !== -1
                                        width: kText.contentWidth + 14
                                        height: 26
                                        radius: 6
                                        color: isSelected ? root.accentColor : Qt.rgba(255, 255, 255, 0.08)

                                        Text {
                                            id: kText
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: isSelected ? "#ffffff" : "#c2c7d4"
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            font.family: root.textFontFamily
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setEditKey(modelData)
                                        }
                                    }
                                }
                            }

                            Row {
                                spacing: 10
                                anchors.horizontalCenter: parent.horizontalCenter

                                Rectangle {
                                    width: 70
                                    height: 24
                                    radius: 6
                                    color: root.accentColor
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Salva"
                                        color: "#ffffff"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.saveEdit()
                                    }
                                }

                                Rectangle {
                                    width: 70
                                    height: 24
                                    radius: 6
                                    color: Qt.rgba(255, 255, 255, 0.08)
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Annulla"
                                        color: "#c2c7d4"
                                        font.pixelSize: 10
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.cancelEdit()
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: index < root.currentShortcuts.length - 1
                        width: parent.width
                        height: 1
                        color: Qt.rgba(255, 255, 255, 0.05)
                    }
                }
            }
        }

        // ── Sezione 2: Snippet di Configurazione Lua ────────────────────
        Row {
            width: parent.width
            spacing: 12

            SettingsHeader {
                text: "Configurazione Hyprland (Lua) - Aggiornata in Tempo Reale"
                accentColor: root.accentColor
                textFontFamily: root.textFontFamily
            }
        }

        SettingsCard {
            Item {
                width: parent.width
                height: 28

                Rectangle {
                    anchors.right: parent.right
                    width: 140
                    height: 28
                    radius: 6
                    color: copyMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1
                    border.color: root.accentColor

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "\uf0c5"
                            font.family: root.iconFontFamily
                            color: root.accentColor
                            font.pixelSize: 11
                        }
                        Text {
                            text: copyTimer.running ? "Copiato!" : "Copia Codice"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                        }
                    }

                    Timer {
                        id: copyTimer
                        interval: 2000
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            Quickshell.execDetached(["bash", "-c", "wl-copy << 'EOF'\n" + root.generateLuaSnippet() + "\nEOF"]);
                            copyTimer.restart();
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                implicitHeight: luaText.contentHeight + 24
                radius: 10
                color: "#080a0f"
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.06)

                Text {
                    id: luaText
                    anchors.fill: parent
                    anchors.margins: 12
                    text: root.generateLuaSnippet()
                    color: "#a4b1cd"
                    font.family: root.iconFontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WrapAnywhere
                }
            }
        }
    }
}
