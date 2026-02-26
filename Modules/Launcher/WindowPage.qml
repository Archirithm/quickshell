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

    function search(text) {
        filteredWindows.clear()
        let q = text.toLowerCase()
        
        for(let i = 0; i < Niri.windows.count; i++) {
            let item = Niri.windows.get(i)
            if(item.title.toLowerCase().includes(q) || item.appId.toLowerCase().includes(q)) {
                filteredWindows.append(item)
            }
        }
        if (windowsList.currentIndex >= filteredWindows.count) {
            windowsList.currentIndex = 0
        }
    }

    // 【神经反射核心】：监听 Niri 发出的更新信号
    Connections {
        target: Niri
        function onWindowsUpdated() {
            // 如果 Launcher 是开着的，背景窗口发生了变化，立刻重绘搜索列表！
            if (root.visible) {
                root.search(searchBox.text)
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            // 每次打开时，顺手要一份最新数据，确保万无一失
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
        // 注意：这里的回车事件被保留作为底层备份，实际上全局的 LauncherWindow 会抢先执行
        Keys.onReturnPressed: (event) => { focusSelectedWindow(); event.accepted = true }
        Keys.onEnterPressed: (event) => { focusSelectedWindow(); event.accepted = true }
        Keys.onUpPressed: (event) => { windowsList.decrementCurrentIndex(); event.accepted = true }
        Keys.onDownPressed: (event) => { windowsList.incrementCurrentIndex(); event.accepted = true }
    }

    Text {
        anchors.centerIn: parent 
        text: "No windows opened."
        color: Colorscheme.on_surface_variant
        font.pixelSize: 16
        visible: filteredWindows.count === 0
    }

    ListView {
        id: windowsList
        width: parent.width
        height: 552 
        anchors.verticalCenter: parent.verticalCenter 
        clip: true
        model: filteredWindows
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
                        anchors.fill: parent
                        sourceSize.width: 64
                        sourceSize.height: 64
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        
                        // 极致清爽：只负责请求图标，找不到就算了，警告随它去
                        source: "image://icon/" + model.appId.toLowerCase()
                    }
                }

                Text {
                    text: root.highlightText(model.title, searchBox.text)
                    textFormat: Text.StyledText 
                    color: delegateItem.ListView.isCurrentItem ? Colorscheme.on_primary : Colorscheme.on_surface
                    font.pixelSize: 16
                    font.bold: false 
                    elide: Text.ElideRight 
                    Layout.fillWidth: true
                }

                Text {
                    text: root.highlightText(model.appId, searchBox.text)
                    textFormat: Text.StyledText 
                    color: delegateItem.ListView.isCurrentItem ? Qt.rgba(1, 1, 1, 0.7) : Colorscheme.on_surface_variant
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                }
            }
        }
    }

    function focusSelectedWindow() {
        if (filteredWindows.count > 0 && windowsList.currentIndex >= 0) {
            let winId = filteredWindows.get(windowsList.currentIndex).winId
            focusProcess.command = ["niri", "msg", "action", "focus-window", "--id", winId]
            focusProcess.running = true
            // 【已移除】：去掉了 root.requestCloseLauncher()
            // 现在按下回车，后台会自动切换焦点，但 Launcher 窗口依然为你保留！
        }
    }
    
    Process { 
        id: focusProcess
        onExited: running = false 
    }
}
