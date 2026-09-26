pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

FocusScope {
    id: root

    property var polkitAgent: null
    property color accentColor: "#0a84ff"
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string heroFontFamily: ""
    property bool showCondition: false

    signal closeRequested()

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
        passInput.forceActiveFocus();
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
            authState = "idle";
            passInput.enabled = true;
            passInput.text = "";
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
            passInput.forceActiveFocus();
        }
    }

    Component.onCompleted: root.grabKeyboardFocus()

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
        passInput.text = "password123";
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

    // Top Section: Face ID Animated Glyph (centers perfectly in the circle on success)
    FaceIdGlyph {
        id: faceIdIcon
        size: 48
        z: 5
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.isSuccess ? Math.round(parent.height / 2 - height / 2) : 10
        glyphColor: "#ffffff"
        bracketColor: root.accentColor
        stateMode: root.faceIdMode

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
        anchors.topMargin: 66
        anchors.bottomMargin: 12
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
                    if (root.isSuccess) return "Autenticato con Face ID";
                    if (root.isFailed) {
                        return root.supplementaryMessage !== ""
                            ? root.supplementaryMessage
                            : "Password errata. Riprova.";
                    }
                    if (root.isVerifying) return "Verifica autorizzazione...";
                    return root.displayMessage;
                }
                color: root.isFailed
                    ? "#ff453a"
                    : (root.isSuccess ? "#30d158" : "#f5f5f7")
                font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.isSuccess
                    ? "Accesso consentito"
                    : (root.isFailed ? "Riprova con la password corretta" : "Inserisci la password")
                color: root.isFailed ? "#ff6961" : (root.isSuccess ? "#30d158" : "#98989f")
                font.family: root.textFontFamily
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }

        // Password Input Pill
        Item {
            id: inputWrapper
            width: parent.width
            height: 42

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
    }
}
