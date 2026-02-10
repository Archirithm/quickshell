import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    // 共享上下文
    LockContext {
        id: lockContext
        
        onUnlocked: {
            sessionLock.locked = false;
            Qt.quit();
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        LockSurface {
            context: lockContext
        }
    }
}
