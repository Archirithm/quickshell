import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config 

Item {
    id: root

    // ============================================================
    // 【纯净数据引擎】：只保留 JSON 解析与 UI 网格渲染
    // ============================================================
    property var scheduleItems: []
    property var timeHeaders: []
    property var headers: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    property int timeW: 45      
    property int cellW: 55      
    property int cellH: 55      
    property int headerH: 25    
    property int gridSpacing: 8 

    function getColorById(id) {
        let colors = [
            Colorscheme.primary_container, Colorscheme.secondary_container, 
            Colorscheme.tertiary_container, Colorscheme.surface_variant, 
            Qt.darker(Colorscheme.primary, 3.5), Qt.darker(Colorscheme.secondary, 3.5), 
            Qt.darker(Colorscheme.tertiary, 3.5), Qt.darker(Colorscheme.error, 3.5)
        ]; return colors[id % colors.length]; 
    }

    function getTextColorById(id) {
        let colors = [
            Colorscheme.on_primary_container, Colorscheme.on_secondary_container, 
            Colorscheme.on_tertiary_container, Colorscheme.on_surface_variant, 
            Colorscheme.primary, Colorscheme.secondary, 
            Colorscheme.tertiary, Colorscheme.error
        ]; return colors[id % colors.length]; 
    }

    property string jsonBuffer: ""

    Process {
        id: scheduleLoader
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/schedule.json"]
        running: false
        stdout: SplitParser { onRead: (data) => { root.jsonBuffer += data; } }
        onExited: {
            try {
                if (root.jsonBuffer.trim() !== "") {
                    let parsed = JSON.parse(root.jsonBuffer);
                    root.timeHeaders = parsed.timeHeaders || [];
                    root.scheduleItems = parsed.scheduleItems || [];
                }
            } catch(e) { console.log("课表 JSON 解析错误:", e); }
            root.jsonBuffer = "";
        }
    }

    Component.onCompleted: scheduleLoader.running = true
    onVisibleChanged: { 
        if (visible) { 
            scheduleLoader.running = false; 
            scheduleLoader.running = true; 
        } 
    }

    // ============================================================
    // 【UI 渲染层】
    // ============================================================
    Rectangle {
        x: 0; y: 0; width: root.timeW; height: root.headerH; color: "transparent"
        Text { anchors.centerIn: parent; text: "Time"; color: Colorscheme.on_surface_variant; font.pixelSize: 11; font.bold: true; font.family: Sizes.fontFamily }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { scheduleLoader.running = false; scheduleLoader.running = true; } }
    }

    Item {
        x: root.timeW + root.gridSpacing; y: 0; width: parent.width - x; height: root.headerH; clip: true
        Row {
            x: -scheduleScroll.contentItem.contentX; spacing: root.gridSpacing
            Repeater {
                model: root.headers
                Rectangle { width: root.cellW; height: root.headerH; color: "transparent"; Text { anchors.centerIn: parent; text: modelData; color: Colorscheme.on_surface_variant; font.pixelSize: 11; font.bold: true; font.family: Sizes.fontFamily } }
            }
        }
    }

    Item {
        x: 0; y: root.headerH + root.gridSpacing; width: root.timeW; height: parent.height - y; clip: true
        Column {
            y: -scheduleScroll.contentItem.contentY; spacing: root.gridSpacing
            Repeater {
                model: root.timeHeaders
                Rectangle { width: root.timeW; height: root.cellH; color: "transparent"; Text { anchors.centerIn: parent; text: modelData.replace(" - ", "\n"); color: Colorscheme.outline; font.pixelSize: 9; font.family: Sizes.fontFamily; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } }
            }
        }
    }

    ScrollView {
        id: scheduleScroll
        x: root.timeW + root.gridSpacing; y: root.headerH + root.gridSpacing
        width: parent.width - x; height: parent.height - y; clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff; ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        GridLayout {
            width: implicitWidth; height: implicitHeight; columns: 7; rowSpacing: root.gridSpacing; columnSpacing: root.gridSpacing
            Repeater {
                model: root.scheduleItems
                Rectangle {
                    Layout.row: modelData.row; Layout.column: modelData.col; Layout.rowSpan: modelData.rowSpan
                    Layout.preferredWidth: root.cellW; Layout.preferredHeight: root.cellH
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 8
                    color: modelData.isEmpty ? "transparent" : root.getColorById(modelData.colorId)
                    border.width: modelData.isEmpty ? 1 : 0; border.color: Colorscheme.outline_variant
                    Text {
                        anchors.fill: parent; anchors.margins: 4; text: modelData.text.replace(" (", "\n(").replace("（", "\n（")
                        color: root.getTextColorById(modelData.colorId)
                        font.pixelSize: 10; font.bold: !modelData.isEmpty; font.family: Sizes.fontFamily; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; wrapMode: Text.WordWrap; elide: Text.ElideRight
                    }
                }
            }
        }
    }

    MouseArea {
        x: root.timeW + root.gridSpacing; y: root.headerH + root.gridSpacing
        width: parent.width - x; height: parent.height - y
        acceptedButtons: Qt.RightButton; cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor
        property real startX: 0; property real startY: 0; property real startContentX: 0; property real startContentY: 0
        onPressed: (mouse) => { startX = mouse.x; startY = mouse.y; startContentX = scheduleScroll.contentItem.contentX; startContentY = scheduleScroll.contentItem.contentY }
        onPositionChanged: (mouse) => {
            if (pressed) {
                let flickable = scheduleScroll.contentItem;
                let targetX = startContentX - (mouse.x - startX); let targetY = startContentY - (mouse.y - startY);
                let maxX = Math.max(0, flickable.contentWidth - scheduleScroll.width); let maxY = Math.max(0, flickable.contentHeight - scheduleScroll.height);
                flickable.contentX = Math.max(0, Math.min(targetX, maxX)); flickable.contentY = Math.max(0, Math.min(targetY, maxY));
            }
        }
    }
}
