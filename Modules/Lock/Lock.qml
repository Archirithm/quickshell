import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.Common

ShellRoot {
    id: root
    signal unlocked()

    // 1. 鉴权逻辑 (Scope)
    Scope {
        id: internalContext
        property string currentText: ""
        property bool unlockInProgress: false
        property bool showFailure: false

        signal unlockSucceeded()
        signal unlockFailed()

        function tryUnlock() {
            if (currentText === "") return;
            if (unlockInProgress) return;
            internalContext.unlockInProgress = true;
            pam.start();
        }
        
        function finishUnlock() {
            sessionLock.locked = false;
            root.unlocked();
        }

        PamContext {
            id: pam
            configDirectory: Paths.shellDir + "/Modules/Lock/pam"
            config: "password.conf"
            onPamMessage: { if (this.responseRequired) this.respond(internalContext.currentText); }
            onCompleted: result => {
                if (result == PamResult.Success) {
                    internalContext.currentText = "";
                    internalContext.showFailure = false;
                    internalContext.unlockSucceeded();
                } else {
                    internalContext.currentText = "";
                    internalContext.showFailure = true;
                    internalContext.unlockFailed();
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
            id: lockSurface

            LockSurface {
                anchors.fill: parent
                context: internalContext
                screenRef: lockSurface.screen
            }

            // // C. 紧急出口 (右上角)
            // Rectangle {
            //     anchors.top: parent.top
            //     anchors.right: parent.right
            //     width: 150; height: 50
            //     color: "red"
            //     z: 999
            //     Text { 
            //         anchors.centerIn: parent
            //         text: "紧急解锁"
            //         color: "white" 
            //         font.pixelSize: 16
            //         font.bold: true
            //     }
            //     MouseArea { 
            //         anchors.fill: parent
            //         onClicked: { 
            //             sessionLock.locked = false
            //             root.unlocked() 
            //         } 
            //     }
            // }
        }
    }
}
