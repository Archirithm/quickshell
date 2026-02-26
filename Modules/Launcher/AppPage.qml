import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config

Item {
    id: root
    
    signal requestCloseLauncher()

    ListModel { id: allAppsModel }
    ListModel { id: filteredApps }
    property bool isLoading: true
    property var tempAppsData: ({}) 

    function decrementCurrentIndex() { appsList.decrementCurrentIndex() }
    function incrementCurrentIndex() { appsList.incrementCurrentIndex() }
    function forceSearchFocus() { searchBox.forceActiveFocus() }

    Component.onCompleted: {
        appScanner.running = true
    }

    Process {
        id: appScanner
        command: ["bash", "-c", "find /usr/share/applications ~/.local/share/applications -name '*.desktop' 2>/dev/null -exec grep -H -E '^(Name|Exec|Icon|NoDisplay)=' {} + > /tmp/qs_apps.txt"]
        running: false 
        onExited: (code, status) => {
            if (code === 0) {
                root.tempAppsData = {}
                appReader.running = true
            } else {
                root.isLoading = false
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
        line = line.trim()
        if (!line) return
        let firstColon = line.indexOf(":")
        if (firstColon === -1) return
        let path = line.substring(0, firstColon)
        let content = line.substring(firstColon + 1)
        let firstEq = content.indexOf("=")
        if (firstEq === -1) return
        let key = content.substring(0, firstEq)
        let value = content.substring(firstEq + 1)

        if (!root.tempAppsData[path]) {
            root.tempAppsData[path] = { name: "", exec: "", icon: "", noDisplay: false }
        }

        if (key === "Name" && !root.tempAppsData[path].name) root.tempAppsData[path].name = value
        else if (key === "Exec" && !root.tempAppsData[path].exec) root.tempAppsData[path].exec = value.replace(/ %[fFuUdDnNickvm].*/, "").trim()
        else if (key === "Icon" && !root.tempAppsData[path].icon) root.tempAppsData[path].icon = value
        else if (key === "NoDisplay" && value === "true") root.tempAppsData[path].noDisplay = true
    }

    function finalizeApps() {
        allAppsModel.clear()
        for (let path in root.tempAppsData) {
            let app = root.tempAppsData[path]
            if (app.name && app.exec && !app.noDisplay) {
                allAppsModel.append(app)
            }
        }
        root.isLoading = false
        root.tempAppsData = {} 
        search("") 
    }

    function search(text) {
        filteredApps.clear()
        let q = text.toLowerCase()
        let count = 0
        
        if (root.isLoading) return

        for(let i = 0; i < allAppsModel.count; i++) {
            let item = allAppsModel.get(i)
            if(item.name.toLowerCase().includes(q) || item.exec.toLowerCase().includes(q)) {
                filteredApps.append(item)
                count++
                if (count >= 40) break 
            }
        }
        appsList.currentIndex = 0
    }

    onVisibleChanged: {
        if (visible) {
            searchBox.text = ""
            if (allAppsModel.count === 0 && !root.isLoading) {
                appScanner.running = true
            } else {
                search("")
            }
        }
    }

    function highlightText(fullText, query) {
        let safeText = fullText.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        if (!query || query.trim() === "") return safeText
        let escapedQuery = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        let regex = new RegExp("(" + escapedQuery + ")", "gi")
        return safeText.replace(regex, "<u><b>$1</b></u>")
    }

    // ==========================================
    // UI 渲染层
    // ==========================================
    
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

    Text {
        anchors.centerIn: parent 
        text: "Loading applications..."
        color: Colorscheme.on_surface_variant
        font.pixelSize: 16
        visible: root.isLoading
    }

    ListView {
        id: appsList
        width: parent.width
        height: 552 
        anchors.verticalCenter: parent.verticalCenter 
        clip: true
        model: filteredApps
        spacing: 6
        
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
                            if (!model.icon) return ""
                            if (model.icon.indexOf("/") !== -1) return "file://" + model.icon
                            return "image://icon/" + model.icon
                        }
                        
                        property bool hasFallenBack: false
                        
                        onStatusChanged: {
                            if (status === Image.Error && !hasFallenBack) {
                                hasFallenBack = true
                                source = "image://icon/application-x-executable"
                            }
                        }
                    }
                }

                Text {
                    text: root.highlightText(model.name, searchBox.text)
                    textFormat: Text.StyledText 
                    color: delegateItem.ListView.isCurrentItem ? Colorscheme.on_primary : Colorscheme.on_surface
                    font.pixelSize: 16
                    font.bold: false 
                    Layout.fillWidth: true
                }
            }
        }
    }

    function runSelectedApp() {
        if (filteredApps.count > 0 && appsList.currentIndex >= 0) {
            let cmd = filteredApps.get(appsList.currentIndex).exec
            launchProcess.command = ["bash", "-c", "nohup " + cmd + " > /dev/null 2>&1 &"]
            launchProcess.running = true
            root.requestCloseLauncher() 
        }
    }
    
    Process { 
        id: launchProcess
        onExited: running = false 
    }
}
