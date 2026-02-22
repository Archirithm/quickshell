import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects 
import Quickshell
import qs.config 

PopupWindow {
    id: root

    property var rootMenuHandle: null
    property string trayName: ""
    
    implicitWidth: 240
    implicitHeight: Math.min(600, mainLayout.implicitHeight + 20)
    color: "transparent"
    
    onVisibleChanged: {
        if (visible) {
            menuStack.clear()
        }
    }

    // --- 1. 状态堆栈 ---
    ListModel {
        id: menuStack
    }

    property var currentSubMenuHandle: {
        if (menuStack.count === 0) return null
        return menuStack.get(menuStack.count - 1).handle
    }

    // --- 2. 双通道数据源 ---
    QsMenuOpener {
        id: rootOpener
        menu: root.rootMenuHandle
    }

    QsMenuOpener {
        id: subOpener
        menu: root.currentSubMenuHandle
    }

    // --- 3. 隐形数据激活器 (Hydrator) ---
    QsMenuAnchor {
        id: hydrator
        anchor.window: root
        anchor.item: mainLayout
        // 【核心修复】不要设为负数！
        // 设为当前窗口中心，防止 Wayland 强制推到屏幕左上角
        anchor.rect.x: root.width / 2
        anchor.rect.y: root.height / 2
        // 设为极小尺寸
        anchor.rect.width: 1
        anchor.rect.height: 1
    }

    // --- 4. 导航逻辑 ---
    function navigateToSubmenu(menuHandle, menuText) {
        if (!menuHandle) return

        menuStack.append({ "handle": menuHandle, "title": menuText })

        try {
            // 1. 标准 API 调用
            if (typeof menuHandle.aboutToShow === "function") menuHandle.aboutToShow()
            if (typeof menuHandle.updateLayout === "function") menuHandle.updateLayout()
            
            // 2. 暴力激活 (瞬时开关)
            // 这里的逻辑是：open() 触发 DBus 信号，close() 销毁渲染请求
            // 如果两个动作在同一帧内完成，用户就看不到窗口，但 NetworkManager 会收到信号
            hydrator.menu = menuHandle
            hydrator.open()
            hydrator.close() // 【关键】移除 Qt.callLater，立即关闭！
            
        } catch (e) {
            console.warn("Hydrator error:", e)
        }
    }

    function navigateBack() {
        if (menuStack.count > 0) {
            menuStack.remove(menuStack.count - 1, 1)
        }
    }

    // --- 界面渲染 ---
    Rectangle {
        anchors.fill: parent
        // [背景] 深色容器背景
        color: Colorscheme.surface_container
        radius: 12
        border.width: 1
        // [边框] 使用 Outline 颜色
        border.color: Colorscheme.outline_variant
        clip: true 

        ColumnLayout {
            id: mainLayout
            width: parent.width
            spacing: 0

            // --- 标题栏 ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "transparent"
                
                // 标题文本
                Text {
                    text: (menuStack.count === 0) ? (root.trayName || "Menu") : menuStack.get(menuStack.count - 1).title
                    anchors.centerIn: parent
                    font.bold: true
                    // [颜色] Primary 主色
                    color: Colorscheme.primary
                    font.pixelSize: 15
                    width: parent.width - 60
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                // 返回按钮
                Rectangle {
                    visible: menuStack.count > 0
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 6
                    color: backMa.containsMouse ? Colorscheme.secondary_container : "transparent"

                    Text {
                        text: "⬅" 
                        anchors.centerIn: parent
                        // [颜色] 返回箭头
                        color: Colorscheme.on_secondary_container
                        font.bold: true
                    }

                    MouseArea {
                        id: backMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.navigateBack()
                    }
                }
                
                // 分割线
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    // [颜色] 分割线
                    color: Colorscheme.primary
                    opacity: 0.2
                }
            }

            // --- 列表内容 ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 6 
                spacing: 4        
                
                property var currentModel: (menuStack.count === 0) ? 
                                         (rootOpener.children ? rootOpener.children.values : []) : 
                                         (subOpener.children ? subOpener.children.values : [])

                Text {
                    visible: (!parent.currentModel || parent.currentModel.length === 0)
                    text: (menuStack.count > 0) ? "Loading..." : "No Items"
                    color: Colorscheme.secondary
                    font.italic: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.margins: 10
                }

                Repeater {
                    model: parent.currentModel

                    delegate: Rectangle {
                        id: menuItem
                        property bool isSeparator: (modelData.isSeparator === true || modelData.text === "")
                        property bool hasSubMenu: (modelData.hasChildren === true)
                        property var effectiveHandle: (modelData.menu) ? modelData.menu : modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: isSeparator ? 9 : 36 
                        radius: 8
                        
                        // [交互] 悬停背景
                        color: (itemMa.containsMouse && !isSeparator) ? Colorscheme.secondary_container : "transparent"
                        
                        Behavior on color { ColorAnimation { duration: 100 } }

                        // 分割线
                        Rectangle {
                            visible: parent.isSeparator
                            anchors.centerIn: parent
                            width: parent.width - 20
                            height: 1
                            color: Colorscheme.outline_variant
                            opacity: 0.5
                        }

                        // 内容行
                        RowLayout {
                            visible: !parent.isSeparator
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // 1. 图标 (染色处理)
                            Item {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                visible: (modelData.icon || "") !== ""
                                
                                Image {
                                    id: iconRaw
                                    anchors.fill: parent
                                    source: modelData.icon || ""
                                    visible: false 
                                    fillMode: Image.PreserveAspectFit
                                }
                                
                                ColorOverlay {
                                    anchors.fill: iconRaw
                                    source: iconRaw
                                    // [颜色] 图标变色
                                    color: itemMa.containsMouse ? Colorscheme.on_secondary_container : Colorscheme.secondary
                                    visible: iconRaw.status === Image.Ready
                                    cached: true
                                }
                            }

                            // 2. 勾选状态
                            Text {
                                visible: modelData.toggleState === 1
                                text: "✔"
                                color: Colorscheme.primary
                                font.bold: true
                            }

                            // 3. 文本
                            Text {
                                text: modelData.text || ""
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                
                                // [颜色] 文字颜色逻辑
                                color: {
                                    if (modelData.enabled === false) return Colorscheme.outline;
                                    if (itemMa.containsMouse) return Colorscheme.on_secondary_container;
                                    return Colorscheme.on_surface;
                                }
                                font.pixelSize: 14
                                font.weight: itemMa.containsMouse ? Font.DemiBold : Font.Normal
                            }

                            // 4. 子菜单箭头
                            Text {
                                visible: hasSubMenu
                                text: "›"
                                font.pixelSize: 20
                                font.bold: true
                                color: itemMa.containsMouse ? Colorscheme.on_secondary_container : Colorscheme.tertiary
                            }
                        }

                        MouseArea {
                            id: itemMa
                            visible: !parent.isSeparator
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: modelData.enabled !== false

                            onClicked: {
                                if (hasSubMenu) {
                                    root.navigateToSubmenu(effectiveHandle, modelData.text)
                                } else {
                                    modelData.triggered()
                                    root.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
