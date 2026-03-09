import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Io          // 【新增】：必须引入 IO 模块以支持命令行 Process
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root
    
    visible: false
    color: "transparent" 
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.namespace: "rofi-launcher-overlay"
    WlrLayershell.layer: WlrLayer.Overlay 
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive 
    WlrLayershell.exclusionMode: ExclusionMode.Ignore 

    property int currentMode: 0 
    
    // 【核心修复 1】：废除容易被缓存坑的软链接，直接绑定全局真理变量 Colorscheme.currentWallpaperPreview
    property string previewImage: (currentMode === 2 && wallpaperPage.currentSelectedPreview !== "") 
                                  ? wallpaperPage.currentSelectedPreview 
                                  : (Colorscheme.currentWallpaperPreview !== "" ? Colorscheme.currentWallpaperPreview : "file://" + Quickshell.env("HOME") + "/.cache/wallpaper_rofi/current")

    // ==========================================
    // 【全局壁纸强制同步引擎】
    // ==========================================
    Process {
        id: syncGlobalWallpaper
        command: ["bash", "-c", "swww query | awk -F 'image: ' '{print $2}' | head -n 1"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (path) => {
                let currentPath = path.trim().replace(/^"|"$/g, '');
                if (currentPath !== "") {
                    // 获取到真实的绝对路径，强行刷新全局变量，QML 图片缓存瞬间失效并更新
                    Colorscheme.currentWallpaperPreview = "file://" + currentPath;
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            // 【核心修复 2】：每次打开 Launcher，第一时间强制核实并同步系统真实壁纸！
            syncGlobalWallpaper.running = false;
            syncGlobalWallpaper.running = true;

            // 智能焦点路由
            if (currentMode === 0) appPage.forceSearchFocus()
            else if (currentMode === 1) windowPage.forceSearchFocus()
            else mainUI.forceActiveFocus()
            
            // 每次打开都正常播放入场动画
            mainUI.opacity = 0.0
            uiTranslate.y = 300
            openAnim.start() 
        }
    }

    onCurrentModeChanged: {
        if (visible) {
            if (currentMode === 0) appPage.forceSearchFocus()
            else if (currentMode === 1) windowPage.forceSearchFocus()
            else mainUI.forceActiveFocus()
        }
    }

    function requestClose() {
        if (closeAnim.running || !root.visible) return
        closeAnim.start() 
    }

    function toggleWindow() {
        if (root.visible) requestClose()
        else root.visible = true 
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.requestClose()
    }

    // ==========================================
    // 主界面 UI
    // ==========================================
    Rectangle {
        id: mainUI
        width: 1008
        height: 567
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        
        opacity: 0.0 
        
        transform: Translate {
            id: uiTranslate
            y: 300 
        }
        
        ParallelAnimation {
            id: openAnim
            NumberAnimation {
                target: mainUI
                property: "opacity"
                to: 1.0
                duration: 400
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: uiTranslate
                property: "y"
                to: 0
                duration: 700
                easing.type: Easing.OutBack
                easing.overshoot: 2.5
            }
        }

        ParallelAnimation {
            id: closeAnim
            NumberAnimation {
                target: mainUI
                property: "opacity"
                to: 0.0
                duration: 300
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: uiTranslate
                property: "y"
                to: 300
                duration: 300
                easing.type: Easing.InCubic
            }
            onFinished: root.visible = false 
        }
        
        color: "transparent" 
        radius: 20 
        focus: true 
        
        // 全局键盘网关
        Keys.onUpPressed: (event) => {
            if (root.currentMode === 0) appPage.decrementCurrentIndex()
            else if (root.currentMode === 1) windowPage.decrementCurrentIndex()
            else if (root.currentMode === 2) wallpaperPage.decrementCurrentIndex()
            event.accepted = true
        }
        
        Keys.onDownPressed: (event) => {
            if (root.currentMode === 0) appPage.incrementCurrentIndex()
            else if (root.currentMode === 1) windowPage.incrementCurrentIndex()
            else if (root.currentMode === 2) wallpaperPage.incrementCurrentIndex()
            event.accepted = true
        }

        Keys.onReturnPressed: (event) => {
            if (root.currentMode === 0) appPage.runSelectedApp()
            else if (root.currentMode === 1) windowPage.focusSelectedWindow()
            else if (root.currentMode === 2) wallpaperPage.applyWallpaper()
            event.accepted = true
        }
        
        Keys.onEnterPressed: (event) => {
            if (root.currentMode === 0) appPage.runSelectedApp()
            else if (root.currentMode === 1) windowPage.focusSelectedWindow()
            else if (root.currentMode === 2) wallpaperPage.applyWallpaper()
            event.accepted = true
        }

        Keys.onEscapePressed: (event) => {
            root.requestClose()
            event.accepted = true
        }

        Keys.onTabPressed: (event) => {
            root.currentMode = (root.currentMode + 1) % 3
            event.accepted = true
        }
        
        MouseArea { anchors.fill: parent } 
        
        Rectangle {
            id: globalMask
            anchors.fill: parent
            radius: 20
            visible: false
        }

        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: globalMask
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0
                
                // --- 左侧：海报区 ---
                Item {
                    Layout.preferredWidth: 640 
                    Layout.fillHeight: true
                    clip: true 
                    
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                    }

                    Image {
                        id: rawPreviewForBlur
                        width: 1008
                        height: 567
                        x: 0 
                        y: 0
                        source: root.previewImage
                        fillMode: Image.PreserveAspectCrop 
                        asynchronous: true
                        visible: false 
                        sourceSize.width: 1008
                        sourceSize.height: 567
                    }

                    FastBlur {
                        anchors.fill: rawPreviewForBlur
                        source: rawPreviewForBlur
                        radius: 64 
                        transparentBorder: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.2)
                    }

                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 80 
                        clip: true 
                        
                        Image {
                            width: 1008
                            height: 567
                            x: -80  
                            y: 0
                            fillMode: Image.PreserveAspectCrop
                            source: root.previewImage
                            asynchronous: true  
                            sourceSize.width: 1008
                            sourceSize.height: 567
                        }
                    }

                    Column {
                        width: 80
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 24
                        
                        // 标签页 1：应用
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 24
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: root.currentMode === 0 ? Colorscheme.secondary : Qt.rgba(0.06, 0.06, 0.1, 0.8)
                            
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: root.currentMode === 0 ? Qt.rgba(0.06, 0.06, 0.1, 1.0) : Colorscheme.secondary
                            }
                        }
                        
                        // 标签页 2：窗口
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 24
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: root.currentMode === 1 ? Colorscheme.secondary : Qt.rgba(0.06, 0.06, 0.1, 0.8)
                            
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: root.currentMode === 1 ? Qt.rgba(0.06, 0.06, 0.1, 1.0) : Colorscheme.secondary
                            }
                        }
                        
                        // 标签页 3：壁纸
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 24
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: root.currentMode === 2 ? Colorscheme.secondary : Qt.rgba(0.06, 0.06, 0.1, 0.8)
                            
                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: root.currentMode === 2 ? Qt.rgba(0.06, 0.06, 0.1, 1.0) : Colorscheme.secondary
                            }
                        }
                    }
                }
                
                // --- 右侧：列表区 ---
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0.06, 0.06, 0.1, 0.85) 
                    }
                    
                    StackLayout {
                        anchors.fill: parent
                        anchors.margins: 30
                        currentIndex: root.currentMode 
                        
                        AppPage { 
                            id: appPage 
                            onRequestCloseLauncher: root.requestClose()
                        }
                        WindowPage { 
                            id: windowPage 
                            onRequestCloseLauncher: root.requestClose()
                        }
                        WallpaperPage { 
                            id: wallpaperPage  
                            onRequestCloseLauncher: root.requestClose()
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Colorscheme.secondary_fixed
            border.width: 2
            radius: 20
        }
    }
}
