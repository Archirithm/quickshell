import QtQuick

Item {
    id: root

    // === 必需属性 ===
    required property real progress       // 0.0~1.0 当前进度
    required property color waveColor     // 波浪/已播放颜色
    required property color trackColor    // 未播放轨道颜色

    // === 可选属性 ===
    property bool isPlaying: false        // 控制波浪动画运行
    property real waveAmplitude: 2.5      // 波浪振幅
    property real waveFrequency: 0.12     // 波浪频率
    property real trackHeight: 6          // 轨道高度
    property real trackRadius: trackHeight / 2
    property real thumbSize: 0            // 滑块大小（0=无滑块）
    property color thumbColor: waveColor
    property real seekMargin: 10          // seek 区域外扩边距
    property real minWaveWidth: trackHeight
    property real fadeLength: 30
    property real secondaryWaveFrequencyMultiplier: 1.5
    property real secondaryWaveAmplitude: 0.3
    property real waveBias: 1.3
    property int phaseDuration: 1200
    property int smoothingDuration: 400
    property real smoothingVelocity: 500

    // === 信号 ===
    signal seekRequested(real position)   // 拖动释放时发出 0~1 比例

    // === 只读：是否正在拖动 ===
    readonly property bool pressed: seekMa.pressed

    // === 当前可视进度 X 坐标（供外部读取） ===
    readonly property real visualX: _visualX

    implicitHeight: 36

    // --- 内部状态 ---
    property real _targetX: root.progress * root.width
    property real _activeX: seekMa.pressed
        ? Math.max(0, Math.min(seekMa.mouseX, root.width))
        : _targetX
    property real _visualX: _activeX

    Behavior on _visualX {
        enabled: root.visible && !seekMa.pressed
        SmoothedAnimation {
            velocity: root.smoothingVelocity
            duration: root.smoothingDuration
        }
    }

    // --- 未播放轨道 ---
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.trackHeight
        radius: root.trackRadius
        color: root.trackColor
    }

    // --- 波浪 Canvas ---
    Canvas {
        id: waveCanvas
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(root.minWaveWidth, root._visualX)

        property real phase: 0

        NumberAnimation on phase {
            loops: Animation.Infinite
            from: 0
            to: Math.PI * 2
            duration: root.phaseDuration
            easing.type: Easing.Linear
            running: root.isPlaying
        }

        onPhaseChanged: requestPaint()

        Connections {
            target: root
            function on_VisualXChanged() { waveCanvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            let trackH = root.trackHeight;
            let radius = root.trackRadius;
            let centerY = height / 2;
            let w = width;

            if (w < radius * 2) return;

            ctx.beginPath();
            ctx.moveTo(w, centerY + trackH / 2);
            ctx.lineTo(radius, centerY + trackH / 2);
            ctx.arcTo(0, centerY + trackH / 2, 0, centerY, radius);
            ctx.arcTo(0, centerY - trackH / 2, radius, centerY - trackH / 2, radius);

            let freq = root.waveFrequency;
            let maxAmp = root.waveAmplitude;
            let fadeLen = root.fadeLength;

            for (let x = radius; x <= w; x++) {
                let leftDist = x - radius;
                let rightDist = w - x;
                let envelope = 1.0;

                if (leftDist < fadeLen) {
                    envelope = Math.sin((leftDist / fadeLen) * (Math.PI / 2));
                }
                if (rightDist < fadeLen) {
                    let envRight = Math.sin((rightDist / fadeLen) * (Math.PI / 2));
                    if (envRight < envelope) {
                        envelope = envRight;
                    }
                }

                let wave1 = Math.sin(x * freq - phase);
                let wave2 = Math.sin(x * freq * root.secondaryWaveFrequencyMultiplier - phase * 2.0) * root.secondaryWaveAmplitude;
                let combined = (wave1 + wave2 + root.waveBias) / (2 * root.waveBias);

                if (combined < 0) combined = 0;
                if (combined > 1) combined = 1;

                let y = (centerY - trackH / 2) - (combined * maxAmp * envelope);
                ctx.lineTo(x, y);
            }

            ctx.lineTo(w, centerY - trackH / 2);
            ctx.lineTo(w, centerY + trackH / 2);
            ctx.closePath();
            ctx.fillStyle = String(root.waveColor);
            ctx.fill();
        }
    }

    // --- 可选滑块 ---
    Rectangle {
        visible: root.thumbSize > 0
        width: root.thumbSize
        height: root.thumbSize
        radius: root.thumbSize / 2
        color: root.thumbColor
        anchors.verticalCenter: parent.verticalCenter
        x: root._visualX - width / 2
    }

    // --- Seek 交互区 ---
    MouseArea {
        id: seekMa
        anchors.fill: parent
        anchors.margins: -root.seekMargin
        cursorShape: Qt.PointingHandCursor

        onReleased: (mouse) => {
            let clampedX = Math.max(0, Math.min(mouse.x, root.width));
            root.seekRequested(clampedX / root.width);
        }
    }
}
