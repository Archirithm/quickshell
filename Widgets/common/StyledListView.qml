import QtQuick
import QtQuick.Controls
import qs.Common

ListView {
    id: root

    spacing: 0
    clip: true

    property real removeOvershoot: 20
    property bool popin: true
    property bool animateAppearance: true
    property bool animateMovement: true

    Component {
        id: elementMoveAnimation

        ElementMoveAnimation {}
    }

    add: Transition {
        animations: root.animateAppearance ? [
            elementMoveAnimation.createObject(this, {
                properties: root.popin ? "opacity,scale" : "opacity",
                from: 0,
                to: 1,
            }),
        ] : []
    }

    addDisplaced: Transition {
        animations: root.animateAppearance ? [
            elementMoveAnimation.createObject(this, {
                property: "y",
            }),
            elementMoveAnimation.createObject(this, {
                properties: root.popin ? "opacity,scale" : "opacity",
                to: 1,
            }),
        ] : []
    }

    displaced: Transition {
        animations: root.animateMovement ? [
            elementMoveAnimation.createObject(this, {
                property: "y",
            }),
            elementMoveAnimation.createObject(this, {
                properties: "opacity,scale",
                to: 1,
            }),
        ] : []
    }

    move: Transition {
        animations: root.animateMovement ? [
            elementMoveAnimation.createObject(this, {
                property: "y",
            }),
            elementMoveAnimation.createObject(this, {
                properties: "opacity,scale",
                to: 1,
            }),
        ] : []
    }

    moveDisplaced: Transition {
        animations: root.animateMovement ? [
            elementMoveAnimation.createObject(this, {
                property: "y",
            }),
            elementMoveAnimation.createObject(this, {
                properties: "opacity,scale",
                to: 1,
            }),
        ] : []
    }

    remove: Transition {
        animations: root.animateAppearance ? [
            elementMoveAnimation.createObject(this, {
                property: "x",
                to: root.width + root.removeOvershoot,
            }),
            elementMoveAnimation.createObject(this, {
                property: "opacity",
                to: 0,
            }),
        ] : []
    }

    removeDisplaced: Transition {
        animations: root.animateAppearance ? [
            elementMoveAnimation.createObject(this, {
                property: "y",
            }),
            elementMoveAnimation.createObject(this, {
                properties: "opacity,scale",
                to: 1,
            }),
        ] : []
    }
}
