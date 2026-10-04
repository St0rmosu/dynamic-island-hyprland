import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import IslandBackend
import "../settings"

FocusScope {
    id: root

    signal closeRequested()

    implicitWidth: 980
    implicitHeight: 680
    width: 980
    height: 680

    property var dynamicConfig: null

    property bool showCondition: true
    focus: showCondition
    activeFocusOnTab: true

    Keys.onEscapePressed: function(event) {
        event.accepted = true;
        if (fontBrowserVisible) {
            fontBrowserVisible = false;
            return;
        }
        root.closeRequested();
    }

    // Theme & Styling
    property color accentColor: "#0a84ff"
    property color bgDark: "#0c0e14"
    property color bgSidebar: "#080a0f"
    property color borderSubtle: Qt.rgba(255, 255, 255, 0.08)
    property real cornerRadius: 20
    property bool isEmbeddedInWindow: false

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    // Watch dynamic pywal/iris colors
    FileView {
        id: localWalColors
        path: root.homeDir + "/.cache/wal/colors.json"
        watchChanges: true
        property string walAccent: (typeof UserConfig !== "undefined" && UserConfig && UserConfig.walAccent !== "") ? UserConfig.walAccent : ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.colors) {
                    walAccent = d.colors.color4 || d.colors.color2 || "#0a84ff";
                }
            } catch(e) {}
        }
    }

    FileView {
        id: localIrisColors
        path: root.homeDir + "/.cache/iris/colors.json"
        watchChanges: true
        property string irisAccent: (typeof UserConfig !== "undefined" && UserConfig && UserConfig.irisAccent !== "") ? UserConfig.irisAccent : ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.accent) {
                    irisAccent = d.accent;
                }
            } catch(e) {}
        }
    }

    FileView {
        id: systemFontsCacheView
        path: root.homeDir + "/.cache/dynamic-island/fonts_cache.json"
        watchChanges: true
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && Array.isArray(d.all) && d.all.length > 0) {
                    root.systemFontsList = d.all;
                    if (Array.isArray(d.icons))
                        root.systemIconFontsList = d.icons;
                    root.systemFontsLoaded = true;
                    root.updateFilteredFonts();
                }
            } catch(e) {}
        }
    }

    Process {
        id: fontScannerProc
        command: [
            "python3", "-c",
            "import os, subprocess; " +
            "home = os.path.expanduser('~'); " +
            "candidates = [" +
            "os.path.join(home, '.config/quickshell/dynamic-island/scripts/scan_system_fonts.py'), " +
            "os.path.join(os.getcwd(), 'scripts/scan_system_fonts.py')]; " +
            "s = next((c for c in candidates if os.path.isfile(c)), None); " +
            "subprocess.run(['python3', s]) if s else None"
        ]
        running: false
        onExited: {
            systemFontsCacheView.reload();
        }
    }

    readonly property color effectiveAccent: {
        if (dynamicConfig && dynamicConfig.customAccentColor !== "" && !dynamicConfig.pywalEnabled)
            return dynamicConfig.customAccentColor;
        if (localIrisColors.irisAccent !== "")
            return localIrisColors.irisAccent;
        if (localWalColors.walAccent !== "")
            return localWalColors.walAccent;
        return accentColor;
    }

    property string textFontFamily: (dynamicConfig && dynamicConfig.textFontFamily !== "") ? dynamicConfig.textFontFamily : "Google Sans Flex"
    property string heroFontFamily: (dynamicConfig && dynamicConfig.heroFontFamily !== "") ? dynamicConfig.heroFontFamily : "Google Sans Flex"
    property string iconFontFamily: (dynamicConfig && dynamicConfig.iconFontFamily !== "") ? dynamicConfig.iconFontFamily : "JetBrainsMono Nerd Font"

    property int selectedCategoryIndex: 0

    readonly property var navigationPages: {
        const _ = I18n.currentLanguage;
        return [
            {
                title: I18n.tr("Isola & Geometria"),
                icon: "\uf108"
            },
            {
                title: I18n.tr("Control Center & Studio"),
                icon: "\uf462"
            },
            {
                title: I18n.tr("Aspetto, Sfondi & Font"),
                icon: "\uf1fc"
            },
            {
                title: I18n.tr("Scorciatoie da Tastiera"),
                icon: "\uf11c"
            }
        ];
    }

    // ── Layout Principale a Due Colonne ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.isEmbeddedInWindow ? 0 : root.cornerRadius
        bottomLeftRadius: root.cornerRadius
        bottomRightRadius: root.cornerRadius
        topLeftRadius: root.isEmbeddedInWindow ? 0 : root.cornerRadius
        topRightRadius: root.isEmbeddedInWindow ? 0 : root.cornerRadius
        color: root.bgDark
        border.width: root.isEmbeddedInWindow ? 0 : 1
        border.color: root.borderSubtle
        clip: true

        Row {
            anchors.fill: parent

            // ── Colonna Sinistra: Sidebar ──────────────────────────────
            Rectangle {
                width: 230
                height: parent.height
                color: root.bgSidebar
                topLeftRadius: root.isEmbeddedInWindow ? 0 : root.cornerRadius
                bottomLeftRadius: root.cornerRadius
                topRightRadius: 0
                bottomRightRadius: 0
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.05)

                Column {
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8

                    Repeater {
                        model: root.navigationPages

                        Rectangle {
                            readonly property bool isSelected: root.selectedCategoryIndex === index
                            width: parent.width
                            height: 44
                            radius: 12
                            color: isSelected
                                ? Qt.rgba(root.effectiveAccent.r, root.effectiveAccent.g, root.effectiveAccent.b, 0.22)
                                : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                            border.width: isSelected ? 1 : 0
                            border.color: root.effectiveAccent

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 15
                                    color: isSelected ? root.effectiveAccent : "#8c94a6"
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.title
                                    color: isSelected ? "#ffffff" : "#c2c7d4"
                                    font.pixelSize: 13
                                    font.weight: isSelected ? Font.DemiBold : Font.Normal
                                    font.family: root.textFontFamily
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedCategoryIndex = index
                            }
                        }
                    }
                }

                // Pulsante Aggiorna Shell in basso nella Sidebar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    height: 38
                    radius: 10
                    color: updateHover.containsMouse ? Qt.rgba(root.effectiveAccent.r, root.effectiveAccent.g, root.effectiveAccent.b, 0.20) : Qt.rgba(255, 255, 255, 0.04)
                    border.width: 1
                    border.color: updateHover.containsMouse ? root.effectiveAccent : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf021" // sync icon
                            font.family: root.iconFontFamily
                            font.pixelSize: 13
                            color: root.effectiveAccent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("Aggiorna Shell")
                            font.family: root.textFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: updateHover.containsMouse ? "#ffffff" : "#c2c7d4"
                        }
                    }

                    MouseArea {
                        id: updateHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["foot", "-e", "bash", "-c", "dynamic-island update; echo ''; read -n 1 -s -r -p 'Premi un tasto per uscire...'; exit"]);
                        }
                    }
                }
            }

            // ── Colonna Destra: Contenuto Pagina ───────────────────────
            Rectangle {
                width: parent.width - 230
                height: parent.height
                color: "transparent"

                Column {
                    anchors.fill: parent

                    // Header Pagina con Titolo e Tasto Chiusura [ ✕ ]
                    Rectangle {
                        width: parent.width
                        height: 60
                        color: "transparent"
                        border.width: 0

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Text {
                                text: root.navigationPages[root.selectedCategoryIndex].title
                                color: "#f2f4f8"
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                font.family: root.textFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Controlli Header (Selettore Rapido Lingua + Chiudi)
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            // Pillola Rapida Selezione Lingua (Auto | EN | IT)
                            Rectangle {
                                height: 30
                                radius: 8
                                color: Qt.rgba(255, 255, 255, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.08)
                                width: langPillRow.implicitWidth + 6
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    id: langPillRow
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Repeater {
                                        model: [
                                            { label: "Auto", value: "auto" },
                                            { label: "EN", value: "en" },
                                            { label: "IT", value: "it" }
                                        ]

                                        Rectangle {
                                            readonly property bool isSelected: {
                                                var cur = (root.dynamicConfig && root.dynamicConfig.language) ? root.dynamicConfig.language : "auto";
                                                return cur === modelData.value;
                                            }
                                            width: lText.contentWidth + 14
                                            height: 22
                                            radius: 6
                                            color: isSelected ? root.effectiveAccent : (lMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")
                                            border.width: isSelected ? 1 : 0
                                            border.color: isSelected ? Qt.rgba(255, 255, 255, 0.25) : "transparent"

                                            Behavior on color { ColorAnimation { duration: 120 } }

                                            Text {
                                                id: lText
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.pixelSize: 11
                                                font.weight: isSelected ? Font.Bold : Font.Normal
                                                font.family: root.textFontFamily
                                                color: isSelected ? "#ffffff" : "#a2a8b8"
                                            }

                                            MouseArea {
                                                id: lMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: {
                                                    if (root.dynamicConfig) {
                                                        root.dynamicConfig.set("language", modelData.value);
                                                    }
                                                    if (typeof I18n !== "undefined" && I18n) {
                                                        I18n.language = modelData.value;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Pulsante Chiudi [ ✕ ] (visibile solo se non integrato nella finestra nativa con barra del titolo)
                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: closeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                                visible: !root.isEmbeddedInWindow

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: "#d8dce6"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.closeRequested()
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Qt.rgba(255, 255, 255, 0.05)
                        }
                    }

                    // Stack View delle 5 Pagine
                    StackLayout {
                        id: pagesStack
                        width: parent.width
                        height: parent.height - 60
                        currentIndex: root.selectedCategoryIndex

                        // Pagina 1: Isola & Geometria
                        IslandGeometryPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            iconFontFamily: root.iconFontFamily
                        }

                        // Pagina 2: Control Center & Studio Canvas (Visual 2D Editor!)
                        ControlCenterStudioPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            heroFontFamily: root.heroFontFamily
                            iconFontFamily: root.iconFontFamily
                        }

                        // Pagina 4: Aspetto, Sfondi & Font
                        AppearanceFontPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            heroFontFamily: root.heroFontFamily
                            iconFontFamily: root.iconFontFamily
                            onOpenFontBrowser: function(target) { root.openFontBrowser(target); }
                        }

                        // Pagina 4: Scorciatoie Hyprland
                        ShortcutsPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            iconFontFamily: root.iconFontFamily
                        }
                    }
                }
            }
        }
    }

    // ── Modal Font Browser (Sfoglia font di sistema e font per icone) ──
    property bool fontBrowserVisible: false
    property string fontBrowserTarget: "text"
    property string fontBrowserQuery: ""
    property var systemFontsList: []
    property var systemIconFontsList: []
    property bool systemFontsLoaded: false
    property var filteredFonts: []

    function isIconFont(name) {
        if (!name) return false;
        const low = name.toLowerCase();
        const p = ["nerd font", "nerdfont", "fontawesome", "font awesome", "font-awesome",
                   "material symbol", "material icon", "material design", "symbols nerd font",
                   "feather", "phosphor", "remix", "tabler", "devicon", "octicon",
                   "weather icon", "ionicons", "symbols"];
        return p.some(function(pat) { return low.indexOf(pat) !== -1; });
    }

    function loadSystemFonts() {
        if (systemFontsList.length === 0) {
            try {
                let list = Qt.fontFamilies();
                if (Array.isArray(list)) {
                    list.sort(function(a, b) { return a.toLowerCase().localeCompare(b.toLowerCase()); });
                    systemFontsList = list;
                    systemIconFontsList = list.filter(function(name) { return root.isIconFont(name); });
                }
            } catch(e) {}
            fontScannerProc.running = true;
        }
    }

    function updateFilteredFonts() {
        let q = fontBrowserQuery.toLowerCase().trim();
        let list = (fontBrowserTarget === "icon") ? systemIconFontsList : systemFontsList;
        let res = [];
        for (let i = 0; i < list.length; i++) {
            let font = list[i];
            if (q !== "" && font.toLowerCase().indexOf(q) === -1) continue;
            res.push(font);
            if (res.length >= 400) break;
        }
        filteredFonts = res;
    }

    function openFontBrowser(target) {
        fontBrowserTarget = (target === "icon") ? "icon" : "text";
        fontBrowserQuery = "";
        loadSystemFonts();
        updateFilteredFonts();
        fontBrowserVisible = true;
    }

    Rectangle {
        id: fontBrowserModal
        visible: root.fontBrowserVisible
        anchors.fill: parent
        radius: 32
        color: Qt.rgba(10/255, 12/255, 17/255, 0.96)
        z: 999

        MouseArea { anchors.fill: parent } // block clicks through

        Column {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 16

            Item {
                width: parent.width
                height: 32

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.fontBrowserTarget === "icon")
                        ? (I18n.tr("Sfoglia Font per Icone & Glifi") + " (" + root.filteredFonts.length + " " + I18n.tr("disponibili") + ")")
                        : (I18n.tr("Sfoglia Font di Sistema") + " (" + root.systemFontsList.length + " " + I18n.tr("installati") + ")")
                    color: "#f2f4f8"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    font.family: root.textFontFamily
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    radius: 16
                    color: Qt.rgba(255, 255, 255, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#ffffff"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: fontCloseMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.fontBrowserVisible = false
                    }
                }
            }

            // Barra di Ricerca Font
            Rectangle {
                width: parent.width
                height: 42
                radius: 10
                color: Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.10)

                Text {
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: fontInput.text === ""
                    text: (root.fontBrowserTarget === "icon")
                        ? I18n.tr("Cerca font per icone (es. Nerd Font, Material, Symbols)...")
                        : I18n.tr("Cerca font di sistema (es. Google Sans, Inter, JetBrains)...")
                    color: Qt.rgba(255, 255, 255, 0.35)
                    font.pixelSize: 13
                    font.family: root.textFontFamily
                }

                TextInput {
                    id: fontInput
                    anchors.fill: parent
                    anchors.margins: 10
                    text: root.fontBrowserQuery
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.family: root.textFontFamily
                    clip: true
                    onTextChanged: {
                        root.fontBrowserQuery = text;
                        root.updateFilteredFonts();
                    }
                }
            }

            // Lista Font con Preview
            ListView {
                width: parent.width
                height: parent.height - 120
                clip: true
                model: root.filteredFonts

                delegate: Rectangle {
                    width: parent.width
                    height: 46
                    radius: 8
                    color: fontRowMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 16

                        Text {
                            text: modelData
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            font.family: root.textFontFamily
                            anchors.verticalCenter: parent.verticalCenter
                            width: 250
                            elide: Text.ElideRight
                        }

                        Text {
                            text: (root.fontBrowserTarget === "icon")
                                ? "                "
                                : "Pack my box with five dozen liquor jugs 1234567890"
                            color: "#8c94a6"
                            font.pixelSize: (root.fontBrowserTarget === "icon") ? 15 : 13
                            font.family: modelData
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - 280
                        }
                    }

                    MouseArea {
                        id: fontRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.fontBrowserTarget === "icon") {
                                root.iconFontFamily = modelData;
                                if (root.dynamicConfig) {
                                    root.dynamicConfig.set("iconFontFamily", modelData);
                                }
                            } else {
                                root.textFontFamily = modelData;
                                root.heroFontFamily = modelData;
                                if (root.dynamicConfig) {
                                    root.dynamicConfig.set("textFontFamily", modelData);
                                    root.dynamicConfig.set("heroFontFamily", modelData);
                                    root.dynamicConfig.set("timeFontFamily", modelData);
                                }
                            }
                            root.fontBrowserVisible = false;
                        }
                    }
                }
            }
        }
    }
}
