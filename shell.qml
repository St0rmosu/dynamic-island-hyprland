import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit
import IslandBackend
import "qml/config"

Scope {
    id: shellRoot

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    DynamicConfig {
        id: dynamicConfig
    }

    readonly property alias dynamicConfig: dynamicConfig

    readonly property bool screenRecordingActive: SystemServices.screenRecordingActive
    property bool focusEnabled: false
    property bool nightLightEnabled: false
    property bool shuttingDown: false
    property bool islandAutoHideRuntimeEnabled: true

    readonly property var userConfig: UserConfig

    PolkitAgent {
        id: polkitAgent

        onIsActiveChanged: {
            console.log("[DynamicIsland] PolkitAgent isActive:", isActive);
            if (isActive) {
                shellRoot.showPolkitPromptAll();
            } else {
                shellRoot.handlePolkitFinishedAll();
            }
        }
    }

    readonly property alias polkitAgent: polkitAgent

    function showPolkitPromptAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.showPolkitPrompt)
                window.showPolkitPrompt();
        });
    }

    function handlePolkitFinishedAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.handlePolkitFinished)
                window.handlePolkitFinished();
            else if (window && window.closePolkitPrompt)
                window.closePolkitPrompt();
        });
    }

    function closePolkitPromptAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.closePolkitPrompt)
                window.closePolkitPrompt();
        });
    }

    function forEachWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window)
                callback(window);
        }
    }

    function showReloadAll(failed, errorString) {
        shellRoot.forEachWindow((window) => {
            if (window && window.showReload)
                window.showReload(failed, errorString);
        });
    }

    function showNotificationAll(appName, summary, body, icon, customColor) {
        if (focusEnabled)
            return;

        shellRoot.forEachWindow((window) => {
            if (window && window.showNotification)
                window.showNotification(appName, summary, body, icon, customColor);
        });
    }

    function showChargingAll(capacity, isCharging) {
        shellRoot.forEachWindow((window) => {
            if (window && window.showCharging)
                window.showCharging(capacity, isCharging);
        });
    }

    function showLowBatteryAll(capacity) {
        shellRoot.forEachWindow((window) => {
            if (window && window.showLowBattery)
                window.showLowBattery(capacity);
        });
    }

    function showSilentRingAll(isMuted) {
        shellRoot.forEachWindow((window) => {
            if (window && window.showSilentRing)
                window.showSilentRing(isMuted);
        });
    }

    function showDiscordCallAll(callerName, subtitle, avatarUrl) {
        shellRoot.forEachWindow((window) => {
            if (window && window.showDiscordCall)
                window.showDiscordCall(callerName, subtitle, avatarUrl);
        });
    }

    function closeDiscordCallAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.closeDiscordCall)
                window.closeDiscordCall();
        });
    }

    function anyOverviewOpen() {
        if (CompositorBackend.compositor === "niri")
            return false;

        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && window.overviewPhase !== "closed")
                return true;
        }

        return false;
    }

    function prepareOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.prepareOverview());
    }

    function cancelPreparedOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.cancelPreparedOverview());
    }

    function openOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.openOverview());
    }

    function closeOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        shellRoot.forEachWindow((window) => window.closeOverview());
    }

    function toggleOverviewAll() {
        if (CompositorBackend.compositor === "niri")
            return;

        if (shellRoot.anyOverviewOpen())
            shellRoot.closeOverviewAll();
        else
            shellRoot.openOverviewAll();
    }

    function anyIslandShown() {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && window.autoHideTargetVisible)
                return true;
        }

        return false;
    }

    function showIslandAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.showIslandWindow)
                window.showIslandWindow();
        });
    }

    function hideIslandAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.hideIslandWindow)
                window.hideIslandWindow();
        });
    }

    function toggleIslandAll() {
        if (shellRoot.anyIslandShown())
            shellRoot.hideIslandAll();
        else
            shellRoot.showIslandAll();
    }

    function refreshIslandAutoHideAll() {
        shellRoot.forEachWindow((window) => {
            if (window && window.refreshAutoHideWindow)
                window.refreshAutoHideWindow();
        });
    }

    function refreshOverviewWallpaperCaches(wallpaperPath) {
        shellRoot.forEachWindow((window) => {
            if (window
                    && wallpaperPath !== undefined
                    && wallpaperPath !== null
                    && String(wallpaperPath) !== "") {
                window.wallpaperPickerActiveWallpaper = String(wallpaperPath);
            }
            if (window && window.refreshWallpaperSources)
                window.refreshWallpaperSources();
            if (window && window.prewarmWallpaperCache)
                window.prewarmWallpaperCache();
        });
    }

    function forFocusedWindow(callback) {
        const windows = panelVariants.instances ? panelVariants.instances : [];
        let fallbackWindow = null;
        for (let index = 0; index < windows.length; index++) {
            const window = windows[index];
            if (window && !fallbackWindow)
                fallbackWindow = window;
            if (window && window.monitorFocused) {
                callback(window);
                return;
            }
        }

        if (fallbackWindow)
            callback(fallbackWindow);
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            shellRoot.toggleOverviewAll();
        }

        function open() {
            shellRoot.openOverviewAll();
        }

        function close() {
            shellRoot.closeOverviewAll();
        }

        function refreshWallpaperCache() {
            shellRoot.refreshOverviewWallpaperCaches();
        }
    }

    IpcHandler {
        target: "island"

        function show() {
            shellRoot.showIslandAll();
        }

        function open() {
            shellRoot.showIslandAll();
        }

        function reveal() {
            shellRoot.showIslandAll();
        }

        function hide() {
            shellRoot.hideIslandAll();
        }

        function toggle() {
            shellRoot.toggleIslandAll();
        }

        function enableAutoHide() {
            shellRoot.islandAutoHideRuntimeEnabled = true;
            shellRoot.refreshIslandAutoHideAll();
        }

        function disableAutoHide() {
            shellRoot.islandAutoHideRuntimeEnabled = false;
            shellRoot.showIslandAll();
        }

        function showReload(failed: bool, error: string) {
            shellRoot.showReloadAll(failed, error);
        }


        function testWifiDisconnect() {
            shellRoot.showNotificationAll(
                "Wi-Fi",
                "Wi-Fi disconnesso",
                "da TIM-94674062",
                "",
                "#ff9f0a"
            );
        }

        function testCharging(capacity: int) {
            const cap = (capacity !== undefined && capacity > 0) ? capacity : 78;
            shellRoot.showChargingAll(cap, true);
        }

        function testLowBattery(capacity: int) {
            const cap = (capacity !== undefined && capacity > 0) ? capacity : 20;
            shellRoot.showLowBatteryAll(cap);
        }

        function testSilentRing(muted: bool) {
            const m = muted !== undefined ? muted : true;
            shellRoot.showSilentRingAll(m);
        }

        function testDiscordCall(name: string) {
            const n = (name !== undefined && name !== "") ? name : "Discord Call";
            shellRoot.showDiscordCallAll(n, "Chiamata in arrivo...", "");
            avatarResolverProc.pendingCaller = n;
            avatarResolverProc.pendingSubtitle = "Chiamata in arrivo...";
            avatarResolverProc.command = [shellRoot.homeDir + "/.config/quickshell/dynamic-island/scripts/resolve_discord_avatar.py", n];
            avatarResolverProc.running = false;
            avatarResolverProc.running = true;
        }

        function testDiscordCallWithAvatar(name: string, avatar: string) {
            const n = (name !== undefined && name !== "") ? name : "Discord Call";
            shellRoot.showDiscordCallAll(n, "Chiamata in arrivo...", avatar || "");
        }

        function incomingCall(name: string, subtitle: string, avatar: string) {
            shellRoot.showDiscordCallAll(name || "Discord Call", subtitle || "Chiamata in arrivo...", avatar || "");
        }

        function testDiscordCallOngoing(name: string) {
            const n = (name !== undefined && name !== "") ? name : "St0rm";
            shellRoot.forEachWindow((window) => {
                if (window && window.showDiscordOngoingCall)
                    window.showDiscordOngoingCall(n, "00:42", "");
            });
        }

        function acceptCall() {
            shellRoot.forEachWindow((window) => {
                if (window && window.acceptDiscordCall)
                    window.acceptDiscordCall();
            });
        }

        function declineCall() {
            shellRoot.forEachWindow((window) => {
                if (window && window.declineDiscordCall)
                    window.declineDiscordCall();
            });
        }

        function callAccepted() {
            shellRoot.forEachWindow((window) => {
                if (window && window.setDiscordCallOngoing)
                    window.setDiscordCallOngoing();
            });
        }

        function closeCall() {
            shellRoot.closeDiscordCallAll();
        }

        function endCall() {
            shellRoot.closeDiscordCallAll();
        }

        function cancelCall() {
            shellRoot.closeDiscordCallAll();
        }

        function testVolume(level: int) {
            const lvl = (level !== undefined && level >= 0) ? level : 65;
            shellRoot.forEachWindow((window) => {
                if (window && window.showOsdWindow)
                    window.showOsdWindow("", lvl / 100.0, "");
            });
        }

        function testBrightness(level: int) {
            const lvl = (level !== undefined && level >= 0) ? level : 80;
            shellRoot.forEachWindow((window) => {
                if (window && window.showOsdWindow)
                    window.showOsdWindow("", lvl / 100.0, "");
            });
        }

        function testWorkspace(ws: int) {
            const w = (ws !== undefined && ws > 0) ? ws : 2;
            shellRoot.forEachWindow((window) => {
                if (window && window.showWorkspaceWindow)
                    window.showWorkspaceWindow(w);
            });
        }

        function testPolkit() {
            shellRoot.showPolkitPromptAll();
        }

        function closePolkit() {
            shellRoot.closePolkitPromptAll();
        }

        function testNotification(app: string, summary: string, body: string) {
            shellRoot.showNotificationAll(
                app || "Telegram",
                summary || "Nuovo messaggio da Marco",
                body || "Ciao, ci vediamo stasera per la pizza?",
                "",
                "#0088cc"
            );
        }

        function testDetailPanel(kind: string, open: bool) {
            const k = (kind !== undefined && kind !== "") ? kind : "wifi";
            const o = (open !== undefined) ? open : true;
            shellRoot.forEachWindow((window) => {
                if (window && window.setConnectivityDetailWindow)
                    window.setConnectivityDetailWindow(k, o);
            });
        }

        function toggleClipboard() {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.toggleClipboardWindow)
                    window.toggleClipboardWindow();
            });
        }

        function showClipboard() {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.showClipboardWindow)
                    window.showClipboardWindow();
            });
        }

        function toggleSettingsApp() {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.toggleSettingsAppWindow)
                    window.toggleSettingsAppWindow();
            });
        }

        function showSettingsApp() {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.showSettingsAppWindow)
                    window.showSettingsAppWindow();
            });
        }

        function setSettingsCategory(catIndex: int) {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.setSettingsCategory)
                    window.setSettingsCategory(catIndex);
            });
        }

        function setSettingsSubView(sub: string) {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.setSettingsSubView)
                    window.setSettingsSubView(sub);
            });
        }

        function openFontBrowser(target: string) {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.openSettingsFontBrowser)
                    window.openSettingsFontBrowser(target);
            });
        }

        function showClock() {
            shellRoot.forFocusedWindow((window) => window.showClockWindow());
        }

        function showTimer() {
            shellRoot.forFocusedWindow((window) => window.showTimerWindow());
        }

        function showCustom() {
            shellRoot.forFocusedWindow((window) => window.showCustomInfoWindow());
        }

        function showLyrics() {
            shellRoot.forFocusedWindow((window) => window.showLyricsWindow());
        }

        function swipeRight() {
            shellRoot.forFocusedWindow((window) => window.swipeRightWindow());
        }

        function swipeLeft() {
            shellRoot.forFocusedWindow((window) => window.swipeLeftWindow());
        }

        function togglePlayer() {
            shellRoot.forFocusedWindow((window) => window.togglePlayerWindow());
        }

        function toggleControlCenter() {
            shellRoot.forFocusedWindow((window) => window.toggleControlCenterWindow());
        }

        function togglePowerMenu() {
            shellRoot.forFocusedWindow((window) => window.togglePowerMenuWindow());
        }

        function toggleNotificationCenter() {
            shellRoot.forFocusedWindow((window) => window.toggleNotificationCenterWindow());
        }

        function toggleWallpaperPicker() {
            shellRoot.forFocusedWindow((window) => window.toggleWallpaperPickerWindow());
        }

        function toggleApplicationLauncher() {
            shellRoot.forFocusedWindow((window) => window.toggleApplicationLauncherWindow());
        }

        function toggleFileShelf() {
            shellRoot.forFocusedWindow((window) => window.toggleFileShelfWindow());
        }

        function reload() {
            try {
                Quickshell.reload(false);
            } catch (e) {
                console.log("Error calling Quickshell.reload():", e);
            }
        }
    }

    IpcHandler {
        target: "tide"

        function showClock() {
            shellRoot.forFocusedWindow((window) => window.showClockWindow());
        }

        function showTimer() {
            shellRoot.forFocusedWindow((window) => window.showTimerWindow());
        }

        function showCustom() {
            shellRoot.forFocusedWindow((window) => window.showCustomInfoWindow());
        }

        function showLyrics() {
            shellRoot.forFocusedWindow((window) => window.showLyricsWindow());
        }

        function swipeRight() {
            shellRoot.forFocusedWindow((window) => window.swipeRightWindow());
        }

        function swipeLeft() {
            shellRoot.forFocusedWindow((window) => window.swipeLeftWindow());
        }

        function togglePlayer() {
            shellRoot.forFocusedWindow((window) => window.togglePlayerWindow());
        }

        function toggleControlCenter() {
            shellRoot.forFocusedWindow((window) => window.toggleControlCenterWindow());
        }

        function togglePowerMenu() {
            shellRoot.forFocusedWindow((window) => window.togglePowerMenuWindow());
        }

        function toggleNotificationCenter() {
            shellRoot.forFocusedWindow((window) => window.toggleNotificationCenterWindow());
        }

        function toggleWallpaperPicker() {
            shellRoot.forFocusedWindow((window) => window.toggleWallpaperPickerWindow());
        }

        function toggleApplicationLauncher() {
            shellRoot.forFocusedWindow((window) => window.toggleApplicationLauncherWindow());
        }

        function toggleClipboard() {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.toggleClipboardWindow)
                    window.toggleClipboardWindow();
            });
        }

        function showClipboard() {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.showClipboardWindow)
                    window.showClipboardWindow();
            });
        }

        function toggleFileShelf() {
            shellRoot.forFocusedWindow((window) => window.toggleFileShelfWindow());
        }

        function toggleSettingsApp() {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.toggleSettingsAppWindow)
                    window.toggleSettingsAppWindow();
            });
        }

        function showSettingsApp() {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.showSettingsAppWindow)
                    window.showSettingsAppWindow();
            });
        }

        function setSettingsCategory(catIndex: int) {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.setSettingsCategory)
                    window.setSettingsCategory(catIndex);
            });
        }

        function setSettingsSubView(sub: string) {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.setSettingsSubView)
                    window.setSettingsSubView(sub);
            });
        }

        function openFontBrowser(target: string) {
            shellRoot.forFocusedWindow((window) => {
                if (window && window.openSettingsFontBrowser)
                    window.openSettingsFontBrowser(target);
            });
        }
    }

    Connections {
        target: Quickshell

        function onReloadCompleted() {
            try { Quickshell.inhibitReloadPopup(); } catch(e) { console.log("inhibit error:", e); }
            shellRoot.showReloadAll(false, "");
        }

        function onReloadFailed(error: string) {
            try { Quickshell.inhibitReloadPopup(); } catch(e) { console.log("inhibit error:", e); }
            shellRoot.showReloadAll(true, error);
        }
    }

    Process {
        id: avatarResolverProc
        property string pendingCaller: ""
        property string pendingSubtitle: ""
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                const avatar = String(data || "").trim();
                if (avatar !== "") {
                    shellRoot.showDiscordCallAll(avatarResolverProc.pendingCaller, avatarResolverProc.pendingSubtitle, avatar);
                }
            }
        }
    }

    Process {
        id: discordCallMonitorProc
        command: [shellRoot.homeDir + "/.config/quickshell/dynamic-island/scripts/discord_call_monitor.py"]
        running: !shellRoot.shuttingDown
    }

    Connections {
        target: SystemServices

        function onNotificationReceived(appName, summary, body) {
            const lowerApp = String(appName || "").toLowerCase();
            const lowerSummary = String(summary || "").toLowerCase();
            const lowerBody = String(body || "").toLowerCase();

            if (lowerApp.indexOf("discord") !== -1 || lowerApp.indexOf("vesktop") !== -1 || lowerApp.indexOf("armcord") !== -1) {
                if (lowerSummary.indexOf("persa") !== -1 || lowerBody.indexOf("persa") !== -1
                        || lowerSummary.indexOf("missed") !== -1 || lowerBody.indexOf("missed") !== -1
                        || lowerSummary.indexOf("terminat") !== -1 || lowerBody.indexOf("terminat") !== -1
                        || lowerSummary.indexOf("ended") !== -1 || lowerBody.indexOf("ended") !== -1
                        || lowerSummary.indexOf("annullat") !== -1 || lowerBody.indexOf("annullat") !== -1
                        || lowerSummary.indexOf("rifiutat") !== -1 || lowerBody.indexOf("rifiutat") !== -1
                        || lowerSummary.indexOf("chiusa") !== -1 || lowerBody.indexOf("chiusa") !== -1) {
                    shellRoot.closeDiscordCallAll();
                    return;
                }

                if (lowerSummary.indexOf("call") !== -1 || lowerSummary.indexOf("chiamat") !== -1
                        || lowerBody.indexOf("call") !== -1 || lowerBody.indexOf("chiamat") !== -1
                        || lowerSummary.indexOf("incoming") !== -1 || lowerBody.indexOf("incoming") !== -1) {
                    const caller = summary || "Discord";
                    const sub = body || "Chiamata in arrivo...";
                    shellRoot.showDiscordCallAll(caller, sub, "");
                    avatarResolverProc.pendingCaller = caller;
                    avatarResolverProc.pendingSubtitle = sub;
                    avatarResolverProc.command = [shellRoot.homeDir + "/.config/quickshell/dynamic-island/scripts/resolve_discord_avatar.py", caller];
                    avatarResolverProc.running = false;
                    avatarResolverProc.running = true;
                    return;
                }
            }
            shellRoot.showNotificationAll(appName, summary, body);
        }
    }

    Component.onDestruction: {
        shuttingDown = true;
    }

    Component.onCompleted: {
        SystemServices.ensureUserConfigAvailable();
        SystemServices.requestScreenRecordingSnapshot();
    }

    Variants {
        id: panelVariants

        model: Quickshell.screens

        DynamicIslandWindow {
            required property var modelData

            screen: modelData
            shellRootController: shellRoot
            dynamicConfig: shellRoot.dynamicConfig
        }
    }
}
