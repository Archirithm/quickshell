import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.config 

Rectangle {
    id: root
    color: Colorsheme.surface_container_high
    radius: 16 // 与其他卡片对齐

    property var scheduleItems: []
    property var timeHeaders: []
    property var headers: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    property int timeW: 45      
    property int cellW: 55      
    property int cellH: 55      
    property int headerH: 25    
    property int gridSpacing: 8 

    // 完美融入 Colorsheme 的课程卡片底色
    function getColorForCourse(courseName) {
        if (!courseName || courseName.trim() === "") return "transparent";
        let colors = [
            Colorsheme.primary_container, 
            Colorsheme.secondary_container, 
            Colorsheme.tertiary_container, 
            Colorsheme.surface_variant, 
            "#4a2b29", 
            "#5c4524"
        ];
        let hash = 0;
        for (let i = 0; i < courseName.length; i++) hash = courseName.charCodeAt(i) + ((hash << 5) - hash);
        return colors[Math.abs(hash) % colors.length];
    }

    // 配合底色的课程文字颜色
    function getTextColorForCourse(courseName) {
        if (!courseName || courseName.trim() === "") return "transparent";
        let colors = [
            Colorsheme.on_primary_container, 
            Colorsheme.on_secondary_container, 
            Colorsheme.on_tertiary_container, 
            Colorsheme.on_surface_variant, 
            "#ffdad5", 
            "#d8c2bf"
        ];
        let hash = 0;
        for (let i = 0; i < courseName.length; i++) hash = courseName.charCodeAt(i) + ((hash << 5) - hash);
        return colors[Math.abs(hash) % colors.length];
    }

    // ==========================================
    // 带有安全缓冲区的暴力原生读取
    // ==========================================
    property string jsonBuffer: ""

    Process {
        id: scheduleLoader
        command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/schedule.json"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                // 将每一行拼接起来，不急着解析
                root.jsonBuffer += data;
            }
        }
        onExited: {
            // 当 cat 命令执行完毕后，一次性解析完整的 JSON
            try {
                if (root.jsonBuffer.trim() !== "") {
                    let parsed = JSON.parse(root.jsonBuffer);
                    root.timeHeaders = parsed.timeHeaders || [];
                    root.scheduleItems = parsed.scheduleItems || [];
                }
            } catch(e) { 
                console.log("课表 JSON 解析错误:", e); 
            }
            // 清空缓冲区，为下一次刷新做准备
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

    Item {
        anchors.fill: parent
        anchors.margins: 12

        // 【象限 1：左上角 (完全冻结)】
        Rectangle {
            x: 0; y: 0; width: timeW; height: headerH
            color: "transparent"
            Text {
                anchors.centerIn: parent
                text: "Time"
                color: Colorsheme.on_surface_variant
                font.pixelSize: 11; font.bold: true; font.family: Sizes.fontFamily
            }
            
            // 点击 Time 依然可以手动刷新！
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    scheduleLoader.running = false;
                    scheduleLoader.running = true;
                }
            }
        }

        // 【象限 2：顶部表头】
        Item {
            x: timeW + gridSpacing
            y: 0
            width: parent.width - x; height: headerH
            clip: true
            Row {
                x: -scheduleScroll.contentItem.contentX 
                spacing: gridSpacing
                Repeater {
                    model: root.headers
                    Rectangle {
                        width: cellW; height: headerH; color: "transparent"
                        Text { anchors.centerIn: parent; text: modelData; color: Colorsheme.on_surface_variant; font.pixelSize: 11; font.bold: true; font.family: Sizes.fontFamily }
                    }
                }
            }
        }

        // 【象限 3：左侧时间列】
        Item {
            x: 0
            y: headerH + gridSpacing
            width: timeW; height: parent.height - y
            clip: true
            Column {
                y: -scheduleScroll.contentItem.contentY 
                spacing: gridSpacing
                Repeater {
                    model: root.timeHeaders
                    Rectangle {
                        width: timeW; height: cellH; color: "transparent"
                        Text { 
                            anchors.centerIn: parent
                            text: modelData.replace(" - ", "\n") 
                            color: Colorsheme.outline
                            font.pixelSize: 9; font.family: Sizes.fontFamily
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        // 【象限 4：主体课程网格】
        ScrollView {
            id: scheduleScroll
            x: timeW + gridSpacing
            y: headerH + gridSpacing
            width: parent.width - x
            height: parent.height - y
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            GridLayout {
                width: implicitWidth
                height: implicitHeight
                columns: 7 
                rowSpacing: gridSpacing; columnSpacing: gridSpacing

                Repeater {
                    model: root.scheduleItems
                    Rectangle {
                        Layout.row: modelData.row; Layout.column: modelData.col; Layout.rowSpan: modelData.rowSpan
                        Layout.preferredWidth: cellW; Layout.preferredHeight: cellH
                        Layout.fillWidth: true; Layout.fillHeight: true
                        radius: 8
                        color: modelData.isEmpty ? "transparent" : root.getColorForCourse(modelData.text)
                        border.width: modelData.isEmpty ? 1 : 0
                        border.color: Colorsheme.outline_variant

                        Text {
                            anchors.fill: parent; anchors.margins: 4
                            text: modelData.text.replace(" (", "\n(").replace("（", "\n（")
                            color: root.getTextColorForCourse(modelData.text)
                            font.pixelSize: 10; font.bold: !modelData.isEmpty; font.family: Sizes.fontFamily
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap; elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. 右键拖拽与锁死判定
        // ==========================================
        MouseArea {
            x: timeW + gridSpacing; y: headerH + gridSpacing
            width: parent.width - x; height: parent.height - y
            acceptedButtons: Qt.RightButton 
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

            property real startX: 0
            property real startY: 0
            property real startContentX: 0
            property real startContentY: 0

            onPressed: (mouse) => {
                startX = mouse.x
                startY = mouse.y
                startContentX = scheduleScroll.contentItem.contentX
                startContentY = scheduleScroll.contentItem.contentY
            }

            onPositionChanged: (mouse) => {
                if (pressed) {
                    let flickable = scheduleScroll.contentItem;
                    let targetX = startContentX - (mouse.x - startX);
                    let targetY = startContentY - (mouse.y - startY);
                    
                    let maxX = Math.max(0, flickable.contentWidth - scheduleScroll.width);
                    let maxY = Math.max(0, flickable.contentHeight - scheduleScroll.height);
                    
                    flickable.contentX = Math.max(0, Math.min(targetX, maxX));
                    flickable.contentY = Math.max(0, Math.min(targetY, maxY));
                }
            }
        }
    }
}
