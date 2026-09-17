import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var hyprMonitor: null
    property string monitorName: ""
    property bool monitorFocused: false

    readonly property int monitorWorkspaceId: {
        if (!hyprMonitor || !hyprMonitor.activeWorkspace) return 1;
        const ws = hyprMonitor.activeWorkspace;
        const fromName = ws.name ? parseInt(ws.name) : NaN;
        if (!isNaN(fromName) && fromName > 0) return fromName;
        if (ws.id && ws.id > 0) return ws.id;
        return 1;
    }
    property int currentWorkspaceId: monitorWorkspaceId > 0 ? monitorWorkspaceId : 1

    signal workspaceSynced(int workspaceId)
    signal workspaceActivated(int workspaceId)

    onMonitorWorkspaceIdChanged: {
        if (monitorWorkspaceId >= 1 && monitorWorkspaceId !== currentWorkspaceId) {
            currentWorkspaceId = monitorWorkspaceId;
            workspaceSynced(monitorWorkspaceId);
            if (isTargetMonitorActive()) {
                showWorkspaceForThisMonitor(monitorWorkspaceId);
            }
        }
    }
    Component.onCompleted: syncWorkspaceState()

    function isTargetMonitorActive() {
        if (root.monitorFocused) return true;
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === monitorName) return true;
        return false;
    }

    function normalizeWorkspaceId(rawValue) {
        const parsed = parseInt(String(rawValue === undefined || rawValue === null ? "" : rawValue), 10);
        return isNaN(parsed) ? -1 : parsed;
    }

    function syncWorkspaceState() {
        if (monitorWorkspaceId < 1)
            return;

        currentWorkspaceId = monitorWorkspaceId;
        workspaceSynced(monitorWorkspaceId);
    }

    function showWorkspaceForThisMonitor(workspaceId) {
        const targetWorkspaceId = normalizeWorkspaceId(workspaceId);
        if (targetWorkspaceId >= 1)
            workspaceActivated(targetWorkspaceId);
    }

    function handleWorkspaceEvent(event) {
        if (!event)
            return;
        if (monitorName === "")
            return;

        if (event.name === "workspacev2" || event.name === "workspace") {
            const args = event.parse(event.name === "workspacev2" ? 2 : 1);
            const targetWorkspaceId = normalizeWorkspaceId(args.length > 0 ? args[0] : "");
            if (targetWorkspaceId < 1)
                return;

            if (!isTargetMonitorActive())
                return;

            if (targetWorkspaceId === root.currentWorkspaceId)
                return;

            root.currentWorkspaceId = targetWorkspaceId;
            root.workspaceSynced(targetWorkspaceId);
            root.showWorkspaceForThisMonitor(targetWorkspaceId);
            return;
        }

        if (event.name === "focusedmonv2" || event.name === "focusedmon") {
            const args = event.parse(2);
            const targetMonitorName = args.length > 0 ? String(args[0]) : "";
            const targetWorkspaceId = normalizeWorkspaceId(args.length > 1 ? args[1] : "");
            if (targetWorkspaceId < 1)
                return;
            if (monitorName !== "" && targetMonitorName !== monitorName)
                return;

            if (targetWorkspaceId === root.currentWorkspaceId)
                return;

            root.currentWorkspaceId = targetWorkspaceId;
            root.workspaceSynced(targetWorkspaceId);
            root.showWorkspaceForThisMonitor(targetWorkspaceId);
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            root.handleWorkspaceEvent(event);
        }
    }

    Connections {
        target: root.hyprMonitor

        function onActiveWorkspaceChanged() {
            if (root.monitorWorkspaceId >= 1 && root.monitorWorkspaceId !== root.currentWorkspaceId) {
                root.currentWorkspaceId = root.monitorWorkspaceId;
                root.workspaceSynced(root.monitorWorkspaceId);
                if (root.isTargetMonitorActive()) {
                    root.showWorkspaceForThisMonitor(root.monitorWorkspaceId);
                }
            }
        }
    }
}
