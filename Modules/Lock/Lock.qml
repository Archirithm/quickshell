import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root
    signal unlocked()

    // 1. 鉴权逻辑 (Scope) - 保持不变
    Scope {
        id: internalContext
        property string currentText: ""
        property bool unlockInProgress: false
        property bool showFailure: false

        function tryUnlock() {
            if (currentText === "") return;
            internalContext.unlockInProgress = true;
            pam.start();
        }
        
        function emergencyUnlock() {
            sessionLock.locked = false;
            root.unlocked();
        }

        PamContext {
            id: pam
            configDirectory: Quickshell.env("HOME") + "/.config/quickshell/Modules/Lock/pam"
            config: "password.conf"
            onPamMessage: { if (this.responseRequired) this.respond(internalContext.currentText); }
            onCompleted: result => {
                if (result == PamResult.Success) {
                    internalContext.currentText = "";
                    internalContext.showFailure = false;
                    internalContext.emergencyUnlock();
                } else {
                    internalContext.currentText = "";
                    internalContext.showFailure = true;
                }
                internalContext.unlockInProgress = false;
            }
        }
    }

    // 2. Wayland 锁屏
    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            
            // A. UI 加载器
            Loader {
                id: uiLoader
                anchors.fill: parent
                
                // 【已修改】使用 HOME 环境变量拼接标准的文件 URL
                source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/Modules/Lock/LockSurface.qml"
                
                onLoaded: {
                    if (item) item.context = internalContext
                }
            }
        }
    }
}
