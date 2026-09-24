import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Widgets
import IslandBackend

Rectangle {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")
    property var targetCapsule: null
    property var rootWindow: null
    property var userConfig: UserConfig
    property real islandTopMargin: 4
    property color accentColor: StyleTokens.accent

    property bool isExpanded: false
    property string headphonesBuffer: ""
    property var headphonesData: ({
        connected: false,
        name: "Nothing Ear (a)",
        address: "3C:B0:ED:AF:07:A4",
        anc: "transparency",
        anc_simplified: "transparency",
        battery: {
            left: { level: 0, charging: false, available: false },
            right: { level: 0, charging: false, available: false },
            case: { level: 0, charging: false, available: false }
        },
        bass: { enabled: false, level: 1 },
        latency: false,
        codec: "LDAC"
    })

    // Sizing:
    // A riposo: cerchio perfetto identico al modulo musica a sinistra (38x38)
    // Espanso: scheda nativa Dynamic Island (380px)
    readonly property real compactHeight: userConfig ? userConfig.islandHeight : 38
    readonly property real compactWidth: compactHeight
    readonly property real expandedWidth: 380
    readonly property real expandedHeight: {
        var base = 265;
        if (headphonesData.anc !== "off" && headphonesData.anc !== "transparency") base += 34;
        if (headphonesData.bass && headphonesData.bass.enabled) base += 34;
        return base;
    }

    width: isExpanded ? expandedWidth : compactWidth
    height: isExpanded ? expandedHeight : compactHeight
    radius: isExpanded ? 36 : compactHeight / 2

    // Posizionamento speculare: ancorato a destra della capsula principale a 7px
    anchors.left: targetCapsule ? targetCapsule.right : undefined
    anchors.leftMargin: 7
    anchors.top: targetCapsule ? targetCapsule.top : undefined

    // Visibilità condizionata alla connessione Bluetooth
    readonly property var adapter: Bluetooth.defaultAdapter
    property var nothingBtDevice: null

    function scanBluetooth() {
        if (!adapter || !adapter.devices) return;
        var devs = adapter.devices.values;
        for (var i = 0; i < devs.length; i++) {
            var d = devs[i];
            var addr = (d.address || "").toUpperCase();
            var name = (d.name || d.deviceName || "").toLowerCase();
            if (addr === "3C:B0:ED:AF:07:A4" || name.indexOf("nothing ear") !== -1) {
                if (nothingBtDevice !== d) nothingBtDevice = d;
                return;
            }
        }
    }

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() { root.scanBluetooth(); }
    }

    Connections {
        target: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : null
        function onValuesChanged() { root.scanBluetooth(); }
    }

    Connections {
        target: root.nothingBtDevice
        function onConnectedChanged() {
            if (root.nothingBtDevice && root.nothingBtDevice.connected) {
                root.fetchStatus(true);
            } else {
                var d = JSON.parse(JSON.stringify(root.headphonesData));
                d.connected = false;
                root.headphonesData = d;
                root.isExpanded = false;
            }
        }
    }

    readonly property bool isEarConnected: (nothingBtDevice && nothingBtDevice.connected)
        || Boolean(headphonesData && headphonesData.connected)

    visible: isEarConnected && opacity > 0.01
    opacity: isEarConnected ? (targetCapsule ? targetCapsule.opacity : 1.0) : 0.0
    scale: isEarConnected ? 1.0 : 0.82

    clip: true
    color: "#000000"
    border.width: isExpanded ? 1 : 1
    border.color: isExpanded ? "#202022" : (compactHoverArea.containsMouse ? "#2e2e32" : "#141416")

    // Animazioni fluide iOS Dynamic Island
    Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
    Behavior on radius { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    onIsEarConnectedChanged: {
        if (!isEarConnected) isExpanded = false;
    }

    // Processi per comunicazione con script Python
    Process {
        id: statusProc
        command: [root.homeDir + "/.scripts/nothing-ear-ctl.py", "cached"]
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                root.headphonesBuffer += data;
                try {
                    var j = JSON.parse(root.headphonesBuffer.trim());
                    if (j && j.name !== undefined) {
                        root.headphonesData = j;
                        root.headphonesBuffer = "";
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: actionProc
        running: false
    }

    function fetchStatus(forceRefresh) {
        if (statusProc.running) return;
        root.headphonesBuffer = "";
        statusProc.command = [root.homeDir + "/.scripts/nothing-ear-ctl.py", forceRefresh ? "status" : "cached"];
        statusProc.running = true;
    }

    function runCtl(args) {
        actionProc.command = [root.homeDir + "/.scripts/nothing-ear-ctl.py"].concat(args);
        actionProc.running = false;
        actionProc.running = true;
    }

    function setAnc(mode) {
        var d = JSON.parse(JSON.stringify(root.headphonesData));
        d.anc = mode;
        d.anc_simplified = (mode === "transparency" ? "transparency" : (mode === "off" ? "off" : "anc"));
        root.headphonesData = d;
        runCtl(["anc", mode]);
    }

    function setBass(enabled, level) {
        var d = JSON.parse(JSON.stringify(root.headphonesData));
        if (!d.bass) d.bass = { enabled: false, level: 4 };
        d.bass.enabled = enabled;
        if (level !== undefined && level !== null) d.bass.level = level;
        root.headphonesData = d;
        var lvl = (d.bass && d.bass.level) ? d.bass.level : 4;
        runCtl(["bass", enabled ? "on" : "off", String(lvl)]);
    }

    function setLatency(enabled) {
        var d = JSON.parse(JSON.stringify(root.headphonesData));
        d.latency = enabled;
        root.headphonesData = d;
        runCtl(["latency", enabled ? "on" : "off"]);
    }

    function disconnectDevice() {
        var d = JSON.parse(JSON.stringify(root.headphonesData));
        d.connected = false;
        root.headphonesData = d;
        root.isExpanded = false;
        runCtl(["disconnect"]);
    }

    Timer {
        id: pollTimer
        interval: root.isExpanded ? 3000 : 15000
        running: root.isEarConnected
        repeat: true
        onTriggered: root.fetchStatus(root.isExpanded)
    }

    Timer {
        id: btScanTimer
        interval: 3000
        running: !root.nothingBtDevice
        repeat: true
        onTriggered: root.scanBluetooth()
    }

    Component.onCompleted: {
        scanBluetooth();
        fetchStatus(false);
    }

    // ==========================================
    // 1. STATO COMPATTO (Mini Circle a destra)
    // ==========================================
    Item {
        id: compactContainer
        anchors.fill: parent
        visible: !root.isExpanded
        opacity: root.isExpanded ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        Item {
            anchors.centerIn: parent
            width: Math.round(root.compactHeight * 0.65)
            height: width

            Image {
                id: pillIcon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -2
                source: Qt.resolvedUrl("assets/earbuds_pill_icon.png")
                width: 21
                height: 21
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }

            // Puntino accentato indicatore di connessione
            Rectangle {
                width: 4
                height: 4
                radius: 2
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: -1
                color: root.accentColor
            }
        }

        MouseArea {
            id: compactHoverArea
            anchors.fill: parent
            enabled: !root.isExpanded
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.isExpanded = true;
                root.fetchStatus(true);
            }
            onEntered: {
                if (rootWindow && rootWindow.autoHideEnabled) {
                    rootWindow.autoHidePointerInside = true;
                    rootWindow.showAutoHiddenIsland("edge");
                }
            }
            onExited: {
                if (rootWindow && rootWindow.autoHideEnabled) {
                    rootWindow.autoHidePointerInside = false;
                    rootWindow.scheduleAutoHide();
                }
            }
        }
    }

    // ==========================================
    // 2. STATO ESPANSO (Scheda Nativa Dynamic Island)
    // ==========================================
    Item {
        id: expandedContainer
        anchors.fill: parent
        visible: root.isExpanded || opacity > 0.01
        opacity: root.isExpanded ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // --- HEADER ---
            Item {
                width: parent.width
                height: 46

                // Hero Image Nothing Ear
                Image {
                    id: heroImg
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44
                    source: Qt.resolvedUrl("assets/Nothing_ear.png")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                // Titolo e Info Connessione
                Column {
                    anchors.left: heroImg.right
                    anchors.leftMargin: 10
                    anchors.right: headerActions.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.headphonesData.name || "Nothing Ear (a)"
                        font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Row {
                        spacing: 5
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.isEarConnected ? "#10b981" : "#ef4444"

                            SequentialAnimation on opacity {
                                running: root.isEarConnected
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.4; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.0; to: 0.4; duration: 900; easing.type: Easing.InOutSine }
                            }
                        }

                        Text {
                            text: root.isEarConnected ? ("Connesso · " + (root.headphonesData.codec || "LDAC")) : "Disconnesso"
                            font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                            font.pixelSize: 11
                            color: "#8e8e93"
                        }
                    }
                }

                // Pulsanti Azione in alto a destra
                Row {
                    id: headerActions
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // Pulsante Refresh
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: refArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: "#ffffff"
                            rotation: statusProc.running ? 360 : 0
                            Behavior on rotation { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: refArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.fetchStatus(true)
                        }
                    }

                    // Pulsante Disconnetti
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: dcArea.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.22) : Qt.rgba(1, 1, 1, 0.06)
                        border.color: dcArea.containsMouse ? "#ef4444" : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰌺"
                            font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: dcArea.containsMouse ? "#ef4444" : "#ffffff"
                        }

                        MouseArea {
                            id: dcArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.disconnectDevice()
                        }
                    }

                    // Pulsante Chiudi
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06)
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isExpanded = false
                        }
                    }
                }
            }

            // --- BATTERIE (3 Pillole orizzontali) ---
            Row {
                width: parent.width
                height: 56
                spacing: 8

                // Sinistro
                Rectangle {
                    width: (parent.width - 16) / 3
                    height: parent.height
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Row {
                            width: parent.width
                            spacing: 4
                            Text {
                                text: "󰋋"
                                font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: "#8e8e93"
                            }
                            Text {
                                text: "Sinistro"
                                font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#8e8e93"
                            }
                            Item { Layout.fillWidth: true; width: 2 }
                            Text {
                                visible: Boolean(root.headphonesData.battery && root.headphonesData.battery.left && root.headphonesData.battery.left.charging)
                                text: "⚡"
                                font.pixelSize: 10
                                color: "#f59e0b"
                            }
                        }

                        Text {
                            text: (root.headphonesData.battery && root.headphonesData.battery.left && root.headphonesData.battery.left.available)
                                ? (root.headphonesData.battery.left.level + "%") : "--"
                            font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }

                        Rectangle {
                            width: parent.width
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                property int lvl: (root.headphonesData.battery && root.headphonesData.battery.left) ? root.headphonesData.battery.left.level : 0
                                width: parent.width * (Math.max(0, Math.min(100, lvl)) / 100)
                                height: parent.height
                                radius: 1.5
                                color: lvl > 20 ? root.accentColor : "#ef4444"
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }

                // Destro
                Rectangle {
                    width: (parent.width - 16) / 3
                    height: parent.height
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Row {
                            width: parent.width
                            spacing: 4
                            Text {
                                text: "󰋋"
                                font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: "#8e8e93"
                            }
                            Text {
                                text: "Destro"
                                font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#8e8e93"
                            }
                            Item { Layout.fillWidth: true; width: 2 }
                            Text {
                                visible: Boolean(root.headphonesData.battery && root.headphonesData.battery.right && root.headphonesData.battery.right.charging)
                                text: "⚡"
                                font.pixelSize: 10
                                color: "#f59e0b"
                            }
                        }

                        Text {
                            text: (root.headphonesData.battery && root.headphonesData.battery.right && root.headphonesData.battery.right.available)
                                ? (root.headphonesData.battery.right.level + "%") : "--"
                            font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }

                        Rectangle {
                            width: parent.width
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                property int lvl: (root.headphonesData.battery && root.headphonesData.battery.right) ? root.headphonesData.battery.right.level : 0
                                width: parent.width * (Math.max(0, Math.min(100, lvl)) / 100)
                                height: parent.height
                                radius: 1.5
                                color: lvl > 20 ? root.accentColor : "#ef4444"
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }

                // Case
                Rectangle {
                    width: (parent.width - 16) / 3
                    height: parent.height
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Row {
                            width: parent.width
                            spacing: 4
                            Text {
                                text: "󰋍"
                                font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: "#8e8e93"
                            }
                            Text {
                                text: "Case"
                                font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#8e8e93"
                            }
                            Item { Layout.fillWidth: true; width: 2 }
                            Text {
                                visible: Boolean(root.headphonesData.battery && root.headphonesData.battery.case && root.headphonesData.battery.case.charging)
                                text: "⚡"
                                font.pixelSize: 10
                                color: "#f59e0b"
                            }
                        }

                        Text {
                            text: (root.headphonesData.battery && root.headphonesData.battery.case && root.headphonesData.battery.case.available)
                                ? (root.headphonesData.battery.case.level + "%") : "--"
                            font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            color: "#ffffff"
                        }

                        Rectangle {
                            width: parent.width
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                property int lvl: (root.headphonesData.battery && root.headphonesData.battery.case) ? root.headphonesData.battery.case.level : 0
                                width: parent.width * (Math.max(0, Math.min(100, lvl)) / 100)
                                height: parent.height
                                radius: 1.5
                                color: lvl > 20 ? root.accentColor : "#ef4444"
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }

            // --- CONTROLLO RUMORE (Segmented iOS Pill) ---
            Column {
                width: parent.width
                spacing: 6

                Text {
                    text: "CONTROLLO RUMORE"
                    font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                    color: "#8e8e93"
                }

                Rectangle {
                    id: ancBox
                    width: parent.width
                    height: 36
                    radius: 18
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1

                    readonly property string activeMode: {
                        var m = root.headphonesData.anc || "off";
                        if (m === "transparency") return "transparency";
                        if (m === "off") return "off";
                        return "anc";
                    }

                    readonly property int activeIndex: {
                        if (activeMode === "anc") return 0;
                        if (activeMode === "off") return 1;
                        return 2;
                    }

                    readonly property real segmentWidth: (width - 6) / 3

                    // Pillola scorrevole fluida stile iOS
                    Rectangle {
                        id: slidingPill
                        y: 3
                        height: 30
                        width: ancBox.segmentWidth
                        radius: 15
                        color: root.accentColor
                        x: 3 + ancBox.activeIndex * ancBox.segmentWidth

                        Behavior on x {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutQuint
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 0
                        z: 2

                        // ANC
                        Item {
                            width: ancBox.segmentWidth
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                radius: 15
                                color: (ancBox.activeIndex !== 0 && ancMouse.containsMouse) ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5
                                scale: ancMouse.pressed ? 0.94 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Text {
                                    text: "󰂵"
                                    font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: ancBox.activeIndex === 0 ? "#ffffff" : "#8e8e93"
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                Text {
                                    text: "ANC"
                                    font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: ancBox.activeIndex === 0 ? "#ffffff" : "#8e8e93"
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                id: ancMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var curr = root.headphonesData.anc;
                                    if (curr === "high" || curr === "mid" || curr === "low" || curr === "adaptive") {
                                        root.setAnc(curr);
                                    } else {
                                        root.setAnc("high");
                                    }
                                }
                            }
                        }

                        // Off
                        Item {
                            width: ancBox.segmentWidth
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                radius: 15
                                color: (ancBox.activeIndex !== 1 && offMouse.containsMouse) ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5
                                scale: offMouse.pressed ? 0.94 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Text {
                                    text: "󰂲"
                                    font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: ancBox.activeIndex === 1 ? "#ffffff" : "#8e8e93"
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                Text {
                                    text: "Off"
                                    font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: ancBox.activeIndex === 1 ? "#ffffff" : "#8e8e93"
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                id: offMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setAnc("off")
                            }
                        }

                        // Trasparenza
                        Item {
                            width: ancBox.segmentWidth
                            height: parent.height

                            Rectangle {
                                anchors.fill: parent
                                radius: 15
                                color: (ancBox.activeIndex !== 2 && transMouse.containsMouse) ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 5
                                scale: transMouse.pressed ? 0.94 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Text {
                                    text: "󰂴"
                                    font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    color: ancBox.activeIndex === 2 ? "#ffffff" : "#8e8e93"
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                                Text {
                                    text: "Trasparenza"
                                    font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: ancBox.activeIndex === 2 ? "#ffffff" : "#8e8e93"
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            MouseArea {
                                id: transMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setAnc("transparency")
                            }
                        }
                    }
                }

                // Sotto-modalità ANC (Alta, Media, Bassa, Adattiva) con indicatore scorrevole
                Rectangle {
                    id: subAncBox
                    width: parent.width
                    visible: (root.headphonesData.anc !== "off" && root.headphonesData.anc !== "transparency")
                    height: visible ? 26 : 0
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.04)
                    border.color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    clip: true

                    readonly property int subIndex: {
                        var a = root.headphonesData.anc;
                        if (a === "high") return 0;
                        if (a === "mid") return 1;
                        if (a === "low") return 2;
                        if (a === "adaptive") return 3;
                        return 0;
                    }
                    readonly property real subWidth: (width - 4) / 4

                    Rectangle {
                        id: subSlidingPill
                        y: 2
                        height: parent.height - 4
                        width: subAncBox.subWidth
                        radius: 6
                        color: root.accentColor
                        x: 2 + subAncBox.subIndex * subAncBox.subWidth

                        Behavior on x {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutQuint
                            }
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0
                        z: 2

                        Repeater {
                            model: [
                                { id: "high", name: "Alta" },
                                { id: "mid", name: "Media" },
                                { id: "low", name: "Bassa" },
                                { id: "adaptive", name: "Adattiva" }
                            ]

                            Item {
                                width: subAncBox.subWidth
                                height: parent.height

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name
                                    font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    color: subAncBox.subIndex === index ? "#ffffff" : "#8e8e93"
                                    scale: subMouse.pressed ? 0.94 : 1.0
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 100 } }
                                }

                                MouseArea {
                                    id: subMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setAnc(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // --- AUDIO & PRESTAZIONI (Bass Boost & Low Latency) ---
            Column {
                width: parent.width
                spacing: 6

                Text {
                    text: "AUDIO & PRESTAZIONI"
                    font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                    color: "#8e8e93"
                }

                Row {
                    width: parent.width
                    spacing: 8

                    // Bass Boost Card
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: (root.headphonesData.bass && root.headphonesData.bass.enabled) ? 72 : 40
                        radius: 12
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        clip: true
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 22

                                Row {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    Text {
                                        text: "󰎆"
                                        font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: (root.headphonesData.bass && root.headphonesData.bass.enabled) ? root.accentColor : "#8e8e93"
                                    }
                                    Text {
                                        text: "Bass Boost"
                                        font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        color: "#ffffff"
                                    }
                                }

                                // Switch toggle
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 34
                                    height: 18
                                    radius: 9
                                    color: (root.headphonesData.bass && root.headphonesData.bass.enabled) ? root.accentColor : Qt.rgba(1, 1, 1, 0.12)
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: (root.headphonesData.bass && root.headphonesData.bass.enabled) ? 18 : 2
                                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var enabled = !(root.headphonesData.bass && root.headphonesData.bass.enabled);
                                            var lvl = (root.headphonesData.bass && root.headphonesData.bass.level) ? root.headphonesData.bass.level : 4;
                                            root.setBass(enabled, lvl);
                                        }
                                    }
                                }
                            }

                            // Slider Livello Bassi (1 a 5)
                            Row {
                                width: parent.width
                                height: 20
                                spacing: 6
                                visible: Boolean(root.headphonesData.bass && root.headphonesData.bass.enabled)

                                Repeater {
                                    model: 5
                                    Rectangle {
                                        width: (parent.width - 24) / 5
                                        height: 18
                                        radius: 5
                                        property int lvl: index + 1
                                        property bool isCurrent: (root.headphonesData.bass && root.headphonesData.bass.level) === lvl
                                        color: isCurrent ? root.accentColor : (bMouse.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.06))

                                        Text {
                                            anchors.centerIn: parent
                                            text: String(index + 1)
                                            font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                            font.pixelSize: 9
                                            font.weight: Font.Bold
                                            color: isCurrent ? "#ffffff" : "#8e8e93"
                                        }

                                        MouseArea {
                                            id: bMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.setBass(true, index + 1)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Low Latency Card
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 40
                        radius: 12
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.color: Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1

                        Item {
                            anchors.fill: parent
                            anchors.margins: 9

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6
                                Text {
                                    text: "󰌌"
                                    font.family: userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    color: root.headphonesData.latency ? root.accentColor : "#8e8e93"
                                }
                                Text {
                                    text: "Bassa Latenza"
                                    font.family: userConfig ? userConfig.textFontFamily : "Sans Serif"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: "#ffffff"
                                }
                            }

                            // Switch toggle
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                height: 18
                                radius: 9
                                color: root.headphonesData.latency ? root.accentColor : Qt.rgba(1, 1, 1, 0.12)
                                Behavior on color { ColorAnimation { duration: 180 } }

                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: "#ffffff"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: root.headphonesData.latency ? 18 : 2
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setLatency(!root.headphonesData.latency)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Auto-collasso quando il cursore esce dall'isola
    HoverHandler {
        id: islandHoverHandler
        onHoveredChanged: {
            if (!hovered) {
                if (root.isExpanded) autoCollapseTimer.restart();
                if (rootWindow && rootWindow.autoHideEnabled) {
                    rootWindow.autoHidePointerInside = false;
                    rootWindow.scheduleAutoHide();
                }
            } else {
                autoCollapseTimer.stop();
                if (rootWindow && rootWindow.autoHideEnabled) {
                    rootWindow.autoHidePointerInside = true;
                    rootWindow.showAutoHiddenIsland("edge");
                }
            }
        }
    }

    Timer {
        id: autoCollapseTimer
        interval: 400
        repeat: false
        onTriggered: {
            if (root.isExpanded && !islandHoverHandler.hovered) {
                root.isExpanded = false;
            }
        }
    }

    onIsExpandedChanged: {
        autoCollapseTimer.stop();
    }
}
