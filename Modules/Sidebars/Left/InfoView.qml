import QtQuick
import QtQuick.Layouts
import Clavis.Sysmon 1.0
import qs.Common
import qs.Services
import qs.Widgets.common
import "./notifications"

Item {
    id: root

    readonly property int fetchCardHeight: 252

    readonly property bool isForeground: WidgetState.leftSidebarOpen && WidgetState.leftSidebarView === "info"
    onIsForegroundChanged: {
        if (isForeground) {
            NotificationManager.timeoutAll();
            NotificationManager.markAllRead();
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: false
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 2

        function wheelPage(angleDeltaY) {
            if (angleDeltaY === 0)
                return;
            const direction = angleDeltaY > 0 ? -1 : 1;
            const target = flick.contentY + direction * Math.max(120, flick.height * 0.85);
            flick.contentY = Math.max(0, Math.min(target, Math.max(0, flick.contentHeight - flick.height)));
        }

        Behavior on contentY {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                flick.wheelPage(event.angleDelta.y);
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: contentColumn
            width: flick.width
            spacing: 12

            SystemFetchCard {
                Layout.fillWidth: true
                Layout.preferredHeight: root.fetchCardHeight
                radius: 24
                cardPadding: 16
                systemUser: SysmonPlugin.systemUser
                hostName: SysmonPlugin.hostName
                chassis: SysmonPlugin.chassis
                uptime: SysmonPlugin.uptime
                osAge: SysmonPlugin.osAgeText
                kernelRelease: SysmonPlugin.kernelRelease
                wmName: SysmonPlugin.wmName
                shellName: SysmonPlugin.shellName
                distroId: SysmonPlugin.distroId
            }

            NotificationCenterCard {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(360, flick.height - root.fetchCardHeight - contentColumn.spacing)
            }
        }
    }

}
