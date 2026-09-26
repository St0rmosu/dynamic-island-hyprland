import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property var rootLayer: null

    readonly property bool hasTrayApps: SystemTray.items && SystemTray.items.values ? SystemTray.items.values.length > 0 : false

    visible: hasTrayApps
    implicitHeight: 34
    implicitWidth: dockPill.width

    property var activeMenuHandle: null
    property point activeMenuPos: Qt.point(0, 0)
    property bool menuVisible: false

    function openMenu(menuHandle, originItem) {
        if (!menuHandle) return;
        if (root.menuVisible && root.activeMenuHandle === menuHandle) {
            root.menuVisible = false;
            return;
        }
        var targetContainer = root.rootLayer || root;
        var p = originItem.mapToItem(targetContainer, 0, 0);
        root.activeMenuPos = Qt.point(p.x + originItem.width / 2, p.y);
        root.activeMenuHandle = menuHandle;
        root.menuVisible = true;
    }

    function closeMenu() {
        root.menuVisible = false;
        root.activeMenuHandle = null;
    }

    // ── Floating Dock Capsule ──────────────────────────────────────────
    Rectangle {
        id: dockPill
        anchors.centerIn: parent
        height: 32
        width: trayRow.implicitWidth + 16
        radius: 16
        color: Qt.rgba(14/255, 17/255, 24/255, 0.85)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.10)

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Row {
            id: trayRow
            anchors.centerIn: parent
            spacing: 6

            // Piccolo indicatore di stato
            Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: root.accentColor
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0.8
            }

            Repeater {
                model: SystemTray.items

                Item {
                    id: trayChipItem
                    width: chipContentRow.implicitWidth + 14
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: chipMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1
                        border.color: chipMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(255, 255, 255, 0.08)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            id: chipContentRow
                            anchors.centerIn: parent
                            spacing: 5

                            Image {
                                id: trayIconImg
                                width: 16
                                height: 16
                                source: modelData.icon || ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                                visible: status === Image.Ready
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Fallback lettera se icona non caricabile
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !trayIconImg.visible
                                text: (modelData.title && modelData.title.length > 0) ? modelData.title.charAt(0).toUpperCase() : "\uf013"
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.family: root.textFontFamily
                                font.weight: Font.Bold
                            }

                            // Nome dell'app (se ci sono 3 o meno app)
                            Text {
                                visible: SystemTray.items.values.length <= 3 && modelData.title && modelData.title.length > 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                color: chipMouse.containsMouse ? "#ffffff" : "#c2c7d4"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                font.family: root.textFontFamily
                            }
                        }

                        // Pallino di notifica / attenzione (es. messaggi Discord non letti)
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 1
                            anchors.rightMargin: 1
                            color: "#30d158"
                            border.width: 1
                            border.color: "#0c0e14"
                            visible: {
                                try {
                                    return modelData.status === SystemTrayItemStatus.NeedsAttention ||
                                           modelData.status === "NeedsAttention" ||
                                           modelData.attention;
                                } catch(e) {
                                    return false;
                                }
                            }

                            SequentialAnimation on opacity {
                                running: parent.visible
                                loops: Animation.Infinite
                                PropertyAnimation { from: 1.0; to: 0.4; duration: 500 }
                                PropertyAnimation { from: 0.4; to: 1.0; duration: 500 }
                            }
                        }
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                if (modelData.hasMenu && modelData.menu) {
                                    root.openMenu(modelData.menu, trayChipItem);
                                } else {
                                    modelData.secondaryActivate();
                                }
                            } else if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate();
                            } else {
                                if (modelData.onlyMenu && modelData.hasMenu && modelData.menu) {
                                    root.openMenu(modelData.menu, trayChipItem);
                                } else {
                                    modelData.activate();
                                }
                            }
                        }

                        onWheel: function(wheel) {
                            modelData.scroll(wheel.angleDelta.y, false);
                        }
                    }

                    // Tooltip al passaggio del mouse
                    Rectangle {
                        id: chipTooltip
                        visible: chipMouse.containsMouse && !root.menuVisible && tooltipText.text.length > 0
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: tooltipText.implicitWidth + 14
                        height: 22
                        radius: 5
                        color: "#080a10"
                        border.width: 1
                        border.color: Qt.rgba(255, 255, 255, 0.15)
                        z: 999

                        Text {
                            id: tooltipText
                            anchors.centerIn: parent
                            text: (modelData.tooltip && modelData.tooltip.trim().length > 0) ? modelData.tooltip : (modelData.title || "")
                            color: "#f2f4f8"
                            font.pixelSize: 10
                            font.family: root.textFontFamily
                        }
                    }
                }
            }
        }
    }

    // ── Overlay e Menu Contestuale che si apre VERSO L'ALTO (UPWARDS) ──
    QsMenuOpener {
        id: trayMenuOpener
        menu: root.activeMenuHandle
    }

    // Transparent dismissal overlay
    MouseArea {
        id: menuDismissOverlay
        parent: root.rootLayer || root
        anchors.fill: parent
        visible: root.menuVisible
        z: 9998
        onClicked: root.closeMenu()
    }

    Rectangle {
        id: trayMenuPopup
        parent: root.rootLayer || root
        visible: root.menuVisible
        z: 9999

        width: Math.max(160, menuCol.implicitWidth + 16)
        height: menuCol.implicitHeight + 12
        radius: 10
        color: "#0d1017"
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.14)

        // Posizionamento verso l'alto (UPWARDS) sopra il chip cliccato
        x: {
            var targetW = (root.rootLayer ? root.rootLayer.width : root.width);
            return Math.max(12, Math.min(targetW - width - 12, root.activeMenuPos.x - width / 2));
        }
        y: Math.max(12, root.activeMenuPos.y - height - 8)

        opacity: root.menuVisible ? 1.0 : 0.0
        scale: root.menuVisible ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

        Column {
            id: menuCol
            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: trayMenuOpener.children

                Item {
                    width: Math.max(144, entryRow.implicitWidth + 20)
                    height: modelData.isSeparator ? 7 : 26

                    // Separatore
                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 6
                        height: 1
                        color: Qt.rgba(255, 255, 255, 0.08)
                    }

                    // Riga Elemento Menu
                    Rectangle {
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        radius: 6
                        color: entryMouse.containsMouse && modelData.enabled ? Qt.rgba(255, 255, 255, 0.12) : "transparent"

                        Row {
                            id: entryRow
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Image {
                                visible: modelData.icon !== ""
                                width: 14
                                height: 14
                                source: modelData.icon || ""
                                fillMode: Image.PreserveAspectFit
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData.text || ""
                                color: modelData.enabled ? "#f2f4f8" : "#606877"
                                font.pixelSize: 11
                                font.family: root.textFontFamily
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: entryMouse
                            anchors.fill: parent
                            hoverEnabled: modelData.enabled
                            cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (modelData.enabled) {
                                    root.closeMenu();
                                    modelData.triggered();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
