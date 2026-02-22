import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config
Item {
    id: root
    signal wallpaperChanged()

    property string wallpaperPath: Quickshell.env("HOME") + "/.config/wallpaper"
    ListModel { id: wallpaperModel }

    Process {
        id: scanWallpapers
        command: ["bash", "-c", "find " + root.wallpaperPath + " -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (file) => {
                if (file.trim() !== "") wallpaperModel.append({ path: file.trim() });
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            view.forceActiveFocus();
            if (wallpaperModel.count === 0) scanWallpapers.running = true;
        }
    }

    // ============================================================
    // PathView 实现无限轮盘 (保持不变)
    // ============================================================
    PathView {
        id: view
        anchors.fill: parent
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
            width: 162; height: 180 
            property bool isCurrent: PathView.isCurrentItem
            Rectangle {
                width: 140; height: 78
                anchors.centerIn: parent
                color: Colorscheme.background
                scale: isCurrent ? 1.6 : 0.9
                opacity: isCurrent ? 1.0 : 0.5
                z: isCurrent ? 100 : 0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 250 } }
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
            TapHandler {
                onTapped: {
                    view.currentIndex = index
                    if (view.currentIndex === index) root.applyWallpaper()
                }
            }
        }
    }

    // ============================================================
    // 【核心修改】 应用壁纸并执行额外脚本
    // ============================================================
    function applyWallpaper() {
        if (wallpaperModel.count === 0) return;
        let currentPath = wallpaperModel.get(view.currentIndex).path;
        let home = Quickshell.env("HOME");
        
        // 1. swww 命令
        let swwwCmd = "swww img \"" + currentPath + "\" " +
                  "--transition-type \"any\" " +
                  "--transition-duration 3 " +
                  "--transition-fps 60 " +
                  "--transition-bezier .43,1.19,1,.4";

        // 2. matugen 命令
        let matugenCmd = "matugen image \"" + currentPath + "\"";

        // 3. overview 脚本命令 (显式传入路径)
        let overviewCmd = "bash " + home + "/.config/quickshell/scripts/overview.sh \"" + currentPath + "\"";

        // ★★★ 核心修改 ★★★
        // 1. 使用 ';' 代替 '&&'，确保 matugen 报错不会阻断后面的脚本
        // 2. 加上 '&' 让整个命令在后台运行，避免卡住界面
        let combinedCmd = swwwCmd + " ; " + matugenCmd + " ; " + overviewCmd + " &";
        
        runScript.command = ["bash", "-c", combinedCmd];
        runScript.running = true;
        
        root.wallpaperChanged();
    }

    // 重命名 Process，因为它现在不仅仅是运行 swww
    Process { id: runScript }
}
