import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Item {
    id: root

    property string buffer: ""
    property bool authenticating: passwd.active
    property bool isError: false
    property string errorMessage: ""
    property int failCount: 0
    property bool enabled: true

    signal authenticated()
    signal failed()

    function submitPassword(pwd): void {
        if (authenticating) return;
        if (pwd !== undefined) {
            buffer = pwd;
        }
        if (buffer.length === 0) {
            return;
        }
        isError = false;
        errorMessage = "";
        passwd.start();
    }

    function clear(): void {
        buffer = "";
        isError = false;
        errorMessage = "";
    }

    function appendChar(c: string): void {
        if (isError) {
            isError = false;
            errorMessage = "";
        }
        buffer += c;
    }

    function backspace(): void {
        if (isError) {
            isError = false;
            errorMessage = "";
        }
        if (buffer.length > 0) {
            buffer = buffer.slice(0, -1);
        }
    }

    PamContext {
        id: passwd

        config: "hyprlock"

        onResponseRequiredChanged: {
            if (!responseRequired) return;
            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: function(res) {
            if (res === PamResult.Success) {
                root.isError = false;
                root.errorMessage = "";
                root.failCount = 0;
                root.authenticated();
            } else {
                root.failCount++;
                root.isError = true;
                if (res === PamResult.MaxTries) {
                    root.errorMessage = "Numero massimo di tentativi raggiunto.";
                } else if (res === PamResult.Error) {
                    root.errorMessage = message || "Errore di autenticazione.";
                } else {
                    root.errorMessage = "Password non corretta. Riprova.";
                }
                root.failed();
                errorResetTimer.restart();
            }
        }
    }

    Timer {
        id: errorResetTimer
        interval: 3500
        repeat: false
        onTriggered: {
            root.isError = false;
            root.errorMessage = "";
        }
    }
}
