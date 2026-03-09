import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects // <-- 必须引入特效库
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root
    signal wallpaperChanged()

    property string wallpaperPath: Quickshell.env("HOME") + "/.config/wallpaper"
    property var allWallpapers: [] // 缓存数组，用于搜索过滤
    
    ListModel { id: wallpaperModel }

    Process {
        id: scanWallpapers
        command: ["bash", "-c", "find " + root.wallpaperPath + " -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (file) => {
                var f = file.trim();
                if (f !== "") {
                    root.allWallpapers.push(f);
                    wallpaperModel.append({ path: f });
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            // 把原来的 view.forceActiveFocus() 改成下面这行：
            searchInput.forceActiveFocus(); 
            
            if (wallpaperModel.count === 0 && root.allWallpapers.length === 0) scanWallpapers.running = true;
            searchInput.text = ""; // 每次打开清空搜索
        }
    }

    // 根据搜索词过滤壁纸
    function filterWallpapers(query) {
        wallpaperModel.clear();
        var q = query.toLowerCase();
        for (var i = 0; i < root.allWallpapers.length; i++) {
            var path = root.allWallpapers[i];
            var name = path.substring(path.lastIndexOf('/') + 1).toLowerCase();
            if (name.includes(q)) {
                wallpaperModel.append({ path: path });
            }
        }
        view.currentIndex = 0;
    }

    // ============================================================
    // PathView 实现无限轮盘
    // ============================================================
    PathView {
        id: view
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: searchContainer.top // 底部留给搜索框
        
        pathItemCount: 5
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        snapMode: PathView.SnapToItem
        dragMargin: view.height
        
        model: wallpaperModel
        focus: true
        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()
        Keys.onReturnPressed: applyWallpaper()
        Keys.onEnterPressed: applyWallpaper()

        path: Path {
            startX: -81
            startY: view.height / 2
            PathLine { x: view.width + 81; y: view.height / 2 }
        }

        delegate: Item {
            width: 162; height: 180 // 增加高度以容纳文字
            property bool isCurrent: PathView.isCurrentItem
            
            // 缩放和动画的统一外层
            Item {
                anchors.centerIn: parent
                width: 140; height: 110
                scale: isCurrent ? 1.6 : 0.9
                opacity: isCurrent ? 1.0 : 0.5
                z: isCurrent ? 100 : 0
                
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 250 } }

                // ==========================================
                // DayNightSwitch 同款的层级遮罩写法
                // ==========================================
                Item {
                    id: imgRect
                    width: 140; height: 78
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imgRect.width; height: imgRect.height
                            radius: 8 // 因为有1.6倍放大，8*1.6 实际渲染出约 12.8 的圆角
                            visible: false
                        }
                    }

                    // 垫一个背景色，防止图片加载时透明
                    Rectangle {
                        anchors.fill: parent
                        color: Colorscheme.background
                    }

                    Image {
                        anchors.fill: parent
                        source: "file://" + model.path
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 320 
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                    }
                }

                // 文件名文字
                Text {
                    anchors.top: imgRect.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    // 提取文件名并去除后缀
                    text: model.path.substring(model.path.lastIndexOf('/') + 1).split('.')[0]
                    color: "white" 
                    font.pixelSize: 10 // 字体稍小，配合 1.6 倍的 scale
                    font.weight: isCurrent ? Font.Bold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            TapHandler {
                onTapped: {
                    view.currentIndex = index
                    if (view.currentIndex === index) root.applyWallpaper()
                }
            }
        }
    }

    // ============================================================
    // 搜索框区域
    // ============================================================
    Rectangle {
        id: searchContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 15
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.9 // 占总宽 90%
        height: 36
        radius: 8
        color: Qt.rgba(0.1, 0.1, 0.1, 0.8) // 半透明深色，可换成 Colorscheme.surface

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                text: "🔍" 
                color: "gray"
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 14
            }

            TextInput {
                id: searchInput
                width: parent.width - 40
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                font.pixelSize: 14
                selectionColor: "gray"
                
                Text {
                    text: ">wallpaper"
                    color: "gray"
                    visible: !searchInput.text && !searchInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                }

                onTextChanged: root.filterWallpapers(text)

                // 1. 焦点在输入框时直接回车应用壁纸 [cite: 447]
                Keys.onReturnPressed: root.applyWallpaper()
                Keys.onEnterPressed: root.applyWallpaper()

                // 2. 解决焦点冲突：引入上下键来切换壁纸
                Keys.onUpPressed: (event) => { view.decrementCurrentIndex(); event.accepted = true }
                Keys.onDownPressed: (event) => { view.incrementCurrentIndex(); event.accepted = true }

                // 3. 智能左右键逻辑：当搜索框为空，或光标在最边缘时，左右键切换壁纸，否则正常移动光标
                Keys.onLeftPressed: (event) => {
                    if (text.length === 0 || cursorPosition === 0) {
                        view.decrementCurrentIndex();
                        event.accepted = true;
                    }
                }
                Keys.onRightPressed: (event) => {
                    if (text.length === 0 || cursorPosition === text.length) {
                        view.incrementCurrentIndex();
                        event.accepted = true;
                    }
                }
            }
        }
        
        // 清空按钮 (x)
        MouseArea {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 30
            cursorShape: Qt.PointingHandCursor
            visible: searchInput.text !== ""
            
            Text {
                text: "✕"
                color: "gray"
                anchors.centerIn: parent
                font.pixelSize: 12
            }
            onClicked: {
                searchInput.text = ""
                searchInput.forceActiveFocus()
            }
        }
    }

    function applyWallpaper() {
        if (wallpaperModel.count === 0) return;
        var currentPath = wallpaperModel.get(view.currentIndex).path;
        var home = Quickshell.env("HOME");
        
        var swwwCmd = "swww img \"" + currentPath + "\" " +
                  "--transition-type \"any\" " +
                  "--transition-duration 3 " +
                  "--transition-fps 60 " +
                  "--transition-bezier .43,1.19,1,.4";
                  
        var matugenCmd = "matugen image \"" + currentPath + "\"";
        var overviewCmd = "bash " + home + "/.config/quickshell/scripts/overview.sh \"" + currentPath + "\"";
        
        var combinedCmd = swwwCmd + " ; " + matugenCmd + " ; " + overviewCmd + " &";
        runScript.command = ["bash", "-c", combinedCmd];
        runScript.running = true;
        
        root.wallpaperChanged();
    }

    Process { id: runScript }
}
