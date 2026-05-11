import QtQuick
import QtQuick.Shapes
import Quickshell

Item {
    id: root

    property var values: []
    property int barCount: values ? values.length : 0
    property real innerRadius: Math.max(0, Math.min(width, height) / 2 - maxMagnitude - strokeWidth)
    property real maxMagnitude: 32
    property real strokeWidth: 4
    property real minimumValue: 1e-3
    property real valueScale: 1
    property real startAngleDegrees: -90
    property color strokeColor: "white"
    property bool roundedCaps: true

    function valueAt(index) {
        if (!root.values || index < 0 || index >= root.values.length)
            return 0;

        const value = Number(root.values[index]);
        return isNaN(value) ? 0 : value;
    }

    Shape {
        id: spectrumShape

        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer
        data: spectrumBars.instances
    }

    Variants {
        id: spectrumBars

        model: Array.from({ length: Math.max(0, root.barCount) }, (_, i) => i)

        ShapePath {
            id: spectrumBar

            required property int modelData

            readonly property real value: Math.max(root.minimumValue, Math.min(1, root.valueAt(modelData) * root.valueScale))
            readonly property real angle: (root.startAngleDegrees * Math.PI / 180) + modelData * 2 * Math.PI / Math.max(1, root.barCount)
            readonly property real magnitude: value * root.maxMagnitude
            readonly property real cos: Math.cos(angle)
            readonly property real sin: Math.sin(angle)

            capStyle: root.roundedCaps ? ShapePath.RoundCap : ShapePath.SquareCap
            strokeWidth: root.strokeWidth
            strokeColor: root.strokeColor
            fillColor: "transparent"

            startX: root.width / 2 + root.innerRadius * cos
            startY: root.height / 2 + root.innerRadius * sin

            PathLine {
                x: root.width / 2 + (root.innerRadius + spectrumBar.magnitude) * spectrumBar.cos
                y: root.height / 2 + (root.innerRadius + spectrumBar.magnitude) * spectrumBar.sin
            }
        }
    }
}
