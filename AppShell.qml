import QtQuick
import Quickshell
import Quickshell.Io
import qs.Modules.Bar
import qs.Modules.DynamicIsland
import qs.Modules.Launcher
import qs.Modules.Lock
import qs.Modules.Sidebars.Left
import qs.Modules.Sidebars.Right
import qs.Modules.Wallpaper

Item {
    id: root

    WallpaperBackground {}

    OverviewWallpaperBackground {}

    Bar {}

    DynamicIsland {}

    LeftSidebarWindow {}

    RightSidebar {}

    LockWarmup {}

    Lock {
        id: sessionLocker
    }

    IpcHandler {
        target: "lock"

        function open() {
            return sessionLocker.open();
        }

        function isLocked() {
            return sessionLocker.isLocked();
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
