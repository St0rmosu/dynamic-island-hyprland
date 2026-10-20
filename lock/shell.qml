pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

Scope {
    id: root

    // ── Background MPRIS Album Art Pre-Cacher (ensures instant 0ms lock art sync) ──
    property string lastDownloadedArtUrl: ""

    function getArtCachePath(url) {
        if (!url || typeof url !== "string") return "/tmp/lock_cached_art.jpg";
        let parts = url.split("/");
        let last = parts[parts.length - 1];
        let safeName = last.replace(/[^a-zA-Z0-9_\.-]/g, "_");
        if (!safeName || safeName.length < 3) return "/tmp/lock_cached_art.jpg";
        return "/tmp/lock_art_" + safeName + ".jpg";
    }

    Process {
        id: bgArtProc
        running: false
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            if (Mpris.players && Mpris.players.values) {
                for (let i = 0; i < Mpris.players.values.length; i++) {
                    let p = Mpris.players.values[i];
                    if (p && (p.playbackState === MprisPlaybackState.Playing || p.playbackState === MprisPlaybackState.Paused)) {
                        let url = p.trackArtUrl || p.artUrl;
                        if (!url && p.metadata) url = p.metadata["mpris:artUrl"];
                        if (url && (String(url).startsWith("http://") || String(url).startsWith("https://"))) {
                            let strUrl = String(url);
                            if (strUrl !== root.lastDownloadedArtUrl) {
                                root.lastDownloadedArtUrl = strUrl;
                                let targetFile = root.getArtCachePath(strUrl);
                                bgArtProc.command = ["sh", "-c", "curl -sL '" + strUrl + "' -o '" + targetFile + "' && cp -f '" + targetFile + "' /tmp/lock_cached_art.jpg"];
                                bgArtProc.running = true;
                            }
                        }
                        break;
                    }
                }
            }
        }
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
