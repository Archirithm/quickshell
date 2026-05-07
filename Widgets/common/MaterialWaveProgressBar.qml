import QtQuick
import QtQuick.Shapes

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
    property real step: 8
    property real endDotSize: Math.max(3, lineWidth * 0.55)
    property color endDotColor: waveColor
    property real endDotOpacity: 1.0
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
        property real centerY: height / 2
        property real waveEndX: Math.max(root.lineWidth / 2, playheadX - (root.gap + root.lineWidth / 2))
        property string wavePath: buildWavePath()

        function waveY(x) {
            return centerY + Math.sin((x - root.lineWidth / 2) * root.waveFrequency + wavePhase) * root.waveAmplitude;
        }

        function waveSlope(x) {
            return Math.cos((x - root.lineWidth / 2) * root.waveFrequency + wavePhase) * root.waveAmplitude * root.waveFrequency;
        }

        function buildWavePath() {
            const padding = root.lineWidth / 2;
            const endX = waveEndX;

            if (endX <= padding)
                return "";

            let path = "M " + padding.toFixed(2) + " " + waveY(padding).toFixed(2);
            const sampleStep = Math.max(0.5, root.step);

            for (let x = padding; x < endX; x += sampleStep) {
                const nextX = Math.min(endX, x + sampleStep);
                const y0 = waveY(x);
                const y1 = waveY(nextX);
                const dx = nextX - x;
                const c1x = x + dx / 3;
                const c1y = y0 + waveSlope(x) * dx / 3;
                const c2x = nextX - dx / 3;
                const c2y = y1 - waveSlope(nextX) * dx / 3;

                path += " C " + c1x.toFixed(2) + " " + c1y.toFixed(2)
                    + " " + c2x.toFixed(2) + " " + c2y.toFixed(2)
                    + " " + nextX.toFixed(2) + " " + y1.toFixed(2);
            }
            return path;
        }

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

        Shape {
            anchors.fill: parent
            opacity: root.trackOpacity
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                strokeWidth: root.lineWidth
                strokeColor: root.trackColor
                fillColor: "transparent"
                startX: Math.min(waveContainer.width - root.lineWidth / 2, waveContainer.playheadX + root.gap)
                startY: waveContainer.centerY

                PathLine {
                    x: waveContainer.width - root.lineWidth / 2
                    y: waveContainer.centerY
                }
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                strokeWidth: root.lineWidth
                strokeColor: root.waveColor
                fillColor: "transparent"

                PathSvg {
                    path: waveContainer.wavePath
                }
            }
        }

        Rectangle {
            width: root.endDotSize
            height: root.endDotSize
            radius: width / 2
            color: root.endDotColor
            opacity: root.endDotOpacity
            antialiasing: true
            x: Math.max(0, waveContainer.width - root.lineWidth / 2 - width / 2)
            y: waveContainer.centerY - height / 2
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
