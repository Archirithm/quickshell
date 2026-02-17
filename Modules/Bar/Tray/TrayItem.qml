import QtQuick
import Quickshell
import qs.config

MouseArea {
    id: root
    required property var modelData 
    
    implicitWidth: 24
    implicitHeight: 24
    
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: (event) => {
        if (event.button === Qt.LeftButton) {
            modelData.activate();
            trayMenu.visible = false;
        } else if (event.button === Qt.RightButton) {
            // 切换菜单显示状态
            trayMenu.visible = !trayMenu.visible;
        }
    }

    // 实例化我们刚才写的 DMS 风格菜单
    TrayMenu {
        id: trayMenu
        
        // 绑定数据
        rootMenuHandle: root.modelData.menu
        trayName: root.modelData.tooltipTitle || root.modelData.id || "Menu"
        
        // 设置锚点 (Anchor)
        anchor.item: root
        // 位置设置：根据你的栏位置调整
        // 假设栏在顶部/底部，这里让它垂直偏移一点
        anchor.rect.y: (root.mapToItem(null, 0, 0).y > 500) ? -trayMenu.height - 5 : root.height + 5
        anchor.rect.x: 0
    }

    Image {
        id: content
        anchors.fill: parent
        anchors.margins: 2
        
        source: {
            const raw = root.modelData.icon;
            if (raw.indexOf("spotify") !== -1) {
                return "image://icon/spotify";
            }
            return raw;
        }
        
        cache: true
        asynchronous: true
        fillMode: Image.PreserveAspectFit
    }
}
