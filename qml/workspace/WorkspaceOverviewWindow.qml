pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root

    property var toplevel: null
    property var windowData: null
    property var monitorData: null
    property var widgetMonitor: null
    property real scale: 0.18
    property real xOffset: 0
    property real yOffset: 0
    property bool centerIcons: true
    property bool previewEnabled: true
    property bool hovered: false
    property bool pressed: false
    property bool draggingActive: false
    property bool forcePreviewActive: false
    property var positionOverride: null
    property real visibilityOpacity: 1
    property real topLeftRadius: 18
    property real topRightRadius: 18
    property real bottomLeftRadius: 18
    property real bottomRightRadius: 18

    readonly property real widthRatio: {
        if (!widgetMonitor || !monitorData)
            return 1;

        const widgetWidth = widgetMonitor.transform & 1 ? widgetMonitor.height : widgetMonitor.width;
        const monitorWidth = monitorData.transform & 1 ? monitorData.height : monitorData.width;
        return monitorWidth > 0 ? (widgetWidth * monitorData.scale) / (monitorWidth * widgetMonitor.scale) : 1;
    }
    readonly property real heightRatio: {
        if (!widgetMonitor || !monitorData)
            return 1;

        const widgetHeight = widgetMonitor.transform & 1 ? widgetMonitor.width : widgetMonitor.height;
        const monitorHeight = monitorData.transform & 1 ? monitorData.width : monitorData.height;
        return monitorHeight > 0 ? (widgetHeight * monitorData.scale) / (monitorHeight * widgetMonitor.scale) : 1;
    }
    readonly property real targetWindowWidth: Math.max(52, (windowData && windowData.size ? windowData.size[0] : 240) * scale * widthRatio)
    readonly property real targetWindowHeight: Math.max(38, (windowData && windowData.size ? windowData.size[1] : 140) * scale * heightRatio)
    readonly property real initX: {
        if (!windowData || !monitorData)
            return xOffset;

        const reserved = monitorData.reserved ? monitorData.reserved : [0, 0, 0, 0];
        const position = positionOverride
            ? [positionOverride.x, positionOverride.y]
            : (windowData.at ? windowData.at : [monitorData.x, monitorData.y]);
        return Math.max((position[0] - monitorData.x - reserved[0]) * widthRatio * scale, 0) + xOffset;
    }
    readonly property real initY: {
        if (!windowData || !monitorData)
            return yOffset;

        const reserved = monitorData.reserved ? monitorData.reserved : [0, 0, 0, 0];
        const position = positionOverride
            ? [positionOverride.x, positionOverride.y]
            : (windowData.at ? windowData.at : [monitorData.x, monitorData.y]);
        return Math.max((position[1] - monitorData.y - reserved[1]) * heightRatio * scale, 0) + yOffset;
    }
    readonly property string iconLookupName: {
        if (!windowData)
            return "";

        return windowData.class || windowData.initialClass || windowData.app_id || windowData.initialTitle || windowData.title || "";
    }
    readonly property bool compactMode: Math.min(targetWindowWidth, targetWindowHeight) < 120
    readonly property string iconThemeName: resolveIconThemeName(iconLookupName)
    readonly property string iconPath: Quickshell.iconPath(iconThemeName, "image-missing")
    readonly property real baseOpacity: !windowData ? 0 : (widgetMonitor && windowData.monitor === widgetMonitor.id ? 1 : 0.46)
    readonly property bool previewActive: previewEnabled && !!toplevel && (forcePreviewActive || (visible && opacity > 0))

    function iconExists(iconName) {
        if (!iconName || iconName.length === 0)
            return false;
        const p = Quickshell.iconPath(iconName, true);
        return p.length > 0 && !p.includes("image-missing");
    }

    function resolveIconThemeName(rawName) {
        const name = String(rawName === undefined || rawName === null ? "" : rawName).trim();
        if (name === "")
            return "application-x-executable";

        const substitutions = {
            "code": "vscode",
            "code-url-handler": "vscode",
            "codium": "vscodium",
            "vscodium": "vscodium",
            "visual-studio-code": "vscode",
            "footclient": "foot",
            "zen": "zen-browser",
            "zen-alpha": "zen-browser",
            "zen-beta": "zen-browser",
            "zen-browser": "zen-browser",
            "spotify": "spotify-client",
            "hyprfm": "org.gnome.Nautilus",
            "nautilus": "org.gnome.Nautilus",
            "gnome-tweaks": "org.gnome.tweaks",
            "pavucontrol-qt": "pavucontrol",
            "pavucontrol": "pavucontrol",
            "wps": "wps-office2019-kprometheus",
            "wpsoffice": "wps-office2019-kprometheus",
            "vesktop": "vesktop",
            "discord": "discord",
            "webcord": "discord",
            "google-chrome-stable": "google-chrome",
            "google-chrome": "google-chrome",
            "chrome": "google-chrome",
            "chromium": "chromium",
            "brave-browser": "brave-browser",
            "brave": "brave-browser",
            "microsoft-edge-dev": "microsoft-edge-dev",
            "microsoft-edge": "microsoft-edge",
            "obsidian": "obsidian",
            "notion-app-enhanced": "notion-app-enhanced",
            "notion-calendar-electron": "notion-calendar-electron",
            "notion": "notion-app-enhanced",
            "kdenlive": "kdenlive",
            "gimp": "gimp",
            "inkscape": "inkscape",
            "blender": "blender",
            "vlc": "vlc",
            "mpv": "mpv",
            "kitty": "kitty",
            "alacritty": "Alacritty",
            "wezterm": "org.wezfurlong.wezterm",
            "org.wezfurlong.wezterm": "org.wezfurlong.wezterm",
            "obs": "com.obsproject.Studio",
            "obs-studio": "com.obsproject.Studio",
            "telegramdesktop": "telegram",
            "org.telegram.desktop": "telegram",
            "telegram": "telegram",
            "satty": "satty",
            "localsend": "localsend",
            "teams": "teams-for-linux",
            "teams-for-linux": "teams-for-linux",
            "whatsapp": "whatsapp-linux-desktop",
            "whatsapp-linux-desktop": "whatsapp-linux-desktop",
            "zathura": "org.pwmt.zathura",
            "org.pwmt.zathura": "org.pwmt.zathura",
            "btop": "btop",
            "yazi": "yazi"
        };

        if (substitutions[name] && iconExists(substitutions[name]))
            return substitutions[name];
        const lowerName = name.toLowerCase();
        if (substitutions[lowerName] && iconExists(substitutions[lowerName]))
            return substitutions[lowerName];

        const steamMatch = lowerName.match(/^steam_app_(\d+)$/);
        if (steamMatch) {
            const steamIcon = "steam_icon_" + steamMatch[1];
            if (iconExists(steamIcon)) return steamIcon;
            if (iconExists("steam")) return "steam";
        }
        if (lowerName.indexOf("polkit") !== -1 || lowerName.indexOf("gcr.prompter") !== -1) {
            if (iconExists("system-lock-screen")) return "system-lock-screen";
        }

        if (iconExists(name))
            return name;

        if (iconExists(lowerName))
            return lowerName;

        const parts = name.split(".");
        const lastPart = parts[parts.length - 1];
        if (iconExists(lastPart))
            return lastPart;
        if (iconExists(lastPart.toLowerCase()))
            return lastPart.toLowerCase();

        const kebab = lowerName.replace(/[_\s]+/g, "-");
        if (iconExists(kebab))
            return kebab;

        if (iconExists(lowerName + "-browser"))
            return lowerName + "-browser";
        if (iconExists(lowerName + "-client"))
            return lowerName + "-client";
        if (iconExists(lowerName + "-desktop"))
            return lowerName + "-desktop";

        if (substitutions[lowerName])
            return substitutions[lowerName];

        if (lowerName.indexOf("vesktop") !== -1 || lowerName.indexOf("discord") !== -1)
            return iconExists("vesktop") ? "vesktop" : "discord";

        if (lowerName.indexOf("zen") !== -1)
            return iconExists("zen-browser") ? "zen-browser" : "zen";

        if (lowerName.indexOf("code") !== -1 || lowerName.indexOf("codium") !== -1)
            return iconExists("vscode") ? "vscode" : (iconExists("visual-studio-code") ? "visual-studio-code" : "vscodium");

        if (lowerName.indexOf("spotify") !== -1)
            return iconExists("spotify-client") ? "spotify-client" : "spotify";

        if (iconExists("application-x-executable"))
            return "application-x-executable";

        return "image-missing";
    }
    x: initX
    y: initY
    width: targetWindowWidth
    height: targetWindowHeight
    opacity: baseOpacity * visibilityOpacity

    Behavior on x {
        enabled: !root.draggingActive

        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        enabled: !root.draggingActive

        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        color: "transparent"
        contentUnderBorder: true
        antialiasing: true
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        border.width: 1
        border.color: root.hovered ? "#77ffffff" : "#33ffffff"

        ScreencopyView {
            anchors.fill: parent
            captureSource: root.previewActive ? root.toplevel : null
            constraintSize: Qt.size(Math.max(1, Math.round(root.width)), Math.max(1, Math.round(root.height)))
            live: root.previewActive
        }

        Rectangle {
            anchors.fill: parent
            color: root.draggingActive
                ? "#14ffffff"
                : (root.pressed
                    ? "#26000000"
                    : (root.hovered ? "#10ffffff" : "transparent"))
        }

        Image {
            id: appIcon

            readonly property real iconSize: {
                const baseSize = Math.min(root.width, root.height);
                const ratio = root.compactMode ? 0.55 : (root.centerIcons ? 0.35 : 0.18);
                return Math.max(18, Math.round(baseSize * ratio));
            }
            property bool iconLoadFailed: false

            anchors {
                top: root.centerIcons ? undefined : parent.top
                left: root.centerIcons ? undefined : parent.left
                centerIn: root.centerIcons ? parent : undefined
                margins: root.centerIcons ? 0 : Math.max(6, Math.round(Math.min(root.width, root.height) * 0.06))
            }
            visible: source !== "" && !iconLoadFailed
            source: !iconLoadFailed ? root.iconPath : ""
            width: iconSize
            height: iconSize
            sourceSize: Qt.size(width, height)
            mipmap: true
            smooth: true
            opacity: 0.96

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: "#73000000"
            }

            onStatusChanged: {
                if (status === Image.Error)
                    iconLoadFailed = true;
            }

            Connections {
                target: root

                function onIconPathChanged() {
                    appIcon.iconLoadFailed = false;
                }
            }
        }
    }
}
