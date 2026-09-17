pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

FocusScope {
    id: root

    signal closeRequested

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string query: ""
    property var allApplications: []
    property var filteredApplications: []
    property var favoriteIds: []
    property var sortFavoriteIds: []
    property bool favoritesHydrated: false
    property int selectedIndex: -1
    property string appsBuffer: ""

    readonly property int visibleApplicationCount: filteredApplications.length

    focus: showCondition
    activeFocusOnTab: true
    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.showCondition ? 220 : 120
            easing.type: Easing.InOutQuad
        }
    }

    function isFavorite(entry) {
        return !!entry && root.favoriteIds.indexOf(String(entry.name || "")) >= 0;
    }

    function isSortFavorite(entry) {
        return !!entry && root.sortFavoriteIds.indexOf(String(entry.name || "")) >= 0;
    }

    function favoriteSortIndex(entry) {
        if (!entry)
            return -1;
        return root.sortFavoriteIds.indexOf(String(entry.name || ""));
    }

    function shortcutNumberForKeyEvent(event) {
        if (!event)
            return 0;

        const blockedModifiers = Qt.ControlModifier | Qt.AltModifier
            | Qt.MetaModifier | Qt.ShiftModifier;
        if (event.isAutoRepeat || (event.modifiers & blockedModifiers) !== 0)
            return 0;
        if (event.key < Qt.Key_1 || event.key > Qt.Key_9)
            return 0;
        return event.key - Qt.Key_0;
    }

    function launchFavoriteShortcut(event) {
        if (root.query !== "")
            return false;

        const requestedNumber = root.shortcutNumberForKeyEvent(event);
        if (requestedNumber === 0)
            return false;

        let shortcutNumber = 0;
        for (let index = 0; index < root.filteredApplications.length; ++index) {
            const entry = root.filteredApplications[index];
            if (!root.isFavorite(entry))
                continue;

            ++shortcutNumber;
            if (shortcutNumber === requestedNumber) {
                root.launchApplication(entry);
                return true;
            }
        }
        return false;
    }

    function favoriteShortcutNumber(entry) {
        if (!entry || root.query !== "" || !root.isFavorite(entry))
            return 0;

        let shortcutNumber = 0;
        for (let index = 0; index < root.filteredApplications.length; ++index) {
            const candidate = root.filteredApplications[index];
            if (!root.isFavorite(candidate))
                continue;

            ++shortcutNumber;
            if (String(candidate.name) === String(entry.name))
                return shortcutNumber <= 9 ? shortcutNumber : 0;
        }
        return 0;
    }

    function applyFavorites(stored, adoptSortOrder) {
        const nextFavorites = [];
        const seen = ({});

        if (Array.isArray(stored)) {
            for (let index = 0; index < stored.length; ++index) {
                const entryId = String(stored[index] || "").trim();
                if (entryId === "" || seen[entryId])
                    continue;
                seen[entryId] = true;
                nextFavorites.push(entryId);
            }
        }

        root.favoriteIds = nextFavorites;
        if (adoptSortOrder && !root.favoritesHydrated)
            root.sortFavoriteIds = nextFavorites.slice();
        root.favoritesHydrated = true;
        root.rebuildApplications();
    }

    function loadFavoritesFromDisk(adoptSortOrder) {
        let stored = [];
        try {
            const contents = favoritesFile.text();
            if (contents.trim() !== "") {
                const parsed = JSON.parse(contents);
                stored = parsed && Array.isArray(parsed.favoriteIds) ? parsed.favoriteIds : [];
            }
        } catch (error) {
            stored = [];
        }
        root.applyFavorites(stored, adoptSortOrder);
    }

    function toggleFavorite(entry) {
        if (!entry)
            return;

        if (!root.favoritesHydrated) {
            favoritesFile.waitForJob();
            root.loadFavoritesFromDisk(true);
        }

        const entryId = String(entry.name || "");
        const nextFavorites = root.favoriteIds.slice();
        const existingIndex = nextFavorites.indexOf(entryId);
        if (existingIndex >= 0)
            nextFavorites.splice(existingIndex, 1);
        else
            nextFavorites.push(entryId);

        root.favoriteIds = nextFavorites;
        favoriteStore.favoriteIds = nextFavorites;
        favoritesFile.writeAdapter();
        root.rebuildApplications();
    }

    function rebuildApplications() {
        const q = String(root.query || "").trim().toLowerCase();
        let list = (root.allApplications || []).slice();

        if (q !== "") {
            list = list.filter(app => {
                const n = String(app.name || "").toLowerCase();
                const e = String(app.exec || "").toLowerCase();
                return n.indexOf(q) >= 0 || e.indexOf(q) >= 0;
            });
        }

        list.sort((left, right) => {
            if (q === "") {
                const leftFavorite = root.isSortFavorite(left);
                const rightFavorite = root.isSortFavorite(right);
                if (leftFavorite !== rightFavorite)
                    return leftFavorite ? -1 : 1;
                if (leftFavorite && rightFavorite) {
                    const favoriteOrder = root.favoriteSortIndex(left) - root.favoriteSortIndex(right);
                    if (favoriteOrder !== 0)
                        return favoriteOrder;
                }
            }
            return String(left.name || "").localeCompare(String(right.name || ""));
        });

        root.filteredApplications = list;
        root.selectedIndex = list.length > 0 ? 0 : -1;
        if (!appGrid)
            return;
        appGrid.currentIndex = root.selectedIndex;
        if (root.selectedIndex >= 0)
            appGrid.positionViewAtIndex(0, GridView.Beginning);
    }

    function grabKeyboardFocus() {
        root.forceActiveFocus();
        searchInput.forceActiveFocus();
    }

    function moveSelection(offset) {
        const count = root.visibleApplicationCount;
        if (count <= 0)
            return;

        if (root.selectedIndex < 0) {
            root.selectedIndex = offset > 0 ? 0 : count - 1;
        } else {
            let next = root.selectedIndex + offset;
            while (next < 0)
                next += count;
            root.selectedIndex = next % count;
        }
        appGrid.currentIndex = root.selectedIndex;
        appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }

    function launchApplication(entry) {
        if (!entry || !entry.exec)
            return;

        const scopedCommand = [
            "systemd-run",
            "--user",
            "--scope",
            "--quiet",
            "--collect",
            "--slice=app.slice",
            "--",
            "bash",
            "-c",
            entry.exec
        ];

        Quickshell.execDetached(scopedCommand);
        root.closeRequested();
    }

    function launchSelected() {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.visibleApplicationCount)
            return;
        root.launchApplication(root.filteredApplications[root.selectedIndex]);
    }

    onShowConditionChanged: {
        if (showCondition) {
            sortFavoriteIds = favoriteIds.slice();
            searchInput.text = "";
            query = "";
            rebuildApplications();
            focusTimer.restart();
            if (!appsFetcher.running)
                appsFetcher.running = true;
        }
    }

    FileView {
        id: cealestiaAppsFile
        path: "/home/lollo/.cache/cealestia_apps.json"
        preload: true
        watchChanges: true
        printErrors: false

        onLoaded: root.loadCachedApps()
    }

    function loadCachedApps() {
        try {
            const txt = cealestiaAppsFile.text();
            if (txt && txt.trim().length > 0) {
                const list = JSON.parse(txt.trim());
                if (Array.isArray(list) && list.length > 0) {
                    root.allApplications = list;
                    root.rebuildApplications();
                }
            }
        } catch(e) {
            console.log("[ApplicationLauncher] Error loading cached apps:", e);
        }
    }

    Process {
        id: appsFetcher
        command: ["python3", "/home/lollo/.scripts/get-apps.py"]
        running: false
        stdout: SplitParser {
            onRead: function(data) {
                root.appsBuffer += data;
            }
        }
        onExited: function(code) {
            if (code === 0) {
                try {
                    const list = JSON.parse(root.appsBuffer.trim());
                    if (Array.isArray(list) && list.length > 0) {
                        root.allApplications = list;
                        root.rebuildApplications();
                    }
                } catch(e) {
                    console.log("[ApplicationLauncher] Error parsing get-apps output:", e);
                }
            }
            root.appsBuffer = "";
        }
    }

    Component.onCompleted: {
        root.loadCachedApps();
        if (!appsFetcher.running)
            appsFetcher.running = true;
    }

    FileView {
        id: favoritesFile
        path: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)
            + "/tide-island/application-launcher.json"
        preload: true
        watchChanges: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: favoriteStore
            property var favoriteIds: []
        }

        onLoaded: root.loadFavoritesFromDisk(true)
    }

    Timer {
        id: focusTimer
        interval: 0
        repeat: false
        onTriggered: root.grabKeyboardFocus()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        } else if (root.launchFavoriteShortcut(event)) {
            event.accepted = true;
        }
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 16
        anchors.bottomMargin: 14
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 12

        Item {
            width: parent.width
            height: 44

            Rectangle {
                id: searchField
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(500, parent.width - 40)
                height: parent.height
                radius: 16
                color: searchInput.activeFocus ? "#17181c" : "#111216"
                border.width: 1
                border.color: searchInput.activeFocus ? "#3d3f47" : "#292a30"

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf002"
                    color: searchInput.activeFocus ? "#d1d1d6" : "#8e8e93"
                    font.family: root.iconFontFamily
                    font.pixelSize: 15
                }

                Text {
                    anchors.left: searchInput.left
                    anchors.verticalCenter: searchInput.verticalCenter
                    text: "Cerca applicazione..."
                    color: "#636366"
                    font.family: root.textFontFamily
                    font.pixelSize: 15
                    visible: searchInput.text === "" && !searchInput.activeFocus
                }

                TextInput {
                    id: searchInput
                    anchors.left: parent.left
                    anchors.leftMargin: 45
                    anchors.right: parent.right
                    anchors.rightMargin: root.query === "" ? 16 : 42
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#f5f5f7"
                    selectionColor: "#0a84ff"
                    selectedTextColor: "#ffffff"
                    font.family: root.textFontFamily
                    font.pixelSize: 15
                    clip: true
                    selectByMouse: true
                    text: ""

                    onTextChanged: {
                        if (root.query !== text)
                            root.query = text;
                        root.rebuildApplications();
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.closeRequested();
                            event.accepted = true;
                        } else if (root.launchFavoriteShortcut(event)) {
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right && text === "") {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.moveSelection(5);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left && text === "") {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-5);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab) {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launchSelected();
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.query !== ""
                    width: 24
                    height: 24
                    radius: 12
                    color: clearSearchArea.containsMouse ? "#34353b" : "#24252a"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        color: "#a5a6ac"
                        font.family: root.iconFontFamily
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: clearSearchArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: searchInput.forceActiveFocus()
                }
            }

        }

        GridView {
            id: appGrid
            width: parent.width
            height: 342
            model: root.filteredApplications
            cellWidth: Math.floor(width / 5)
            cellHeight: 114
            flow: GridView.FlowLeftToRight
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 1800
            keyNavigationEnabled: false

            delegate: Item {
                id: appDelegate
                required property var modelData
                required property int index

                readonly property var entry: modelData
                readonly property bool selected: index === root.selectedIndex
                readonly property bool favorite: root.isFavorite(entry)
                readonly property int favoriteNumber: root.favoriteShortcutNumber(entry)

                width: appGrid.cellWidth
                height: appGrid.cellHeight

                Item {
                    id: appCard

                    z: 2
                    anchors.centerIn: parent
                    width: parent.width - 12
                    height: 102
                    scale: appArea.pressed ? 0.95
                        : (appDelegate.selected || appArea.containsMouse ? 1.035 : 1)

                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Item {
                        id: iconArea
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 66
                        height: 66

                        Image {
                            id: appIcon
                            anchors.centerIn: parent
                            width: 56
                            height: 56
                            source: {
                                const ic = String(appDelegate.entry.icon || "");
                                if (!ic) return "";
                                if (ic.startsWith("/") || ic.startsWith("file://"))
                                    return ic.startsWith("file://") ? ic : ("file://" + ic);
                                return Quickshell.iconPath(ic, true);
                            }
                            asynchronous: true
                            mipmap: true
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            z: 100
                            visible: !appIcon.visible
                            text: String(appDelegate.entry.name || "?").charAt(0).toLocaleUpperCase()
                            color: "white"
                            font.family: root.textFontFamily
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.topMargin: -2
                            anchors.left: parent.left
                            anchors.leftMargin: -2
                            visible: appDelegate.favoriteNumber > 0
                            text: appDelegate.favoriteNumber
                            color: "#a5a6ac"
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        anchors.top: iconArea.bottom
                        anchors.topMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 6
                        text: appDelegate.entry.name || ""
                        color: appDelegate.selected ? "#f5f5f7" : "#d0d1d5"
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        font.weight: appDelegate.selected ? Font.Medium : Font.Normal
                    }

                    FavoriteStar {
                        anchors.top: iconArea.top
                        anchors.topMargin: -2
                        anchors.right: iconArea.right
                        anchors.rightMargin: -4
                        active: appDelegate.favorite
                        hovered: delegateHover.hovered
                        onToggleRequested: root.toggleFavorite(appDelegate.entry)
                    }
                }

                MouseArea {
                    id: appArea
                    z: 1
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        root.selectedIndex = appDelegate.index;
                        appGrid.currentIndex = appDelegate.index;
                    }
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton)
                            root.toggleFavorite(appDelegate.entry);
                        else
                            root.launchApplication(appDelegate.entry);
                    }
                }

                HoverHandler {
                    id: delegateHover
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.visibleApplicationCount === 0
                text: root.query === "" ? "Nessuna applicazione trovata" : "Nessuna applicazione trovata per “" + root.query + "”"
                color: "#696b72"
                font.family: root.textFontFamily
                font.pixelSize: 13
            }
        }
    }
}
