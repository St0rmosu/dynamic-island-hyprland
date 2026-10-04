import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: bgWindow

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "dynamic-island:background"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    property var shellRootController: null
    property var dynamicConfig: null

    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")

    // File watchers per tracciare lo sfondo attivo in tempo reale
    FileView {
        id: walCurrentFile
        path: bgWindow.homeDir + "/.cache/wal/wal"
        watchChanges: true
        preload: true
        printErrors: false
        property string wallpaper: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: wallpaper = text().trim()
    }

    FileView {
        id: pywalColorsFile
        path: bgWindow.homeDir + "/.cache/wal/colors.json"
        watchChanges: true
        preload: true
        printErrors: false
        property string wallpaper: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.wallpaper) wallpaper = d.wallpaper.trim();
            } catch(e) {}
        }
    }

    FileView {
        id: configCurrentFile
        path: bgWindow.homeDir + "/.config/dynamic-island/current_wallpaper"
        watchChanges: true
        preload: true
        printErrors: false
        property string wallpaper: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: wallpaper = text().trim()
    }

    FileView {
        id: iiConfigFile
        path: bgWindow.homeDir + "/.config/illogical-impulse/config.json"
        watchChanges: true
        preload: true
        printErrors: false
        property string wallpaper: ""
        Component.onCompleted: reload()
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                if (d && d.background && d.background.wallpaperPath) {
                    wallpaper = d.background.wallpaperPath.trim();
                }
            } catch(e) {}
        }
    }

    readonly property string effectiveWallpaperPath: {
        if (dynamicConfig && dynamicConfig.wallpaperPath && dynamicConfig.wallpaperPath !== "")
            return dynamicConfig.wallpaperPath;
        if (configCurrentFile.wallpaper !== "")
            return configCurrentFile.wallpaper;
        if (walCurrentFile.wallpaper !== "")
            return walCurrentFile.wallpaper;
        if (pywalColorsFile.wallpaper !== "")
            return pywalColorsFile.wallpaper;
        if (iiConfigFile.wallpaper !== "")
            return iiConfigFile.wallpaper;
        return "";
    }

    readonly property string effectiveWallpaperUrl: {
        const wp = effectiveWallpaperPath;
        if (wp === "") return "";
        return wp.startsWith("file://") ? wp : ("file://" + encodeURI(wp));
    }

    // Se abilitato da configurazione (default: true) e lo sfondo è valido
    visible: (dynamicConfig ? (dynamicConfig.enableQuickshellWallpaper !== false) : true) && effectiveWallpaperUrl !== ""

    Image {
        id: bgImage
        anchors.fill: parent
        source: bgWindow.effectiveWallpaperUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true

        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }
    }
}
