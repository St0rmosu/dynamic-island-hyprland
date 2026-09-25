import QtQuick
import IslandBackend

Item {
    id: root

    visible: false
    width: 0
    height: 0

    signal wifiDisconnected(string ssid)

    readonly property var controller: WifiController
    readonly property string currentSsid: controller ? controller.currentSsid : ""
    readonly property bool wifiEnabled: controller ? controller.enabled : false
    readonly property bool wifiAvailable: controller ? controller.available : false

    property string lastKnownSsid: ""
    property string pendingDisconnectedSsid: ""
    property bool initialized: false

    // Initial startup delay: avoid alerting on boot or shell reload before backend connects
    Timer {
        id: startupTimer
        interval: 1500
        running: true
        repeat: false
        onTriggered: {
            if (root.currentSsid !== "") {
                root.lastKnownSsid = root.currentSsid;
            }
            root.initialized = true;
        }
    }

    // Debounce timer: wait 3500ms after disconnection before alerting.
    // If the network re-establishes or switches within 3500ms, cancel the alert.
    Timer {
        id: disconnectDebounceTimer
        interval: 3500
        repeat: false
        onTriggered: {
            const isConnected = root.currentSsid !== "" && root.wifiEnabled && root.wifiAvailable;
            if (root.initialized && !isConnected && root.pendingDisconnectedSsid !== "") {
                const disconnectedNetwork = root.pendingDisconnectedSsid;
                root.pendingDisconnectedSsid = "";
                root.wifiDisconnected(disconnectedNetwork);
            } else {
                root.pendingDisconnectedSsid = "";
            }
        }
    }

    Connections {
        target: root.controller

        function onCurrentSsidChanged() {
            root.evaluateState();
        }

        function onEnabledChanged() {
            root.evaluateState();
        }

        function onAvailableChanged() {
            root.evaluateState();
        }
    }

    function evaluateState() {
        const ssid = root.currentSsid;
        const isConnected = ssid !== "" && root.wifiEnabled && root.wifiAvailable;

        if (isConnected) {
            // Cancel any pending disconnect alert if reconnected quickly or switched networks
            if (disconnectDebounceTimer.running) {
                disconnectDebounceTimer.stop();
                root.pendingDisconnectedSsid = "";
            }
            root.lastKnownSsid = ssid;
            if (!root.initialized) {
                root.initialized = true;
            }
        } else {
            // Disconnected or Wi-Fi turned off
            if (root.initialized && root.lastKnownSsid !== "") {
                root.pendingDisconnectedSsid = root.lastKnownSsid;
                root.lastKnownSsid = "";
                disconnectDebounceTimer.restart();
            }
        }
    }

    Component.onCompleted: {
        if (currentSsid !== "" && wifiEnabled && wifiAvailable) {
            lastKnownSsid = currentSsid;
            initialized = true;
        }
    }
}
