pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock

    color: "transparent"

    LockContent {
        anchors.fill: parent
        onUnlockRequested: {
            root.lock.locked = false;
        }
    }
}
