import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import IslandBackend

FocusScope {
    id: root

    implicitWidth: 860
    implicitHeight: 580
    width: 860
    height: 580
    clip: true

    anchors.top: parent ? parent.top : undefined
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

    property bool showCondition: false
    readonly property bool capsuleReady: parent && (parent.width >= 800 && parent.height >= 500)
    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    signal closeRequested()

    focus: showCondition
    activeFocusOnTab: true

    function grabKeyboardFocus() {
        root.forceActiveFocus();
    }

    // ── Hierarchy Escape Key Management ──────────────────────────────
    function handleEscapeKey() {
        if (root.selectedAppClass !== "") {
            root.clearSelectedApp();
            return true;
        }
        if (root.isWeekView) {
            root.isWeekView = false;
            return true;
        }
        root.closeRequested();
        return true;
    }

    Keys.onEscapePressed: function(event) {
        event.accepted = true;
        root.handleEscapeKey();
    }

    Keys.onLeftPressed: function(event) {
        event.accepted = true;
        root.changeDay(root.isWeekView ? -7 : -1);
    }

    Keys.onRightPressed: function(event) {
        event.accepted = true;
        root.changeDay(root.isWeekView ? 7 : 1);
    }

    // ── Smooth Animation Container ────────────────────────────────────
    opacity: (showCondition && capsuleReady) ? 1.0 : 0.0
    visible: opacity > 0.001

    Behavior on opacity {
        NumberAnimation {
            duration: (root.showCondition && root.capsuleReady) ? 180 : 50
            easing.type: Easing.OutCubic
        }
    }

    // ── Navigation & State Paths ──────────────────────────────────────
    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")
    readonly property string scriptsDir: homeDir + "/.config/hypr/scripts/quickshell/focustime"
    readonly property string stateDir: homeDir + "/.local/state/quickshell/focustime"
    readonly property string stateFilePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000") + "/quickshell/focustime/focustime_state.json"

    property var globalDate: new Date()
    property var appDate: new Date()
    readonly property var activeDate: root.selectedAppClass === "" ? root.globalDate : root.appDate
    readonly property bool isTodaySelected: getIsoDate(root.activeDate) === getIsoDate(new Date())

    property bool isWeekView: false
    property string selectedAppClass: ""
    property string selectedAppName: ""
    property string selectedAppIcon: ""

    property string selectedDateStr: ""
    property string weekRangeStr: ""
    property string peakUsageStr: "N/A"
    property int totalSeconds: 0
    property int averageSeconds: 0
    property int yesterdaySeconds: 0
    property string currentApp: "Desktop"

    // Raw ingested data
    property var topApps: []
    property var weekAppsData: []
    property var weekData: []
    property var monthData: []
    property var weekHeatmapData: [[],[],[],[],[],[],[]]
    property var hourlyData: new Array(48).fill(0)

    property real maxWeekTotal: 1
    property real maxMonthTotal: 1
    property real maxWeekHour: 1
    property real maxHourlyTotal: 1

    property real animatedTotalSeconds: 0
    Behavior on animatedTotalSeconds {
        enabled: root.capsuleReady && !root.isFirstLoad
        NumberAnimation { duration: 650; easing.type: Easing.OutQuint }
    }
    onTotalSecondsChanged: {
        animatedTotalSeconds = totalSeconds;
    }

    property real weekViewFocus: root.isWeekView ? 1.0 : 0.0
    Behavior on weekViewFocus {
        NumberAnimation { duration: 320; easing.type: Easing.OutQuint }
    }

    property real appViewFocus: root.selectedAppClass !== "" ? 1.0 : 0.0
    Behavior on appViewFocus {
        NumberAnimation { duration: 320; easing.type: Easing.OutQuint }
    }

    property bool isFirstLoad: true
    Timer {
        id: firstLoadTimer
        interval: 350
        onTriggered: root.isFirstLoad = false
    }

    property real appBarsProgress: 0.0
    NumberAnimation {
        id: appBarsAnim
        target: root
        property: "appBarsProgress"
        from: 0.0
        to: 1.0
        duration: 650
        easing.type: Easing.OutQuint
    }

    function triggerAppBarsAnimation() {
        appBarsAnim.stop();
        root.appBarsProgress = 0.0;
        appBarsAnim.start();
    }

    onVisibleChanged: {
        if (visible) {
            triggerAppBarsAnimation();
        }
    }
    onIsWeekViewChanged: {
        triggerAppBarsAnimation();
    }
    onSelectedAppClassChanged: {
        if (selectedAppClass === "") {
            triggerAppBarsAnimation();
        }
    }

    // ── ListModels (In-Place Synchronization to Prevent Glitches) ────
    ListModel { id: appListModel }
    ListModel { id: weekAppListModel }
    ListModel { id: weekListModel }
    ListModel { id: monthListModel }

    readonly property var monthNamesItalian: ["Gennaio", "Febbraio", "Marzo", "Aprile", "Maggio", "Giugno", "Luglio", "Agosto", "Settembre", "Ottobre", "Novembre", "Dicembre"]

    // ── Time & Date Helpers ───────────────────────────────────────────
    function formatTime(sec) {
        if (!sec || sec <= 0) return "0m";
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        if (h > 0) return h + "h " + (m < 10 ? "0" : "") + m + "m";
        return m + "m";
    }

    function formatTimeLarge(sec) {
        if (!sec || sec <= 0) return "0m";
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }

    function getIsoDate(d) {
        let z = d.getTimezoneOffset() * 60000;
        return (new Date(d - z)).toISOString().slice(0, 10);
    }

    function getFancyDate(d) {
        let isToday = getIsoDate(d) === getIsoDate(new Date());
        if (isToday) return I18n.tr("Oggi");
        let mName = root.monthNamesItalian[d.getMonth()] || "";
        return d.getDate() + " " + mName;
    }

    readonly property int totalWeekSeconds: {
        let t = 0;
        for (let i = 0; i < root.weekData.length; i++) {
            if (root.weekData[i] && root.weekData[i].total > 0) t += root.weekData[i].total;
        }
        return t;
    }

    // ── Date and App Navigation ───────────────────────────────────────
    function changeDay(offsetDays) {
        let d = new Date(root.activeDate);
        d.setDate(d.getDate() + offsetDays);
        let today = new Date();
        if (d > today) {
            d = today;
        }
        if (root.selectedAppClass === "") {
            root.globalDate = d;
        } else {
            root.appDate = d;
        }
        root.isFirstLoad = true;
        root.triggerAppBarsAnimation();
        root.requestDataUpdate();
    }

    function changeToDate(clickedDateStr) {
        if (!clickedDateStr) return;
        let currentIso = getIsoDate(root.activeDate);
        if (clickedDateStr === currentIso) return;
        let dCurrent = new Date(currentIso + "T12:00:00");
        let dClicked = new Date(clickedDateStr + "T12:00:00");
        let diffDays = Math.round((dClicked - dCurrent) / (1000 * 60 * 60 * 24));
        if (diffDays !== 0) changeDay(diffDays);
    }

    function selectApp(item) {
        if (!item) return;
        root.isWeekView = false;
        root.selectedAppClass = item.appClass || item.class || "";
        root.selectedAppName = item.name || item.appClass || item.class || "App";
        root.selectedAppIcon = item.icon || "";
        root.appDate = new Date();
        root.isFirstLoad = true;
        root.requestDataUpdate();
    }

    function selectAppByClass(appClass) {
        if (!appClass) return;
        root.isWeekView = false;
        root.selectedAppClass = appClass;
        root.selectedAppName = appClass;
        root.selectedAppIcon = "";
        root.appDate = new Date();
        root.isFirstLoad = true;
        root.requestDataUpdate();
    }

    function clearSelectedApp() {
        root.selectedAppClass = "";
        root.selectedAppName = "";
        root.selectedAppIcon = "";
        root.isFirstLoad = true;
        root.requestDataUpdate();
    }

    // ── Data Ingestion & Model Syncing ────────────────────────────────
    function updateFromData(data) {
        if (!data) return;

        root.selectedDateStr = data.selected_date || "";
        root.totalSeconds = data.total || 0;
        root.averageSeconds = data.average || 0;
        root.yesterdaySeconds = data.yesterday || 0;
        root.weekRangeStr = data.week_range || "";
        root.currentApp = data.current || "Unknown";

        // Top Apps Model
        root.topApps = data.apps || [];
        syncAppsModel();

        // Week Apps Model
        root.weekAppsData = data.week_apps || [];
        syncWeekAppsModel();

        // Week Heatmap Matrix
        root.weekHeatmapData = data.week_heatmap || [[],[],[],[],[],[],[]];
        let mwh = 1;
        let hourSums = new Array(24).fill(0);
        for (let i = 0; i < 7; i++) {
            if (!root.weekHeatmapData[i]) continue;
            for (let j = 0; j < 24; j++) {
                if (root.weekHeatmapData[i][j] > mwh) mwh = root.weekHeatmapData[i][j];
                hourSums[j] += root.weekHeatmapData[i][j];
            }
        }
        root.maxWeekHour = Math.max(1, mwh);

        // Peak Usage Hours
        let max2H = -1;
        let peakStart = 0;
        for (let h = 0; h < 23; h++) {
            let cur2H = hourSums[h] + hourSums[h+1];
            if (cur2H > max2H) {
                max2H = cur2H;
                peakStart = h;
            }
        }
        if (max2H > 0) {
            let startStr = (peakStart < 10 ? "0" : "") + peakStart + ":00";
            let endH = peakStart + 2;
            let endStr = (endH < 10 ? "0" : "") + endH + ":00";
            root.peakUsageStr = startStr + " - " + endStr;
        } else {
            root.peakUsageStr = data.peak_usage_str || "N/A";
        }

        // Week Model & maxWeekTotal
        let pw = data.week || [];
        root.weekData = pw;
        let cmw = 1;
        for (let i = 0; i < pw.length; i++) {
            if (pw[i].total > cmw) cmw = pw[i].total;
        }
        root.maxWeekTotal = Math.max(1, cmw);
        syncWeekModel();

        // Month Model & maxMonthTotal
        let pm = data.month || [];
        root.monthData = pm;
        let cmm = 1;
        for (let i = 0; i < pm.length; i++) {
            if (pm[i].total > cmm) cmm = pm[i].total;
        }
        root.maxMonthTotal = Math.max(1, cmm);
        syncMonthModel();

        // Hourly 24h Activity & maxHourlyTotal
        let hly = data.hourly || new Array(48).fill(0);
        root.hourlyData = hly;
        let cmh = 1;
        for (let i = 0; i < hly.length; i++) {
            if (hly[i] > cmh) cmh = hly[i];
        }
        root.maxHourlyTotal = Math.max(1, cmh);

        if (root.isFirstLoad || root.appBarsProgress < 0.05) {
            root.triggerAppBarsAnimation();
        }
        firstLoadTimer.restart();
    }

    function syncAppsModel() {
        for (let i = 0; i < root.topApps.length; i++) {
            let app = root.topApps[i];
            if (i < appListModel.count) {
                appListModel.setProperty(i, "name", app.name || app.class);
                appListModel.setProperty(i, "appClass", app.class);
                appListModel.setProperty(i, "icon", app.icon || "");
                appListModel.setProperty(i, "seconds", app.seconds || 0);
                appListModel.setProperty(i, "percent", app.percent || 0);
            } else {
                appListModel.append({
                    name: app.name || app.class,
                    appClass: app.class,
                    icon: app.icon || "",
                    seconds: app.seconds || 0,
                    percent: app.percent || 0,
                    idx: i
                });
            }
        }
        while (appListModel.count > root.topApps.length) {
            appListModel.remove(appListModel.count - 1);
        }
    }

    function syncWeekAppsModel() {
        for (let i = 0; i < root.weekAppsData.length; i++) {
            let app = root.weekAppsData[i];
            if (i < weekAppListModel.count) {
                weekAppListModel.setProperty(i, "name", app.name || app.class);
                weekAppListModel.setProperty(i, "appClass", app.class);
                weekAppListModel.setProperty(i, "icon", app.icon || "");
                weekAppListModel.setProperty(i, "seconds", app.seconds || 0);
                weekAppListModel.setProperty(i, "percent", app.percent || 0);
            } else {
                weekAppListModel.append({
                    name: app.name || app.class,
                    appClass: app.class,
                    icon: app.icon || "",
                    seconds: app.seconds || 0,
                    percent: app.percent || 0,
                    idx: i
                });
            }
        }
        while (weekAppListModel.count > root.weekAppsData.length) {
            weekAppListModel.remove(weekAppListModel.count - 1);
        }
    }

    function syncWeekModel() {
        for (let i = 0; i < root.weekData.length; i++) {
            let w = root.weekData[i];
            if (i < weekListModel.count) {
                weekListModel.setProperty(i, "dateStr", w.date || "");
                weekListModel.setProperty(i, "dayName", w.day || "");
                weekListModel.setProperty(i, "total", w.total || 0);
                weekListModel.setProperty(i, "isTarget", !!w.is_target);
            } else {
                weekListModel.append({
                    dateStr: w.date || "",
                    dayName: w.day || "",
                    total: w.total || 0,
                    isTarget: !!w.is_target
                });
            }
        }
        while (weekListModel.count > root.weekData.length) {
            weekListModel.remove(weekListModel.count - 1);
        }
    }

    function syncMonthModel() {
        for (let i = 0; i < root.monthData.length; i++) {
            let m = root.monthData[i];
            if (i < monthListModel.count) {
                monthListModel.setProperty(i, "dateStr", m.date || "");
                monthListModel.setProperty(i, "total", m.total !== undefined ? m.total : -1);
                monthListModel.setProperty(i, "isTarget", !!m.is_target);
            } else {
                monthListModel.append({
                    dateStr: m.date || "",
                    total: m.total !== undefined ? m.total : -1,
                    isTarget: !!m.is_target
                });
            }
        }
        while (monthListModel.count > root.monthData.length) {
            monthListModel.remove(monthListModel.count - 1);
        }
    }

    // ── Data Fetching Routing ─────────────────────────────────────────
    function requestDataUpdate() {
        if (root.selectedAppClass === "" && root.isTodaySelected) {
            liveFileReader.running = true;
            stateFileView.reload();
        } else {
            let cmd = ["python3", root.scriptsDir + "/get_stats.py", root.getIsoDate(root.activeDate)];
            if (root.selectedAppClass !== "") {
                cmd.push("--app");
                cmd.push(root.selectedAppClass);
            }
            cmd.push("--db-dir");
            cmd.push(root.stateDir);
            statsPoller.command = cmd;
            statsPoller.running = true;
        }
    }

    // ── Live File View (Realtime Daemon Updates for Today) ─────────────
    FileView {
        id: stateFileView
        path: root.stateFilePath
        watchChanges: true
        Component.onCompleted: reload()
        onFileChanged: {
            if (root.selectedAppClass === "" && root.isTodaySelected) reload();
        }
        onLoaded: {
            if (root.selectedAppClass === "" && root.isTodaySelected) {
                try {
                    let d = JSON.parse(text());
                    root.updateFromData(d);
                } catch(e) {}
            }
        }
    }

    Process {
        id: liveFileReader
        command: ["sh", "-c", "cat \"" + root.stateFilePath + "\" 2>/dev/null || cat /tmp/quickshell/focustime/focustime_state.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "") {
                    let cmd = ["python3", root.scriptsDir + "/get_stats.py", root.getIsoDate(root.activeDate), "--db-dir", root.stateDir];
                    statsPoller.command = cmd;
                    statsPoller.running = true;
                    return;
                }
                try {
                    let d = JSON.parse(raw);
                    root.updateFromData(d);
                } catch(e) {}
            }
        }
    }

    Process {
        id: statsPoller
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "") return;
                try {
                    let d = JSON.parse(raw);
                    root.updateFromData(d);
                } catch(e) {
                    console.warn("[FocusTimeLayer] Failed to parse Python stats JSON:", e);
                }
            }
        }
    }

    Timer {
        id: livePollTimer
        interval: 1000
        running: root.showCondition && root.isTodaySelected && root.selectedAppClass === ""
        repeat: true
        onTriggered: root.requestDataUpdate()
    }

    onShowConditionChanged: {
        if (showCondition) {
            root.forceActiveFocus();
            root.isFirstLoad = true;
            root.requestDataUpdate();
        } else {
            root.selectedAppClass = "";
            root.isWeekView = false;
        }
    }

    // ── Base Background Frame ─────────────────────────────────────────
    Rectangle {
        width: 860
        height: 580
        anchors.centerIn: parent
        radius: 32
        color: "#0c0e14"
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.08)
        clip: true

        // ── Main Scalable Content Wrapper ─────────────────────────────
        Item {
            id: mainContentWrapper
            width: 820
            height: 540
            anchors.centerIn: parent
            scale: (root.showCondition && root.capsuleReady) ? 1.0 : 0.96
            opacity: (root.showCondition && root.capsuleReady) ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation {
                    duration: (root.showCondition && root.capsuleReady) ? 220 : 60
                    easing.type: Easing.OutQuint
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: (root.showCondition && root.capsuleReady) ? 180 : 50
                    easing.type: Easing.OutCubic
                }
            }

            // ═══════════════════════════════════════════════════════════
            // 1. HEADER (Navigation, Titles & Close)
            // ═══════════════════════════════════════════════════════════
            Item {
                id: headerItem
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 40

                // Tasti Sinistri: Indietro [󰁍], Vista Settimanale [󰃭], Giorno Precedente [󰅁]
                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // Bottone Indietro (se dentro App o Vista Settimana)
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: backBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        opacity: (root.selectedAppClass !== "" || root.isWeekView) ? 1.0 : 0.0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰁍"
                            font.family: root.iconFontFamily
                            font.pixelSize: 16
                            color: root.accentColor
                        }

                        MouseArea {
                            id: backBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.selectedAppClass !== "") {
                                    root.clearSelectedApp();
                                } else if (root.isWeekView) {
                                    root.isWeekView = false;
                                }
                            }
                        }
                    }

                    // Bottone Calendario Panoramica Settimanale (se in Vista Giorno normale)
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: calBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        opacity: (root.selectedAppClass === "" && !root.isWeekView) ? 1.0 : 0.0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰃭"
                            font.family: root.iconFontFamily
                            font.pixelSize: 15
                            color: "#c6cddb"
                        }

                        MouseArea {
                            id: calBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.isWeekView = true
                        }
                    }

                    // Tasto Giorno / Settimana Precedente [<]
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: prevDayMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅁"
                            font.family: root.iconFontFamily
                            font.pixelSize: 16
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: prevDayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.changeDay(root.isWeekView ? -7 : -1)
                        }
                    }
                }

                // Titolo Centrale & Contesto Dinamico
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.selectedAppClass !== "" && root.selectedAppIcon !== ""
                        source: root.selectedAppIcon.startsWith("/") ? ("file://" + root.selectedAppIcon) : ("image://icon/" + root.selectedAppIcon)
                        sourceSize: Qt.size(40, 40)
                    }

                    Text {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: "#ffffff"
                        font.pixelSize: 17
                        font.weight: Font.Bold
                        font.family: root.textFontFamily
                        text: {
                            if (root.isWeekView) {
                                return root.weekRangeStr !== "" ? root.weekRangeStr : I18n.tr("Panoramica Settimanale");
                            }
                            if (root.selectedAppClass !== "") {
                                return root.selectedAppName + " - " + root.getFancyDate(root.activeDate);
                            }
                            return root.getFancyDate(root.activeDate);
                        }
                    }
                }

                // Tasti Destri: Giorno Successivo [>], Chiudi Finestra [✕]
                RowLayout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // Tasto Giorno / Settimana Successivo [>]
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: nextDayMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        opacity: root.isTodaySelected ? 0.35 : 1.0
                        enabled: !root.isTodaySelected
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅂"
                            font.family: root.iconFontFamily
                            font.pixelSize: 16
                            color: "#ffffff"
                        }

                        MouseArea {
                            id: nextDayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: root.isTodaySelected ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                if (!root.isTodaySelected) {
                                    root.changeDay(root.isWeekView ? 7 : 1);
                                }
                            }
                        }
                    }

                    // Tasto Chiudi Focus Time [✕]
                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: closeBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: root.iconFontFamily
                            font.pixelSize: 15
                            color: "#a0a8b8"
                        }

                        MouseArea {
                            id: closeBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }
                }
            }

            // ═══════════════════════════════════════════════════════════
            // CONTENUTO MASTER (Vista Giornaliera/App VS Panoramica Settimanale)
            // ═══════════════════════════════════════════════════════════
            Item {
                id: masterContainer
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerItem.bottom
                anchors.bottom: parent.bottom
                anchors.topMargin: 12

                // ───────────────────────────────────────────────────────
                // SCHERMATA A: VISTA GIORNALIERA & DETTAGLIO APP
                // ───────────────────────────────────────────────────────
                Item {
                    id: dailyViewWrapper
                    anchors.fill: parent

                    opacity: 1.0 - root.weekViewFocus
                    visible: opacity > 0.01
                    transform: Translate { x: -40 * root.weekViewFocus }
                    scale: 0.95 + (0.05 * (1.0 - root.weekViewFocus))

                    // 1. TOP STATS (3 Card Rettangolari in Stile Apple)
                    Row {
                        id: topStatsRow
                        width: parent.width
                        height: 76
                        spacing: 12

                        // Box Sinistro: Media Giornaliera
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: 14
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.07)

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: I18n.tr("Media Giornaliera")
                                    color: "#8e99a8"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    font.family: root.textFontFamily
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.formatTime(root.averageSeconds)
                                    color: "#ffffff"
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                    font.family: root.textFontFamily
                                    font.features: { "tnum": 1 }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.weekRangeStr
                                    color: "#5e697a"
                                    font.pixelSize: 10
                                    font.family: root.textFontFamily
                                    visible: root.weekRangeStr !== ""
                                }
                            }
                        }

                        // Box Centrale: Tempo Totale Utilizzo
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: 14
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.07)

                            Column {
                                anchors.centerIn: parent
                                spacing: 0

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.formatTimeLarge(root.animatedTotalSeconds)
                                    color: "#ffffff"
                                    font.pixelSize: 30
                                    font.weight: Font.Black
                                    font.family: root.textFontFamily
                                    font.features: { "tnum": 1 }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.selectedAppClass !== "" ? root.selectedAppName : (root.isTodaySelected ? I18n.tr("Oggi") : root.getFancyDate(root.activeDate))
                                    color: "#8e99a8"
                                    font.pixelSize: 11
                                    font.family: root.textFontFamily
                                }
                            }
                        }

                        // Box Destro: Confronto con Ieri
                        Rectangle {
                            width: (parent.width - 24) / 3
                            height: parent.height
                            radius: 14
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.07)

                            readonly property int diffSec: root.totalSeconds - root.yesterdaySeconds
                            readonly property bool hasDiff: !(root.totalSeconds === 0 && root.yesterdaySeconds === 0) && (root.totalSeconds !== root.yesterdaySeconds)

                            Column {
                                anchors.centerIn: parent
                                spacing: 3

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: I18n.tr("Rispetto a Ieri")
                                    color: "#8e99a8"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    font.family: root.textFontFamily
                                }

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4
                                    visible: parent.parent.hasDiff

                                    Text {
                                        text: parent.parent.parent.diffSec > 0 ? "↑" : "↓"
                                        color: parent.parent.parent.diffSec > 0 ? "#ff9f0a" : "#30d158"
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                        font.family: root.textFontFamily
                                    }

                                    Text {
                                        text: root.formatTime(Math.abs(parent.parent.parent.diffSec))
                                        color: parent.parent.parent.diffSec > 0 ? "#ff9f0a" : "#30d158"
                                        font.pixelSize: 19
                                        font.weight: Font.Bold
                                        font.family: root.textFontFamily
                                        font.features: { "tnum": 1 }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: (root.totalSeconds === 0 && root.yesterdaySeconds === 0) ? I18n.tr("Nessun dato") : I18n.tr("Stesso tempo")
                                    color: "#5e697a"
                                    font.pixelSize: 13
                                    font.family: root.textFontFamily
                                    visible: !parent.parent.hasDiff
                                }
                            }
                        }
                    }

                    // 2. MIDDLE CHARTS: Grafico a Barre Settimanale & Heatmap del Mese
                    Row {
                        id: middleChartsRow
                        anchors.top: topStatsRow.bottom
                        anchors.topMargin: 12
                        width: parent.width
                        height: 140
                        spacing: 12

                        // Card Sinistra: Attività Settimanale (Cliccabile su ogni giorno)
                        Rectangle {
                            id: weekBarCard
                            width: parent.width * 0.58
                            height: parent.height
                            radius: 14
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.07)
                            clip: true

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Row {
                                    width: parent.width
                                    Text {
                                        text: I18n.tr("Attività Settimanale")
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        font.family: root.textFontFamily
                                    }
                                    Item { Layout.fillWidth: true; width: parent.width - 200 }
                                    Text {
                                        text: I18n.tr("Clicca un giorno")
                                        color: "#6e7787"
                                        font.pixelSize: 10
                                        font.family: root.textFontFamily
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // 7 Colonne da Lunedì a Domenica
                                Row {
                                    width: parent.width
                                    height: parent.height - 24
                                    spacing: (width - (weekListModel.count * 38)) / Math.max(1, weekListModel.count - 1)

                                    Repeater {
                                        model: weekListModel

                                        Column {
                                            width: 38
                                            height: parent.height
                                            spacing: 4

                                            Item {
                                                width: parent.width
                                                height: parent.height - 18
                                                clip: true

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: 24
                                                    // Clamping rigido per impedire qualsiasi bug di altezza anomala
                                                    height: Math.min(parent.height - 4, Math.max(4, Math.round((model.total / Math.max(1, root.maxWeekTotal)) * (parent.height - 4))))
                                                    radius: 4
                                                    color: model.isTarget ? root.accentColor : Qt.rgba(255, 255, 255, 0.16)
                                                    opacity: dayBarMouse.containsMouse ? 0.75 : 1.0

                                                    Behavior on height {
                                                        enabled: root.capsuleReady && !root.isFirstLoad
                                                        NumberAnimation { duration: 450; easing.type: Easing.OutQuint }
                                                    }
                                                }

                                                MouseArea {
                                                    id: dayBarMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.changeToDate(model.dateStr)
                                                }
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: model.dayName
                                                color: model.isTarget ? "#ffffff" : "#6e7787"
                                                font.pixelSize: 10
                                                font.weight: model.isTarget ? Font.Bold : Font.Normal
                                                font.family: root.textFontFamily
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Card Destra: Calendario Presenza nel Mese (Cliccabile su ogni giorno)
                        Rectangle {
                            id: monthHeatmapCard
                            width: parent.width - weekBarCard.width - 12
                            height: parent.height
                            radius: 14
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.07)
                            clip: true

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    text: root.monthNamesItalian[root.activeDate.getMonth()] + " " + root.activeDate.getFullYear()
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    font.family: root.textFontFamily
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Grid {
                                    columns: 7
                                    spacing: 5
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Repeater {
                                        model: monthListModel

                                        Rectangle {
                                            width: 17
                                            height: 17
                                            radius: 4
                                            color: {
                                                if (model.total === -1) return "transparent";
                                                if (model.total === 0) return Qt.rgba(255, 255, 255, 0.04);
                                                const intensity = Math.min(1.0, 0.25 + 0.75 * (model.total / Math.max(1, root.maxMonthTotal)));
                                                return Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, intensity);
                                            }
                                            border.width: model.isTarget ? 1.5 : 0
                                            border.color: model.isTarget ? "#ffffff" : "transparent"
                                            opacity: cellMouse.containsMouse ? 0.75 : 1.0

                                            MouseArea {
                                                id: cellMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                enabled: model.total !== -1
                                                cursorShape: model.total !== -1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: {
                                                    if (model.total !== -1 && model.dateStr) {
                                                        root.changeToDate(model.dateStr);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. BOTTOM SECTION: Lista Applicazioni Tracciate OPPURE Grafico Orario Dettaglio App
                    Rectangle {
                        id: bottomCard
                        anchors.top: middleChartsRow.bottom
                        anchors.topMargin: 12
                        anchors.bottom: parent.bottom
                        width: parent.width
                        radius: 14
                        color: Qt.rgba(255, 255, 255, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.07)
                        clip: true

                        Item {
                            anchors.fill: parent

                            // SOTTO-VISTA 1: Lista Applicazioni Tracciate del Giorno
                            Column {
                                id: dailyAppListWrapper
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                opacity: 1.0 - root.appViewFocus
                                visible: opacity > 0.01
                                transform: Translate { x: -30 * root.appViewFocus }
                                scale: 0.95 + (0.05 * (1.0 - root.appViewFocus))

                                Row {
                                    width: parent.width
                                    Text {
                                        text: I18n.tr("Applicazioni Tracciate") + " (" + appListModel.count + ")"
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        font.family: root.textFontFamily
                                    }
                                    Item { width: 12; height: 1 }
                                    Text {
                                        text: I18n.tr("Clicca per dettagli orari 󰁔")
                                        color: root.accentColor
                                        font.pixelSize: 10
                                        font.family: root.textFontFamily
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                ListView {
                                    id: dailyAppListView
                                    width: parent.width
                                    height: parent.height - 24
                                    clip: true
                                    spacing: 4
                                    model: appListModel
                                    boundsBehavior: Flickable.StopAtBounds

                                    ScrollBar.vertical: ScrollBar {
                                        width: 3
                                        policy: ScrollBar.AsNeeded
                                    }

                                    delegate: Rectangle {
                                        width: ListView.view.width - 6
                                        height: 44
                                        radius: 8
                                        color: appRowMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.07) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Item {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8

                                            Row {
                                                anchors.fill: parent
                                                spacing: 10

                                                Rectangle {
                                                    width: 30
                                                    height: 30
                                                    radius: 6
                                                    color: Qt.rgba(255, 255, 255, 0.06)
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    Image {
                                                        anchors.centerIn: parent
                                                        width: 20
                                                        height: 20
                                                        source: model.icon ? (model.icon.startsWith("/") ? ("file://" + model.icon) : ("image://icon/" + model.icon)) : ""
                                                        sourceSize: Qt.size(40, 40)
                                                        visible: status === Image.Ready
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: !model.icon || model.icon === ""
                                                        text: "\uf108"
                                                        font.family: root.iconFontFamily
                                                        font.pixelSize: 14
                                                        color: root.accentColor
                                                    }
                                                }

                                                Column {
                                                    width: parent.width - 30 - 10
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: 4

                                                    Row {
                                                        width: parent.width

                                                        Text {
                                                            width: parent.width - timeText.implicitWidth
                                                            text: model.name || model.appClass
                                                            color: "#ffffff"
                                                            font.pixelSize: 12
                                                            font.weight: Font.DemiBold
                                                            font.family: root.textFontFamily
                                                            elide: Text.ElideRight
                                                        }

                                                        Text {
                                                            id: timeText
                                                            text: root.formatTime(model.seconds) + " (" + (model.percent || 0).toFixed(1) + "%)"
                                                            color: "#8e99a8"
                                                            font.pixelSize: 11
                                                            font.family: root.textFontFamily
                                                            font.features: { "tnum": 1 }
                                                        }
                                                    }

                                                    Rectangle {
                                                        width: parent.width
                                                        height: 4
                                                        radius: 2
                                                        color: Qt.rgba(255, 255, 255, 0.08)
                                                        clip: true

                                                        Rectangle {
                                                            // Clamping rigoroso sul calcolo della larghezza e riempimento animato da sinistra a destra
                                                            width: Math.min(parent.width, Math.max(0, parent.width * (Math.min(100, Math.max(0, model.percent || 0)) / 100.0) * root.appBarsProgress))
                                                            height: parent.height
                                                            radius: 2
                                                            color: root.accentColor

                                                            Behavior on width {
                                                                enabled: !appBarsAnim.running && root.capsuleReady && !root.isFirstLoad
                                                                NumberAnimation { duration: 320; easing.type: Easing.OutQuint }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: appRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectApp(model)
                                        }
                                    }
                                }
                            }

                            // SOTTO-VISTA 2: Grafico Orario Dettaglio 24h dell'App Selezionata
                            Column {
                                id: singleAppChartWrapper
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 8

                                opacity: root.appViewFocus
                                visible: opacity > 0.01
                                transform: Translate { x: 30 * (1 - root.appViewFocus) }
                                scale: 0.95 + (0.05 * root.appViewFocus)

                                Item {
                                    width: parent.width
                                    height: 18

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: I18n.tr("Distribuzione Attività 24 Ore (Intervalli da 30 Min)")
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        font.family: root.textFontFamily
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.peakUsageStr !== "N/A" ? (I18n.tr("Ore di picco: ") + root.peakUsageStr) : ""
                                        color: root.accentColor
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        font.family: root.textFontFamily
                                    }
                                }

                                // 48 Barre da 30 minuti (dalle 00:00 alle 24:00)
                                Item {
                                    width: parent.width
                                    height: parent.height - 48
                                    clip: true

                                    Row {
                                        anchors.fill: parent
                                        spacing: (width - (48 * Math.floor((width - 48) / 48))) / 48

                                        Repeater {
                                            model: 48

                                            Item {
                                                width: Math.floor((parent.width - 48) / 48)
                                                height: parent.height

                                                readonly property int val: (root.hourlyData && root.hourlyData[index]) ? root.hourlyData[index] : 0

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    // Clamping rigido di sicurezza
                                                    height: Math.min(parent.height - 4, Math.max(3, Math.round((parent.val / Math.max(1, root.maxHourlyTotal)) * (parent.height - 4))))
                                                    radius: 2
                                                    color: parent.val > 0 ? root.accentColor : Qt.rgba(255, 255, 255, 0.08)
                                                    opacity: barTooltipMouse.containsMouse ? 0.75 : 1.0

                                                    Behavior on height {
                                                        enabled: root.capsuleReady && !root.isFirstLoad
                                                        NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
                                                    }
                                                }

                                                MouseArea {
                                                    id: barTooltipMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                }

                                                // Tooltip al passaggio del mouse
                                                Rectangle {
                                                    visible: barTooltipMouse.containsMouse && parent.val > 0
                                                    anchors.bottom: parent.top
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    anchors.bottomMargin: 4
                                                    width: tipTxt.implicitWidth + 12
                                                    height: 20
                                                    radius: 4
                                                    color: "#181b24"
                                                    border.width: 1
                                                    border.color: root.accentColor
                                                    z: 10

                                                    Text {
                                                        id: tipTxt
                                                        anchors.centerIn: parent
                                                        text: {
                                                            let h = Math.floor(index / 2);
                                                            let m = (index % 2 === 0) ? "00" : "30";
                                                            return (h < 10 ? "0" : "") + h + ":" + m + " (" + root.formatTime(parent.val) + ")";
                                                        }
                                                        font.family: root.textFontFamily
                                                        font.pixelSize: 9
                                                        color: "#ffffff"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Asse dei Tempi
                                Row {
                                    width: parent.width
                                    Text { text: "00:00"; font.pixelSize: 10; color: "#6e7787"; font.family: root.textFontFamily }
                                    Item { Layout.fillWidth: true; width: (parent.width - 240) / 4; height: 1 }
                                    Text { text: "06:00"; font.pixelSize: 10; color: "#6e7787"; font.family: root.textFontFamily }
                                    Item { Layout.fillWidth: true; width: (parent.width - 240) / 4; height: 1 }
                                    Text { text: "12:00"; font.pixelSize: 10; color: "#6e7787"; font.family: root.textFontFamily }
                                    Item { Layout.fillWidth: true; width: (parent.width - 240) / 4; height: 1 }
                                    Text { text: "18:00"; font.pixelSize: 10; color: "#6e7787"; font.family: root.textFontFamily }
                                    Item { Layout.fillWidth: true; width: (parent.width - 240) / 4; height: 1 }
                                    Text { text: "23:00"; font.pixelSize: 10; color: "#6e7787"; font.family: root.textFontFamily }
                                }
                            }
                        }
                    }
                }

                // ───────────────────────────────────────────────────────
                // SCHERMATA B: PANORAMICA SETTIMANALE COMPLETA (HEATMAP 7x24 + TOP APP)
                // ───────────────────────────────────────────────────────
                Item {
                    id: weekViewWrapper
                    anchors.fill: parent

                    opacity: root.weekViewFocus
                    visible: opacity > 0.01
                    transform: Translate { x: 40 * (1 - root.weekViewFocus) }
                    scale: 0.95 + (0.05 * root.weekViewFocus)

                    // Card Superiore: Heatmap Settimanale 7x24 + Box Statistiche
                    Rectangle {
                        id: weekHeatmapContainer
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 245
                        radius: 14
                        color: Qt.rgba(255, 255, 255, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.07)
                        clip: true

                        Row {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 16

                            // Griglia Heatmap 7 Giorni x 24 Ore
                            Column {
                                width: parent.width - 150 - 16
                                height: parent.height
                                spacing: 4

                                Text {
                                    text: I18n.tr("Distribuzione Oraria della Settimana")
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    font.family: root.textFontFamily
                                }

                                Item { width: 1; height: 4 }

                                // 7 Righe da Lunedì a Domenica
                                Repeater {
                                    model: 7

                                    Row {
                                        property int dayIdx: index
                                        width: parent.width
                                        height: 20
                                        spacing: 4

                                        Text {
                                            width: 44
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"][dayIdx]
                                            font.family: root.textFontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: "#8a94a6"
                                        }

                                        Row {
                                            width: parent.width - 48
                                            height: 18
                                            spacing: 2
                                            anchors.verticalCenter: parent.verticalCenter

                                            Repeater {
                                                model: 24

                                                Rectangle {
                                                    property real cellVal: (root.weekHeatmapData[dayIdx] && root.weekHeatmapData[dayIdx][index]) ? root.weekHeatmapData[dayIdx][index] : 0
                                                    width: (parent.width - (23 * 2)) / 24
                                                    height: 16
                                                    radius: 3
                                                    color: {
                                                        if (cellVal <= 0) return Qt.rgba(255, 255, 255, 0.04);
                                                        const ratio = Math.min(1.0, 0.20 + 0.80 * (cellVal / Math.max(1, root.maxWeekHour)));
                                                        return Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, ratio);
                                                    }
                                                    opacity: hmCellMouse.containsMouse ? 0.75 : 1.0

                                                    MouseArea {
                                                        id: hmCellMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Asse X Orario
                                Row {
                                    width: parent.width
                                    anchors.leftMargin: 48
                                    Text { text: "00:00"; font.pixelSize: 9; color: "#6e7787"; font.family: root.textFontFamily }
                                    Item { width: (parent.width - 170) / 4; height: 1 }
                                    Text { text: "06:00"; font.pixelSize: 9; color: "#6e7787"; font.family: root.textFontFamily }
                                    Item { width: (parent.width - 170) / 4; height: 1 }
                                    Text { text: "12:00"; font.pixelSize: 9; color: "#6e7787"; font.family: root.textFontFamily }
                                    Item { width: (parent.width - 170) / 4; height: 1 }
                                    Text { text: "18:00"; font.pixelSize: 9; color: "#6e7787"; font.family: root.textFontFamily }
                                    Item { width: (parent.width - 170) / 4; height: 1 }
                                    Text { text: "23:00"; font.pixelSize: 9; color: "#6e7787"; font.family: root.textFontFamily }
                                }
                            }

                            // Colonna Destra: Statistiche della Settimana
                            Column {
                                width: 150
                                height: parent.height
                                spacing: 8

                                // Box 1: Media Giornaliera
                                Rectangle {
                                    width: parent.width
                                    height: 64
                                    radius: 10
                                    color: Qt.rgba(255, 255, 255, 0.04)
                                    border.width: 1
                                    border.color: Qt.rgba(255, 255, 255, 0.07)

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: I18n.tr("Media Giornaliera")
                                            color: "#8a94a6"
                                            font.pixelSize: 10
                                            font.family: root.textFontFamily
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.formatTime(root.averageSeconds)
                                            color: "#ffffff"
                                            font.pixelSize: 16
                                            font.weight: Font.Bold
                                            font.family: root.textFontFamily
                                            font.features: { "tnum": 1 }
                                        }
                                    }
                                }

                                // Box 2: Ore di Picco
                                Rectangle {
                                    width: parent.width
                                    height: 64
                                    radius: 10
                                    color: Qt.rgba(255, 255, 255, 0.04)
                                    border.width: 1
                                    border.color: Qt.rgba(255, 255, 255, 0.07)

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: I18n.tr("Ore di Punta")
                                            color: "#8a94a6"
                                            font.pixelSize: 10
                                            font.family: root.textFontFamily
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.peakUsageStr
                                            color: root.accentColor
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            font.family: root.textFontFamily
                                        }
                                    }
                                }

                                // Box 3: Totale Settimana
                                Rectangle {
                                    width: parent.width
                                    height: 64
                                    radius: 10
                                    color: Qt.rgba(255, 255, 255, 0.04)
                                    border.width: 1
                                    border.color: Qt.rgba(255, 255, 255, 0.07)

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: I18n.tr("Totale Settimana")
                                            color: "#8a94a6"
                                            font.pixelSize: 10
                                            font.family: root.textFontFamily
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.formatTime(root.totalWeekSeconds)
                                            color: "#ffffff"
                                            font.pixelSize: 16
                                            font.weight: Font.Bold
                                            font.family: root.textFontFamily
                                            font.features: { "tnum": 1 }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Card Inferiore: App Più Usate nella Settimana
                    Rectangle {
                        anchors.top: weekHeatmapContainer.bottom
                        anchors.topMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        radius: 14
                        color: Qt.rgba(255, 255, 255, 0.04)
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.07)
                        clip: true

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Row {
                                width: parent.width
                                Text {
                                    text: I18n.tr("App Più Usate nella Settimana") + " (" + weekAppListModel.count + ")"
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    font.family: root.textFontFamily
                                }
                                Item { width: 12; height: 1 }
                                Text {
                                    text: I18n.tr("Clicca per dettagli orari 󰁔")
                                    color: root.accentColor
                                    font.pixelSize: 10
                                    font.family: root.textFontFamily
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            ListView {
                                id: weekAppListView
                                width: parent.width
                                height: parent.height - 24
                                clip: true
                                spacing: 4
                                model: weekAppListModel
                                boundsBehavior: Flickable.StopAtBounds

                                ScrollBar.vertical: ScrollBar {
                                    width: 3
                                    policy: ScrollBar.AsNeeded
                                }

                                delegate: Rectangle {
                                    width: ListView.view.width - 6
                                    height: 44
                                    radius: 8
                                    color: weekAppMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.07) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Item {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8

                                        Row {
                                            anchors.fill: parent
                                            spacing: 10

                                            Rectangle {
                                                width: 30
                                                height: 30
                                                radius: 6
                                                color: Qt.rgba(255, 255, 255, 0.06)
                                                anchors.verticalCenter: parent.verticalCenter

                                                Image {
                                                    anchors.centerIn: parent
                                                    width: 20
                                                    height: 20
                                                    source: model.icon ? (model.icon.startsWith("/") ? ("file://" + model.icon) : ("image://icon/" + model.icon)) : ""
                                                    sourceSize: Qt.size(40, 40)
                                                    visible: status === Image.Ready
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: !model.icon || model.icon === ""
                                                    text: "\uf108"
                                                    font.family: root.iconFontFamily
                                                    font.pixelSize: 14
                                                    color: root.accentColor
                                                }
                                            }

                                            Column {
                                                width: parent.width - 30 - 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 4

                                                Row {
                                                    width: parent.width

                                                    Text {
                                                        width: parent.width - weekTimeText.implicitWidth
                                                        text: model.name || model.appClass
                                                        color: "#ffffff"
                                                        font.pixelSize: 12
                                                        font.weight: Font.DemiBold
                                                        font.family: root.textFontFamily
                                                        elide: Text.ElideRight
                                                    }

                                                    Text {
                                                        id: weekTimeText
                                                        text: root.formatTime(model.seconds) + " (" + (model.percent || 0).toFixed(1) + "%)"
                                                        color: "#8e99a8"
                                                        font.pixelSize: 11
                                                        font.family: root.textFontFamily
                                                        font.features: { "tnum": 1 }
                                                    }
                                                }

                                                Rectangle {
                                                    width: parent.width
                                                    height: 4
                                                    radius: 2
                                                    color: Qt.rgba(255, 255, 255, 0.08)
                                                    clip: true

                                                    Rectangle {
                                                        // Clamping rigoroso sul calcolo della larghezza e riempimento animato da sinistra a destra
                                                        width: Math.min(parent.width, Math.max(0, parent.width * (Math.min(100, Math.max(0, model.percent || 0)) / 100.0) * root.appBarsProgress))
                                                        height: parent.height
                                                        radius: 2
                                                        color: root.accentColor

                                                        Behavior on width {
                                                            enabled: !appBarsAnim.running && root.capsuleReady && !root.isFirstLoad
                                                            NumberAnimation { duration: 320; easing.type: Easing.OutQuint }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: weekAppMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.isWeekView = false;
                                            root.selectApp(model);
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
