import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Common

Scope {
    id: root

    signal unlocked()

    function open() {
        if (sessionLock.locked)
            return "ALREADY_LOCKED";

        internalContext.currentText = "";
        internalContext.unlockInProgress = false;
        internalContext.showFailure = false;
        sessionLock.locked = true;
        return "LOCKED";
    }

    function isLocked() {
        return sessionLock.locked;
    }

    Scope {
        id: internalContext

        property string currentText: ""
        property bool unlockInProgress: false
        property bool showFailure: false

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
                    sessionLock.unlock();
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

        signal unlock()

        LockSurface {
            lock: sessionLock
            context: internalContext
        }
    }
}
