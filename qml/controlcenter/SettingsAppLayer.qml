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
    signal startMoveRequested()
    signal toggleMaximizeRequested()

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

    property string searchQuery: ""

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
        if (dynamicConfig && !dynamicConfig.pywalEnabled)
            return (dynamicConfig.customAccentColor !== "") ? dynamicConfig.customAccentColor : "#0a84ff";
        if (dynamicConfig && dynamicConfig.effectiveAccentColor)
            return dynamicConfig.effectiveAccentColor;
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
                subtitle: I18n.tr("Forma, dimensioni della capsula, notch e margini dello schermo"),
                icon: "\uf108",
                keywords: ["isola", "geometria", "notch", "larghezza", "altezza", "raggio", "margine", "curvatura", "bar", "island"]
            },
            {
                title: I18n.tr("Control Center & Studio"),
                subtitle: I18n.tr("Disponi, ridimensiona e configura i controlli del pannello rapido"),
                icon: "\uf462",
                keywords: ["control", "center", "studio", "widget", "audio", "volume", "luminosita", "bluetooth", "wifi", "rete", "media"]
            },
            {
                title: I18n.tr("Aspetto, Sfondi & Font"),
                subtitle: I18n.tr("Tipografia dell'orologio, colori dinamici Pywal/Iris e sfondi"),
                icon: "\uf1fc",
                keywords: ["aspetto", "sfondi", "font", "orologio", "tipografia", "pywal", "iris", "colori", "sfondo", "transizione", "wallpaper"]
            },
            {
                title: I18n.tr("Interazioni & Movimento"),
                subtitle: I18n.tr("Regolazione volume con la rotellina e comportamento media player"),
                icon: "\uf0e7",
                keywords: ["interazioni", "movimento", "rotellina", "wheel", "volume", "luminosita", "scroll", "media"]
            },
            {
                title: I18n.tr("Scorciatoie da Tastiera"),
                subtitle: I18n.tr("Combinazioni di tasti Hyprland e comandi rapidi per la shell"),
                icon: "\uf11c",
                keywords: ["scorciatoie", "tasti", "hyprland", "bind", "keybind", "super", "tastiera", "shortcuts"]
            },
            {
                title: I18n.tr("Schermata di Blocco"),
                subtitle: I18n.tr("Personalizza stile iPadOS, foto profilo, effetto profondità e widget"),
                icon: "\uf023",
                keywords: ["lock", "blocco", "schermata", "ipad", "profondita", "depth", "avatar", "profilo", "password", "spotify"]
            }
        ];
    }

    readonly property var filteredPages: {
        var q = root.searchQuery.toLowerCase().trim();
        var all = root.navigationPages;
        if (q === "") {
            var list = [];
            for (var i = 0; i < all.length; i++) {
                list.push({ pageIndex: i, item: all[i] });
            }
            return list;
        }
        var matches = [];
        for (var j = 0; j < all.length; j++) {
            var p = all[j];
            var matched = p.title.toLowerCase().indexOf(q) !== -1 ||
                          p.subtitle.toLowerCase().indexOf(q) !== -1;
            if (!matched && p.keywords) {
                for (var k = 0; k < p.keywords.length; k++) {
                    if (p.keywords[k].toLowerCase().indexOf(q) !== -1) {
                        matched = true;
                        break;
                    }
                }
            }
            if (matched) {
                matches.push({ pageIndex: j, item: p });
            }
        }
        return matches;
    }

    // ── Layout Principale a Due Colonne ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.bgDark
        border.width: root.isEmbeddedInWindow ? 0 : 1
        border.color: root.borderSubtle
        clip: true

        Row {
            anchors.fill: parent

            // ── Colonna Sinistra: Sidebar ──────────────────────────────
            Rectangle {
                id: sidebarRect
                width: 275
                height: parent.height
                color: root.bgSidebar
                radius: 0
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.05)

                Column {
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // ── Pillola di Ricerca Impostazioni (Stile Video 1:37) ──
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 10
                        color: searchTextInput.activeFocus ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: searchTextInput.activeFocus ? root.effectiveAccent : Qt.rgba(255, 255, 255, 0.08)

                        Behavior on border.color { ColorAnimation { duration: 140 } }
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\uf002" // search icon
                                font.family: root.iconFontFamily
                                font.pixelSize: 12
                                color: searchTextInput.activeFocus ? root.effectiveAccent : "#7e889b"
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            TextInput {
                                id: searchTextInput
                                width: parent.width - 44
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 12
                                font.family: root.textFontFamily
                                color: "#ffffff"
                                selectByMouse: true
                                clip: true

                                Text {
                                    anchors.fill: parent
                                    visible: parent.text === "" && !parent.activeFocus
                                    text: I18n.tr("Cerca impostazioni...")
                                    color: "#6e7787"
                                    font.pixelSize: 12
                                    font.family: root.textFontFamily
                                }

                                onTextChanged: {
                                    root.searchQuery = text;
                                    if (root.filteredPages.length > 0) {
                                        var found = false;
                                        for (var i = 0; i < root.filteredPages.length; i++) {
                                            if (root.filteredPages[i].pageIndex === root.selectedCategoryIndex) {
                                                found = true;
                                                break;
                                            }
                                        }
                                        if (!found) {
                                            root.selectedCategoryIndex = root.filteredPages[0].pageIndex;
                                        }
                                    }
                                }
                            }

                            // Tasto cancella ricerca
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: Qt.rgba(255, 255, 255, 0.12)
                                visible: root.searchQuery !== ""
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    font.pixelSize: 8
                                    color: "#d8dce6"
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchTextInput.text = "";
                                        root.searchQuery = "";
                                    }
                                }
                            }
                        }
                    }

                    // ── Lista Categorie ──
                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.filteredPages

                            Rectangle {
                                readonly property int pIndex: modelData.pageIndex
                                readonly property var pItem: modelData.item
                                readonly property bool isSelected: root.selectedCategoryIndex === pIndex

                                width: parent.width
                                height: 42
                                radius: 10
                                color: isSelected
                                    ? Qt.rgba(255, 255, 255, 0.09)
                                    : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.04) : "transparent")
                                border.width: isSelected ? 1 : 0
                                border.color: Qt.rgba(255, 255, 255, 0.08)
                                scale: itemMouse.pressed ? 0.98 : 1.0

                                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                // Indicatore sinistro verticale per la voce attiva
                                Rectangle {
                                    width: 3
                                    height: 18
                                    radius: 1.5
                                    color: root.effectiveAccent
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: isSelected
                                    opacity: isSelected ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 140 } }
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    // Icona sezione: usa sempre il colore d'accento dinamico quando attiva
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: pItem.icon
                                        font.family: root.iconFontFamily
                                        font.pixelSize: 14
                                        color: isSelected ? root.effectiveAccent : (itemMouse.containsMouse ? "#ffffff" : "#7e889b")
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 32
                                        text: pItem.title
                                        elide: Text.ElideRight
                                        color: isSelected ? "#ffffff" : (itemMouse.containsMouse ? "#e2e6f0" : "#9fa8b8")
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
                                    onClicked: root.selectedCategoryIndex = pIndex
                                }
                            }
                        }
                    }
                }

                // ── Pulsante Aggiorna Shell in fondo alla Sidebar ──
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    height: 38
                    radius: 10
                    color: updateHover.containsMouse ? Qt.rgba(root.effectiveAccent.r, root.effectiveAccent.g, root.effectiveAccent.b, 0.16) : Qt.rgba(255, 255, 255, 0.04)
                    border.width: 1
                    border.color: updateHover.containsMouse ? root.effectiveAccent : Qt.rgba(255, 255, 255, 0.08)
                    scale: updateHover.pressed ? 0.94 : (updateHover.containsMouse ? 1.02 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: updateHover.pressed ? 90 : 180
                            easing.type: updateHover.pressed ? Easing.OutQuad : Easing.OutBack
                            easing.overshoot: 1.15
                        }
                    }

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
                width: parent.width - 275
                height: parent.height
                color: "transparent"

                Column {
                    anchors.fill: parent

                    // ── Barra Superiore di Navigazione (< > e Chiudi) ──
                    Rectangle {
                        width: parent.width
                        height: 48
                        color: "transparent"

                        // Area per spostare la finestra nativamente trascinando
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onPressed: root.startMoveRequested()
                            onDoubleClicked: root.toggleMaximizeRequested()
                        }

                        // Frecce di navigazione Indietro / Avanti (come a 1:37 nel video)
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            // Tasto < (Indietro)
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 7
                                color: navBackMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.05)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.07)
                                opacity: root.selectedCategoryIndex > 0 ? 1.0 : 0.35
                                scale: navBackMouse.pressed ? 0.90 : 1.0

                                Behavior on scale { NumberAnimation { duration: 90 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "‹"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    id: navBackMouse
                                    anchors.fill: parent
                                    cursorShape: root.selectedCategoryIndex > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (root.selectedCategoryIndex > 0)
                                            root.selectedCategoryIndex--;
                                    }
                                }
                            }

                            // Tasto > (Avanti)
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 7
                                color: navForwardMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.05)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.07)
                                opacity: root.selectedCategoryIndex < (root.navigationPages.length - 1) ? 1.0 : 0.35
                                scale: navForwardMouse.pressed ? 0.90 : 1.0

                                Behavior on scale { NumberAnimation { duration: 90 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "›"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    id: navForwardMouse
                                    anchors.fill: parent
                                    cursorShape: root.selectedCategoryIndex < (root.navigationPages.length - 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        if (root.selectedCategoryIndex < (root.navigationPages.length - 1))
                                            root.selectedCategoryIndex++;
                                    }
                                }
                            }
                        }

                        // Controlli Header a destra (Lingua + Chiudi Finestra)
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            // Pillola Selezione Lingua (Auto | EN | IT)
                            Rectangle {
                                height: 28
                                radius: 7
                                color: Qt.rgba(255, 255, 255, 0.05)
                                border.width: 1
                                border.color: Qt.rgba(255, 255, 255, 0.07)
                                width: langPillRow.implicitWidth + 6
                                anchors.verticalCenter: parent.verticalCenter

                                Row {
                                    id: langPillRow
                                    anchors.centerIn: parent
                                    spacing: 2

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
                                            width: lText.contentWidth + 12
                                            height: 22
                                            radius: 5
                                            color: isSelected ? root.effectiveAccent : (lMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")
                                            scale: lMouse.pressed ? 0.92 : 1.0

                                            Behavior on scale { NumberAnimation { duration: 90 } }
                                            Behavior on color { ColorAnimation { duration: 120 } }

                                            Text {
                                                id: lText
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.pixelSize: 10
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

                            // Tasto Chiudi Finestra [ ✕ ]
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: closeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                                scale: closeMouse.pressed ? 0.88 : (closeMouse.containsMouse ? 1.06 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: "#d8dce6"
                                    font.pixelSize: 11
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
                    }

                    // ── HERO HEADER CENTRALE (Fedele al minuto 1:37 del video) ──
                    Rectangle {
                        id: heroHeaderBox
                        width: parent.width
                        height: 120
                        color: "transparent"

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            // Badge Circolare con Colore d'Accento Dinamico
                            Rectangle {
                                width: 52
                                height: 52
                                radius: 26
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Qt.rgba(root.effectiveAccent.r, root.effectiveAccent.g, root.effectiveAccent.b, 0.16)
                                border.width: 1
                                border.color: Qt.rgba(root.effectiveAccent.r, root.effectiveAccent.g, root.effectiveAccent.b, 0.35)

                                Text {
                                    anchors.centerIn: parent
                                    text: root.navigationPages[root.selectedCategoryIndex].icon
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 22
                                    color: root.effectiveAccent
                                }
                            }

                            // Titolo Sezione Grande
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.navigationPages[root.selectedCategoryIndex].title
                                color: "#ffffff"
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                font.family: root.textFontFamily
                            }

                            // Sottotitolo Descrittivo
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.navigationPages[root.selectedCategoryIndex].subtitle
                                color: "#8a94a6"
                                font.pixelSize: 11
                                font.family: root.textFontFamily
                            }
                        }

                        // Linea divisoria sottile inferiore
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Qt.rgba(255, 255, 255, 0.05)
                        }
                    }

                    // ── Stack View delle Pagine di Impostazioni ──
                    StackLayout {
                        id: pagesStack
                        width: parent.width
                        height: parent.height - 48 - 120
                        currentIndex: root.selectedCategoryIndex

                        // Pagina 0: Isola & Geometria
                        IslandGeometryPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            iconFontFamily: root.iconFontFamily
                        }

                        // Pagina 1: Control Center & Studio Canvas (Visual 2D Editor)
                        ControlCenterStudioPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            heroFontFamily: root.heroFontFamily
                            iconFontFamily: root.iconFontFamily
                            onRequestReloadQuickshell: {
                                if (root.dynamicConfig && typeof root.dynamicConfig.dispatchSave === "function") {
                                    root.dynamicConfig.dispatchSave();
                                }
                                try {
                                    Quickshell.reload(false);
                                } catch(e) {
                                    console.warn("[SettingsAppLayer] reload failed:", e);
                                }
                            }
                        }

                        // Pagina 2: Aspetto, Sfondi & Font
                        AppearanceFontPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            heroFontFamily: root.heroFontFamily
                            iconFontFamily: root.iconFontFamily
                            onOpenFontBrowser: function(target) { root.openFontBrowser(target); }
                        }

                        // Pagina 3: Interazioni & Movimento
                        InteractionsPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            iconFontFamily: root.iconFontFamily
                        }

                        // Pagina 4: Scorciatoie Hyprland
                        ShortcutsPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            iconFontFamily: root.iconFontFamily
                        }

                        // Pagina 5: Schermata di Blocco
                        LockScreenSettingsPage {
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
        radius: root.cornerRadius
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
                    color: "#7e889b"
                    font.pixelSize: 13
                    font.family: root.textFontFamily
                    verticalAlignment: Text.AlignVCenter
                }

                TextInput {
                    id: fontInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: "#ffffff"
                    font.pixelSize: 13
                    font.family: root.textFontFamily
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    onTextChanged: {
                        root.fontBrowserQuery = text;
                        root.updateFilteredFonts();
                    }
                }
            }

            // GridView con elenco font
            GridView {
                width: parent.width
                height: parent.height - 110
                clip: true
                cellWidth: width / 3
                cellHeight: 70
                model: root.filteredFonts

                delegate: Rectangle {
                    width: GridView.view.cellWidth - 10
                    height: 60
                    radius: 10
                    color: fontCardMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.09) : Qt.rgba(255, 255, 255, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.07)

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.family: root.textFontFamily
                            elide: Text.ElideRight
                            width: parent.parent.width - 16
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (root.fontBrowserTarget === "icon") ? "\uf001 \uf015 \uf013 \uf0e7 \uf11c" : "12:34 Aa Bb Cc"
                            color: root.effectiveAccent
                            font.pixelSize: 14
                            font.family: modelData
                        }
                    }

                    MouseArea {
                        id: fontCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.dynamicConfig) {
                                if (root.fontBrowserTarget === "icon") {
                                    root.dynamicConfig.set("iconFontFamily", modelData);
                                } else {
                                    root.dynamicConfig.set("clockFontFamily", modelData);
                                    root.dynamicConfig.set("textFontFamily", modelData);
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
