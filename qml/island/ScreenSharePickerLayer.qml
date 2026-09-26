pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import IslandBackend

FocusScope {
    id: root

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    // Iris colors
    FileView {
        id: irisColors
        path: root.homeDir + "/.cache/iris/colors.json"
        watchChanges: true
        property string accentHex: ""
        property string redHex: ""
        property string greenHex: ""
        property string yellowHex: ""
        property string purpleHex: ""
        property string blueHex: ""
        property string fgHex: ""
        property string bgHex: ""
        property string surfaceHex: ""
        property string dimHex: ""

        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text());
                if (d) {
                    accentHex = d.accent || "";
                    redHex = d.red || d.syntax_param || "";
                    greenHex = d.green || d.syntax_const || "";
                    yellowHex = d.yellow || d.syntax_operator || "";
                    purpleHex = d.syntax_type || d.syntax_keyword || "";
                    blueHex = d.syntax_func || d.accent || "";
                    fgHex = d.fg || "";
                    bgHex = d.bg || "";
                    surfaceHex = d.surface || "";
                    dimHex = d.dim || "";
                }
            } catch(e) {}
        }
    }

    property color accentColor: irisColors.accentHex !== "" ? irisColors.accentHex : "#86a0b3"
    readonly property color screenColor: irisColors.blueHex !== "" ? irisColors.blueHex : accentColor
    readonly property color windowColor: irisColors.purpleHex !== "" ? irisColors.purpleHex : "#d49ec5"
    readonly property color regionColor: irisColors.greenHex !== "" ? irisColors.greenHex : "#bbd69e"
    readonly property color textPrimary: irisColors.fgHex !== "" ? irisColors.fgHex : "#cdc6b2"
    readonly property color textSecondary: irisColors.dimHex !== "" ? irisColors.dimHex : "#80766a"
    readonly property color cardSurface: irisColors.surfaceHex !== "" ? irisColors.surfaceHex : "#675a4c"

    property string iconFontFamily: "Font Awesome 6 Free, JetBrainsMono Nerd Font, sans-serif"
    property string textFontFamily: "Inter, sans-serif"
    property string heroFontFamily: "SF Pro Text, Inter, sans-serif"
    property string monitorName: "eDP-1"
    property bool showCondition: false

    // Restore Token state (critical for XDPH screencopy)
    property bool allowToken: true

    signal selectionMade(string choice)
    signal closeRequested()

    property string currentMode: "main" // "main" or "windows"
    property var windowList: []

    // Enlarged dimensions for a spacious, comfortable look
    readonly property real preferredWidth: currentMode === "windows" ? 700 : 620
    readonly property real preferredHeight: currentMode === "windows" ? 480 : 220

    anchors.fill: parent
    focus: showCondition
    activeFocusOnTab: true
    opacity: showCondition ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
    }

    Keys.onEscapePressed: cancelSelection()

    function grabKeyboardFocus() {
        forceActiveFocus();
    }

    FileView {
        id: xdphWindowListFile
        path: "/tmp/island_xdph_windows.txt"
        watchChanges: true
        Component.onCompleted: reload()
        onFileChanged: reload()
    }

    function refreshWindows() {
        // First check if XDPH provided the transient window list
        xdphWindowListFile.reload();
        const raw = xdphWindowListFile.text();
        if (raw && raw.indexOf("[HA>]") >= 0) {
            const items = raw.split("[HA>]");
            const parsed = [];
            for (let i = 0; i < items.length; i++) {
                const item = items[i].trim();
                if (!item) continue;
                const hcIdx = item.indexOf("[HC>]");
                const htIdx = item.indexOf("[HT>]");
                const heIdx = item.indexOf("[HE>]");
                if (hcIdx >= 0 && htIdx >= 0 && heIdx >= 0) {
                    const handleLo = item.substring(0, hcIdx).trim();
                    const clazz = item.substring(hcIdx + 5, htIdx).trim();
                    const title = item.substring(htIdx + 5, heIdx).trim();
                    if (title !== "") {
                        parsed.push({
                            id: handleLo,
                            title: title,
                            clazz: clazz || "App",
                            initialClass: clazz
                        });
                    }
                }
            }
            if (parsed.length > 0) {
                root.windowList = parsed;
                return;
            }
        }

        // Fallback to querying hyprctl clients
        fetchWindowsProcess.running = true;
    }

    Process {
        id: fetchWindowsProcess
        command: ["hyprctl", "clients", "-j"]
        running: false

        stdout: StdioCollector {
            onDataChanged: {
                if (!data) return;
                try {
                    const parsed = JSON.parse(data);
                    const filtered = [];
                    for (let i = 0; i < parsed.length; i++) {
                        const win = parsed[i];
                        if (win.mapped && win.title && win.title !== "") {
                            // Convert hex address to unsigned 32-bit handleLo for XDPH
                            const addrNum = parseInt(win.address, 16) >>> 0;
                            filtered.push({
                                id: String(addrNum),
                                address: win.address,
                                title: win.title,
                                clazz: win.class || "App",
                                initialClass: win.initialClass || win.class || ""
                            });
                        }
                    }
                    root.windowList = filtered;
                } catch (e) {
                    console.log("[ScreenSharePicker] Error parsing clients:", e);
                }
            }
        }
    }

    Process {
        id: slurpProcess
        // Region format expected by XDPH: <output>@<x>,<y>,<w>,<h>
        command: ["slurp", "-f", "%o@%x,%y,%w,%h"]
        running: false

        stdout: StdioCollector {
            onDataChanged: {
                if (data && data.trim() !== "") {
                    root.finishSelection("region:" + data.trim());
                } else {
                    root.cancelSelection();
                }
            }
        }

        onExited: (code) => {
            if (code !== 0) {
                root.cancelSelection();
            }
        }
    }

    function finishSelection(choice) {
        // Prepend restore token prefix 'r/' if allowToken is active
        const finalChoice = (root.allowToken ? "r/" : "/") + choice;
        root.selectionMade(finalChoice);
        root.closeRequested();
    }

    function cancelSelection() {
        root.selectionMade("cancel");
        root.closeRequested();
    }

    onShowConditionChanged: {
        if (showCondition) {
            currentMode = "main";
            forceActiveFocus();
            refreshWindows();
        }
    }

    // --- MAIN VIEW ---
    Item {
        id: mainView
        anchors.fill: parent
        anchors.margins: 14
        visible: root.currentMode === "main"
        opacity: root.currentMode === "main" ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Icon Badge
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.20)
                    border.width: 1.5
                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.50)

                    Text {
                        anchors.centerIn: parent
                        text: "\u{F0379}"
                        color: root.accentColor
                        font.family: root.iconFontFamily
                        font.pixelSize: 15
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Condivisione Schermo"
                        color: root.textPrimary
                        font.family: root.heroFontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Seleziona la sorgente da condividere con l'applicazione"
                        color: root.textSecondary
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                    }
                }

                // Close / Dismiss button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: root.textSecondary
                        font.family: root.iconFontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancelSelection()
                    }
                }
            }

            // 3 Source Option Cards
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Card 1: Schermo Intero
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: fullScreenHover.containsMouse
                        ? Qt.rgba(root.screenColor.r, root.screenColor.g, root.screenColor.b, 0.18)
                        : Qt.rgba(root.cardSurface.r, root.cardSurface.g, root.cardSurface.b, 0.22)
                    border.width: fullScreenHover.containsMouse ? 1.5 : 1
                    border.color: fullScreenHover.containsMouse
                        ? root.screenColor
                        : Qt.rgba(1, 1, 1, 0.12)

                    scale: fullScreenHover.pressed ? 0.97 : (fullScreenHover.containsMouse ? 1.02 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44
                            height: 44
                            radius: 22
                            color: Qt.rgba(root.screenColor.r, root.screenColor.g, root.screenColor.b, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: "\u{F0379}"
                                color: root.screenColor
                                font.family: root.iconFontFamily
                                font.pixelSize: 22
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Schermo"
                            color: root.textPrimary
                            font.family: root.heroFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.monitorName
                            color: root.textSecondary
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: fullScreenHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.finishSelection("screen:" + root.monitorName)
                    }
                }

                // Card 2: Finestra
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: windowHover.containsMouse
                        ? Qt.rgba(root.windowColor.r, root.windowColor.g, root.windowColor.b, 0.18)
                        : Qt.rgba(root.cardSurface.r, root.cardSurface.g, root.cardSurface.b, 0.22)
                    border.width: windowHover.containsMouse ? 1.5 : 1
                    border.color: windowHover.containsMouse
                        ? root.windowColor
                        : Qt.rgba(1, 1, 1, 0.12)

                    scale: windowHover.pressed ? 0.97 : (windowHover.containsMouse ? 1.02 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44
                            height: 44
                            radius: 22
                            color: Qt.rgba(root.windowColor.r, root.windowColor.g, root.windowColor.b, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: "\uf2d0"
                                color: root.windowColor
                                font.family: root.iconFontFamily
                                font.pixelSize: 22
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Finestra"
                            color: root.textPrimary
                            font.family: root.heroFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.windowList.length > 0 ? (root.windowList.length + " aperte") : "Seleziona..."
                            color: root.textSecondary
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: windowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.refreshWindows();
                            root.currentMode = "windows";
                        }
                    }
                }

                // Card 3: Area / Regione
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: regionHover.containsMouse
                        ? Qt.rgba(root.regionColor.r, root.regionColor.g, root.regionColor.b, 0.18)
                        : Qt.rgba(root.cardSurface.r, root.cardSurface.g, root.cardSurface.b, 0.22)
                    border.width: regionHover.containsMouse ? 1.5 : 1
                    border.color: regionHover.containsMouse
                        ? root.regionColor
                        : Qt.rgba(1, 1, 1, 0.12)

                    scale: regionHover.pressed ? 0.97 : (regionHover.containsMouse ? 1.02 : 1.0)

                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44
                            height: 44
                            radius: 22
                            color: Qt.rgba(root.regionColor.r, root.regionColor.g, root.regionColor.b, 0.15)

                            Text {
                                anchors.centerIn: parent
                                text: "\uf125"
                                color: root.regionColor
                                font.family: root.iconFontFamily
                                font.pixelSize: 22
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Regione"
                            color: root.textPrimary
                            font.family: root.heroFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Trascina mirino"
                            color: root.textSecondary
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: regionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            slurpProcess.running = true;
                        }
                    }
                }
            }

            // Restore Token Toggle Pill Row
            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 10
                color: tokenMouse.containsMouse
                    ? Qt.rgba(1, 1, 1, 0.10)
                    : Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
                border.color: root.allowToken
                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)
                    : Qt.rgba(1, 1, 1, 0.10)

                Behavior on border.color { ColorAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    // Checkbox Indicator
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 5
                        color: root.allowToken ? root.accentColor : Qt.rgba(1, 1, 1, 0.10)
                        border.width: 1
                        border.color: root.allowToken ? root.accentColor : root.textSecondary

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            visible: root.allowToken
                            text: "\uf00c"
                            color: "#ffffff"
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        text: "Consenti token di ripristino"
                        color: root.textPrimary
                        font.family: root.heroFontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "— Ricorda l'autorizzazione per non doverla confermare ogni volta"
                        color: root.textSecondary
                        font.family: root.textFontFamily
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: tokenMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.allowToken = !root.allowToken
                }
            }
        }
    }

    // --- WINDOW SELECTION VIEW ---
    Item {
        id: windowsView
        anchors.fill: parent
        anchors.margins: 14
        visible: root.currentMode === "windows"
        opacity: root.currentMode === "windows" ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // Header with back button and token indicator
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: backHover.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.14)

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf060"
                        color: root.textPrimary
                        font.family: root.iconFontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: backHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.currentMode = "main"
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Seleziona Finestra"
                        color: root.textPrimary
                        font.family: root.heroFontFamily
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Fai clic sulla finestra che desideri condividere"
                        color: root.textSecondary
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                    }
                }

                // Token checkbox small in windows view
                Rectangle {
                    height: 28
                    radius: 8
                    width: tokenWinRow.implicitWidth + 16
                    color: tokenWinMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: root.allowToken ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.50) : Qt.rgba(1, 1, 1, 0.10)

                    Row {
                        id: tokenWinRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.allowToken ? root.accentColor : Qt.rgba(1, 1, 1, 0.10)
                            border.width: 1
                            border.color: root.allowToken ? root.accentColor : root.textSecondary

                            Text {
                                anchors.centerIn: parent
                                visible: root.allowToken
                                text: "\uf00c"
                                color: "#ffffff"
                                font.family: root.iconFontFamily
                                font.pixelSize: 9
                            }
                        }

                        Text {
                            text: "Ricorda token"
                            color: root.textPrimary
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: tokenWinMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.allowToken = !root.allowToken
                    }
                }

                // Close button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeAreaWin.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: root.textSecondary
                        font.family: root.iconFontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeAreaWin
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancelSelection()
                    }
                }
            }

            // Window list
            ListView {
                id: winListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.windowList
                spacing: 8

                delegate: Rectangle {
                    id: winItem
                    width: winListView.width
                    height: 52
                    radius: 12
                    color: winItemArea.containsMouse
                        ? Qt.rgba(root.windowColor.r, root.windowColor.g, root.windowColor.b, 0.18)
                        : Qt.rgba(root.cardSurface.r, root.cardSurface.g, root.cardSurface.b, 0.20)
                    border.width: winItemArea.containsMouse ? 1.5 : 1
                    border.color: winItemArea.containsMouse
                        ? root.windowColor
                        : Qt.rgba(1, 1, 1, 0.10)

                    scale: winItemArea.pressed ? 0.98 : 1.0

                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        // App badge
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: Qt.rgba(root.windowColor.r, root.windowColor.g, root.windowColor.b, 0.18)

                            Text {
                                anchors.centerIn: parent
                                text: "\uf2d0"
                                color: root.windowColor
                                font.family: root.iconFontFamily
                                font.pixelSize: 14
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData.title
                                color: root.textPrimary
                                font.family: root.textFontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: modelData.clazz
                                color: root.textSecondary
                                font.family: root.textFontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: winItemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.finishSelection("window:" + (modelData.id || modelData.address))
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.windowList.length === 0
                    text: "Nessuna finestra aperta rilevata"
                    color: root.textSecondary
                    font.family: root.textFontFamily
                    font.pixelSize: 12
                }
            }
        }
    }
}
