pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock

    color: "transparent"

    Connections {
        target: root.lock
        function onLockedChanged(): void {
            if (root.lock.locked) {
                content.resetToLockedState();
            }
        }
        function onRequestUnlock(): void {
            content.triggerUnlock();
        }
    }

    LockContent {
        id: content
        anchors.fill: parent
        onUnlockRequested: {
            root.lock.locked = false;
        }
    }
}
