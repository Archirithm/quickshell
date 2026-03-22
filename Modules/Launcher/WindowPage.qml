import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config
import qs.Services 

Item {
    id: root
    
    signal requestCloseLauncher()

    ListModel { id: filteredWindows }
    
    function decrementCurrentIndex() { windowsList.decrementCurrentIndex() }
    function incrementCurrentIndex() { windowsList.incrementCurrentIndex() }
    function forceSearchFocus() { searchBox.forceActiveFocus() }

    // ==========================================
    // 正则清洗器：去除前后缀，保留原本的首字母大小写
    // ==========================================
    function cleanAppName(rawName, isAppId) {
        if (!rawName) return ""
        let name = rawName

        if (isAppId) {
            // 切掉域名前缀 (如 org.kde.dolphin -> dolphin)
            name = name.replace(/^([a-z0-9\-]+\.)+/gi, "")
            // 切掉 .desktop 后缀
            name = name.replace(/\.desktop$/gi, "")
            // 注意：已移除首字母强制大写的逻辑，保留原生大小写
        } else {
            // 切掉窗口标题后面的浏览器/编辑器后缀尾巴
            name = name.replace(/\s*[-—|]\s*(Mozilla Firefox|Google Chrome|Chromium|Brave|Edge|Vivaldi|Visual Studio Code|Kate|KWrite).*$/gi, "")
        }

        return name
    }

    function search(text) {
        filteredWindows.clear()
        let q = text.toLowerCase()
        
        for(let i = 0; i < Niri.windows.count; i++) {
            let item = Niri.windows.get(i)
            if(item.title.toLowerCase().includes(q) || item.appId.toLowerCase().includes(q)) {
                
                filteredWindows.append({
                    title: item.title,
                    appId: item.appId, 
                    winId: item.winId
                })
            }
        }
        if (windowsList.currentIndex >= filteredWindows.count) {
            windowsList.currentIndex = 0
        }
    }

    Connections {
        target: Niri
        function onWindowsUpdated() {
            if (root.visible) {
                root.search(searchBox.text)
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            Niri.reloadWindows()
            searchBox.text = ""
            search("")
        }
    }

    function highlightText(fullText, query) {
        let safeText = fullText.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        if (!query || query.trim() === "") return safeText
        let escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        let regex = new RegExp("(" + escapedQuery + ")", "gi")
        return safeText.replace(regex, "<u><b>$1</b></u>")
    }

    TextInput {
        id: searchBox
        x: -1000 
        y: -1000
        width: 0
        height: 0
        opacity: 0
        visible: true 
        
        onTextChanged: {
            root.search(text)
            windowsList.currentIndex = 0 
        }
        Keys.onReturnPressed: (event) => { focusSelectedWindow(); event.accepted = true }
        Keys.onEnterPressed: (event) => { focusSelectedWindow(); event.accepted = true }
        Keys.onUpPressed: (event) => { windowsList.decrementCurrentIndex(); event.accepted = true }
        Keys.onDownPressed: (event) => { windowsList.incrementCurrentIndex(); event.accepted = true }
    }

    Item {
        anchors.fill: parent

        Text {
            anchors.centerIn: parent 
            text: "No windows opened."
            color: Colorscheme.on_surface_variant
            font.pixelSize: 16
            visible: filteredWindows.count === 0
        }

        // ==========================================
        // 统一高度和样式的 ListView
        // ==========================================
        ListView {
            id: windowsList
            width: parent.width
            height: 504 
            anchors.verticalCenter: parent.verticalCenter 
            clip: true
            
            model: filteredWindows
            
            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.StrictlyEnforceRange 
            preferredHighlightBegin: 0
            preferredHighlightEnd: height - 56 
            
            highlight: Rectangle { 
                color: Colorscheme.primary
                radius: 12 
            }
            highlightMoveDuration: 0 

            delegate: Item {
                id: delegateItem 
                width: ListView.view.width
                height: 56

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        windowsList.currentIndex = index
                        focusSelectedWindow()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 16
                    spacing: 16

                    Item {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36

                        Image {
                            id: windowIcon
                            anchors.fill: parent
                            sourceSize.width: 64
                            sourceSize.height: 64
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            
                            property int attempt: 0
                            
                            property string rawId: model.appId || ""
                            property string lowerId: rawId.toLowerCase()

                            // 5 发子弹智能图标匹配阵列
                            property var candidates: [
                                "/usr/share/icons/Tela-circle-dracula/scalable/apps/" + lowerId + ".svg", 
                                "/usr/share/icons/Tela-circle-dracula/scalable/apps/" + rawId + ".svg",   
                                "image://icon/" + rawId,                                                  
                                "image://icon/" + lowerId,                                                
                                "image://icon/application-x-executable"                                   
                            ]
                            
                            source: {
                                let ic = candidates[attempt]
                                if (ic.startsWith("/")) return "file://" + ic
                                return ic
                            }
                            
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    if (attempt < candidates.length - 1) {
                                        attempt++ 
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: root.highlightText(root.cleanAppName(model.title, false), searchBox.text)
                        textFormat: Text.StyledText 
                        color: delegateItem.ListView.isCurrentItem ? Colorscheme.on_primary : Colorscheme.on_surface
                        font.pixelSize: 16
                        font.bold: false 
                        elide: Text.ElideRight 
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.highlightText(root.cleanAppName(model.appId, true), searchBox.text)
                        textFormat: Text.StyledText 
                        color: delegateItem.ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.7) : Colorscheme.on_surface_variant
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }
        }
    }

    function focusSelectedWindow() {
        if (filteredWindows.count > 0 && windowsList.currentIndex >= 0) {
            let winId = filteredWindows.get(windowsList.currentIndex).winId
            focusProcess.command = ["niri", "msg", "action", "focus-window", "--id", winId]
            focusProcess.running = true
        }
    }
    
    Process { 
        id: focusProcess
        onExited: {
            running = false 
            // root.requestCloseLauncher()
        }
    }
}
