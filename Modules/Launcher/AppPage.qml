import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config

import "../../JS/AppManager.js" as AppManager

Item {
    id: root
    
    signal requestCloseLauncher()

    property var filteredAppsModel: []
    

    function decrementCurrentIndex() { appsList.decrementCurrentIndex() }
    function incrementCurrentIndex() { appsList.incrementCurrentIndex() }
    function forceSearchFocus() { searchBox.forceActiveFocus() }

    function search(text) {
        filteredAppsModel = AppManager.updateFilter(text, DesktopEntries)
        appsList.currentIndex = 0
    }

    // ==========================================
    // 异步等待机制
    // ==========================================
    Timer {
        id: startupPollTimer
        interval: 50 // 频率加快到 50 毫秒（0.05秒）
        repeat: true
        running: true 
        onTriggered: {
            // 直接去底层看一眼，有数据了吗？
            if (DesktopEntries.applications.values.length > 0) {
                // 有数据了！立刻执行搜索并渲染
                root.search(searchBox.text)
                // 任务完成，当场自毁。
                running = false 
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
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
        
        onTextChanged: root.search(text)
        Keys.onReturnPressed: (event) => { runSelectedApp(); event.accepted = true }
        Keys.onEnterPressed: (event) => { runSelectedApp(); event.accepted = true }
        Keys.onUpPressed: (event) => { appsList.decrementCurrentIndex(); event.accepted = true }
        Keys.onDownPressed: (event) => { appsList.incrementCurrentIndex(); event.accepted = true }
    }

    ListView {
        id: appsList
        width: parent.width
        height: 504 
        anchors.verticalCenter: parent.verticalCenter 
        clip: true
        
        model: filteredAppsModel
        
        boundsBehavior: Flickable.StopAtBounds
        highlightRangeMode: ListView.StrictlyEnforceRange 
        preferredHighlightBegin: 0
        preferredHighlightEnd: height - 56 
        
        highlight: Rectangle { 
            color: Appearance.colors.colPrimary
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
                    appsList.currentIndex = index
                    runSelectedApp()
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

                        source: {
                            let ic = modelData.icon
                            if (!ic) return ""
                            // 因为我们在 JS 里已经拼接成 /usr 开头了，所以这里会自动加上 file://
                            if (ic.startsWith("/")) return "file://" + ic
                            if (ic.startsWith("file://") || ic.startsWith("image://")) return ic
                            return "image://icon/" + ic
                        }
                        
                        property int failCount: 0
                        
                        onStatusChanged: {
                            // 【兜底策略】：
                            if (status === Image.Error) {
                                failCount++
                                if (failCount === 1) {
                                    // 第一次失败：说明 Tela 库里没有这个 svg，我们退回让系统用原名去找
                                    source = "image://icon/" + modelData.fallbackIcon
                                } else if (failCount === 2) {
                                    // 第二次失败：系统里也彻底找不到，那就显示一个通用的执行文件图标
                                    source = "image://icon/application-x-executable"
                                }
                            }
                        }
                    }
                }

                Text {
                    text: root.highlightText(modelData.name, searchBox.text)
                    textFormat: Text.StyledText 
                    color: delegateItem.ListView.isCurrentItem ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                    font.pixelSize: 16
                    font.bold: false 
                    Layout.fillWidth: true
                }
            }
        }
    }

    function runSelectedApp() {
        if (filteredAppsModel.length > 0 && appsList.currentIndex >= 0) {
            let appData = filteredAppsModel[appsList.currentIndex]
            if (appData && appData.appObj) {
                appData.appObj.execute()
            }
            root.requestCloseLauncher() 
        }
    }
}
