import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root
    
    signal requestCloseLauncher()

    property string wallpaperPath: Quickshell.env("HOME") + "/.config/wallpaper"
    
    property string currentSelectedPreview: ""
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
        running: false // 改为默认不运行，在每次打开窗口时由 onVisibleChanged 触发
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
            getCurrentWallpaper.running = true
        }
    }

    // ==========================================
    // 渲染引擎审问器 (swww query)
    // ==========================================
    Process {
        id: getCurrentWallpaper
        command: ["bash", "-c", "swww query | awk -F 'image: ' '{print $2}' | head -n 1"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (path) => {
                let currentPath = path.trim();
                currentPath = currentPath.replace(/^"|"$/g, '');
                
                if (currentPath === "") return;

                for (let i = 0; i < wallpaperModel.count; i++) {
                    if (wallpaperModel.get(i).path === currentPath) {
                        wallpaperList.currentIndex = i;
                        root.currentSelectedPreview = "file://" + currentPath;
                        wallpaperList.positionViewAtIndex(i, ListView.Center);
                        break;
                    }
                }
            }
        }
    }

    // 每次 Launcher 显示时触发：清空列表并重新扫描，完美解决新加图片不显示的问题！
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
        color: Colorscheme.on_surface_variant
        font.pixelSize: 16
        visible: root.isLoading
    }

    ListView {
        id: wallpaperList
        width: parent.width
        height: 552 
        anchors.verticalCenter: parent.verticalCenter 
        clip: true
        model: wallpaperModel
        spacing: 6
        
        snapMode: ListView.SnapToItem         
        boundsBehavior: Flickable.StopAtBounds
        highlightRangeMode: ListView.StrictlyEnforceRange 
        preferredHighlightBegin: 0
        preferredHighlightEnd: height - 56 
        
        highlight: Rectangle { 
            color: Colorscheme.primary
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
                    color: delegateItem.ListView.isCurrentItem ? Colorscheme.on_primary : Colorscheme.on_surface
                    font.pixelSize: 16
                    font.bold: false 
                    elide: Text.ElideRight 
                    Layout.fillWidth: true
                }
            }
        }
    }

    // ==========================================
    // 脚本执行引擎：干净的拼接命令
    // ==========================================
    function applyWallpaper() {
        if (wallpaperModel.count === 0 || wallpaperList.currentIndex < 0) return
        
        // 【防抖锁】：如果当前正有脚本在后台跑，直接拦截本次重复触发！
        if (runScript.running) {
            console.log("Wallpaper switch in progress, ignoring extra triggers...")
            return
        }
        
        let currentPath = wallpaperModel.get(wallpaperList.currentIndex).path
        let home = Quickshell.env("HOME")
        
        // 【剔除冗余】：删掉了 QML 里的 cachePath 变量和 ln -sf 命令
        // 加上了 60 帧和丝滑的贝塞尔曲线
        let scriptContent = "swww img '" + currentPath + "' --transition-type any --transition-duration 3 --transition-fps 60 --transition-bezier .43,1.19,1,.4; " +
                           "matugen image '" + currentPath + "'; " +
                           "bash '" + home + "/.config/quickshell/scripts/overview.sh' '" + currentPath + "'"
                           
        runScript.command = ["bash", "-c", scriptContent]
        runScript.running = true
    }

    Process { 
        id: runScript 
        // 脚本执行完毕后，running 状态会自动恢复为 false，锁自动解开
    }
}
