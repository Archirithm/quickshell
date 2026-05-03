import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root
    signal wallpaperChanged()

    property string wallpaperPath: Quickshell.env("HOME") + "/.config/wallpaper"
    property var allWallpapers: [] 
    
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
            searchInput.forceActiveFocus();
            if (wallpaperModel.count === 0 && root.allWallpapers.length === 0) scanWallpapers.running = true;
            searchInput.text = "";
        }
    }

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
        anchors.bottom: searchContainer.top 
        
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
            startX: 20
            startY: view.height / 2 + 15 
            PathLine { 
                x: view.width - 20
                y: view.height / 2 + 15 
            }
        }

        delegate: Item {
            id: delegateRoot
            width: 200  
            height: 240 
            
            z: PathView.isCurrentItem ? 100 : 0
            property bool isCurrent: PathView.isCurrentItem

            Item {
                id: imageWrapper
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -20 
                
                width: 160  
                height: 90
                
                scale: isCurrent ? 1.5 : 1.0 
                opacity: isCurrent ? 1.0 : 0.6 
                
                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "black"
                    visible: isCurrent 
                    opacity: isCurrent ? 1.0 : 0.0
                    
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        radius: 20
                        samples: 41
                        color: Qt.rgba(0, 0, 0, 0.6)
                        verticalOffset: 6
                    }
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                Item {
                    id: imgRect
                    anchors.fill: parent

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imgRect.width
                            height: imgRect.height
                            radius: 8 
                            visible: false
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Appearance.colors.colLayer0
                    }

                    Image {
                        anchors.fill: parent
                        source: "file://" + model.path
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 512
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                    }
                }
            }

            Text {
                anchors.top: imageWrapper.bottom
                anchors.topMargin: isCurrent ? 30 : 8 
                Behavior on anchors.topMargin { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                
                text: model.path.substring(model.path.lastIndexOf('/') + 1).split('.')[0]
                color: "white" 
                font.pixelSize: 11
                font.weight: isCurrent ? Font.Bold : Font.Normal
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        height: 40
        radius: 10
        color: Qt.rgba(0.12, 0.12, 0.12, 0.85)

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

                Keys.onReturnPressed: root.applyWallpaper()
                Keys.onEnterPressed: root.applyWallpaper()

                Keys.onUpPressed: (event) => { view.decrementCurrentIndex(); event.accepted = true }
                Keys.onDownPressed: (event) => { view.incrementCurrentIndex(); event.accepted = true }

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
    
    // ============================================================
    // 【核心修改】 应用壁纸并执行额外脚本
    // ============================================================
    function applyWallpaper() {
        if (wallpaperModel.count === 0) return;
        let currentPath = wallpaperModel.get(view.currentIndex).path;
        let home = Quickshell.env("HOME");
        Appearance.currentWallpaperPreview = "file://" + currentPath;
        
        // 1. awww 命令
        let awwwCmd = "awww img \"" + currentPath + "\" " +
                  "--transition-type \"any\" " +
                  "--transition-duration 3 " +
                  "--transition-fps 60 " +
                  "--transition-bezier .43,1.19,1,.4";

        // 2. Quickshell 专用 matugen 颜色命令
        let matugenCmd = "bash \"" + home + "/.config/quickshell/scripts/generate_quickshell_colors.sh\" " +
                         "--image \"" + currentPath + "\" " +
                         "--scheme \"" + Appearance.matugenScheme + "\"";

        // 3. overview 脚本命令
        let overviewCmd = "bash " + home + "/.config/quickshell/scripts/overview.sh \"" + currentPath + "\"";

        // 注意这里把 swwwCmd 换成了 awwwCmd
        let combinedCmd = awwwCmd + " ; " + matugenCmd + " ; " + overviewCmd + " &";

        runScript.command = ["bash", "-c", combinedCmd];
        runScript.running = true;
        
        root.wallpaperChanged();
    }

    Process { id: runScript }
}
