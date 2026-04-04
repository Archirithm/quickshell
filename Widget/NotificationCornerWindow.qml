import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.Widget.common

PanelWindow {
    id: root
    
    Theme { id: theme }

    property int sidebarWidth: 460
    property int gap: -16 
    property int gooeyRadius: 48  

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-notification-corner"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors { right: true; bottom: true }
    
    implicitWidth: sidebarWidth + 50
    implicitHeight: 750
    color: "transparent"

    property int targetNotifHeight: Math.max(240, Math.min(notifContent.totalHeight, 540))
    
    property int currentNotifHeight: targetNotifHeight
    Behavior on currentNotifHeight { 
        NumberAnimation { 
            duration: 600;
            easing.type: Easing.OutQuint 
        } 
    }

    Item {
        id: animController
        property int slideOffset: 800

        state: WidgetState.notifOpen ? "open" : "closed"
        
        states: [
            State { name: "open"; PropertyChanges { target: animController; slideOffset: 0 } },
            State { name: "closed"; PropertyChanges { target: animController; slideOffset: 800 } }
        ]
        
        transitions: [
            Transition {
                from: "closed"; to: "open"
                NumberAnimation { target: animController; property: "slideOffset"; duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.3 }
            },
            Transition {
                from: "open"; to: "closed"
                NumberAnimation { target: animController; property: "slideOffset"; duration: 350; easing.type: Easing.InBack; easing.overshoot: 0.1 }
            }
        ]
    }

    Item {
        id: hitBoxRegion
        x: qsShadow.x
        y: qsShadow.y
        width: qsShadow.width + root.gap
        height: qsShadow.height + root.gap 
    }
    mask: Region { item: hitBoxRegion }

    Item {
        id: renderCanvas
        width: parent.width + 100 
        height: parent.height + 100
        x: 0
        y: 0

        Item {
            id: rawShapes
            anchors.fill: parent
            visible: false

            Rectangle {
                id: qsShadow
                width: root.sidebarWidth
                height: root.currentNotifHeight
                x: root.implicitWidth - root.sidebarWidth - root.gap
                y: (root.implicitHeight - root.currentNotifHeight - root.gap) + animController.slideOffset
                radius: theme.radius
                color: "black" 
            }

            Rectangle {
                width: 100
                height: parent.height
                x: root.implicitWidth 
                y: 0
                color: "black"
                opacity: WidgetState.notifOpen ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
            }

            Rectangle {
                width: parent.width
                height: 100
                x: 0
                y: root.implicitHeight 
                color: "black"
                opacity: WidgetState.notifOpen ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
            }
        }

        GaussianBlur {
            id: blurredShapes
            anchors.fill: parent
            source: rawShapes
            radius: root.gooeyRadius
            samples: 1 + root.gooeyRadius * 2
            visible: false 
        }

        Rectangle { 
            id: solidBg
            anchors.fill: parent
            color: theme.background 
            visible: false 
        }

        ThresholdMask {
            id: gooeyLayer
            anchors.fill: parent
            source: solidBg
            maskSource: blurredShapes
            threshold: 0.51
            spread: 0.02
        }
    }

    Item {
        anchors.fill: parent

        Item {
            width: qsShadow.width
            height: qsShadow.height
            x: qsShadow.x
            y: qsShadow.y
            clip: true 

            HoverHandler {
                onHoveredChanged: {
                    WidgetState.notifIsHovered = hovered;
                    if (hovered) {
                        panelCloseTimer.stop();
                    } else {
                        if (!WidgetState.notifPinned) {
                            panelCloseTimer.start();
                        }
                    }
                }
            }

            Timer {
                id: panelCloseTimer
                interval: 1000 
                onTriggered: {
                    if (!WidgetState.notifIsHovered && !WidgetState.notifPinned) {
                        WidgetState.notifOpen = false;
                    }
                }
            }

            NotificationContent { 
                id: notifContent
                anchors.fill: parent 
            }
        }
    }
}
