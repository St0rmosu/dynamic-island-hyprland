import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.SystemTray
import IslandBackend
import "../connectivity"
import "../common/BluetoothFormatting.js" as BluetoothFormatting

Item {
    id: controlCenter

    signal connectivityPanelRequested(string kind, bool open)
    signal focusModeChanged(bool enabled)
    signal nightLightModeChanged(bool enabled)
    signal requestNotification(string appName, string summary, string body)
    signal settingsRequested()
    signal clipboardRequested()
    signal closeRequested()

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")
    readonly property var userConfig: UserConfig
    property var notificationModel: null
    property var userConfigData: null

    FileView {
        id: localConfigFile
        path: controlCenter.homeDir + "/.config/dynamic-island/userconfig.json"
        watchChanges: true
        property var parsedData: ({})
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                parsedData = JSON.parse(text());
                if (userConfig && typeof userConfig.reload === "function") {
                    userConfig.reload();
                }
            } catch(e) {}
        }
    }

    function cfgValue(key, fallback) {
        if (userConfigData && userConfigData[key] !== undefined)
            return userConfigData[key];
        if (localConfigFile.parsedData && localConfigFile.parsedData[key] !== undefined)
            return localConfigFile.parsedData[key];
        if (userConfig && userConfig[key] !== undefined)
            return userConfig[key];
        return fallback;
    }

    function getModuleConfig(id) {
        const layout = cfgValue("controlCenterCanvasLayout", null);
        if (Array.isArray(layout)) {
            for (let i = 0; i < layout.length; i++) {
                if (layout[i].id === id) return layout[i];
            }
        }
        return null;
    }

    readonly property bool cfgShowWifi: {
        const c = getModuleConfig("wifi");
        return c !== null ? c.active : cfgValue("showWifiCard", true);
    }
    readonly property bool cfgShowBluetooth: {
        const c = getModuleConfig("bluetooth");
        return c !== null ? c.active : cfgValue("showBluetoothCard", true);
    }
    readonly property bool cfgShowConnectivity: cfgShowWifi || cfgShowBluetooth

    readonly property bool cfgShowBarraDesktop: {
        const c = getModuleConfig("quickactions");
        return c !== null ? c.active : cfgValue("showBarraDesktopCard", true);
    }
    readonly property bool cfgShowClipboard: {
        const c = getModuleConfig("quickactions");
        return c !== null ? c.active : cfgValue("showClipboardQuickAccess", true);
    }
    readonly property bool cfgShowQuickActions: cfgShowBarraDesktop || cfgShowClipboard

    readonly property bool cfgShowTlpBattery: {
        const c = getModuleConfig("battery");
        return c !== null ? c.active : cfgValue("showTlpBatteryMode", false);
    }
    readonly property bool cfgShowNightFocus: {
        const c = getModuleConfig("toggles");
        return c !== null ? c.active : cfgValue("showNightFocusToggles", false);
    }
    readonly property bool cfgShowBatteryDrawer: cfgShowTlpBattery || cfgShowNightFocus

    readonly property bool cfgShowSliders: {
        const c1 = getModuleConfig("brightness");
        const c2 = getModuleConfig("volume");
        if (c1 !== null || c2 !== null) {
            return (c1 ? c1.active : false) || (c2 ? c2.active : false);
        }
        return cfgValue("showDisplaySoundSliders", true);
    }
    readonly property bool isBrightnessFullSpan: {
        const c = getModuleConfig("brightness");
        return c !== null ? (c.colSpan === 4) : false;
    }
    readonly property bool isVolumeFullSpan: {
        const c = getModuleConfig("volume");
        return c !== null ? (c.colSpan === 4) : false;
    }

    readonly property bool cfgShowNotifications: {
        const c = getModuleConfig("notifications");
        return c !== null ? c.active : cfgValue("controlCenterShowNotifications", true);
    }
    readonly property string cfgOrientation: cfgValue("controlCenterOrientation", "vertical")
    readonly property bool isHorizontal: cfgOrientation === "horizontal"

    readonly property real controlCenterPreferredWidth: {
        const customW = Number(cfgValue("controlCenterWidth", 0));
        if (isHorizontal) {
            return (customW >= 420 && customW <= 800) ? customW : 540;
        }
        if (customW >= 340 && customW <= 720) return customW;
        return 380;
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

    readonly property var activeCanvasLayout: {
        let layout = null;
        if (userConfigData && userConfigData.controlCenterCanvasLayout !== undefined) {
            layout = userConfigData.controlCenterCanvasLayout;
        } else if (localConfigFile.parsedData && localConfigFile.parsedData.controlCenterCanvasLayout !== undefined) {
            layout = localConfigFile.parsedData.controlCenterCanvasLayout;
        } else if (userConfig && userConfig.controlCenterCanvasLayout !== undefined) {
            layout = userConfig.controlCenterCanvasLayout;
        }

        if (Array.isArray(layout) && layout.length > 0) {
            let res = [];
            // Header is unconditionally pinned at the very top (index 0), full width, 32px
            res.push({
                id: "header",
                col: 0,
                row: -1,
                colSpan: 4,
                rowSpan: 1,
                height: 32,
                active: true
            });

            for (let i = 0; i < layout.length; i++) {
                let m = layout[i];
                if (!m || !m.id || m.id === "header") continue;
                let def = getDefaultPos(m.id);
                let span = Number(m.colSpan);
                if (isNaN(span) || span < 1) span = def.colSpan;
                if (span > 4) span = 4;
                let rSpan = Number(m.rowSpan);
                if (isNaN(rSpan) || rSpan < 1) rSpan = (m.height >= 140 ? 2 : def.rowSpan);
                if (rSpan > 3) rSpan = 3;
                let c = Number(m.col);
                if (isNaN(c) || c < 0) c = def.col;
                if (c + span > 4) c = Math.max(0, 4 - span);
                let r = Number(m.row);
                if (isNaN(r) || r < 0) r = def.row;

                let isAct = true;
                if (m.active !== undefined) {
                    isAct = Boolean(m.active);
                } else {
                    if (m.id === "wifi" && cfgValue("showWifiCard", null) !== null) isAct = Boolean(cfgValue("showWifiCard", true));
                    else if (m.id === "bluetooth" && cfgValue("showBluetoothCard", null) !== null) isAct = Boolean(cfgValue("showBluetoothCard", true));
                    else if (m.id === "brightness" && cfgValue("showDisplaySoundSliders", null) !== null) isAct = Boolean(cfgValue("showDisplaySoundSliders", true));
                    else if (m.id === "volume" && cfgValue("showDisplaySoundSliders", null) !== null) isAct = Boolean(cfgValue("showDisplaySoundSliders", true));
                    else if (m.id === "notifications" && cfgValue("controlCenterShowNotifications", null) !== null) isAct = Boolean(cfgValue("controlCenterShowNotifications", true));
                    else if (m.id === "battery" && cfgValue("showTlpBatteryMode", null) !== null) isAct = Boolean(cfgValue("showTlpBatteryMode", true));
                    else if (m.id === "toggles" && cfgValue("showNightFocusToggles", null) !== null) isAct = Boolean(cfgValue("showNightFocusToggles", true));
                    else if (m.id === "quickactions") {
                        let b1 = cfgValue("showBarraDesktopCard", null);
                        let b2 = cfgValue("showClipboardQuickAccess", null);
                        if (b1 !== null || b2 !== null) {
                            isAct = Boolean((b1 !== null ? b1 : false) || (b2 !== null ? b2 : false));
                        }
                    }
                }

                res.push({
                    id: m.id,
                    col: c,
                    row: r,
                    colSpan: span,
                    rowSpan: rSpan,
                    height: rSpan * 80,
                    active: isAct
                });
            }

            const allStandard = ["wifi", "bluetooth", "brightness", "volume", "toggles", "notifications", "battery", "quickactions"];
            for (let k = 0; k < allStandard.length; k++) {
                let modId = allStandard[k];
                let alreadyInRes = false;
                for (let rIdx = 0; rIdx < res.length; rIdx++) {
                    if (res[rIdx].id === modId) { alreadyInRes = true; break; }
                }
                if (!alreadyInRes) {
                    let def = getDefaultPos(modId);
                    res.push({
                        id: modId,
                        col: def.col,
                        row: def.row,
                        colSpan: def.colSpan,
                        rowSpan: def.rowSpan,
                        height: def.rowSpan * 80,
                        active: false
                    });
                }
            }
            return res;
        }

        return [
            { id: "header", col: 0, row: -1, colSpan: 4, rowSpan: 1, height: 32, active: true },
            { id: "wifi", col: 0, row: 0, colSpan: 2, rowSpan: 1, height: 80, active: cfgValue("showWifiCard", true) },
            { id: "bluetooth", col: 0, row: 1, colSpan: 2, rowSpan: 1, height: 80, active: cfgValue("showBluetoothCard", true) },
            { id: "brightness", col: 2, row: 0, colSpan: 1, rowSpan: 2, height: 160, active: cfgValue("showDisplaySoundSliders", true) },
            { id: "volume", col: 3, row: 0, colSpan: 1, rowSpan: 2, height: 160, active: cfgValue("showDisplaySoundSliders", true) },
            { id: "notifications", col: 0, row: 2, colSpan: 4, rowSpan: 2, height: 160, active: cfgValue("controlCenterShowNotifications", true) },
            { id: "toggles", col: 0, row: 4, colSpan: 2, rowSpan: 1, height: 80, active: cfgValue("showNightFocusToggles", false) },
            { id: "battery", col: 0, row: 5, colSpan: 2, rowSpan: 1, height: 80, active: cfgValue("showTlpBatteryMode", false) },
            { id: "quickactions", col: 2, row: 4, colSpan: 2, rowSpan: 1, height: 80, active: cfgValue("showBarraDesktopCard", false) || cfgValue("showClipboardQuickAccess", false) }
        ];
    }

    onActiveCanvasLayoutChanged: {
        if (typeof modulesRepeater !== "undefined" && modulesRepeater) {
            modulesRepeater.model = 0;
            modulesRepeater.model = controlCenter.activeCanvasLayout;
        }
    }

    readonly property real controlCenterPreferredHeight: {
        const layout = controlCenter.activeCanvasLayout;
        if (!Array.isArray(layout) || layout.length === 0) return 420;

        let maxRow = 0;
        let extraNotificationH = 0;
        for (let i = 0; i < layout.length; i++) {
            const item = layout[i];
            if (!item.active || item.id === "header") continue;
            let r = (item.row !== undefined && item.row >= 0) ? item.row : 0;
            let rSpan = Math.max(1, Math.min(3, Number(item.rowSpan) || (item.height >= 140 ? 2 : 1)));
            if (r + rSpan > maxRow) maxRow = r + rSpan;

            if (item.id === "notifications" && controlCenter.notificationModel && controlCenter.notificationModel.count > 0) {
                let baseH = rSpan * 80 + (rSpan - 1) * 10;
                let neededH = Math.min(260, 38 + Math.min(3, controlCenter.notificationModel.count) * 58 + 10);
                if (neededH > baseH) {
                    extraNotificationH = Math.max(extraNotificationH, neededH - baseH);
                }
            }
        }
        maxRow = Math.max(2, maxRow);
        const spacing = 10;
        const cellH = 80;
        const gridH = maxRow * cellH + (maxRow - 1) * spacing;
        const headerH = 32;
        const bottomPadding = 34;
        const padding = 12 + 10 + bottomPadding;
        return Math.max(160, headerH + gridH + padding + extraNotificationH);
    }

    property bool showCondition: false
    property string iconFontFamily: userConfig.iconFontFamily
    property string textFontFamily: userConfig.textFontFamily
    property string heroFontFamily: userConfig.heroFontFamily
    // ... rest of properties ...

    scale: showCondition ? 1.0 : 0.12
    transformOrigin: Item.Top

    Behavior on scale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutQuint
        }
    }
    property string currentTime: "00:00"
    property string currentDateLabel: ""
    property int batteryCapacity: 0
    property bool isCharging: false
    property real volumeLevel: -1
    property real brightnessLevel: -1
    property int currentWorkspace: 1
    property string currentTrack: ""
    property string currentArtist: ""

    property real localVolume: 0.5
    property real localBrightness: 0.5
    property real displayedVolume: 0.5
    property real displayedBrightness: 0.5
    property real pendingVolume: 0.5
    property real pendingBrightness: 0.5
    property real lastAppliedVolume: -1
    property real lastAppliedBrightness: -1
    property bool brightnessSetterRunning: false
    property bool volumeSetterRunning: false
    property bool wifiPanelOpen: false
    property bool bluetoothPanelOpen: false
    property bool powerPanelOpen: false
    property bool powerViewActive: false
    property string activeDetailModule: ""
    readonly property bool anyConnectivitySubViewActive: wifiPanelOpen || bluetoothPanelOpen || (activeDetailModule !== "")
    property bool batteryDrawerOpen: false
    property bool batteryDrawerDragging: false
    property real batteryDrawerProgress: 0
    property bool batteryDrawerSettling: false
    readonly property bool batteryDrawerMoving: batteryDrawerDragging
        || batteryDrawerSettling
        || batteryDrawerProgressAnimation.running
    property bool batteryModeBusy: false
    property bool batteryModeStateRunning: false
    property bool batteryModeSetterRunning: false
    property bool batteryModeSliderDragging: false
    property bool batteryTlpAvailable: false
    property bool batteryTlpChecked: false
    property int batteryModeIndex: 1
    property int batteryModeAppliedIndex: 1
    property int batteryModePendingIndex: 1
    property real batteryModeDragOffset: 0
    property string batteryModeInfoMessage: ""
    property string batteryModeError: ""
    property string batteryModeLastCommandOutput: ""
    property int batteryModeRefreshPollsRemaining: 0
    property bool nightLightEnabled: false
    property bool nightLightBusy: false
    property int nightLightTemperature: 4500
    readonly property bool hyprlandNightLight: CompositorBackend.compositor === "hyprland"
    property bool focusEnabled: false
    property bool focusBusy: false

    property string wifiLocalInfoMessage: ""
    property string wifiLocalError: ""
    property string wifiPendingPasswordSsid: ""
    property string wifiPendingPasswordValue: ""

    property string bluetoothInfoMessage: ""
    property string bluetoothError: ""
    property string bluetoothPairAndConnectPath: ""
    property string bluetoothPendingSecretValue: ""
    readonly property var wifiController: WifiController
    readonly property var bluetoothPairingAgent: BluetoothPairingAgent
    readonly property var wifiNetworks: wifiController ? wifiController.networks : null

    readonly property real sliderKnobSize: 24
    readonly property color panelColor: StyleTokens.panel
    readonly property color moduleColor: StyleTokens.module
    readonly property color moduleHover: StyleTokens.moduleHover
    readonly property color trackColor: StyleTokens.track
    readonly property color textPrimary: StyleTokens.textPrimary
    readonly property color textSecondary: StyleTokens.textSecondary
    property color accentColor: StyleTokens.accent
    readonly property color cardAccent: accentColor
    readonly property color cardAccentPressed: Qt.darker(accentColor, 1.25)
    readonly property color cardFillActive: StyleTokens.cardFillActive
    readonly property color cardFillHover: StyleTokens.cardFillHover
    readonly property color buttonFill: StyleTokens.buttonFill
    readonly property color buttonFillHover: StyleTokens.buttonFillHover
    readonly property color buttonFillPressed: StyleTokens.buttonFillPressed
    readonly property string wifiGlyph: ""
    readonly property string bluetoothGlyph: ""
    readonly property string chargingIconGlyph: "\uf0e7"
    readonly property string brightnessIconGlyph: displayedBrightness < 0.3 ? "\u{F00DE}" : (displayedBrightness < 0.7 ? "\u{F00DF}" : "\u{F00E0}")
    readonly property string volumeIconGlyph: displayedVolume <= 0.01 ? "\u{F0581}" : (displayedVolume < 0.5 ? "\u{F057F}" : "\u{F057E}")
    readonly property string nightLightGlyph: "\uf186"
    readonly property var batteryModeGlyphs: ["", "", ""]
    readonly property real batteryDrawerHandleHeight: 20
    readonly property real batteryDrawerContentGap: 8
    readonly property real batteryModeCardHeight: 80
    readonly property real roundToggleButtonSize: 58
    readonly property real roundToggleButtonGap: 18
    readonly property real controlCenterExtraHeight: controlCenterPreferredHeight - 380
    readonly property real controlCenterMaximumExtraHeight: 380
    readonly property bool bluetoothAvailable: !!bluetoothAdapter
    readonly property var bluetoothAdapter: Bluetooth.defaultAdapter
    readonly property var bluetoothDeviceValues: bluetoothAdapter ? bluetoothAdapter.devices.values : []
    readonly property bool wifiSupported: wifiController ? wifiController.supported : false
    readonly property bool wifiReadOnly: wifiController ? wifiController.readOnly : true
    readonly property bool wifiAvailable: wifiController ? wifiController.available : false
    readonly property bool wifiEnabled: wifiController ? wifiController.enabled : false
    readonly property bool wifiBusy: wifiController ? wifiController.busy : false
    readonly property bool wifiListRunning: wifiController ? wifiController.scanning : false
    readonly property string wifiCurrentSsid: wifiController ? wifiController.currentSsid : ""
    readonly property string wifiInfoMessage: wifiLocalInfoMessage.length > 0
        ? wifiLocalInfoMessage
        : (wifiController ? wifiController.infoMessage : "")
    readonly property string wifiError: wifiLocalError.length > 0
        ? wifiLocalError
        : (wifiController ? wifiController.errorMessage : "")
    readonly property string wifiUnsupportedReason: wifiController ? wifiController.unsupportedReason : ""
    readonly property string wifiAvailabilityMessage: {
        if (wifiUnsupportedReason.length > 0) return wifiUnsupportedReason;
        if (wifiSupported && !wifiAvailable) return "No Wi-Fi device is available.";
        return "";
    }
    readonly property bool bluetoothEnabled: bluetoothAdapter ? bluetoothAdapter.enabled : false
    readonly property bool bluetoothBusy: bluetoothAdapter
        ? bluetoothAdapter.state === BluetoothAdapterState.Enabling
            || bluetoothAdapter.state === BluetoothAdapterState.Disabling
        : false
    readonly property bool bluetoothPairingActive: bluetoothPairingAgent ? bluetoothPairingAgent.requestActive : false
    readonly property bool bluetoothPairingRequiresInput: bluetoothPairingAgent ? bluetoothPairingAgent.requestRequiresInput : false
    readonly property bool bluetoothPairingNumericInput: bluetoothPairingAgent ? bluetoothPairingAgent.requestNumericInput : false
    readonly property bool bluetoothPairingRequiresConfirmation: bluetoothPairingAgent ? bluetoothPairingAgent.requestRequiresConfirmation : false
    readonly property string bluetoothPairingTitle: bluetoothPairingAgent ? bluetoothPairingAgent.promptTitle : ""
    readonly property string bluetoothPairingMessage: bluetoothPairingAgent ? bluetoothPairingAgent.promptMessage : ""
    readonly property string bluetoothPairingDisplayedCode: bluetoothPairingAgent ? bluetoothPairingAgent.displayedCode : ""
    readonly property bool hasConnectivityPrompt: wifiPendingPasswordSsid.length > 0 || bluetoothPairingActive
    readonly property bool anyConnectivityPanelOpen: wifiPanelOpen || bluetoothPanelOpen || (activeDetailModule !== "")
    readonly property string wifiStatusText: wifiController ? wifiController.statusText : "Unavailable"
    readonly property string bluetoothStatusText: buildBluetoothStatusText()
    readonly property string bluetoothAvailabilityMessage: bluetoothAvailable ? "" : "No Bluetooth adapter is available."
    readonly property string batteryModeStatusText: buildBatteryModeStatusText()
    readonly property bool tlpControlsEnabled: trimString(userConfig.tlpPermissionMode) !== "skip"

    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }

    function trimString(value) {
        if (value === undefined || value === null) return "";
        return String(value).trim();
    }

    function batteryModeLabel(index) {
        if (index <= 0) return "Power Saver";
        if (index >= 2) return "Performance";
        return "Balanced";
    }

    function batteryModeCommand(index) {
        if (index <= 0) return "power-saver";
        if (index >= 2) return "performance";
        return "balanced";
    }

    function batteryModeIndexForCommand(command) {
        const normalized = trimString(command).toLowerCase();
        if (normalized === "power-saver" || normalized === "bat") return 0;
        if (normalized === "performance" || normalized === "ac") return 2;
        return 1;
    }

    function setBatteryModeVisualIndex(index, animate) {
        const nextIndex = Math.max(0, Math.min(2, index));
        batteryModeIndex = nextIndex;
    }

    function setBatteryDrawerOpen(open) {
        const nextOpen = !!open;
        batteryDrawerOpen = nextOpen;
        batteryDrawerSettling = true;
        batteryDrawerProgress = nextOpen ? 1 : 0;
        batteryDrawerSettleTimer.restart();
        if (nextOpen && tlpControlsEnabled && !batteryTlpChecked)
            refreshBatteryModeState();
    }

    function toggleBatteryDrawer() {
        setBatteryDrawerOpen(!batteryDrawerOpen);
    }

    function refreshBatteryModeState() {
        if (batteryModeStateRunning)
            return;

        batteryModeStateRunning = true;
        SystemServices.requestTlpState();
    }

    function applyBatteryModeState(available, profile, output, errorString) {
        batteryModeStateRunning = false;
        batteryTlpChecked = true;
        batteryTlpAvailable = !!available;

        if (!batteryTlpAvailable) {
            batteryModeBusy = false;
            batteryModeError = trimString(errorString).length > 0 ? errorString : "TLP is not installed.";
            setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
            return;
        }

        if (batteryModeError === "TLP is not installed.")
            batteryModeError = "";

        let resolvedProfile = trimString(profile);
        if (resolvedProfile.length === 0) {
            const profileMatch = String(output || "").match(/TLP profile\s*=\s*([a-z-]+)/i);
            if (profileMatch)
                resolvedProfile = profileMatch[1];
        }

        if (resolvedProfile.length > 0) {
            const nextIndex = batteryModeIndexForCommand(resolvedProfile);
            batteryModeAppliedIndex = nextIndex;
            setBatteryModeVisualIndex(nextIndex, true);

            if (batteryModeRefreshPollsRemaining > 0 && nextIndex === batteryModePendingIndex) {
                batteryModeRefreshPollsRemaining = 0;
                batteryModeRefreshTimer.stop();
                batteryModeError = "";
                batteryModeInfoMessage = batteryModeLabel(nextIndex) + " active.";
            }
        }
    }

    function buildBatteryModeStatusText() {
        if (batteryModeBusy) return "Applying " + batteryModeLabel(batteryModePendingIndex);
        if (trimString(userConfig.tlpPermissionMode) === "skip") return "TLP disabled";
        if (!batteryTlpChecked) return "Checking TLP";
        if (!batteryTlpAvailable) return "TLP is not installed";
        return batteryModeLabel(batteryModeIndex);
    }

    function rollbackBatteryMode(message) {
        batteryModeBusy = false;
        batteryModeError = message;
        batteryModeInfoMessage = "";
        batteryModeDragOffset = 0;
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
    }

    function classifyBatteryModeFailure(exitCode) {
        const details = trimString(batteryModeLastCommandOutput).toLowerCase();

        if (details.indexOf("sorry, try again") >= 0 || details.indexOf("incorrect password attempt") >= 0)
            return "The configured sudo password did not work.";
        if (details.indexOf("pkexec") >= 0 && details.indexOf("not installed") >= 0)
            return "Install pkexec or set tlpSudoPassword in userconfig.json.";
        if (details.indexOf("sudo is not installed") >= 0)
            return "sudo is not installed.";
        if (details.indexOf("sudo:") >= 0 && details.indexOf("password") >= 0) {
            if (trimString(userConfig.tlpPermissionMode) === "ask")
                return "Install pkexec or set tlpSudoPassword in userconfig.json.";
            return "sudo needs a password; set tlpSudoPassword in userconfig.json.";
        }
        if (details.indexOf("sudo:") >= 0 && details.indexOf("no new privileges") >= 0)
            return "sudo is blocked by the current process security flags.";
        if (details.indexOf("sudo:") >= 0 && details.indexOf("a terminal is required") >= 0)
            return "sudo needs a real terminal, but the panel could not open one.";
        if (details.indexOf("missing root privilege") >= 0)
            return "TLP needs admin permission.";
        if (details.indexOf("command not found") >= 0 || details.indexOf("not found") >= 0) {
            if (details.indexOf("tlp") >= 0)
                return "TLP is not installed.";
        }

        if (exitCode === 127)
            return "TLP is not installed.";
        if (exitCode === 126)
            return "Install pkexec or set tlpSudoPassword in userconfig.json.";
        return "TLP could not apply that mode.";
    }

    function queueBatteryModeStateRefresh(polls) {
        batteryModeRefreshPollsRemaining = Math.max(0, polls);
        if (batteryModeRefreshPollsRemaining > 0)
            batteryModeRefreshTimer.restart();
        else
            batteryModeRefreshTimer.stop();
    }

    function selectBatteryMode(index) {
        if (batteryModeBusy) {
            if (batteryModeSetterRunning)
                SystemServices.cancelTlpApply();
            batteryModeBusy = false;
            batteryModeSetterRunning = false;
        }

        queueBatteryModeStateRefresh(0);

        const nextIndex = Math.max(0, Math.min(2, index));

        if (trimString(userConfig.tlpPermissionMode) === "skip") {
            rollbackBatteryMode("TLP mode switching is disabled in userconfig.json.");
            return;
        }

        if (!batteryTlpChecked) {
            refreshBatteryModeState();
            rollbackBatteryMode("Checking TLP. Try again in a moment.");
            return;
        }

        if (!batteryTlpAvailable) {
            rollbackBatteryMode("TLP is not installed.");
            return;
        }

        if (nextIndex === batteryModeAppliedIndex) {
            batteryModeError = "";
            batteryModeInfoMessage = batteryModeLabel(nextIndex) + " active.";
            setBatteryModeVisualIndex(nextIndex, true);
            return;
        }

        batteryModePendingIndex = nextIndex;
        batteryModeBusy = true;
        batteryModeSetterRunning = true;
        batteryModeError = "";
        batteryModeInfoMessage = "Applying " + batteryModeLabel(nextIndex) + "...";
        setBatteryModeVisualIndex(nextIndex, true);
        batteryModeLastCommandOutput = "";
        const permissionMode = trimString(userConfig.tlpPermissionMode);
        const sudoPassword = permissionMode === "password"
            ? trimString(userConfig.tlpSudoPassword)
            : "";
        SystemServices.setTlpMode(batteryModeCommand(nextIndex), sudoPassword, permissionMode === "ask");
    }

    function finishBatteryModeApply(success, exitCode, output, errorString) {
        batteryModeSetterRunning = false;
        batteryModeBusy = false;
        batteryModeLastCommandOutput = trimString(output);
        if (batteryModeLastCommandOutput.length === 0)
            batteryModeLastCommandOutput = trimString(errorString);

        if (!success) {
            rollbackBatteryMode(classifyBatteryModeFailure(exitCode));
            return;
        }

        batteryModeAppliedIndex = batteryModePendingIndex;
        batteryModeError = "";
        batteryModeInfoMessage = batteryModeLabel(batteryModeAppliedIndex) + " active.";
        setBatteryModeVisualIndex(batteryModeAppliedIndex, true);
        refreshBatteryModeState();
    }

    function toggleNightLight() {
        if (nightLightBusy)
            return;

        nightLightBusy = true;
        if (nightLightEnabled) {
            nightLightDisableProcess.running = true;
        } else {
            nightLightEnableProcess.running = true;
        }
    }

    function toggleFocus() {
        if (focusBusy)
            return;

        focusBusy = true;
        if (focusEnabled)
            focusDisableProcess.running = true;
        else
            focusEnableProcess.running = true;
    }

    function clearWifiPrompt() {
        wifiPendingPasswordSsid = "";
        wifiPendingPasswordValue = "";
        wifiLocalInfoMessage = "";
        wifiLocalError = "";
    }

    function clearWifiMessages() {
        wifiLocalInfoMessage = "";
        wifiLocalError = "";
        if (wifiController)
            wifiController.clearMessages();
    }

    function clearBluetoothMessages() {
        bluetoothInfoMessage = "";
        bluetoothError = "";
    }

    function submitBluetoothPairingSecret() {
        if (!bluetoothPairingAgent || !bluetoothPairingRequiresInput)
            return;

        const secret = trimString(bluetoothPendingSecretValue);
        if (!secret) {
            bluetoothError = bluetoothPairingNumericInput
                ? "Enter the 6-digit passkey first."
                : "Enter the PIN first.";
            return;
        }

        if (bluetoothPairingNumericInput && !/^\d{1,6}$/.test(secret)) {
            bluetoothError = "Passkeys must be 1 to 6 digits.";
            return;
        }

        bluetoothError = "";
        bluetoothPairingAgent.submitSecret(secret);
        bluetoothPendingSecretValue = "";
    }

    function confirmBluetoothPairing() {
        if (!bluetoothPairingAgent)
            return;

        bluetoothError = "";
        bluetoothPairingAgent.confirmRequest();
    }

    function cancelBluetoothPairing() {
        if (!bluetoothPairingAgent)
            return;

        bluetoothPairingAgent.cancelRequest();
        bluetoothPendingSecretValue = "";
    }

    function isConnectivityPanelOpen(kind) {
        if (kind === "wifi") return wifiPanelOpen;
        if (kind === "bluetooth") return bluetoothPanelOpen;
        if (kind === "power") return powerPanelOpen;
        return false;
    }

    function setConnectivityPanelOpen(kind, open, emitSignal) {
        if (emitSignal === undefined)
            emitSignal = true;

        const nextOpen = !!open;
        let changed = false;

        if (kind === "wifi") {
            changed = wifiPanelOpen !== nextOpen;
            wifiPanelOpen = nextOpen;
            if (nextOpen)
                bluetoothPanelOpen = false;

            if (nextOpen) {
                if (showCondition) {
                    requestWifiStateRefresh();
                    if (wifiSupported && wifiEnabled)
                        requestWifiListRefresh(true);
                }
            } else {
                clearWifiPrompt();
                clearWifiMessages();
            }
        } else if (kind === "bluetooth") {
            changed = bluetoothPanelOpen !== nextOpen;
            bluetoothPanelOpen = nextOpen;
            if (nextOpen)
                wifiPanelOpen = false;

            if (nextOpen) {
                if (bluetoothAdapter && bluetoothEnabled && !bluetoothAdapter.discovering) {
                    bluetoothAdapter.discovering = true;
                    bluetoothInfoMessage = "Scanning for nearby devices...";
                    bluetoothScanStopTimer.restart();
                }
            } else {
                if (bluetoothPairingActive)
                    cancelBluetoothPairing();
                if (bluetoothAdapter && bluetoothAdapter.discovering)
                    bluetoothAdapter.discovering = false;
                bluetoothScanStopTimer.stop();
                bluetoothConnectAfterPairTimer.stop();
                bluetoothConnectionTimeoutTimer.stop();
                bluetoothPairAndConnectPath = "";
                bluetoothPendingSecretValue = "";
                clearBluetoothMessages();
            }
        } 
        else if (kind === "power") {
            changed = powerPanelOpen !== nextOpen;
            powerPanelOpen = nextOpen;
        }
        else {
            return;
        }

        if (changed && emitSignal)
            connectivityPanelRequested(kind, nextOpen);
    }

    function toggleConnectivityOverlay(kind) {
        setConnectivityPanelOpen(kind, !isConnectivityPanelOpen(kind));
    }

    function triggerShutdown() {
        if (!shutdownProcess.running)
            shutdownProcess.running = true;
    }
    function triggerRestart() {
        if (!restartProcess.running)
            restartProcess.running = true;
    }
    function triggerSleep() {
        if (!sleepProcess.running)
            sleepProcess.running = true;
    }
    function triggerLock() {
        if (!lockProcess.running)
            lockProcess.running = true;
    }

    function closeConnectivityPanels(emitSignals) {
        if (emitSignals === undefined)
            emitSignals = true;

        setConnectivityPanelOpen("wifi", false, emitSignals);
        setConnectivityPanelOpen("bluetooth", false, emitSignals);
        activeDetailModule = "";
        clearWifiPrompt();
        clearWifiMessages();
        clearBluetoothMessages();
    }

    function openModuleDetail(kind) {
        if (kind === "wifi") {
            setConnectivityPanelOpen("wifi", true);
            return;
        }
        if (kind === "bluetooth") {
            setConnectivityPanelOpen("bluetooth", true);
            return;
        }
        activeDetailModule = kind;
    }

    function requestWifiStateRefresh() {
        if (!showCondition || !wifiController) return;
        wifiController.refreshState();
    }

    function requestWifiListRefresh(rescan) {
        if (!showCondition || !wifiController) return;
        if (!wifiSupported || !wifiAvailable || !wifiEnabled) return;
        wifiController.refreshNetworks(!!rescan);
    }

    function toggleWifiEnabled() {
        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.setEnabled(!wifiEnabled);
    }

    function disconnectWifi() {
        if (!wifiSupported || !wifiAvailable) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "No Wi-Fi device is available.";
            return;
        }

        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.disconnectCurrent();
    }

    function connectWifiNetwork(network) {
        if (!network) return;
        if (!wifiSupported) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "Wi-Fi control is unavailable.";
            return;
        }
        if (!wifiAvailable) {
            wifiLocalError = wifiAvailabilityMessage.length > 0 ? wifiAvailabilityMessage : "No Wi-Fi device is available.";
            return;
        }
        if (!wifiEnabled) {
            wifiLocalError = "Turn on Wi-Fi first.";
            return;
        }
        if (network.connected) return;

        const ssid = trimString(network.ssid);
        const networkType = trimString(network.type);
        const secure = !!network.secure;
        const savedConnection = !!network.savedConnection;

        if (!ssid) {
            wifiLocalError = "Hidden networks are not supported in this panel yet.";
            return;
        }

        if (!savedConnection && networkType === "wep") {
            wifiLocalError = "WEP networks aren't supported by this panel.";
            return;
        }

        if (!savedConnection && networkType === "8021x") {
            wifiLocalError = "802.1X networks need to be provisioned first.";
            return;
        }

        clearWifiPrompt();
        clearWifiMessages();

        if (savedConnection) {
            if (wifiController)
                wifiController.connectToNetwork(ssid);
            return;
        }

        if (!secure) {
            if (wifiController)
                wifiController.connectToNetwork(ssid);
            return;
        }

        wifiPendingPasswordSsid = ssid;
        wifiPendingPasswordValue = "";
        wifiLocalInfoMessage = "Enter the password for " + ssid + ".";
    }

    function submitWifiPassword() {
        const ssid = trimString(wifiPendingPasswordSsid);
        if (!ssid) return;

        if (trimString(wifiPendingPasswordValue).length === 0) {
            wifiLocalError = "Enter a password first.";
            return;
        }

        const password = wifiPendingPasswordValue;
        clearWifiPrompt();
        clearWifiMessages();
        if (wifiController)
            wifiController.connectToNetwork(ssid, password);
    }

    function applyBrightnessSnapshot(value) {
        if (value >= 0)
            syncBrightnessFromLevel(value);
    }

    function applyVolumeSnapshot(value) {
        if (value >= 0)
            syncVolumeFromLevel(value);
    }

    function flushBrightness(force) {
        const nextValue = clamp01(pendingBrightness);
        if (!force && Math.abs(nextValue - lastAppliedBrightness) < 0.01) return;
        if (brightnessSetterRunning) {
            brightnessApplyTimer.restart();
            return;
        }

        lastAppliedBrightness = nextValue;
        brightnessSetterRunning = true;
        SystemServices.setBrightness(nextValue);
    }

    function queueBrightness(value) {
        localBrightness = clamp01(value);
        displayedBrightness = localBrightness;
        pendingBrightness = localBrightness;
        brightnessApplyTimer.restart();
    }

    function flushVolume(force) {
        const nextValue = clamp01(pendingVolume);
        if (!force && Math.abs(nextValue - lastAppliedVolume) < 0.01) return;
        if (volumeSetterRunning) {
            volumeApplyTimer.restart();
            return;
        }

        lastAppliedVolume = nextValue;
        volumeSetterRunning = true;
        SystemServices.setVolume(nextValue);
    }

    function queueVolume(value) {
        localVolume = clamp01(value);
        displayedVolume = localVolume;
        pendingVolume = localVolume;
        volumeApplyTimer.restart();
    }

    function syncBrightnessFromLevel(level) {
        if (level < 0) return;
        localBrightness = clamp01(level);
        displayedBrightness = localBrightness;
        pendingBrightness = localBrightness;
        lastAppliedBrightness = localBrightness;
    }

    function syncVolumeFromLevel(level) {
        if (level < 0) return;
        localVolume = clamp01(level);
        displayedVolume = localVolume;
        pendingVolume = localVolume;
        lastAppliedVolume = localVolume;
    }

    function syncLevelsFromProps() {
        syncBrightnessFromLevel(brightnessLevel);
        syncVolumeFromLevel(volumeLevel);
    }

    function bluetoothDeviceName(device) {
        if (!device) return "Unknown device";
        return BluetoothFormatting.displayName(
            device.name,
            device.deviceName,
            device.address,
            device.icon
        );
    }

    function bluetoothDeviceHasFriendlyName(device) {
        if (!device) return false;
        return BluetoothFormatting.friendlyName(
            device.name,
            device.deviceName,
            device.address
        ).length > 0;
    }

    function bluetoothDeviceAddress(device) {
        return device ? BluetoothFormatting.addressLabel(device.address) : "";
    }

    function bluetoothDeviceStateText(device) {
        if (!device) return "";
        if (device.pairing) return "Pairing";

        switch (device.state) {
        case BluetoothDeviceState.Connecting:
            return "Connecting";
        case BluetoothDeviceState.Connected:
            return "Connected";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnecting";
        default:
            break;
        }

        if (device.paired || device.bonded) return "Paired";
        return "Available";
    }

    function bluetoothDeviceSubtitle(device) {
        const parts = [];
        const stateLabel = bluetoothDeviceStateText(device);
        if (stateLabel.length > 0) parts.push(stateLabel);
        if (device && device.batteryAvailable) parts.push(bluetoothBatteryPercent(device) + "%");
        if (device && !bluetoothDeviceHasFriendlyName(device)) {
            const address = bluetoothDeviceAddress(device);
            if (address.length > 0) parts.push(address);
        }
        return parts.join(" • ");
    }

    function bluetoothBatteryPercent(device) {
        if (!device || !device.batteryAvailable)
            return -1;

        const rawValue = Math.max(0, Number(device.battery) || 0);
        return Math.max(0, Math.min(100, Math.round(rawValue <= 1 ? rawValue * 100 : rawValue)));
    }

    function bluetoothDeviceMatchesSection(device, section) {
        if (!device) return false;

        const paired = device.paired || device.bonded;
        if (section === "connected") return device.connected;
        if (section === "paired") return !device.connected && paired;
        if (section === "available") return !paired;
        return false;
    }

    function buildBluetoothStatusText() {
        if (!bluetoothAvailable) return "Unavailable";
        if (!bluetoothEnabled) return "Off";

        const devices = bluetoothDeviceValues || [];
        const connectedNames = [];

        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];
            if (device && device.connected)
                connectedNames.push(bluetoothDeviceName(device));
        }

        if (connectedNames.length === 1) return connectedNames[0];
        if (connectedNames.length > 1) return connectedNames[0] + " +" + (connectedNames.length - 1);
        if (bluetoothAdapter.discovering) return "Scanning";
        return bluetoothBusy ? "Working..." : "On";
    }

    function toggleBluetoothEnabled() {
        if (!bluetoothAdapter) {
            bluetoothError = "No Bluetooth adapter is available.";
            return;
        }

        bluetoothError = "";
        bluetoothInfoMessage = "";
        bluetoothPairAndConnectPath = "";

        if (bluetoothAdapter.discovering)
            bluetoothAdapter.discovering = false;

        bluetoothAdapter.enabled = !bluetoothAdapter.enabled;
    }

    function toggleBluetoothScan() {
        if (!bluetoothAdapter) {
            bluetoothError = "No Bluetooth adapter is available.";
            return;
        }
        if (!bluetoothEnabled) {
            bluetoothError = "Turn on Bluetooth first.";
            return;
        }

        bluetoothError = "";
        if (bluetoothAdapter.discovering) {
            bluetoothAdapter.discovering = false;
            bluetoothInfoMessage = "";
            bluetoothScanStopTimer.stop();
        } else {
            bluetoothAdapter.discovering = true;
            bluetoothInfoMessage = "Scanning for nearby devices...";
            bluetoothScanStopTimer.restart();
        }
    }

    function handleBluetoothDevicePressed(device) {
        if (!device) return;
        if (!bluetoothAdapter || !bluetoothEnabled) {
            bluetoothError = "Turn on Bluetooth first.";
            return;
        }

        bluetoothError = "";

        if (device.connected) {
            bluetoothInfoMessage = "Disconnecting from " + bluetoothDeviceName(device) + "...";
            bluetoothMessageClearTimer.restart();
            device.disconnect();
            return;
        }

        if (device.paired || device.bonded) {
            bluetoothPairAndConnectPath = device.dbusPath;
            bluetoothInfoMessage = "Connecting to " + bluetoothDeviceName(device) + "...";
            device.trusted = true;
            bluetoothConnectionTimeoutTimer.restart();
            device.connect();
            return;
        }

        bluetoothPairAndConnectPath = device.dbusPath;
        bluetoothInfoMessage = "Pairing " + bluetoothDeviceName(device) + "...";
        bluetoothConnectionTimeoutTimer.restart();
        device.pair();
    }

    function bluetoothDeviceForPath(path) {
        const devices = bluetoothDeviceValues || [];
        for (let index = 0; index < devices.length; index++) {
            const device = devices[index];
            if (device && device.dbusPath === path)
                return device;
        }
        return null;
    }

    function finishBluetoothConnection(device) {
        if (!device || bluetoothPairAndConnectPath !== device.dbusPath)
            return;

        if (device.paired || device.bonded)
            device.trusted = true;

        bluetoothConnectAfterPairTimer.stop();
        bluetoothConnectionTimeoutTimer.stop();
        bluetoothPairAndConnectPath = "";
        bluetoothInfoMessage = "";
        bluetoothError = "";
    }

    function continueBluetoothPairAndConnect(device) {
        if (!device || bluetoothPairAndConnectPath !== device.dbusPath)
            return;
        if (device.pairing)
            return;

        if (!(device.paired || device.bonded)) {
            bluetoothConnectAfterPairTimer.stop();
            bluetoothConnectionTimeoutTimer.stop();
            bluetoothPairAndConnectPath = "";
            bluetoothInfoMessage = "";
            if (!bluetoothPairingActive)
                bluetoothError = "Pairing failed or was canceled.";
            return;
        }

        device.trusted = true;
        if (device.connected) {
            finishBluetoothConnection(device);
            return;
        }

        bluetoothInfoMessage = "Connecting to " + bluetoothDeviceName(device) + "...";
        bluetoothConnectAfterPairTimer.restart();
    }

    function handleBluetoothConnectionStateChanged(device) {
        if (!device || bluetoothPairAndConnectPath !== device.dbusPath)
            return;

        if (device.connected) {
            if (device.pairing)
                return;
            finishBluetoothConnection(device);
            return;
        }

        if (!device.pairing
                && (device.paired || device.bonded)
                && device.state === BluetoothDeviceState.Disconnected
                && !bluetoothConnectAfterPairTimer.running) {
            bluetoothConnectionTimeoutTimer.stop();
            bluetoothPairAndConnectPath = "";
            bluetoothInfoMessage = "";
            bluetoothError = "Paired successfully, but the connection failed. Make sure the device is still ready to connect.";
        }
    }

    function forgetBluetoothDevice(device) {
        if (!device) return;
        const name = bluetoothDeviceName(device);
        if (bluetoothPairAndConnectPath === device.dbusPath) {
            bluetoothConnectAfterPairTimer.stop();
            bluetoothConnectionTimeoutTimer.stop();
            bluetoothPairAndConnectPath = "";
        }
        device.forget();
        bluetoothError = "";
        bluetoothInfoMessage = "Forgot " + name + ".";
        bluetoothMessageClearTimer.restart();
    }

    anchors.fill: parent
    anchors.margins: 12
    opacity: showCondition ? 1 : 0
    visible: opacity > 0

    onBrightnessLevelChanged: syncBrightnessFromLevel(brightnessLevel)
    onVolumeLevelChanged: syncVolumeFromLevel(volumeLevel)
    onShowConditionChanged: {
        if (showCondition) {
            localConfigFile.reload();
            syncLevelsFromProps();
            displayedBrightness = localBrightness;
            displayedVolume = localVolume;
            refreshBatteryModeState();
            requestWifiStateRefresh();
            if (wifiPanelOpen && wifiSupported && wifiEnabled)
                requestWifiListRefresh(true);
        } else {
            displayedBrightness = localBrightness;
            displayedVolume = localVolume;
            closeConnectivityPanels();
        }
    }

    Component.onCompleted: {
        syncLevelsFromProps();
        displayedBrightness = localBrightness;
        displayedVolume = localVolume;
        SystemServices.requestBrightness();
        SystemServices.requestVolume();
        refreshBatteryModeState();
        focusStateProcess.running = true;
    }

    Behavior on opacity {
        NumberAnimation {
            duration: showCondition ? 240 : 100
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on batteryDrawerProgress {
        enabled: !controlCenter.batteryDrawerDragging

        NumberAnimation {
            id: batteryDrawerProgressAnimation
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Process {
        id: focusStateProcess
        command: ["swaync-client", "--get-dnd"]
        running: false

        stdout: SplitParser {
            onRead: function(line) {
                const enabled = line.trim().toLowerCase() === "true";
                controlCenter.focusEnabled = enabled;
                controlCenter.focusModeChanged(enabled);
            }
        }
    }

    Process {
        id: nightLightEnableProcess
        command: [
            "sh",
            "-c",
            controlCenter.hyprlandNightLight
                ? "temp=\"$1\"\n"
                    + "if ! command -v hyprsunset >/dev/null 2>&1; then exit 127; fi\n"
                    + "if hyprctl hyprsunset temperature \"$temp\" >/dev/null 2>&1; then exit 0; fi\n"
                    + "if ! command -v pgrep >/dev/null 2>&1 || ! pgrep -x hyprsunset >/dev/null 2>&1; then\n"
                    + "  if command -v setsid >/dev/null 2>&1; then\n"
                    + "    setsid hyprsunset >/dev/null 2>&1 < /dev/null &\n"
                    + "  else\n"
                    + "    nohup hyprsunset >/dev/null 2>&1 < /dev/null &\n"
                    + "  fi\n"
                    + "fi\n"
                    + "i=0\n"
                    + "while [ \"$i\" -lt 24 ]; do\n"
                    + "  if hyprctl hyprsunset temperature \"$temp\" >/dev/null 2>&1; then exit 0; fi\n"
                    + "  i=$((i + 1))\n"
                    + "  sleep 0.04\n"
                    + "done\n"
                    + "exit 1"
                : "temp=\"$1\"\n"
                    + "if ! command -v gammastep >/dev/null 2>&1; then exit 127; fi\n"
                    + "gammastep -m wayland -P -O \"$temp\" >/dev/null 2>&1",
            "dynamic-island-night-light",
            controlCenter.nightLightTemperature.toString()
        ]
        running: false

        onExited: function(exitCode) {
            if (exitCode === 0) {
                controlCenter.nightLightBusy = false;
                controlCenter.nightLightEnabled = true;
                controlCenter.nightLightModeChanged(true);
                controlCenter.requestNotification("Night Light", "Night Light enabled", controlCenter.nightLightTemperature + "K");
                return;
            }

            controlCenter.nightLightBusy = false;
            controlCenter.nightLightEnabled = false;
            controlCenter.nightLightModeChanged(false);
            controlCenter.requestNotification("Night Light", "Night Light unavailable",
                controlCenter.hyprlandNightLight
                    ? "Install hyprsunset to use Night Light."
                    : "Install gammastep to use Night Light.");
        }
    }

    Process {
        id: nightLightDisableProcess
        command: [
            "sh",
            "-c",
            controlCenter.hyprlandNightLight
                ? "hyprctl hyprsunset identity >/dev/null 2>&1 || true"
                : "if ! command -v gammastep >/dev/null 2>&1; then exit 127; fi\n"
                    + "gammastep -m wayland -x >/dev/null 2>&1 || true"
        ]
        running: false

        onExited: function(exitCode) {
            controlCenter.nightLightBusy = false;
            controlCenter.nightLightEnabled = false;
            controlCenter.nightLightModeChanged(false);
            if (exitCode === 127)
                controlCenter.requestNotification("Night Light", "Night Light unavailable",
                    controlCenter.hyprlandNightLight
                        ? "Install hyprsunset to use Night Light."
                        : "Install gammastep to use Night Light.");
            else
                controlCenter.requestNotification("Night Light", "Night Light disabled", "");
        }
    }

    Process {
        id: focusEnableProcess
        command: ["swaync-client", "-dn"]
        running: false

        onExited: function(exitCode) {
            controlCenter.focusBusy = false;
            controlCenter.focusEnabled = exitCode === 0;
            controlCenter.focusModeChanged(controlCenter.focusEnabled);
            if (exitCode === 0)
                controlCenter.requestNotification("Focus", "Focus enabled", "Notifications paused");
        }
    }

    Process {
        id: focusDisableProcess
        command: ["swaync-client", "-df"]
        running: false

        onExited: function(exitCode) {
            controlCenter.focusBusy = false;
            controlCenter.focusEnabled = false;
            controlCenter.focusModeChanged(false);
            if (exitCode === 0)
                controlCenter.requestNotification("Focus", "Focus disabled", "");
        }
    }

    Process {
        id: shutdownProcess
        command: ["systemctl", "poweroff"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                controlCenter.requestNotification("Power", "Shutdown failed",
                    "Could not power off via systemctl.");
        }
    }
    Process {
        id: restartProcess
        command: ["systemctl", "reboot"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                controlCenter.requestNotification("Power", "Restart failed",
                    "Could not reboot via systemctl.");
        }
    }
    Process {
        id: sleepProcess
        command: ["systemctl", "suspend"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                controlCenter.requestNotification("Power", "Sleep failed",
                    "Could not suspend via systemctl.");
        }
    }
    Process {
        id: lockProcess
        command: [controlCenter.homeDir + "/.scripts/qslock-wrapper.sh"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                controlCenter.requestNotification("Power", "Lock failed",
                    "Could not lock screen.");
        }
    }

    Process {
        id: applyBarProcess
        running: false
        function run(bar) {
            command = [controlCenter.homeDir + "/.scripts/apply-qs-bar.sh", bar];
            running = true;
        }
    }

    Process {
        id: openSwitcherProcess
        command: [controlCenter.homeDir + "/.scripts/qs-theme-switcher.sh"]
        running: false
        function run() {
            running = true;
        }
    }

    Connections {
        target: SystemServices

        function onTlpStateReady(available, profile, output, errorString) {
            controlCenter.applyBatteryModeState(available, profile, output, errorString);
        }

        function onTlpSetFinished(success, exitCode, output, errorString) {
            controlCenter.finishBatteryModeApply(success, exitCode, output, errorString);
        }

        function onBrightnessSnapshotReady(value, errorString) {
            if (errorString === "")
                controlCenter.applyBrightnessSnapshot(value);
        }

        function onBrightnessSetFinished(value, success, errorString) {
            controlCenter.brightnessSetterRunning = false;
            if (success)
                controlCenter.applyBrightnessSnapshot(value);
            if (success && Math.abs(controlCenter.pendingBrightness - controlCenter.lastAppliedBrightness) >= 0.01)
                brightnessApplyTimer.restart();
        }

        function onVolumeSnapshotReady(value, muted, errorString) {
            if (errorString === "")
                controlCenter.applyVolumeSnapshot(value);
        }

        function onVolumeSetFinished(value, success, errorString) {
            controlCenter.volumeSetterRunning = false;
            if (success)
                controlCenter.applyVolumeSnapshot(value);
            if (success && Math.abs(controlCenter.pendingVolume - controlCenter.lastAppliedVolume) >= 0.01)
                volumeApplyTimer.restart();
        }
    }

    Timer {
        id: brightnessApplyTimer
        interval: 55
        repeat: false
        onTriggered: controlCenter.flushBrightness(false)
    }

    Timer {
        id: volumeApplyTimer
        interval: 55
        repeat: false
        onTriggered: controlCenter.flushVolume(false)
    }

    Timer {
        id: batteryModeRefreshTimer
        interval: 1500
        repeat: true
        onTriggered: {
            if (controlCenter.batteryModeRefreshPollsRemaining <= 0) {
                stop();
                return;
            }

            controlCenter.batteryModeRefreshPollsRemaining -= 1;
            controlCenter.refreshBatteryModeState();

            if (controlCenter.batteryModeRefreshPollsRemaining <= 0)
                stop();
        }
    }

    Timer {
        id: bluetoothScanStopTimer
        interval: 8000
        repeat: false
        onTriggered: {
            if (controlCenter.bluetoothAdapter && controlCenter.bluetoothAdapter.discovering)
                controlCenter.bluetoothAdapter.discovering = false;
            controlCenter.bluetoothInfoMessage = "";
        }
    }

    Timer {
        id: bluetoothConnectAfterPairTimer
        interval: 350
        repeat: false
        onTriggered: {
            const device = controlCenter.bluetoothDeviceForPath(controlCenter.bluetoothPairAndConnectPath);
            if (!device)
                return;
            if (device.connected) {
                controlCenter.finishBluetoothConnection(device);
                return;
            }
            device.connect();
        }
    }

    Timer {
        id: bluetoothConnectionTimeoutTimer
        interval: 30000
        repeat: false
        onTriggered: {
            if (controlCenter.bluetoothPairAndConnectPath.length === 0)
                return;
            bluetoothConnectAfterPairTimer.stop();
            controlCenter.bluetoothPairAndConnectPath = "";
            controlCenter.bluetoothInfoMessage = "";
            controlCenter.bluetoothError = "Bluetooth pairing or connection timed out. Put the device back in pairing mode and try again.";
        }
    }

    Timer {
        id: bluetoothMessageClearTimer
        interval: 2500
        repeat: false
        onTriggered: {
            if (controlCenter.bluetoothPairAndConnectPath.length === 0)
                controlCenter.bluetoothInfoMessage = "";
        }
    }

    Timer {
        id: batteryDrawerSettleTimer
        interval: 300
        repeat: false
        onTriggered: controlCenter.batteryDrawerSettling = false
    }

    Connections {
        target: wifiController

        function onEnabledChanged() {
            if (!controlCenter.wifiEnabled)
                controlCenter.clearWifiPrompt();
        }
    }

    Connections {
        target: bluetoothAdapter

        function onEnabledChanged() {
            if (!controlCenter.bluetoothAdapter.enabled) {
                controlCenter.bluetoothPairAndConnectPath = "";
                controlCenter.bluetoothInfoMessage = "";
                controlCenter.bluetoothError = "";
                bluetoothScanStopTimer.stop();
                bluetoothConnectAfterPairTimer.stop();
                bluetoothConnectionTimeoutTimer.stop();
            }
        }

        function onDiscoveringChanged() {
            if (!controlCenter.bluetoothAdapter.discovering)
                bluetoothScanStopTimer.stop();
        }
    }

    // Keep device state observers outside the filtered UI rows. A device moves
    // from "available" to "paired" during first-time pairing, which destroys
    // its old row before a row-local PairedChanged handler can reliably finish
    // the trust-and-connect sequence.
    Repeater {
        model: controlCenter.bluetoothDeviceValues

        delegate: Item {
            width: 0
            height: 0
            visible: false

            property var bluetoothDevice: modelData

            Connections {
                target: bluetoothDevice
                ignoreUnknownSignals: true

                function onPairedChanged() {
                    controlCenter.continueBluetoothPairAndConnect(bluetoothDevice);
                }

                function onBondedChanged() {
                    controlCenter.continueBluetoothPairAndConnect(bluetoothDevice);
                }

                function onPairingChanged() {
                    controlCenter.continueBluetoothPairAndConnect(bluetoothDevice);
                }

                function onConnectedChanged() {
                    controlCenter.handleBluetoothConnectionStateChanged(bluetoothDevice);
                }

                function onStateChanged() {
                    controlCenter.handleBluetoothConnectionStateChanged(bluetoothDevice);
                }
            }
        }
    }

    Connections {
        target: bluetoothPairingAgent

        function onRequestChanged() {
            controlCenter.bluetoothPendingSecretValue = "";
            if (controlCenter.bluetoothPairingActive) {
                controlCenter.bluetoothError = "";
                controlCenter.setConnectivityPanelOpen("bluetooth", true);
            }
        }

        function onRegistrationErrorChanged() {
            if (!controlCenter.bluetoothPairingAgent)
                return;

            if (!controlCenter.bluetoothPairingAgent.registered
                    && controlCenter.bluetoothPairingAgent.registrationError.length > 0
                    && controlCenter.bluetoothPanelOpen) {
                controlCenter.bluetoothError = controlCenter.bluetoothPairingAgent.registrationError;
            }
        }
    }

    Component {
        id: headerComponent
        Item {
            anchors.fill: parent

            Row {
                id: timeAndDateRow
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    id: timeLabel
                    text: controlCenter.currentTime
                    color: controlCenter.accentColor
                    font.pixelSize: 19
                    font.family: controlCenter.heroFontFamily
                    font.weight: Font.Bold
                    font.letterSpacing: -0.45

                    Behavior on color {
                        ColorAnimation { duration: 300 }
                    }
                }

                Text {
                    anchors.baseline: timeLabel.baseline
                    text: controlCenter.currentDateLabel
                    color: controlCenter.textSecondary
                    font.pixelSize: 12
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.Medium
                }
            }

            Row {
                id: batteryIndicatorRow
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: controlCenter.chargingIconGlyph
                    color: StyleTokens.white
                    font.pixelSize: 13
                    font.family: controlCenter.iconFontFamily
                    visible: controlCenter.isCharging
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: controlCenter.batteryCapacity + "%"
                    color: StyleTokens.white
                    font.pixelSize: 13
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item {
                    width: 28
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        anchors.rightMargin: 2
                        radius: 4
                        color: StyleTokens.transparent
                        border.color: StyleTokens.textSecondary
                        border.width: 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 2
                            radius: 2
                            width: (parent.width - 4) * (controlCenter.batteryCapacity / 100.0)
                            color: {
                                if (controlCenter.batteryCapacity <= 10) return StyleTokens.danger;
                                if (controlCenter.batteryCapacity <= 20) return StyleTokens.warning;
                                return StyleTokens.success;
                            }

                            Behavior on width {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 2
                        height: 6
                        radius: 1
                        color: StyleTokens.textSecondary
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item {
                    width: 26
                    height: 26
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: settingsGearBtn
                        anchors.fill: parent
                        radius: 13
                        color: settingsGearMouse.containsMouse ? "#26ffffff" : "#10ffffff"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.pixelSize: 13
                            font.family: controlCenter.iconFontFamily
                            color: settingsGearMouse.containsMouse ? controlCenter.cardAccent : "#d6d8df"
                            rotation: settingsGearMouse.containsMouse ? 60 : 0

                            Behavior on rotation {
                                NumberAnimation { duration: 320; easing.type: Easing.OutBack }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        MouseArea {
                            id: settingsGearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlCenter.settingsRequested()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: oneByOneComponent
        Item {
            id: tileContainer
            anchors.fill: parent

            Rectangle {
                id: tileRoot
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                radius: width / 2
                clip: true

                readonly property string modId: (tileContainer.parent && tileContainer.parent.slotModel) ? tileContainer.parent.slotModel.id : (moduleSlot ? moduleSlot.modelData.id : "")
                readonly property bool isModuleActive: {
                    switch (modId) {
                    case "wifi": return controlCenter.wifiEnabled;
                    case "bluetooth": return controlCenter.bluetoothEnabled;
                    case "volume": return controlCenter.displayedVolume > 0.01;
                    case "brightness": return controlCenter.displayedBrightness > 0.01;
                    case "toggles": return controlCenter.focusEnabled || controlCenter.nightLightEnabled;
                    case "notifications": return controlCenter.notificationModel && controlCenter.notificationModel.count > 0;
                    case "battery": return true;
                    case "quickactions": return true;
                    default: return false;
                    }
                }

                readonly property string iconGlyph: {
                    switch (modId) {
                    case "wifi": return controlCenter.wifiGlyph;
                    case "bluetooth": return "\uf294";
                    case "volume": return controlCenter.volumeIconGlyph;
                    case "brightness": return controlCenter.brightnessIconGlyph;
                    case "toggles": return controlCenter.focusEnabled ? "\uf186" : (controlCenter.nightLightEnabled ? "\uf185" : "\uf186");
                    case "battery": return (controlCenter.batteryModeGlyphs && controlCenter.batteryModeGlyphs[controlCenter.batteryModeIndex]) || "\uf0e7";
                    case "notifications": return "\uf0f3";
                    case "quickactions": return "\uf108";
                    default: return "\uf013";
                    }
                }

                readonly property color activeColor: {
                    switch (modId) {
                    case "wifi": return "#0a84ff";
                    case "bluetooth": return "#0a84ff";
                    case "volume": return controlCenter.cardAccent;
                    case "brightness": return "#ff9f0a";
                    case "toggles": return controlCenter.focusEnabled ? "#af52de" : "#ff9f0a";
                    case "battery": {
                        if (controlCenter.batteryModeIndex === 0) return "#30d158";
                        if (controlCenter.batteryModeIndex === 2) return "#ff453a";
                        return controlCenter.cardAccent;
                    }
                    case "notifications": return controlCenter.cardAccent;
                    default: return controlCenter.cardAccent;
                    }
                }

                color: isModuleActive
                    ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, tileMouse.containsMouse ? 0.28 : 0.18)
                    : (tileMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.10) : Qt.rgba(255, 255, 255, 0.05))

                border.width: 1
                border.color: isModuleActive
                    ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.42)
                    : Qt.rgba(255, 255, 255, 0.08)

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                MatteSurface {
                    anchors.fill: parent
                    radius: parent.radius
                    hovered: tileMouse.containsMouse
                    pressed: tileMouse.pressed
                }

                Text {
                    anchors.centerIn: parent
                    text: tileRoot.iconGlyph
                    font.family: controlCenter.iconFontFamily
                    font.pixelSize: 26
                    color: tileRoot.isModuleActive ? tileRoot.activeColor : StyleTokens.textSecondary
                    scale: tileMouse.pressed ? 0.90 : (tileMouse.containsMouse ? 1.10 : 1.0)

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }
                }

                Rectangle {
                    visible: tileRoot.modId === "notifications" && controlCenter.notificationModel && controlCenter.notificationModel.count > 0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 8
                    anchors.rightMargin: 8
                    width: 18
                    height: 18
                    radius: 9
                    color: "#ff3b30"
                    Text {
                        anchors.centerIn: parent
                        text: String(controlCenter.notificationModel ? controlCenter.notificationModel.count : 0)
                        font.pixelSize: 9
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.Bold
                        color: "#ffffff"
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        controlCenter.openModuleDetail(tileRoot.modId);
                    }
                }
            }
        }
    }

    Component {
        id: wifiComponent
        Rectangle {
            anchors.fill: parent
            radius: Math.min(20, Math.max(14, parent.height / 2))
            color: StyleTokens.clearBlack
            clip: true

            readonly property bool isCompact: parent.height < 58

            MatteSurface {
                anchors.fill: parent
                radius: parent.radius
                hovered: wifiCardMouse.containsMouse || controlCenter.wifiPanelOpen
            }

            MouseArea {
                id: wifiCardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isCompact ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (isCompact) controlCenter.toggleConnectivityOverlay("wifi");
                }
            }

            Text {
                id: wifiIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.top: isCompact ? undefined : parent.top
                anchors.topMargin: isCompact ? 0 : Math.min(14, Math.max(8, (parent.height - 56) / 2))
                anchors.verticalCenter: isCompact ? parent.verticalCenter : undefined
                text: controlCenter.wifiGlyph
                color: controlCenter.wifiEnabled ? controlCenter.cardAccent : StyleTokens.textDisabled
                font.pixelSize: isCompact ? 16 : 18
                font.family: controlCenter.iconFontFamily
            }

            Rectangle {
                id: wifiSwitchTrack
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.top: isCompact ? undefined : parent.top
                anchors.topMargin: isCompact ? 0 : Math.min(12, Math.max(8, (parent.height - 56) / 2))
                anchors.verticalCenter: isCompact ? parent.verticalCenter : undefined
                width: isCompact ? 30 : 34
                height: isCompact ? 18 : 20
                radius: height / 2
                color: controlCenter.wifiEnabled ? StyleTokens.success : StyleTokens.switchOff

                Behavior on color {
                    ColorAnimation {
                        duration: StyleTokens.durationFast
                    }
                }

                Rectangle {
                    width: parent.height - 4
                    height: width
                    radius: width / 2
                    y: 2
                    x: controlCenter.wifiEnabled ? (parent.width - width - 2) : 2
                    color: StyleTokens.white

                    Behavior on x {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: wifiToggleArea
                    anchors.fill: parent
                    enabled: controlCenter.wifiSupported && controlCenter.wifiAvailable && !controlCenter.wifiBusy
                    onClicked: controlCenter.toggleWifiEnabled()
                }
            }

            Text {
                anchors.left: wifiIcon.right
                anchors.leftMargin: 8
                anchors.right: wifiSwitchTrack.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: "Wi-Fi"
                color: controlCenter.textPrimary
                font.pixelSize: 12
                font.family: controlCenter.textFontFamily
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                visible: isCompact && (parent.width >= 100)
            }

            Item {
                id: wifiDetailButton
                visible: !isCompact
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: Math.min(10, Math.max(6, (parent.height - 56) / 3))
                height: Math.min(30, Math.max(22, parent.height - 46))

                Column {
                    anchors.left: parent.left
                    anchors.right: wifiChevron.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: "Wi-Fi"
                        color: controlCenter.textPrimary
                        font.pixelSize: 13
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: controlCenter.wifiStatusText
                        color: StyleTokens.textMuted
                        font.pixelSize: 10
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: wifiChevron
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: controlCenter.wifiPanelOpen ? "#c7c9cf" : StyleTokens.textSubtle
                    font.pixelSize: 17
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenter.toggleConnectivityOverlay("wifi")
                }
            }
        }
    }

    Component {
        id: bluetoothComponent
        Rectangle {
            anchors.fill: parent
            radius: Math.min(20, Math.max(14, parent.height / 2))
            color: StyleTokens.clearBlack
            clip: true

            readonly property bool isCompact: parent.height < 58

            MatteSurface {
                anchors.fill: parent
                radius: parent.radius
                hovered: bluetoothCardMouse.containsMouse || controlCenter.bluetoothPanelOpen
            }

            MouseArea {
                id: bluetoothCardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isCompact ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (isCompact) controlCenter.toggleConnectivityOverlay("bluetooth");
                }
            }

            Text {
                id: bluetoothIcon
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.top: isCompact ? undefined : parent.top
                anchors.topMargin: isCompact ? 0 : Math.min(14, Math.max(8, (parent.height - 56) / 2))
                anchors.verticalCenter: isCompact ? parent.verticalCenter : undefined
                text: controlCenter.bluetoothGlyph
                color: controlCenter.bluetoothEnabled ? controlCenter.cardAccent : StyleTokens.textDisabled
                font.pixelSize: isCompact ? 16 : 18
                font.family: controlCenter.iconFontFamily
            }

            Rectangle {
                id: bluetoothSwitchTrack
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.top: isCompact ? undefined : parent.top
                anchors.topMargin: isCompact ? 0 : Math.min(12, Math.max(8, (parent.height - 56) / 2))
                anchors.verticalCenter: isCompact ? parent.verticalCenter : undefined
                width: isCompact ? 30 : 34
                height: isCompact ? 18 : 20
                radius: height / 2
                color: controlCenter.bluetoothEnabled ? StyleTokens.success : StyleTokens.switchOff

                Behavior on color {
                    ColorAnimation {
                        duration: StyleTokens.durationFast
                    }
                }

                Rectangle {
                    width: parent.height - 4
                    height: width
                    radius: width / 2
                    y: 2
                    x: controlCenter.bluetoothEnabled ? (parent.width - width - 2) : 2
                    color: StyleTokens.white

                    Behavior on x {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: bluetoothToggleArea
                    anchors.fill: parent
                    enabled: controlCenter.bluetoothAvailable && !controlCenter.bluetoothBusy
                    onClicked: controlCenter.toggleBluetoothEnabled()
                }
            }

            Text {
                anchors.left: bluetoothIcon.right
                anchors.leftMargin: 8
                anchors.right: bluetoothSwitchTrack.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: "Bluetooth"
                color: controlCenter.textPrimary
                font.pixelSize: 12
                font.family: controlCenter.textFontFamily
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                visible: isCompact && (parent.width >= 100)
            }

            Item {
                id: bluetoothDetailButton
                visible: !isCompact
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: Math.min(10, Math.max(6, (parent.height - 56) / 3))
                height: Math.min(30, Math.max(22, parent.height - 46))

                Column {
                    anchors.left: parent.left
                    anchors.right: bluetoothChevron.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: "Bluetooth"
                        color: controlCenter.textPrimary
                        font.pixelSize: 13
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: controlCenter.bluetoothStatusText
                        color: StyleTokens.textMuted
                        font.pixelSize: 10
                        font.family: controlCenter.textFontFamily
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: bluetoothChevron
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: controlCenter.bluetoothPanelOpen ? "#c7c9cf" : StyleTokens.textSubtle
                    font.pixelSize: 17
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenter.toggleConnectivityOverlay("bluetooth")
                }
            }
        }
    }

    Component {
        id: brightnessComponent
        ControlSliderCard {
            anchors.fill: parent
            title: "Display"
            iconText: controlCenter.brightnessIconGlyph
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedBrightness
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary

            onInteractionStarted: {}
            onValueMoved: function(value) {
                controlCenter.queueBrightness(value);
            }
            onCommitRequested: {
                brightnessApplyTimer.stop();
                controlCenter.flushBrightness(true);
            }
            onCancelRequested: SystemServices.requestBrightness()
        }
    }

    Component {
        id: volumeComponent
        ControlSliderCard {
            anchors.fill: parent
            title: "Sound"
            iconText: controlCenter.volumeIconGlyph
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            value: controlCenter.displayedVolume
            knobSize: controlCenter.sliderKnobSize
            moduleColor: controlCenter.moduleColor
            moduleHover: controlCenter.moduleHover
            trackColor: controlCenter.trackColor
            textPrimary: controlCenter.textPrimary
            textSecondary: controlCenter.textSecondary

            onInteractionStarted: {}
            onValueMoved: function(value) {
                controlCenter.queueVolume(value);
            }
            onCommitRequested: {
                volumeApplyTimer.stop();
                controlCenter.flushVolume(true);
            }
            onCancelRequested: SystemServices.requestVolume()
        }
    }

    Component {
        id: notificationsComponent
        NotificationCard {
            anchors.fill: parent
            notificationModel: controlCenter.notificationModel
            accentColor: controlCenter.cardAccent
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            heroFontFamily: controlCenter.heroFontFamily
            onNotificationDismissed: function(index) {
                if (controlCenter.notificationModel && index >= 0 && index < controlCenter.notificationModel.count)
                    controlCenter.notificationModel.remove(index);
            }
            onClearAllRequested: {
                if (controlCenter.notificationModel)
                    controlCenter.notificationModel.clear();
            }
        }
    }

    Component {
        id: batteryComponent
        Rectangle {
            id: batteryModeCardItem
            anchors.fill: parent
            radius: Math.min(20, Math.max(14, parent.height / 2))
            color: StyleTokens.clearBlack
            clip: true

            readonly property bool isCompact: parent.height < 58
            readonly property real modeSlotWidth: 44

            MatteSurface {
                anchors.fill: parent
                radius: parent.radius
                hovered: controlCenter.batteryModeSliderDragging
            }

            Text {
                visible: !batteryModeCardItem.isCompact
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.top: parent.top
                anchors.topMargin: Math.min(11, Math.max(6, (parent.height - 56) / 2))
                text: "Battery"
                color: controlCenter.textPrimary
                font.pixelSize: 13
                font.family: controlCenter.textFontFamily
                font.weight: Font.DemiBold
            }

            Text {
                visible: !batteryModeCardItem.isCompact
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.top: parent.top
                anchors.topMargin: Math.min(12, Math.max(6, (parent.height - 56) / 2))
                width: Math.max(0, parent.width - 88)
                text: controlCenter.batteryModeError.length > 0
                    ? controlCenter.batteryModeError
                    : (controlCenter.batteryModeInfoMessage.length > 0
                        ? controlCenter.batteryModeInfoMessage
                        : controlCenter.batteryModeStatusText)
                color: controlCenter.batteryModeError.length > 0 ? StyleTokens.error : StyleTokens.textMuted
                horizontalAlignment: Text.AlignRight
                font.pixelSize: 9
                font.family: controlCenter.textFontFamily
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Item {
                id: batteryModeCarousel
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.bottom: batteryModeCardItem.isCompact ? undefined : parent.bottom
                anchors.bottomMargin: batteryModeCardItem.isCompact ? 0 : Math.min(8, Math.max(4, (parent.height - 56) / 3))
                anchors.verticalCenter: batteryModeCardItem.isCompact ? parent.verticalCenter : undefined
                height: batteryModeCardItem.isCompact ? Math.min(32, Math.max(22, parent.height - 8)) : Math.min(34, Math.max(22, parent.height - 46))
                clip: true

                Item {
                    id: batteryModeItems
                    width: batteryModeCardItem.modeSlotWidth * 3
                    height: parent.height
                    x: batteryModeCarousel.width / 2
                        - batteryModeCardItem.modeSlotWidth / 2
                        - controlCenter.batteryModeIndex * batteryModeCardItem.modeSlotWidth
                        + controlCenter.batteryModeDragOffset

                    Behavior on x {
                        enabled: !controlCenter.batteryModeSliderDragging

                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: 3

                        delegate: Item {
                            x: index * batteryModeCardItem.modeSlotWidth
                            width: batteryModeCardItem.modeSlotWidth
                            height: batteryModeCarousel.height
                            opacity: index === controlCenter.batteryModeIndex ? 1 : 0.42

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 140
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: index === controlCenter.batteryModeIndex ? 32 : 28
                                height: index === controlCenter.batteryModeIndex ? 28 : 24
                                radius: 12
                                color: index === controlCenter.batteryModeIndex ? StyleTokens.textPrimary : "#292a2f"

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 140
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 140
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: controlCenter.batteryModeGlyphs[index]
                                    color: index === controlCenter.batteryModeIndex ? StyleTokens.module : StyleTokens.textDim
                                    font.pixelSize: index === controlCenter.batteryModeIndex ? 15 : 13
                                    font.family: controlCenter.iconFontFamily
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: 22
                    height: 2
                    radius: 1
                    color: "#5d6068"
                    opacity: 0.75
                }

                MouseArea {
                    anchors.fill: parent
                    property real startX: 0
                    property int startIndex: 1
                    property bool moved: false

                    function clampDrag(delta) {
                        return Math.max(-batteryModeCardItem.modeSlotWidth, Math.min(batteryModeCardItem.modeSlotWidth, delta));
                    }

                    onPressed: function(mouse) {
                        startX = mouse.x;
                        startIndex = controlCenter.batteryModeIndex;
                        moved = false;
                        controlCenter.batteryModeInfoMessage = "";
                        controlCenter.batteryModeError = "";
                        controlCenter.batteryModeSliderDragging = true;
                        controlCenter.batteryModeDragOffset = 0;
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed)
                            return;

                        const delta = mouse.x - startX;
                        if (!moved && Math.abs(delta) < 4)
                            return;

                        moved = true;
                        controlCenter.batteryModeDragOffset = clampDrag(delta);
                    }

                    onReleased: function(mouse) {
                        const delta = mouse.x - startX;
                        let nextIndex = startIndex;

                        if (delta <= -18)
                            nextIndex = Math.min(2, startIndex + 1);
                        else if (delta >= 18)
                            nextIndex = Math.max(0, startIndex - 1);
                        else if (mouse.x < width / 2 - batteryModeCardItem.modeSlotWidth / 2)
                            nextIndex = Math.max(0, startIndex - 1);
                        else if (mouse.x > width / 2 + batteryModeCardItem.modeSlotWidth / 2)
                            nextIndex = Math.min(2, startIndex + 1);

                        controlCenter.batteryModeSliderDragging = false;
                        controlCenter.batteryModeDragOffset = 0;
                        controlCenter.selectBatteryMode(nextIndex);
                    }

                    onCanceled: {
                        controlCenter.batteryModeSliderDragging = false;
                        controlCenter.batteryModeDragOffset = 0;
                        controlCenter.setBatteryModeVisualIndex(controlCenter.batteryModeAppliedIndex, true);
                    }
                }
            }
        }
    }

    Component {
        id: togglesComponent
        Rectangle {
            id: togglesCardItem
            anchors.fill: parent
            radius: Math.min(20, Math.max(14, parent.height / 2))
            color: StyleTokens.clearBlack
            clip: true

            readonly property bool isCompact: parent.height < 58

            MatteSurface {
                anchors.fill: parent
                radius: parent.radius
                hovered: focusButtonMouse.containsMouse || nightLightButtonMouse.containsMouse
                pressed: focusButtonMouse.pressed || nightLightButtonMouse.pressed
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: Math.max(16, parent.height - (togglesCardItem.isCompact ? 16 : 34))
                radius: 1
                color: "#1cffffff"
            }

            Item {
                id: focusButton
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width / 2
                property real slashProgress: controlCenter.focusEnabled ? 1 : 0
                property color iconColor: controlCenter.focusEnabled ? StyleTokens.textPrimaryBright : "#c8cad1"

                Behavior on slashProgress {
                    NumberAnimation {
                        duration: 830
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 16
                    color: focusButtonMouse.containsMouse ? "#08ffffff" : StyleTokens.clearBlack

                    Behavior on color {
                        ColorAnimation {
                            duration: StyleTokens.durationFast
                        }
                    }
                }

                MouseArea {
                    id: focusButtonMouse
                    anchors.fill: parent
                    enabled: !controlCenter.focusBusy
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenter.toggleFocus()
                }

                Item {
                    id: focusIconSlot
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: togglesCardItem.isCompact ? undefined : parent.top
                    anchors.topMargin: togglesCardItem.isCompact ? 0 : Math.min(12, Math.max(6, (parent.height - 56) / 2))
                    anchors.verticalCenter: togglesCardItem.isCompact ? parent.verticalCenter : undefined
                    width: parent.width
                    height: 32

                    Shape {
                        id: focusIcon
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        scale: focusButtonMouse.pressed ? 0.94 : 1.0
                        opacity: controlCenter.focusBusy ? 0.5 : 1.0
                        preferredRendererType: Shape.CurveRenderer

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        ShapePath {
                            fillColor: StyleTokens.transparent
                            strokeColor: focusButton.iconColor
                            strokeWidth: 2
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin

                            PathSvg {
                                path: "M22 17H2a3 3 0 0 0 3-3V9a7 7 0 0 1 14 0v5a3 3 0 0 0 3 3zm-8.27 4a2 2 0 0 1-3.46 0"
                            }
                        }

                        ShapePath {
                            fillColor: StyleTokens.transparent
                            strokeColor: focusButton.iconColor
                            strokeWidth: 2.1
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin

                            PathMove {
                                x: 1
                                y: 1
                            }

                            PathLine {
                                x: 1 + 22 * focusButton.slashProgress
                                y: 1 + 22 * focusButton.slashProgress
                            }
                        }
                    }
                }

                Text {
                    visible: !togglesCardItem.isCompact
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.min(12, Math.max(6, (parent.height - 56) / 2))
                    width: parent.width
                    text: "Silent"
                    color: controlCenter.focusEnabled ? StyleTokens.textPrimaryBright : StyleTokens.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 10
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    opacity: controlCenter.focusBusy ? 0.5 : 1.0
                }
            }

            Item {
                id: nightLightButton
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width / 2

                MouseArea {
                    id: nightLightButtonMouse
                    anchors.fill: parent
                    enabled: !controlCenter.nightLightBusy
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenter.toggleNightLight()
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 16
                    color: nightLightButtonMouse.containsMouse ? "#08ffffff" : StyleTokens.clearBlack

                    Behavior on color {
                        ColorAnimation {
                            duration: StyleTokens.durationFast
                        }
                    }
                }

                Item {
                    id: nightLightIconSlot
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: togglesCardItem.isCompact ? undefined : parent.top
                    anchors.topMargin: togglesCardItem.isCompact ? 0 : Math.min(12, Math.max(6, (parent.height - 56) / 2))
                    anchors.verticalCenter: togglesCardItem.isCompact ? parent.verticalCenter : undefined
                    width: parent.width
                    height: 32

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1
                        text: controlCenter.nightLightGlyph
                        color: "#45000000"
                        font.pixelSize: 29
                        font.family: controlCenter.iconFontFamily
                        scale: nightLightButtonMouse.pressed ? 0.94 : 1.0
                        opacity: controlCenter.nightLightBusy ? 0.1 : 0.22
                    }

                    Text {
                        id: nightLightIcon
                        anchors.centerIn: parent
                        text: controlCenter.nightLightGlyph
                        color: controlCenter.nightLightEnabled ? StyleTokens.textPrimaryBright : "#c8cad1"
                        font.pixelSize: 29
                        font.family: controlCenter.iconFontFamily
                        scale: nightLightButtonMouse.pressed ? 0.94 : 1.0
                        opacity: controlCenter.nightLightBusy ? 0.5 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Text {
                    visible: !togglesCardItem.isCompact
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.min(12, Math.max(6, (parent.height - 56) / 2))
                    width: parent.width
                    text: "Night mode"
                    color: controlCenter.nightLightEnabled ? StyleTokens.textPrimaryBright : StyleTokens.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 10
                    font.family: controlCenter.textFontFamily
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    opacity: controlCenter.nightLightBusy ? 0.5 : 1.0
                }
            }
        }
    }

    Component {
        id: quickactionsComponent
        Row {
            anchors.fill: parent
            spacing: 12

            Rectangle {
                id: barSwitcherCard
                width: (parent.width - 12) / 2
                height: parent.height
                radius: 18
                color: StyleTokens.clearBlack
                clip: true

                MatteSurface {
                    anchors.fill: parent
                    radius: parent.radius
                    hovered: barSwitcherMouse.containsMouse
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: barSwitcherMouse.containsMouse ? controlCenter.cardAccent : "#1affffff"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: StyleTokens.durationFast } }

                        Text {
                            text: "󰍹"
                            color: StyleTokens.white
                            font.pixelSize: 14
                            font.family: controlCenter.iconFontFamily
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 42
                        spacing: 1

                        Text {
                            text: "Barra Desktop"
                            color: controlCenter.textPrimary
                            font.pixelSize: 12
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Cealestia"
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: barSwitcherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        applyBarProcess.run("cealestia");
                    }
                }
            }

            Rectangle {
                id: clipboardCard
                width: (parent.width - 12) / 2
                height: parent.height
                radius: 18
                color: StyleTokens.clearBlack
                clip: true

                MatteSurface {
                    anchors.fill: parent
                    radius: parent.radius
                    hovered: clipboardCardMouse.containsMouse
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: clipboardCardMouse.containsMouse ? controlCenter.cardAccent : "#1affffff"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: StyleTokens.durationFast } }

                        Text {
                            text: "󰅍"
                            color: StyleTokens.white
                            font.pixelSize: 14
                            font.family: controlCenter.iconFontFamily
                            anchors.centerIn: parent
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 42
                        spacing: 1

                        Text {
                            text: "Appunti"
                            color: controlCenter.textPrimary
                            font.pixelSize: 12
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Cronologia"
                            color: StyleTokens.textMuted
                            font.pixelSize: 10
                            font.family: controlCenter.textFontFamily
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: clipboardCardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: controlCenter.clipboardRequested()
                }
            }
        }
    }

    Item {
        id: mainContent
        anchors.fill: parent
        visible: opacity > 0.001
        opacity: !controlCenter.anyConnectivitySubViewActive ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        // Pinned Top Header (Clock, Date, Battery, Settings)
        Loader {
            id: topHeaderSlot
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 32
            sourceComponent: headerComponent
        }

        // 2D Grid with iPadOS 18 Circular Caselle Underneath
        Item {
            id: gridCaselleArea
            anchors.top: topHeaderSlot.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 34

            readonly property real gridSpacing: 10
            readonly property real unitColWidth: (width - (3 * gridSpacing)) / 4
            readonly property real unitRowHeight: 80

            function colWidth(c, cSpan) {
                if (cSpan === 4) return width;
                return Math.round(cSpan * unitColWidth + (cSpan - 1) * gridSpacing);
            }

            function colX(c) {
                return Math.round(c * (unitColWidth + gridSpacing));
            }

            readonly property int totalGridRows: {
                let maxR = 2;
                const layout = controlCenter.activeCanvasLayout;
                if (Array.isArray(layout)) {
                    for (let i = 0; i < layout.length; i++) {
                        let m = layout[i];
                        if (m && m.active && m.id !== "header") {
                            let r = (m.row !== undefined && m.row >= 0) ? m.row : 0;
                            let rs = Math.max(1, Math.min(3, Number(m.rowSpan) || (m.height >= 140 ? 2 : 1)));
                            if (r + rs > maxR) maxR = r + rs;
                        }
                    }
                }
                return Math.max(2, maxR);
            }

            function isSlotOccupied(c, r) {
                const layout = controlCenter.activeCanvasLayout;
                if (Array.isArray(layout)) {
                    for (let i = 0; i < layout.length; i++) {
                        let m = layout[i];
                        if (m && m.active && m.id !== "header") {
                            let mc = (m.col !== undefined && m.col >= 0) ? m.col : 0;
                            let mr = (m.row !== undefined && m.row >= 0) ? m.row : 0;
                            let mcs = Math.max(1, Math.min(4, Number(m.colSpan) || 1));
                            let mrs = Math.max(1, Math.min(3, Number(m.rowSpan) || (m.height >= 140 ? 2 : 1)));
                            if (c >= mc && c < mc + mcs && r >= mr && r < mr + mrs) {
                                return true;
                            }
                        }
                    }
                }
                return false;
            }

            // Layer 0: The Caselle (iPadOS 18 Circular Slots Underneath)
            Repeater {
                model: Math.max(0, gridCaselleArea.totalGridRows * 4)

                delegate: Rectangle {
                    required property int index
                    readonly property int col: index % 4
                    readonly property int row: Math.floor(index / 4)

                    x: gridCaselleArea.colX(col)
                    y: Math.round(row * (gridCaselleArea.unitRowHeight + gridCaselleArea.gridSpacing))
                    width: Math.round(gridCaselleArea.colWidth(col, 1))
                    height: Math.round(gridCaselleArea.unitRowHeight)
                    radius: 20

                    color: Qt.rgba(255, 255, 255, 0.055)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)

                    // Subtle dot for empty caselle
                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: Qt.rgba(255, 255, 255, 0.12)
                        visible: {
                            const _ = controlCenter.activeCanvasLayout;
                            return !gridCaselleArea.isSlotOccupied(col, row);
                        }
                    }
                }
            }

            // Layer 1: Active Modules on 2D Grid
            Repeater {
                id: modulesRepeater
                model: controlCenter.activeCanvasLayout

                delegate: Item {
                    id: moduleSlot
                    required property int index
                    required property var modelData

                    visible: modelData.active && modelData.id !== "header"

                    readonly property int col: (modelData.col !== undefined && modelData.col >= 0) ? modelData.col : 0
                    readonly property int row: (modelData.row !== undefined && modelData.row >= 0) ? modelData.row : 0
                    readonly property int colSpan: Math.max(1, Math.min(4, Number(modelData.colSpan) || 1))
                    readonly property int rowSpan: Math.max(1, Math.min(3, Number(modelData.rowSpan) || (modelData.height >= 140 ? 2 : 1)))

                    readonly property bool isFullWidth: colSpan === 4
                    readonly property real slotWidth: isFullWidth
                        ? gridCaselleArea.width
                        : Math.round(gridCaselleArea.colWidth(col, colSpan))
                    readonly property real slotHeight: {
                        if (modelData.id === "quickactions" && rowSpan === 1 && modelData.height && modelData.height < 80)
                            return Math.round(modelData.height);
                        if (modelData.id === "notifications") {
                            if (controlCenter.notificationModel && controlCenter.notificationModel.count > 0) {
                                return Math.max(rowSpan * gridCaselleArea.unitRowHeight + (rowSpan - 1) * gridCaselleArea.gridSpacing,
                                                Math.min(260, 38 + Math.min(3, controlCenter.notificationModel.count) * 58 + 10));
                            }
                        }
                        return Math.round(rowSpan * gridCaselleArea.unitRowHeight + (rowSpan - 1) * gridCaselleArea.gridSpacing);
                    }
                    readonly property bool isOneByOne: colSpan === 1 && rowSpan === 1

                    x: gridCaselleArea.colX(col)
                    y: Math.round(row * (gridCaselleArea.unitRowHeight + gridCaselleArea.gridSpacing))
                    width: slotWidth
                    height: slotHeight

                    Loader {
                        anchors.fill: parent
                        property var slotModel: moduleSlot.modelData
                        property bool isOneByOneSlot: moduleSlot.isOneByOne
                        active: moduleSlot.visible
                        sourceComponent: {
                            if (moduleSlot.isOneByOne) {
                                return oneByOneComponent;
                            }
                            switch (moduleSlot.modelData.id) {
                            case "wifi": return wifiComponent;
                            case "bluetooth": return bluetoothComponent;
                            case "brightness": return brightnessComponent;
                            case "volume": return volumeComponent;
                            case "notifications": return notificationsComponent;
                            case "battery": return batteryComponent;
                            case "toggles": return togglesComponent;
                            case "quickactions": return quickactionsComponent;
                            default: return null;
                            }
                        }
                    }
                }
            }
        }
    }


    Item {
        id: connectivitySubView
        anchors.fill: parent
        visible: opacity > 0.001
        opacity: controlCenter.anyConnectivitySubViewActive ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        // 1. Wifi / Bluetooth Detail Panel
        ConnectivityDetailPanel {
            anchors.fill: parent
            visible: controlCenter.wifiPanelOpen || controlCenter.bluetoothPanelOpen
            provider: controlCenter
            panelKind: controlCenter.wifiPanelOpen ? "wifi" : "bluetooth"
            iconFontFamily: controlCenter.iconFontFamily
            textFontFamily: controlCenter.textFontFamily
            heroFontFamily: controlCenter.heroFontFamily
            showBackground: false
            presentationProgress: connectivitySubView.opacity
            onBackRequested: {
                controlCenter.closeConnectivityPanels();
            }
        }

        // 2. Generic Module Detail View (Volume, Brightness, Battery, Toggles, Notifications, Quickactions)
        Item {
            id: genericDetailView
            anchors.fill: parent
            anchors.margins: 14
            visible: controlCenter.activeDetailModule !== "" && !controlCenter.wifiPanelOpen && !controlCenter.bluetoothPanelOpen

            // Header top bar with Back button and Module title
            Item {
                id: detailTopBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 36

                Rectangle {
                    id: backBtn
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: backRow.width + 18
                    height: 30
                    radius: 15
                    color: backBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                    border.width: 1
                    border.color: backBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : Qt.rgba(255, 255, 255, 0.10)

                    Row {
                        id: backRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            font.family: controlCenter.iconFontFamily
                            font.pixelSize: 11
                            color: controlCenter.cardAccent
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Indietro"
                            font.family: controlCenter.textFontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: controlCenter.textPrimary
                        }
                    }

                    MouseArea {
                        id: backBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlCenter.activeDetailModule = ""
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            switch (controlCenter.activeDetailModule) {
                            case "volume": return controlCenter.volumeIconGlyph;
                            case "brightness": return controlCenter.brightnessIconGlyph;
                            case "battery": return "\uf0e7";
                            case "toggles": return "\uf186";
                            case "notifications": return "\uf0f3";
                            case "quickactions": return "\uf108";
                            default: return "";
                            }
                        }
                        font.family: controlCenter.iconFontFamily
                        font.pixelSize: 14
                        color: controlCenter.cardAccent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            switch (controlCenter.activeDetailModule) {
                            case "volume": return "Controllo Volume";
                            case "brightness": return "Luminosità Display";
                            case "battery": return "Profilo Batteria TLP";
                            case "toggles": return "Luce Notturna & Focus";
                            case "notifications": return "Centro Notifiche";
                            case "quickactions": return "Barra & Appunti";
                            default: return "";
                            }
                        }
                        font.family: controlCenter.textFontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: controlCenter.textPrimary
                    }
                }
            }

            // Interactive component body
            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: detailTopBar.bottom
                anchors.bottom: parent.bottom
                anchors.topMargin: 14

                Loader {
                    id: detailLoader
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: (controlCenter.activeDetailModule === "notifications") ? parent.top : undefined
                    anchors.verticalCenter: (controlCenter.activeDetailModule !== "notifications") ? parent.verticalCenter : undefined
                    width: parent.width
                    height: {
                        switch (controlCenter.activeDetailModule) {
                        case "volume": return 90;
                        case "brightness": return 90;
                        case "battery": return 100;
                        case "toggles": return 100;
                        case "quickactions": return 64;
                        case "notifications": return Math.min(parent.height, 320);
                        default: return 90;
                        }
                    }
                    active: genericDetailView.visible
                    sourceComponent: {
                        switch (controlCenter.activeDetailModule) {
                        case "volume": return volumeComponent;
                        case "brightness": return brightnessComponent;
                        case "battery": return batteryComponent;
                        case "toggles": return togglesComponent;
                        case "notifications": return notificationsComponent;
                        case "quickactions": return quickactionsComponent;
                        default: return null;
                        }
                    }
                }
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (controlCenter.anyConnectivitySubViewActive) {
                controlCenter.closeConnectivityPanels();
                event.accepted = true;
                return;
            }
            controlCenter.closeRequested();
            event.accepted = true;
        }
    }
}
