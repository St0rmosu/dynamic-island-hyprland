import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import IslandBackend
import "qml/common"
import "qml/controlcenter"
import "qml/connectivity"
import "qml/island"
import "qml/workspace"

PanelWindow {
    id: root
    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")
    property var shellRootController: null
    property var dynamicConfig: null
    readonly property var polkitAgent: shellRootController ? shellRootController.polkitAgent : null
    property string overviewPhase: "closed"
    property bool overviewPreloading: false
    readonly property bool overviewPreparing: overviewPhase === "preparing"
    readonly property bool overviewVisible: overviewPhase === "preparing" || overviewPhase === "opening" || overviewPhase === "open"
    readonly property bool overviewMounted: overviewPhase !== "closed" || overviewPreloading
    readonly property bool overviewLoaderActive: !compositorIsNiri
    readonly property bool overviewDataReady: overviewLoader.item
        ? !!overviewLoader.item.overviewDataReady
        : true
    readonly property bool overviewWallpaperReady: true
    readonly property bool overviewVisualReady: overviewLoader.status === Loader.Ready
    readonly property bool overviewContentVisible: (overviewPhase === "opening" || overviewPhase === "open")
        && overviewVisualReady
    readonly property bool compositorIsNiri: CompositorBackend.compositor === "niri"
    readonly property int compositorRevision: CompositorBackend.revision
    readonly property string screenOutputName: screen && screen.name !== undefined ? String(screen.name) : ""
    readonly property var hyprlandIntegration: hyprlandIntegrationLoader.item
    readonly property var hyprMonitor: hyprlandIntegration ? hyprlandIntegration.monitor : null
    readonly property string hyprMonitorName: hyprlandIntegration ? hyprlandIntegration.monitorName : ""
    readonly property string compositorOutputName: compositorIsNiri ? screenOutputName : hyprMonitorName
    readonly property bool monitorFocused: {
        compositorRevision;
        return compositorIsNiri
            ? CompositorBackend.isOutputFocused(screenOutputName)
            : (hyprlandIntegration ? hyprlandIntegration.monitorFocused : false);
    }
    readonly property bool connectivityPromptActive: controlCenterLoader.item
        ? controlCenterLoader.item.hasConnectivityPrompt
        : false
    readonly property var controlCenterRef: controlCenterLoader.item
    readonly property int currentMonitorWorkspaceId: {
        compositorRevision;
        return compositorIsNiri
            ? CompositorBackend.activeWorkspaceIndexForOutput(screenOutputName)
            : (hyprlandIntegration ? hyprlandIntegration.workspaceId : 1);
    }
    readonly property bool screenRecordingActive: shellRootController
        && shellRootController.screenRecordingActive !== undefined
        ? !!shellRootController.screenRecordingActive
        : false
    property bool autoHideVisible: false
    property bool autoHidePointerInside: false
    property bool autoHideForcedHidden: false
    property string autoHideRevealSource: "none"

    readonly property var userConfig: UserConfig

    FileView {
        id: localUserConfigFile
        path: root.homeDir + "/.config/dynamic-island/userconfig.json"
        watchChanges: true
        property var parsedData: ({})

        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                parsedData = JSON.parse(text());
                console.log("[DynamicIsland] Loaded local userconfig. hoverAction:", parsedData.hoverExpandAction, "hoverEnabled:", parsedData.hoverExpandEnabled);
                if (userConfig && typeof userConfig.reload === "function") {
                    userConfig.reload();
                }
            } catch(e) {
                console.warn("[DynamicIsland] Failed to parse local userconfig:", e);
            }
        }
    }

    FileView {
        id: irisColors
        path: root.homeDir + "/.cache/iris/colors.json"
        watchChanges: true
        property string accentHex: ""

        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                var idata = JSON.parse(text());
                if (idata && idata.accent) {
                    accentHex = idata.accent;
                    console.log("[DynamicIsland] Loaded iris colors! accent:", accentHex);
                }
            } catch(e) {
                console.warn("[DynamicIsland] Failed to parse iris colors:", e);
            }
        }
    }

    FileView {
        id: walWallpaperFile
        path: root.homeDir + "/.cache/wal/wal"
        watchChanges: true
        property string wallpaperPath: ""

        Component.onCompleted: reload()
        onFileChanged: {
            reload();
            if (awwwQueryProc && !awwwQueryProc.running) {
                awwwQueryProc.running = true;
            }
        }
        onLoaded: {
            try {
                var p = text().trim();
                if (p !== "") {
                    wallpaperPath = p;
                    console.log("[DynamicIsland] Loaded wallpaper from ~/.cache/wal/wal:", p);
                }
            } catch(e) {
                console.warn("[DynamicIsland] Failed to read wal wallpaper path:", e);
            }
        }
    }

    FileView {
        id: currentWallpaperFile
        path: root.homeDir + "/.local/state/caelestia/wallpaper/path.txt"
        watchChanges: true
        property string wallpaperPath: ""

        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                var p = text().trim();
                if (p !== "") {
                    wallpaperPath = p;
                    console.log("[DynamicIsland] Loaded current wallpaper path from caelestia:", p);
                }
            } catch(e) {
                console.warn("[DynamicIsland] Failed to read current wallpaper path:", e);
            }
        }
    }

    FileView {
        id: pywalColors
        path: root.homeDir + "/.cache/wal/colors.json"
        watchChanges: true
        property color background: "#0f141c"
        property color foreground: "#ffffff"
        property string walAccent: "#0a84ff"
        property color accent: irisColors.accentHex !== "" ? irisColors.accentHex : walAccent
        property color accentSoft: Qt.lighter(accent, 1.25)
        property color accentPressed: Qt.darker(accent, 1.3)
        property string wallpaper: ""

        Component.onCompleted: reload()
        onFileChanged: {
            reload();
            if (awwwQueryProc && !awwwQueryProc.running) {
                awwwQueryProc.running = true;
            }
        }
        onLoaded: {
            try {
                var data = JSON.parse(text());
                if (data.special) {
                    if (data.special.background) background = data.special.background;
                    if (data.special.foreground) foreground = data.special.foreground;
                }
                if (data.wallpaper) {
                    wallpaper = data.wallpaper;
                }
                if (data.colors) {
                    var acc = data.colors.color4 || data.colors.color2 || "#0a84ff";
                    walAccent = acc;
                    console.log("[DynamicIsland] Loaded pywal colors! accent:", walAccent, "wallpaper:", data.wallpaper);
                }
            } catch(e) {
                console.warn("[DynamicIsland] Failed to parse pywal colors:", e);
            }
        }
    }

    property string awwwWallpaperPath: ""

    Process {
        id: awwwQueryProc
        command: ["awww", "query"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    const text = String(data);
                    const match = text.match(/currently displaying:\s*(?:image:\s*)?([^\r\n]+)/);
                    if (match && match[1]) {
                        const parsedPath = match[1].trim();
                        if (parsedPath !== "" && parsedPath !== root.awwwWallpaperPath) {
                            root.awwwWallpaperPath = parsedPath;
                            console.log("[DynamicIsland] awww wallpaper detected:", parsedPath);
                        }
                    }
                } catch(e) {
                    console.warn("[DynamicIsland] Failed to parse awww query:", e);
                }
            }
        }
    }

    Timer {
        id: wallpaperSyncTimer
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            if (awwwQueryProc && !awwwQueryProc.running) {
                awwwQueryProc.running = true;
            }
            if (walWallpaperFile) walWallpaperFile.reload();
        }
    }

    function refreshWallpaperSources() {
        if (walWallpaperFile) walWallpaperFile.reload();
        if (pywalColors) pywalColors.reload();
        if (currentWallpaperFile) currentWallpaperFile.reload();
        if (awwwQueryProc && !awwwQueryProc.running) {
            awwwQueryProc.running = true;
        }
    }

    Loader {
        id: hyprlandIntegrationLoader

        active: !root.compositorIsNiri
        asynchronous: false
        source: active ? "qml/island/HyprlandWindowIntegration.qml" : ""
    }

    Binding {
        target: hyprlandIntegrationLoader.item
        property: "screenObject"
        value: root.screen
        when: hyprlandIntegrationLoader.item !== null
    }

    color: StyleTokens.transparent
    anchors { top: true; left: true; right: true }
    mask: Region {
        // Input is the union of the island's visible surfaces plus a compact top
        // gesture strip. The gesture strip must not grow with expanded content.
        Region {
            x: Math.floor(root.topGestureInputX)
            y: 0
            width: Math.ceil(root.topGestureInputWidth)
            height: Math.ceil(root.topGestureInputHeight)
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(mainCapsule.x)
            y: Math.floor(mainCapsule.y)
            width: Math.ceil(mainCapsule.width)
            height: Math.ceil(mainCapsule.height)
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(topAnchorProxy.x)
            y: Math.floor(topAnchorProxy.y)
            width: (topAnchorProxy.visible && topAnchorProxy.width > 0) ? Math.ceil(topAnchorProxy.width) : 0
            height: (topAnchorProxy.visible && topAnchorProxy.width > 0) ? Math.ceil(topAnchorProxy.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: musicFloatingIsland ? Math.floor(musicFloatingIsland.x) : 0
            y: musicFloatingIsland ? Math.floor(musicFloatingIsland.y) : 0
            width: (musicFloatingIsland && musicFloatingIsland.visible) ? Math.ceil(musicFloatingIsland.width) : 0
            height: (musicFloatingIsland && musicFloatingIsland.visible) ? Math.ceil(musicFloatingIsland.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: headphonesFloatingIsland ? Math.floor(headphonesFloatingIsland.x) : 0
            y: headphonesFloatingIsland ? Math.floor(headphonesFloatingIsland.y) : 0
            width: (headphonesFloatingIsland && headphonesFloatingIsland.visible) ? Math.ceil(headphonesFloatingIsland.width) : 0
            height: (headphonesFloatingIsland && headphonesFloatingIsland.visible) ? Math.ceil(headphonesFloatingIsland.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: callFloatingIsland ? Math.floor(callFloatingIsland.x) : 0
            y: callFloatingIsland ? Math.floor(callFloatingIsland.y) : 0
            width: (callFloatingIsland && callFloatingIsland.visible) ? Math.ceil(callFloatingIsland.width) : 0
            height: (callFloatingIsland && callFloatingIsland.visible) ? Math.ceil(callFloatingIsland.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(fileShelfBubble.x)
            y: Math.floor(fileShelfBubble.y)
            width: fileShelfBubble.visible ? Math.ceil(fileShelfBubble.width) : 0
            height: fileShelfBubble.visible ? Math.ceil(fileShelfBubble.height) : 0
        }
        
        // Add existing detail shells
        Region {
            intersection: Intersection.Combine
            x: Math.floor(wifiConnectivityDetailShell.x)
            y: Math.floor(wifiConnectivityDetailShell.y)
            width: wifiConnectivityDetailShell.visible ? Math.ceil(wifiConnectivityDetailShell.width) : 0
            height: wifiConnectivityDetailShell.visible ? Math.ceil(wifiConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(bluetoothConnectivityDetailShell.x)
            y: Math.floor(bluetoothConnectivityDetailShell.y)
            width: bluetoothConnectivityDetailShell.visible ? Math.ceil(bluetoothConnectivityDetailShell.width) : 0
            height: bluetoothConnectivityDetailShell.visible ? Math.ceil(bluetoothConnectivityDetailShell.height) : 0
        }

        Region {
            intersection: Intersection.Combine
            x: Math.floor(powerConnectivityDetailShell.x)
            y: Math.floor(powerConnectivityDetailShell.y)
            width: powerConnectivityDetailShell.visible ? Math.ceil(powerConnectivityDetailShell.width) : 0
            height: powerConnectivityDetailShell.visible ? Math.ceil(powerConnectivityDetailShell.height) : 0
        }
    }
    readonly property real capsuleWindowHeight: {
        if (islandContainer.islandState === "settings_app" || islandContainer.settingsAppLayerVisible) {
            return root.screen ? root.screen.height : 1080;
        }
        return Math.ceil(effectiveIslandTopMargin + mainCapsule.targetHeight + 12);
    }
    readonly property real connectivityDetailWindowHeight: root.anyConnectivityDetailMounted
        ? Math.ceil(effectiveIslandTopMargin + root.connectivityDetailHeight + 12)
        : 0
    readonly property real overviewWindowHeight: root.overviewVisible
        ? Math.ceil(effectiveIslandTopMargin + root.overviewCapsuleHeight + 8)
        : 0
    readonly property real musicFloatingIslandHeight: musicFloatingIsland && musicFloatingIsland.visible
        ? Math.ceil(musicFloatingIsland.y + musicFloatingIsland.height + 12)
        : 0
    readonly property real headphonesFloatingIslandHeight: headphonesFloatingIsland && headphonesFloatingIsland.visible
        ? Math.ceil(headphonesFloatingIsland.y + headphonesFloatingIsland.height + 12)
        : 0
    readonly property real callFloatingIslandHeight: callFloatingIsland && callFloatingIsland.visible
        ? Math.ceil(callFloatingIsland.y + callFloatingIsland.height + 12)
        : 0
    readonly property real requestedWindowHeight: Math.max(
        root.notificationCenterWindowHeight,
        root.capsuleWindowHeight,
        root.connectivityDetailWindowHeight,
        root.overviewWindowHeight,
        Math.ceil(root.controlCenterWindowHeight),
        root.musicFloatingIslandHeight,
        root.headphonesFloatingIslandHeight,
        root.callFloatingIslandHeight
    )
    // Grow the layer surface immediately, but keep the old extent while the
    // capsule finishes its collapse animation. A later expansion interrupts
    // the pending shrink instead of letting a stale timer clip new content.
    property real retainedWindowHeight: 0
    implicitHeight: Math.max(root.requestedWindowHeight, root.retainedWindowHeight)

    function reconcileWindowHeight() {
        if (root.requestedWindowHeight >= root.retainedWindowHeight) {
            windowShrinkTimer.stop();
            root.retainedWindowHeight = root.requestedWindowHeight;
            return;
        }

        windowShrinkTimer.restart();
    }

    onRequestedWindowHeightChanged: root.reconcileWindowHeight()
    Component.onCompleted: {
        root.retainedWindowHeight = root.requestedWindowHeight;
        root.refreshWallpaperSources();
    }

    exclusiveZone: Math.ceil(root.baseExclusiveZone * root.exclusiveZoneProgress)
    WlrLayershell.layer: islandContainer.wallpaperPickerLayerVisible
        || islandContainer.applicationLauncherLayerVisible
        || islandContainer.clipboardLayerVisible
        || islandContainer.settingsAppLayerVisible
        || islandContainer.fileShelfLayerVisible
        || islandContainer.polkitLayerVisible
        || islandContainer.powerMenuLayerVisible
        ? WlrLayer.Overlay
        : WlrLayer.Top
    WlrLayershell.keyboardFocus: {
        if (islandContainer.polkitLayerVisible
                || islandContainer.controlCenterLayerVisible
                || islandContainer.powerMenuLayerVisible
                || islandContainer.wallpaperPickerLayerVisible
                || islandContainer.applicationLauncherLayerVisible
                || islandContainer.clipboardLayerVisible
                || islandContainer.settingsAppLayerVisible)
            return WlrKeyboardFocus.Exclusive;
        if (islandContainer.fileShelfLayerVisible)
            return WlrKeyboardFocus.OnDemand;
        // Keep keyboard focus on the overview until an overview action closes it.
        // Click-to-focus closes the overview before focusing the selected client.
        if (root.monitorFocused && root.overviewVisible)
            return WlrKeyboardFocus.Exclusive;
        if (islandContainer.expandedPlayerKeyboardFocusRequested)
            return WlrKeyboardFocus.Exclusive;
        if (root.monitorFocused && root.connectivityPromptActive)
            return WlrKeyboardFocus.OnDemand;
        return WlrKeyboardFocus.None;
    }
    function cfgVal(key, fallback) {
        if (localUserConfigFile.parsedData && localUserConfigFile.parsedData[key] !== undefined) {
            return localUserConfigFile.parsedData[key];
        }
        if (userConfig && userConfig[key] !== undefined) {
            return userConfig[key];
        }
        return fallback;
    }

    readonly property real effectiveIslandWidth: {
        if (dynamicConfig && dynamicConfig.islandWidth > 0) return dynamicConfig.islandWidth;
        let v = cfgVal("islandWidth", userConfig ? userConfig.islandWidth : 140);
        return (v !== undefined && !isNaN(Number(v)) && Number(v) > 0) ? Number(v) : 140;
    }
    readonly property real effectiveIslandHeight: {
        if (dynamicConfig && dynamicConfig.islandHeight > 0) return dynamicConfig.islandHeight;
        let v = cfgVal("islandHeight", userConfig ? userConfig.islandHeight : 40);
        return (v !== undefined && !isNaN(Number(v)) && Number(v) > 0) ? Number(v) : 40;
    }
    readonly property real effectiveIslandTopMargin: {
        if (dynamicConfig && dynamicConfig.islandTopMargin >= 0) return dynamicConfig.islandTopMargin;
        let v = cfgVal("islandTopMargin", userConfig ? userConfig.islandTopMargin : 8);
        return (v !== undefined && !isNaN(Number(v)) && Number(v) >= 0) ? Number(v) : 8;
    }
    readonly property real effectiveIslandBackgroundOpacity: {
        if (dynamicConfig && dynamicConfig.islandBackgroundOpacity !== undefined) return dynamicConfig.islandBackgroundOpacity;
        let v = cfgVal("islandBackgroundOpacity", userConfig ? userConfig.islandBackgroundOpacity : 92);
        return (v !== undefined && !isNaN(Number(v))) ? Math.max(0, Math.min(100, Number(v))) : 92;
    }
    readonly property real effectiveIslandPositionX: {
        if (dynamicConfig && dynamicConfig.islandPositionX !== undefined) return dynamicConfig.islandPositionX;
        let v = cfgVal("islandPositionX", userConfig ? userConfig.islandPositionX : 50);
        return (v !== undefined && !isNaN(Number(v))) ? Number(v) : 50;
    }
    readonly property real effectiveIslandExclusiveZone: {
        if (dynamicConfig && dynamicConfig.islandExclusiveZone !== undefined && dynamicConfig.islandExclusiveZone > 0)
            return dynamicConfig.islandExclusiveZone;
        let v = cfgVal("islandExclusiveZone", userConfig ? userConfig.islandExclusiveZone : 48);
        let num = Number(v);
        return (!isNaN(num) && num > 0) ? num : (root.effectiveIslandHeight + root.effectiveIslandTopMargin);
    }
    readonly property real effectiveIslandCornerRadius: {
        if (dynamicConfig && dynamicConfig.islandCornerRadius > 0) return dynamicConfig.islandCornerRadius;
        let v = cfgVal("islandCornerRadius", 0);
        return (v !== undefined && !isNaN(Number(v)) && Number(v) > 0) ? Number(v) : (effectiveIslandHeight / 2);
    }

    readonly property string iconFontFamily: (dynamicConfig && dynamicConfig.iconFontFamily !== "") ? dynamicConfig.iconFontFamily : cfgVal("iconFontFamily", userConfig ? userConfig.iconFontFamily : "JetBrainsMono Nerd Font")
    readonly property string textFontFamily: (dynamicConfig && dynamicConfig.textFontFamily !== "") ? dynamicConfig.textFontFamily : cfgVal("textFontFamily", userConfig ? userConfig.textFontFamily : "Google Sans Flex")
    readonly property string heroFontFamily: (dynamicConfig && dynamicConfig.heroFontFamily !== "") ? dynamicConfig.heroFontFamily : cfgVal("heroFontFamily", userConfig ? userConfig.heroFontFamily : "Google Sans Flex")
    readonly property string timeFontFamily: (dynamicConfig && dynamicConfig.timeFontFamily !== "") ? dynamicConfig.timeFontFamily : cfgVal("timeFontFamily", userConfig ? userConfig.timeFontFamily : "Google Sans Flex")
    readonly property int bodyFontSize: Number(cfgVal("bodyFontSize", userConfig ? userConfig.bodyFontSize : 14)) || 14
    readonly property int titleFontSize: Number(cfgVal("titleFontSize", userConfig ? userConfig.titleFontSize : 16)) || 16
    readonly property int iconFontSize: Number(cfgVal("iconFontSize", userConfig ? userConfig.iconFontSize : 16)) || 16
    readonly property string defaultSplitIcon: "\ud83c\udfa7"
    readonly property string notificationStatusIcon: "\uf0f3"
    readonly property real overviewWindowCornerRadius: 12
    readonly property int dynamicIslandAcceptedButtons: userConfig.mouseButtonsMask([
        1,
        userConfig.dynamicIslandPrimaryButton,
        userConfig.dynamicIslandSecondaryButton
    ])
    readonly property int configuredHoverExpandAction: {
        let action = undefined;
        if (localUserConfigFile.parsedData && localUserConfigFile.parsedData.hoverExpandAction !== undefined) {
            action = Number(localUserConfigFile.parsedData.hoverExpandAction);
        } else if (userConfig && userConfig.hoverExpandAction !== undefined) {
            action = Number(userConfig.hoverExpandAction);
        }
        return (action === undefined || isNaN(action)) ? 2 : Math.max(0, Math.min(2, Math.round(action)));
    }
    readonly property real baseExclusiveZone: effectiveIslandExclusiveZone
    readonly property bool hoverExpandEnabled: {
        if (localUserConfigFile.parsedData && localUserConfigFile.parsedData.hoverExpandEnabled !== undefined) {
            return Boolean(localUserConfigFile.parsedData.hoverExpandEnabled);
        }
        if (userConfig && userConfig.hoverExpandEnabled !== undefined) {
            return Boolean(userConfig.hoverExpandEnabled);
        }
        return configuredHoverExpandAction > 0;
    }
    readonly property bool topGestureInputActive: false
    readonly property bool autoHideRuntimeEnabled: !shellRootController
        || shellRootController.islandAutoHideRuntimeEnabled === undefined
        || !!shellRootController.islandAutoHideRuntimeEnabled
    readonly property bool autoHideEnabled: Boolean(cfgVal("islandAutoHideEnabled", userConfig ? userConfig.islandAutoHideEnabled : false)) && autoHideRuntimeEnabled
    readonly property bool autoHideRestingState: islandContainer.islandState === "normal"
        || islandContainer.islandState === "custom"
        || islandContainer.islandState === "lyrics"
    readonly property bool autoHideCanHideNow: autoHideEnabled
        && autoHideRestingState
        && !root.overviewVisible
        && !root.connectivityPromptActive
        && !root.anyConnectivityDetailMounted
    readonly property bool autoHideMustShow: !autoHideRestingState
        || root.overviewVisible
        || root.connectivityPromptActive
        || root.anyConnectivityDetailMounted
    readonly property bool autoHideTargetVisible: autoHideMustShow
        || (!autoHideForcedHidden && (!autoHideEnabled || autoHideVisible))
    readonly property bool autoHideSuppressesTransientReveal: (autoHideEnabled || autoHideForcedHidden)
        && !autoHideTargetVisible
    property real autoHideProgress: autoHideTargetVisible ? 1 : 0
    readonly property bool exclusiveZoneTargetActive: (!autoHideEnabled && autoHideTargetVisible)
        || (autoHideRevealSource === "edge" && autoHideTargetVisible)
        || islandContainer.notificationLayerVisible
        || islandContainer.reloadLayerVisible
    property real exclusiveZoneProgress: exclusiveZoneTargetActive ? 1 : 0
    readonly property real autoHideRevealWidth: Math.min(root.width, Math.max(root.effectiveIslandWidth + 120, 240))
    readonly property real autoHideRevealHeight: autoHideEnabled ? 10 : 0
    readonly property real autoHideRevealX: Math.max(
        0,
        Math.min(root.width - autoHideRevealWidth, root.width * root.effectiveIslandPositionX / 100 - autoHideRevealWidth / 2)
    )
    readonly property real topGestureInputX: autoHideEnabled ? autoHideRevealX : 0
    readonly property real topGestureInputWidth: topGestureInputActive
        ? (autoHideEnabled ? autoHideRevealWidth : root.width)
        : 0
    readonly property real topGestureInputHeight: topGestureInputActive
        ? (autoHideEnabled ? autoHideRevealHeight : root.baseExclusiveZone)
        : 0
    readonly property real overviewCapsuleWidth: islandContainer.overviewView ? islandContainer.overviewView.width : 760
    readonly property real overviewCapsuleHeight: islandContainer.overviewView ? islandContainer.overviewView.height : 308
    readonly property real overviewCapsuleRadius: islandContainer.overviewView
        ? islandContainer.overviewView.largeWorkspaceRadius + islandContainer.overviewView.outerPadding
        : 44
    readonly property color overviewCapsuleColor: islandContainer.overviewView
        ? islandContainer.overviewView.cardColor
        : StyleTokens.overviewCard
    readonly property color overviewCapsuleBorderColor: islandContainer.overviewView
        ? islandContainer.overviewView.cardBorderColor
        : StyleTokens.overviewBorder
    property bool wifiConnectivityDetailOpen: false
    property bool wifiConnectivityDetailMounted: false
    property bool bluetoothConnectivityDetailOpen: false
    property bool bluetoothConnectivityDetailMounted: false
    property bool powerConnectivityDetailOpen: false
    property bool powerConnectivityDetailMounted: false
    readonly property bool anyConnectivityDetailMounted: wifiConnectivityDetailMounted || bluetoothConnectivityDetailMounted || powerConnectivityDetailMounted
    readonly property real connectivityDetailHeight: 404
    readonly property real controlCenterMaximumExtraHeight: controlCenterLoader.item
        ? controlCenterLoader.item.controlCenterMaximumExtraHeight
        : 120
    readonly property real controlCenterWindowHeight: islandContainer.controlCenterLayerVisible
        ? root.effectiveIslandTopMargin + (controlCenterLoader.item ? controlCenterLoader.item.controlCenterPreferredHeight : 450) + 60
        : 0

    readonly property real notificationCenterWindowHeight: islandContainer.notificationCenterLayerVisible
        ? root.effectiveIslandTopMargin + (notificationCenterLoader.item ? notificationCenterLoader.item.contentHeight : 400) + 6
        : 0
    readonly property real connectivityDetailGap: 16
    readonly property int connectivityDetailAnimationDuration: 360

    readonly property string effectiveWallpaperPath: {
        if (root.awwwWallpaperPath !== "")
            return root.awwwWallpaperPath;
        if (walWallpaperFile.wallpaperPath !== "")
            return walWallpaperFile.wallpaperPath;
        if (pywalColors.wallpaper !== "")
            return pywalColors.wallpaper;
        if (root.wallpaperPickerActiveWallpaper !== "")
            return root.wallpaperPickerActiveWallpaper;
        if (currentWallpaperFile.wallpaperPath !== "")
            return currentWallpaperFile.wallpaperPath;
        if (userConfig.wallpaperPath !== "")
            return userConfig.wallpaperPath;
        return root.homeDir + "/Sfondi/B & W Window.png";
    }

    onEffectiveWallpaperPathChanged: {
        console.log("[DynamicIsland] Effective wallpaper path changed:", effectiveWallpaperPath);
        root.wallpaperPickerActiveWallpaper = effectiveWallpaperPath;
        prewarmWallpaperCache();
    }

    readonly property string effectiveWallpaperUrl: {
        const wp = root.effectiveWallpaperPath;
        if (wp === "") return "";
        return wp.startsWith("file://") ? wp : ("file://" + encodeURI(wp));
    }

    readonly property string overviewWallpaperSource: {
        if (overviewWallpaperCache.effectiveSource !== "")
            return overviewWallpaperCache.effectiveSource;
        return root.effectiveWallpaperUrl;
    }

    property string wallpaperPickerActiveWallpaper: userConfig.wallpaperPath

    Behavior on autoHideProgress {
        NumberAnimation {
            duration: root.autoHideTargetVisible ? 120 : 300
            easing.type: root.autoHideTargetVisible ? Easing.OutCubic : Easing.InCubic
        }
    }

    Behavior on exclusiveZoneProgress {
        NumberAnimation {
            duration: root.exclusiveZoneTargetActive ? 120 : 300
            easing.type: root.exclusiveZoneTargetActive ? Easing.OutCubic : Easing.InCubic
        }
    }

    function setAutoHideRevealSource(source) {
        if (source === undefined || source === null)
            return;

        const nextSource = String(source);
        autoHideRevealSource = nextSource === "edge" || nextSource === "state" || nextSource === "manual"
            ? nextSource
            : "manual";
    }

    function showAutoHiddenIsland(source) {
        setAutoHideRevealSource(source);
        autoHideForcedHidden = false;
        if (!autoHideEnabled) {
            autoHideHideTimer.stop();
            autoHideVisible = true;
            return;
        }

        autoHideHideTimer.stop();
        autoHideVisible = true;
    }

    function scheduleAutoHide() {
        if (!autoHideEnabled) {
            autoHideHideTimer.stop();
            autoHideVisible = true;
            return;
        }

        if (!autoHideCanHideNow) {
            autoHideHideTimer.stop();
            showAutoHiddenIsland("state");
            return;
        }

        if (autoHidePointerInside) {
            autoHideHideTimer.stop();
            return;
        }

        autoHideHideTimer.interval = Math.max(100, Math.min(10000, userConfig.islandAutoHideDelayMs));
        autoHideHideTimer.restart();
    }

    function hideAutoHiddenIsland(force) {
        if (force === undefined) force = false;
        if (!autoHideEnabled) {
            autoHideHideTimer.stop();
            if (!force && autoHideMustShow)
                return;
            autoHideForcedHidden = true;
            autoHideRevealSource = "none";
            autoHideVisible = false;
            return;
        }

        if (!force && (!autoHideCanHideNow || autoHidePointerInside))
            return;

        autoHideHideTimer.stop();
        autoHideForcedHidden = false;
        autoHideRevealSource = "none";
        autoHideVisible = false;
    }

    function toggleAutoHiddenIsland() {
        if (autoHideTargetVisible)
            hideAutoHiddenIsland(false);
        else
            showAutoHiddenIsland("manual");
    }

    function showIslandWindow() {
        showAutoHiddenIsland("manual");
    }

    function hideIslandWindow() {
        autoHidePointerInside = false;
        hideAutoHiddenIsland(false);
    }

    function toggleIslandWindow() {
        toggleAutoHiddenIsland();
    }

    function refreshAutoHideWindow() {
        if (autoHideEnabled)
            scheduleAutoHide();
        else
            showAutoHiddenIsland("manual");
    }

    function beginOverviewOpening() {
        if (!overviewPreparing) return;
        if (overviewLoader.status !== Loader.Ready || !overviewVisualReady) return;
        overviewPreloading = false;
        overviewPhase = "opening";
        overviewRevealTimer.restart();
    }

    function prepareOverview() {
        if (compositorIsNiri) return;
        if (overviewPhase !== "closed") return;
        root.refreshWallpaperSources();
        overviewUnloadGraceTimer.stop();
        overviewPreloading = true;
        overviewPreloadExpireTimer.restart();
    }

    function cancelPreparedOverview() {
        if (compositorIsNiri) return;
        if (overviewPhase !== "closed") return;
        overviewPreloadExpireTimer.stop();
        overviewPreloading = false;
    }

    function openOverview() {
        if (compositorIsNiri)
            return;
        if (overviewPhase !== "closed") return;
        root.refreshWallpaperSources();
        overviewUnloadGraceTimer.stop();
        overviewPreloadExpireTimer.stop();
        overviewPreloading = true;
        overviewPhase = "preparing";
        if (overviewLoader.status === Loader.Ready) {
            beginOverviewOpening();
        }
    }

    function closeOverview() {
        if (compositorIsNiri)
            return;
        if (!overviewMounted) return;
        if (overviewLoader.status === Loader.Ready)
            overviewUnloadGraceTimer.restart();
        overviewRevealTimer.stop();
        overviewPreloadExpireTimer.stop();
        islandContainer.restoreRestingCapsule(true);
        overviewPreloading = false;
        overviewPhase = "closed";
    }

    function closeOverviewEverywhere() {
        if (shellRootController && shellRootController.closeOverviewAll) {
            shellRootController.closeOverviewAll();
            return;
        }

        closeOverview();
    }

    function setConnectivityDetailVisible(kind, open) {
        if (!islandContainer.controlCenterLayerVisible && open) {
            showControlCenterWindow();
        }
        if (controlCenterLoader.item && controlCenterLoader.item.setConnectivityPanelOpen) {
            controlCenterLoader.item.setConnectivityPanelOpen(kind, open);
        }
    }

    function closeAllConnectivityDetails() {
        if (controlCenterLoader.item && controlCenterLoader.item.closeConnectivityPanels) {
            controlCenterLoader.item.closeConnectivityPanels();
        }
    }

    function openOverviewEverywhere() {
        if (shellRootController && shellRootController.openOverviewAll) {
            shellRootController.openOverviewAll();
            return;
        }

        openOverview();
    }

    function prepareOverviewEverywhere() {
        if (shellRootController && shellRootController.prepareOverviewAll) {
            shellRootController.prepareOverviewAll();
            return;
        }

        prepareOverview();
    }

    function cancelPreparedOverviewEverywhere() {
        if (shellRootController && shellRootController.cancelPreparedOverviewAll) {
            shellRootController.cancelPreparedOverviewAll();
            return;
        }

        cancelPreparedOverview();
    }

    function toggleOverviewEverywhere() {
        if (compositorIsNiri)
            return;

        if (shellRootController && shellRootController.toggleOverviewAll) {
            shellRootController.toggleOverviewAll();
            return;
        }

        if (overviewMounted)
            closeOverviewEverywhere();
        else
            openOverviewEverywhere();
    }

    function prewarmWallpaperCache() {
        overviewWallpaperCache.prewarm();
    }

    function handleWallpaperApplySucceeded(filePath) {
        wallpaperPickerActiveWallpaper = filePath;
        if (shellRootController && shellRootController.refreshOverviewWallpaperCaches)
            shellRootController.refreshOverviewWallpaperCaches(filePath);
        else
            prewarmWallpaperCache();
        refreshWallpaperSources();
    }

    function showReload(failed, errorString) {
        islandContainer.showReloadCapsule(failed, errorString);
    }

    function showNotification(appName, summary, body, icon, customColor) {
        islandContainer.showNotificationCapsule(appName, summary, body, icon, customColor);
    }

    function showCharging(capacity, isCharging) {
        islandContainer.showChargingCapsule(capacity, isCharging);
    }

    function showLowBattery(capacity) {
        islandContainer.showLowBatteryCapsule(capacity);
    }

    function showSilentRing(isMuted) {
        islandContainer.showSilentRingCapsule(isMuted);
    }

    function showDiscordCall(callerName, subtitle, avatarUrl) {
        islandContainer.showDiscordCallCapsule(callerName, subtitle, avatarUrl);
    }

    function showDiscordOngoingCall(callerName, subtitle, avatarUrl) {
        islandContainer.abortSideTransientMode();
        islandContainer.clearTransientCapsule();
        islandContainer.discordCallerName = callerName || "St0rm";
        islandContainer.discordCallSubtitle = subtitle || "00:00";
        islandContainer.discordCallAvatarUrl = avatarUrl || "";
        islandContainer.discordCallOngoing = true;
        islandContainer.discordCallActive = true;
        islandContainer.smartRestoreState();
        islandContainer.stopAutoHideTimer();
    }

    Process {
        id: discordCallActionProc
        property string action: "accept"
        command: ["python3", root.homeDir + "/.config/quickshell/dynamic-island/scripts/discord_call_action.py", action]
        running: false
    }

    function acceptDiscordCall() {
        islandContainer.discordCallActive = true;
        islandContainer.discordCallOngoing = true;
        islandContainer.discordCallSubtitle = "00:00";
        islandContainer.smartRestoreState();
        islandContainer.stopAutoHideTimer();
        discordCallActionProc.action = "accept";
        discordCallActionProc.running = false;
        discordCallActionProc.running = true;
    }

    function declineDiscordCall() {
        islandContainer.discordCallActive = false;
        islandContainer.discordCallOngoing = false;
        islandContainer.discordCallAvatarUrl = "";
        islandContainer.closeDiscordCallCapsule();
        discordCallActionProc.action = "decline";
        discordCallActionProc.running = false;
        discordCallActionProc.running = true;
    }

    function focusDiscordWindow() {
        discordCallActionProc.action = "focus";
        discordCallActionProc.running = false;
        discordCallActionProc.running = true;
    }

    function setDiscordCallOngoing() {
        islandContainer.discordCallActive = true;
        islandContainer.discordCallOngoing = true;
        islandContainer.discordCallSubtitle = "00:00";
        if (islandContainer.islandState === "discord_call") {
            islandContainer.smartRestoreState();
        }
        islandContainer.stopAutoHideTimer();
    }

    function closeDiscordCall() {
        islandContainer.closeDiscordCallCapsule();
    }

    function showOsdWindow(icon, progress, customText) {
        islandContainer.showTransientCapsule(icon, progress, customText);
        showAutoHiddenIsland("state");
    }

    function showWorkspaceWindow(wsId) {
        islandContainer.showWorkspaceCapsule(wsId);
        showAutoHiddenIsland("state");
    }

    function setConnectivityDetailWindow(kind, open) {
        setConnectivityDetailVisible(kind, open);
    }

    function showClockWindow() {
        islandContainer.showTimeCapsule();
        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }
    function showCustomInfoWindow() {
        islandContainer.showCustomCapsule();
        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }
    function showLyricsWindow() {
        islandContainer.showLyricsCapsule();
        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }

    function swipeRightWindow() {
        if (islandContainer.restingState === "lyrics")
            islandContainer.showTimeCapsule();
        else if (islandContainer.restingState === "normal") {
            if (islandContainer.hasCustomLeftItems)
                islandContainer.showCustomCapsule();
            else
                islandContainer.showLyricsCapsule();
        }
        else
            islandContainer.showLyricsCapsule();

        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }

    function swipeLeftWindow() {
        if (islandContainer.restingState === "custom")
            islandContainer.showTimeCapsule();
        else if (islandContainer.restingState === "normal")
            islandContainer.showLyricsCapsule();
        else if (islandContainer.hasCustomLeftItems)
            islandContainer.showCustomCapsule();
        else
            islandContainer.showTimeCapsule();

        showAutoHiddenIsland("manual");
        scheduleAutoHide();
    }

    function togglePlayerWindow() {
        if (musicFloatingIsland && musicFloatingIsland.hasTrack) {
            musicFloatingIsland.isExpanded = !musicFloatingIsland.isExpanded;
            return;
        }
        if (islandContainer.islandState === "expanded")
            islandContainer.smartRestoreState();
    }

    function showTimerWindow() {
        islandContainer.showExpandedTimerPage();
    }

    function toggleControlCenterWindow() {
        if (islandContainer.islandState === "control_center")
            islandContainer.smartRestoreState();
        else {
            islandContainer.showControlCenter();
            if (controlCenterLoader.item)
                controlCenterLoader.item.powerViewActive = false;
        }
    }

    function togglePowerMenuWindow() {
        if (islandContainer.islandState === "power_menu")
            islandContainer.smartRestoreState();
        else
            islandContainer.showPowerMenu();
    }

    function toggleNotificationCenterWindow() {
        if (islandContainer.islandState === "notification_center")
            islandContainer.smartRestoreState();
        else
            islandContainer.showNotificationCenter();
    }

    function toggleWallpaperPickerWindow() {
        if (islandContainer.islandState === "wallpaper_picker")
            islandContainer.smartRestoreState();
        else
            islandContainer.showWallpaperPicker();
    }

    function toggleApplicationLauncherWindow() {
        if (islandContainer.islandState === "application_launcher")
            islandContainer.smartRestoreState();
        else
            islandContainer.showApplicationLauncher();
    }

    function toggleClipboardWindow() {
        if (islandContainer.islandState === "clipboard")
            islandContainer.smartRestoreState();
        else
            islandContainer.showClipboard();
    }

    function showClipboardWindow() {
        islandContainer.showClipboard();
    }

    function toggleSettingsAppWindow() {
        if (islandContainer.islandState === "settings_app")
            islandContainer.smartRestoreState();
        else
            islandContainer.showSettingsApp();
    }

    function showSettingsAppWindow() {
        islandContainer.showSettingsApp();
    }

    function setSettingsCategory(catIndex) {
        if (settingsAppLoader.item)
            settingsAppLoader.item.selectedCategoryIndex = catIndex;
    }

    function setSettingsAppCategory(catIndex) {
        setSettingsCategory(catIndex);
    }

    function setSettingsSubView(sub) {
        if (settingsAppLoader.item)
            settingsAppLoader.item.controlCenterSubView = sub;
    }

    function setSettingsAppSubView(sub) {
        setSettingsSubView(sub);
    }

    function openSettingsFontBrowser(target) {
        if (islandContainer.islandState !== "settings_app") {
            islandContainer.showSettingsApp();
        }
        if (settingsAppLoader.item) {
            settingsAppLoader.item.selectedCategoryIndex = 2;
            settingsAppLoader.item.openFontBrowser(target || "global");
        }
    }

    function toggleFileShelfWindow() {
        if (islandContainer.islandState === "file_shelf")
            islandContainer.smartRestoreState();
        else
            islandContainer.showFileShelf(true);
    }

    function showPolkitPrompt() {
        islandContainer.showPolkitPrompt();
    }

    function closePolkitPrompt() {
        islandContainer.closePolkitPrompt();
    }

    function handlePolkitFinished() {
        if (polkitLoader.item && polkitLoader.item.isVerifying && !polkitLoader.item.isFailed) {
            islandContainer.polkitSuccessMorph = true;
            polkitLoader.item.markSuccess();
        } else {
            closePolkitPrompt();
        }
    }

    onOverviewVisibleChanged: {
        if (overviewVisible && monitorFocused) overviewFocusTimer.restart();
        if (overviewVisible)
            showAutoHiddenIsland("state");
        else
            scheduleAutoHide();
    }
    onConnectivityPromptActiveChanged: {
        if (connectivityPromptActive && monitorFocused)
            connectivityPromptFocusTimer.restart();
        if (connectivityPromptActive)
            showAutoHiddenIsland("state");
        else
            scheduleAutoHide();
    }
    onAutoHideEnabledChanged: {
        if (autoHideEnabled)
            scheduleAutoHide();
        else
            showAutoHiddenIsland("manual");
    }
    onAutoHideCanHideNowChanged: {
        if (autoHideCanHideNow)
            scheduleAutoHide();
        else
            showAutoHiddenIsland("state");
    }
    onOverviewVisualReadyChanged: {
        if (overviewVisualReady) beginOverviewOpening();
    }
    onOverviewContentVisibleChanged: {
        if (overviewContentVisible && monitorFocused)
            overviewFocusTimer.restart();
    }
    onMonitorFocusedChanged: {
        if (overviewVisible && monitorFocused) overviewFocusTimer.restart();
        if (connectivityPromptActive && monitorFocused) connectivityPromptFocusTimer.restart();
    }

    Timer {
        id: overviewFocusTimer
        interval: 0
        repeat: false
        onTriggered: root.focusOverview()
    }

    Timer {
        id: connectivityPromptFocusTimer
        interval: 0
        repeat: false
        onTriggered: islandContainer.forceActiveFocus()
    }

    Timer {
        id: expandedPlayerFocusTimer
        interval: 0
        repeat: false
        onTriggered: root.focusExpandedPlayer()
    }

    Timer {
        id: windowShrinkTimer
        interval: 1000
        repeat: false
        onTriggered: root.retainedWindowHeight = root.requestedWindowHeight
    }

    Timer {
        id: autoHideHideTimer
        interval: Math.max(100, Math.min(10000, userConfig.islandAutoHideDelayMs))
        repeat: false
        onTriggered: root.hideAutoHiddenIsland(false)
    }

    function focusWallpaperPicker() {
        islandContainer.forceActiveFocus();
        if (wallpaperPickerLoader.item && wallpaperPickerLoader.item.grabKeyboardFocus)
            wallpaperPickerLoader.item.grabKeyboardFocus();
    }

    function focusOverview() {
        islandContainer.forceActiveFocus();
        const view = islandContainer.overviewView;
        if (view && view.grabKeyboardFocus)
            view.grabKeyboardFocus();
    }

    function focusExpandedPlayer() {
        islandContainer.requestExpandedPlayerKeyboardFocus();
        if (expandedPlayerLoader.item && expandedPlayerLoader.item.grabKeyboardFocus)
            expandedPlayerLoader.item.grabKeyboardFocus();
    }

    function focusApplicationLauncher() {
        islandContainer.forceActiveFocus();
        if (applicationLauncherLoader.item && applicationLauncherLoader.item.grabKeyboardFocus)
            applicationLauncherLoader.item.grabKeyboardFocus();
    }

    function focusClipboard() {
        islandContainer.forceActiveFocus();
        if (clipboardLoader.item && clipboardLoader.item.grabKeyboardFocus)
            clipboardLoader.item.grabKeyboardFocus();
        else if (clipboardLoader.item)
            clipboardLoader.item.forceActiveFocus();
    }

    function focusSettingsApp() {
        islandContainer.forceActiveFocus();
        if (settingsAppLoader.item && settingsAppLoader.item.forceActiveFocus)
            settingsAppLoader.item.forceActiveFocus();
    }

    function focusFileShelf() {
        islandContainer.forceActiveFocus();
        if (fileShelfLoader.item && fileShelfLoader.item.grabKeyboardFocus)
            fileShelfLoader.item.grabKeyboardFocus();
    }

    function focusPolkit() {
        islandContainer.forceActiveFocus();
        if (polkitLoader.item) {
            polkitLoader.item.forceActiveFocus();
            if (polkitLoader.item.grabKeyboardFocus)
                polkitLoader.item.grabKeyboardFocus();
        }
    }

    function dragCarriesFiles(dragEvent) {
        if (!dragEvent)
            return false;
        if (dragEvent.hasUrls)
            return true;

        const formats = dragEvent.formats || [];
        return formats.indexOf("text/uri-list") >= 0
            || formats.indexOf("x-special/gnome-copied-files") >= 0;
    }

    function addFilesFromDrop(dropEvent) {
        if (!dropEvent)
            return 0;

        let added = 0;
        if (dropEvent.hasUrls)
            added += FileShelf.addUrls(dropEvent.urls);

        const formats = dropEvent.formats || [];
        if (added === 0 && formats.indexOf("text/uri-list") >= 0)
            added += FileShelf.addUriList(dropEvent.getDataAsString("text/uri-list"));
        if (added === 0 && formats.indexOf("x-special/gnome-copied-files") >= 0)
            added += FileShelf.addUriList(dropEvent.getDataAsString("x-special/gnome-copied-files"));
        return added;
    }

    Timer {
        id: overviewRevealTimer
        interval: 0
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "opening") root.overviewPhase = "open";
        }
    }

    Timer {
        id: overviewPreloadExpireTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (root.overviewPhase === "closed")
                root.overviewPreloading = false;
        }
    }

    Timer {
        id: overviewUnloadGraceTimer
        interval: 260
        repeat: false
    }

    Timer {
        id: wifiConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.wifiConnectivityDetailMounted = false
    }

    Timer {
        id: bluetoothConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.bluetoothConnectivityDetailMounted = false
    }

    Timer {
        id: powerConnectivityDetailCleanupTimer
        interval: root.connectivityDetailAnimationDuration
        repeat: false
        onTriggered: root.powerConnectivityDetailMounted = false
    }

    OverviewWallpaperCacheController {
        id: overviewWallpaperCache

        active: root.overviewLoaderActive
        wallpaperPath: root.effectiveWallpaperPath
        hyprMonitor: root.hyprMonitor
        screenObject: root.screen
    }

    IslandClock {
        id: timeObj
        clockFormat: userConfig.clockFormat
    }

    // --- 灵动岛主容器与全局状态 ---
    FocusScope {
        id: islandContainer
        anchors.fill: parent
        focus: controlCenterLayerVisible
            || wallpaperPickerLayerVisible
            || applicationLauncherLayerVisible
            || clipboardLayerVisible
            || settingsAppLayerVisible
            || fileShelfLayerVisible
            || polkitLayerVisible
            || expandedPlayerKeyboardFocusRequested
            || (root.monitorFocused && (root.overviewVisible || root.connectivityPromptActive))

        property string islandState: "normal"
        property bool reloadFailed: false
        property string reloadErrorString: ""
        readonly property bool reloadLayerVisible: !root.overviewVisible && islandState === "reload"
        property bool polkitSuccessMorph: false
        property string splitIcon: root.defaultSplitIcon
        property real osdProgress: -1.0
        property bool osdProgressAnimationEnabled: true
        property string osdCustomText: ""
        property int currentWs: root.currentMonitorWorkspaceId > 0 ? root.currentMonitorWorkspaceId : 1
        readonly property int batteryCapacity: systemState.batteryCapacity
        readonly property bool isCharging: systemState.isCharging
        readonly property real currentVolume: systemState.currentVolume
        readonly property bool isMuted: systemState.isMuted
        readonly property real currentBrightness: systemState.currentBrightness
        readonly property real currentCpuUsage: systemState.currentCpuUsage
        readonly property real currentRamUsage: systemState.currentRamUsage
        property string notificationAppName: ""
        property string notificationSummary: ""
        property string notificationBody: ""
        property string notificationIcon: ""
        property color notificationIconColor: "#f4f5f7"
        property bool notificationExpanded: false
        property string batteryAlertMode: "charging"
        property int batteryAlertCapacity: 100
        property bool silentRingIsMuted: false
        property bool pendingPowerView: false
        property bool controlCenterHadPointer: false
        readonly property bool controlCenterPointerInside: Boolean(
            (mainCapsuleHoverHandler && mainCapsuleHoverHandler.hovered)
            || (wifiConnectivityDetailShell && wifiConnectivityDetailShell.open && wifiConnectivityDetailShell.hovered)
            || (bluetoothConnectivityDetailShell && bluetoothConnectivityDetailShell.open && bluetoothConnectivityDetailShell.hovered)
            || (powerConnectivityDetailShell && powerConnectivityDetailShell.open && powerConnectivityDetailShell.hovered)
        )

        onControlCenterPointerInsideChanged: {
            if (islandState === "control_center") {
                if (controlCenterPointerInside) {
                    controlCenterHadPointer = true;
                    controlCenterAutoCollapseTimer.stop();
                } else if (controlCenterHadPointer) {
                    controlCenterAutoCollapseTimer.restart();
                }
            }
        }

        onIslandStateChanged: {
            controlCenterAutoCollapseTimer.stop();
            if (islandState === "control_center") {
                controlCenterHadPointer = controlCenterPointerInside;
            } else {
                controlCenterHadPointer = false;
            }
        }
        property string discordCallerName: "Discord Call"
        property string discordCallSubtitle: "Chiamata in arrivo..."
        property string discordCallAvatarUrl: ""
        property bool discordCallOngoing: false
        property bool discordCallActive: false
        property var bluetoothExpandedDevice: null
        property var notificationHistoryModel: ListModel {}
        readonly property var cavaLevels: systemState.cavaLevels
        property real swipeTransitionProgress: 0
        property string workspaceOriginSide: "none"
        property string splitOriginSide: "none"
        property string restingState: "normal"
        property bool expandedByPlayerAutoOpen: false
        property real customCapsuleWidth: 220
        property real lyricsCapsuleWidth: 220
        property bool sideSwipeSettling: false
        property bool hoverExpandedActive: false
        property bool expandedPlayerKeyboardFocusRequested: false
        property bool openTimerPageWhenExpanded: false
        property int timerSelectedHours: 0
        property int timerSelectedMinutes: 5
        property int timerTotalSeconds: 300
        property int timerRemainingSeconds: 0
        property bool timerRunning: false
        property bool timerActive: false
        property bool timerCompletionAnimating: false
        property real timerCompletionPulse: 0
        property real timerCompletionFlash: 0
        property bool fileShelfOpenedManually: false
        readonly property int defaultAutoHideInterval: 1250
        readonly property int notificationAutoHideInterval: 4200
        readonly property int bluetoothExpandedAutoHideInterval: 2500
        readonly property int swipeAnimationDuration: 220
        readonly property real timerProgress: timerActive && timerTotalSeconds > 0
            ? Math.max(0, Math.min(1, timerRemainingSeconds / timerTotalSeconds))
            : 0
        readonly property bool timerBubbleWanted: (timerActive && timerRemainingSeconds > 0 || timerCompletionAnimating)
            && !root.overviewVisible
            && (islandState === "normal" || islandState === "lyrics" || islandState === "custom")
        readonly property bool fileShelfBubbleWanted: FileShelf.count > 0
            && !root.overviewVisible
            && (islandState === "normal" || islandState === "lyrics" || islandState === "custom")
        readonly property bool fileShelfCanAutoOpen: !root.overviewVisible
            && (islandState === "normal" || islandState === "lyrics" || islandState === "custom")
        readonly property bool blocksTransientSplit: islandState === "expanded"
            || islandState === "bluetooth_expanded"
            || islandState === "control_center"
            || islandState === "power_menu"
            || islandState === "notification"
            || islandState === "reload"
            || islandState === "wallpaper_picker"
            || islandState === "application_launcher"
            || islandState === "clipboard"
            || islandState === "settings_app"
            || islandState === "file_shelf"
            || islandState === "polkit"
            || islandState === "charging"
            || islandState === "silent_ring"
            || islandState === "discord_call"
        readonly property bool splitShowsProgress: islandState === "split" && osdProgress >= 0
        readonly property bool splitShowsText: islandState === "split" && osdProgress < 0 && osdCustomText !== ""
        readonly property bool splitShowsIconOnly: islandState === "split" && osdProgress < 0 && osdCustomText === ""
        readonly property bool splitUsesExtendedLayout: splitShowsProgress || splitShowsText
        readonly property real splitCapsuleWidth: splitShowsProgress ? 248 : (splitShowsText ? 220 : root.effectiveIslandWidth)
        readonly property bool canShowSideSwipe: false
        readonly property real rightSwipeProgress: Math.max(0, swipeTransitionProgress)
        readonly property var customLeftItems: systemState.customLeftItems
        readonly property bool hasCustomLeftItems: systemState.hasCustomLeftItems
        readonly property bool customSwipeVisible: !root.overviewVisible
            && hasCustomLeftItems
            && (
                capsuleMouseArea.sideSwipeInteractive
                ? swipeTransitionProgress < 0
                : (
                    islandState === "custom"
                    || (islandState === "normal" && swipeTransitionProgress < 0)
                    || (islandState === "split" && splitOriginSide === "left")
                    || (islandState === "long_capsule"
                        && (workspaceOriginSide === "left" || swipeTransitionProgress < 0))
                )
            )
        readonly property bool lyricsSwipeVisible: !root.overviewVisible && (
            capsuleMouseArea.sideSwipeInteractive
            ? swipeTransitionProgress >= 0
            : (
                islandState === "lyrics"
                || (islandState === "normal" && swipeTransitionProgress >= 0)
                || (islandState === "split" && splitOriginSide === "right")
                || (islandState === "long_capsule"
                    && (workspaceOriginSide === "right" || swipeTransitionProgress > 0))
            )
        )
        readonly property bool expandedLayerVisible: !root.overviewVisible && islandState === "expanded"
        readonly property bool bluetoothExpandedLayerVisible: !root.overviewVisible && islandState === "bluetooth_expanded"
        readonly property bool notificationLayerVisible: !root.overviewVisible && islandState === "notification"
        readonly property bool controlCenterLayerVisible: !root.overviewVisible && islandState === "control_center"
        readonly property bool powerMenuLayerVisible: !root.overviewVisible && islandState === "power_menu"
        readonly property bool notificationCenterLayerVisible: !root.overviewVisible && islandState === "notification_center"
        readonly property bool wallpaperPickerLayerVisible: !root.overviewVisible && islandState === "wallpaper_picker"
        readonly property bool applicationLauncherLayerVisible: !root.overviewVisible && islandState === "application_launcher"
        readonly property bool clipboardLayerVisible: !root.overviewVisible && islandState === "clipboard"
        readonly property bool settingsAppLayerVisible: !root.overviewVisible && islandState === "settings_app"
        property bool settingsTopNotificationActive: false
        readonly property bool fileShelfLayerVisible: !root.overviewVisible && islandState === "file_shelf"
        readonly property bool polkitLayerVisible: !root.overviewVisible && islandState === "polkit"
        readonly property var activePlayer: mediaController.activePlayer
        readonly property string lyricsDisplayText: mediaController.displayText
        readonly property string currentTrack: mediaController.currentTrack
        readonly property string currentArtist: mediaController.currentArtist
        readonly property string currentArtUrl: mediaController.currentArtUrl
        readonly property real trackProgress: mediaController.trackProgress
        readonly property string timePlayed: mediaController.timePlayed
        readonly property string timeTotal: mediaController.timeTotal
        readonly property bool screenRecordingActive: root.screenRecordingActive
        readonly property var bluetoothDevices: bluetoothConnectionTracker.devices
        readonly property var overviewView: overviewLoader.item && overviewLoader.item.overviewView
            ? overviewLoader.item.overviewView
            : null

        onExpandedLayerVisibleChanged: {
            if (expandedLayerVisible)
                requestExpandedPlayerKeyboardFocus();
            else
                expandedPlayerKeyboardFocusRequested = false;
        }

        onControlCenterLayerVisibleChanged: {
            if (!controlCenterLayerVisible) {
                if (controlCenterLoader.item)
                    controlCenterLoader.item.closeConnectivityPanels();
                else
                    root.closeAllConnectivityDetails();
            }
        }

        onFileShelfLayerVisibleChanged: {
            if (!fileShelfLayerVisible)
                fileShelfOpenedManually = false;
        }

        onCustomLeftItemsChanged: {
            if (restingState === "custom" && !hasCustomLeftItems) {
                restingState = "normal";

                if (islandState === "custom"
                        || (islandState === "split" && splitOriginSide === "left")
                        || (islandState === "long_capsule" && workspaceOriginSide === "left")) {
                    restoreRestingCapsule(true);
                } else {
                    applyRestingVisuals();
                }
            } else if (restingState === "custom") {
                syncCustomCapsuleWidth();
            }
        }

        IslandMprisController {
            id: mediaController

            expanded: islandContainer.islandState === "expanded" || (musicFloatingIsland && musicFloatingIsland.hasTrack)
            clientId: "island-mpris-" + root.screenOutputName
        }

        BluetoothConnectionTracker {
            id: bluetoothConnectionTracker

            onAdapterChanged: islandContainer.bluetoothExpandedDevice = null

            onNewConnection: function(device) {
                islandContainer.showBluetoothExpanded(device);
            }
        }

        WifiConnectionTracker {
            id: wifiConnectionTracker

            onWifiDisconnected: function(ssid) {
                islandContainer.showNotificationCapsule(
                    "Wi-Fi",
                    "Wi-Fi disconnesso",
                    ssid ? ("da " + ssid) : "",
                    "",
                    "#ff9f0a"
                );
            }
        }

        IslandSystemState {
            id: systemState

            configuredLeftSwipeItems: userConfig.dynamicIslandLeftSwipeItems
            timeText: timeObj.currentTime
            dateText: timeObj.currentDateLabel
            currentTrack: islandContainer.currentTrack
            currentArtUrl: islandContainer.currentArtUrl
            currentWorkspace: islandContainer.currentWs
            customSwipeActive: customSwipeLoader.active
            lyricsCavaActive: islandContainer.lyricsSwipeVisible
                && islandContainer.rightSwipeProgress > 0.001

            onTransientRequested: function(icon, progress, text) {
                islandContainer.showTransientCapsule(icon, progress, text);
            }

            onChargingAlertRequested: function(isCharging, capacity) {
                islandContainer.showChargingCapsule(capacity, isCharging);
            }

            onLowBatteryAlertRequested: function(capacity) {
                islandContainer.showLowBatteryCapsule(capacity);
            }

            onMuteAlertRequested: function(isMuted) {
                islandContainer.showSilentRingCapsule(isMuted);
            }
        }

        CompositorWorkspaceTracker {
            id: workspaceTracker

            compositor: CompositorBackend.compositor
            hyprMonitor: root.hyprMonitor
            hyprMonitorName: root.hyprMonitorName
            outputName: root.compositorOutputName
            monitorFocused: root.monitorFocused

            onWorkspaceSynced: function(workspaceId) {
                islandContainer.currentWs = workspaceId;
            }

            onWorkspaceActivated: function(workspaceId) {
                if(userConfig.islandShowWorkspaceOnAutoHide){
                    root.showAutoHiddenIsland();
                }

                islandContainer.showWorkspaceCapsule(workspaceId);
            }
        }

        Behavior on osdProgress {
            enabled: islandContainer.osdProgressAnimationEnabled

            SmoothedAnimation { velocity: 1.2; duration: 180; easing.type: Easing.InOutQuad }
        }
        Behavior on swipeTransitionProgress {
            NumberAnimation {
                duration: capsuleMouseArea.sideSwipeInteractive ? 0 : islandContainer.swipeAnimationDuration
                easing.type: Easing.OutCubic
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                if (root.overviewVisible) {
                    root.closeOverviewEverywhere();
                    event.accepted = true;
                    return;
                }

                if (islandContainer.expandedLayerVisible) {
                    islandContainer.smartRestoreState();
                    event.accepted = true;
                    return;
                }

                if (islandContainer.controlCenterLayerVisible) {
                    islandContainer.smartRestoreState();
                    event.accepted = true;
                    return;
                }

                if (islandContainer.powerMenuLayerVisible) {
                    islandContainer.smartRestoreState();
                    event.accepted = true;
                    return;
                }
            }

            if (!root.overviewVisible) return;

            const view = islandContainer.overviewView;
            if (event.key === Qt.Key_H) {
                if (view)
                    view.focusAdjacentWorkspace(0, -1);
                event.accepted = true;
            } else if (event.key === Qt.Key_J) {
                if (view)
                    view.focusAdjacentWorkspace(1, 0);
                event.accepted = true;
            } else if (event.key === Qt.Key_K) {
                if (view)
                    view.focusAdjacentWorkspace(-1, 0);
                event.accepted = true;
            } else if (event.key === Qt.Key_L) {
                if (view)
                    view.focusAdjacentWorkspace(0, 1);
                event.accepted = true;
            } else if ((event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) || event.key === Qt.Key_Backtab) {
                if (root.hyprlandIntegration)
                    root.hyprlandIntegration.focusWorkspace("r-1");
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab) {
                if (root.hyprlandIntegration)
                    root.hyprlandIntegration.focusWorkspace("r+1");
                event.accepted = true;
            }
        }

        function handleConfiguredClickAction(actionName) {
            switch (actionName) {
            case "":
            case "none":
                return;
            case "toggleExpandedPlayer":
                if (musicFloatingIsland && musicFloatingIsland.hasTrack) {
                    musicFloatingIsland.isExpanded = !musicFloatingIsland.isExpanded;
                    return;
                }
                if (islandState === "expanded") {
                    autoHideTimer.stop();
                    smartRestoreState();
                }
                return;
            case "openExpandedPlayer":
                if (musicFloatingIsland && musicFloatingIsland.hasTrack) {
                    musicFloatingIsland.isExpanded = true;
                    return;
                }
                return;
            case "closeExpandedPlayer":
                if (musicFloatingIsland)
                    musicFloatingIsland.isExpanded = false;
                if (headphonesFloatingIsland)
                    headphonesFloatingIsland.isExpanded = false;
                if (callFloatingIsland)
                    callFloatingIsland.isExpanded = false;
                if (islandState === "expanded")
                    smartRestoreState();
                return;
            case "toggleNotificationCenter":
                if (islandState === "notification_center")
                    smartRestoreState();
                else
                    showNotificationCenter();
                return;
            case "openNotificationCenter":
                showNotificationCenter();
                return;
            case "closeNotificationCenter":
                if (islandState === "notification_center")
                    smartRestoreState();
                return;
            case "toggleControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                else
                    showControlCenter();
                return;
            case "openControlCenter":
                showControlCenter();
                return;
            case "closeControlCenter":
                if (islandState === "control_center")
                    smartRestoreState();
                return;
            case "togglePowerMenu":
                if (islandState === "power_menu")
                    smartRestoreState();
                else
                    showPowerMenu();
                return;
            case "openPowerMenu":
                showPowerMenu();
                return;
            case "closePowerMenu":
                if (islandState === "power_menu")
                    smartRestoreState();
                return;
            case "toggleOverview":
                root.toggleOverviewEverywhere();
                return;
            case "openOverview":
                root.openOverviewEverywhere();
                return;
            case "closeOverview":
                root.closeOverviewEverywhere();
                return;
            case "toggleLyrics":
                if (restingState === "lyrics")
                    showTimeCapsule();
                else
                    showLyricsCapsule();
                return;
            case "showLyrics":
                showLyricsCapsule();
                return;
            case "showTime":
                showTimeCapsule();
                return;
            case "restoreRestingCapsule":
                smartRestoreState();
                return;
            default:
            }
        }

        function clamp01(value) {
            return Math.max(0, Math.min(1, value));
        }

        function normalizeRestingState(nextState) {
            if (nextState === "lyrics") return "lyrics";
            if (nextState === "custom" && hasCustomLeftItems) return "custom";
            return "normal";
        }

        function restingStateProgress(nextState) {
            switch (normalizeRestingState(nextState)) {
            case "custom":
                return -1;
            case "lyrics":
                return 1;
            default:
                return 0;
            }
        }

        function restingStateSide(nextState) {
            switch (normalizeRestingState(nextState)) {
            case "custom":
                return "left";
            case "lyrics":
                return "right";
            default:
                return "none";
            }
        }

        function swipeRestProgressForState() {
            switch (islandState) {
            case "custom":
                return -1;
            case "lyrics":
                return 1;
            default:
                return 0;
            }
        }

        function currentTransientOriginSide() {
            switch (islandState) {
            case "custom":
                return "left";
            case "lyrics":
                return "right";
            case "long_capsule":
                return workspaceOriginSide;
            case "split":
                return splitOriginSide;
            default:
                return "none";
            }
        }

        function setOsdProgress(nextProgress, animate) {
            osdProgressAnimationReset.stop();
            osdProgressAnimationEnabled = animate;
            osdProgress = nextProgress;
            if (!animate) osdProgressAnimationReset.restart();
        }

        function abortSideTransientMode() {
            sideTransientRestoreTimer.stop();
            workspaceOriginSide = "none";
            splitOriginSide = "none";
        }

        function clearTransientCapsule() {
            setOsdProgress(-1.0, false);
            osdCustomText = "";
            notificationAppName = "";
            notificationSummary = "";
            notificationBody = "";
            notificationIcon = "";
            notificationIconColor = "#f4f5f7";
            notificationExpanded = false;
            bluetoothExpandedDevice = null;
            discordCallOngoing = false;
        }

        function cleanNotificationText(text) {
            return String(text === undefined || text === null ? "" : text)
                .replace(/<[^>]*>/g, " ")
                .replace(/&nbsp;/g, " ")
                .replace(/&amp;/g, "&")
                .replace(/&quot;/g, "\"")
                .replace(/&lt;/g, "<")
                .replace(/&gt;/g, ">")
                .replace(/\s+/g, " ")
                .trim();
        }

        function prepareRestingCapsuleGeometry() {
            if (restingState === "custom")
                syncCustomCapsuleWidth();
            if (restingState === "lyrics")
                syncLyricsCapsuleWidth();
        }

        function applyRestingVisuals() {
            prepareRestingCapsuleGeometry();
            swipeTransitionProgress = restingStateProgress(restingState);
        }

        function sideSwipeRestProgressForProgress(progressValue) {
            if (progressValue <= -0.5) return -1;
            if (progressValue >= 0.5) return 1;
            return 0;
        }

        function sideSwipeRestWidthForProgress(progressValue) {
            if (progressValue <= -0.5) return customCapsuleWidth;
            if (progressValue >= 0.5) return lyricsCapsuleWidth;
            return root.effectiveIslandWidth;
        }

        function customSideSwipeDragDistance() {
            const view = customSwipeLoader.item;
            if (view && view.dragDistance > 0) return view.dragDistance;
            return Math.max(root.effectiveIslandWidth, customCapsuleWidth + 4);
        }

        function lyricsSideSwipeDragDistance() {
            const view = lyricsSwipeLoader.item;
            if (view && view.dragDistance > 0) return view.dragDistance;
            return Math.max(root.effectiveIslandWidth, lyricsCapsuleWidth + 2);
        }

        function sideSwipeDragDistanceForDirection(direction) {
            if (direction === "left") return customSideSwipeDragDistance();
            if (direction === "right") return lyricsSideSwipeDragDistance();
            return root.effectiveIslandWidth;
        }

        function advanceSideSwipeProgress(currentProgress, deltaX) {
            const minProgress = hasCustomLeftItems ? -1 : 0;
            let nextProgress = Math.max(minProgress, Math.min(1, currentProgress));
            let remainingDelta = deltaX;

            if (remainingDelta > 0) {
                if (nextProgress < 0) {
                    const leftDistance = Math.max(1, sideSwipeDragDistanceForDirection("left"));
                    const progressToCenter = Math.min(-nextProgress, remainingDelta / leftDistance);
                    nextProgress += progressToCenter;
                    remainingDelta -= progressToCenter * leftDistance;
                }

                if (remainingDelta > 0 && nextProgress < 1) {
                    const rightDistance = Math.max(1, sideSwipeDragDistanceForDirection("right"));
                    nextProgress = Math.min(1, nextProgress + remainingDelta / rightDistance);
                }
            } else if (remainingDelta < 0) {
                if (nextProgress > 0) {
                    const rightDistance = Math.max(1, sideSwipeDragDistanceForDirection("right"));
                    const progressToCenter = Math.min(nextProgress, -remainingDelta / rightDistance);
                    nextProgress -= progressToCenter;
                    remainingDelta += progressToCenter * rightDistance;
                }

                if (remainingDelta < 0 && nextProgress > minProgress) {
                    const leftDistance = Math.max(1, sideSwipeDragDistanceForDirection("left"));
                    nextProgress = Math.max(minProgress, nextProgress + remainingDelta / leftDistance);
                }
            }

            return Math.max(minProgress, Math.min(1, nextProgress));
        }

        function resolveSideSwipeSettle(startProgress, finalProgress) {
            let settleAction = "";
            let settleProgress = sideSwipeRestProgressForProgress(startProgress);
            let settleWidth = sideSwipeRestWidthForProgress(startProgress);

            if (finalProgress >= 0.56) {
                settleAction = "lyrics";
                settleProgress = 1;
                settleWidth = lyricsCapsuleWidth;
            } else if (hasCustomLeftItems && finalProgress <= -0.56) {
                settleAction = "custom";
                settleProgress = -1;
                settleWidth = customCapsuleWidth;
            } else if (startProgress <= -0.5) {
                if (finalProgress >= -0.44) {
                    settleAction = "time";
                    settleProgress = 0;
                    settleWidth = root.effectiveIslandWidth;
                }
            } else if (startProgress >= 0.5) {
                if (finalProgress <= 0.44) {
                    settleAction = "time";
                    settleProgress = 0;
                    settleWidth = root.effectiveIslandWidth;
                }
            } else {
                settleAction = "time";
                settleProgress = 0;
                settleWidth = root.effectiveIslandWidth;
            }

            return {
                action: settleAction,
                progress: settleProgress,
                width: settleWidth
            };
        }

        function beginSideSwipeSettle(targetWidth) {
            sideSwipeSettling = true;
            mainCapsule.displayedWidth = targetWidth;
            sideSwipeSettleReset.restart();
        }

        function cancelSideSwipeSettle() {
            sideSwipeSettleReset.stop();
            sideSwipeSettling = false;
        }

        function finishSideSwipeSettle() {
            sideSwipeSettling = false;
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
        }

        function restartAutoHideTimer(duration) {
            autoHideTimer.interval = duration === undefined ? defaultAutoHideInterval : duration;
            autoHideTimer.restart();
        }

        function stopAutoHideTimer() {
            autoHideTimer.stop();
            autoHideTimer.interval = defaultAutoHideInterval;
        }

        function requestExpandedPlayerKeyboardFocus() {
            const shouldGrabFocus = !expandedPlayerKeyboardFocusRequested;
            expandedPlayerKeyboardFocusRequested = true;
            if (shouldGrabFocus)
                expandedPlayerFocusTimer.restart();
        }

        function releaseExpandedPlayerKeyboardFocus() {
            expandedPlayerKeyboardFocusRequested = false;
        }

        function clampTimerInput(value, minValue, maxValue) {
            const parsed = parseInt(value, 10);
            if (isNaN(parsed)) return minValue;
            return Math.max(minValue, Math.min(maxValue, parsed));
        }

        function syncTimerDuration(hours, minutes) {
            cancelTimerCompletionAnimation();
            timerSelectedHours = clampTimerInput(hours, 0, 23);
            timerSelectedMinutes = clampTimerInput(minutes, 0, 59);
            timerTotalSeconds = timerSelectedHours * 3600 + timerSelectedMinutes * 60;
            timerRemainingSeconds = 0;
            timerRunning = false;
            timerActive = false;
        }

        function toggleTimer(hours, minutes) {
            if (timerCompletionAnimating)
                cancelTimerCompletionAnimation();

            if (timerRunning) {
                timerRunning = false;
                return;
            }

            if (!timerActive || timerRemainingSeconds <= 0) {
                syncTimerDuration(hours, minutes);
                timerRemainingSeconds = timerTotalSeconds;
                timerActive = timerRemainingSeconds > 0;
            }

            if (timerRemainingSeconds > 0)
                timerRunning = true;
        }

        function resetTimer() {
            cancelTimerCompletionAnimation();
            timerRemainingSeconds = 0;
            timerRunning = false;
            timerActive = false;
        }

        function startTimerCompletionAnimation() {
            timerCompletionPulse = 0;
            timerCompletionFlash = 0;
            timerCompletionAnimating = true;
        }

        function cancelTimerCompletionAnimation() {
            timerCompletionAnimating = false;
            timerCompletionPulse = 0;
            timerCompletionFlash = 0;
        }

        function showExpandedTimerPage() {
            openTimerPageWhenExpanded = true;
            showExpandedPlayer(false);
            if (expandedPlayerLoader.item && expandedPlayerLoader.item.openTimerPage) {
                expandedPlayerLoader.item.openTimerPage();
                openTimerPageWhenExpanded = false;
            }
        }

        function showTransientCapsule(icon, progress, customText) {
            if (progress === undefined)    progress = -1.0;
            if (customText === undefined)  customText = "";

            if (root.autoHideSuppressesTransientReveal) return;
            if (blocksTransientSplit) return;

            const nextProgress = progress >= 0 ? progress : -1.0;
            const animateProgress = islandState === "split" && osdProgress >= 0 && nextProgress >= 0;
            const animateFromSide = currentTransientOriginSide();

            abortSideTransientMode();
            splitIcon = icon;
            osdCustomText = customText;
            setOsdProgress(nextProgress, animateProgress);
            splitOriginSide = animateFromSide;
            islandState = "split";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        function showNotificationCapsule(appName, summary, body, icon, customColor) {
            if (root.overviewVisible || islandState === "control_center"
                    || islandState === "expanded" || islandState === "file_shelf"
                    || islandState === "polkit") return;

            const cleanedAppName = cleanNotificationText(appName);
            const cleanedSummary = cleanNotificationText(summary);
            const cleanedBody = cleanNotificationText(body);
            const resolvedSummary = cleanedSummary !== ""
                ? cleanedSummary
                : (cleanedBody !== "" ? cleanedBody : "New notification");

            if (islandState === "settings_app") {
                const floatingExpanded = (musicFloatingIsland && musicFloatingIsland.isExpanded)
                    || (headphonesFloatingIsland && headphonesFloatingIsland.isExpanded);
                if (floatingExpanded) {
                    // Responsive convergence: suppressed when media or headphones card is expanded
                    if (notificationHistoryModel) {
                        notificationHistoryModel.insert(0, {
                            appName: cleanedAppName !== "" ? cleanedAppName : "Notification",
                            summary: resolvedSummary,
                            body: cleanedSummary !== "" ? cleanedBody : "",
                            timestamp: new Date()
                        });
                    }
                    return;
                }
                notificationAppName = cleanedAppName !== "" ? cleanedAppName : "Notification";
                notificationSummary = resolvedSummary;
                notificationBody = cleanedSummary !== "" ? cleanedBody : "";
                notificationIcon = (icon !== undefined && icon !== null) ? String(icon) : "";
                notificationIconColor = customColor ? customColor : (notificationAppName === "Wi-Fi" ? "#ff9f0a" : "#f4f5f7");
                settingsTopNotificationActive = true;
                settingsTopNotificationTimer.restart();
                if (notificationHistoryModel) {
                    notificationHistoryModel.insert(0, {
                        appName: cleanedAppName !== "" ? cleanedAppName : "Notification",
                        summary: resolvedSummary,
                        body: cleanedSummary !== "" ? cleanedBody : "",
                        timestamp: new Date()
                    });
                    if (notificationHistoryModel.count > 50)
                        notificationHistoryModel.remove(50, notificationHistoryModel.count - 50);
                }
                return;
            }

            abortSideTransientMode();
            clearTransientCapsule();
            notificationAppName = cleanedAppName !== "" ? cleanedAppName : "Notification";
            notificationSummary = resolvedSummary;
            notificationBody = cleanedSummary !== "" ? cleanedBody : "";
            notificationIcon = (icon !== undefined && icon !== null) ? String(icon) : "";
            notificationIconColor = customColor ? customColor : (notificationAppName === "Wi-Fi" ? "#ff9f0a" : "#f4f5f7");
            notificationExpanded = false;
            islandState = "notification";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.showAutoHiddenIsland("state");
            restartAutoHideTimer(notificationAutoHideInterval);
            // Store in notification history
            if (notificationHistoryModel) {
                notificationHistoryModel.insert(0, {
                    appName: cleanedAppName !== "" ? cleanedAppName : "Notification",
                    summary: resolvedSummary,
                    body: cleanedSummary !== "" ? cleanedBody : "",
                    timestamp: new Date()
                });
                if (notificationHistoryModel.count > 50)
                    notificationHistoryModel.remove(50, notificationHistoryModel.count - 50);
            }
        }

        function showReloadCapsule(failed, errorString) {
            if (root.overviewVisible || islandState === "control_center"
                    || islandState === "expanded" || islandState === "file_shelf") return;

            abortSideTransientMode();
            clearTransientCapsule();
            reloadFailed = failed;
            reloadErrorString = errorString || "";
            islandState = "reload";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            restartAutoHideTimer(failed ? 8000 : 2500);
        }

        function showChargingCapsule(capacity, isCharging) {
            if (root.overviewVisible || islandState === "control_center"
                    || islandState === "expanded" || islandState === "file_shelf"
                    || islandState === "polkit") return;

            abortSideTransientMode();
            clearTransientCapsule();
            batteryAlertMode = "charging";
            batteryAlertCapacity = (capacity !== undefined && capacity > 0) ? capacity : batteryCapacity;
            islandState = "charging";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.showAutoHiddenIsland("state");
            restartAutoHideTimer(3500);
        }

        function showLowBatteryCapsule(capacity) {
            if (root.overviewVisible || islandState === "control_center"
                    || islandState === "expanded" || islandState === "file_shelf"
                    || islandState === "polkit") return;

            abortSideTransientMode();
            clearTransientCapsule();
            batteryAlertMode = "low_battery";
            batteryAlertCapacity = (capacity !== undefined && capacity > 0) ? capacity : batteryCapacity;
            islandState = "charging";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.showAutoHiddenIsland("state");
            restartAutoHideTimer(4200);
        }

        function showSilentRingCapsule(isMuted) {
            if (root.overviewVisible || islandState === "control_center"
                    || islandState === "expanded" || islandState === "file_shelf"
                    || islandState === "polkit") return;

            abortSideTransientMode();
            clearTransientCapsule();
            silentRingIsMuted = isMuted;
            islandState = "silent_ring";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.showAutoHiddenIsland("state");
            restartAutoHideTimer(2600);
        }

        function showDiscordCallCapsule(callerName, subtitle, avatarUrl) {
            if (root.overviewVisible || islandState === "polkit") return;

            discordCallerName = callerName || "Discord Call";
            discordCallSubtitle = subtitle || "Chiamata in arrivo...";
            discordCallAvatarUrl = avatarUrl || "";
            discordCallOngoing = false;
            discordCallActive = true;

            if (islandState !== "discord_call") {
                abortSideTransientMode();
                clearTransientCapsule();
                islandState = "discord_call";
                mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
                root.showAutoHiddenIsland("state");
                stopAutoHideTimer();
            }
        }

        function closeDiscordCallCapsule() {
            discordCallActive = false;
            discordCallOngoing = false;
            discordCallAvatarUrl = "";
            if (islandState === "discord_call") {
                smartRestoreState();
            }
        }

        function toggleNotificationExpansionIfNeeded() {
            if (islandState !== "notification" || !notificationLoader.item || !notificationLoader.item.hasOverflowContent)
                return false;

            if (notificationExpanded) {
                smartRestoreState();
                return true;
            }

            notificationExpanded = true;
            stopAutoHideTimer();
            return true;
        }

        function suppressCapsuleClick(cancelPreparedOverview) {
            if (cancelPreparedOverview === undefined) cancelPreparedOverview = false;
            if (cancelPreparedOverview && capsuleMouseArea.preparedOverviewOnPress) {
                root.cancelPreparedOverviewEverywhere();
                capsuleMouseArea.preparedOverviewOnPress = false;
            }
            capsuleMouseArea.suppressNextClick = true;
            swipeSuppressReset.restart();
        }

        function restoreRestingCapsule(forceImmediate) {
            if (forceImmediate === undefined) forceImmediate = false;
            const normalizedRestingState = normalizeRestingState(restingState);
            const targetSide = restingStateSide(normalizedRestingState);
            const shouldAnimateToSide = targetSide !== "none"
                && ((islandState === "long_capsule" && workspaceOriginSide === targetSide)
                    || (islandState === "split" && splitOriginSide === targetSide));

            if (!forceImmediate && shouldAnimateToSide) {
                expandedByPlayerAutoOpen = false;
                prepareRestingCapsuleGeometry();
                swipeTransitionProgress = restingStateProgress(normalizedRestingState);
                stopAutoHideTimer();
                sideTransientRestoreTimer.restart();
                return;
            }

            abortSideTransientMode();
            prepareRestingCapsuleGeometry();
            islandState = normalizedRestingState;
            clearTransientCapsule();
            applyRestingVisuals();
            expandedByPlayerAutoOpen = false;
            stopAutoHideTimer();
        }

        function setRestingState(nextState) {
            restingState = normalizeRestingState(nextState);
        }

        function smartRestoreState() {
            controlCenterAutoCollapseTimer.stop();
            controlCenterHadPointer = false;
            pendingPowerView = false;
            root.closeAllConnectivityDetails();
            restoreRestingCapsule();
            if (controlCenterLoader.item)
                controlCenterLoader.item.powerViewActive = false;
        }

        function showRestingCapsule(nextState) {
            setRestingState(nextState);
            restoreRestingCapsule();
            stopAutoHideTimer();
        }

        function showExpandedPlayer(autoOpened) {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "expanded";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            root.showAutoHiddenIsland("state");
            expandedByPlayerAutoOpen = autoOpened;
            if (autoOpened) restartAutoHideTimer();
            else stopAutoHideTimer();
        }

        function showBluetoothExpanded(device) {
            if (!device || root.overviewVisible || islandState === "control_center"
                    || islandState === "notification" || islandState === "file_shelf")
                return;

            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            bluetoothExpandedDevice = device;
            islandState = "bluetooth_expanded";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            expandedByPlayerAutoOpen = false;
            restartAutoHideTimer(bluetoothExpandedAutoHideInterval);
        }

        function showPowerMenu() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "power_menu";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showControlCenter() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "control_center";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showNotificationCenter() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "notification_center";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }


        function showWallpaperPicker() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "wallpaper_picker";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showApplicationLauncher() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "application_launcher";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showClipboard() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "clipboard";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showSettingsApp() {
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            settingsTopNotificationActive = false;
            settingsTopNotificationTimer.stop();
            islandState = "settings_app";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function showFileShelf(manuallyOpened) {
            const manual = manuallyOpened === true;
            if (islandState === "file_shelf") {
                if (manual)
                    fileShelfOpenedManually = true;
                return;
            }

            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            fileShelfOpenedManually = manual;
            islandState = "file_shelf";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
        }

        function closeAutoOpenedFileShelf() {
            if (islandState === "file_shelf" && !fileShelfOpenedManually)
                smartRestoreState();
        }

        function showPolkitPrompt() {
            polkitSuccessMorph = false;
            cancelSideSwipeSettle();
            abortSideTransientMode();
            clearTransientCapsule();
            islandState = "polkit";
            mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
            stopAutoHideTimer();
            root.showAutoHiddenIsland("state");
            root.focusPolkit();
        }

        function closePolkitPrompt() {
            polkitSuccessMorph = false;
            if (islandState === "polkit")
                smartRestoreState();
        }

        function showCustomCapsule() {
            if (!hasCustomLeftItems) {
                showTimeCapsule();
                return;
            }

            systemState.refreshMissingValues();
            showRestingCapsule("custom");
        }

        function showLyricsCapsule() {
            showRestingCapsule("lyrics");
        }

        function showTimeCapsule() {
            showRestingCapsule("normal");
        }

        function showWorkspaceCapsule(wsId) {
            if (currentWs === wsId && islandState === "long_capsule") return;
            currentWs = wsId;
            if (root.autoHideSuppressesTransientReveal) return;
            if (islandState === "control_center" || islandState === "notification" || islandState === "discord_call") return;
            const animateFromSide = currentTransientOriginSide();
            clearTransientCapsule();
            sideTransientRestoreTimer.stop();
            workspaceOriginSide = animateFromSide;
            splitOriginSide = "none";
            islandState = "long_capsule";
            swipeTransitionProgress = 0;
            restartAutoHideTimer();
        }

        Timer { id: autoHideTimer; interval: islandContainer.defaultAutoHideInterval; onTriggered: islandContainer.smartRestoreState() }
        Timer {
            id: settingsTopNotificationTimer
            interval: 4000
            repeat: false
            onTriggered: islandContainer.settingsTopNotificationActive = false
        }
        Timer {
            id: islandTimerTick
            interval: 1000
            repeat: true
            running: islandContainer.timerRunning
            onTriggered: {
                const nextRemainingSeconds = Math.max(0, islandContainer.timerRemainingSeconds - 1);
                if (nextRemainingSeconds <= 0) {
                    islandContainer.startTimerCompletionAnimation();
                    islandContainer.timerRemainingSeconds = 0;
                    islandContainer.timerRunning = false;
                    islandContainer.timerActive = false;
                } else {
                    islandContainer.timerRemainingSeconds = nextRemainingSeconds;
                }
            }
        }
        Timer {
            id: osdProgressAnimationReset
            interval: 0
            onTriggered: islandContainer.osdProgressAnimationEnabled = true
        }
        Timer {
            id: sideTransientRestoreTimer
            interval: islandContainer.swipeAnimationDuration
            onTriggered: {
                islandContainer.workspaceOriginSide = "none";
                islandContainer.splitOriginSide = "none";
                islandContainer.prepareRestingCapsuleGeometry();
                islandContainer.islandState = islandContainer.normalizeRestingState(islandContainer.restingState);
                islandContainer.clearTransientCapsule();
                islandContainer.applyRestingVisuals();
                islandContainer.expandedByPlayerAutoOpen = false;
            }
        }
        Timer {
            id: sideSwipeSettleReset
            interval: mainCapsule.morphDuration
            onTriggered: islandContainer.finishSideSwipeSettle()
        }
        Timer {
            id: hoverExpandDelayTimer
            interval: {
                if (localUserConfigFile.parsedData && localUserConfigFile.parsedData.hoverExpandDelayMs > 0)
                    return localUserConfigFile.parsedData.hoverExpandDelayMs;
                return userConfig.hoverExpandDelayMs > 0 ? userConfig.hoverExpandDelayMs : 180;
            }
            repeat: false
            onTriggered: {
                if (!capsuleMouseArea.containsMouse && !mainCapsuleHoverHandler.hovered) return;
                if (!root.hoverExpandEnabled) return;

                const current = islandContainer.islandState;
                const target = root.configuredHoverExpandAction === 1 ? "expanded" : "control_center";
                if (current === target) return;
                if (current !== "normal" && current !== "custom" && current !== "lyrics")
                    return;

                islandContainer.hoverExpandedActive = true;
                if (target === "expanded")
                    islandContainer.showExpandedPlayer(false);
                else
                    islandContainer.showControlCenter();
            }
        }
        Timer {
            id: hoverCollapseDelayTimer
            interval: {
                if (localUserConfigFile.parsedData && localUserConfigFile.parsedData.hoverCollapseDelayMs > 0)
                    return localUserConfigFile.parsedData.hoverCollapseDelayMs;
                return userConfig.hoverCollapseDelayMs > 0 ? userConfig.hoverCollapseDelayMs : 300;
            }
            repeat: false
            onTriggered: {
                if (capsuleMouseArea.containsMouse || mainCapsuleHoverHandler.hovered) return;
                if (!islandContainer.hoverExpandedActive) return;
                if (islandContainer.islandState === "settings_app" ||
                    islandContainer.islandState === "clipboard" ||
                    islandContainer.islandState === "wallpaper_picker" ||
                    islandContainer.islandState === "application_launcher" ||
                    islandContainer.islandState === "file_shelf") {
                    islandContainer.hoverExpandedActive = false;
                    return;
                }
                islandContainer.hoverExpandedActive = false;
                islandContainer.smartRestoreState();
            }
        }
        Timer {
            id: controlCenterAutoCollapseTimer
            interval: 400
            repeat: false
            onTriggered: {
                if (islandContainer.islandState === "control_center" && !islandContainer.controlCenterPointerInside) {
                    islandContainer.smartRestoreState();
                }
            }
        }

        function syncCustomCapsuleWidth() {
            const view = customSwipeLoader.item;
            if (!view) return;
            customCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        function syncLyricsCapsuleWidth() {
            const view = lyricsSwipeLoader.item;
            if (!view) return;
            lyricsCapsuleWidth = Math.max(220, Math.min(root.width - 48, view.preferredWidth));
        }

        onCurrentTrackChanged: {
            const disableAutoExpand = (localUserConfigFile.parsedData && localUserConfigFile.parsedData.disableAutoExpandOnTrackChange !== undefined)
                ? Boolean(localUserConfigFile.parsedData.disableAutoExpandOnTrackChange)
                : (userConfig.disableAutoExpandOnTrackChange !== undefined ? Boolean(userConfig.disableAutoExpandOnTrackChange) : true);
            if (disableAutoExpand) return;
            if (musicFloatingIsland) return;
            if (currentTrack !== ""
                    && islandState !== "control_center"
                    && islandState !== "notification"
                    && islandState !== "bluetooth_expanded"
                    && islandState !== "file_shelf") {
                if (root.autoHideSuppressesTransientReveal) return;
                if (islandState === "expanded" && !expandedByPlayerAutoOpen) return;
                showExpandedPlayer(true);
            }
        }

        Item {
            id: topAnchorProxy
            y: root.effectiveIslandTopMargin
            height: root.effectiveIslandHeight
            opacity: mainCapsule.opacity
            z: 7

            readonly property bool isSettingsApp: islandContainer.islandState === "settings_app"
            readonly property bool hasTopNotification: islandContainer.settingsTopNotificationActive
            property bool exitingSettingsApp: false

            Timer {
                id: exitSettingsTimer
                interval: 420
                repeat: false
                onTriggered: topAnchorProxy.exitingSettingsApp = false
            }

            onIsSettingsAppChanged: {
                if (!isSettingsApp) {
                    exitingSettingsApp = true;
                    exitSettingsTimer.restart();
                }
            }

            // In settings_app mode or exiting settings_app:
            // Animate smoothly between compact center and resting width.
            // In all normal modes (control_center, clipboard, etc.):
            // 1:1 locked with mainCapsule with ZERO delay!
            width: isSettingsApp ? (hasTopNotification ? 290 : 0)
                 : (exitingSettingsApp ? mainCapsule.baseTargetWidth : mainCapsule.width)

            x: (isSettingsApp || exitingSettingsApp)
                ? Math.round(parent.width * root.effectiveIslandPositionX / 100 - width / 2)
                : mainCapsule.x

            Behavior on width {
                enabled: topAnchorProxy.isSettingsApp || topAnchorProxy.exitingSettingsApp
                NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
            }
            Behavior on x {
                enabled: topAnchorProxy.isSettingsApp || topAnchorProxy.exitingSettingsApp
                NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
            }

            Rectangle {
                id: topNotificationCapsule
                anchors.fill: parent
                radius: height / 2
                color: "#000000"
                border.width: 1
                border.color: "#2a2a2a"
                clip: true
                visible: topAnchorProxy.isSettingsApp && topAnchorProxy.width > 20
                opacity: Math.min(1.0, Math.max(0.0, (topAnchorProxy.width - 50) / 180))

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: islandContainer.notificationIcon !== "" ? islandContainer.notificationIcon : "󰂚"
                        font.family: root.iconFontFamily
                        font.pixelSize: 15
                        color: islandContainer.notificationIconColor
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0

                        Text {
                            text: islandContainer.notificationAppName
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: "#ffffff"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: islandContainer.notificationSummary
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            color: "#a0a0a0"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        MusicFloatingIsland {
            id: musicFloatingIsland
            targetCapsule: topAnchorProxy
            rootWindow: root
            mprisController: mediaController
            userConfig: root.userConfig
            islandTopMargin: root.effectiveIslandTopMargin
            accentColor: pywalColors.accent
            z: 8
        }

        HeadphonesFloatingIsland {
            id: headphonesFloatingIsland
            targetCapsule: topAnchorProxy
            rootWindow: root
            userConfig: root.userConfig
            islandTopMargin: root.effectiveIslandTopMargin
            accentColor: pywalColors.accent
            z: 8
        }

        CallFloatingIsland {
            id: callFloatingIsland
            targetCapsule: topAnchorProxy
            headphonesFloatingIsland: headphonesFloatingIsland
            rootWindow: root
            userConfig: root.userConfig
            islandTopMargin: root.effectiveIslandTopMargin
            accentColor: pywalColors.accent
            hasCall: islandContainer.discordCallActive
            ongoing: islandContainer.discordCallOngoing
            callerName: islandContainer.discordCallerName
            subtitle: islandContainer.discordCallSubtitle
            avatarUrl: islandContainer.discordCallAvatarUrl
            islandState: islandContainer.islandState
            currentWs: islandContainer.currentWs
            z: 8
            onAccepted: root.acceptDiscordCall()
            onDeclined: root.declineDiscordCall()
            onCallerClicked: root.focusDiscordWindow()
        }

        // --- UI 渲染：灵动岛主干 ---
        Rectangle {
            id: mainCapsule
            z: 5
            property int morphDuration: (islandContainer.islandState === "polkit" && islandContainer.polkitSuccessMorph) ? 320 : 400
            readonly property bool notificationHistorySurface: islandContainer.islandState === "notification_center"
            property real outlineWidth: root.overviewContentVisible || notificationHistorySurface ? 1 : 0
            property color outlineColor: root.overviewContentVisible
                ? root.overviewCapsuleBorderColor
                : (notificationHistorySurface ? "#1affffff" : StyleTokens.clearBlack)
            property real displayedWidth: baseTargetWidth
            readonly property real baseTargetWidth: {
                if (root.overviewVisible) return root.overviewCapsuleWidth;
                if (sideTransientRestoreTimer.running) {
                    if (islandContainer.restingState === "lyrics"
                            && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "right")
                                || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "right"))) {
                        return islandContainer.lyricsCapsuleWidth;
                    }

                    if (islandContainer.restingState === "custom"
                            && ((islandContainer.islandState === "split" && islandContainer.splitOriginSide === "left")
                                || (islandContainer.islandState === "long_capsule" && islandContainer.workspaceOriginSide === "left"))) {
                        return islandContainer.customCapsuleWidth;
                    }
                }

                switch (islandContainer.islandState) {
                case "split":
                    return islandContainer.splitCapsuleWidth;
                case "long_capsule":
                    return 220;
                case "custom":
                    return islandContainer.customCapsuleWidth;
                case "lyrics":
                    return islandContainer.lyricsCapsuleWidth;
                case "power_menu":
                    return 400;
                case "control_center":
                    return controlCenterLoader.item ? controlCenterLoader.item.controlCenterPreferredWidth : 420;
                case "notification_center":
                    return 410;
                case "wallpaper_picker":
                case "file_shelf":
                    return 1100;
                case "application_launcher":
                    return 820;
                case "clipboard":
                    return 800;
                case "settings_app":
                    return 980;
                case "polkit":
                    if (islandContainer.polkitSuccessMorph) return 58;
                    return 400;
                case "expanded":
                case "bluetooth_expanded":
                    return 410;
                case "notification":
                    if (!notificationLoader.item) return 272;
                    return Math.max(
                        notificationLoader.item.minimumWidth,
                        Math.min(root.width - 48, notificationLoader.item.maximumWidth, notificationLoader.item.preferredWidth)
                    );
                case "reload":
                    return reloadLoader.item ? reloadLoader.item.preferredWidth : 295;
                case "charging":
                    return 260;
                case "silent_ring":
                    return 240;
                case "discord_call":
                    return islandContainer.discordCallOngoing ? 290 : 340;
                default:
                    return root.effectiveIslandWidth;
                }
            }
            readonly property real targetHeight: {
                if (root.overviewVisible) return root.overviewCapsuleHeight;

                switch (islandContainer.islandState) {
                case "power_menu":
                    return 92;
                case "control_center":
                    if (controlCenterLoader.item && controlCenterLoader.item.anyConnectivitySubViewActive)
                        return 470;
                    return controlCenterLoader.item ? controlCenterLoader.item.controlCenterPreferredHeight : 420;
                case "notification_center":
                    return notificationCenterLoader.item ? notificationCenterLoader.item.contentHeight : 200;
                case "wallpaper_picker":
                case "file_shelf":
                    return 260;
                case "application_launcher":
                    return 428;
                case "clipboard":
                    return 520;
                case "settings_app":
                    return 680;
                case "polkit":
                    if (islandContainer.polkitSuccessMorph) return 58;
                    return 174;
                case "expanded":
                case "bluetooth_expanded":
                    return 165;
                case "notification":
                    return notificationLoader.item
                        ? Math.max(56, notificationLoader.item.preferredHeight)
                        : 56;
                case "reload":
                    return reloadLoader.item ? reloadLoader.item.preferredHeight : root.effectiveIslandHeight;
                case "charging":
                    return 44;
                case "silent_ring":
                    return 44;
                case "discord_call":
                    return 58;
                default:
                    return root.effectiveIslandHeight;
                }
            }
            readonly property real targetRadius: {
                if (root.overviewVisible) return root.overviewCapsuleRadius;

                switch (islandContainer.islandState) {
                case "power_menu":
                    return 36;
                case "control_center":
                    return 34;
                case "notification_center":
                    return mainCapsule.targetHeight * 36 / 165;
                case "wallpaper_picker":
                case "file_shelf":
                    return 34;
                case "application_launcher":
                case "clipboard":
                    return 34;
                case "settings_app":
                    return 32;
                case "polkit":
                    if (islandContainer.polkitSuccessMorph) return 29;
                    return 32;
                case "expanded":
                case "bluetooth_expanded":
                    return 40;
                case "notification":
                    return islandContainer.notificationExpanded ? 28 : mainCapsule.targetHeight / 2;
                case "reload":
                    return reloadLoader.item ? reloadLoader.item.preferredRadius : mainCapsule.targetHeight / 2;
                case "charging":
                case "silent_ring":
                    return 22;
                case "discord_call":
                    return 29;
                default:
                    return root.effectiveIslandCornerRadius;
                }
            }
            function sideSwipeWidthForProgress(progressValue) {
                if (progressValue < 0)
                    return root.effectiveIslandWidth + (islandContainer.customCapsuleWidth - root.effectiveIslandWidth)
                        * islandContainer.clamp01(-progressValue);
                if (progressValue > 0)
                    return root.effectiveIslandWidth + (islandContainer.lyricsCapsuleWidth - root.effectiveIslandWidth)
                        * islandContainer.clamp01(progressValue);
                return root.effectiveIslandWidth;
            }
            readonly property real sideSwipePreviewWidth: mainCapsule.sideSwipeWidthForProgress(
                islandContainer.swipeTransitionProgress
            )
            color: root.overviewContentVisible
                ? root.overviewCapsuleColor
                : (notificationHistorySurface ? "#080808" : Qt.rgba(0, 0, 0, root.effectiveIslandBackgroundOpacity / 100.0))
            y: (islandContainer.islandState === "settings_app"
                ? Math.round(((root.screen ? root.screen.height : 1080) - targetHeight) / 2)
                : root.effectiveIslandTopMargin - (1 - root.autoHideProgress) * (targetHeight + root.effectiveIslandTopMargin + 8))
            x: parent ? parent.width * root.effectiveIslandPositionX / 100 - width / 2 : 0
            clip: true
            width: displayedWidth
            height: targetHeight
            radius: targetRadius
            opacity: root.autoHideProgress
            scale: 0.96 + root.autoHideProgress * 0.04
            transformOrigin: Item.Top

            onBaseTargetWidthChanged: {
                if (!capsuleMouseArea.sideSwipeInteractive && !islandContainer.sideSwipeSettling)
                    displayedWidth = baseTargetWidth;
            }

            Behavior on displayedWidth  {
                NumberAnimation {
                    duration: capsuleMouseArea.sideSwipeInteractive ? 0 : mainCapsule.morphDuration
                    easing.type: Easing.OutQuint
                }
            }
            Behavior on height {
                enabled: !(controlCenterLoader.item && controlCenterLoader.item.batteryDrawerMoving)

                NumberAnimation {
                    duration: mainCapsule.morphDuration
                    easing.type: Easing.OutQuint
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: mainCapsule.morphDuration
                    easing.type: Easing.OutQuint
                }
            }
            Behavior on radius { NumberAnimation { duration: mainCapsule.morphDuration; easing.type: Easing.OutQuint } }
            Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.InOutQuad } }
            Behavior on outlineWidth { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            Behavior on outlineColor { ColorAnimation { duration: 260; easing.type: Easing.InOutQuad } }
            border.width: outlineWidth
            border.color: outlineColor

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Math.max(parent.radius - 1, 0)
                color: StyleTokens.transparent
                border.width: 1
                border.color: StyleTokens.overviewInnerBorder
                opacity: root.overviewContentVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.overviewContentVisible ? 260 : 140
                        easing.type: Easing.InOutQuad
                    }
                }
            }


            HoverHandler {
                id: mainCapsuleHoverHandler
                onHoveredChanged: {
                    if (hovered) {
                        if (root.autoHideEnabled) {
                            root.autoHidePointerInside = true;
                            root.showAutoHiddenIsland();
                        }
                        if (root.hoverExpandEnabled && (islandContainer.islandState === "normal" || islandContainer.islandState === "custom" || islandContainer.islandState === "lyrics")) {
                            hoverCollapseDelayTimer.stop();
                            hoverExpandDelayTimer.restart();
                        }
                    } else {
                        if (root.autoHideEnabled) {
                            root.autoHidePointerInside = false;
                            root.scheduleAutoHide();
                        }
                        if (root.hoverExpandEnabled) {
                            hoverExpandDelayTimer.stop();
                            if (islandContainer.hoverExpandedActive) {
                                hoverCollapseDelayTimer.restart();
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: capsuleMouseArea
                anchors.fill: parent
                z: -1
                enabled: !root.overviewVisible && twoFingerTouchArea.touchPoints.length < 2
                acceptedButtons: root.dynamicIslandAcceptedButtons
                preventStealing: true
                hoverEnabled: root.hoverExpandEnabled || root.autoHideEnabled
                property real swipeStartX: 0
                property real swipeStartY: 0
                property real swipeStartProgress: 0
                property real swipeLastX: 0
                readonly property real sideSwipeVerticalTolerance: 24
                property bool swipeArmed: false
                property bool swipeMoved: false
                property bool sideSwipeInteractive: false
                property bool suppressNextClick: false
                property bool preparedOverviewOnPress: false

                Timer {
                    id: swipeSuppressReset
                    interval: 180
                    repeat: false
                    onTriggered: capsuleMouseArea.suppressNextClick = false
                }

                onEntered: {
                    if (root.autoHideEnabled) {
                        root.autoHidePointerInside = true;
                        root.showAutoHiddenIsland();
                    }
                    if (root.hoverExpandEnabled && (islandContainer.islandState === "normal" || islandContainer.islandState === "custom" || islandContainer.islandState === "lyrics")) {
                        hoverCollapseDelayTimer.stop();
                        hoverExpandDelayTimer.restart();
                    }
                }

                onExited: {
                    if (root.autoHideEnabled && !mainCapsuleHoverHandler.hovered) {
                        root.autoHidePointerInside = false;
                        root.scheduleAutoHide();
                    }
                    if (root.hoverExpandEnabled && !mainCapsuleHoverHandler.hovered) {
                        hoverExpandDelayTimer.stop();
                        if (islandContainer.hoverExpandedActive) {
                            hoverCollapseDelayTimer.restart();
                        }
                    }
                }

                onPressed: (mouse) => {
                    const mappedPoint = capsuleMouseArea.mapToItem(islandContainer, mouse.x, mouse.y);
                    swipeStartX = mappedPoint.x;
                    swipeStartY = mappedPoint.y;
                    islandContainer.cancelSideSwipeSettle();
                    swipeArmed = mouse.button === Qt.LeftButton
                        && islandContainer.canShowSideSwipe;
                    swipeStartProgress = islandContainer.swipeTransitionProgress;
                    swipeLastX = mappedPoint.x;
                    swipeMoved = false;
                    sideSwipeInteractive = swipeArmed;
                    islandContainer.swipeTransitionProgress = swipeStartProgress;

                    let pressedAction = "";
                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)) {
                        pressedAction = userConfig.dynamicIslandPrimaryAction;
                    } else if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton)) {
                        pressedAction = userConfig.dynamicIslandSecondaryAction;
                    }

                    preparedOverviewOnPress = pressedAction === "openOverview"
                        || (pressedAction === "toggleOverview" && root.overviewPhase === "closed");
                    if (preparedOverviewOnPress)
                        root.prepareOverviewEverywhere();
                }

                onPositionChanged: (mouse) => {
                    if (!pressed || !swipeArmed || suppressNextClick || twoFingerTouchArea.touchPoints.length >= 2) return;

                    const mappedPoint = capsuleMouseArea.mapToItem(islandContainer, mouse.x, mouse.y);
                    const deltaX = mappedPoint.x - swipeLastX;
                    const deltaY = Math.abs(mappedPoint.y - swipeStartY);
                    const adjustedDeltaX = deltaY < sideSwipeVerticalTolerance ? deltaX : 0;
                    const nextProgress = islandContainer.advanceSideSwipeProgress(
                        islandContainer.swipeTransitionProgress,
                        adjustedDeltaX
                    );

                    swipeMoved = swipeMoved || Math.abs(nextProgress - swipeStartProgress) > 0.03 || deltaY > 6;
                    swipeLastX = mappedPoint.x;
                    islandContainer.swipeTransitionProgress = nextProgress;
                    mainCapsule.displayedWidth = mainCapsule.sideSwipePreviewWidth;
                }

                onReleased: {
                    if (swipeMoved) {
                        if (preparedOverviewOnPress)
                            root.cancelPreparedOverviewEverywhere();
                        preparedOverviewOnPress = false;
                        suppressNextClick = true;
                        swipeSuppressReset.restart();
                    }
                    let settleResult = {
                        action: "",
                        progress: islandContainer.sideSwipeRestProgressForProgress(swipeStartProgress),
                        width: islandContainer.sideSwipeRestWidthForProgress(swipeStartProgress)
                    };

                    if (swipeArmed)
                        settleResult = islandContainer.resolveSideSwipeSettle(
                            swipeStartProgress,
                            islandContainer.swipeTransitionProgress
                        );

                    sideSwipeInteractive = false;

                    if (swipeArmed)
                        islandContainer.beginSideSwipeSettle(settleResult.width);
                    else
                        mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;

                    if (swipeArmed) {
                        switch (settleResult.action) {
                        case "time":
                            islandContainer.showTimeCapsule();
                            break;
                        case "custom":
                            islandContainer.showCustomCapsule();
                            break;
                        case "lyrics":
                            islandContainer.showLyricsCapsule();
                            break;
                        default:
                            islandContainer.swipeTransitionProgress = settleResult.progress;
                        }
                    } else {
                        islandContainer.swipeTransitionProgress = settleResult.progress;
                    }
                    swipeArmed = false;
                    swipeMoved = false;
                }

                onCanceled: {
                    if (preparedOverviewOnPress)
                        root.cancelPreparedOverviewEverywhere();
                    swipeArmed = false;
                    swipeMoved = false;
                    sideSwipeInteractive = false;
                    suppressNextClick = false;
                    preparedOverviewOnPress = false;
                    swipeSuppressReset.stop();
                    mainCapsule.displayedWidth = mainCapsule.baseTargetWidth;
                    islandContainer.swipeTransitionProgress = islandContainer.swipeRestProgressForState();
                }

                onClicked: (mouse) => {
                    islandContainer.hoverExpandedActive = false;
                    hoverExpandDelayTimer.stop();
                    hoverCollapseDelayTimer.stop();

                    if (suppressNextClick) {
                        swipeSuppressReset.stop();
                        suppressNextClick = false;
                        preparedOverviewOnPress = false;
                        return;
                    }

                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)) {
                        if (islandContainer.toggleNotificationExpansionIfNeeded()) {
                            if (preparedOverviewOnPress)
                                root.cancelPreparedOverviewEverywhere();
                            preparedOverviewOnPress = false;
                            return;
                        }

                        preparedOverviewOnPress = false;
                        const action = userConfig.dynamicIslandPrimaryAction && userConfig.dynamicIslandPrimaryAction !== "toggleExpandedPlayer"
                            ? userConfig.dynamicIslandPrimaryAction : "toggleControlCenter";
                        islandContainer.handleConfiguredClickAction(action);
                        return;
                    }

                    if (mouse.button === userConfig.mouseButton(userConfig.dynamicIslandSecondaryButton)) {
                        preparedOverviewOnPress = false;
                        islandContainer.handleConfiguredClickAction(userConfig.dynamicIslandSecondaryAction);
                    }
                }
            }

            MultiPointTouchArea {
                id: twoFingerTouchArea
                anchors.fill: parent
                z: 0
                enabled: !root.overviewVisible
                mouseEnabled: false
                minimumTouchPoints: 2
                maximumTouchPoints: 2

                property real swipeStartX: 0
                property real swipeStartProgress: 0
                property bool swipeMoved: false

                onPressed: (touchPoints) => {
                    const centerPoint = islandContainer.mapFromItem(twoFingerTouchArea, 
                        (touchPoints[0].x + touchPoints[1].x) / 2,
                        (touchPoints[0].y + touchPoints[1].y) / 2);
                    swipeStartX = centerPoint.x;
                    swipeStartProgress = islandContainer.swipeTransitionProgress;
                    swipeMoved = false;
                    islandContainer.cancelSideSwipeSettle();
                }

                onUpdated: (touchPoints) => {
                    const centerPoint = islandContainer.mapFromItem(twoFingerTouchArea, 
                        (touchPoints[0].x + touchPoints[1].x) / 2,
                        (touchPoints[0].y + touchPoints[1].y) / 2);
                    
                    const deltaX = centerPoint.x - swipeStartX;
                    const nextProgress = islandContainer.advanceSideSwipeProgress(
                        swipeStartProgress,
                        deltaX
                    );

                    if (Math.abs(nextProgress - swipeStartProgress) > 0.03) {
                        swipeMoved = true;
                    }

                    islandContainer.swipeTransitionProgress = nextProgress;
                    mainCapsule.displayedWidth = mainCapsule.sideSwipePreviewWidth;
                }

                onReleased: {
                    if (swipeMoved) {
                        const settleResult = islandContainer.resolveSideSwipeSettle(
                            swipeStartProgress,
                            islandContainer.swipeTransitionProgress
                        );

                        islandContainer.beginSideSwipeSettle(settleResult.width);

                        switch (settleResult.action) {
                        case "time":
                            islandContainer.showTimeCapsule();
                            break;
                        case "custom":
                            islandContainer.showCustomCapsule();
                            break;
                        case "lyrics":
                            islandContainer.showLyricsCapsule();
                            break;
                        default:
                            islandContainer.swipeTransitionProgress = settleResult.progress;
                        }
                    } else {
                        islandContainer.swipeTransitionProgress = islandContainer.sideSwipeRestProgressForProgress(swipeStartProgress);
                    }
                    swipeMoved = false;
                }
            }



            Loader {
                id: customSwipeLoader
                anchors.fill: parent
                active: islandContainer.customSwipeVisible
                asynchronous: false
                visible: active

                onLoaded: islandContainer.syncCustomCapsuleWidth()

                sourceComponent: Component {
                    SwipeCustomInfoLayer {
                        accentColor: pywalColors.accent
                        items: islandContainer.customLeftItems
                        cavaLevels: islandContainer.cavaLevels
                        timeText: timeObj.currentTime
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.heroFontFamily
                        timeFontFamily: root.heroFontFamily
                        textPixelSize: root.bodyFontSize
                        iconPixelSize: root.iconFontSize
                        minimumWidth: 220
                        maximumWidth: Math.max(220, root.width - 48)
                        transitionProgress: islandContainer.swipeTransitionProgress
                        recordingActive: islandContainer.screenRecordingActive
                        showSecondaryText: islandContainer.workspaceOriginSide !== "left"
                            && islandContainer.splitOriginSide !== "left"
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncCustomCapsuleWidth()
                    }
                }
            }

            Loader {
                id: lyricsSwipeLoader
                anchors.fill: parent
                active: islandContainer.lyricsSwipeVisible
                asynchronous: false
                visible: active

                onLoaded: islandContainer.syncLyricsCapsuleWidth()

                sourceComponent: Component {
                    SwipeLyricsLayer {
                        accentColor: pywalColors.accent
                        lyricText: islandContainer.lyricsDisplayText
                        currentArtUrl: islandContainer.currentArtUrl
                        cavaLevels: islandContainer.cavaLevels
                        timeText: timeObj.currentTime
                        textFontFamily: root.textFontFamily
                        timeFontFamily: root.timeFontFamily
                        textPixelSize: root.bodyFontSize
                        minimumWidth: 220
                        maximumWidth: Math.max(220, root.width - 48)
                        transitionProgress: islandContainer.rightSwipeProgress
                        recordingActive: islandContainer.screenRecordingActive
                        showSecondaryText: islandContainer.workspaceOriginSide !== "right"
                            && islandContainer.splitOriginSide !== "right"
                        showCondition: true
                        onPreferredWidthChanged: islandContainer.syncLyricsCapsuleWidth()
                    }
                }
            }

            Loader {
                id: splitIconLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.splitShowsIconOnly
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    SplitIconLayer {
                        iconText: islandContainer.splitIcon
                        iconFontFamily: root.iconFontFamily
                        transitionProgress: islandContainer.swipeTransitionProgress
                        slideDirection: islandContainer.splitOriginSide
                        showCondition: true
                    }
                }
            }

            Loader {
                id: osdLayerLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.splitUsesExtendedLayout
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    OsdLayer {
                        iconText: islandContainer.splitIcon
                        progress: islandContainer.osdProgress
                        customText: islandContainer.osdCustomText
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        transitionProgress: islandContainer.swipeTransitionProgress
                        slideDirection: islandContainer.splitOriginSide
                        showCondition: true
                    }
                }
            }

            Loader {
                id: workspaceLayerLoader
                anchors.fill: parent
                active: !root.overviewVisible
                asynchronous: false
                visible: active && islandContainer.islandState === "long_capsule"

                sourceComponent: Component {
                    WorkspaceLayer {
                        workspaceId: islandContainer.currentWs
                        displayText: "Workspace " + islandContainer.currentWs
                        textFontFamily: root.textFontFamily
                        textPixelSize: root.bodyFontSize
                        animateVisibility: islandContainer.restingState === "normal"
                        transitionProgress: islandContainer.swipeTransitionProgress
                        showCondition: islandContainer.islandState === "long_capsule"
                        slideDirection: islandContainer.workspaceOriginSide
                    }
                }
            }

            Loader {
                id: expandedPlayerLoader
                anchors.fill: parent
                active: islandContainer.expandedLayerVisible
                asynchronous: false
                visible: active
                onLoaded: {
                    if (islandContainer.openTimerPageWhenExpanded
                            && item && item.openTimerPage) {
                        item.openTimerPage();
                        islandContainer.openTimerPageWhenExpanded = false;
                    }
                    root.focusExpandedPlayer();
                }

                sourceComponent: Component {
                    ExpandedPlayerLayer {
                        accentColor: pywalColors.accent
                        currentArtUrl: islandContainer.currentArtUrl
                        currentTrack: islandContainer.currentTrack !== "" ? islandContainer.currentTrack : "Starboy"
                        currentArtist: islandContainer.currentArtist !== "" ? islandContainer.currentArtist : "The Weeknd"
                        timePlayed: islandContainer.timePlayed !== "" ? islandContainer.timePlayed : "1:24"
                        timeTotal: islandContainer.timeTotal !== "" ? islandContainer.timeTotal : "3:50"
                        trackProgress: islandContainer.trackProgress > 0 ? islandContainer.trackProgress : 0.36
                        activePlayer: islandContainer.activePlayer
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        timerSelectedHours: islandContainer.timerSelectedHours
                        timerSelectedMinutes: islandContainer.timerSelectedMinutes
                        timerTotalSeconds: islandContainer.timerTotalSeconds
                        timerRemainingSeconds: islandContainer.timerRemainingSeconds
                        timerRunning: islandContainer.timerRunning
                        timerActive: islandContainer.timerActive
                        showCondition: islandContainer.expandedLayerVisible
                        onControlPressed: islandContainer.suppressCapsuleClick()
                        onBackgroundClicked: islandContainer.smartRestoreState()
                        onCloseRequested: islandContainer.smartRestoreState()
                        onKeyboardFocusRequested: islandContainer.requestExpandedPlayerKeyboardFocus()
                        onKeyboardFocusReleased: islandContainer.releaseExpandedPlayerKeyboardFocus()
                        onPreviousRequested: mediaController.previous()
                        onTimerToggleRequested: function(hours, minutes) {
                            islandContainer.toggleTimer(hours, minutes);
                        }
                        onTimerResetRequested: islandContainer.resetTimer()
                        onTimerDurationRequested: function(hours, minutes) {
                            if (!islandContainer.timerActive)
                                islandContainer.syncTimerDuration(hours, minutes);
                        }
                    }
                }
            }

            Loader {
                id: bluetoothExpandedLoader
                anchors.fill: parent
                active: islandContainer.bluetoothExpandedLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    BluetoothExpandedLayer {
                        device: islandContainer.bluetoothExpandedDevice
                        volumeLevel: islandContainer.currentVolume
                        iconText: ""
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.bluetoothExpandedLayerVisible
                    }
                }
            }

            Loader {
                id: notificationLoader
                anchors.fill: parent
                active: islandContainer.notificationLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    NotificationLayer {
                        appName: islandContainer.notificationAppName
                        summary: islandContainer.notificationSummary
                        body: islandContainer.notificationBody
                        expanded: islandContainer.notificationExpanded
                        toggleButton: userConfig.mouseButton(userConfig.dynamicIslandPrimaryButton)
                        iconText: {
                            if (islandContainer.notificationIcon !== "")
                                return islandContainer.notificationIcon;
                            if (islandContainer.notificationAppName === "Wi-Fi" || islandContainer.notificationAppName === "wifi")
                                return "";
                            return root.notificationStatusIcon;
                        }
                        iconColor: islandContainer.notificationIconColor
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: true
                        onExpansionToggleRequested: {
                            islandContainer.suppressCapsuleClick(true);
                            islandContainer.toggleNotificationExpansionIfNeeded();
                        }
                    }
                }
            }

            Loader {
                id: reloadLoader
                anchors.fill: parent
                active: islandContainer.reloadLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    ReloadLayer {
                        failed: islandContainer.reloadFailed
                        errorString: islandContainer.reloadErrorString
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        accentColor: pywalColors.accent
                        showCondition: islandContainer.reloadLayerVisible
                        onDismissRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: batteryAlertLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.islandState === "charging"
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    BatteryAlertLayer {
                        mode: islandContainer.batteryAlertMode
                        capacity: islandContainer.batteryAlertCapacity
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        iconFontFamily: root.iconFontFamily
                        showCondition: true
                    }
                }
            }

            Loader {
                id: silentRingLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.islandState === "silent_ring"
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    SilentRingLayer {
                        isMuted: islandContainer.silentRingIsMuted
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        iconFontFamily: root.iconFontFamily
                        showCondition: true
                    }
                }
            }

            Loader {
                id: discordCallLoader
                anchors.fill: parent
                active: !root.overviewVisible && islandContainer.islandState === "discord_call"
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    DiscordCallLayer {
                        callerName: islandContainer.discordCallerName
                        subtitle: islandContainer.discordCallSubtitle
                        avatarUrl: islandContainer.discordCallAvatarUrl
                        ongoing: islandContainer.discordCallOngoing
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        iconFontFamily: root.iconFontFamily
                        showCondition: true
                        onAccepted: root.acceptDiscordCall()
                        onDeclined: root.declineDiscordCall()
                        onCallerClicked: root.focusDiscordWindow()
                    }
                }
            }

            Loader {
                id: controlCenterLoader
                anchors.fill: parent
                active: islandContainer.controlCenterLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    ControlCenterLayer {
                        userConfigData: (root.dynamicConfig && root.dynamicConfig.controlCenterCanvasLayout)
                            ? { controlCenterCanvasLayout: root.dynamicConfig.controlCenterCanvasLayout }
                            : localUserConfigFile.parsedData
                        accentColor: pywalColors.accent
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        currentTime: timeObj.currentTime
                        currentDateLabel: timeObj.currentDateLabel
                        batteryCapacity: islandContainer.batteryCapacity
                        isCharging: islandContainer.isCharging
                        volumeLevel: islandContainer.currentVolume
                        brightnessLevel: islandContainer.currentBrightness
                        currentWorkspace: islandContainer.currentWs
                        currentTrack: islandContainer.currentTrack
                        currentArtist: islandContainer.currentArtist
                        nightLightEnabled: root.shellRootController && root.shellRootController.nightLightEnabled !== undefined
                            ? root.shellRootController.nightLightEnabled
                            : false
                        showCondition: islandContainer.controlCenterLayerVisible
                        notificationModel: islandContainer.notificationHistoryModel
                        onFocusModeChanged: function(enabled) {
                            if (root.shellRootController && root.shellRootController.focusEnabled !== undefined)
                                root.shellRootController.focusEnabled = enabled;
                        }
                        onNightLightModeChanged: function(enabled) {
                            if (root.shellRootController && root.shellRootController.nightLightEnabled !== undefined)
                                root.shellRootController.nightLightEnabled = enabled;
                        }
                        onRequestNotification: function(appName, summary, body) {
                            islandContainer.showNotificationCapsule(appName, summary, body);
                        }
                        onConnectivityPanelRequested: function(kind, open) {
                        }
                        onSettingsRequested: {
                            islandContainer.showSettingsApp();
                        }
                        onClipboardRequested: {
                            islandContainer.showClipboard();
                        }
                        onCloseRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: powerMenuLoader
                anchors.fill: parent
                active: islandContainer.powerMenuLayerVisible
                asynchronous: false
                visible: islandContainer.powerMenuLayerVisible
                onLoaded: {
                    if (item) item.forceActiveFocus();
                }

                sourceComponent: Component {
                    PowerMenuLayer {
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        accentColor: pywalColors.accent
                        showCondition: islandContainer.powerMenuLayerVisible
                        onCloseRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: notificationCenterLoader
                anchors.fill: parent
                active: islandContainer.notificationCenterLayerVisible
                asynchronous: false
                visible: active

                sourceComponent: Component {
                    NotificationCenterLayer {
                        notificationModel: islandContainer.notificationHistoryModel
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily

                        onClearAllRequested: {
                            islandContainer.notificationHistoryModel.clear();
                        }
                    }
                }
            }

            Loader {
                id: wallpaperPickerLoader
                anchors.fill: parent
                active: islandContainer.wallpaperPickerLayerVisible
                asynchronous: false
                visible: islandContainer.wallpaperPickerLayerVisible
                onLoaded: root.focusWallpaperPicker()

                sourceComponent: Component {
                    WallpaperPickerLayer {
                        dynamicConfig: root.dynamicConfig
                        accentColor: pywalColors.accent
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        activeWallpaper: root.effectiveWallpaperPath
                        showCondition: islandContainer.wallpaperPickerLayerVisible
                        onWallpaperApplied: filePath => root.wallpaperPickerActiveWallpaper = filePath
                        onWallpaperApplySucceeded: filePath => root.handleWallpaperApplySucceeded(filePath)
                        onCloseRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: applicationLauncherLoader
                anchors.fill: parent
                active: islandContainer.applicationLauncherLayerVisible
                asynchronous: false
                visible: islandContainer.applicationLauncherLayerVisible
                onLoaded: root.focusApplicationLauncher()

                sourceComponent: Component {
                    ApplicationLauncherLayer {
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.applicationLauncherLayerVisible
                        onCloseRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: clipboardLoader
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: 800
                active: islandContainer.clipboardLayerVisible
                asynchronous: false
                visible: islandContainer.clipboardLayerVisible
                onLoaded: root.focusClipboard()

                sourceComponent: Component {
                    ClipboardLayer {
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        accentColor: pywalColors.accent
                        showCondition: islandContainer.clipboardLayerVisible
                        onCloseRequested: islandContainer.smartRestoreState()
                        onItemCopied: function(msg) {
                            islandContainer.smartRestoreState();
                        }
                    }
                }
            }

            Loader {
                id: settingsAppLoader
                anchors.fill: parent
                active: islandContainer.settingsAppLayerVisible
                asynchronous: false
                visible: islandContainer.settingsAppLayerVisible
                onLoaded: root.focusSettingsApp()

                sourceComponent: Component {
                    SettingsAppLayer {
                        dynamicConfig: root.dynamicConfig
                        accentColor: pywalColors.accent
                        showCondition: islandContainer.settingsAppLayerVisible
                        onCloseRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: fileShelfLoader
                anchors.fill: parent
                active: islandContainer.fileShelfLayerVisible
                asynchronous: false
                visible: islandContainer.fileShelfLayerVisible
                onLoaded: {
                    if (islandContainer.fileShelfOpenedManually)
                        root.focusFileShelf();
                }

                sourceComponent: Component {
                    FileShelfLayer {
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        showCondition: islandContainer.fileShelfLayerVisible
                        dropPreviewOnly: !islandContainer.fileShelfOpenedManually
                        onCloseRequested: islandContainer.smartRestoreState()
                    }
                }
            }

            Loader {
                id: polkitLoader
                anchors.fill: parent
                active: islandContainer.polkitLayerVisible
                asynchronous: false
                visible: islandContainer.polkitLayerVisible
                focus: true
                onLoaded: root.focusPolkit()

                sourceComponent: Component {
                    PolkitLayer {
                        polkitAgent: root.polkitAgent
                        accentColor: pywalColors.accent
                        iconFontFamily: root.iconFontFamily
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        showCondition: islandContainer.polkitLayerVisible
                        onCloseRequested: {
                            if (root.polkitAgent && root.polkitAgent.flow) {
                                root.polkitAgent.flow.cancelAuthenticationRequest();
                            }
                            islandContainer.polkitSuccessMorph = false;
                            islandContainer.smartRestoreState();
                        }
                    }
                }
            }

            DropArea {
                id: islandFileDropArea
                z: 10000
                anchors.fill: parent
                enabled: islandContainer.fileShelfLayerVisible
                    || islandContainer.fileShelfCanAutoOpen

                onEntered: drag => {
                    if (!root.dragCarriesFiles(drag)) {
                        drag.accepted = false;
                        return;
                    }

                    drag.accept(Qt.CopyAction);
                    if (!islandContainer.fileShelfLayerVisible)
                        islandContainer.showFileShelf(false);
                    root.showAutoHiddenIsland("state");
                }

                onExited: islandContainer.closeAutoOpenedFileShelf()

                onDropped: drop => {
                    if (!root.dragCarriesFiles(drop)) {
                        drop.accepted = false;
                        return;
                    }

                    root.addFilesFromDrop(drop);
                    drop.accept(Qt.CopyAction);
                    islandContainer.closeAutoOpenedFileShelf();
                }
            }

            Rectangle {
                z: 9999
                anchors.fill: parent
                radius: mainCapsule.radius
                color: StyleTokens.clearBlack
                border.width: islandFileDropArea.containsDrag ? 2 : 0
                border.color: StyleTokens.accent
                visible: islandFileDropArea.containsDrag
            }

            Loader {
                id: overviewLoader

                anchors.fill: parent
                active: root.overviewLoaderActive
                asynchronous: false
                visible: root.overviewContentVisible

                onStatusChanged: {
                    if (status === Loader.Ready && root.overviewPreparing) {
                        root.beginOverviewOpening();
                        root.focusOverview();
                    }
                }

                sourceComponent: Component {
                    WorkspaceOverviewScene {
                        screen: root.screen
                        showCondition: root.overviewVisible
                        previewsEnabled: root.overviewContentVisible
                        textFontFamily: root.textFontFamily
                        heroFontFamily: root.heroFontFamily
                        wallpaperPath: root.overviewWallpaperSource !== "" ? root.overviewWallpaperSource : root.effectiveWallpaperUrl
                        windowCornerRadius: root.overviewWindowCornerRadius
                        onCloseRequested: root.closeOverviewEverywhere()
                    }
                }
            }

        }

        Item {
            id: fileShelfBubble

            readonly property int bubbleSize: 36

            width: bubbleSize
            height: bubbleSize
            x: mainCapsule.x - width - 8
            y: mainCapsule.y + mainCapsule.height / 2 - height / 2
            z: 6
            visible: islandContainer.fileShelfBubbleWanted
            opacity: root.autoHideProgress
            scale: 0.96 + root.autoHideProgress * 0.04
            transformOrigin: Item.Center

            Behavior on opacity {
                NumberAnimation { duration: StyleTokens.durationFast }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: StyleTokens.black
                border.width: 1
                border.color: StyleTokens.inputBorder

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -1
                    text: "\uf08d"
                    color: StyleTokens.textPrimary
                    font.family: root.iconFontFamily
                    font.pixelSize: 13
                    rotation: -18
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: -2
                    anchors.bottomMargin: -2
                    width: Math.max(17, countText.implicitWidth + 8)
                    height: 17
                    radius: height / 2
                    color: StyleTokens.accent
                    border.width: 2
                    border.color: StyleTokens.black

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: FileShelf.count > 99 ? "99+" : String(FileShelf.count)
                        color: StyleTokens.white
                        font.family: root.textFontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: fileShelfBubble.visible && root.autoHideProgress > 0.5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    islandContainer.showFileShelf(true);
                    root.showAutoHiddenIsland("state");
                }
            }
        }

        Item {
            id: timerBubble

            property bool mounted: islandContainer.timerBubbleWanted
            property real reveal: islandContainer.timerBubbleWanted ? 1 : 0
            readonly property int bubbleSize: 34
            readonly property real hiddenX: mainCapsule.x + mainCapsule.width - width * 0.62
            readonly property real shownX: mainCapsule.x + mainCapsule.width + 8
            readonly property real centerY: mainCapsule.y + mainCapsule.height / 2 - height / 2

            width: bubbleSize
            height: bubbleSize
            x: hiddenX + (shownX - hiddenX) * reveal
            y: centerY + (1 - reveal) * 10
            z: 6
            visible: mounted
            opacity: reveal * root.autoHideProgress
            scale: (0.55 + reveal * 0.45) * (0.96 + root.autoHideProgress * 0.04) * (1 + islandContainer.timerCompletionPulse * 0.12)
            transformOrigin: Item.Center

            Connections {
                target: islandContainer

                function onTimerBubbleWantedChanged() {
                    timerBubbleShowAnimation.stop();
                    timerBubbleHideAnimation.stop();

                    if (islandContainer.timerBubbleWanted) {
                        timerBubble.mounted = true;
                        timerBubbleShowAnimation.restart();
                    } else {
                        timerBubbleHideAnimation.restart();
                    }
                }

                function onTimerProgressChanged() {
                    timerBubbleRing.requestPaint();
                }

                function onTimerRemainingSecondsChanged() {
                    timerBubbleRing.requestPaint();
                }

                function onTimerTotalSecondsChanged() {
                    timerBubbleRing.requestPaint();
                }

                function onTimerCompletionAnimatingChanged() {
                    timerBubbleRing.requestPaint();
                }

                function onTimerCompletionFlashChanged() {
                    timerBubbleRing.requestPaint();
                }
            }

            NumberAnimation {
                id: timerBubbleShowAnimation

                target: timerBubble
                property: "reveal"
                from: timerBubble.reveal
                to: 1
                duration: 360
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: timerBubbleHideAnimation

                target: timerBubble
                property: "reveal"
                from: timerBubble.reveal
                to: 0
                duration: 280
                easing.type: Easing.InCubic
                onStopped: {
                    if (!islandContainer.timerBubbleWanted && timerBubble.reveal <= 0.001)
                        timerBubble.mounted = false;
                }
            }

            SequentialAnimation {
                id: timerBubbleCompletionAnimation

                running: islandContainer.timerCompletionAnimating

                onStarted: {
                    timerBubbleShowAnimation.stop();
                    timerBubbleHideAnimation.stop();
                    timerBubble.mounted = true;
                    timerBubble.reveal = 1;
                }

                onStopped: {
                    if (islandContainer.timerCompletionAnimating)
                        islandContainer.timerCompletionAnimating = false;
                    islandContainer.timerCompletionPulse = 0;
                    islandContainer.timerCompletionFlash = 0;
                    timerBubbleRing.requestPaint();
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: islandContainer
                        property: "timerCompletionPulse"
                        from: 0
                        to: 1
                        duration: 140
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: islandContainer
                        property: "timerCompletionFlash"
                        from: 0
                        to: 1
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: islandContainer
                        property: "timerCompletionPulse"
                        from: 1
                        to: 0
                        duration: 380
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: islandContainer
                        property: "timerCompletionFlash"
                        from: 1
                        to: 0
                        duration: 380
                        easing.type: Easing.InOutQuad
                    }
                }

                PauseAnimation {
                    duration: 380
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: width / 2
                color: StyleTokens.black
            }

            Canvas {
                id: timerBubbleRing

                anchors.fill: parent
                anchors.margins: 1

                Component.onCompleted: requestPaint()
                onVisibleChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    const centerX = width / 2;
                    const centerY = height / 2;
                    const completionActive = islandContainer.timerCompletionAnimating;
                    const flash = Math.max(0, Math.min(1, islandContainer.timerCompletionFlash));
                    const lineWidth = completionActive ? 3 + flash : 3;
                    const radius = Math.min(width, height) / 2 - lineWidth / 2;
                    const progress = Math.max(0, Math.min(1, islandContainer.timerProgress));
                    const startAngle = -Math.PI / 2;
                    const endAngle = startAngle - Math.PI * 2 * progress;

                    ctx.clearRect(0, 0, width, height);
                    ctx.lineCap = "round";
                    ctx.lineWidth = lineWidth;

                    ctx.beginPath();
                    ctx.strokeStyle = "#303036";
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                    ctx.stroke();

                    if (completionActive) {
                        if (flash > 0) {
                            ctx.beginPath();
                            ctx.lineWidth = lineWidth + 1.5;
                            ctx.strokeStyle = "rgba(255, 204, 0, " + (0.18 * flash) + ")";
                            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                            ctx.stroke();
                        }

                        ctx.beginPath();
                        ctx.lineWidth = lineWidth;
                        ctx.strokeStyle = "rgba(255, 204, 0, " + (0.72 + 0.28 * flash) + ")";
                        ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                        ctx.stroke();
                    } else if (progress > 0) {
                        ctx.beginPath();
                        ctx.strokeStyle = "#ffcc00";
                        ctx.arc(centerX, centerY, radius, startAngle, endAngle, true);
                        ctx.stroke();
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -1
                text: "󰔛"
                color: "white"
                font.pixelSize: root.iconFontSize - 1
                font.family: root.iconFontFamily
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                enabled: timerBubble.mounted && root.autoHideProgress > 0.5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    if (root.autoHideEnabled) {
                        root.autoHidePointerInside = true;
                        root.showAutoHiddenIsland();
                    }
                }
                onExited: {
                    if (root.autoHideEnabled) {
                        root.autoHidePointerInside = false;
                        root.scheduleAutoHide();
                    }
                }
                onClicked: islandContainer.showExpandedTimerPage()
            }
        }

        ConnectivityDetailShell {
            id: wifiConnectivityDetailShell
            open: false
            mounted: false
            visible: false
            enabled: false
        }

        ConnectivityDetailShell {
            id: bluetoothConnectivityDetailShell
            open: false
            mounted: false
            visible: false
            enabled: false
        }

        ConnectivityDetailShell {
            id: powerConnectivityDetailShell
            open: false
            mounted: false
            visible: false
            enabled: false
        }
    }

    MouseArea {
        id: autoHideRevealArea

        x: root.autoHideRevealX
        y: 0
        z: 20
        width: root.autoHideRevealWidth
        height: root.autoHideRevealHeight
        enabled: root.autoHideEnabled
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onEntered: {
            root.autoHidePointerInside = true;
            root.showAutoHiddenIsland("edge");
        }

        onExited: {
            root.autoHidePointerInside = false;
            root.scheduleAutoHide();
        }
    }

    IslandRootGestureArea {
        anchors.fill: parent
        enabled: root.topGestureInputActive
        islandController: islandContainer
        capsule: mainCapsule
    }
}
