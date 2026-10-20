pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    WlSessionLock {
        id: sessionLock

        signal requestUnlock()

        LockSurface {
            lock: sessionLock
        }
    }

    IpcHandler {
        id: lockIpc
        target: "lock"

        signal lockedSecure

        function lock(): void {
            sessionLock.locked = true;
            if (sessionLock.secure) settled.restart();
        }

        function unlock(): void {
            if (sessionLock.locked) {
                sessionLock.requestUnlock();
            }
        }

        function isLocked(): bool {
            return sessionLock.locked;
        }
    }

    IpcHandler {
        id: appleLockIpc
        target: "apple-lock"

        function lock(): void {
            lockIpc.lock();
        }

        function unlock(): void {
            lockIpc.unlock();
        }

        function isLocked(): bool {
            return lockIpc.isLocked();
        }
    }

    Timer {
        id: settled
        interval: 800
        onTriggered: lockIpc.lockedSecure()
    }

    Connections {
        target: sessionLock

        function onSecureChanged(): void {
            if (sessionLock.secure) {
                settled.restart();
            }
        }
    }
}
