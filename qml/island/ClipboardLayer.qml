import QtCore
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import IslandBackend

FocusScope {
    id: root

    signal closeRequested
    signal itemCopied(string message)
    signal itemSelected(var item)

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property color accentColor: StyleTokens.accent
    property string searchQuery: ""
    property bool isLoading: false

    property var allItems: []
    property var filteredItems: []
    property var leftColumnItems: []
    property var rightColumnItems: []
    property string copiedItemId: ""
    readonly property string homeDir: Quickshell.env("HOME") || "/home/" + (Quickshell.env("USER") || "user")
    readonly property string helperScriptPath: homeDir + "/.config/quickshell/dynamic-island/scripts/cliphist_helper.py"

    focus: showCondition
    activeFocusOnTab: true
    anchors.fill: parent
    opacity: showCondition ? 1 : 0
    visible: opacity > 0.001

    Behavior on opacity {
        NumberAnimation {
            duration: root.showCondition ? 240 : 120
            easing.type: Easing.OutCubic
        }
    }

    property int renderLimit: 12

    Timer {
        id: deferredLoadTimer
        interval: 260
        repeat: false
        onTriggered: {
            if (root.renderLimit < root.filteredItems.length) {
                root.renderLimit = root.filteredItems.length;
                root.rebuildMasonryColumns();
            }
        }
    }

    onShowConditionChanged: {
        if (showCondition) {
            root.searchQuery = "";
            searchInput.text = "";
            root.copiedItemId = "";
            root.isLoading = true;
            root.renderLimit = 12;
            cacheFileView.reload();
            refreshHistory();
            deferredLoadTimer.restart();
            focusTimer.restart();
        } else {
            deferredLoadTimer.stop();
            root.renderLimit = 12;
        }
    }

    Timer {
        id: focusTimer
        interval: 60
        repeat: false
        onTriggered: root.grabKeyboardFocus()
    }

    function grabKeyboardFocus() {
        root.focus = true;
        root.forceActiveFocus();
        searchInput.forceActiveFocus();
    }

    Timer {
        id: resetCopiedTimer
        interval: 700
        repeat: false
        onTriggered: {
            root.copiedItemId = "";
        }
    }

    FileView {
        id: cacheFileView
        path: "/tmp/cliphist_cache.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const raw = text();
                if (raw && raw.length > 2) {
                    root.parseCacheJson(raw);
                }
            } catch(e) {
                console.warn("[ClipboardLayer] Error reading cache file:", e);
            }
        }
    }

    Process {
        id: helperProcess
        command: [root.helperScriptPath, "--limit", "60"]
        running: false
        property string stdoutBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                helperProcess.stdoutBuffer += data;
            }
        }

        onExited: code => {
            if (code === 0 && helperProcess.stdoutBuffer.trim().length > 0) {
                root.parseCacheJson(helperProcess.stdoutBuffer.trim());
            }
            helperProcess.stdoutBuffer = "";
            root.isLoading = false;
        }
    }

    function refreshHistory() {
        if (!helperProcess.running) {
            helperProcess.stdoutBuffer = "";
            helperProcess.running = true;
        }
    }

    function parseCacheJson(jsonStr) {
        try {
            const list = JSON.parse(jsonStr);
            if (Array.isArray(list)) {
                root.allItems = list;
                root.applyFilter();
            }
        } catch(e) {
            console.warn("[ClipboardLayer] Error parsing clipboard JSON:", e);
        }
    }

    function applyFilter() {
        const q = root.searchQuery.trim().toLowerCase();
        if (q === "") {
            root.filteredItems = root.allItems;
            root.renderLimit = 12;
            deferredLoadTimer.restart();
        } else {
            root.filteredItems = root.allItems.filter(item => {
                if (!item) return false;
                const t = (item.title || "").toLowerCase();
                const p = (item.preview || "").toLowerCase();
                const c = (item.content || "").toLowerCase();
                return t.indexOf(q) >= 0 || p.indexOf(q) >= 0 || c.indexOf(q) >= 0;
            });
            root.renderLimit = root.filteredItems.length;
        }
        root.rebuildMasonryColumns();
    }

    function rebuildMasonryColumns() {
        const left = [];
        const right = [];
        let leftH = 0;
        let rightH = 0;

        const count = Math.min(root.filteredItems.length, root.renderLimit);
        for (let i = 0; i < count; ++i) {
            const item = root.filteredItems[i];
            if (!item) continue;

            let estHeight = 115;
            if (item.type === "image") {
                estHeight = 210;
            } else {
                const len = (item.preview || item.content || "").length;
                if (len > 80) estHeight = 145;
                else if (len < 30) estHeight = 90;
                else estHeight = 118;
            }

            if (leftH <= rightH) {
                left.push(item);
                leftH += estHeight + 14;
            } else {
                right.push(item);
                rightH += estHeight + 14;
            }
        }

        root.leftColumnItems = left;
        root.rightColumnItems = right;
    }

    function copyItem(itemId, itemTitle, itemObj) {
        root.copiedItemId = String(itemId);
        resetCopiedTimer.restart();

        try {
            Quickshell.execDetached([root.helperScriptPath, "--copy", String(itemId)]);
        } catch(e) {
            console.warn("[ClipboardLayer] Error calling execDetached for copy:", e);
        }

        root.itemCopied(itemTitle || "Copied to clipboard");
        if (itemObj) {
            root.itemSelected(itemObj);
        }
    }

    function deleteItem(itemId) {
        try {
            Quickshell.execDetached([root.helperScriptPath, "--delete", String(itemId)]);
        } catch(e) {
            console.warn("[ClipboardLayer] Error deleting item:", e);
        }

        root.allItems = root.allItems.filter(it => it && String(it.id) !== String(itemId));
        root.applyFilter();
    }

    function clearAllHistory() {
        try {
            Quickshell.execDetached([root.helperScriptPath, "--clear"]);
        } catch(e) {
            console.warn("[ClipboardLayer] Error clearing history:", e);
        }

        root.allItems = [];
        root.filteredItems = [];
        root.leftColumnItems = [];
        root.rightColumnItems = [];
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.filteredItems.length > 0) {
                const first = root.filteredItems[0];
                root.copyItem(first.id, first.title, first);
                event.accepted = true;
            }
        }
    }

    Component.onCompleted: {
        root.renderLimit = 12;
        cacheFileView.reload();
        refreshHistory();
        deferredLoadTimer.restart();
    }

    // Main Container
    Item {
        anchors.fill: parent

        // Top Navigation Bar
        Item {
            id: topBar
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 22
            anchors.right: parent.right
            anchors.rightMargin: 22
            height: 42
            z: 20

            // Search Bar (Sleek Apple Intelligence pill)
            Rectangle {
                id: searchPill
                anchors.left: parent.left
                anchors.right: actionsRow.left
                anchors.rightMargin: 14
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 16
                color: searchInput.activeFocus ? "#1f2128" : "#16171d"
                border.width: searchInput.activeFocus ? 1.5 : 1
                border.color: searchInput.activeFocus ? root.accentColor : "#2a2b34"

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                // Search Icon
                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf002"
                    font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                    font.pixelSize: 14
                    color: searchInput.activeFocus ? root.accentColor : "#8e8e93"
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Placeholder
                Text {
                    anchors.left: searchInput.left
                    anchors.verticalCenter: searchInput.verticalCenter
                    text: "Search clipboard..."
                    color: "#6c6c70"
                    font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                    font.pixelSize: 14
                    visible: searchInput.text === "" && !searchInput.activeFocus
                }

                // Search Input Field
                TextInput {
                    id: searchInput
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 11
                    anchors.right: clearSearchBtn.visible ? clearSearchBtn.left : parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#f5f5f7"
                    selectionColor: root.accentColor
                    selectedTextColor: "#ffffff"
                    font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                    font.pixelSize: 14
                    clip: true
                    selectByMouse: true
                    text: ""

                    onTextChanged: {
                        if (root.searchQuery !== text) {
                            root.searchQuery = text;
                            root.applyFilter();
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            if (text !== "") {
                                text = "";
                            } else {
                                root.closeRequested();
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            cardsFlickable.flick(0, -300);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            cardsFlickable.flick(0, 300);
                            event.accepted = true;
                        }
                    }
                }

                // Clear Search Query Button
                Rectangle {
                    id: clearSearchBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: clearSearchMouse.containsMouse ? "#33ffffff" : "#1fffffff"
                    visible: searchInput.text !== ""

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 10
                        color: "#c7c7cc"
                    }

                    MouseArea {
                        id: clearSearchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }

            // Action Buttons Row (Item count badge, Clear history, Close)
            Row {
                id: actionsRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // Item Count Badge
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 34
                    width: countText.implicitWidth + 20
                    radius: 14
                    color: "#14ffffff"
                    border.width: 1
                    border.color: "#20ffffff"

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.filteredItems.length === root.allItems.length
                            ? `${root.allItems.length} items`
                            : `${root.filteredItems.length} of ${root.allItems.length}`
                        color: "#98989d"
                        font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                // Clear History Button
                Rectangle {
                    id: clearHistoryBtn
                    anchors.verticalCenter: parent.verticalCenter
                    height: 34
                    width: clearHistoryRow.implicitWidth + 22
                    radius: 14
                    color: clearHistMouse.containsMouse ? "#26ff453a" : "#14ffffff"
                    border.width: 1
                    border.color: clearHistMouse.containsMouse ? "#80ff453a" : "#20ffffff"

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Row {
                        id: clearHistoryRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf1f8"
                            font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                            font.pixelSize: 12
                            color: clearHistMouse.containsMouse ? "#ff453a" : "#98989d"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Clear"
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: clearHistMouse.containsMouse ? "#ff453a" : "#c7c7cc"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        id: clearHistMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearAllHistory()
                    }
                }

                // Close Button
                Rectangle {
                    id: closeBtn
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34
                    radius: 17
                    color: closeMouse.containsMouse ? "#28ffffff" : "#16ffffff"
                    border.width: 1
                    border.color: closeMouse.containsMouse ? "#44ffffff" : "#20ffffff"

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: closeMouse.containsMouse ? "#ffffff" : "#c7c7cc"
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }
        }

        // Empty State
        Item {
            id: emptyState
            anchors.top: topBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            visible: root.filteredItems.length === 0

            Text {
                anchors.centerIn: parent
                text: root.searchQuery === "" ? "Nessun elemento copiato" : "Nessun risultato trovato"
                color: "#8e8e93"
                font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }

        // Scrollable Masonry Cards Area
        Flickable {
            id: cardsFlickable
            anchors.top: topBar.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            contentWidth: width
            contentHeight: Math.max(leftColumn.implicitHeight, rightColumn.implicitHeight) + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: root.filteredItems.length > 0

            onContentYChanged: {
                if (contentY > 20 && root.renderLimit < root.filteredItems.length) {
                    deferredLoadTimer.stop();
                    root.renderLimit = root.filteredItems.length;
                    root.rebuildMasonryColumns();
                }
            }

            ScrollBar.vertical: ScrollBar {
                id: vbar
                active: cardsFlickable.moving || cardsFlickable.flicking
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 5
                    radius: 2.5
                    color: "#40ffffff"
                }
            }

            // 2-Column Masonry Flow (centered with safety margins to prevent hover clipping)
            Row {
                id: cardsRow
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 12
                spacing: 14

                // Left Column
                Column {
                    id: leftColumn
                    width: (cardsRow.width - cardsRow.spacing) / 2
                    spacing: 14

                    Repeater {
                        model: root.leftColumnItems
                        delegate: CardComponent {}
                    }
                }

                // Right Column
                Column {
                    id: rightColumn
                    width: (cardsRow.width - cardsRow.spacing) / 2
                    spacing: 14

                    Repeater {
                        model: root.rightColumnItems
                        delegate: CardComponent {}
                    }
                }
            }
        }
    }

    // Reusable Apple Intelligence / Siri Card Component
    component CardComponent: Item {
        id: cardWrapper
        required property var modelData
        required property int index

        readonly property bool isImage: modelData && modelData.type === "image"
        readonly property bool isCopied: String(modelData.id) === root.copiedItemId

        width: parent.width
        implicitHeight: isImage ? 210 : textCardHeight

        readonly property real textCardHeight: {
            if (isImage) return 210;
            if (modelData && modelData.is_url) return 134;
            const previewLen = (modelData.preview || "").length;
            if (previewLen > 80) return 142;
            if (previewLen < 25) return 96;
            return 120;
        }

        // Main Card Surface (ClippingRectangle ensures child images clip to rounded corners at the top)
        ClippingRectangle {
            id: cardSurface
            anchors.fill: parent
            anchors.leftMargin: 3
            anchors.rightMargin: 3
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            radius: 24
            clip: true
            color: cardMouse.containsMouse
                ? (StyleTokens.moduleHover || "#24ffffff")
                : (StyleTokens.module || "#14ffffff")
            border.width: cardMouse.containsMouse ? 1.5 : 1
            border.color: cardMouse.containsMouse
                ? root.accentColor
                : "#20ffffff"

            // Elevated Apple Intelligence lift on hover without horizontal boundary cut-off:
            transform: Translate {
                y: cardMouse.containsMouse ? -2 : (cardMouse.pressed ? 1 : 0)
                Behavior on y {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }
            scale: cardMouse.containsMouse ? 1.008 : (cardMouse.pressed ? 0.988 : 1.0)

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }

            // === IMAGE CARD LAYOUT ===
            Item {
                id: imageCardContainer
                anchors.fill: parent
                visible: cardWrapper.isImage

                // Image Thumbnail (fills card surface)
                Image {
                    id: thumbImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: cardWrapper.isImage && modelData.thumb ? `file://${modelData.thumb}` : ""
                    asynchronous: true
                    cache: true
                    smooth: true

                    // Placeholder background while loading
                    Rectangle {
                        anchors.fill: parent
                        color: "#1c1d22"
                        visible: thumbImage.status !== Image.Ready
                    }
                }

                // Time Badge (Frosted glass floating pill in upper right)
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 11
                    anchors.right: parent.right
                    anchors.rightMargin: 11
                    height: 22
                    width: timeBadgeRow.implicitWidth + 16
                    radius: 11
                    color: "#99000000"
                    border.width: 1
                    border.color: "#33ffffff"
                    z: 5

                    Row {
                        id: timeBadgeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.time || ""
                            color: "#ffffff"
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }

                // Image Type Badge (Frosted pill in upper left)
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 11
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    height: 22
                    width: imgTypeRow.implicitWidth + 14
                    radius: 11
                    color: "#99000000"
                    border.width: 1
                    border.color: "#33ffffff"
                    z: 5

                    Row {
                        id: imgTypeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf03e"
                            font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                            font.pixelSize: 11
                            color: "#f5f5f7"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Image"
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            font.pixelSize: 10
                            font.weight: Font.SemiBold
                            color: "#ffffff"
                        }
                    }
                }

                // Liquid glass bottom gradient overlay (rising from bottom to a few px above file name)
                Rectangle {
                    id: liquidGlassGradient
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: bottomInfoArea.height + 34
                    z: 6
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.25; color: "#440f1117" }
                        GradientStop { position: 0.60; color: "#bb0f1117" }
                        GradientStop { position: 1.0; color: "#f00f1117" }
                    }
                }

                // Bottom Label & Info Area (Sitting on the liquid glass gradient)
                Item {
                    id: bottomInfoArea
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    height: infoCol.implicitHeight
                    z: 7

                    Column {
                        id: infoCol
                        anchors.bottom: parent.bottom
                        width: parent.width
                        spacing: 2

                        Text {
                            width: parent.width
                            text: modelData.title || "Clipboard Image"
                            color: "#ffffff"
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            width: parent.width
                            text: modelData.preview || ""
                            color: "#c7c7cc"
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }
            }

            // === TEXT CARD LAYOUT ===
            Item {
                id: textCardContainer
                anchors.fill: parent
                visible: !cardWrapper.isImage
                anchors.margins: 14

                // Header Row (Icon pill on left, Timestamp pill on right)
                Item {
                    id: textHeaderRow
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 22

                    // Icon / Source pill (Shows Favicon & Origin for links like Cealestia)
                    Rectangle {
                        id: typeBadgePill
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: 22
                        width: Math.min(cardSurface.width - 100, textPillRow.implicitWidth + 14)
                        radius: 8
                        color: (modelData && modelData.is_url) ? "#2438bdf8" : "#1fffffff"
                        border.width: 1
                        border.color: (modelData && modelData.is_url) ? "#4538bdf8" : "#25ffffff"
                        clip: true

                        Row {
                            id: textPillRow
                            anchors.centerIn: parent
                            spacing: 6

                            // 1. Favicon for URLs
                            Image {
                                id: linkFavicon
                                width: 13
                                height: 13
                                anchors.verticalCenter: parent.verticalCenter
                                source: (modelData && modelData.is_url && modelData.favicon) ? ("file://" + modelData.favicon) : ""
                                fillMode: Image.PreserveAspectFit
                                visible: modelData && modelData.is_url && linkFavicon.status === Image.Ready
                                asynchronous: true
                                cache: true
                            }

                            // 2. Icon fallback / code / text icon
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !linkFavicon.visible
                                text: {
                                    if (modelData && modelData.is_url) return "\uf0ac"; // Globe
                                    const c = String(modelData ? modelData.content || "" : "");
                                    if (c.indexOf("quickshell") >= 0 || c.indexOf("sudo") >= 0 || c.indexOf("pacman") >= 0 || c.indexOf("git") >= 0) return "\uf120";
                                    return "\uf02d";
                                }
                                font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                                font.pixelSize: 11
                                color: (modelData && modelData.is_url) ? "#38bdf8" : "#e4e4e7"
                            }

                            // 3. Source Name / Origin (e.g. "YouTube", "GitHub", "Wikipedia")
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    if (modelData && modelData.is_url) {
                                        return modelData.source_name || modelData.domain || "Link";
                                    }
                                    const c = String(modelData ? modelData.content || "" : "");
                                    if (c.indexOf("quickshell") >= 0 || c.indexOf("sudo") >= 0) return "Code";
                                    return "Text";
                                }
                                font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                                font.pixelSize: 11
                                font.weight: Font.SemiBold
                                color: (modelData && modelData.is_url) ? "#38bdf8" : "#c7c7cc"
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }

                    // Timestamp Badge
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 20
                        width: textTime.implicitWidth + 14
                        radius: 10
                        color: "#18ffffff"
                        border.width: 1
                        border.color: "#20ffffff"

                        Text {
                            id: textTime
                            anchors.centerIn: parent
                            text: modelData.time || ""
                            color: "#98989d"
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }
                }

                // Bold snippet title & preview text body
                Column {
                    anchors.top: textHeaderRow.bottom
                    anchors.topMargin: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: 3

                    Text {
                        width: parent.width
                        text: modelData.title || modelData.content || ""
                        color: "#ffffff"
                        font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }

                    // Origin subtitle for URLs ("Da YouTube (www.youtube.com)")
                    Row {
                        width: parent.width
                        spacing: 5
                        visible: Boolean(modelData && modelData.is_url && modelData.domain)

                        Text {
                            text: "\uf0c1" // link icon
                            font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                            font.pixelSize: 10
                            color: "#38bdf8"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Da " + (modelData && modelData.source_name ? modelData.source_name + " (" + modelData.domain + ")" : (modelData ? modelData.domain : ""))
                            color: "#7dd3fc"
                            font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                            width: parent.width - 20
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        width: parent.width
                        text: modelData.preview || modelData.content || ""
                        color: "#a1a1a6"
                        font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        maximumLineCount: (modelData && modelData.is_url) ? 1 : (cardWrapper.textCardHeight > 120 ? 3 : 2)
                        wrapMode: Text.Wrap
                        lineHeight: 1.15
                    }
                }
            }

            // Hover Delete Button (Discreet Trash icon in corner when card is hovered)
            Rectangle {
                id: deleteCardBtn
                anchors.top: parent.top
                anchors.topMargin: cardWrapper.isImage ? 40 : 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                width: 24
                height: 24
                radius: 12
                color: deleteMouse.containsMouse ? "#ff453a" : "#55000000"
                border.width: 1
                border.color: deleteMouse.containsMouse ? "#ff453a" : "#40ffffff"
                opacity: cardMouse.containsMouse ? 1 : 0
                visible: opacity > 0
                z: 15

                Behavior on opacity { NumberAnimation { duration: 140 } }
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf1f8"
                    font.family: root.iconFontFamily !== "" ? root.iconFontFamily : "Sans Serif"
                    font.pixelSize: 11
                    color: "#ffffff"
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.deleteItem(modelData.id);
                    }
                }
            }

            // Swift Visual Feedback / Checkmark Overlay on Click
            Rectangle {
                id: copiedFeedback
                anchors.fill: parent
                radius: 24
                color: "#d9000000"
                opacity: cardWrapper.isCopied ? 1 : 0
                visible: opacity > 0
                z: 20

                Behavior on opacity {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutQuad
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    scale: cardWrapper.isCopied ? 1 : 0.8

                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutBack
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 14
                        color: "#34c759"

                        Text {
                            anchors.centerIn: parent
                            text: "✓"
                            color: "#ffffff"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Copied!"
                        color: "#ffffff"
                        font.family: root.textFontFamily !== "" ? root.textFontFamily : "Sans Serif"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }
            }

            // Card Click Handler
            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                z: 1

                onClicked: {
                    root.copyItem(modelData.id, modelData.title, modelData);
                }
            }
        }
    }
}
