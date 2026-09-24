import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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

    // Watch dynamic pywal/iris colors
    FileView {
        id: localWalColors
        path: "/home/lollo/.cache/wal/colors.json"
        watchChanges: true
        property string walAccent: ""
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

    readonly property color effectiveAccent: {
        if (dynamicConfig && dynamicConfig.customAccentColor !== "" && !dynamicConfig.pywalEnabled)
            return dynamicConfig.customAccentColor;
        if (localWalColors.walAccent !== "")
            return localWalColors.walAccent;
        return accentColor;
    }

    readonly property string textFontFamily: dynamicConfig ? dynamicConfig.textFontFamily : "Google Sans Flex"
    readonly property string heroFontFamily: dynamicConfig ? dynamicConfig.heroFontFamily : "Google Sans Flex"
    readonly property string iconFontFamily: dynamicConfig ? dynamicConfig.iconFontFamily : "JetBrainsMono Nerd Font"

    property int selectedCategoryIndex: 0

    readonly property var navigationPages: [
        {
            title: "Isola & Geometria",
            icon: "\uf108",
            subtitle: "Dimensioni, margini & hover"
        },
        {
            title: "Interazioni & Mouse",
            icon: "\uf245",
            subtitle: "Click, rotella volume & gesti"
        },
        {
            title: "Control Center & Studio",
            icon: "\uf462",
            subtitle: "Griglia 2D, moduli & cestino"
        },
        {
            title: "Aspetto, Sfondi & Font",
            icon: "\uf1fc",
            subtitle: "Trasparenza, sfondi & font"
        },
        {
            title: "Scorciatoie da Tastiera",
            icon: "\uf11c",
            subtitle: "7 comandi Hyprland & test"
        }
    ]

    // ── Layout Principale a Due Colonne ────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 32
        color: root.bgDark
        border.width: 1
        border.color: root.borderSubtle
        clip: true

        Row {
            anchors.fill: parent

            // ── Colonna Sinistra: Sidebar ──────────────────────────────
            Rectangle {
                width: 250
                height: parent.height
                color: root.bgSidebar
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.05)

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    // App Header
                    Row {
                        spacing: 12
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 12
                            color: Qt.rgba(root.effectiveAccent.r, root.effectiveAccent.g, root.effectiveAccent.b, 0.22)
                            border.width: 1
                            border.color: root.effectiveAccent

                            Text {
                                anchors.centerIn: parent
                                text: "🏝️"
                                font.pixelSize: 18
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: "Dynamic Island"
                                color: "#f2f4f8"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                font.family: root.textFontFamily
                            }

                            Text {
                                text: "Impostazioni Sistema"
                                color: "#7e889b"
                                font.pixelSize: 11
                                font.family: root.textFontFamily
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Qt.rgba(255, 255, 255, 0.06)
                    }

                    // Navigation List
                    Column {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: root.navigationPages

                            Rectangle {
                                readonly property bool isSelected: root.selectedCategoryIndex === index
                                width: parent.width
                                height: 50
                                radius: 12
                                color: isSelected
                                    ? Qt.rgba(root.effectiveAccent.r, root.effectiveAccent.g, root.effectiveAccent.b, 0.22)
                                    : (itemMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                                border.width: isSelected ? 1 : 0
                                border.color: root.effectiveAccent

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon
                                        font.family: root.iconFontFamily
                                        font.pixelSize: 15
                                        color: isSelected ? root.effectiveAccent : "#8c94a6"
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            text: modelData.title
                                            color: isSelected ? "#ffffff" : "#c2c7d4"
                                            font.pixelSize: 12
                                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                                            font.family: root.textFontFamily
                                        }

                                        Text {
                                            text: modelData.subtitle
                                            color: isSelected ? Qt.rgba(255, 255, 255, 0.70) : "#656d80"
                                            font.pixelSize: 10
                                            font.family: root.textFontFamily
                                        }
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

                    Item { Layout.fillHeight: true; width: 1; height: 40 }

                    // Bottom Sync Pill & Reload
                    Rectangle {
                        width: parent.width
                        height: 38
                        radius: 10
                        color: Qt.rgba(255, 255, 255, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.06)

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 7; height: 7; radius: 3.5
                                color: (root.dynamicConfig && root.dynamicConfig.isSaving) ? "#fbbf24" : "#34c759"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.dynamicConfig ? root.dynamicConfig.saveStatus : "Live Synced"
                                color: "#9aa3b5"
                                font.pixelSize: 11
                                font.family: root.textFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // ── Colonna Destra: Contenuto Pagina ───────────────────────
            Rectangle {
                width: parent.width - 250
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

                        // Pulsante Chiudi [ ✕ ]
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            radius: 16
                            color: closeMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)

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

                        // Pagina 2: Interazioni & Mouse
                        InteractionsPage {
                            config: root.dynamicConfig
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            iconFontFamily: root.iconFontFamily
                        }

                        // Pagina 3: Control Center & Studio Canvas (Visual 2D Editor!)
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

                        // Pagina 5: Scorciatoie Hyprland
                        ShortcutsPage {
                            accentColor: root.effectiveAccent
                            textFontFamily: root.textFontFamily
                            iconFontFamily: root.iconFontFamily
                        }
                    }
                }
            }
        }
    }

    // ── Modal Font Browser (Sfoglia tutti i font di sistema) ───────────
    property bool fontBrowserVisible: false
    property string fontBrowserTarget: "text"
    property string fontBrowserQuery: ""
    property var systemFontsList: []
    property bool systemFontsLoaded: false
    property var filteredFonts: []

    function loadSystemFonts() {
        if (systemFontsLoaded) return;
        try {
            let list = Qt.fontFamilies();
            if (Array.isArray(list)) {
                list.sort(function(a, b) { return a.toLowerCase().localeCompare(b.toLowerCase()); });
                systemFontsList = list;
                systemFontsLoaded = true;
            }
        } catch(e) {}
    }

    function updateFilteredFonts() {
        let q = fontBrowserQuery.toLowerCase().trim();
        let list = systemFontsList;
        let res = [];
        for (let i = 0; i < list.length; i++) {
            let font = list[i];
            if (q !== "" && font.toLowerCase().indexOf(q) === -1) continue;
            res.push(font);
            if (res.length >= 300) break;
        }
        filteredFonts = res;
    }

    function openFontBrowser(target) {
        loadSystemFonts();
        fontBrowserTarget = target;
        fontBrowserQuery = "";
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
                    text: "Sfoglia Font di Sistema (" + root.systemFontsList.length + " installati)"
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

                TextInput {
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
                            width: 240
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Pack my box with five dozen liquor jugs 1234567890"
                            color: "#8c94a6"
                            font.pixelSize: 13
                            font.family: modelData
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - 270
                        }
                    }

                    MouseArea {
                        id: fontRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.dynamicConfig) {
                                if (root.fontBrowserTarget === "icon") {
                                    root.dynamicConfig.set("iconFontFamily", modelData);
                                } else {
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
