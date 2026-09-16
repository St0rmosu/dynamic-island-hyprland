import QtQuick
import Quickshell.Hyprland
import "../common"

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property var screenObject: null

    readonly property var monitor: screenObject
        ? Hyprland.monitorFor(screenObject)
        : Hyprland.focusedMonitor
    readonly property string monitorName: monitor && monitor.name ? String(monitor.name) : ""
    readonly property bool monitorFocused: monitor ? !!monitor.focused : false
    readonly property int workspaceId: {
        if (!monitor || !monitor.activeWorkspace) return 1;
        const ws = monitor.activeWorkspace;
        const fromName = ws.name ? parseInt(ws.name) : NaN;
        if (!isNaN(fromName) && fromName > 0) return fromName;
        if (ws.id && ws.id > 0) return ws.id;
        return 1;
    }

    HyprlandDispatch {
        id: dispatch
    }

    function focusWorkspace(workspace) {
        return dispatch.focusWorkspace(workspace);
    }
}
