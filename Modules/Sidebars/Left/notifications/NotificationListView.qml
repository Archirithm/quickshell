import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services

ListView {
    id: root

    property int dragIndex: -1
    property real dragDistance: 0
    property real scrollTargetY: 0
    property var expandedGroups: ({})

    spacing: 3
    clip: true
    interactive: false
    boundsBehavior: Flickable.StopAtBounds
    model: NotificationManager.appNameList

    function maxContentY() {
        return Math.max(0, root.contentHeight - root.height);
    }

    function clampContentY(value) {
        return Math.max(0, Math.min(value, root.maxContentY()));
    }

    function wheelStep(pixelDeltaY, angleDeltaY) {
        if (pixelDeltaY !== 0)
            return -pixelDeltaY;
        if (angleDeltaY === 0)
            return 0;
        const direction = angleDeltaY > 0 ? -1 : 1;
        return direction * Math.max(56, root.height * 0.18);
    }

    function wheelScroll(pixelDeltaY, angleDeltaY) {
        const step = root.wheelStep(pixelDeltaY, angleDeltaY);
        if (step === 0)
            return;
        root.scrollTargetY = root.clampContentY(root.scrollTargetY + step);
        root.contentY = root.scrollTargetY;
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    Behavior on contentY {
        NumberAnimation {
            duration: Appearance.animation.standardDecel.duration
            easing.type: Appearance.animation.standardDecel.type
            easing.bezierCurve: Appearance.animation.standardDecel.bezierCurve
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root.wheelScroll(event.pixelDelta.y, event.angleDelta.y);
            event.accepted = true;
        }
    }

    onContentHeightChanged: {
        root.scrollTargetY = root.clampContentY(root.scrollTargetY);
        if (root.contentY > root.maxContentY())
            root.contentY = root.maxContentY();
    }

    function resetDrag() {
        root.dragIndex = -1;
        root.dragDistance = 0;
    }

    function isExpanded(appName) {
        return root.expandedGroups[appName] === true;
    }

    function setExpanded(appName, expanded) {
        const next = Object.assign({}, root.expandedGroups);
        if (expanded)
            next[appName] = true;
        else
            delete next[appName];
        root.expandedGroups = next;
    }

    delegate: NotificationGroup {
        delegateIndex: index
        dragHost: root
        expanded: root.isExpanded(modelData)
        width: root.width
        notificationGroup: NotificationManager.groupsByAppName[modelData]
        onExpandedChanged: root.setExpanded(modelData, expanded)
    }

    add: Transition {
        NumberAnimation {
            properties: "opacity,scale"
            from: 0
            to: 1
            duration: Appearance.animation.expressiveDefaultSpatial.duration
            easing.type: Appearance.animation.expressiveDefaultSpatial.type
            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
        }
    }

    addDisplaced: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "y"
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
            NumberAnimation {
                properties: "opacity,scale"
                to: 1
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
        }
    }

    remove: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "x"
                to: root.width + 20
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
        }
    }

    removeDisplaced: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "y"
                duration: Appearance.animation.expressiveDefaultSpatial.duration
                easing.type: Appearance.animation.expressiveDefaultSpatial.type
                easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
            }
            NumberAnimation {
                properties: "opacity,scale"
                to: 1
                duration: 1
            }
        }
    }

    displaced: Transition {
        NumberAnimation {
            property: "y"
            duration: Appearance.animation.expressiveDefaultSpatial.duration
            easing.type: Appearance.animation.expressiveDefaultSpatial.type
            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
        }
    }

    move: Transition {
        NumberAnimation {
            property: "y"
            duration: Appearance.animation.expressiveDefaultSpatial.duration
            easing.type: Appearance.animation.expressiveDefaultSpatial.type
            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
        }
    }

    moveDisplaced: Transition {
        NumberAnimation {
            property: "y"
            duration: Appearance.animation.expressiveDefaultSpatial.duration
            easing.type: Appearance.animation.expressiveDefaultSpatial.type
            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
        }
    }
}
