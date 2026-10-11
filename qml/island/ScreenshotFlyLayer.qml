import QtQuick

Item {
    id: root

    enabled: false
    visible: root.isFlying

    property string imagePath: ""
    property color accentColor: "#bdb6a6"

    property real startX: 0
    property real startY: 0
    property real startW: 100
    property real startH: 100

    property real destX: 0
    property real destY: 0
    property real destW: 100
    property real destH: 100

    property real currentX: startX
    property real currentY: startY
    property real currentW: startW
    property real currentH: startH
    property real currentRadius: 8
    property real currentOpacity: 0.0
    property real currentRotation: 0.0
    property real flyTiltAngle: 0.0
    property bool isFlying: false

    property var pendingCallback: null

    signal animationFinished()

    Timer {
        id: flyTimeout
        interval: 500
        repeat: false
        running: root.isFlying
        onTriggered: {
            if (root.isFlying) {
                if (root.pendingCallback) {
                    const cb = root.pendingCallback;
                    root.pendingCallback = null;
                    cb();
                }
                root.isFlying = false;
                root.animationFinished();
            }
        }
    }

    function refreshImage(filePath) {
        if (filePath && filePath !== "") {
            imagePath = filePath;
        }
        flyImg.source = "";
        if (imagePath !== "") {
            flyImg.source = "file://" + imagePath;
        }
    }

    function startFlight(filePath, rx, ry, rw, rh, targetX, targetY, targetW, targetH, onLandCallback) {
        imagePath = filePath;
        startX = rx;
        startY = ry;
        startW = Math.max(16, rw);
        startH = Math.max(16, rh);

        currentX = rx;
        currentY = ry;
        currentW = startW;
        currentH = startH;

        destX = targetX;
        destY = targetY;
        destW = Math.max(16, targetW);
        destH = Math.max(16, targetH);

        const deltaX = targetX - rx;
        flyTiltAngle = Math.max(-2.5, Math.min(2.5, deltaX / 250));
        currentRotation = 0;

        currentRadius = 8;
        currentOpacity = 1.0;
        pendingCallback = onLandCallback;
        isFlying = true;

        flashAnim.restart();
        flyAnim.restart();
    }

    ParallelAnimation {
        id: flyAnim
        running: false

        // Curva parabolica naturale: X con InOutCubic e Y con OutCubic crea un arco morbido
        NumberAnimation {
            target: root
            property: "currentX"
            from: root.startX
            to: root.destX
            duration: 290
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            target: root
            property: "currentY"
            from: root.startY
            to: root.destY
            duration: 290
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "currentW"
            from: root.startW
            to: root.destW
            duration: 290
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "currentH"
            from: root.startH
            to: root.destH
            duration: 290
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "currentRadius"
            from: 8
            to: 10
            duration: 290
            easing.type: Easing.OutCubic
        }

        // Leggera inclinazione dinamica verso la direzione del moto
        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "currentRotation"
                from: 0
                to: root.flyTiltAngle
                duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "currentRotation"
                from: root.flyTiltAngle
                to: 0
                duration: 190
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation {
            PauseAnimation { duration: 250 }
            ScriptAction {
                script: {
                    if (root.pendingCallback) {
                        const cb = root.pendingCallback;
                        root.pendingCallback = null;
                        cb();
                    }
                }
            }
            NumberAnimation {
                target: root
                property: "currentOpacity"
                from: 1.0
                to: 0.0
                duration: 40
                easing.type: Easing.OutQuad
            }
        }

        onFinished: {
            root.isFlying = false;
            root.animationFinished();
        }
    }

    // Ombra morbida di profondità per dare consistenza fisica alla scheda in volo
    Rectangle {
        id: flyCardShadow
        visible: root.isFlying && root.currentOpacity > 0.05
        z: 1
        x: root.currentX - 4
        y: root.currentY - 1
        width: Math.max(8, root.currentW) + 8
        height: Math.max(8, root.currentH) + 8
        radius: root.currentRadius + 4
        color: Qt.rgba(0, 0, 0, 0.40 * root.currentOpacity)
        rotation: root.currentRotation
        transformOrigin: Item.Center
    }

    Rectangle {
        id: flyCard
        visible: root.isFlying && root.currentOpacity > 0.01
        z: 2
        x: root.currentX
        y: root.currentY
        width: Math.max(8, root.currentW)
        height: Math.max(8, root.currentH)
        radius: root.currentRadius
        opacity: root.currentOpacity
        color: Qt.rgba(0, 0, 0, 0.75)
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.12)
        rotation: root.currentRotation
        transformOrigin: Item.Center
        clip: true

        Image {
            id: flyImg
            anchors.fill: parent
            anchors.margins: 4
            source: root.imagePath !== "" ? ("file://" + root.imagePath) : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            cache: false
            asynchronous: false
        }

        // Effetto Flash scatto fotocamera
        Rectangle {
            id: shutterFlash
            anchors.fill: parent
            color: "#ffffff"
            opacity: 0.0

            NumberAnimation {
                id: flashAnim
                target: shutterFlash
                property: "opacity"
                from: 0.35
                to: 0.0
                duration: 90
                easing.type: Easing.OutQuad
                running: false
            }
        }
    }
}
