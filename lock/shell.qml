pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

Scope {
    id: root

    // ── Background MPRIS Album Art Pre-Cacher (keeps image warm in Qt Quick cache) ──
    property int mprisPulse: 0

    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            ignoreUnknownSignals: true
            function onPlaybackStateChanged() { root.mprisPulse++; }
            function onTrackTitleChanged() { root.mprisPulse++; }
            function onTrackArtUrlChanged() { root.mprisPulse++; }
            function onMetadataChanged() { root.mprisPulse++; }
        }
        onObjectAdded: root.mprisPulse++
        onObjectRemoved: root.mprisPulse++
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.mprisPulse++; }
    }

    property string activeArtUrl: {
        let _p = root.mprisPulse;
        if (!Mpris.players || !Mpris.players.values) return "";
        for (let i = 0; i < Mpris.players.values.length; i++) {
            let p = Mpris.players.values[i];
            if (p && (p.playbackState === MprisPlaybackState.Playing || p.playbackState === MprisPlaybackState.Paused)) {
                let url = p.trackArtUrl || p.artUrl;
                if (!url && p.metadata) url = p.metadata["mpris:artUrl"];
                if (url && String(url).length > 0) return String(url);
            }
        }
        return "";
    }

    Image {
        id: bgArtPreloader
        visible: false
        source: root.activeArtUrl
        sourceSize: Qt.size(500, 500)
        asynchronous: true
    }

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
