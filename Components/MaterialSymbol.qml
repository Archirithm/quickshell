import QtQuick
import qs.Common

Text {
    id: root

    property real iconSize: 22
    property real fill: 0
    readonly property real roundedFill: Number(fill).toFixed(1)

    renderType: Text.NativeRendering
    font {
        family: "Material Symbols Rounded"
        pixelSize: root.iconSize
        weight: Font.Normal + (Font.DemiBold - Font.Normal) * root.roundedFill
        variableAxes: {
            "FILL": root.roundedFill,
            "opsz": root.iconSize
        }
    }
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on fill {
        NumberAnimation {
            duration: Appearance.animation.expressiveEffects.duration
            easing.type: Appearance.animation.expressiveEffects.type
            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
        }
    }
}
