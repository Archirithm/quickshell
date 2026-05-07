import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common

Item {
    id: root
    
    signal requestCloseLauncher()

    property string wallpaperPath: Quickshell.env("HOME") + "/.config/wallpaper"
    
    property string currentSelectedPreview: ""
    property string pendingOverviewPath: ""
    property bool isLoading: true

    ListModel { id: wallpaperModel }

    function decrementCurrentIndex() { wallpaperList.decrementCurrentIndex() }
    function incrementCurrentIndex() { wallpaperList.incrementCurrentIndex() }

    // ==========================================
    // 壁纸扫描引擎
    // ==========================================
    Process {
        id: scanWallpapers
        command: ["bash", "-c", "find " + root.wallpaperPath + " -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        running: false 
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (file) => {
                if (file.trim() !== "") {
                    let name = file.substring(file.lastIndexOf("/") + 1)
                    wallpaperModel.append({ path: file.trim(), fileName: name })
                }
            }
        }
        onExited: {
            root.isLoading = false
            
            // 直接白嫖 LauncherWindow 刚打开时就已经查好的全局变量
            let currentPath = Appearance.currentWallpaperPreview.replace("file://", "");
            
            if (currentPath === "") return;

            for (let i = 0; i < wallpaperModel.count; i++) {
                if (wallpaperModel.get(i).path === currentPath) {
                    wallpaperList.currentIndex = i;
                    // 初始化当前页面的预览变量
                    root.currentSelectedPreview = Appearance.currentWallpaperPreview;
                    // 自动滚动到当前选中的壁纸位置
                    wallpaperList.positionViewAtIndex(i, ListView.Center);
                    break;
                }
            }
        }
    }

    // 删除了原先冗余的 Process { id: getCurrentWallpaper ... } 

    onVisibleChanged: {
        if (visible) {
            wallpaperModel.clear()
            root.isLoading = true
            scanWallpapers.running = true
        } 
    }

    // ==========================================
    // UI 渲染层
    // ==========================================
    Text {
        anchors.centerIn: parent 
        text: "Scanning wallpapers..."
        color: Appearance.colors.colOnSurfaceVariant
        font.pixelSize: 16
        visible: root.isLoading
    }

    ListView {
        id: wallpaperList
        width: parent.width
        height: 504 
        anchors.verticalCenter: parent.verticalCenter 
        clip: true
        model: wallpaperModel
        
        snapMode: ListView.SnapToItem         
        boundsBehavior: Flickable.StopAtBounds
        highlightRangeMode: ListView.StrictlyEnforceRange 
        preferredHighlightBegin: 0
        preferredHighlightEnd: height - 56 
        
        highlight: Rectangle { 
            color: Appearance.colors.colPrimary
            radius: 12 
        }
        highlightMoveDuration: 0 

        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < count) {
                root.currentSelectedPreview = "file://" + wallpaperModel.get(currentIndex).path
            }
        }

        delegate: Item {
            id: delegateItem 
            width: ListView.view.width
            height: 56

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    wallpaperList.currentIndex = index
                    applyWallpaper()
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 16
                spacing: 16

                Image {
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 36
                    source: "file://" + model.path
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 128
                    sourceSize.height: 72
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }

                Text {
                    text: model.fileName
                    color: delegateItem.ListView.isCurrentItem ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                    font.pixelSize: 16
                    font.bold: false 
                    elide: Text.ElideRight 
                    Layout.fillWidth: true
                }
            }
        }
    }

    // ==========================================
    // 脚本执行引擎
    // ==========================================
    function wallpaperProcessesRunning() {
        return setWallpaperProcess.running || generateColorsProcess.running || overviewProcess.running;
    }

    function applyWallpaper() {
        if (wallpaperModel.count === 0 || wallpaperList.currentIndex < 0) return
        
        if (wallpaperProcessesRunning()) {
            console.log("Wallpaper switch in progress, ignoring extra triggers...")
            return
        }
        
        let currentPath = wallpaperModel.get(wallpaperList.currentIndex).path
        
        Appearance.currentWallpaperPreview = "file://" + currentPath;
        root.pendingOverviewPath = currentPath

        generateColorsProcess.command = [
            "bash", Paths.scriptPath("theme", "generate_quickshell_colors.sh"),
            "--image", currentPath,
            "--scheme", Appearance.matugenScheme,
            "--mode", Appearance.effectiveMatugenMode
        ]
        generateColorsProcess.running = true

        setWallpaperProcess.command = [
            "awww", "img", currentPath,
            "--transition-type", "any",
            "--transition-duration", "3",
            "--transition-fps", "60",
            "--transition-bezier", ".43,1.19,1,.4"
        ]
        setWallpaperProcess.running = true
    }

    Process {
        id: setWallpaperProcess
        onExited: {
            if (root.pendingOverviewPath === "")
                return

            overviewProcess.command = ["bash", Paths.scriptPath("system", "overview.sh"), root.pendingOverviewPath]
            overviewProcess.running = true
        }
    }

    Process {
        id: generateColorsProcess
        onExited: Appearance.reloadColors()
    }

    Process {
        id: overviewProcess
        onExited: root.pendingOverviewPath = ""
    }
}
