import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Common

Scope {
    id: root

    signal unlocked()

    Scope {
        id: internalContext

        property string currentText: ""
        property bool unlockInProgress: false
        property bool showFailure: false

        signal unlockSucceeded()
        signal unlockFailed()

        function tryUnlock() {
            if (currentText === "" || unlockInProgress)
                return;

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

            onPamMessage: {
                if (this.responseRequired)
                    this.respond(internalContext.currentText);
            }

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

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            id: lockSurface
            color: "transparent"

            LockSurface {
                anchors.fill: parent
                context: internalContext
                screenRef: lockSurface.screen
            }
        }
    }
}
