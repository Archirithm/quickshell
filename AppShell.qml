import QtQuick
import Quickshell
import Quickshell.Io
import qs.Modules.Bar
import qs.Modules.DynamicIsland
import qs.Modules.Launcher
import qs.Modules.Sidebars.Left
import qs.Modules.Sidebars.Right

Item {
    id: root

    Bar {}

    DynamicIsland {}

    LeftSidebarWindow {}

    RightSidebar {}

    Loader {
        id: lockLoader
        active: false
        source: Qt.resolvedUrl("Modules/Lock/Lock.qml")

        Connections {
            target: lockLoader.item
            ignoreUnknownSignals: true

            function onUnlocked() {
                lockLoader.active = false;
            }
        }
    }

    IpcHandler {
        target: "lock"

        function open() {
            if (!lockLoader.active) {
                lockLoader.active = true;
                return "LOCKED";
            }
            return "ALREADY_LOCKED";
        }
    }

    LauncherWindow {
        id: rofiLauncher
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            rofiLauncher.toggleWindow();
            return "LAUNCHER_TOGGLED";
        }
    }
}
