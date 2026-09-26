import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

FocusScope {
    id: root

    property var config: null
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    focus: true

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    // ── 7 Scorciatoie Ufficiali della Dynamic Island ──────────────────
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

    // ── Stato Registratore Tasti in Tempo Reale ───────────────────────
    property int recordingIndex: -1
    property var heldModifiers: []
    property var recordedCombo: []
    property bool recordingSuccess: false
    property bool autoApplyHyprland: true
    property bool isApplying: false
    property string applyStatusMessage: ""

    // Catturatore globale di eventi da tastiera
    Item {
        id: keyCaptureItem
        focus: root.recordingIndex !== -1
        Keys.priority: Keys.BeforeItemPriority
        Keys.enabled: root.recordingIndex !== -1

        Keys.onEscapePressed: function(event) {
            event.accepted = true;
            root.cancelRecording();
        }

        Keys.onPressed: function(event) {
            root.handleKeyPress(event);
        }

        Keys.onReleased: function(event) {
            root.handleKeyRelease(event);
        }
    }

    Timer {
        id: closeTimer
        interval: 550
        repeat: false
        onTriggered: {
            root.recordingIndex = -1;
            root.recordingSuccess = false;
            root.heldModifiers = [];
            root.recordedCombo = [];
        }
    }

    Process {
        id: applyHyprlandProc
        command: []
        running: false
        onExited: {
            root.isApplying = false;
            root.applyStatusMessage = "Sincronizzato con Hyprland!";
            applyMsgTimer.restart();
        }
    }

    Timer {
        id: applyMsgTimer
        interval: 2500
        onTriggered: root.applyStatusMessage = ""
    }

    // ── Logica di Riconoscimento & Registrazione Tasti ──────────────────
    function isIgnoredKey(key) {
        return key === Qt.Key_CapsLock || key === Qt.Key_NumLock || key === Qt.Key_ScrollLock;
    }

    function isModifierKey(key) {
        return key === Qt.Key_Super_L || key === Qt.Key_Super_R ||
               key === Qt.Key_Meta || key === Qt.Key_Hyper_L || key === Qt.Key_Hyper_R ||
               key === Qt.Key_Control ||
               key === Qt.Key_Alt || key === Qt.Key_AltGr ||
               key === Qt.Key_Shift;
    }

    function modifierNameFromKey(key) {
        if (key === Qt.Key_Super_L || key === Qt.Key_Super_R || key === Qt.Key_Meta || key === Qt.Key_Hyper_L || key === Qt.Key_Hyper_R)
            return "SUPER";
        if (key === Qt.Key_Control)
            return "CTRL";
        if (key === Qt.Key_Alt || key === Qt.Key_AltGr)
            return "ALT";
        if (key === Qt.Key_Shift)
            return "SHIFT";
        return "";
    }

    function resolveKeyName(key, text) {
        switch (key) {
            case Qt.Key_Tab: return "Tab";
            case Qt.Key_Backtab: return "Tab";
            case Qt.Key_Space: return "Spazio";
            case Qt.Key_Return:
            case Qt.Key_Enter: return "Return";
            case Qt.Key_Backspace: return "Backspace";
            case Qt.Key_Delete: return "Delete";
            case Qt.Key_Left: return "left";
            case Qt.Key_Right: return "right";
            case Qt.Key_Up: return "up";
            case Qt.Key_Down: return "down";
            case Qt.Key_Home: return "Home";
            case Qt.Key_End: return "End";
            case Qt.Key_PageUp: return "PageUp";
            case Qt.Key_PageDown: return "PageDown";
            case Qt.Key_F1: return "F1";
            case Qt.Key_F2: return "F2";
            case Qt.Key_F3: return "F3";
            case Qt.Key_F4: return "F4";
            case Qt.Key_F5: return "F5";
            case Qt.Key_F6: return "F6";
            case Qt.Key_F7: return "F7";
            case Qt.Key_F8: return "F8";
            case Qt.Key_F9: return "F9";
            case Qt.Key_F10: return "F10";
            case Qt.Key_F11: return "F11";
            case Qt.Key_F12: return "F12";
            case Qt.Key_Print: return "Print";
            case Qt.Key_Insert: return "Insert";
            case Qt.Key_Minus: return "minus";
            case Qt.Key_Equal: return "equal";
            case Qt.Key_BracketLeft: return "bracketleft";
            case Qt.Key_BracketRight: return "bracketright";
            case Qt.Key_Semicolon: return "semicolon";
            case Qt.Key_Apostrophe: return "apostrophe";
            case Qt.Key_Comma: return "comma";
            case Qt.Key_Period: return "period";
            case Qt.Key_Slash: return "slash";
            case Qt.Key_Backslash: return "backslash";
            case Qt.Key_Grave: return "grave";
        }

        if (key >= Qt.Key_A && key <= Qt.Key_Z) {
            return String.fromCharCode(key).toUpperCase();
        }
        if (key >= Qt.Key_0 && key <= Qt.Key_9) {
            return String.fromCharCode(key);
        }
        if (text && text.trim().length === 1) {
            let code = text.charCodeAt(0);
            if (code >= 33 && code <= 126) {
                return text.toUpperCase();
            }
        }
        return "";
    }

    function handleKeyPress(event) {
        if (recordingIndex < 0 || recordingIndex >= currentShortcuts.length) return;

        if (event.key === Qt.Key_Escape) {
            event.accepted = true;
            cancelRecording();
            return;
        }

        if (isIgnoredKey(event.key)) {
            event.accepted = true;
            return;
        }

        if (isModifierKey(event.key)) {
            let modName = modifierNameFromKey(event.key);
            if (modName && heldModifiers.indexOf(modName) === -1) {
                let mods = heldModifiers.slice();
                mods.push(modName);
                heldModifiers = mods;
            }
            event.accepted = true;
            return;
        }

        // Tasto non modificatore premuto: la combinazione è completata!
        let keyName = resolveKeyName(event.key, event.text);
        if (!keyName) {
            event.accepted = true;
            return;
        }

        // Raccogli tutti i modificatori attivi (da event.modifiers e da heldModifiers)
        let activeMods = [];
        let hasSuper = (event.modifiers & Qt.MetaModifier) || heldModifiers.indexOf("SUPER") !== -1;
        let hasCtrl = (event.modifiers & Qt.ControlModifier) || heldModifiers.indexOf("CTRL") !== -1;
        let hasAlt = (event.modifiers & Qt.AltModifier) || heldModifiers.indexOf("ALT") !== -1;
        let hasShift = (event.modifiers & Qt.ShiftModifier) || heldModifiers.indexOf("SHIFT") !== -1;

        if (hasSuper) activeMods.push("SUPER");
        if (hasCtrl) activeMods.push("CTRL");
        if (hasAlt) activeMods.push("ALT");
        if (hasShift) activeMods.push("SHIFT");

        let combo = activeMods.concat([keyName]);
        recordedCombo = combo;
        recordingSuccess = true;
        event.accepted = true;

        // Salva istantaneamente sul momento
        applyShortcut(recordingIndex, combo);

        // Chiudi il recorder con feedback visivo verde
        closeTimer.restart();
    }

    function handleKeyRelease(event) {
        if (recordingIndex < 0) return;
        if (isModifierKey(event.key)) {
            let modName = modifierNameFromKey(event.key);
            let idx = heldModifiers.indexOf(modName);
            if (idx !== -1) {
                let mods = heldModifiers.slice();
                mods.splice(idx, 1);
                heldModifiers = mods;
            }
        }
    }

    function startRecording(idx) {
        if (idx < 0 || idx >= currentShortcuts.length) return;
        if (recordingIndex === idx) {
            cancelRecording();
            return;
        }
        closeTimer.stop();
        recordingIndex = idx;
        heldModifiers = [];
        recordedCombo = [];
        recordingSuccess = false;
        Qt.callLater(function() {
            keyCaptureItem.forceActiveFocus();
        });
    }

    function cancelRecording() {
        closeTimer.stop();
        recordingIndex = -1;
        heldModifiers = [];
        recordedCombo = [];
        recordingSuccess = false;
    }

    function toggleModifierManual(mod) {
        let mods = heldModifiers.slice();
        let idx = mods.indexOf(mod);
        if (idx !== -1) {
            mods.splice(idx, 1);
        } else {
            mods.push(mod);
        }
        heldModifiers = mods;
        keyCaptureItem.forceActiveFocus();
    }

    function isShortcutCustomized(idx) {
        if (idx < 0 || idx >= currentShortcuts.length) return false;
        let cur = currentShortcuts[idx].keys || [];
        let def = defaultShortcuts[idx].keys || [];
        if (cur.length !== def.length) return true;
        for (let i = 0; i < cur.length; i++) {
            if (cur[i] !== def[i]) return true;
        }
        return false;
    }

    function resetShortcut(idx) {
        if (idx < 0 || idx >= defaultShortcuts.length) return;
        let defKeys = defaultShortcuts[idx].keys.slice();
        applyShortcut(idx, defKeys);
        if (recordingIndex === idx) {
            cancelRecording();
        }
    }

    function resetAllToDefault() {
        let updated = JSON.parse(JSON.stringify(defaultShortcuts));
        if (root.config) {
            root.config.set("customShortcuts", updated);
        }
        syncHyprland(updated);
        cancelRecording();
    }

    function applyShortcut(idx, keys) {
        if (idx < 0 || idx >= currentShortcuts.length) return;
        let updated = JSON.parse(JSON.stringify(currentShortcuts));
        updated[idx].keys = keys;
        if (root.config) {
            root.config.set("customShortcuts", updated);
        }
        if (autoApplyHyprland) {
            syncHyprland(updated);
        }
    }

    function syncHyprland(shortcutsList) {
        let list = shortcutsList || currentShortcuts;
        applyHyprlandProc.command = [
            root.homeDir + "/.config/quickshell/dynamic-island/scripts/apply_hyprland_binds.py",
            JSON.stringify(list)
        ];
        root.isApplying = true;
        applyHyprlandProc.running = true;
    }

    function generateLuaSnippet() {
        let lines = [];
        lines.push('-- Scorciatoie Dynamic Island sincronizzate per ~/.config/hypr/moduli/binds.lua :');
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

    // ── Layout della Pagina ───────────────────────────────────────────
    Flickable {
        anchors.fill: parent
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

            // ── Sezione 1: Header e Controlli Globali ──────────────────────
            Row {
                width: parent.width
                spacing: 12

                SettingsHeader {
                    text: "Scorciatoie Hyprland (Registra al volo premendo la tastiera)"
                    accentColor: root.accentColor
                    textFontFamily: root.textFontFamily
                }

                Item {
                    width: parent.width - 450
                    height: 1
                }

                // Pulsante Ripristina Tutte
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 130
                    height: 28
                    radius: 7
                    color: resetAllMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.10)

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "\uf0e2"
                            font.family: root.iconFontFamily
                            color: "#c2c7d4"
                            font.pixelSize: 11
                        }
                        Text {
                            text: "Ripristina Tutte"
                            color: "#c2c7d4"
                            font.pixelSize: 11
                            font.family: root.textFontFamily
                        }
                    }

                    MouseArea {
                        id: resetAllMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.resetAllToDefault()
                    }
                }
            }

            // ── Sezione 2: Lista Scorciatoie Interattive ──────────────────
            SettingsCard {
                Repeater {
                    model: root.currentShortcuts

                    Column {
                        width: parent.width
                        spacing: 10

                        // Riga Principale della Scorciatoia
                        Item {
                            width: parent.width
                            height: 54

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: actionControls.left
                                anchors.rightMargin: 16
                                spacing: 12

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 9
                                    color: (root.recordingIndex === index)
                                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                                        : Qt.rgba(255, 255, 255, 0.05)
                                    border.width: 1
                                    border.color: (root.recordingIndex === index) ? root.accentColor : Qt.rgba(255, 255, 255, 0.08)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        color: root.accentColor
                                        font.family: root.iconFontFamily
                                        font.pixelSize: 15
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Row {
                                        spacing: 8
                                        Text {
                                            text: modelData.title
                                            color: "#f2f4f8"
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            font.family: root.textFontFamily
                                        }

                                        // Badge se personalizzata
                                        Rectangle {
                                            visible: root.isShortcutCustomized(index)
                                            width: 44
                                            height: 16
                                            radius: 4
                                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.20)
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Modificata"
                                                color: root.accentColor
                                                font.pixelSize: 8
                                                font.weight: Font.Bold
                                            }
                                        }
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
                                spacing: 8

                                // Pulsante Ripristina Singolo (se modificata)
                                Rectangle {
                                    visible: root.isShortcutCustomized(index)
                                    width: 28
                                    height: 30
                                    radius: 7
                                    color: resetMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                                    border.width: 1
                                    border.color: Qt.rgba(255, 255, 255, 0.10)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf0e2"
                                        font.family: root.iconFontFamily
                                        color: "#9aa3b5"
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        id: resetMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: root.resetShortcut(index)
                                    }
                                }

                                // Key Badge Pills (Cliccabile per iniziare a registrare!)
                                Rectangle {
                                    height: 32
                                    width: keysRow.width + 16
                                    radius: 8
                                    color: (root.recordingIndex === index)
                                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                                        : (badgeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.05))
                                    border.width: 1
                                    border.color: (root.recordingIndex === index) ? root.accentColor : Qt.rgba(255, 255, 255, 0.12)
                                    anchors.verticalCenter: parent.verticalCenter

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
                                                    color: (root.recordingIndex === index)
                                                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
                                                        : Qt.rgba(255, 255, 255, 0.08)

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
                                        onClicked: root.startRecording(index)
                                    }
                                }

                                // Pulsante Esplicito "Registra "
                                Rectangle {
                                    height: 32
                                    width: recLabelRow.width + 16
                                    radius: 8
                                    color: (root.recordingIndex === index)
                                        ? root.accentColor
                                        : (recBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06))
                                    border.width: 1
                                    border.color: (root.recordingIndex === index) ? root.accentColor : Qt.rgba(255, 255, 255, 0.12)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Row {
                                        id: recLabelRow
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Text {
                                            text: "\uf11c"
                                            font.family: root.iconFontFamily
                                            color: (root.recordingIndex === index) ? "#ffffff" : root.accentColor
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: (root.recordingIndex === index) ? "In Ascolto..." : "Registra"
                                            color: (root.recordingIndex === index) ? "#ffffff" : "#d8dce6"
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            font.family: root.textFontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: recBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.startRecording(index)
                                    }
                                }

                                // Pulsante Prova Rapida [ ▶ ]
                                Rectangle {
                                    width: 32
                                    height: 32
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

                        // ── Cassetto Registratore Tasti (Attivo per questa scorciatoia) ──
                        Rectangle {
                            visible: root.recordingIndex === index
                            width: parent.width
                            implicitHeight: 112
                            radius: 12
                            color: root.recordingSuccess ? Qt.rgba(48/255, 209/255, 88/255, 0.12) : "#0a0c12"
                            border.width: 1.5
                            border.color: root.recordingSuccess ? "#30d158" : root.accentColor

                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                // Riga Superiore: Badge di stato + suggerimento + tasto annulla
                                Item {
                                    width: parent.width
                                    height: 24

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 10

                                        // Badge Pulsante IN ASCOLTO / REGISTRATO
                                        Rectangle {
                                            width: statusRow.width + 16
                                            height: 22
                                            radius: 11
                                            color: root.recordingSuccess ? Qt.rgba(48/255, 209/255, 88/255, 0.22) : Qt.rgba(255, 69, 58, 0.20)
                                            border.width: 1
                                            border.color: root.recordingSuccess ? "#30d158" : "#ff453a"

                                            Row {
                                                id: statusRow
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Rectangle {
                                                    width: 7
                                                    height: 7
                                                    radius: 3.5
                                                    color: root.recordingSuccess ? "#30d158" : "#ff453a"
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    SequentialAnimation on opacity {
                                                        running: root.recordingIndex !== -1 && !root.recordingSuccess
                                                        loops: Animation.Infinite
                                                        PropertyAnimation { from: 1.0; to: 0.3; duration: 450; easing.type: Easing.InOutQuad }
                                                        PropertyAnimation { from: 0.3; to: 1.0; duration: 450; easing.type: Easing.InOutQuad }
                                                    }
                                                }

                                                Text {
                                                    text: root.recordingSuccess ? "REGISTRATO!" : "IN ASCOLTO..."
                                                    color: root.recordingSuccess ? "#30d158" : "#ff6961"
                                                    font.pixelSize: 10
                                                    font.weight: Font.Bold
                                                    font.family: root.textFontFamily
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: root.recordingSuccess
                                                ? "Scorciatoia aggiornata e salvata con successo!"
                                                : "Premi i tasti sulla tastiera per registrare sul momento (es. SUPER + K)"
                                            color: root.recordingSuccess ? "#30d158" : "#9aa3b5"
                                            font.pixelSize: 11
                                            font.family: root.textFontFamily
                                        }
                                    }

                                    // Pulsante Annulla (Esc)
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 86
                                        height: 22
                                        radius: 6
                                        color: cancelMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08)
                                        border.width: 1
                                        border.color: Qt.rgba(255, 255, 255, 0.12)

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                text: "✕"
                                                color: "#c2c7d4"
                                                font.pixelSize: 9
                                            }
                                            Text {
                                                text: "Annulla (Esc)"
                                                color: "#c2c7d4"
                                                font.pixelSize: 10
                                                font.family: root.textFontFamily
                                            }
                                        }

                                        MouseArea {
                                            id: cancelMouse
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true
                                            onClicked: root.cancelRecording()
                                        }
                                    }
                                }

                                // Box Centrale: Visualizzatore Dinamico dei Tasti Premuti
                                Rectangle {
                                    width: parent.width
                                    height: 40
                                    radius: 8
                                    color: "#05070a"
                                    border.width: 1
                                    border.color: root.recordingSuccess ? "#30d158" : Qt.rgba(255, 255, 255, 0.10)

                                    // Visualizzazione se registrazione completata
                                    Row {
                                        visible: root.recordingSuccess
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: "✔"
                                            color: "#30d158"
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Repeater {
                                            model: root.recordedCombo
                                            Row {
                                                spacing: 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                Rectangle {
                                                    width: okPillText.contentWidth + 16
                                                    height: 24
                                                    radius: 6
                                                    color: Qt.rgba(48/255, 209/255, 88/255, 0.25)
                                                    border.width: 1
                                                    border.color: "#30d158"
                                                    Text {
                                                        id: okPillText
                                                        anchors.centerIn: parent
                                                        text: modelData
                                                        color: "#ffffff"
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                        font.family: root.textFontFamily
                                                    }
                                                }
                                                Text {
                                                    visible: index < root.recordedCombo.length - 1
                                                    text: "+"
                                                    color: "#30d158"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }
                                    }

                                    // Visualizzazione durante la pressione (modificatori tenuti premuti)
                                    Row {
                                        visible: !root.recordingSuccess && root.heldModifiers.length > 0
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Repeater {
                                            model: root.heldModifiers
                                            Row {
                                                spacing: 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                Rectangle {
                                                    width: modHeldText.contentWidth + 16
                                                    height: 24
                                                    radius: 6
                                                    color: root.accentColor
                                                    Text {
                                                        id: modHeldText
                                                        anchors.centerIn: parent
                                                        text: modelData
                                                        color: "#ffffff"
                                                        font.pixelSize: 11
                                                        font.weight: Font.Bold
                                                        font.family: root.textFontFamily
                                                    }
                                                }
                                                Text {
                                                    text: "+"
                                                    color: "#c2c7d4"
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }
                                        }

                                        // Pillola pulsante in attesa del tasto finale
                                        Rectangle {
                                            width: 44
                                            height: 24
                                            radius: 6
                                            color: Qt.rgba(255, 255, 255, 0.12)
                                            border.width: 1
                                            border.color: Qt.rgba(255, 255, 255, 0.20)
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: "..."
                                                color: "#ffffff"
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                            }

                                            SequentialAnimation on opacity {
                                                loops: Animation.Infinite
                                                PropertyAnimation { from: 1.0; to: 0.3; duration: 400 }
                                                PropertyAnimation { from: 0.3; to: 1.0; duration: 400 }
                                            }
                                        }
                                    }

                                    // Prompt se nessun tasto è ancora premuto
                                    Row {
                                        visible: !root.recordingSuccess && root.heldModifiers.length === 0
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            text: "\uf11c"
                                            font.family: root.iconFontFamily
                                            color: root.accentColor
                                            font.pixelSize: 13
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: "Premi una combinazione (es. SUPER + Tab, ALT + Spazio, o premi solo una lettera)"
                                            color: "#8e99ae"
                                            font.pixelSize: 11
                                            font.family: root.textFontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: keyCaptureItem.forceActiveFocus()
                                    }
                                }

                                // Riga Inferiore: Scorciatoie rapide per modificatori e aiuto
                                Item {
                                    width: parent.width
                                    height: 20

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        Text {
                                            text: "Modificatori rapidi:"
                                            color: "#7e889b"
                                            font.pixelSize: 10
                                            font.family: root.textFontFamily
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Repeater {
                                            model: ["SUPER", "ALT", "CTRL", "SHIFT"]
                                            Rectangle {
                                                readonly property bool isHeld: root.heldModifiers.indexOf(modelData) !== -1
                                                width: chipText.contentWidth + 10
                                                height: 18
                                                radius: 4
                                                color: isHeld ? root.accentColor : Qt.rgba(255, 255, 255, 0.08)
                                                anchors.verticalCenter: parent.verticalCenter

                                                Text {
                                                    id: chipText
                                                    anchors.centerIn: parent
                                                    text: modelData
                                                    color: isHeld ? "#ffffff" : "#a4b1cd"
                                                    font.pixelSize: 9
                                                    font.weight: Font.DemiBold
                                                    font.family: root.textFontFamily
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.toggleModifierManual(modelData)
                                                }
                                            }
                                        }
                                    }

                                    // Ripristina a default questo specifico shortcut
                                    Rectangle {
                                        visible: root.isShortcutCustomized(index)
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 120
                                        height: 18
                                        radius: 4
                                        color: Qt.rgba(255, 255, 255, 0.06)

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text {
                                                text: "\uf0e2"
                                                font.family: root.iconFontFamily
                                                color: "#8e99ae"
                                                font.pixelSize: 9
                                            }
                                            Text {
                                                text: "Ripristina Default"
                                                color: "#8e99ae"
                                                font.pixelSize: 9
                                                font.family: root.textFontFamily
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.resetShortcut(index)
                                        }
                                    }
                                }
                            }
                        }

                        // Divisore tra le righe
                        Rectangle {
                            visible: index < root.currentShortcuts.length - 1
                            width: parent.width
                            height: 1
                            color: Qt.rgba(255, 255, 255, 0.05)
                        }
                    }
                }
            }

            // ── Sezione 3: Snippet di Configurazione Lua Hyprland ───────────
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
                    height: 30

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Switch Auto-Applica
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 6
                            color: root.autoApplyHyprland ? root.accentColor : Qt.rgba(255, 255, 255, 0.10)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: root.autoApplyHyprland ? "✓" : ""
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.autoApplyHyprland = !root.autoApplyHyprland
                            }
                        }

                        Text {
                            text: "Sincronizza automaticamente con ~/.config/hypr/moduli/binds.lua"
                            color: "#c2c7d4"
                            font.pixelSize: 11
                            font.family: root.textFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Feedback messaggio applicato
                        Text {
                            visible: root.applyStatusMessage !== ""
                            text: " • " + root.applyStatusMessage
                            color: "#30d158"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.family: root.textFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Pulsante Applica Manuale
                        Rectangle {
                            width: 140
                            height: 28
                            radius: 6
                            color: applyBtnMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40) : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)
                            border.width: 1
                            border.color: root.accentColor

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: root.isApplying ? "\uf110" : "\uf0e7"
                                    font.family: root.iconFontFamily
                                    color: root.accentColor
                                    font.pixelSize: 11
                                }
                                Text {
                                    text: root.isApplying ? "Applicando..." : "Applica a Hyprland"
                                    color: "#ffffff"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    font.family: root.textFontFamily
                                }
                            }

                            MouseArea {
                                id: applyBtnMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: root.syncHyprland()
                            }
                        }

                        // Pulsante Copia Codice
                        Rectangle {
                            width: 120
                            height: 28
                            radius: 6
                            color: copyMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.15)

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "\uf0c5"
                                    font.family: root.iconFontFamily
                                    color: "#c2c7d4"
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
}
