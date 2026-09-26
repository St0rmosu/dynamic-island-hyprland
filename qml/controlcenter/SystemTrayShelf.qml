import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property color accentColor: "#0a84ff"
    property string textFontFamily: "Google Sans Flex"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    implicitHeight: 28
    implicitWidth: trayRow.implicitWidth

    visible: SystemTray.items && SystemTray.items.values ? SystemTray.items.values.length > 0 : false

    property var activeMenuHandle: null
    property point activeMenuPos: Qt.point(0, 0)
    property bool menuVisible: false

    function openMenu(menuHandle, originItem) {
        if (!menuHandle) return;
        if (root.menuVisible && root.activeMenuHandle === menuHandle) {
            root.menuVisible = false;
            return;
        }
        var p = originItem.mapToItem(root, 0, originItem.height + 6);
        root.activeMenuPos = p;
        root.activeMenuHandle = menuHandle;
        root.menuVisible = true;
    }

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            Item {
                id: trayChipItem
                width: 26
                height: 26

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: chipMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.07)
                    border.width: 1
                    border.color: chipMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Image {
                        id: trayIconImg
                        anchors.centerIn: parent
                        width: 17
                        height: 17
                        source: modelData.icon || ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        visible: status === Image.Ready
                    }

                    // Fallback se l'icona non è un'immagine valida
                    Text {
                        anchors.centerIn: parent
                        visible: !trayIconImg.visible
                        text: (modelData.title && modelData.title.length > 0) ? modelData.title.charAt(0).toUpperCase() : "\uf013"
                        color: "#ffffff"
                        font.pixelSize: 11
                        font.family: root.textFontFamily
                        font.weight: Font.Bold
                    }

                    // Pallino di notifica / attenzione (es. messaggi Discord non letti)
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 2
                        anchors.rightMargin: 2
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
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tooltipText.implicitWidth + 14
                    height: 20
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

    // ── Menu Contestuale della Tray (QsMenuOpener) ───────────────────
    QsMenuOpener {
        id: trayMenuOpener
        menu: root.activeMenuHandle
    }

    Rectangle {
        id: trayMenuPopup
        visible: root.menuVisible
        x: Math.max(0, Math.min(root.width - width, root.activeMenuPos.x - width / 2))
        y: root.activeMenuPos.y
        z: 1000

        width: Math.max(160, menuCol.implicitWidth + 16)
        height: menuCol.implicitHeight + 12
        radius: 10
        color: "#0d1017"
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.12)

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
                        color: entryMouse.containsMouse && modelData.enabled ? Qt.rgba(255, 255, 255, 0.10) : "transparent"

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
                                    root.menuVisible = false;
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
