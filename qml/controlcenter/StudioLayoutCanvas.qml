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
    signal orientationChanged(string orientation)
    signal widthChanged(int width)

    // Current selection in canvas
    property string selectedModuleId: "wifi"
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    property bool isDraggingModule: false

    // Live list of modules
    property var modules: [
        { id: "header", name: "Orologio & Batteria", icon: "\uf017", colSpan: 2, height: 32, minHeight: 28, maxHeight: 44, active: true, desc: "Pillola superiore con orologio e percentuale batteria" },
        { id: "wifi", name: "Scheda Wi-Fi", icon: "\uf1eb", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Stato connessione, rete attiva e discovery drawer" },
        { id: "bluetooth", name: "Scheda Bluetooth", icon: "\uf294", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Controller bluetooth e periferiche connesse" },
        { id: "brightness", name: "Luminosità Display", icon: "\uf185", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Cursore retroilluminazione schermo" },
        { id: "volume", name: "Controllo Volume", icon: "\uf028", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Cursore volume audio master" },
        { id: "notifications", name: "Centro Notifiche", icon: "\uf0f3", colSpan: 2, height: 68, minHeight: 44, maxHeight: 160, active: true, desc: "Cronologia notifiche, contatore e cancellazione rapida" },
        { id: "battery", name: "Profilo Batteria TLP", icon: "\uf0e7", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Selettore Risparmio, Bilanciato, Prestazioni" },
        { id: "toggles", name: "Luce Notturna & Focus", icon: "\uf186", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Filtro luce blu e modalità non disturbare" },
        { id: "quickactions", name: "Barra & Appunti", icon: "\uf108", colSpan: 2, height: 44, minHeight: 32, maxHeight: 80, active: false, desc: "Pulsanti rapidi desktop workspace e cronologia appunti" }
    ]

    Component.onCompleted: {
        initializeFromConfig();
    }

    onRawConfigChanged: {
        initializeFromConfig();
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
                            merged.push({
                                id: m.id,
                                name: m.name,
                                icon: m.icon,
                                colSpan: s.colSpan !== undefined ? s.colSpan : m.colSpan,
                                height: s.height !== undefined ? s.height : m.height,
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
                height: modules[i].height,
                active: modules[i].active
            });
        }
        studioRoot.layoutChanged(clean);
    }

    function toggleColSpan(id) {
        let copy = modules.slice();
        for (let i = 0; i < copy.length; i++) {
            if (copy[i].id === id) {
                copy[i].colSpan = (copy[i].colSpan === 2) ? 1 : 2;
                break;
            }
        }
        modules = copy;
        emitSave();
    }

    function adjustModuleHeight(id, delta) {
        let copy = modules.slice();
        for (let i = 0; i < copy.length; i++) {
            if (copy[i].id === id) {
                const nh = Math.max(copy[i].minHeight || 28, Math.min(copy[i].maxHeight || 180, copy[i].height + delta));
                copy[i].height = nh;
                break;
            }
        }
        modules = copy;
        emitSave();
    }

    function setModuleActive(id, active) {
        let copy = modules.slice();
        for (let i = 0; i < copy.length; i++) {
            if (copy[i].id === id) {
                copy[i].active = active;
                break;
            }
        }
        modules = copy;
        if (active) studioRoot.selectedModuleId = id;
        else if (studioRoot.selectedModuleId === id) studioRoot.selectedModuleId = "";
        emitSave();
    }

    function moveModule(fromIdx, toIdx) {
        if (fromIdx < 0 || fromIdx >= modules.length || toIdx < 0 || toIdx >= modules.length || fromIdx === toIdx)
            return;
        let copy = modules.slice();
        let item = copy.splice(fromIdx, 1)[0];
        copy.splice(toIdx, 0, item);
        modules = copy;
        emitSave();
    }

    function resetToDefault() {
        modules = [
            { id: "header", name: "Orologio & Batteria", icon: "\uf017", colSpan: 2, height: 32, minHeight: 28, maxHeight: 44, active: true, desc: "Pillola superiore con orologio e percentuale batteria" },
            { id: "wifi", name: "Scheda Wi-Fi", icon: "\uf1eb", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Stato connessione, rete attiva e discovery drawer" },
            { id: "bluetooth", name: "Scheda Bluetooth", icon: "\uf294", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Controller bluetooth e periferiche connesse" },
            { id: "brightness", name: "Luminosità Display", icon: "\uf185", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Cursore retroilluminazione schermo" },
            { id: "volume", name: "Controllo Volume", icon: "\uf028", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Cursore volume audio master" },
            { id: "notifications", name: "Centro Notifiche", icon: "\uf0f3", colSpan: 2, height: 68, minHeight: 44, maxHeight: 160, active: true, desc: "Cronologia notifiche, contatore e cancellazione rapida" },
            { id: "battery", name: "Profilo Batteria TLP", icon: "\uf0e7", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Selettore Risparmio, Bilanciato, Prestazioni" },
            { id: "toggles", name: "Luce Notturna & Focus", icon: "\uf186", colSpan: 1, height: 46, minHeight: 32, maxHeight: 80, active: true, desc: "Filtro luce blu e modalità non disturbare" },
            { id: "quickactions", name: "Barra & Appunti", icon: "\uf108", colSpan: 2, height: 44, minHeight: 32, maxHeight: 80, active: false, desc: "Pulsanti rapidi desktop workspace e cronologia appunti" }
        ];
        studioRoot.selectedModuleId = "wifi";
        studioRoot.controlCenterOrientation = "vertical";
        studioRoot.controlCenterWidth = 420;
        studioRoot.orientationChanged("vertical");
        studioRoot.widthChanged(420);
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
                        text: "Studio Canvas & Griglia Isola"
                        font.family: studioRoot.textFontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: studioRoot.textPrimary
                    }
                    Text {
                        text: "Clicca su un modulo per ridimensionarlo con i pallini laterali o riposizionarlo."
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
                spacing: 8

                // Orientation toggle
                Rectangle {
                    width: 120
                    height: 30
                    radius: 8
                    color: Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 2

                        Rectangle {
                            width: (parent.width - 2) / 2
                            height: parent.height
                            radius: 6
                            color: studioRoot.controlCenterOrientation === "vertical" ? studioRoot.accentColor : StyleTokens.transparent
                            Text {
                                anchors.centerIn: parent
                                text: "Verticale"
                                font.family: studioRoot.textFontFamily
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: studioRoot.controlCenterOrientation === "vertical" ? "#10141b" : studioRoot.textSecondary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    studioRoot.controlCenterOrientation = "vertical";
                                    studioRoot.orientationChanged("vertical");
                                }
                            }
                        }

                        Rectangle {
                            width: (parent.width - 2) / 2
                            height: parent.height
                            radius: 6
                            color: studioRoot.controlCenterOrientation === "horizontal" ? studioRoot.accentColor : StyleTokens.transparent
                            Text {
                                anchors.centerIn: parent
                                text: "Orizzontale"
                                font.family: studioRoot.textFontFamily
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: studioRoot.controlCenterOrientation === "horizontal" ? "#10141b" : studioRoot.textSecondary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    studioRoot.controlCenterOrientation = "horizontal";
                                    studioRoot.orientationChanged("horizontal");
                                }
                            }
                        }
                    }
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
                width: Math.min(stageContainer.width - 40, studioRoot.controlCenterOrientation === "horizontal" ? 440 : 330)
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
                            readonly property real slotHeight: modelData.height || 42

                            visible: modelData.active
                            width: modelData.active ? slotWidth : 0
                            height: modelData.active ? slotHeight : 0

                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

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

                                    property real pressY: 0
                                    property bool dragging: false

                                    onPressed: function(mouse) {
                                        studioRoot.selectedModuleId = moduleItemDelegate.modelData.id;
                                        pressY = mouse.y;
                                        dragging = false;
                                    }

                                    onPositionChanged: function(mouse) {
                                        if (pressed && Math.abs(mouse.y - pressY) > 12) {
                                            dragging = true;
                                            studioRoot.isDraggingModule = true;
                                            studioRoot.dragSourceIndex = moduleItemDelegate.index;
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
                                    anchors.bottom: parent.top
                                    anchors.bottomMargin: 4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: 22
                                    width: pillRow.width + 14
                                    radius: 11
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
                                            text: moduleItemDelegate.modelData.name + " (" + (moduleItemDelegate.modelData.colSpan === 2 ? "100%" : "50%") + " • " + Math.round(moduleItemDelegate.modelData.height) + "px)"
                                            font.family: studioRoot.textFontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            color: studioRoot.textPrimary
                                        }

                                        // Move Earlier / Up button
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "▲"
                                            font.pixelSize: 9
                                            color: upMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                                            MouseArea {
                                                id: upMouse
                                                anchors.fill: parent
                                                anchors.margins: -3
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.moveModule(moduleItemDelegate.index, Math.max(0, moduleItemDelegate.index - 1))
                                            }
                                        }

                                        // Move Later / Down button
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "▼"
                                            font.pixelSize: 9
                                            color: downMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                                            MouseArea {
                                                id: downMouse
                                                anchors.fill: parent
                                                anchors.margins: -3
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.moveModule(moduleItemDelegate.index, Math.min(studioRoot.modules.length - 1, moduleItemDelegate.index + 1))
                                            }
                                        }

                                        // Span Width Toggle button
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "↔"
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                            color: spanMouse.containsMouse ? studioRoot.accentColor : studioRoot.textSecondary
                                            MouseArea {
                                                id: spanMouse
                                                anchors.fill: parent
                                                anchors.margins: -3
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.toggleColSpan(moduleItemDelegate.modelData.id)
                                            }
                                        }

                                        // Delete / Remove from grid button
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "✕"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: delMouse.containsMouse ? "#ff453a" : studioRoot.textSecondary
                                            MouseArea {
                                                id: delMouse
                                                anchors.fill: parent
                                                anchors.margins: -3
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioRoot.setModuleActive(moduleItemDelegate.modelData.id, false)
                                            }
                                        }
                                    }
                                }

                                // ====================================================
                                // RESIZE HANDLES ("PALLINI AL CENTRO DI TUTTI I LATI")
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
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeVerCursor

                                        property real startY: 0
                                        onPressed: function(mouse) { startY = mouse.y; }
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                let delta = startY - mouse.y;
                                                if (Math.abs(delta) >= 2) {
                                                    studioRoot.adjustModuleHeight(moduleItemDelegate.modelData.id, delta);
                                                }
                                            }
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
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.SizeVerCursor

                                        property real startY: 0
                                        onPressed: function(mouse) { startY = mouse.y; }
                                        onPositionChanged: function(mouse) {
                                            if (pressed) {
                                                let delta = mouse.y - startY;
                                                if (Math.abs(delta) >= 2) {
                                                    studioRoot.adjustModuleHeight(moduleItemDelegate.modelData.id, delta);
                                                }
                                            }
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
