import QtQuick
import Quickshell
import Quickshell.Io
import IslandBackend

FocusScope {
    id: root

    signal closeRequested()

    implicitWidth: 840
    implicitHeight: 560
    width: 840
    height: 560

    property bool showCondition: true
    focus: showCondition
    activeFocusOnTab: true

    Keys.onEscapePressed: function(event) {
        event.accepted = true;
        root.closeRequested();
    }

    // Typography and fonts
    readonly property string iconFontFamily: UserConfig.iconFontFamily !== "" ? UserConfig.iconFontFamily : "JetBrainsMono Nerd Font"
    readonly property string textFontFamily: UserConfig.textFontFamily !== "" ? UserConfig.textFontFamily : "Google Sans Flex"
    readonly property string heroFontFamily: UserConfig.heroFontFamily !== "" ? UserConfig.heroFontFamily : "Google Sans Flex"

    // External theme inputs (from DynamicIslandWindow)
    property color accentColor: StyleTokens.accent
    property color pywalBackground: "#0f141c"
    property color pywalForeground: "#ffffff"

    // Live watchers for Iris and Pywal palette files
    FileView {
        id: localIrisColors
        path: "/home/lollo/.cache/iris/colors.json"
        watchChanges: true
        property string accentHex: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.accent) accentHex = d.accent;
            } catch(e) {}
        }
    }

    FileView {
        id: localWalColors
        path: "/home/lollo/.cache/wal/colors.json"
        watchChanges: true
        property string walAccent: ""
        property color walBg: "#0f141c"
        property color walFg: "#ffffff"
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.colors) {
                    walAccent = d.colors.color4 || d.colors.color2 || "#0a84ff";
                }
                if (d && d.special) {
                    if (d.special.background) walBg = d.special.background;
                    if (d.special.foreground) walFg = d.special.foreground;
                }
            } catch(e) {}
        }
    }

    // Unified dynamic theme tokens
    readonly property color effectiveAccent: {
        if (accentColor !== StyleTokens.accent && String(accentColor) !== "#00000000") return accentColor;
        if (localIrisColors.accentHex !== "") return localIrisColors.accentHex;
        if (localWalColors.walAccent !== "") return localWalColors.walAccent;
        return StyleTokens.accent;
    }

    readonly property color effectiveBg: {
        const base = pywalBackground !== "#0f141c" ? pywalBackground : localWalColors.walBg;
        return Qt.darker(base, 1.15);
    }

    readonly property color effectiveFg: {
        return pywalForeground !== "#ffffff" ? pywalForeground : localWalColors.walFg;
    }

    // Glass & Accent Derivations
    readonly property color accentSoft: Qt.rgba(effectiveAccent.r, effectiveAccent.g, effectiveAccent.b, 0.16)
    readonly property color accentBorder: Qt.rgba(effectiveAccent.r, effectiveAccent.g, effectiveAccent.b, 0.42)
    readonly property color accentGlow: Qt.rgba(effectiveAccent.r, effectiveAccent.g, effectiveAccent.b, 0.28)
    readonly property color accentPressed: Qt.darker(effectiveAccent, 1.3)

    readonly property color bgGlass: Qt.rgba(14/255, 17/255, 24/255, 0.94)
    readonly property color bgSidebar: Qt.rgba(10/255, 12/255, 17/255, 0.97)
    readonly property color bgCard: Qt.rgba(255, 255, 255, 0.045)
    readonly property color bgCardHover: Qt.rgba(255, 255, 255, 0.08)
    readonly property color borderCard: Qt.rgba(255, 255, 255, 0.08)
    readonly property color borderSubtle: Qt.rgba(255, 255, 255, 0.05)
    readonly property color dividerColor: Qt.rgba(255, 255, 255, 0.04)
    readonly property color textPrimary: "#f2f4f8"
    readonly property color textSecondary: "#9aa3b5"
    readonly property color textMuted: "#656f82"
    readonly property color successColor: "#34c759"
    readonly property color switchOffColor: Qt.rgba(255, 255, 255, 0.12)

    // Active navigation
    property int selectedCategoryIndex: 0
    property string searchQuery: ""

    // Raw configuration store
    property var configData: ({})
    property bool configLoaded: false
    property bool hasPendingSave: false
    property bool isSaving: false
    property string lastSavedStatus: "Live Synced"

    // Live configurable properties mirroring userconfig.json
    property int cfgCornerRadius: 32
    property int cfgIslandHeight: UserConfig.islandHeight > 0 ? UserConfig.islandHeight : 40
    property int cfgIslandWidth: UserConfig.islandWidth > 0 ? UserConfig.islandWidth : 140
    property int cfgTopMargin: UserConfig.islandTopMargin >= 0 ? UserConfig.islandTopMargin : 8
    property int cfgExclusiveZone: UserConfig.islandExclusiveZone >= 0 ? UserConfig.islandExclusiveZone : 0
    property int cfgClusterGap: 12
    property int cfgStageLift: 0
    property int cfgBackgroundOpacity: UserConfig.islandBackgroundOpacity > 0 ? UserConfig.islandBackgroundOpacity : 100
    property int cfgAutoHideDelay: UserConfig.islandAutoHideDelayMs > 0 ? UserConfig.islandAutoHideDelayMs : 2000
    property bool cfgAutoHideEnabled: UserConfig.islandAutoHideEnabled
    property bool cfgShowWorkspaceOnAutoHide: UserConfig.islandShowWorkspaceOnAutoHide
    property bool cfgDisableAutoExpand: UserConfig.disableAutoExpandOnTrackChange

    // Hover & Interaction Properties
    property bool cfgHoverExpandEnabled: true
    property int cfgHoverExpandAction: 2 // 1: Player, 2: Control Center
    property int cfgHoverExpandDelay: 200

    // Control Center Module Toggles
    property bool cfgShowWifiCard: true
    property bool cfgShowBluetoothCard: true
    property bool cfgShowBarraDesktopCard: true
    property bool cfgShowTlpBatteryMode: true
    property bool cfgShowDisplaySoundSliders: true
    property bool cfgShowNightFocusToggles: true
    property bool cfgShowClipboardQuickAccess: true

    // Appearance & Typography
    property string cfgClockFormat: UserConfig.clockFormat !== "" ? UserConfig.clockFormat : "24"
    property int cfgBodyFontSize: UserConfig.bodyFontSize > 0 ? UserConfig.bodyFontSize : 20
    property int cfgTitleFontSize: UserConfig.titleFontSize > 0 ? UserConfig.titleFontSize : 24
    property int cfgIconFontSize: UserConfig.iconFontSize > 0 ? UserConfig.iconFontSize : 22
    property bool cfgPywalEnabled: UserConfig.wallpaperPywalEnabled

    // Motion & Animation
    property string cfgTransitionType: UserConfig.wallpaperTransitionType !== "" ? UserConfig.wallpaperTransitionType : "random"
    property real cfgTransitionDuration: UserConfig.wallpaperTransitionDuration > 0 ? UserConfig.wallpaperTransitionDuration : 1.0
    property int cfgTransitionFps: UserConfig.wallpaperTransitionFps > 0 ? UserConfig.wallpaperTransitionFps : 60
    property int cfgAnimationSpeedMode: 0 // 0: Snappy, 1: Smooth, 2: Bouncy

    // Modules & Actions
    property string cfgPrimaryAction: UserConfig.dynamicIslandPrimaryAction !== "" ? UserConfig.dynamicIslandPrimaryAction : "toggleControlCenter"
    property string cfgSecondaryAction: UserConfig.dynamicIslandSecondaryAction !== "" ? UserConfig.dynamicIslandSecondaryAction : "toggleControlCenter"
    property var cfgSwipeItems: ["albumcover", "trackname", "date", "time", "workspace", "battery"]

    // Categories list definition
    readonly property var categories: [
        {
            key: "bar",
            title: "Bar & Island",
            icon: "\uf108", // desktop
            subtitle: "Geometry, margins & hover behavior"
        },
        {
            key: "controlcenter",
            title: "Control Center",
            icon: "\uf462", // sliders
            subtitle: "Module cards & quick toggles"
        },
        {
            key: "appearance",
            title: "Appearance",
            icon: "\uf1fc", // palette
            subtitle: "Opacity, fonts & clock format"
        },
        {
            key: "motion",
            title: "Motion & Animation",
            icon: "\uf0e7", // bolt
            subtitle: "Transitions, FPS & dynamics"
        },
        {
            key: "modules",
            title: "Modules",
            icon: "\uf1b2", // cube
            subtitle: "Island swipe pills & actions"
        }
    ]

    // Read userconfig.json
    FileView {
        id: configFileView
        path: UserConfig.userConfigPath !== "" ? UserConfig.userConfigPath : (StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/dynamic-island/userconfig.json")
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root.loadConfigFromDisk()
        onFileChanged: root.loadConfigFromDisk()
    }

    function loadConfigFromDisk() {
        try {
            const raw = configFileView.text();
            if (!raw || raw.trim() === "") return;
            const parsed = JSON.parse(raw);
            root.configData = parsed;

            if (parsed.islandCornerRadius !== undefined) root.cfgCornerRadius = Math.round(Number(parsed.islandCornerRadius));
            if (parsed.islandHeight !== undefined) root.cfgIslandHeight = Math.round(Number(parsed.islandHeight));
            if (parsed.islandWidth !== undefined) root.cfgIslandWidth = Math.round(Number(parsed.islandWidth));
            if (parsed.islandTopMargin !== undefined) root.cfgTopMargin = Math.round(Number(parsed.islandTopMargin));
            if (parsed.islandExclusiveZone !== undefined) root.cfgExclusiveZone = Math.round(Number(parsed.islandExclusiveZone));
            if (parsed.islandClusterGap !== undefined) root.cfgClusterGap = Math.round(Number(parsed.islandClusterGap));
            if (parsed.islandStageLift !== undefined) root.cfgStageLift = Math.round(Number(parsed.islandStageLift));
            if (parsed.islandBackgroundOpacity !== undefined) root.cfgBackgroundOpacity = Math.round(Number(parsed.islandBackgroundOpacity));
            if (parsed.islandAutoHideEnabled !== undefined) root.cfgAutoHideEnabled = Boolean(parsed.islandAutoHideEnabled);
            if (parsed.islandAutoHideDelayMs !== undefined) root.cfgAutoHideDelay = Math.round(Number(parsed.islandAutoHideDelayMs));
            if (parsed.islandShowWorkspaceOnAutoHide !== undefined) root.cfgShowWorkspaceOnAutoHide = Boolean(parsed.islandShowWorkspaceOnAutoHide);
            if (parsed.disableAutoExpandOnTrackChange !== undefined) root.cfgDisableAutoExpand = Boolean(parsed.disableAutoExpandOnTrackChange);

            if (parsed.hoverExpandEnabled !== undefined) root.cfgHoverExpandEnabled = Boolean(parsed.hoverExpandEnabled);
            if (parsed.hoverExpandAction !== undefined) root.cfgHoverExpandAction = Math.round(Number(parsed.hoverExpandAction));
            if (parsed.hoverExpandDelayMs !== undefined) root.cfgHoverExpandDelay = Math.round(Number(parsed.hoverExpandDelayMs));

            if (parsed.showWifiCard !== undefined) root.cfgShowWifiCard = Boolean(parsed.showWifiCard);
            if (parsed.showBluetoothCard !== undefined) root.cfgShowBluetoothCard = Boolean(parsed.showBluetoothCard);
            if (parsed.showBarraDesktopCard !== undefined) root.cfgShowBarraDesktopCard = Boolean(parsed.showBarraDesktopCard);
            if (parsed.showTlpBatteryMode !== undefined) root.cfgShowTlpBatteryMode = Boolean(parsed.showTlpBatteryMode);
            if (parsed.showDisplaySoundSliders !== undefined) root.cfgShowDisplaySoundSliders = Boolean(parsed.showDisplaySoundSliders);
            if (parsed.showNightFocusToggles !== undefined) root.cfgShowNightFocusToggles = Boolean(parsed.showNightFocusToggles);
            if (parsed.showClipboardQuickAccess !== undefined) root.cfgShowClipboardQuickAccess = Boolean(parsed.showClipboardQuickAccess);

            if (parsed.clockFormat !== undefined) root.cfgClockFormat = String(parsed.clockFormat);
            if (parsed.bodyFontSize !== undefined) root.cfgBodyFontSize = Math.round(Number(parsed.bodyFontSize));
            if (parsed.titleFontSize !== undefined) root.cfgTitleFontSize = Math.round(Number(parsed.titleFontSize));
            if (parsed.iconFontSize !== undefined) root.cfgIconFontSize = Math.round(Number(parsed.iconFontSize));
            if (parsed.wallpaperPywalEnabled !== undefined) root.cfgPywalEnabled = Boolean(parsed.wallpaperPywalEnabled);
            if (parsed.wallpaperTransitionType !== undefined) root.cfgTransitionType = String(parsed.wallpaperTransitionType);
            if (parsed.wallpaperTransitionDuration !== undefined) root.cfgTransitionDuration = Number(parsed.wallpaperTransitionDuration);
            if (parsed.wallpaperTransitionFps !== undefined) root.cfgTransitionFps = Math.round(Number(parsed.wallpaperTransitionFps));
            if (parsed.dynamicIslandPrimaryAction !== undefined) root.cfgPrimaryAction = String(parsed.dynamicIslandPrimaryAction);
            if (parsed.dynamicIslandSecondaryAction !== undefined) root.cfgSecondaryAction = String(parsed.dynamicIslandSecondaryAction);
            if (Array.isArray(parsed.dynamicIslandLeftSwipeItems)) root.cfgSwipeItems = parsed.dynamicIslandLeftSwipeItems.slice();

            root.configLoaded = true;
        } catch(e) {
            console.log("[SettingsApp] Error loading config:", e);
        }
    }

    // Debounced live save
    function updateSetting(key, val) {
        if (!root.configData) root.configData = {};
        root.configData[key] = val;
        root.lastSavedStatus = "Saving...";
        saveDebounceTimer.restart();
    }

    Timer {
        id: saveDebounceTimer
        interval: 100
        repeat: false
        onTriggered: root.dispatchSave()
    }

    Process {
        id: saveProcess
        property string payload: ""
        command: [
            "python3",
            "-c",
            "import sys, json, os\n" +
            "p = os.path.expanduser('~/.config/dynamic-island/userconfig.json')\n" +
            "os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "d = {}\n" +
            "if os.path.exists(p):\n" +
            "    try:\n" +
            "        with open(p, 'r', encoding='utf-8') as f: d = json.load(f)\n" +
            "    except: d = {}\n" +
            "d.update(json.loads(sys.argv[1]))\n" +
            "tmp = p + '.tmp'\n" +
            "with open(tmp, 'w', encoding='utf-8') as f:\n" +
            "    json.dump(d, f, indent=4, ensure_ascii=False)\n" +
            "    f.write('\\n')\n" +
            "os.replace(tmp, p)\n",
            payload
        ]
        running: false
        onExited: function(code) {
            root.isSaving = false;
            if (code === 0) {
                root.lastSavedStatus = "Live Synced";
                try {
                    UserConfig.reload();
                } catch(e) {
                    console.log("[SettingsApp] Error reloading UserConfig:", e);
                }
            } else {
                root.lastSavedStatus = "Error saving";
            }
            if (root.hasPendingSave) {
                root.hasPendingSave = false;
                saveDebounceTimer.restart();
            }
        }
    }

    function dispatchSave() {
        if (saveProcess.running) {
            root.hasPendingSave = true;
            return;
        }
        root.isSaving = true;
        saveProcess.payload = JSON.stringify(root.configData);
        saveProcess.running = true;
    }

    Component.onCompleted: {
        root.loadConfigFromDisk();
    }

    // Outer Window Shell: 840x560 with smooth radius
    Rectangle {
        id: windowFrame
        anchors.fill: parent
        radius: 28
        color: root.bgGlass
        border.width: 1
        border.color: root.borderCard
        clip: true

        // Ambient theme accent background glow
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.accentGlow }
                GradientStop { position: 0.12; color: Qt.rgba(root.effectiveAccent.r, root.effectiveAccent.g, root.effectiveAccent.b, 0.04) }
                GradientStop { position: 1.0; color: StyleTokens.transparent }
            }
        }

        // Inner subtle specular highlight rim
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: StyleTokens.transparent
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.07)
        }

        // Main Horizontal Split: Left Sidebar (234px) + Right Content Area
        Row {
            anchors.fill: parent

            // ==========================================
            // LEFT SIDEBAR (Width: 234px)
            // ==========================================
            Rectangle {
                id: sidebar
                width: 234
                height: parent.height
                color: root.bgSidebar

                // Right border divider
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.borderSubtle
                }

                // Sidebar Layout Column
                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // App Brand Header
                    Row {
                        width: parent.width
                        height: 46
                        spacing: 12

                        // Glowing Logo Capsule
                        Rectangle {
                            width: 42
                            height: 42
                            radius: 13
                            color: root.accentSoft
                            border.width: 1
                            border.color: root.accentBorder
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "\uf108" // Dynamic Island / Desktop
                                font.family: root.iconFontFamily
                                font.pixelSize: 19
                                color: root.effectiveAccent
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "Dynamic Island"
                                font.family: root.heroFontFamily
                                font.pixelSize: 15
                                font.weight: Font.Bold
                                color: root.textPrimary
                            }

                            Text {
                                text: "Preferences & Styles"
                                font.family: root.textFontFamily
                                font.pixelSize: 11
                                color: root.textMuted
                            }
                        }
                    }

                    // Divider
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: root.borderSubtle
                    }

                    // Categories List
                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.categories

                            delegate: Rectangle {
                                id: navItem
                                required property int index
                                required property var modelData

                                readonly property bool isSelected: root.selectedCategoryIndex === index
                                readonly property bool isHovered: navMouse.containsMouse

                                width: sidebar.width - 28
                                height: 44
                                radius: 12
                                color: isSelected ? root.accentSoft : (isHovered ? Qt.rgba(255, 255, 255, 0.05) : StyleTokens.transparent)
                                border.width: isSelected ? 1 : 0
                                border.color: isSelected ? root.accentBorder : StyleTokens.transparent

                                Behavior on color {
                                    ColorAnimation { duration: 140 }
                                }

                                // Active indicator pill on left edge
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 3.5
                                    height: 20
                                    radius: 1.75
                                    color: root.effectiveAccent
                                    visible: navItem.isSelected
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: navItem.modelData.icon
                                        font.family: root.iconFontFamily
                                        font.pixelSize: 15
                                        color: navItem.isSelected ? root.effectiveAccent : (navItem.isHovered ? root.textPrimary : root.textSecondary)
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: navItem.modelData.title
                                        font.family: root.textFontFamily
                                        font.pixelSize: 13
                                        font.weight: navItem.isSelected ? Font.DemiBold : Font.Normal
                                        color: navItem.isSelected ? root.textPrimary : (navItem.isHovered ? "#ffffff" : root.textSecondary)
                                    }
                                }

                                MouseArea {
                                    id: navMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedCategoryIndex = navItem.index;
                                        root.searchQuery = "";
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        // Flexible spacer
                        width: parent.width
                        height: Math.max(16, sidebar.height - 350)
                    }

                    // Sidebar Footer: Live Status & Reload
                    Rectangle {
                        width: parent.width
                        height: 50
                        radius: 12
                        color: Qt.rgba(255, 255, 255, 0.03)
                        border.width: 1
                        border.color: root.borderSubtle

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            // Pulsing Sync Dot
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: root.isSaving ? "#e5a93b" : root.effectiveAccent
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    running: root.isSaving
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.3; duration: 400 }
                                    NumberAnimation { to: 1.0; duration: 400 }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: root.lastSavedStatus
                                    font.family: root.textFontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: root.isSaving ? "#e5a93b" : root.textPrimary
                                }

                                Text {
                                    text: "userconfig.json"
                                    font.family: root.textFontFamily
                                    font.pixelSize: 9
                                    color: root.textMuted
                                }
                            }

                            Item { width: 1; height: 1 } // spacer

                            // Quick manual reload button
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: reloadMouse.containsMouse ? root.accentSoft : Qt.rgba(255, 255, 255, 0.05)
                                border.width: 1
                                border.color: reloadMouse.containsMouse ? root.accentBorder : root.borderCard
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: reloadIcon
                                    anchors.centerIn: parent
                                    text: "\uf021" // Refresh
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 12
                                    color: reloadMouse.containsMouse ? root.effectiveAccent : root.textSecondary

                                    RotationAnimation on rotation {
                                        id: reloadAnim
                                        running: false
                                        from: 0
                                        to: 360
                                        duration: 400
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                MouseArea {
                                    id: reloadMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        reloadAnim.restart();
                                        UserConfig.reload();
                                        root.loadConfigFromDisk();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // RIGHT CONTENT AREA (Width: 606px)
            // ==========================================
            Item {
                id: contentArea
                width: parent.width - sidebar.width
                height: parent.height

                // Top Header Bar
                Rectangle {
                    id: headerBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 64
                    color: StyleTokens.transparent

                    // Bottom subtle separator line
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: root.borderSubtle
                    }

                    // Category Title & Icon Badge
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 10
                            color: root.accentSoft
                            border.width: 1
                            border.color: root.accentBorder
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: root.categories[root.selectedCategoryIndex].icon
                                font.family: root.iconFontFamily
                                font.pixelSize: 16
                                color: root.effectiveAccent
                            }
                        }

                        Text {
                            text: root.categories[root.selectedCategoryIndex].title
                            font.family: root.heroFontFamily
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: root.textPrimary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Search field and Close Button
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        // Search capsule
                        Rectangle {
                            width: 180
                            height: 32
                            radius: 16
                            color: Qt.rgba(255, 255, 255, 0.05)
                            border.width: 1
                            border.color: searchInput.activeFocus ? root.effectiveAccent : root.borderCard

                            Behavior on border.color {
                                ColorAnimation { duration: 120 }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "\uf002" // Search icon
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 11
                                    color: root.textMuted
                                }

                                TextInput {
                                    id: searchInput
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 40
                                    font.family: root.textFontFamily
                                    font.pixelSize: 12
                                    color: root.textPrimary
                                    clip: true
                                    onTextChanged: root.searchQuery = text.toLowerCase().trim()

                                    Text {
                                        anchors.fill: parent
                                        text: "Search settings..."
                                        font.family: root.textFontFamily
                                        font.pixelSize: 12
                                        color: root.textMuted
                                        visible: !searchInput.text && !searchInput.activeFocus
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "\u2715"
                                    font.pixelSize: 10
                                    color: root.textMuted
                                    visible: searchInput.text !== ""
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: searchInput.text = ""
                                    }
                                }
                            }
                        }

                        // Close Button ('✕')
                        Rectangle {
                            id: closeBtn
                            width: 32
                            height: 32
                            radius: 16
                            color: closeMouse.pressed ? "#551c22" : (closeMouse.containsMouse ? "#3a191d" : Qt.rgba(255, 255, 255, 0.05))
                            border.width: 1
                            border.color: closeMouse.containsMouse ? "#7d2c34" : root.borderCard

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent
                                text: "\u2715" // ✕
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: closeMouse.containsMouse ? "#ff453a" : root.textSecondary
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

                // Scrollable Content
                Flickable {
                    id: flickable
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: headerBar.bottom
                    anchors.bottom: parent.bottom
                    anchors.margins: 20
                    contentWidth: width
                    contentHeight: contentColumn.height + 40
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: contentColumn
                        width: parent.width
                        spacing: 18

                        // ==========================================
                        // CATEGORY 0: BAR & ISLAND
                        // ==========================================
                        Column {
                            width: parent.width
                            spacing: 14
                            visible: root.selectedCategoryIndex === 0 || (root.searchQuery !== "" && (
                                "bar island geometry height width radius margin auto-hide hover".indexOf(root.searchQuery) >= 0
                            ))

                            SettingsSectionHeader { title: "ISLAND GEOMETRY" }

                            // Group Card: Dimensions & Radius
                            Rectangle {
                                width: parent.width
                                height: geomCol.height + 24
                                radius: 18
                                color: root.bgCard
                                border.width: 1
                                border.color: root.borderCard

                                Column {
                                    id: geomCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 8

                                    // Corner Radius Slider
                                    SettingsSliderRow {
                                        title: "Corner Radius"
                                        desc: "Roundness of the dynamic island capsule"
                                        fromVal: 16
                                        toVal: 44
                                        step: 1
                                        unitStr: "px"
                                        currentVal: root.cfgCornerRadius
                                        onValMoved: function(nextVal) {
                                            root.cfgCornerRadius = Math.round(nextVal);
                                            root.updateSetting("islandCornerRadius", root.cfgCornerRadius);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Island Height Slider
                                    SettingsSliderRow {
                                        title: "Island Height"
                                        desc: "Resting height of the main capsule"
                                        fromVal: 32
                                        toVal: 54
                                        step: 1
                                        unitStr: "px"
                                        currentVal: root.cfgIslandHeight
                                        onValMoved: function(nextVal) {
                                            root.cfgIslandHeight = Math.round(nextVal);
                                            root.updateSetting("islandHeight", root.cfgIslandHeight);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Island Width Slider
                                    SettingsSliderRow {
                                        title: "Island Width"
                                        desc: "Compact resting width before expansion"
                                        fromVal: 120
                                        toVal: 260
                                        step: 2
                                        unitStr: "px"
                                        currentVal: root.cfgIslandWidth
                                        onValMoved: function(nextVal) {
                                            root.cfgIslandWidth = Math.round(nextVal);
                                            root.updateSetting("islandWidth", root.cfgIslandWidth);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Top Margin Slider
                                    SettingsSliderRow {
                                        title: "Top Margin"
                                        desc: "Offset from top edge of screen bezel"
                                        fromVal: 0
                                        toVal: 60
                                        step: 1
                                        unitStr: "px"
                                        currentVal: root.cfgTopMargin
                                        onValMoved: function(nextVal) {
                                            root.cfgTopMargin = Math.round(nextVal);
                                            root.updateSetting("islandTopMargin", root.cfgTopMargin);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Exclusive Zone / Stage Lift Slider
                                    SettingsSliderRow {
                                        title: "Stage Lift / Exclusive Zone"
                                        desc: "Reserved space pushing application windows down"
                                        fromVal: 0
                                        toVal: 64
                                        step: 2
                                        unitStr: "px"
                                        currentVal: root.cfgExclusiveZone
                                        onValMoved: function(nextVal) {
                                            root.cfgExclusiveZone = Math.round(nextVal);
                                            root.updateSetting("islandExclusiveZone", root.cfgExclusiveZone);
                                        }
                                    }
                                }
                            }

                            SettingsSectionHeader { title: "MOUSE HOVER INTERACTION" }

                            // Group Card: Hover Settings
                            Rectangle {
                                width: parent.width
                                height: hoverCol.height + 24
                                radius: 18
                                color: root.bgCard
                                border.width: 1
                                border.color: root.borderCard

                                Column {
                                    id: hoverCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 8

                                    // Hover Expand Toggle
                                    SettingsSwitchRow {
                                        title: "Hover to Open Island"
                                        desc: "Instantly open the island by moving mouse cursor over it"
                                        iconGlyph: "\uf245" // mouse pointer
                                        checked: root.cfgHoverExpandEnabled
                                        onToggled: function(val) {
                                            root.cfgHoverExpandEnabled = val;
                                            root.updateSetting("hoverExpandEnabled", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Hover Target Action
                                    Row {
                                        width: parent.width
                                        height: 48

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 230
                                            spacing: 2

                                            Text {
                                                text: "Hover Open Target"
                                                font.family: root.textFontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                color: root.textPrimary
                                            }

                                            Text {
                                                text: "Choose what opens when hovering cursor"
                                                font.family: root.textFontFamily
                                                font.pixelSize: 11
                                                color: root.textSecondary
                                            }
                                        }

                                        // Segmented Target Picker
                                        Rectangle {
                                            width: 220
                                            height: 30
                                            radius: 15
                                            color: Qt.rgba(255, 255, 255, 0.05)
                                            border.width: 1
                                            border.color: root.borderCard
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                anchors.fill: parent

                                                Rectangle {
                                                    width: parent.width / 2
                                                    height: parent.height
                                                    radius: 15
                                                    color: root.cfgHoverExpandAction === 2 ? root.effectiveAccent : StyleTokens.transparent

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "Control Center"
                                                        font.family: root.textFontFamily
                                                        font.pixelSize: 11
                                                        font.weight: root.cfgHoverExpandAction === 2 ? Font.Bold : Font.Normal
                                                        color: root.cfgHoverExpandAction === 2 ? "#ffffff" : root.textSecondary
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.cfgHoverExpandAction = 2;
                                                            root.updateSetting("hoverExpandAction", 2);
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    width: parent.width / 2
                                                    height: parent.height
                                                    radius: 15
                                                    color: root.cfgHoverExpandAction === 1 ? root.effectiveAccent : StyleTokens.transparent

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "Music Player"
                                                        font.family: root.textFontFamily
                                                        font.pixelSize: 11
                                                        font.weight: root.cfgHoverExpandAction === 1 ? Font.Bold : Font.Normal
                                                        color: root.cfgHoverExpandAction === 1 ? "#ffffff" : root.textSecondary
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.cfgHoverExpandAction = 1;
                                                            root.updateSetting("hoverExpandAction", 1);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Hover Expand Delay Slider
                                    SettingsSliderRow {
                                        title: "Hover Open Delay"
                                        desc: "Cursor dwell time before triggering island expansion"
                                        fromVal: 100
                                        toVal: 500
                                        step: 25
                                        unitStr: "ms"
                                        currentVal: root.cfgHoverExpandDelay
                                        onValMoved: function(nextVal) {
                                            root.cfgHoverExpandDelay = Math.round(nextVal);
                                            root.updateSetting("hoverExpandDelayMs", root.cfgHoverExpandDelay);
                                        }
                                    }
                                }
                            }

                            SettingsSectionHeader { title: "ISLAND AUTO-HIDE & BEHAVIOR" }

                            // Group Card: Auto-hide & Media
                            Rectangle {
                                width: parent.width
                                height: behavCol.height + 24
                                radius: 18
                                color: root.bgCard
                                border.width: 1
                                border.color: root.borderCard

                                Column {
                                    id: behavCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 8

                                    // Auto-hide toggle
                                    SettingsSwitchRow {
                                        title: "Auto-hide Dynamic Island"
                                        desc: "Collapse island when no active track or alert is present"
                                        iconGlyph: "\uf070" // eye slash
                                        checked: root.cfgAutoHideEnabled
                                        onToggled: function(val) {
                                            root.cfgAutoHideEnabled = val;
                                            root.updateSetting("islandAutoHideEnabled", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Auto-hide delay slider
                                    SettingsSliderRow {
                                        title: "Auto-hide Inactivity Delay"
                                        desc: "Delay before automatically tucking the island away"
                                        fromVal: 500
                                        toVal: 5000
                                        step: 250
                                        unitStr: "ms"
                                        currentVal: root.cfgAutoHideDelay
                                        onValMoved: function(nextVal) {
                                            root.cfgAutoHideDelay = Math.round(nextVal);
                                            root.updateSetting("islandAutoHideDelayMs", root.cfgAutoHideDelay);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Show Workspace on Auto-hide
                                    SettingsSwitchRow {
                                        title: "Show Workspace on Auto-hide"
                                        desc: "Display active workspace number indicator when tucked"
                                        iconGlyph: "\uf108"
                                        checked: root.cfgShowWorkspaceOnAutoHide
                                        onToggled: function(val) {
                                            root.cfgShowWorkspaceOnAutoHide = val;
                                            root.updateSetting("islandShowWorkspaceOnAutoHide", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Disable Media Auto-expand
                                    SettingsSwitchRow {
                                        title: "Disable Media Track Auto-Expand"
                                        desc: "Prevent island from popping open whenever songs change"
                                        iconGlyph: "\uf001"
                                        checked: root.cfgDisableAutoExpand
                                        onToggled: function(val) {
                                            root.cfgDisableAutoExpand = val;
                                            root.updateSetting("disableAutoExpandOnTrackChange", val);
                                        }
                                    }
                                }
                            }
                        }

                        // ==========================================
                        // CATEGORY 1: CONTROL CENTER
                        // ==========================================
                        Column {
                            width: parent.width
                            spacing: 14
                            visible: root.selectedCategoryIndex === 1 || (root.searchQuery !== "" && (
                                "control center module card wifi bluetooth barra battery sound sliders night focus clipboard".indexOf(root.searchQuery) >= 0
                            ))

                            SettingsSectionHeader { title: "CONTROL CENTER MODULES" }

                            // Group Card: Module Switches
                            Rectangle {
                                width: parent.width
                                height: ccModulesCol.height + 24
                                radius: 18
                                color: root.bgCard
                                border.width: 1
                                border.color: root.borderCard

                                Column {
                                    id: ccModulesCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 8

                                    // Show Wi-Fi Card
                                    SettingsSwitchRow {
                                        title: "Show Wi-Fi Card"
                                        desc: "Network connection status, SSID and discovery drawer"
                                        iconGlyph: "\uf1eb"
                                        checked: root.cfgShowWifiCard
                                        onToggled: function(val) {
                                            root.cfgShowWifiCard = val;
                                            root.updateSetting("showWifiCard", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Show Bluetooth Card
                                    SettingsSwitchRow {
                                        title: "Show Bluetooth Card"
                                        desc: "Bluetooth controller toggle and paired peripherals"
                                        iconGlyph: "\uf294"
                                        checked: root.cfgShowBluetoothCard
                                        onToggled: function(val) {
                                            root.cfgShowBluetoothCard = val;
                                            root.updateSetting("showBluetoothCard", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Show Barra Desktop Card
                                    SettingsSwitchRow {
                                        title: "Show Barra Desktop Card"
                                        desc: "Desktop and workspace navigation overview card"
                                        iconGlyph: "\uf108"
                                        checked: root.cfgShowBarraDesktopCard
                                        onToggled: function(val) {
                                            root.cfgShowBarraDesktopCard = val;
                                            root.updateSetting("showBarraDesktopCard", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Show TLP Battery Mode
                                    SettingsSwitchRow {
                                        title: "Show TLP Battery Mode"
                                        desc: "Power profile selector (Performance, Balanced, Saver)"
                                        iconGlyph: "\uf0e7"
                                        checked: root.cfgShowTlpBatteryMode
                                        onToggled: function(val) {
                                            root.cfgShowTlpBatteryMode = val;
                                            root.updateSetting("showTlpBatteryMode", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Show Display & Sound Sliders
                                    SettingsSwitchRow {
                                        title: "Show Display & Sound Sliders"
                                        desc: "Backlight brightness and master volume sliders"
                                        iconGlyph: "\uf462"
                                        checked: root.cfgShowDisplaySoundSliders
                                        onToggled: function(val) {
                                            root.cfgShowDisplaySoundSliders = val;
                                            root.updateSetting("showDisplaySoundSliders", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Show Night Mode & Focus Toggles
                                    SettingsSwitchRow {
                                        title: "Show Night Mode & Focus Toggles"
                                        desc: "Blue light filter and distraction-free focus mode"
                                        iconGlyph: "\uf186"
                                        checked: root.cfgShowNightFocusToggles
                                        onToggled: function(val) {
                                            root.cfgShowNightFocusToggles = val;
                                            root.updateSetting("showNightFocusToggles", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Show Clipboard Quick Access
                                    SettingsSwitchRow {
                                        title: "Show Clipboard Quick Access"
                                        desc: "Direct access to cliphist clipboard history from control center"
                                        iconGlyph: "\uf0ea"
                                        checked: root.cfgShowClipboardQuickAccess
                                        onToggled: function(val) {
                                            root.cfgShowClipboardQuickAccess = val;
                                            root.updateSetting("showClipboardQuickAccess", val);
                                        }
                                    }
                                }
                            }
                        }

                        // ==========================================
                        // CATEGORY 2: APPEARANCE
                        // ==========================================
                        Column {
                            width: parent.width
                            spacing: 14
                            visible: root.selectedCategoryIndex === 2 || (root.searchQuery !== "" && (
                                "appearance opacity font typography clock format pywal palette iris".indexOf(root.searchQuery) >= 0
                            ))

                            SettingsSectionHeader { title: "APPEARANCE & THEME HARMONY" }

                            // Group Card: Styling & Fonts
                            Rectangle {
                                width: parent.width
                                height: appCol.height + 24
                                radius: 18
                                color: root.bgCard
                                border.width: 1
                                border.color: root.borderCard

                                Column {
                                    id: appCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 8

                                    // Background Opacity
                                    SettingsSliderRow {
                                        title: "Island Background Opacity"
                                        desc: "Dark matte glass transparency percentage"
                                        fromVal: 20
                                        toVal: 100
                                        step: 5
                                        unitStr: "%"
                                        currentVal: root.cfgBackgroundOpacity
                                        onValMoved: function(nextVal) {
                                            root.cfgBackgroundOpacity = Math.round(nextVal);
                                            root.updateSetting("islandBackgroundOpacity", root.cfgBackgroundOpacity);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Clock Format (24h vs 12h)
                                    Row {
                                        width: parent.width
                                        height: 48

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 150
                                            spacing: 2

                                            Text {
                                                text: "Clock Format"
                                                font.family: root.textFontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                color: root.textPrimary
                                            }

                                            Text {
                                                text: "Choose between 24-hour and 12-hour AM/PM time"
                                                font.family: root.textFontFamily
                                                font.pixelSize: 11
                                                color: root.textSecondary
                                            }
                                        }

                                        // Segmented 24h / 12h toggle
                                        Rectangle {
                                            width: 120
                                            height: 30
                                            radius: 15
                                            color: Qt.rgba(255, 255, 255, 0.05)
                                            border.width: 1
                                            border.color: root.borderCard
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                anchors.fill: parent

                                                Rectangle {
                                                    width: parent.width / 2
                                                    height: parent.height
                                                    radius: 15
                                                    color: root.cfgClockFormat === "24" ? root.effectiveAccent : StyleTokens.transparent

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "24h"
                                                        font.family: root.textFontFamily
                                                        font.pixelSize: 11
                                                        font.weight: root.cfgClockFormat === "24" ? Font.Bold : Font.Normal
                                                        color: root.cfgClockFormat === "24" ? "#ffffff" : root.textSecondary
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.cfgClockFormat = "24";
                                                            root.updateSetting("clockFormat", "24");
                                                        }
                                                    }
                                                }

                                                Rectangle {
                                                    width: parent.width / 2
                                                    height: parent.height
                                                    radius: 15
                                                    color: root.cfgClockFormat === "12" ? root.effectiveAccent : StyleTokens.transparent

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "12h"
                                                        font.family: root.textFontFamily
                                                        font.pixelSize: 11
                                                        font.weight: root.cfgClockFormat === "12" ? Font.Bold : Font.Normal
                                                        color: root.cfgClockFormat === "12" ? "#ffffff" : root.textSecondary
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.cfgClockFormat = "12";
                                                            root.updateSetting("clockFormat", "12");
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Pywal / Iris Dynamic Theming Toggle
                                    SettingsSwitchRow {
                                        title: "Pywal & Iris Dynamic Palette"
                                        desc: "Harmonize island accent colors automatically with wallpaper and theme"
                                        iconGlyph: "\uf1fc"
                                        checked: root.cfgPywalEnabled
                                        onToggled: function(val) {
                                            root.cfgPywalEnabled = val;
                                            root.updateSetting("wallpaperPywalEnabled", val);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Body Font Size
                                    SettingsSliderRow {
                                        title: "Body Font Size"
                                        desc: "Standard typography scale across modules"
                                        fromVal: 12
                                        toVal: 28
                                        step: 1
                                        unitStr: "px"
                                        currentVal: root.cfgBodyFontSize
                                        onValMoved: function(nextVal) {
                                            root.cfgBodyFontSize = Math.round(nextVal);
                                            root.updateSetting("bodyFontSize", root.cfgBodyFontSize);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Title Font Size
                                    SettingsSliderRow {
                                        title: "Title Font Size"
                                        desc: "Headers and prominent dialog text scale"
                                        fromVal: 16
                                        toVal: 36
                                        step: 1
                                        unitStr: "px"
                                        currentVal: root.cfgTitleFontSize
                                        onValMoved: function(nextVal) {
                                            root.cfgTitleFontSize = Math.round(nextVal);
                                            root.updateSetting("titleFontSize", root.cfgTitleFontSize);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Icon Font Size
                                    SettingsSliderRow {
                                        title: "Icon Font Size"
                                        desc: "Glyph indicators and system status icon scale"
                                        fromVal: 14
                                        toVal: 32
                                        step: 1
                                        unitStr: "px"
                                        currentVal: root.cfgIconFontSize
                                        onValMoved: function(nextVal) {
                                            root.cfgIconFontSize = Math.round(nextVal);
                                            root.updateSetting("iconFontSize", root.cfgIconFontSize);
                                        }
                                    }
                                }
                            }
                        }

                        // ==========================================
                        // CATEGORY 3: MOTION & ANIMATION
                        // ==========================================
                        Column {
                            width: parent.width
                            spacing: 14
                            visible: root.selectedCategoryIndex === 3 || (root.searchQuery !== "" && (
                                "motion animation fps transition duration curve".indexOf(root.searchQuery) >= 0
                            ))

                            SettingsSectionHeader { title: "MOTION & ANIMATION" }

                            // Group Card: Motion
                            Rectangle {
                                width: parent.width
                                height: motionCol.height + 24
                                radius: 18
                                color: root.bgCard
                                border.width: 1
                                border.color: root.borderCard

                                Column {
                                    id: motionCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 8

                                    // Wallpaper Transition Duration
                                    SettingsSliderRow {
                                        title: "Transition Duration"
                                        desc: "Crossfade and morphing duration for wallpaper updates"
                                        fromVal: 0.2
                                        toVal: 3.0
                                        step: 0.1
                                        unitStr: "s"
                                        currentVal: root.cfgTransitionDuration
                                        onValMoved: function(nextVal) {
                                            root.cfgTransitionDuration = Math.round(nextVal * 10) / 10;
                                            root.updateSetting("wallpaperTransitionDuration", root.cfgTransitionDuration);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Animation Refresh Rate (FPS)
                                    SettingsSliderRow {
                                        title: "Animation Framerate (FPS)"
                                        desc: "Target refresh rate for fluid swiping and animations"
                                        fromVal: 30
                                        toVal: 165
                                        step: 5
                                        unitStr: "fps"
                                        currentVal: root.cfgTransitionFps
                                        onValMoved: function(nextVal) {
                                            root.cfgTransitionFps = Math.round(nextVal);
                                            root.updateSetting("wallpaperTransitionFps", root.cfgTransitionFps);
                                        }
                                    }

                                    Rectangle { width: parent.width; height: 1; color: root.dividerColor }

                                    // Animation Curves Preset
                                    Row {
                                        width: parent.width
                                        height: 48

                                        Column {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 240
                                            spacing: 2

                                            Text {
                                                text: "Motion Curve Profile"
                                                font.family: root.textFontFamily
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                color: root.textPrimary
                                            }

                                            Text {
                                                text: "Spring and easing characteristics of the island"
                                                font.family: root.textFontFamily
                                                font.pixelSize: 11
                                                color: root.textSecondary
                                            }
                                        }

                                        Rectangle {
                                            width: 220
                                            height: 30
                                            radius: 15
                                            color: Qt.rgba(255, 255, 255, 0.05)
                                            border.width: 1
                                            border.color: root.borderCard
                                            anchors.verticalCenter: parent.verticalCenter

                                            Row {
                                                anchors.fill: parent

                                                Repeater {
                                                    model: ["Snappy (iOS)", "Smooth", "Bouncy"]

                                                    delegate: Rectangle {
                                                        required property int index
                                                        required property string modelData
                                                        width: 220 / 3
                                                        height: parent.height
                                                        radius: 15
                                                        color: root.cfgAnimationSpeedMode === index ? root.effectiveAccent : StyleTokens.transparent

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: modelData
                                                            font.family: root.textFontFamily
                                                            font.pixelSize: 10
                                                            font.weight: root.cfgAnimationSpeedMode === index ? Font.Bold : Font.Normal
                                                            color: root.cfgAnimationSpeedMode === index ? "#ffffff" : root.textSecondary
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                root.cfgAnimationSpeedMode = index;
                                                                root.updateSetting("animationProfile", index);
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

                        // ==========================================
                        // CATEGORY 4: MODULES
                        // ==========================================
                        Column {
                            width: parent.width
                            spacing: 14
                            visible: root.selectedCategoryIndex === 4 || (root.searchQuery !== "" && (
                                "modules swipe pills triggers actions".indexOf(root.searchQuery) >= 0
                            ))

                            SettingsSectionHeader { title: "DYNAMIC ISLAND SWIPE MODULES" }

                            // Group Card: Swipe Modules
                            Rectangle {
                                width: parent.width
                                height: swipeCol.height + 24
                                radius: 18
                                color: root.bgCard
                                border.width: 1
                                border.color: root.borderCard

                                Column {
                                    id: swipeCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 12
                                    spacing: 8

                                    Repeater {
                                        model: [
                                            { id: "albumcover", name: "Album Artwork Pill", desc: "Swipe to view currently playing album cover art", icon: "\uf001" },
                                            { id: "trackname", name: "Track Title & Artist", desc: "Swipe to view current song title and artist ticker", icon: "\uf028" },
                                            { id: "date", name: "Date & Calendar Preview", desc: "Swipe to view full date, day of week and month", icon: "\uf073" },
                                            { id: "time", name: "Clock Time Pill", desc: "Swipe to reveal large digital clock format", icon: "\uf017" },
                                            { id: "workspace", name: "Active Workspace Pill", desc: "Swipe to display current Hyprland workspace", icon: "\uf108" },
                                            { id: "battery", name: "Battery & Power Pill", desc: "Swipe to inspect battery percentage and charging state", icon: "\uf240" }
                                        ]

                                        delegate: Column {
                                            required property int index
                                            required property var modelData
                                            width: swipeCol.width
                                            spacing: 8

                                            SettingsSwitchRow {
                                                title: modelData.name
                                                desc: modelData.desc
                                                iconGlyph: modelData.icon
                                                checked: root.cfgSwipeItems.indexOf(modelData.id) >= 0
                                                onToggled: function(val) {
                                                    let nextItems = root.cfgSwipeItems.slice();
                                                    const idx = nextItems.indexOf(modelData.id);
                                                    if (val && idx < 0) {
                                                        nextItems.push(modelData.id);
                                                    } else if (!val && idx >= 0) {
                                                        nextItems.splice(idx, 1);
                                                    }
                                                    root.cfgSwipeItems = nextItems;
                                                    root.updateSetting("dynamicIslandLeftSwipeItems", nextItems);
                                                }
                                            }

                                            Rectangle {
                                                width: parent.width
                                                height: 1
                                                color: root.dividerColor
                                                visible: index < 5
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom spacing
                        Item { width: parent.width; height: 20 }
                    }
                }
            }
        }
    }

    // ==========================================
    // REUSABLE SUB-COMPONENTS
    // ==========================================

    // Component: Section Header with Accent Dot
    component SettingsSectionHeader: Row {
        property string title: ""
        spacing: 8

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: root.effectiveAccent
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: title
            font.family: root.textFontFamily
            font.pixelSize: 11
            font.weight: Font.Bold
            color: root.effectiveAccent
            font.letterSpacing: 0.8
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Component: Switch Row with Vibrant Accent Toggle
    component SettingsSwitchRow: Row {
        id: switchRowItem
        property string title: ""
        property string desc: ""
        property string iconGlyph: ""
        property bool checked: false
        signal toggled(bool nextVal)

        width: parent.width
        height: 52

        Row {
            anchors.left: parent.left
            anchors.right: toggleSwitch.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            // Leading Icon if provided
            Rectangle {
                width: 32
                height: 32
                radius: 10
                color: switchRowItem.checked ? root.accentSoft : Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: switchRowItem.checked ? root.accentBorder : root.borderCard
                visible: switchRowItem.iconGlyph !== ""
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on border.color { ColorAnimation { duration: 160 } }

                Text {
                    anchors.centerIn: parent
                    text: switchRowItem.iconGlyph
                    font.family: root.iconFontFamily
                    font.pixelSize: 14
                    color: switchRowItem.checked ? root.effectiveAccent : root.textSecondary
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - (switchRowItem.iconGlyph !== "" ? 44 : 0)
                spacing: 2

                Text {
                    text: switchRowItem.title
                    font.family: root.textFontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: root.textPrimary
                }

                Text {
                    text: switchRowItem.desc
                    font.family: root.textFontFamily
                    font.pixelSize: 11
                    color: root.textSecondary
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        // Animated iOS Switch Capsule
        Rectangle {
            id: toggleSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 48
            height: 26
            radius: 13
            color: switchRowItem.checked ? root.effectiveAccent : root.switchOffColor

            Behavior on color {
                ColorAnimation { duration: 180 }
            }

            // Sliding Knob with Spring Easing
            Rectangle {
                id: switchKnob
                width: 20
                height: 20
                radius: 10
                color: "#ffffff"
                y: 3
                x: switchRowItem.checked ? (toggleSwitch.width - width - 3) : 3

                Behavior on x {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }

                // Subtle inner shadow for 3D feel
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: StyleTokens.transparent
                    border.width: 1
                    border.color: "#18000000"
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: switchRowItem.toggled(!switchRowItem.checked)
            }
        }
    }

    // Component: Slider Row with Value Badge
    component SettingsSliderRow: Row {
        id: sliderRowItem
        property string title: ""
        property string desc: ""
        property real fromVal: 0
        property real toVal: 100
        property real step: 1
        property real currentVal: 0
        property string unitStr: "px"
        signal valMoved(real nextVal)

        width: parent.width
        height: 52

        Column {
            anchors.left: parent.left
            anchors.right: sliderControls.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: sliderRowItem.title
                font.family: root.textFontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: root.textPrimary
            }

            Text {
                text: sliderRowItem.desc
                font.family: root.textFontFamily
                font.pixelSize: 11
                color: root.textSecondary
                elide: Text.ElideRight
                width: parent.width
            }
        }

        // Slider Track + Value Badge
        Row {
            id: sliderControls
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            // Draggable Track
            Rectangle {
                id: trackArea
                width: 140
                height: 7
                radius: 3.5
                color: Qt.rgba(255, 255, 255, 0.1)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.05)
                anchors.verticalCenter: parent.verticalCenter

                readonly property real normVal: Math.max(0, Math.min(1, (sliderRowItem.currentVal - sliderRowItem.fromVal) / Math.max(0.001, (sliderRowItem.toVal - sliderRowItem.fromVal))))

                // Active Fill
                Rectangle {
                    height: parent.height
                    width: Math.max(4, trackArea.normVal * parent.width)
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.effectiveAccent }
                        GradientStop { position: 1.0; color: Qt.lighter(root.effectiveAccent, 1.2) }
                    }
                }

                // Knob
                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: "#ffffff"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.2)
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(trackArea.width - width, trackArea.normVal * trackArea.width - width / 2))

                    scale: sliderMouse.pressed ? 1.18 : (sliderMouse.containsMouse ? 1.08 : 1.0)
                    Behavior on scale {
                        NumberAnimation { duration: 120 }
                    }
                }

                MouseArea {
                    id: sliderMouse
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updateFromPos(mousePos) {
                        const clampedX = Math.max(0, Math.min(trackArea.width, mousePos.x + 8));
                        const progress = clampedX / trackArea.width;
                        let target = sliderRowItem.fromVal + progress * (sliderRowItem.toVal - sliderRowItem.fromVal);
                        if (sliderRowItem.step > 0) {
                            target = Math.round(target / sliderRowItem.step) * sliderRowItem.step;
                        }
                        sliderRowItem.valMoved(target);
                    }

                    onPositionChanged: function(mouse) {
                        if (pressed) updateFromPos(mouse);
                    }
                    onPressed: function(mouse) {
                        updateFromPos(mouse);
                    }
                }
            }

            // Value Badge
            Rectangle {
                width: 60
                height: 26
                radius: 13
                color: sliderMouse.pressed ? root.accentSoft : Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: sliderMouse.pressed ? root.accentBorder : root.borderCard
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: (sliderRowItem.step < 1 ? sliderRowItem.currentVal.toFixed(1) : Math.round(sliderRowItem.currentVal)) + " " + sliderRowItem.unitStr
                    font.family: root.textFontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: sliderMouse.pressed ? root.effectiveAccent : "#e2e6f0"
                }
            }
        }
    }
}
