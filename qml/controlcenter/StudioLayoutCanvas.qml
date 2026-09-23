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

    // Current selection & drag in canvas
    property string selectedModuleId: "wifi"
    property string draggedModuleId: ""
    property int dragTargetCol: 0
    property int dragTargetRow: 0
    property int dragTargetColSpan: 2
    property int dragTargetRowSpan: 1
    property real dragGhostX: 0
    property real dragGhostY: 0
    property real dragGhostW: 80
    property real dragGhostH: 80
    property string dragGhostName: ""
    property string dragGhostIcon: ""
    property int dragGhostColSpan: 1
    property bool isDraggingModule: false
    property bool isResizing: false
    readonly property bool isInteracting: isDraggingModule || isResizing
    property bool isStageHovered: false
    property bool isInternalSave: false
    property bool canvasInitialized: false

    readonly property var selectedModule: {
        for (let i = 0; i < modules.length; i++) {
            if (modules[i].id === selectedModuleId) return modules[i];
        }
        return null;
    }

    function getDefaultPos(id) {
        switch(id) {
        case "wifi": return { col: 0, row: 0, colSpan: 2, rowSpan: 1, height: 80 };
        case "bluetooth": return { col: 0, row: 1, colSpan: 2, rowSpan: 1, height: 80 };
        case "brightness": return { col: 2, row: 0, colSpan: 1, rowSpan: 2, height: 160 };
        case "volume": return { col: 3, row: 0, colSpan: 1, rowSpan: 2, height: 160 };
        case "notifications": return { col: 0, row: 2, colSpan: 4, rowSpan: 2, height: 160 };
        case "toggles": return { col: 0, row: 4, colSpan: 2, rowSpan: 1, height: 80 };
        case "battery": return { col: 0, row: 5, colSpan: 2, rowSpan: 1, height: 80 };
        case "quickactions": return { col: 2, row: 4, colSpan: 2, rowSpan: 1, height: 80 };
        default: return { col: 0, row: 6, colSpan: 2, rowSpan: 1, height: 80 };
        }
    }

    // Live list of modules with 2D Grid coordinates (iPadOS 18 style)
    property var modules: [
        { id: "header", name: "Orologio & Batteria", icon: "\uf017", col: 0, row: -1, colSpan: 4, rowSpan: 1, height: 32, minHeight: 32, maxHeight: 32, active: true, desc: "Pillola superiore con orologio e percentuale batteria" },
        { id: "wifi", name: "Scheda Wi-Fi", icon: "\uf1eb", col: 0, row: 0, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Stato connessione, rete attiva e discovery drawer" },
        { id: "bluetooth", name: "Scheda Bluetooth", icon: "\uf294", col: 0, row: 1, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Controller bluetooth e periferiche connesse" },
        { id: "brightness", name: "Luminosità Display", icon: "\uf185", col: 2, row: 0, colSpan: 1, rowSpan: 2, height: 160, minHeight: 80, maxHeight: 240, active: true, desc: "Cursore retroilluminazione schermo" },
        { id: "volume", name: "Controllo Volume", icon: "\uf028", col: 3, row: 0, colSpan: 1, rowSpan: 2, height: 160, minHeight: 80, maxHeight: 240, active: true, desc: "Cursore volume audio master" },
        { id: "notifications", name: "Centro Notifiche", icon: "\uf0f3", col: 0, row: 2, colSpan: 4, rowSpan: 2, height: 160, minHeight: 80, maxHeight: 240, active: true, desc: "Cronologia notifiche, contatore e cancellazione rapida" },
        { id: "toggles", name: "Luce Notturna & Focus", icon: "\uf186", col: 0, row: 4, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: false, desc: "Filtro luce blu e modalità non disturbare" },
        { id: "battery", name: "Profilo Batteria TLP", icon: "\uf0e7", col: 0, row: 5, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: false, desc: "Selettore Risparmio, Bilanciato, Prestazioni" },
        { id: "quickactions", name: "Barra & Appunti", icon: "\uf108", col: 2, row: 4, colSpan: 2, rowSpan: 1, height: 80, minHeight: 48, maxHeight: 96, active: false, desc: "Pulsanti rapidi desktop workspace e cronologia appunti" }
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
        const snapped = Math.round(rawH / 80) * 80;
        return Math.max(80, Math.min(240, snapped));
    }

    function defaultHeight(id) {
        switch(id) {
        case "header": return 32;
        case "brightness":
        case "volume": return 160;
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

                let headerDef = {
                    id: "header", name: "Orologio & Batteria", icon: "\uf017", col: 0, row: -1, colSpan: 4, rowSpan: 1, height: 32, minHeight: 32, maxHeight: 32, active: true, desc: "Pillola superiore con orologio e percentuale batteria"
                };
                merged.push(headerDef);
                seen["header"] = true;

                for (let i = 0; i < saved.length; i++) {
                    let s = saved[i];
                    if (s.id === "header") continue;
                    for (let j = 0; j < modules.length; j++) {
                        let m = modules[j];
                        if (m.id === s.id) {
                            let def = getDefaultPos(m.id);
                            let targetH = s.height !== undefined ? snapHeight(m.id, s.height) : defaultHeight(m.id);
                            let rSpan = s.rowSpan !== undefined ? Math.max(1, Math.min(3, Number(s.rowSpan) || 1)) : (targetH >= 140 ? 2 : def.rowSpan);
                            let cSpan = s.colSpan !== undefined ? Math.max(1, Math.min(4, Number(s.colSpan) || 1)) : def.colSpan;
                            let col = s.col !== undefined ? Math.max(0, Math.min(4 - cSpan, Number(s.col) || 0)) : def.col;
                            let row = s.row !== undefined ? Math.max(0, Number(s.row) || 0) : def.row;

                            merged.push({
                                id: m.id,
                                name: m.name,
                                icon: m.icon,
                                col: col,
                                row: row,
                                colSpan: cSpan,
                                rowSpan: rSpan,
                                height: rSpan * 80,
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
                    if (!seen[m.id]) {
                        let def = getDefaultPos(m.id);
                        merged.push(Object.assign({}, m, def));
                    }
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
        clean.push({
            id: "header",
            col: 0,
            row: -1,
            colSpan: 4,
            rowSpan: 1,
            height: 32,
            active: true
        });

        for (let i = 0; i < modules.length; i++) {
            let m = modules[i];
            if (m.id === "header") continue;
            let cSpan = Math.max(1, Math.min(4, Number(m.colSpan) || 1));
            let rSpan = Math.max(1, Math.min(3, Number(m.rowSpan) || (m.height >= 140 ? 2 : 1)));
            clean.push({
                id: m.id,
                col: m.col !== undefined ? Math.max(0, Math.min(4 - cSpan, Number(m.col) || 0)) : 0,
                row: m.row !== undefined ? Math.max(0, Number(m.row) || 0) : 0,
                colSpan: cSpan,
                rowSpan: rSpan,
                height: rSpan * 80,
                active: m.active
            });
        }
        isInternalSave = true;
        studioRoot.layoutChanged(clean);
        isInternalSave = false;
    }

    function resolveResizeCollisions(expandedId, copy) {
        let exp = null;
        for (let i = 0; i < copy.length; i++) {
            if (copy[i].id === expandedId) { exp = copy[i]; break; }
        }
        if (!exp) return;

        let expCol = exp.col || 0;
        let expRow = exp.row || 0;
        let expCSpan = exp.colSpan || 1;
        let expRSpan = exp.rowSpan || 1;

        let iterations = 0;
        let hasCollision = true;
        while (hasCollision && iterations < 20) {
            hasCollision = false;
            iterations++;
            for (let i = 0; i < copy.length; i++) {
                let m = copy[i];
                if (m.id === expandedId || m.id === "header" || !m.active) continue;
                let mCol = m.col || 0;
                let mRow = m.row || 0;
                let mCSpan = m.colSpan || 1;
                let mRSpan = m.rowSpan || 1;

                let overlapX = (expCol < mCol + mCSpan) && (expCol + expCSpan > mCol);
                let overlapY = (expRow < mRow + mRSpan) && (expRow + expRSpan > mRow);

                if (overlapX && overlapY) {
                    m.row = expRow + expRSpan;
                    hasCollision = true;
                }
            }
        }
    }

    function adjustModuleColSpan(id, delta) {
        if (id === "header") return;
        let copy = [];
        let changed = false;
        for (let i = 0; i < modules.length; i++) {
            let m = Object.assign({}, modules[i]);
            if (m.id === id) {
                let curr = Number(m.colSpan) || 1;
                let next = Math.max(1, Math.min(4, curr + delta));
                if (m.colSpan !== next) {
                    m.colSpan = next;
                    if (m.col + next > 4) {
                        m.col = 4 - next;
                    }
                    changed = true;
                }
            }
            copy.push(m);
        }
        if (changed) {
            resolveResizeCollisions(id, copy);
            selectedModuleId = id;
            modules = copy;
            emitSave();
        }
    }

    function adjustModuleRowSpan(id, delta) {
        if (id === "header") return;
        let copy = [];
        let changed = false;
        for (let i = 0; i < modules.length; i++) {
            let m = Object.assign({}, modules[i]);
            if (m.id === id) {
                let curr = Number(m.rowSpan) || (m.height >= 140 ? 2 : 1);
                let next = Math.max(1, Math.min(3, curr + delta));
                if (m.rowSpan !== next) {
                    m.rowSpan = next;
                    m.height = next * 80;
                    changed = true;
                }
            }
            copy.push(m);
        }
        if (changed) {
            resolveResizeCollisions(id, copy);
            selectedModuleId = id;
            modules = copy;
            emitSave();
        }
    }

    function toggleColSpan(id) {
        if (id === "header") return;
        for (let i = 0; i < modules.length; i++) {
            if (modules[i].id === id) {
                let next = (Number(modules[i].colSpan) || 1) + 1;
                if (next > 4) next = 1;
                adjustModuleColSpan(id, next - modules[i].colSpan);
                break;
            }
        }
    }

    function anchorModuleToSlot(id, targetCol, targetRow) {
        if (id === "header") return;
        let targetModule = null;
        let otherModules = [];

        for (let i = 0; i < modules.length; i++) {
            let m = Object.assign({}, modules[i]);
            if (m.id === id) {
                targetModule = m;
            } else {
                otherModules.push(m);
            }
        }
        if (!targetModule) return;

        let oldCol = targetModule.col !== undefined ? targetModule.col : 0;
        let oldRow = targetModule.row !== undefined ? targetModule.row : 0;
        let cSpan = targetModule.colSpan || 1;
        let rSpan = targetModule.rowSpan || 1;

        targetCol = Math.max(0, Math.min(4 - cSpan, targetCol));
        targetRow = Math.max(0, targetRow);

        if (targetCol === oldCol && targetRow === oldRow) return;

        targetModule.col = targetCol;
        targetModule.row = targetRow;

        // Collision check and swap/shift with overlapping active modules
        for (let j = 0; j < otherModules.length; j++) {
            let om = otherModules[j];
            if (!om.active || om.id === "header") continue;

            let omCol = om.col !== undefined ? om.col : 0;
            let omRow = om.row !== undefined ? om.row : 0;
            let omCSpan = om.colSpan || 1;
            let omRSpan = om.rowSpan || 1;

            let overlapX = (targetCol < omCol + omCSpan) && (targetCol + cSpan > omCol);
            let overlapY = (targetRow < omRow + omRSpan) && (targetRow + rSpan > omRow);

            if (overlapX && overlapY) {
                if (oldCol + omCSpan <= 4) {
                    om.col = oldCol;
                    om.row = oldRow;
                } else {
                    om.col = Math.max(0, 4 - omCSpan);
                    om.row = oldRow;
                }
            }
        }

        let newModules = [targetModule].concat(otherModules);
        newModules.sort((a, b) => {
            if (a.id === "header") return -1;
            if (b.id === "header") return 1;
            let rowA = a.row !== undefined ? a.row : 0;
            let rowB = b.row !== undefined ? b.row : 0;
            if (rowA !== rowB) return rowA - rowB;
            let colA = a.col !== undefined ? a.col : 0;
            let colB = b.col !== undefined ? b.col : 0;
            return colA - colB;
        });

        selectedModuleId = id;
        modules = newModules;
        emitSave();
    }

    function nudgeSelectedModule(dCol, dRow) {
        if (!selectedModule || selectedModuleId === "header") return;
        let cSpan = selectedModule.colSpan || 1;
        let curCol = selectedModule.col !== undefined ? selectedModule.col : 0;
        let curRow = selectedModule.row !== undefined ? selectedModule.row : 0;
        let newCol = Math.max(0, Math.min(4 - cSpan, curCol + dCol));
        let newRow = Math.max(0, curRow + dRow);
        anchorModuleToSlot(selectedModuleId, newCol, newRow);
    }

    function setModuleActive(id, active) {
        if (id === "header") return;
        let copy = [];
        for (let i = 0; i < modules.length; i++) {
            let m = Object.assign({}, modules[i]);
            if (m.id === id) {
                m.active = active;
                if (active) {
                    let maxR = 0;
                    for (let k = 0; k < modules.length; k++) {
                        if (modules[k].active && modules[k].id !== "header") {
                            let br = (modules[k].row !== undefined ? modules[k].row : 0) + (modules[k].rowSpan || 1);
                            if (br > maxR) maxR = br;
                        }
                    }
                    m.row = maxR;
                    m.col = 0;
                }
            }
            copy.push(m);
        }
        modules = copy;
        if (active) studioRoot.selectedModuleId = id;
        else if (studioRoot.selectedModuleId === id) studioRoot.selectedModuleId = "";
        emitSave();
    }

    function resetToDefault() {
        modules = [
            { id: "header", name: "Orologio & Batteria", icon: "\uf017", col: 0, row: -1, colSpan: 4, rowSpan: 1, height: 32, minHeight: 32, maxHeight: 32, active: true, desc: "Pillola superiore con orologio e percentuale batteria" },
            { id: "wifi", name: "Scheda Wi-Fi", icon: "\uf1eb", col: 0, row: 0, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Stato connessione, rete attiva e discovery drawer" },
            { id: "bluetooth", name: "Scheda Bluetooth", icon: "\uf294", col: 0, row: 1, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Controller bluetooth e periferiche connesse" },
            { id: "brightness", name: "Luminosità Display", icon: "\uf185", col: 2, row: 0, colSpan: 1, rowSpan: 2, height: 160, minHeight: 80, maxHeight: 240, active: true, desc: "Cursore retroilluminazione schermo" },
            { id: "volume", name: "Controllo Volume", icon: "\uf028", col: 3, row: 0, colSpan: 1, rowSpan: 2, height: 160, minHeight: 80, maxHeight: 240, active: true, desc: "Cursore volume audio master" },
            { id: "toggles", name: "Luce Notturna & Focus", icon: "\uf186", col: 0, row: 2, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Filtro luce blu e modalità non disturbare" },
            { id: "notifications", name: "Centro Notifiche", icon: "\uf0f3", col: 2, row: 2, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Cronologia notifiche, contatore e cancellazione rapida" },
            { id: "battery", name: "Profilo Batteria TLP", icon: "\uf0e7", col: 0, row: 3, colSpan: 2, rowSpan: 1, height: 80, minHeight: 80, maxHeight: 240, active: true, desc: "Selettore Risparmio, Bilanciato, Prestazioni" },
            { id: "quickactions", name: "Barra & Appunti", icon: "\uf108", col: 2, row: 3, colSpan: 2, rowSpan: 1, height: 80, minHeight: 48, maxHeight: 96, active: false, desc: "Pulsanti rapidi desktop workspace e cronologia appunti" }
        ];
        studioRoot.selectedModuleId = "wifi";
        emitSave();
    }

    width: parent.width
    implicitHeight: mainColumn.implicitHeight
    height: implicitHeight

    Column {
        id: mainColumn
        width: parent.width
        spacing: 16

        // ====================================================
        // TOP CONTROLS & CANVAS STATUS
        // ====================================================
        Rectangle {
            width: parent.width
            implicitHeight: topBarCol.implicitHeight + 20
            radius: 16
            color: studioRoot.bgCard
            border.width: 1
            border.color: studioRoot.borderCard

            Column {
                id: topBarCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                // Line 1: Canvas Title & Subtitle (Left) + Ripristina & Ricarica (Right)
                Item {
                    width: parent.width
                    height: 32

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9

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
                            spacing: 1
                            Text {
                                text: "Studio Canvas • Griglia a Caselle"
                                font.family: studioRoot.textFontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: studioRoot.textPrimary
                            }
                            Text {
                                text: "Trascina per ordinare • Ridimensiona per caselle stile iOS"
                                font.family: studioRoot.textFontFamily
                                font.pixelSize: 10
                                color: studioRoot.textMuted
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Reset Layout Button
                        Rectangle {
                            width: resetRow.width + 14
                            height: 28
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
                                    text: ""
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
                            width: reloadRow.width + 14
                            height: 28
                            radius: 8
                            color: reloadMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.05)
                            border.width: 1
                            border.color: reloadMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                id: reloadRow
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ""
                                    font.family: studioRoot.iconFontFamily
                                    font.pixelSize: 11
                                    color: studioRoot.accentColor
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Ricarica"
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

                // Line 2: Contextual Module Controls Bar (When selected)
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(255, 255, 255, 0.06)
                    visible: studioRoot.selectedModule !== null
                }

                Item {
                    width: parent.width
                    height: 28
                    visible: studioRoot.selectedModule !== null

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: studioRoot.selectedModule ? studioRoot.selectedModule.icon : ""
                            font.family: studioRoot.iconFontFamily
                            font.pixelSize: 12
                            color: studioRoot.accentColor
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: studioRoot.selectedModule ? (studioRoot.selectedModule.id === "header" ? "Orologio & Batteria (Fisso in Cima)" : (studioRoot.selectedModule.name + " (" + studioRoot.selectedModule.colSpan + "/4 Col)")) : ""
                            font.family: studioRoot.textFontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: studioRoot.textPrimary
                        }
                    }

                    // Header locked pill when selected
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: studioRoot.selectedModuleId === "header"
                        height: 26
                        width: lockedRow.width + 16
                        radius: 6
                        color: Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.10)

                        Row {
                            id: lockedRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: ""
                                font.family: studioRoot.iconFontFamily
                                font.pixelSize: 10
                                color: studioRoot.accentColor
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Barra Fissa in Cima (Immobile)"
                                font.family: studioRoot.textFontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                color: studioRoot.textPrimary
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        visible: studioRoot.selectedModuleId !== "header"

                        // 4-Way Grid Nudge [ ◀ ] [ ▶ ] [ ▲ ] [ ▼ ]
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Rectangle {
                                width: 24; height: 26; radius: 6
                                color: barLeftMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: barLeftMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                                anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: "◀"; font.pixelSize: 8; color: barLeftMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary }
                                MouseArea {
                                    id: barLeftMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioRoot.nudgeSelectedModule(-1, 0)
                                }
                            }

                            Rectangle {
                                width: 24; height: 26; radius: 6
                                color: barRightMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: barRightMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                                anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: "▶"; font.pixelSize: 8; color: barRightMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary }
                                MouseArea {
                                    id: barRightMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioRoot.nudgeSelectedModule(1, 0)
                                }
                            }

                            Rectangle {
                                width: 24; height: 26; radius: 6
                                color: barUpMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: barUpMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                                anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: 8; color: barUpMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary }
                                MouseArea {
                                    id: barUpMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioRoot.nudgeSelectedModule(0, -1)
                                }
                            }

                            Rectangle {
                                width: 24; height: 26; radius: 6
                                color: barDownMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: barDownMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                                anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: 8; color: barDownMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary }
                                MouseArea {
                                    id: barDownMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioRoot.nudgeSelectedModule(0, 1)
                                }
                            }
                        }

                        // Stepper Altezza / Righe: [ − ] [ X Righe ] [ + ]
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
                                    onClicked: studioRoot.adjustModuleRowSpan(studioRoot.selectedModuleId, -1)
                                }
                            }

                            Rectangle {
                                width: 56; height: 26; radius: 6
                                color: Qt.rgba(0, 0, 0, 0.25)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.08)
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: studioRoot.selectedModule ? (studioRoot.selectedModule.rowSpan + (studioRoot.selectedModule.rowSpan === 1 ? " Riga" : " Righe")) : "1 Riga"
                                    font.family: studioRoot.textFontFamily
                                    font.pixelSize: 10
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
                                    onClicked: studioRoot.adjustModuleRowSpan(studioRoot.selectedModuleId, 1)
                                }
                            }
                        }

                        // Stepper Larghezza: [ − ] [ X Col ] [ + ] (1=min, 4=max)
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Rectangle {
                                width: 26; height: 26; radius: 6
                                color: barColMinusMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: barColMinusMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                                anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 14; font.weight: Font.Bold; color: studioRoot.accentColor }
                                MouseArea {
                                    id: barColMinusMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioRoot.adjustModuleColSpan(studioRoot.selectedModuleId, -1)
                                }
                            }

                            Rectangle {
                                width: 56; height: 26; radius: 6
                                color: barWidthMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(0, 0, 0, 0.25)
                                border.width: 1
                                border.color: barWidthMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.08)
                                anchors.verticalCenter: parent.verticalCenter
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "↔"; font.pixelSize: 10; font.weight: Font.Bold; color: studioRoot.accentColor }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: studioRoot.selectedModule ? (studioRoot.selectedModule.colSpan + " Col") : "1 Col"
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

                            Rectangle {
                                width: 26; height: 26; radius: 6
                                color: barColPlusMouse.containsMouse ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: barColPlusMouse.containsMouse ? studioRoot.accentBorder : Qt.rgba(255, 255, 255, 0.10)
                                anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 14; font.weight: Font.Bold; color: studioRoot.accentColor }
                                MouseArea {
                                    id: barColPlusMouse
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioRoot.adjustModuleColSpan(studioRoot.selectedModuleId, 1)
                                }
                            }
                        }

                        // Remove / Delete button [ Trash ]
                        Rectangle {
                            width: 26; height: 26; radius: 6
                            color: barDelMouse.containsMouse ? Qt.rgba(255, 69, 58, 0.22) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: barDelMouse.containsMouse ? Qt.rgba(255, 69, 58, 0.45) : Qt.rgba(255, 255, 255, 0.10)
                            anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: ""; font.family: studioRoot.iconFontFamily; font.pixelSize: 11; font.weight: Font.Bold; color: barDelMouse.containsMouse ? "#ff453a" : studioRoot.textSecondary }
                            MouseArea {
                                id: barDelMouse
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: studioRoot.setModuleActive(studioRoot.selectedModuleId, false)
                            }
                        }
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
            height: Math.max(760, islandCapsule.height + 80)
            radius: 20
            color: "#0c0f16"
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.08)
            clip: true

            Behavior on height {
                enabled: !studioRoot.isResizing
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            // Subtle CAD/Blueprint Grid Pattern
            Item {
                anchors.fill: parent
                opacity: 0.14

                Repeater {
                    model: Math.max(0, Math.ceil(stageContainer.width / 24))
                    Rectangle {
                        x: index * 24
                        y: 0
                        width: 1
                        height: stageContainer.height
                        color: "#5c7099"
                    }
                }

                Repeater {
                    model: Math.max(0, Math.ceil(stageContainer.height / 24))
                    Rectangle {
                        x: 0
                        y: index * 24
                        width: stageContainer.width
                        height: 1
                        color: "#5c7099"
                    }
                }
            }

            // Click outside deselects & stage hover tracking
            MouseArea {
                id: stageBgMouse
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: false
                onContainsMouseChanged: studioRoot.isStageHovered = containsMouse
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
                    text: "AREA LIVE CANVAS • WORKSPACE 8 RIGHE • " + studioRoot.controlCenterWidth + "px"
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
                width: 374
                height: 12 + 32 + 10 + gridCaselleArea.height + 24
                radius: 24
                color: Qt.rgba(18/255, 22/255, 30/255, 0.94)
                border.width: 1.5
                border.color: Qt.rgba(255, 255, 255, 0.12)

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                Behavior on height {
                    enabled: !studioRoot.isResizing
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

                // Header Module at Top (Clock & Battery)
                Item {
                    id: headerSlotItem
                    anchors.top: parent.top
                    anchors.topMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 350
                    height: 32

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: studioRoot.selectedModuleId === "header" ? studioRoot.accentSoft : Qt.rgba(255, 255, 255, 0.06)
                        border.width: studioRoot.selectedModuleId === "header" ? 2 : 1
                        border.color: studioRoot.selectedModuleId === "header" ? studioRoot.accentColor : Qt.rgba(255, 255, 255, 0.08)

                        Item {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "16:15"
                                font.family: studioRoot.heroFontFamily
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: studioRoot.textPrimary
                            }

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

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: studioRoot.selectedModuleId = "header"
                        }
                    }
                }

                // Grid of Caselle & Modules Area
                Item {
                    id: gridCaselleArea
                    anchors.top: headerSlotItem.bottom
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 350
                    height: totalGridRows * 80 + (totalGridRows - 1) * 10

                    readonly property int totalGridRows: {
                        let maxR = 3;
                        for (let i = 0; i < studioRoot.modules.length; i++) {
                            let m = studioRoot.modules[i];
                            if (m && m.active && m.id !== "header") {
                                let r = (m.row !== undefined && m.row >= 0) ? m.row : 0;
                                let rs = Math.max(1, Math.min(3, Number(m.rowSpan) || (m.height >= 140 ? 2 : 1)));
                                if (r + rs > maxR) maxR = r + rs;
                            }
                        }
                        return maxR + 1; // Always at least 1 extra empty row below for easy drop
                    }

                    function isSlotOccupied(c, r) {
                        for (let i = 0; i < studioRoot.modules.length; i++) {
                            let m = studioRoot.modules[i];
                            if (m && m.active && m.id !== "header") {
                                let mc = (m.col !== undefined && m.col >= 0) ? m.col : 0;
                                let mr = (m.row !== undefined && m.row >= 0) ? m.row : 0;
                                let mcs = m.colSpan || 1;
                                let mrs = m.rowSpan || 1;
                                if (c >= mc && c < mc + mcs && r >= mr && r < mr + mrs) {
                                    return true;
                                }
                            }
                        }
                        return false;
                    }

                    // Layer 0: The Caselle (iPadOS 18 Circular Slots)
                    Repeater {
                        model: Math.max(0, gridCaselleArea.totalGridRows * 4)

                        delegate: Rectangle {
                            required property int index
                            readonly property int col: index % 4
                            readonly property int row: Math.floor(index / 4)

                            x: col * (80 + 10)
                            y: row * (80 + 10)
                            width: 80
                            height: 80
                            radius: 20

                            readonly property bool isDropTarget: studioRoot.isDraggingModule &&
                                                                col >= studioRoot.dragTargetCol &&
                                                                col < studioRoot.dragTargetCol + studioRoot.dragTargetColSpan &&
                                                                row >= studioRoot.dragTargetRow &&
                                                                row < studioRoot.dragTargetRow + studioRoot.dragTargetRowSpan

                            color: isDropTarget
                                ? studioRoot.accentSoft
                                : Qt.rgba(255, 255, 255, 0.055)
                            border.width: isDropTarget ? 2 : 1
                            border.color: isDropTarget ? studioRoot.accentColor : Qt.rgba(255, 255, 255, 0.08)
                            scale: isDropTarget ? 1.05 : 1.0

                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            // Subtle dot for empty caselle
                            Rectangle {
                                anchors.centerIn: parent
                                width: 6
                                height: 6
                                radius: 3
                                color: parent.isDropTarget ? studioRoot.accentColor : Qt.rgba(255, 255, 255, 0.12)
                                visible: !gridCaselleArea.isSlotOccupied(col, row)
                            }
                        }
                    }

                    // Layer 1: Active Modules positioned on Grid
                    Repeater {
                        id: modulesRepeater
                        model: studioRoot.modules

                        delegate: Item {
                            id: moduleItemDelegate
                            required property int index
                            required property var modelData

                            visible: modelData.active && modelData.id !== "header"

                            readonly property bool isSelected: studioRoot.selectedModuleId === modelData.id
                            readonly property int col: (modelData.col !== undefined && modelData.col >= 0) ? modelData.col : 0
                            readonly property int row: (modelData.row !== undefined && modelData.row >= 0) ? modelData.row : 0
                            readonly property int colSpan: Math.max(1, Math.min(4, Number(modelData.colSpan) || 1))
                            readonly property int rowSpan: Math.max(1, Math.min(3, Number(modelData.rowSpan) || (modelData.height >= 140 ? 2 : 1)))

                            readonly property real slotWidth: colSpan === 4 ? 350 : (colSpan * 80 + (colSpan - 1) * 10)
                            property real overrideHeight: 0
                            readonly property real slotHeight: (overrideHeight > 0) ? overrideHeight : (rowSpan * 80 + (rowSpan - 1) * 10)
                            readonly property bool isOneByOne: colSpan === 1 && rowSpan === 1

                            x: col * (80 + 10)
                            y: row * (80 + 10)
                            width: slotWidth
                            height: slotHeight
                            opacity: (studioRoot.isDraggingModule && studioRoot.draggedModuleId === modelData.id) ? 0.30 : 1.0
                            z: isSelected ? 25 : 10

                            Behavior on x {
                                enabled: !studioRoot.isDraggingModule
                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                            }
                            Behavior on y {
                                enabled: !studioRoot.isDraggingModule
                                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                            }
                            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            Behavior on height {
                                enabled: !studioRoot.isResizing && !bottomHandleMouse.pressed
                                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                            }

                            // Card Surface
                            Rectangle {
                                id: cardBody
                                anchors.fill: parent
                                radius: 20
                                color: moduleMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.065)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.09)

                                Behavior on color { ColorAnimation { duration: 120 } }

                                // Module Content Rendering
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: moduleItemDelegate.isOneByOne ? 0 : 8

                                    // 1x1 Circular Tile UI (Solo Icona centrata stile iPad)
                                    Item {
                                        visible: moduleItemDelegate.isOneByOne
                                        anchors.fill: parent

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 44
                                            height: 44
                                            radius: 22
                                            color: Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.20)
                                            border.width: 1
                                            border.color: Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.35)

                                            Text {
                                                anchors.centerIn: parent
                                                text: moduleItemDelegate.modelData.icon
                                                font.family: studioRoot.iconFontFamily
                                                font.pixelSize: 18
                                                color: studioRoot.accentColor
                                            }
                                        }
                                    }

                                    // Standard / Expanded Module UI
                                    Row {
                                        visible: !moduleItemDelegate.isOneByOne
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 6
                                        spacing: 8

                                        Rectangle {
                                            width: 26
                                            height: 26
                                            radius: 13
                                            color: Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.20)
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                anchors.centerIn: parent
                                                text: moduleItemDelegate.modelData.icon
                                                font.family: studioRoot.iconFontFamily
                                                font.pixelSize: 11
                                                color: studioRoot.accentColor
                                            }
                                        }

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2
                                            width: parent.width - 38

                                            Text {
                                                width: parent.width
                                                text: moduleItemDelegate.modelData.name
                                                font.family: studioRoot.textFontFamily
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                color: studioRoot.textPrimary
                                                elide: Text.ElideRight
                                            }

                                            // Mini interactive visual details
                                            Item {
                                                width: parent.width
                                                height: 10
                                                visible: (moduleItemDelegate.modelData.id === "brightness" || moduleItemDelegate.modelData.id === "volume") && (moduleItemDelegate.slotHeight < 110 || moduleItemDelegate.colSpan > 1)

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
                                                visible: (moduleItemDelegate.modelData.id === "brightness" || moduleItemDelegate.modelData.id === "volume") && (moduleItemDelegate.slotHeight >= 110 && moduleItemDelegate.colSpan === 1)
                                                text: "Cursore Verticale"
                                                font.family: studioRoot.textFontFamily
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold
                                                color: studioRoot.accentColor
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                visible: moduleItemDelegate.modelData.id === "notifications"
                                                text: "Centro Notifiche"
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

                                // Drag & Click MouseArea
                                MouseArea {
                                    id: moduleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: true
                                    cursorShape: isSelected ? Qt.SizeAllCursor : Qt.PointingHandCursor

                                    property real pressStageX: 0
                                    property real pressStageY: 0
                                    property bool isDragging: false

                                    onPressed: function(mouse) {
                                        studioRoot.selectedModuleId = moduleItemDelegate.modelData.id;
                                        let p = mapToItem(stageContainer, mouse.x, mouse.y);
                                        pressStageX = p.x;
                                        pressStageY = p.y;
                                        isDragging = false;
                                    }

                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            let stagePos = mapToItem(stageContainer, mouse.x, mouse.y);
                                            if (!isDragging && (Math.abs(stagePos.x - pressStageX) > 8 || Math.abs(stagePos.y - pressStageY) > 8)) {
                                                isDragging = true;
                                                studioRoot.isDraggingModule = true;
                                                studioRoot.draggedModuleId = moduleItemDelegate.modelData.id;
                                                studioRoot.dragGhostW = moduleItemDelegate.width;
                                                studioRoot.dragGhostH = moduleItemDelegate.height;
                                                studioRoot.dragGhostName = moduleItemDelegate.modelData.name;
                                                studioRoot.dragGhostIcon = moduleItemDelegate.modelData.icon;
                                                studioRoot.dragGhostColSpan = moduleItemDelegate.colSpan;
                                                studioRoot.dragTargetColSpan = moduleItemDelegate.colSpan;
                                                studioRoot.dragTargetRowSpan = moduleItemDelegate.rowSpan;
                                            }

                                            if (isDragging) {
                                                studioRoot.dragGhostX = stagePos.x;
                                                studioRoot.dragGhostY = stagePos.y;

                                                let gridPos = mapToItem(gridCaselleArea, mouse.x, mouse.y);
                                                let targetC = Math.round((gridPos.x - (moduleItemDelegate.slotWidth / 2)) / 90);
                                                let targetR = Math.round((gridPos.y - (moduleItemDelegate.slotHeight / 2)) / 90);
                                                targetC = Math.max(0, Math.min(4 - moduleItemDelegate.colSpan, targetC));
                                                targetR = Math.max(0, targetR);

                                                studioRoot.dragTargetCol = targetC;
                                                studioRoot.dragTargetRow = targetR;
                                            }
                                        }
                                    }

                                    onReleased: function(mouse) {
                                        if (isDragging) {
                                            let targetC = studioRoot.dragTargetCol;
                                            let targetR = studioRoot.dragTargetRow;
                                            let modId = studioRoot.draggedModuleId;

                                            isDragging = false;
                                            studioRoot.isDraggingModule = false;
                                            studioRoot.draggedModuleId = "";

                                            studioRoot.anchorModuleToSlot(modId, targetC, targetR);
                                        }
                                    }

                                    onCanceled: {
                                        isDragging = false;
                                        studioRoot.isDraggingModule = false;
                                        studioRoot.draggedModuleId = "";
                                    }

                                    onClicked: {
                                        studioRoot.selectedModuleId = moduleItemDelegate.modelData.id;
                                    }
                                }
                            }

                            // Selection Box & Resize Handles
                            Rectangle {
                                id: boundingBox
                                anchors.fill: parent
                                anchors.margins: -2
                                radius: cardBody.radius + 2
                                color: Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.08)
                                border.width: 2
                                border.color: studioRoot.accentColor
                                visible: moduleItemDelegate.isSelected && !studioRoot.isDraggingModule
                                z: 50

                                Item {
                                    id: resizeHandlesContainer
                                    anchors.fill: parent

                                    // Bottom Handle
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
                                        scale: bottomHandleMouse.containsMouse || bottomHandleMouse.pressed ? 1.3 : 1.0

                                        Behavior on scale { NumberAnimation { duration: 100 } }

                                        MouseArea {
                                            id: bottomHandleMouse
                                            anchors.fill: parent
                                            anchors.margins: -10
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.SizeVerCursor

                                            property real startCursorStageY: 0
                                            property real startCardH: 0

                                            onPressed: function(mouse) {
                                                studioRoot.isResizing = true;
                                                let p = mapToItem(stageContainer, mouse.x, mouse.y);
                                                startCursorStageY = p.y;
                                                startCardH = moduleItemDelegate.slotHeight;
                                                moduleItemDelegate.overrideHeight = startCardH;
                                            }

                                            onPositionChanged: function(mouse) {
                                                if (pressed) {
                                                    let p = mapToItem(stageContainer, mouse.x, mouse.y);
                                                    let delta = p.y - startCursorStageY;
                                                    let rSpan = Math.max(1, Math.min(3, Math.round((startCardH + delta) / 90)));
                                                    moduleItemDelegate.overrideHeight = rSpan * 80 + (rSpan - 1) * 10;
                                                }
                                            }

                                            onReleased: {
                                                let targetH = moduleItemDelegate.overrideHeight;
                                                let modId = (moduleItemDelegate && moduleItemDelegate.modelData) ? moduleItemDelegate.modelData.id : "";
                                                let curSpan = moduleItemDelegate ? moduleItemDelegate.rowSpan : 1;
                                                moduleItemDelegate.overrideHeight = 0;
                                                studioRoot.isResizing = false;
                                                if (targetH > 0 && modId) {
                                                    let rSpan = Math.max(1, Math.min(3, Math.round(targetH / 90)));
                                                    studioRoot.adjustModuleRowSpan(modId, rSpan - curSpan);
                                                }
                                            }

                                            onCanceled: {
                                                moduleItemDelegate.overrideHeight = 0;
                                                studioRoot.isResizing = false;
                                            }
                                        }
                                    }

                                    // Right Handle (Width colSpan)
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
                                        scale: rightHandleMouse.containsMouse || rightHandleMouse.pressed ? 1.3 : 1.0

                                        Behavior on scale { NumberAnimation { duration: 100 } }

                                        MouseArea {
                                            id: rightHandleMouse
                                            anchors.fill: parent
                                            anchors.margins: -8
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.SizeHorCursor

                                            property real pressGlobalX: 0
                                            property bool toggledInDrag: false

                                            onPressed: function(mouse) {
                                                studioRoot.isResizing = true;
                                                pressGlobalX = mapToItem(gridCaselleArea, mouse.x, mouse.y).x;
                                                toggledInDrag = false;
                                            }
                                            onPositionChanged: function(mouse) {
                                                if (pressed && !toggledInDrag) {
                                                    let currentGlobalX = mapToItem(gridCaselleArea, mouse.x, mouse.y).x;
                                                    let diff = currentGlobalX - pressGlobalX;
                                                    let curr = moduleItemDelegate.colSpan;
                                                    let modId = (moduleItemDelegate && moduleItemDelegate.modelData) ? moduleItemDelegate.modelData.id : "";
                                                    if (diff > 40 && curr < 4 && modId) {
                                                        toggledInDrag = true;
                                                        studioRoot.adjustModuleColSpan(modId, 1);
                                                    } else if (diff < -40 && curr > 1 && modId) {
                                                        toggledInDrag = true;
                                                        studioRoot.adjustModuleColSpan(modId, -1);
                                                    }
                                                }
                                            }
                                            onReleased: {
                                                studioRoot.isResizing = false;
                                            }
                                            onCanceled: {
                                                studioRoot.isResizing = false;
                                            }
                                            onClicked: {
                                                if (!toggledInDrag) {
                                                    let modId = (moduleItemDelegate && moduleItemDelegate.modelData) ? moduleItemDelegate.modelData.id : "";
                                                    if (modId) {
                                                        studioRoot.toggleColSpan(modId);
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

            // Floating Drag & Drop Ghost
            Rectangle {
                id: dragGhost
                visible: studioRoot.isDraggingModule
                x: studioRoot.dragGhostX - width / 2
                y: studioRoot.dragGhostY - height / 2
                width: studioRoot.dragGhostW
                height: studioRoot.dragGhostH
                radius: (studioRoot.dragGhostColSpan === 1 && studioRoot.dragGhostH <= 100) ? 40 : 16
                color: Qt.rgba(20/255, 24/255, 34/255, 0.94)
                border.width: 2
                border.color: studioRoot.accentColor
                z: 200
                scale: 1.04
                opacity: 0.95

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: parent.radius + 4
                    color: StyleTokens.transparent
                    border.width: 2
                    border.color: studioRoot.accentSoft
                    z: -1
                }

                Item {
                    anchors.fill: parent
                    anchors.margins: 8

                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: studioRoot.accentSoft
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: studioRoot.dragGhostIcon
                                font.family: studioRoot.iconFontFamily
                                font.pixelSize: 14
                                color: studioRoot.accentColor
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: studioRoot.dragGhostColSpan > 1 || studioRoot.dragGhostH > 100
                            text: studioRoot.dragGhostName
                            font.family: studioRoot.textFontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: studioRoot.textPrimary
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
                            readonly property bool isHeader: modelData.id === "header"

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
                                    color: libraryCard.isHeader
                                        ? Qt.rgba(255, 255, 255, 0.05)
                                        : (isInCanvas
                                            ? (btnMouse.containsMouse ? "#33ff453a" : Qt.rgba(studioRoot.accentColor.r, studioRoot.accentColor.g, studioRoot.accentColor.b, 0.16))
                                            : (btnMouse.containsMouse ? studioRoot.accentColor : Qt.rgba(255, 255, 255, 0.08)))
                                    border.width: 1
                                    border.color: libraryCard.isHeader
                                        ? Qt.rgba(255, 255, 255, 0.10)
                                        : (isInCanvas
                                            ? (btnMouse.containsMouse ? "#ff453a" : studioRoot.accentBorder)
                                            : Qt.rgba(255, 255, 255, 0.12))

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Row {
                                        id: btnRow
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: libraryCard.isHeader ? "" : (isInCanvas ? (btnMouse.containsMouse ? "" : "✓") : "+")
                                            font.family: studioRoot.iconFontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: libraryCard.isHeader
                                                ? studioRoot.textSecondary
                                                : (isInCanvas
                                                    ? (btnMouse.containsMouse ? "#ff453a" : studioRoot.accentColor)
                                                    : (btnMouse.containsMouse ? "#10141b" : studioRoot.textPrimary))
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: libraryCard.isHeader ? "Fisso" : (isInCanvas ? (btnMouse.containsMouse ? "Rimuovi" : "Attivo") : "Aggiungi")
                                            font.family: studioRoot.textFontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.Medium
                                            color: libraryCard.isHeader
                                                ? studioRoot.textSecondary
                                                : (isInCanvas
                                                    ? (btnMouse.containsMouse ? "#ff453a" : studioRoot.accentColor)
                                                    : (btnMouse.containsMouse ? "#10141b" : studioRoot.textPrimary))
                                        }
                                    }

                                    MouseArea {
                                        id: btnMouse
                                        anchors.fill: parent
                                        hoverEnabled: !libraryCard.isHeader
                                        cursorShape: libraryCard.isHeader ? Qt.PointingHandCursor : Qt.PointingHandCursor
                                        onClicked: {
                                            if (libraryCard.isHeader) {
                                                studioRoot.selectedModuleId = "header";
                                                return;
                                            }
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
