import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root
    signal launchRequested()

    ListModel { id: allAppsModel }
    ListModel { id: filteredApps }
    property bool isLoading: true
    property var tempAppsData: ({}) 

    // ============================================================
    // 【核心策略：预加载】
    // ============================================================
    Component.onCompleted: {
        appScanner.running = true;
    }

    Process {
        id: appScanner
        command: ["bash", "-c", "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null -exec grep -H -E '^(Name|Exec|Icon|NoDisplay|Categories)=' {} + > /tmp/qs_apps.txt"]
        running: false 
        onExited: (code, status) => {
            if (code === 0) {
                root.tempAppsData = {};
                appReader.running = true;
            } else {
                root.isLoading = false;
            }
        }
    }

    Process {
        id: appReader
        command: ["cat", "/tmp/qs_apps.txt"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => root.parseSingleLine(line)
        }
        onExited: (code, status) => root.finalizeApps()
    }

    function parseSingleLine(line) {
        line = line.trim();
        if (!line) return;
        let firstColon = line.indexOf(":");
        if (firstColon === -1) return;
        let path = line.substring(0, firstColon);
        let content = line.substring(firstColon + 1);
        let firstEq = content.indexOf("=");
        if (firstEq === -1) return;
        let key = content.substring(0, firstEq);
        let value = content.substring(firstEq + 1);

        if (!root.tempAppsData[path]) {
            root.tempAppsData[path] = { name: "", exec: "", icon: "", noDisplay: false, categories: "" };
        }

        if (key === "Name" && !root.tempAppsData[path].name) root.tempAppsData[path].name = value;
        else if (key === "Exec" && !root.tempAppsData[path].exec) root.tempAppsData[path].exec = value.replace(/ %[fFuUdDnNickvm].*/, "").trim();
        else if (key === "Icon") {
            if (!root.tempAppsData[path].icon) root.tempAppsData[path].icon = value;
        }
        else if (key === "NoDisplay" && value === "true") root.tempAppsData[path].noDisplay = true;
        else if (key === "Categories") root.tempAppsData[path].categories = value;
    }

    function finalizeApps() {
        allAppsModel.clear();
        for (let path in root.tempAppsData) {
            let app = root.tempAppsData[path];
            if (app.name && app.exec) {
                if (!shouldHideApp(app)) {
                    allAppsModel.append(app);
                }
            }
        }
        root.isLoading = false;
        root.tempAppsData = {}; 
        search(""); 
    }

    function shouldHideApp(app) {
        let name = app.name.toLowerCase();
        let exec = app.exec.toLowerCase();
        if (app.noDisplay === true) return true;
        const blockedKeywords = [
            "avahi", "fcitx", "cmake", "qt v4l2", "qvidcap", "display cal",
            "lstopo", "compton", "picom", "nitrogen", "uxterm", "xterm",
            "hicolor", "xdg", "configuration", "keyboard layout", "gcr prompter",
            "viewer", "wizard", "qt5", "qt6", "manage printing",
            "rofi", "blueman", "bluetooth adapters", "btop"
        ];
        for (let i = 0; i < blockedKeywords.length; i++) {
            if (name.includes(blockedKeywords[i]) || exec.includes(blockedKeywords[i])) return true;
        }
        return false;
    }

    function search(text) {
        filteredApps.clear();
        let q = text.toLowerCase();
        let count = 0;
        
        if (root.isLoading) return;

        for(let i = 0; i < allAppsModel.count; i++) {
            let item = allAppsModel.get(i);
            if(item.name.toLowerCase().includes(q) || item.exec.toLowerCase().includes(q)) {
                filteredApps.append(item);
                count++;
                if (count >= 50) break;
            }
        }
        appsList.currentIndex = 0;
    }

    onVisibleChanged: {
        if (visible) {
            searchBox.text = "";
            searchBox.forceActiveFocus();
            
            if (allAppsModel.count === 0 && !root.isLoading) {
                appScanner.running = true;
            } else {
                search("");
            }
        }
    }

    // ============================================================
    // 【全新界面布局：Material You 风格】
    // ============================================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // 1. 搜索框
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            
            color: Colorscheme.surface_container_highest 
            radius: 24 
            
            border.width: 1
            border.color: searchBox.activeFocus ? Colorscheme.primary : "transparent"
            Behavior on border.color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12
                
                Text { 
                    text: "" 
                    color: searchBox.activeFocus ? Colorscheme.primary : Colorscheme.on_surface_variant 
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 14 
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                
                TextInput {
                    id: searchBox
                    Layout.fillWidth: true
                    color: Colorscheme.on_surface 
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    selectByMouse: true
                    activeFocusOnTab: true
                    
                    Text {
                        text: root.isLoading ? "Loading apps..." : "Search apps..."
                        color: Colorscheme.on_surface_variant
                        visible: parent.text === ""
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    onTextChanged: root.search(text)
                    Keys.onUpPressed: (event) => { appsList.decrementCurrentIndex(); event.accepted = true; }
                    Keys.onDownPressed: (event) => { appsList.incrementCurrentIndex(); event.accepted = true; }
                    Keys.onReturnPressed: (event) => { runSelectedApp(); event.accepted = true; }
                    Keys.onEnterPressed: (event) => { runSelectedApp(); event.accepted = true; }
                }
            }
        }

        // 2. 列表视图
        ListView {
            id: appsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filteredApps
            spacing: 4
            cacheBuffer: 200 
            
            highlight: Rectangle { 
                color: Colorscheme.primary_container
                radius: 12 
            }
            highlightMoveDuration: 150 

            delegate: Item {
                width: ListView.view.width
                height: 52

                TapHandler {
                    onTapped: {
                        appsList.currentIndex = index;
                        runSelectedApp();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 16
                    spacing: 16

                    // 图标容器
                    Item {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36

                        // 底层：文字头像 (没有图标时显示)
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: Colorscheme.surface_variant
                            
                            Text {
                                anchors.centerIn: parent
                                text: model.name ? model.name.charAt(0).toUpperCase() : "?"
                                color: Colorscheme.on_surface_variant
                                font.bold: true
                                font.pixelSize: 18
                            }
                        }

                        // 上层：图片
                        Image {
                            id: appIcon
                            anchors.fill: parent
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                            smooth: true

                            source: {
                                if (!model.icon) return "";
                                if (model.icon.indexOf("/") !== -1) return "file://" + model.icon;
                                return "image://icon/" + model.icon;
                            }
                            
                            visible: status === Image.Ready
                        }
                    }

                    // 应用名称
                    Text {
                        text: model.name
                        color: ListView.isCurrentItem ? Colorscheme.on_primary_container : Colorscheme.on_surface
                        font.pixelSize: 15
                        font.bold: ListView.isCurrentItem
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering 
                    }

                    // 回车提示图标
                    Text { 
                        text: "⏎"
                        color: Colorscheme.primary 
                        visible: ListView.isCurrentItem 
                        font.pixelSize: 16
                        font.bold: true
                    }
                }
            }
        }
    }

    function runSelectedApp() {
        if (filteredApps.count > 0 && appsList.currentIndex >= 0) {
            let cmd = filteredApps.get(appsList.currentIndex).exec;
            launchProcess.command = ["bash", "-c", "nohup " + cmd + " > /dev/null 2>&1 &"];
            launchProcess.running = true;
            root.launchRequested();
        }
    }
    
    Process { id: launchProcess; onExited: running = false }
}
