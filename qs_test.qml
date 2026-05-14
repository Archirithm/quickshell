import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    visible: true
    width: 200
    height: 200
    ScreencopyView {
        id: sc
        captureSource: screen
        Component.onCompleted: {
            for (var prop in sc) {
                console.log(prop + ": " + sc[prop])
            }
            Qt.quit()
        }
    }
}
