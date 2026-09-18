import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import IslandBackend

Item {
    id: studioRoot

    property color accentColor: StyleTokens.accent
    property color accentSoft: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.16)
    property color accentBorder: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.42)
    property color accentGlow: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.28)
    property color textPrimary: "#f2f4f8"
    property color textSecondary: "#9aa3b5"
    property color textMuted: "#656f82"
    property color bgCard: Qt.rgba(255, 255, 255, 0.045)
    property color borderCard: Qt.rgba(255, 255, 255, 0.08)

    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property string textFontFamily: "Google Sans Flex"
    property string heroFontFamily: "Google Sans Flex"

    property string controlCenterOrientation: "vertical"
    property int controlCenterWidth: 420
    property var rawConfig: ({})

    signal layoutChanged(var layoutArray)
    signal requestOrientationChange(string orientation)
    signal requestWidthChange(int newWidth)
    signal requestReloadQuickshell()

    // Current selection in canvas
    property string selectedModuleId: "wifi"
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    property bool isDraggingModule: false
    property bool isResizing: false
    property bool isInternalSave: false
    property bool canvasInitialized: false

    readonly property var selectedModule: {
        for (let i = 0; i < modules.length; i++) {
            if (modules[i].id === selectedModuleId) return modules[i];
        }
        return null;
    }

    // Live list of modules
    property var modules: [
        { id: "header", name: "Orologio & Batteria", icon: "\uf017", colSpan: 2, height: 32, minHeight: 32, maxHeight: 32, active: true, desc: "Pillola superiore con orologio e percentuale batteria" },
        { id: "wifi", name: "Scheda Wi-Fi", icon: "\uf1eb", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Stato connessione, rete attiva e discovery drawer" },
        { id: "bluetooth", name: "Scheda Bluetooth", icon: "\uf294", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Controller bluetooth e periferiche connesse" },
        { id: "brightness", name: "Luminosità Display", icon: "\uf185", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Cursore retroilluminazione schermo" },
        { id: "volume", name: "Controllo Volume", icon: "\uf028", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Cursore volume audio master" },
        { id: "notifications", name: "Centro Notifiche", icon: "\uf0f3", colSpan: 2, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Cronologia notifiche, contatore e cancellazione rapida" },
        { id: "battery", name: "Profilo Batteria TLP", icon: "\uf0e7", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Selettore Risparmio, Bilanciato, Prestazioni" },
        { id: "toggles", name: "Luce Notturna & Focus", icon: "\uf186", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Filtro luce blu e modalità non disturbare" },
        { id: "quickactions", name: "Barra & Appunti", icon: "\uf108", colSpan: 2, height: 48, minHeight: 48, maxHeight: 96, active: false, desc: "Pulsanti rapidi desktop workspace e cronologia appunti" }
    ]

    Component.onCompleted: {
        if (rawConfig && (rawConfig.controlCenterCanvasLayout || Object.keys(rawConfig).length > 0)) {
            initializeFromConfig();
            canvasInitialized = true;
        }
    }

    onRawConfigChanged: {
        if (!canvasInitialized && rawConfig && (rawConfig.controlCenterCanvasLayout || Object.keys(rawConfig).length > 0)) {
            initializeFromConfig();
            canvasInitialized = true;
        }
    }

    function snapHeight(id, rawH) {
        if (id === "header") return 32;
        if (id === "quickactions") return Math.max(48, Math.min(96, Math.round(rawH / 24) * 24));
        const minH = 80;
        const maxH = 240;
        // Griglia a caselle stile iOS: snap a passi di 40px (80 = 1 casella, 120 = 1.5, 160 = 2, 200 = 2.5, 240 = 3)
        const snapped = Math.round(rawH / 40) * 40;
        return Math.max(minH, Math.min(maxH, snapped));
    }

    function defaultHeight(id) {
        switch(id) {
        case "header": return 32;
        case "quickactions": return 48;
        default: return 80;
        }
    }

    function initializeFromConfig() {
        if (!rawConfig) return;
        try {
            if (Array.isArray(rawConfig.controlCenterCanvasLayout) && rawConfig.controlCenterCanvasLayout.length > 0) {
                let saved = rawConfig.controlCenterCanvasLayout;
                let merged = [];
                let seen = {};
                for (let i = 0; i < saved.length; i++) {
                    let s = saved[i];
                    for (let j = 0; j < modules.length; j++) {
                        let m = modules[j];
                        if (m.id === s.id) {
                            let targetH = s.height !== undefined ? snapHeight(m.id, s.height) : defaultHeight(m.id);
                            merged.push({
                                id: m.id,
                                name: m.name,
                                icon: m.icon,
                                colSpan: s.colSpan !== undefined ? s.colSpan : m.colSpan,
                                height: targetH,
                                minHeight: m.minHeight,
                                maxHeight: m.maxHeight,
                                active: s.active !== undefined ? s.active : m.active,
                                desc: m.desc
                            });
                            seen[m.id] = true;
                            break;
                        }
                    }
                }
                for (let j = 0; j < modules.length; j++) {
                    let m = modules[j];
                    if (!seen[m.id]) merged.push(m);
                }
                modules = merged;
                return;
            }

            // Otherwise initialize active states from booleans
            let copy = [];
            for (let i = 0; i < modules.length; i++) {
                let item = Object.assign({}, modules[i]);
                if (item.id === "wifi" && rawConfig.showWifiCard !== undefined)
                    item.active = Boolean(rawConfig.showWifiCard);
                else if (item.id === "bluetooth" && rawConfig.showBluetoothCard !== undefined)
                    item.active = Boolean(rawConfig.showBluetoothCard);
                else if (item.id === "brightness" && rawConfig.showDisplaySoundSliders !== undefined)
                    item.active = Boolean(rawConfig.showDisplaySoundSliders);
                else if (item.id === "volume" && rawConfig.showDisplaySoundSliders !== undefined)
                    item.active = Boolean(rawConfig.showDisplaySoundSliders);
                else if (item.id === "notifications" && rawConfig.controlCenterShowNotifications !== undefined)
                    item.active = Boolean(rawConfig.controlCenterShowNotifications);
                else if (item.id === "battery" && rawConfig.showTlpBatteryMode !== undefined)
                    item.active = Boolean(rawConfig.showTlpBatteryMode);
                else if (item.id === "toggles" && rawConfig.showNightFocusToggles !== undefined)
                    item.active = Boolean(rawConfig.showNightFocusToggles);
                else if (item.id === "quickactions" && (rawConfig.showBarraDesktopCard !== undefined || rawConfig.showClipboardQuickAccess !== undefined))
                    item.active = Boolean(rawConfig.showBarraDesktopCard) || Boolean(rawConfig.showClipboardQuickAccess);
                copy.push(item);
            }
            modules = copy;
        } catch(e) {
            console.log("[StudioLayoutCanvas] init error:", e);
        }
    }

    function emitSave() {
        let clean = [];
        for (let i = 0; i < modules.length; i++) {
            clean.push({
                id: modules[i].id,
                colSpan: modules[i].colSpan,
                height: Math.round(modules[i].height || defaultHeight(modules[i].id)),
                active: modules[i].active
            });
        }
        isInternalSave = true;
        studioRoot.layoutChanged(clean);
        isInternalSave = false;
    }

    function toggleColSpan(id) {
        let copy = [];
        for (let i = 0; i < modules.length; i++) {
            let m = Object.assign({}, modules[i]);
            if (m.id === id) {
                m.colSpan = (m.colSpan === 2) ? 1 : 2;
            }
            copy.push(m);
        }
        modules = copy;
        emitSave();
    }

    function setModuleHeight(id, h) {
        let copy = [];
        let changed = false;
        for (let i = 0; i < modules.length; i++) {
            let m = Object.assign({}, modules[i]);
            if (m.id === id) {
                const nh = snapHeight(id, h);
                if (m.height !== nh) {
                    m.height = nh;
                    changed = true;
                }
            }
            copy.push(m);
        }
        if (changed) {
            modules = copy;
            emitSave();
        }
    }

    function adjustModuleHeight(id, delta) {
        for (let i = 0; i < modules.length; i++) {
            if (modules[i].id === id) {
                if (id === "header") return;
                let cur = Number(modules[i].height) || defaultHeight(id);
                let step = (id === "quickactions") ? 24 : 40;
                setModuleHeight(id, cur + (delta > 0 ? step : -step));
                break;
            }
        }
    }

    function setModuleActive(id, active) {
        let copy = [];
        for (let i = 0; i < modules.length; i++) {
            let m = Object.assign({}, modules[i]);
            if (m.id === id) {
                m.active = active;
            }
            copy.push(m);
        }
        modules = copy;
        if (active) studioRoot.selectedModuleId = id;
        else if (studioRoot.selectedModuleId === id) studioRoot.selectedModuleId = "";
        emitSave();
    }

    function moveModule(fromIdx, toIdx) {
        if (fromIdx < 0 || fromIdx >= modules.length || toIdx < 0 || toIdx >= modules.length || fromIdx === toIdx)
            return;
        let copy = [];
        for (let i = 0; i < modules.length; i++) {
            copy.push(Object.assign({}, modules[i]));
        }
        let item = copy.splice(fromIdx, 1)[0];
        copy.splice(toIdx, 0, item);
        modules = copy;
        emitSave();
    }

    function resetToDefault() {
        modules = [
            { id: "header", name: "Orologio & Batteria", icon: "\uf017", colSpan: 2, height: 32, minHeight: 32, maxHeight: 32, active: true, desc: "Pillola superiore con orologio e percentuale batteria" },
            { id: "wifi", name: "Scheda Wi-Fi", icon: "\uf1eb", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Stato connessione, rete attiva e discovery drawer" },
            { id: "bluetooth", name: "Scheda Bluetooth", icon: "\uf294", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Controller bluetooth e periferiche connesse" },
            { id: "brightness", name: "Luminosità Display", icon: "\uf185", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Cursore retroilluminazione schermo" },
            { id: "volume", name: "Controllo Volume", icon: "\uf028", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Cursore volume audio master" },
            { id: "notifications", name: "Centro Notifiche", icon: "\uf0f3", colSpan: 2, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Cronologia notifiche, contatore e cancellazione rapida" },
            { id: "battery", name: "Profilo Batteria TLP", icon: "\uf0e7", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Selettore Risparmio, Bilanciato, Prestazioni" },
            { id: "toggles", name: "Luce Notturna & Focus", icon: "\uf186", colSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Filtro luce blu e modalità non disturbare" },
            { id: "quickactions", name: "Barra & Appunti", icon: "\uf108", colSpan: 2, height: 48, minHeight: 48, maxHeight: 96, active: false, desc: "Pulsanti rapidi desktop workspace e cronologia appunti" }
        ];
        studioRoot.selectedModuleId = "wifi";
        emitSave();
    }

    width: parent.width
    implicitHeight: mainColumn.implicitHeight

    Column {
        id: mainColumn
        width: parent.width
        spacing: 16

        // ====================================================
        // TOP CONTROLS & CANVAS STATUS
        // ====================================================
        Rectangle {
            width: parent.width
            height: 52
            radius: 16
            color: studioRoot.bgCard
            border.width: 1
            border.color: studioRoot.borderCard

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: studioRoot.accentSoft
                    border.width: 1
                    border.color: studioRoot.accentBorder
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "" // Grid icon
                        font.family: studioRoot.iconFontFamily
                        font.pixelSize: 12
                        color: studioRoot.accentColor
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: "Studio Canvas • Griglia Dinamica"
                        font.family: studioRoot.textFontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: studioRoot.textPrimary
                    }
                    Text {
                        text: "Disponi liberamente i moduli: posizione, ordine e dimensioni si riflettono direttamente nel Centro di Controllo."
                        font.family: studioRoot.textFontFamily
                        font.pixelSize: 10
                        color: studioRoot.textMuted
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // Quick Controls for Selected Module
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    visible: studioRoot.selectedModule !== null

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: studioRoot.selectedModule ? (studioRoot.selectedModule.name + " (" + (studioRoot.selectedModule.colSpan === 2 ? "100%" : "50%") + ")") : ""
                        font.family: studioRoot.textFontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: studioRoot.textPrimary
                    }

                    // Stepper Altezza: [ − ] [ 80px ] [ + ]
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Rectangle {
                            width: 26; height: 26; radius: 6
                            color: barMinusMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: barMinusMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 14; font.weight: Font.Bold; color: studioRoot.accentColor }
                            MouseArea {
                                id: barMinusMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: studioRoot.adjustModuleHeight(studioRoot.selectedModuleId, -10)
                            }
                        }

                        Rectangle {
                            width: 48; height: 26; radius: 6
                            color: Qt.rgba(0, 0, 0, 0.25)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.08)
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: studioRoot.selectedModule ? (Math.round(studioRoot.selectedModule.height) + "px") : "80px"
                                font.family: studioRoot.textFontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: studioRoot.accentColor
                            }
                        }

                        Rectangle {
                            width: 26; height: 26; radius: 6
                            color: barPlusMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: barPlusMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 14; font.weight: Font.Bold; color: studioRoot.accentColor }
                            MouseArea {
                                id: barPlusMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: studioRoot.adjustModuleHeight(studioRoot.selectedModuleId, 10)
                            }
                        }
                    }

                    // Larghezza Toggle: 50% / 100%
                    Rectangle {
                        width: 68; height: 26; radius: 6
                        color: barWidthMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: barWidthMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                        anchors.verticalCenter: parent.verticalCenter
                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "↔"; font.pixelSize: 11; font.weight: Font.Bold; color: studioRoot.accentColor }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: studioRoot.selectedModule ? (studioRoot.selectedModule.colSpan === 2 ? "100%" : "50%") : "50%"
                                font.family: studioRoot.textFontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: studioRoot.textPrimary
                            }
                        }
                        MouseArea {
                            id: barWidthMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: studioRoot.toggleColSpan(studioRoot.selectedModuleId)
                        }
                    }

                    Rectangle { width: 1; height: 20; color: Qt.rgba(255, 255, 255, 0.12); anchors.verticalCenter: parent.verticalCenter }
                }

                // Reset Layout Button
                Rectangle {
                    width: resetRow.width + 16
                    height: 30
                    radius: 8
                    color: resetMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.09) : Qt.rgba(255, 255, 255, 0.04)
                    border.width: 1
                    border.color: resetMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.08)
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: resetRow
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "" // Reset
                            font.family: studioRoot.iconFontFamily
                            font.pixelSize: 10
                            color: resetMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Ripristina"
                            font.family: studioRoot.textFontFamily
                            font.pixelSize: 10
                            color: resetMouse.containsMouse ? studioRoot.textPrimary : studioRoot.textSecondary
                        }
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: studioRoot.resetToDefault()
                    }
                }

                // Reload Quickshell Button
                Rectangle {
                    width: reloadRow.width + 16
                    height: 30
                    radius: 8
                    color: reloadMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1
                    border.color: reloadMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: reloadRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            font.family: studioRoot.iconFontFamily
                            font.pixelSize: 11
                            color: studioRoot.accentColor
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Ricarica Quickshell"
                            font.family: studioRoot.textFontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: studioRoot.textPrimary
                        }
                    }

                    MouseArea {
                        id: reloadMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: studioRoot.requestReloadQuickshell()
                    }
                }
            }
        }

        // ====================================================
        // INTERACTIVE BLUEPRINT GRID STAGE
        // ====================================================
        Rectangle {
            id: stageContainer
            width: parent.width
            height: Math.max(340, islandCapsule.height + 60)
            radius: 20
            color: "#0c0f16"
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.08)
            clip: true

            Behavior on height {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            // Subtle CAD/Blueprint Grid Pattern
            Item {
                anchors.fill: parent
                opacity: 0.14

                Repeater {
                    model: Math.ceil(stageContainer.width / 24)
                    Rectangle {
                        x: index * 24
                        y: 0
                        width: 1
                        height: stageContainer.height
                        color: "#5c7099"
                    }
                }

                Repeater {
                    model: Math.ceil(stageContainer.height / 24)
                    Rectangle {
                        x: 0
                        y: index * 24
                        width: stageContainer.width
                        height: 1
                        color: "#5c7099"
                    }
                }
            }

            // Click outside deselects
            MouseArea {
                anchors.fill: parent
                onClicked: studioRoot.selectedModuleId = ""
            }

            // Background badge in top left
            Row {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 12
                spacing: 6
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: studioRoot.accentColor
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "AREA LIVE CANVAS • " + studioRoot.controlCenterWidth + "px"
                    font.family: studioRoot.textFontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                    color: studioRoot.textMuted
                }
            }

            // The Island Control Center Capsule
            Rectangle {
                id: islandCapsule
                anchors.horizontalCenter: parent.horizontalCenter
                y: 30
                width: Math.min(stageContainer.width - 40, (studioRoot.controlCenterWidth >= 360 ? studioRoot.controlCenterWidth * 0.85 : (studioRoot.controlCenterOrientation === "horizontal" ? 450 : 340)))
                height: capsuleLayout.height + 24
                radius: 24
                color: Qt.rgba(18/255, 22/255, 30/255, 0.94)
                border.width: 1.5
                border.color: Qt.rgba(255, 255, 255, 0.12)

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                Behavior on height {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                // Inner specular highlight
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: parent.radius - 1
                    color: StyleTokens.transparent
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.05)
                }

                // Module Grid / Flow Layout
                Flow {
                    id: capsuleLayout
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    spacing: 8

                    Repeater {
                        model: studioRoot.modules

                        delegate: Item {
                            id: moduleItemDelegate
                            required property int index
                            required property var modelData

                            readonly property bool isSelected: studioRoot.selectedModuleId === modelData.id
                            readonly property bool isFullWidth: modelData.colSpan === 2
                            readonly property real slotWidth: isFullWidth ? capsuleLayout.width : ((capsuleLayout.width - 8) / 2)
                            property real overrideHeight: 0
                            readonly property real slotHeight: (overrideHeight > 0) ? overrideHeight : (modelData.height || studioRoot.defaultHeight(modelData.id))

                            visible: modelData.active
                            width: modelData.active ? slotWidth : 0
                            height: modelData.active ? slotHeight : 0

                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on height {
                                enabled: !studioRoot.isResizing && !bottomHandleMouse.pressed && !topHandleMouse.pressed
                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                            }

                            // Card Surface
                            Rectangle {
                                id: cardBody
                                anchors.fill: parent
                                radius: 12
                                color: moduleMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.08)

                                Behavior on color { ColorAnimation { duration: 120 } }

                                // Module Content Rendering
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    anchors.topMargin: moduleItemDelegate.isSelected ? 28 : 6
                                    Behavior on anchors.topMargin { NumberAnimation { duration: 120 } }

                                    // Header Module Special UI
                                    Row {
                                        visible: moduleItemDelegate.modelData.id === "header"
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "16:15"
                                            font.family: studioRoot.heroFontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: studioRoot.textPrimary
                                        }

                                        Item { Layout.fillWidth: true; width: 10 }

                                        Row {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4
                                            Text {
                                                text: "85%"
                                                font.family: studioRoot.textFontFamily
                                                font.pixelSize: 10
                                                color: studioRoot.textSecondary
                                            }
                                            Text {
                                                text: ""
                                                font.family: studioRoot.iconFontFamily
                                                font.pixelSize: 11
                                                color: studioRoot.accentColor
                                            }
                                        }
                                    }

                                    // Standard Module UI (Icon + Name + Live Mini Element)
                                    Row {
                                        visible: moduleItemDelegate.modelData.id !== "header"
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        spacing: 6

                                        Rectangle {
                                            width: 22
                                            height: 22
                                            radius: 11
                                            color: Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.18)
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: moduleItemDelegate.modelData.icon
                                                font.family: studioRoot.iconFontFamily
                                                font.pixelSize: 10
                                                color: studioRoot.accentColor
                                            }
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 1
                                            width: parent.width - 34

                                            Text {
                                                width: parent.width
                                                text: moduleItemDelegate.modelData.name
                                                font.family: studioRoot.textFontFamily
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                color: studioRoot.textPrimary
                                                elide: Text.ElideRight
                                            }

                                            // Mini interactive visual details depending on type
                                            Item {
                                                width: parent.width
                                                height: 10
                                                visible: moduleItemDelegate.modelData.id === "brightness" || moduleItemDelegate.modelData.id === "volume"

                                                Rectangle {
                                                    anchors.fill: parent
                                                    anchors.topMargin: 3
                                                    anchors.bottomMargin: 3
                                                    radius: 2
                                                    color: Qt.rgba(255, 255, 255, 0.12)

                                                    Rectangle {
                                                        width: parent.width * (moduleItemDelegate.modelData.id === "brightness" ? 0.72 : 0.58)
                                                        height: parent.height
                                                        radius: 2
                                                        color: studioRoot.accentColor
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: moduleItemDelegate.modelData.id === "notifications"
                                                text: "3 nuove notifiche"
                                                font.family: studioRoot.textFontFamily
                                                font.pixelSize: 8
                                                color: studioRoot.textMuted
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                visible: moduleItemDelegate.modelData.id === "wifi" || moduleItemDelegate.modelData.id === "bluetooth"
                                                text: "Connesso"
                                                font.family: studioRoot.textFontFamily
                                                font.pixelSize: 8
                                                color: studioRoot.accentColor
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }

                                // Selection Click & Drag MouseArea
                                MouseArea {
                                    id: moduleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: isSelected ? Qt.SizeAllCursor : Qt.PointingHandCursor

                                    property real pressX: 0
                                    property real pressY: 0
                                    property bool dragging: false

                                    onPressed: function(mouse) {
                                        studioRoot.selectedModuleId = moduleItemDelegate.modelData.id;
                                        pressX = mouse.x;
                                        pressY = mouse.y;
                                        dragging = false;
                                    }

                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            if (!dragging && (Math.abs(mouse.y - pressY) > 8 || Math.abs(mouse.x - pressX) > 8)) {
                                                dragging = true;
                                                studioRoot.isDraggingModule = true;
                                                studioRoot.dragSourceIndex = moduleItemDelegate.index;
                                            }
                                            if (dragging) {
                                                let scenePos = mapToItem(capsuleLayout, mouse.x, mouse.y);
                                                for (let i = 0; i < capsuleLayout.children.length; i++) {
                                                    let targetChild = capsuleLayout.children[i];
                                                    if (targetChild && targetChild.visible && targetChild.width > 0 && targetChild.height > 0) {
                                                        if (scenePos.x >= targetChild.x && scenePos.x <= (targetChild.x + targetChild.width) &&
                                                            scenePos.y >= targetChild.y && scenePos.y <= (targetChild.y + targetChild.height)) {
                                                            let targetIndex = targetChild.index !== undefined ? targetChild.index : i;
                                                            if (targetIndex !== moduleItemDelegate.index && targetIndex >= 0 && targetIndex < studioRoot.modules.length) {
                                                                studioRoot.moveModule(moduleItemDelegate.index, targetIndex);
                                                                break;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    onReleased: {
                                        if (dragging) {
                                            studioRoot.isDraggingModule = false;
                                            dragging = false;
                                        }
                                    }

                                    onClicked: {
                                        studioRoot.selectedModuleId = moduleItemDelegate.modelData.id;
                                    }
                                }
                            }

                            // ====================================================
                            // SELECTION BOUNDING BOX ("IL COSO INTORNO")
                            // ====================================================
                            Rectangle {
                                id: boundingBox
                                anchors.fill: parent
                                anchors.margins: -2
                                radius: cardBody.radius + 2
                                color: Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.08)
                                border.width: 2
                                border.color: studioRoot.accentColor
                                visible: moduleItemDelegate.isSelected
                                z: 50

                                // Top Floating Action & Dimension Pill
                                Rectangle {
                                    id: infoPill
                                    anchors.top: parent.top
                                    anchors.topMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: 24
                                    width: pillRow.width + 16
                                    radius: 12
                                    color: "#161b24"
                                    border.width: 1
                                    border.color: studioRoot.accentColor
                                    z: 60

                                    Row {
                                        id: pillRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: moduleItemDelegate.modelData.name + " (" + (moduleItemDelegate.modelData.colSpan === 2 ? "100%" : "50%") + " • " + Math.round(moduleItemDelegate.slotHeight) + "px)"
                                            font.family: studioRoot.textFontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            color: studioRoot.textPrimary
                                        }

                                        // Height decrease button
                                        Item {
                                            width: 18
                                            height: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "−"
                                                font.pixelSize: 13
                                                font.weight: Font.Bold
                                                color: minusMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                                            }
                                            MouseArea {
                                                id: minusMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.adjustModuleHeight(moduleItemDelegate.modelData.id, -10)
                                            }
                                        }

                                        // Height increase button
                                        Item {
                                            width: 18
                                            height: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "+"
                                                font.pixelSize: 13
                                                font.weight: Font.Bold
                                                color: plusMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                                            }
                                            MouseArea {
                                                id: plusMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.adjustModuleHeight(moduleItemDelegate.modelData.id, 10)
                                            }
                                        }

                                        // Move Earlier / Up button
                                        Item {
                                            width: 16
                                            height: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "▲"
                                                font.pixelSize: 9
                                                color: upMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                                            }
                                            MouseArea {
                                                id: upMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.moveModule(moduleItemDelegate.index, Math.max(0, moduleItemDelegate.index - 1))
                                            }
                                        }

                                        // Move Later / Down button
                                        Item {
                                            width: 16
                                            height: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "▼"
                                                font.pixelSize: 9
                                                color: downMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                                            }
                                            MouseArea {
                                                id: downMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.moveModule(moduleItemDelegate.index, Math.min(studioRoot.modules.length - 1, moduleItemDelegate.index + 1))
                                            }
                                        }

                                        // Span Width Toggle button
                                        Item {
                                            width: 18
                                            height: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "↔"
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                color: spanMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                                            }
                                            MouseArea {
                                                id: spanMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.toggleColSpan(moduleItemDelegate.modelData.id)
                                            }
                                        }

                                        // Delete / Remove from grid button
                                        Item {
                                            width: 16
                                            height: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                color: delMouse.containsMouse ? "#ff453a" : studioRoot.textSecondary
                                            }
                                            MouseArea {
                                                id: delMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.setModuleActive(moduleItemDelegate.modelData.id, false)
                                            }
                                        }
                                    }
                                }

                                // ====================================================
                                // RESIZE HANDLES (TUTTI I 4 LATI: ALTEZZA E LARGHEZZA)
                                // ====================================================

                                // 1. TOP RESIZE HANDLE (Pallino al centro del lato superiore)
                                Rectangle {
                                    id: topHandle
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.top
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    border.width: 2.5
                                    border.color: studioRoot.accentColor
                                    z: 55
                                    scale: topHandleMouse.containsMouse || topHandleMouse.pressed ? 1.25 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 100 } }

                                    MouseArea {
                                        id: topHandleMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeVerCursor

                                        property real startStageY: 0
                                        property real startH: 0
                                        property real currentH: 0

                                        onPressed: function(mouse) {
                                            studioRoot.isResizing = true;
                                            let p = mapToItem(stageContainer, mouse.x, mouse.y);
                                            startStageY = p.y;
                                            startH = moduleItemDelegate.modelData.height || studioRoot.defaultHeight(moduleItemDelegate.modelData.id);
                                            currentH = startH;
                                        }
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                let p = mapToItem(stageContainer, mouse.x, mouse.y);
                                                let delta = startStageY - p.y;
                                                currentH = studioRoot.snapHeight(moduleItemDelegate.modelData.id, startH + delta);
                                                moduleItemDelegate.overrideHeight = currentH;
                                            }
                                        }
                                        onReleased: {
                                            let targetH = currentH;
                                            if (targetH > 0) {
                                                studioRoot.setModuleHeight(moduleItemDelegate.modelData.id, targetH);
                                            }
                                            moduleItemDelegate.overrideHeight = 0;
                                            studioRoot.isResizing = false;
                                        }
                                        onCanceled: {
                                            moduleItemDelegate.overrideHeight = 0;
                                            studioRoot.isResizing = false;
                                        }
                                    }
                                }

                                // 2. BOTTOM RESIZE HANDLE (Pallino al centro del lato inferiore)
                                Rectangle {
                                    id: bottomHandle
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.bottom
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    border.width: 2.5
                                    border.color: studioRoot.accentColor
                                    z: 55
                                    scale: bottomHandleMouse.containsMouse || bottomHandleMouse.pressed ? 1.25 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 100 } }

                                    MouseArea {
                                        id: bottomHandleMouse
                                        anchors.fill: parent
                                        anchors.margins: -8
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeVerCursor

                                        property real startStageY: 0
                                        property real startH: 0
                                        property real currentH: 0

                                        onPressed: function(mouse) {
                                            studioRoot.isResizing = true;
                                            let p = mapToItem(stageContainer, mouse.x, mouse.y);
                                            startStageY = p.y;
                                            startH = moduleItemDelegate.modelData.height || studioRoot.defaultHeight(moduleItemDelegate.modelData.id);
                                            currentH = startH;
                                        }
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                let p = mapToItem(stageContainer, mouse.x, mouse.y);
                                                let delta = p.y - startStageY;
                                                currentH = studioRoot.snapHeight(moduleItemDelegate.modelData.id, startH + delta);
                                                moduleItemDelegate.overrideHeight = currentH;
                                            }
                                        }
                                        onReleased: {
                                            let targetH = currentH;
                                            if (targetH > 0) {
                                                studioRoot.setModuleHeight(moduleItemDelegate.modelData.id, targetH);
                                            }
                                            moduleItemDelegate.overrideHeight = 0;
                                            studioRoot.isResizing = false;
                                        }
                                        onCanceled: {
                                            moduleItemDelegate.overrideHeight = 0;
                                            studioRoot.isResizing = false;
                                        }
                                    }
                                }

                                // 3. LEFT RESIZE HANDLE (Pallino al centro del lato sinistro)
                                Rectangle {
                                    id: leftHandle
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.left
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    border.width: 2.5
                                    border.color: studioRoot.accentColor
                                    z: 55
                                    scale: leftHandleMouse.containsMouse || leftHandleMouse.pressed ? 1.25 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 100 } }

                                    MouseArea {
                                        id: leftHandleMouse
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeHorCursor

                                        property real startX: 0
                                        onPressed: function(mouse) { startX = mouse.x; }
                                        onClicked: {
                                            studioRoot.toggleColSpan(moduleItemDelegate.modelData.id);
                                        }
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                let diff = startX - mouse.x;
                                                if (diff > 25 && moduleItemDelegate.modelData.colSpan === 1) {
                                                    studioRoot.toggleColSpan(moduleItemDelegate.modelData.id);
                                                    startX = mouse.x;
                                                } else if (diff < -25 && moduleItemDelegate.modelData.colSpan === 2) {
                                                    studioRoot.toggleColSpan(moduleItemDelegate.modelData.id);
                                                    startX = mouse.x;
                                                }
                                            }
                                        }
                                    }
                                }

                                // 4. RIGHT RESIZE HANDLE (Pallino al centro del lato destro)
                                Rectangle {
                                    id: rightHandle
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.right
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    border.width: 2.5
                                    border.color: studioRoot.accentColor
                                    z: 55
                                    scale: rightHandleMouse.containsMouse || rightHandleMouse.pressed ? 1.25 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 100 } }

                                    MouseArea {
                                        id: rightHandleMouse
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeHorCursor

                                        property real startX: 0
                                        onPressed: function(mouse) { startX = mouse.x; }
                                        onClicked: {
                                            studioRoot.toggleColSpan(moduleItemDelegate.modelData.id);
                                        }
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                let diff = mouse.x - startX;
                                                if (diff > 25 && moduleItemDelegate.modelData.colSpan === 1) {
                                                    studioRoot.toggleColSpan(moduleItemDelegate.modelData.id);
                                                    startX = mouse.x;
                                                } else if (diff < -25 && moduleItemDelegate.modelData.colSpan === 2) {
                                                    studioRoot.toggleColSpan(moduleItemDelegate.modelData.id);
                                                    startX = mouse.x;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ====================================================
        // SHELF / DOCK UNDERNEATH ("SOTTO TUTTI I MODULI")
        // ====================================================
        Rectangle {
            width: parent.width
            height: shelfCol.implicitHeight + 28
            radius: 18
            color: studioRoot.bgCard
            border.width: 1
            border.color: studioRoot.borderCard

            Column {
                id: shelfCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: studioRoot.accentSoft
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "" // Box / library icon
                            font.family: studioRoot.iconFontFamily
                            font.pixelSize: 11
                            color: studioRoot.accentColor
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            text: "LIBRERIA DEI MODULI DISPONIBILI"
                            font.family: studioRoot.heroFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.6
                            color: studioRoot.textSecondary
                        }
                        Text {
                            text: "Clicca per aggiungere un modulo alla griglia dell'isola o rimuoverlo."
                            font.family: studioRoot.textFontFamily
                            font.pixelSize: 9
                            color: studioRoot.textMuted
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(255, 255, 255, 0.05)
                }

                // Grid of all modules
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 8

                    Repeater {
                        model: studioRoot.modules

                        delegate: Rectangle {
                            id: libraryCard
                            required property int index
                            required property var modelData

                            readonly property bool isInCanvas: modelData.active
                            readonly property bool isSelected: studioRoot.selectedModuleId === modelData.id

                            width: (parent.width - 8) / 2
                            height: 60
                            radius: 12
                            color: isSelected
                                ? Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.12)
                                : (libMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.07) : Qt.rgba(255, 255, 255, 0.035))
                            border.width: 1
                            border.color: isSelected ? studioRoot.accentBorder : (isInCanvas ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.04))

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 10

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: isInCanvas ? Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.20) : Qt.rgba(255, 255, 255, 0.06)
                                    border.width: 1
                                    border.color: isInCanvas ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.06)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: libraryCard.modelData.icon
                                        font.family: studioRoot.iconFontFamily
                                        font.pixelSize: 13
                                        color: isInCanvas ? studioRoot.accentColor : studioRoot.textMuted
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 42 - actionBtn.width - 12
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        text: libraryCard.modelData.name
                                        font.family: studioRoot.textFontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: isInCanvas ? studioRoot.textPrimary : studioRoot.textSecondary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: libraryCard.modelData.desc || ""
                                        font.family: studioRoot.textFontFamily
                                        font.pixelSize: 9
                                        color: studioRoot.textMuted
                                        elide: Text.ElideRight
                                    }
                                }

                                // Action Button (+ Aggiungi / Seleziona / Rimuovi)
                                Rectangle {
                                    id: actionBtn
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: btnRow.width + 12
                                    height: 26
                                    radius: 13
                                    color: isInCanvas
                                        ? (btnMouse.containsMouse ? "#33ff453a" : Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.16))
                                        : (btnMouse.containsMouse ? studioRoot.accentColor : Qt.rgba(255, 255, 255, 0.08))
                                    border.width: 1
                                    border.color: isInCanvas
                                        ? (btnMouse.containsMouse ? "#ff453a" : studioRoot.accentBorder)
                                        : Qt.rgba(255, 255, 255, 0.12)

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Row {
                                        id: btnRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: isInCanvas ? (btnMouse.containsMouse ? "✕" : "✓") : "+"
                                            font.family: studioRoot.iconFontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: isInCanvas
                                                ? (btnMouse.containsMouse ? "#ff453a" : studioRoot.accentColor)
                                                : (btnMouse.containsMouse ? "#10141b" : studioRoot.textPrimary)
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: isInCanvas ? (btnMouse.containsMouse ? "Rimuovi" : "Attivo") : "Aggiungi"
                                            font.family: studioRoot.textFontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.Medium
                                            color: isInCanvas
                                                ? (btnMouse.containsMouse ? "#ff453a" : studioRoot.accentColor)
                                                : (btnMouse.containsMouse ? "#10141b" : studioRoot.textPrimary)
                                        }
                                    }

                                    MouseArea {
                                        id: btnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (libraryCard.isInCanvas) {
                                                studioRoot.setModuleActive(libraryCard.modelData.id, false);
                                            } else {
                                                studioRoot.setModuleActive(libraryCard.modelData.id, true);
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: libMouse
                                anchors.fill: parent
                                anchors.rightMargin: actionBtn.width + 12
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (libraryCard.isInCanvas) {
                                        studioRoot.selectedModuleId = libraryCard.modelData.id;
                                    } else {
                                        studioRoot.setModuleActive(libraryCard.modelData.id, true);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
