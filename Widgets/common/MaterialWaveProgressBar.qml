import QtQuick

Item {
    id: root

    required property real progress
    required property color waveColor

    property color trackColor: waveColor
    property real trackOpacity: 0.3
    property bool isPlaying: false

    property real lineWidth: 6
    property real lineRadius: lineWidth / 2
    property real gap: 4
    property real waveFrequency: 0.12
    property real waveAmplitude: 2.5
    property real step: 2
    property real seekMargin: 12
    property int phaseDuration: 1200
    property int smoothingDuration: 1500
    property real smoothingVelocity: 200

    readonly property bool pressed: seekMa.pressed
    readonly property real visualX: waveContainer.playheadX

    signal seekRequested(real position)

    implicitHeight: 26

    Item {
        id: waveContainer
        anchors.fill: parent

        property real targetPlayhead: seekMa.pressed ? Math.max(0, Math.min(seekMa.mouseX, width)) : (root.progress * width)
        property real playheadX: targetPlayhead
        property real wavePhase: 0

        Behavior on playheadX {
            enabled: root.visible && !seekMa.pressed
            SmoothedAnimation {
                velocity: root.smoothingVelocity
                duration: root.smoothingDuration
                reversingMode: SmoothedAnimation.Sync
            }
        }

        NumberAnimation on wavePhase {
            from: 0
            to: Math.PI * 2
            duration: root.phaseDuration
            loops: Animation.Infinite
            running: root.isPlaying
        }

        onWavePhaseChanged: fgWave.requestPaint()
        onPlayheadXChanged: fgWave.requestPaint()
        onWidthChanged: fgWave.requestPaint()
        onHeightChanged: fgWave.requestPaint()

        Rectangle {
            height: root.lineWidth
            radius: root.lineRadius
            color: root.trackColor
            opacity: root.trackOpacity
            x: Math.min(parent.width, waveContainer.playheadX + root.gap)
            width: Math.max(0, parent.width - x)
            anchors.verticalCenter: parent.verticalCenter
        }

        Canvas {
            id: fgWave
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                let endX = waveContainer.playheadX - (root.gap + root.lineWidth / 2);
                let padding = root.lineWidth / 2;

                if (endX <= padding)
                    return;

                ctx.beginPath();
                ctx.lineWidth = root.lineWidth;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.strokeStyle = String(root.waveColor);

                for (let x = padding; x <= endX; x += root.step) {
                    let y = height / 2 + Math.sin((x - padding) * root.waveFrequency + waveContainer.wavePhase) * root.waveAmplitude;
                    if (x === padding)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();
            }

            Connections {
                target: root
                function onWaveColorChanged() { fgWave.requestPaint() }
                function onLineWidthChanged() { fgWave.requestPaint() }
                function onGapChanged() { fgWave.requestPaint() }
                function onWaveFrequencyChanged() { fgWave.requestPaint() }
                function onWaveAmplitudeChanged() { fgWave.requestPaint() }
            }
        }

        MouseArea {
            id: seekMa
            anchors.fill: parent
            anchors.margins: -root.seekMargin
            cursorShape: Qt.PointingHandCursor

            onReleased: (mouse) => {
                let clampedX = Math.max(0, Math.min(mouse.x, waveContainer.width));
                root.seekRequested(clampedX / waveContainer.width);
            }
        }
    }
}
