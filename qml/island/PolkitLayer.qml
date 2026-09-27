pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

FocusScope {
    id: root

    property var polkitAgent: null
    property color accentColor: "#0a84ff"
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string heroFontFamily: ""
    property bool showCondition: false

    signal closeRequested()
    signal polkitSuccessRequested()

    readonly property var flow: polkitAgent ? polkitAgent.flow : null
    readonly property string rawMessage: flow ? (flow.message || "") : ""
    readonly property string rawActionId: flow ? (flow.actionId || "") : ""
    readonly property string displayMessage: {
        if (rawMessage !== "") return rawMessage;
        if (rawActionId !== "") return rawActionId;
        return "Autenticazione richiesta";
    }
    readonly property string supplementaryMessage: flow ? (flow.supplementaryMessage || "") : ""
    readonly property bool flowFailed: flow ? !!flow.failed : false

    property string authState: "idle" // "idle", "verifying", "success", "failed"
    readonly property bool isFailed: authState === "failed" || flowFailed
    readonly property bool isVerifying: authState === "verifying"
    readonly property bool isSuccess: authState === "success"

    readonly property string faceIdMode: {
        if (isSuccess) return "success";
        if (isFailed) return "failed";
        if (isVerifying) return "verifying";
        return "idle";
    }

    // Biometric hardware detection and mode state
    property bool hasFingerprintSensor: false
    property bool hasFaceUnlock: false
    property string activeAuthMode: "password" // "face", "fingerprint", "password"
    property bool userChosePassword: false

    readonly property real preferredWidth: root.isSuccess ? 58 : 380
    readonly property real preferredHeight: {
        if (root.isSuccess) return 58;
        if (root.activeAuthMode === "face") return 310;
        if (root.hasBiometrics) return 186;
        return 160;
    }

    readonly property bool hasBiometrics: hasFingerprintSensor || hasFaceUnlock

    function resetAuthMode() {
        authState = "idle";
        passInput.enabled = true;
        passInput.text = "";
        userChosePassword = false;

        if (root.hasFaceUnlock) {
            activeAuthMode = "face";
        } else if (root.hasFingerprintSensor) {
            activeAuthMode = "fingerprint";
        } else {
            activeAuthMode = "password";
            userChosePassword = true;
        }
    }

    onHasFingerprintSensorChanged: {
        if (hasFingerprintSensor && !userChosePassword && !hasFaceUnlock) {
            activeAuthMode = "fingerprint";
        }
    }

    onHasFaceUnlockChanged: {
        if (hasFaceUnlock && !userChosePassword) {
            activeAuthMode = "face";
        }
    }


    anchors.fill: parent
    focus: showCondition
    activeFocusOnTab: true
    opacity: showCondition ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.showCondition ? 220 : 130
            easing.type: Easing.InOutQuad
        }
    }

    function grabKeyboardFocus() {
        forceActiveFocus();
        if (activeAuthMode === "password") {
            passInput.forceActiveFocus();
        }
    }

    function switchToFace() {
        activeAuthMode = "face";
        userChosePassword = false;
        authState = "idle";
    }

    function switchToFingerprint() {
        activeAuthMode = "fingerprint";
        userChosePassword = false;
        authState = "idle";
    }

    function switchToPassword() {
        activeAuthMode = "password";
        userChosePassword = true;
        authState = "idle";
        grabKeyboardFocus();
    }

    function triggerFingerprintTouch() {
        if (isVerifying || isSuccess) return;
        authState = "verifying";
        fingerprintSimTimer.restart();
    }

    Timer {
        id: fingerprintSimTimer
        interval: 500
        repeat: false
        onTriggered: {
            root.markSuccess();
        }
    }

    function triggerFaceIdScan() {
        if (isVerifying || isSuccess) return;
        authState = "verifying";
        faceSimTimer.restart();
    }


    Timer {
        id: faceSimTimer
        interval: 800
        repeat: false
        onTriggered: {
            root.markSuccess();
        }
    }

    function submitPassword() {
        if (!flow) return;
        if (passInput.text.length === 0) return;

        authState = "verifying";
        flow.submit(passInput.text);
    }

    function markSuccess() {
        authState = "success";
        passInput.enabled = false;
        root.polkitSuccessRequested();
        successDismissTimer.restart();
    }

    function cancelAuth() {
        if (flow) {
            flow.cancelAuthenticationRequest();
        }
        authState = "idle";
        passInput.text = "";
        root.closeRequested();
    }

    onShowConditionChanged: {
        if (showCondition) {
            resetAuthMode();
            focusDelayTimer.restart();
        } else {
            authState = "idle";
            passInput.enabled = true;
            passInput.text = "";
        }
    }

    onFlowFailedChanged: {
        if (flowFailed) {
            authState = "failed";
            passInput.enabled = true;
            shakeAnimation.restart();
            passInput.text = "";
            if (activeAuthMode === "password") {
                passInput.forceActiveFocus();
            }
        }
    }

    Component.onCompleted: {
        resetAuthMode();
        root.grabKeyboardFocus();
    }

    Timer {
        id: focusDelayTimer
        interval: 60
        repeat: false
        onTriggered: root.grabKeyboardFocus()
    }

    Timer {
        id: successDismissTimer
        interval: 1150
        repeat: false
        onTriggered: {
            authState = "idle";
            passInput.enabled = true;
            passInput.text = "";
            root.closeRequested();
        }
    }

    Timer {
        id: demoVerifyTimer
        interval: 650
        repeat: false
        onTriggered: {
            root.markSuccess();
        }
    }

    function simulateDemoSuccess() {
        activeAuthMode = "password";
        passInput.text = "password123";
        authState = "verifying";
        demoVerifyTimer.restart();
    }

    function simulateFaceSuccess() {
        activeAuthMode = "face";
        userChosePassword = false;
        authState = "verifying";
        demoVerifyTimer.restart();
    }

    function simulateFingerprintSuccess() {
        activeAuthMode = "fingerprint";
        userChosePassword = false;
        authState = "verifying";
        demoVerifyTimer.restart();
    }

    // Top Right Cancel / Close Button
    Rectangle {
        id: closeBtn
        width: 24
        height: 24
        radius: 12
        anchors.top: parent.top
        anchors.topMargin: 9
        anchors.right: parent.right
        anchors.rightMargin: 11
        z: 10
        color: closeMouse.containsMouse ? "#3a3a3c" : "#242428"
        opacity: root.isSuccess ? 0 : 1
        visible: !root.isSuccess

        Behavior on opacity { NumberAnimation { duration: 60 } }
        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
            anchors.centerIn: parent
            text: "\uf00d"
            font.family: root.iconFontFamily
            font.pixelSize: 11
            color: closeMouse.containsMouse ? "#ffffff" : "#8e8e93"
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cancelAuth()
        }
    }

    // Top Section: Face ID Animated Glyph (Positioned directly under webcam notch)
    FaceIdGlyph {
        id: faceIdIcon
        size: 42
        z: 5
        visible: root.activeAuthMode === "face"
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.isSuccess ? Math.round(parent.height / 2 - height / 2) : 10
        glyphColor: "#ffffff"
        bracketColor: root.accentColor
        stateMode: root.activeAuthMode === "face" ? root.faceIdMode : "idle"

        Behavior on y {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutQuint
            }
        }
    }

    // Top Section: Touch ID Animated Fingerprint Glyph (Round Biometric Sensor)
    FingerprintGlyph {
        id: fingerprintIcon
        size: 56
        z: 5
        visible: root.activeAuthMode === "fingerprint"
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.isSuccess ? Math.round(parent.height / 2 - height / 2) : 14
        glyphColor: "#ffffff"
        accentColor: root.accentColor
        iconFontFamily: root.iconFontFamily
        stateMode: root.activeAuthMode === "fingerprint" ? root.faceIdMode : "idle"
        onClicked: root.triggerFingerprintTouch()

        Behavior on y {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutQuint
            }
        }
    }

    Column {
        id: formColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: {
            if (root.activeAuthMode === "face") return 54;
            if (root.activeAuthMode === "fingerprint") return 78;
            if (root.hasBiometrics) return 42;
            return 28;
        }
        anchors.bottomMargin: 8
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 6
        opacity: root.isSuccess ? 0 : 1
        visible: !root.isSuccess

        Behavior on opacity {
            NumberAnimation {
                duration: 60
                easing.type: Easing.OutQuad
            }
        }

        // Title and Subtitle Text
        Column {
            width: parent.width
            spacing: 2

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (root.isSuccess) {
                        if (root.activeAuthMode === "face") return "Autenticato con Face ID";
                        if (root.activeAuthMode === "fingerprint") return "Touch ID Confermato";
                        return "Accesso Consentito";
                    }
                    if (root.isFailed) {
                        if (root.activeAuthMode === "face") return "Viso non riconosciuto";
                        if (root.activeAuthMode === "fingerprint") return "Impronta non riconosciuta";
                        return (root.supplementaryMessage !== "" ? root.supplementaryMessage : "Password errata. Riprova.");
                    }
                    if (root.isVerifying) {
                        if (root.activeAuthMode === "face") return "Riconoscimento facciale...";
                        if (root.activeAuthMode === "fingerprint") return "Verifica impronta in corso...";
                        return "Verifica autorizzazione...";
                    }
                    if (root.activeAuthMode === "face") {
                        return "Face ID (Windows Hello)";
                    }
                    if (root.activeAuthMode === "fingerprint") {
                        return "Touch ID (Telefono)";
                    }
                    return root.displayMessage;
                }
                color: root.isFailed
                    ? "#ff453a"
                    : (root.isSuccess ? "#30d158" : "#f5f5f7")
                font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (root.isSuccess) return "Accesso consentito";
                    if (root.isFailed) {
                        if (root.activeAuthMode === "face") return "Posizionati davanti alla fotocamera o usa la password";
                        if (root.activeAuthMode === "fingerprint") return "Poggia nuovamente il dito sul sensore";
                        return "Riprova con la password corretta";
                    }
                    if (root.isVerifying) {
                        if (root.activeAuthMode === "face") return "Scansione del volto...";
                        if (root.activeAuthMode === "fingerprint") return "Scansione dell'impronta...";
                        return "Controllo credenziali...";
                    }
                    if (root.activeAuthMode === "face") {
                        return "Posizionati davanti alla fotocamera";
                    }
                    if (root.activeAuthMode === "fingerprint") {
                        return "Poggia il dito per sbloccare";
                    }
                    return "Inserisci la password";
                }
                color: root.isFailed ? "#ff6961" : (root.isSuccess ? "#30d158" : "#98989f")
                font.family: root.textFontFamily
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        // Face Camera Live Viewfinder Box ("quadratino nella quale mostra la cam che userà il portatile")
        FaceCameraBox {
            id: faceCameraPreview
            visible: root.activeAuthMode === "face" && !root.isSuccess
            anchors.horizontalCenter: parent.horizontalCenter
            width: 136
            height: 136
            active: root.showCondition && root.activeAuthMode === "face" && !root.isSuccess
            isSuccess: root.isSuccess
            isFailed: root.isFailed
            accentColor: root.accentColor
            iconFontFamily: root.iconFontFamily
            textFontFamily: root.textFontFamily
            onClicked: root.triggerFaceIdScan()
        }

        // 2. Password Input Pill (Shown when password mode is active)
        Item {
            id: inputWrapper
            visible: root.activeAuthMode === "password"
            width: parent.width
            height: 40

            Rectangle {
                id: inputContainer
                anchors.fill: parent
                radius: 13
                color: "#16181e"
                border.width: (passInput.activeFocus || root.isSuccess) ? 1.5 : 1
                border.color: root.isFailed
                    ? "#ff453a"
                    : (root.isSuccess ? "#30d158" : (passInput.activeFocus ? root.accentColor : "#2a2d37"))

                Behavior on border.color { ColorAnimation { duration: 180 } }

                SequentialAnimation {
                    id: shakeAnimation
                    NumberAnimation { target: inputContainer; property: "x"; from: 0; to: -10; duration: 40; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputContainer; property: "x"; from: -10; to: 10; duration: 40; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputContainer; property: "x"; from: 10; to: -6; duration: 40; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputContainer; property: "x"; from: -6; to: 6; duration: 40; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: inputContainer; property: "x"; from: 6; to: 0; duration: 40; easing.type: Easing.InOutQuad }
                }

                // Key Icon
                Text {
                    id: keyIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 13
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isSuccess ? "\uf00c" : "\uf084"
                    font.family: root.iconFontFamily
                    font.pixelSize: 14
                    color: root.isSuccess
                        ? "#30d158"
                        : (passInput.activeFocus ? root.accentColor : "#636366")
                }

                // Password TextInput
                TextInput {
                    id: passInput
                    anchors.left: keyIcon.right
                    anchors.leftMargin: 10
                    anchors.right: submitBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#ffffff"
                    selectionColor: root.accentColor
                    selectedTextColor: "#ffffff"
                    font.family: root.textFontFamily
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    echoMode: (root.flow && root.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    clip: true
                    selectByMouse: true
                    cursorVisible: activeFocus && !root.isSuccess
                    focus: true

                    Keys.onEscapePressed: event => {
                        root.cancelAuth();
                        event.accepted = true;
                    }

                    Keys.onReturnPressed: event => {
                        root.submitPassword();
                        event.accepted = true;
                    }

                    Keys.onEnterPressed: event => {
                        root.submitPassword();
                        event.accepted = true;
                    }
                }

                // Placeholder Text
                Text {
                    anchors.left: passInput.left
                    anchors.verticalCenter: passInput.verticalCenter
                    text: "Password amministratore..."
                    color: "#636366"
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    visible: passInput.text === "" && !passInput.inputMethodComposing && !root.isSuccess
                }

                // Submit Button / Spinner
                Rectangle {
                    id: submitBtn
                    width: 30
                    height: 30
                    radius: 9
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.isSuccess
                        ? "#30d158"
                        : (root.isVerifying
                            ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3)
                            : (passInput.text.length > 0 ? root.accentColor : "#252830"))

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: root.isSuccess ? "\uf00c" : (root.isVerifying ? "\uf110" : "\uf061")
                        font.family: root.iconFontFamily
                        font.pixelSize: 13
                        color: (root.isSuccess || root.isVerifying || passInput.text.length > 0) ? "#ffffff" : "#636366"

                        RotationAnimator on rotation {
                            running: root.isVerifying
                            from: 0
                            to: 360
                            loops: Animation.Infinite
                            duration: 900
                        }
                    }

                    MouseArea {
                        id: submitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: (passInput.text.length > 0 && !root.isVerifying && !root.isSuccess) ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (!root.isVerifying && !root.isSuccess)
                                root.submitPassword();
                        }
                    }
                }
            }
        }

        // 3. Apple-style Biometric & Password Switcher Pills
        Item {
            width: parent.width
            height: 26
            visible: root.hasBiometrics

            Row {
                anchors.centerIn: parent
                spacing: 8

                // Switch to Face ID pill
                Rectangle {
                    visible: root.hasFaceUnlock && root.activeAuthMode !== "face"
                    height: 26
                    width: facePillRow.width + 20
                    radius: 13
                    color: faceMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1
                    border.color: faceMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4) : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        id: facePillRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf2bd"
                            font.family: root.iconFontFamily
                            font.pixelSize: 12
                            color: faceMouse.containsMouse ? root.accentColor : "#98989f"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Usa Face ID"
                            font.family: root.textFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: faceMouse.containsMouse ? "#ffffff" : "#c7c7cc"
                        }
                    }

                    MouseArea {
                        id: faceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchToFace()
                    }
                }

                // Switch to Touch ID pill
                Rectangle {
                    visible: root.hasFingerprintSensor && root.activeAuthMode !== "fingerprint"
                    height: 26
                    width: fpPillRow.width + 20
                    radius: 13
                    color: fpMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1
                    border.color: fpMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4) : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        id: fpPillRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\udb80\ude37"
                            font.family: root.iconFontFamily
                            font.pixelSize: 12
                            color: fpMouse.containsMouse ? root.accentColor : "#98989f"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Usa Touch ID"
                            font.family: root.textFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: fpMouse.containsMouse ? "#ffffff" : "#c7c7cc"
                        }
                    }

                    MouseArea {
                        id: fpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchToFingerprint()
                    }
                }

                // Switch to Password pill
                Rectangle {
                    visible: root.activeAuthMode !== "password"
                    height: 26
                    width: passPillRow.width + 20
                    radius: 13
                    color: passPillMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                    border.width: 1
                    border.color: passPillMouse.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4) : Qt.rgba(255, 255, 255, 0.08)

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Row {
                        id: passPillRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf084"
                            font.family: root.iconFontFamily
                            font.pixelSize: 12
                            color: passPillMouse.containsMouse ? root.accentColor : "#98989f"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Usa Password"
                            font.family: root.textFontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: passPillMouse.containsMouse ? "#ffffff" : "#c7c7cc"
                        }
                    }

                    MouseArea {
                        id: passPillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.switchToPassword()
                    }
                }
            }
        }
    }
}
