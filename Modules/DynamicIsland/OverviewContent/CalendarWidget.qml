import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config 

Rectangle {
    id: root
    color: Appearance.colors.colLayer3 
    radius: 24

    ListModel { id: calendarModel }
    
    // 状态机：记录当前显示的年月
    property int displayYear: new Date().getFullYear()
    property int displayMonth: new Date().getMonth()
    
    // 真实世界的今天
    property int todayDate: new Date().getDate()
    property int realYear: new Date().getFullYear()
    property int realMonth: new Date().getMonth()

    property var monthNames: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]

    function generateCalendar() {
        calendarModel.clear();
        
        let startDay = (new Date(displayYear, displayMonth, 1).getDay() + 6) % 7;
        let daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate();
        let daysInPrevMonth = new Date(displayYear, displayMonth, 0).getDate();
        
        let isRealCurrentMonth = (displayYear === realYear && displayMonth === realMonth);

        // 上个月的尾巴
        for (let i = 0; i < startDay; i++) {
            calendarModel.append({ "dayText": daysInPrevMonth - startDay + 1 + i, "isCurrentMonth": false, "isToday": false });
        }
        // 当月
        for (let i = 1; i <= daysInMonth; i++) {
            calendarModel.append({ "dayText": i, "isCurrentMonth": true, "isToday": (isRealCurrentMonth && i === root.todayDate) });
        }
        // 下个月的开头 (填满 42 格，保证高度绝对固定)
        let remaining = 42 - calendarModel.count;
        for (let i = 1; i <= remaining; i++) {
            calendarModel.append({ "dayText": i, "isCurrentMonth": false, "isToday": false });
        }
    }

    Component.onCompleted: generateCalendar()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        
        // 1. 顶部：独立药丸控制器
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            // 年月显示药丸
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 18
                color: Appearance.colors.colLayer4
                
                Text {
                    anchors.centerIn: parent
                    text: root.monthNames[root.displayMonth] + " " + root.displayYear
                    color: Appearance.colors.colOnSurface
                    font.family: Sizes.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                }
            }

            // 翻页按钮组件
            component NavBtn : Rectangle {
                property string iconTxt: ""
                Layout.preferredWidth: 42; Layout.preferredHeight: 36; radius: 18
                color: Appearance.colors.colLayer4
                scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 150 } }
                Text { anchors.centerIn: parent; text: iconTxt; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 14; color: Appearance.colors.colPrimary }
                signal clicked()
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
            }

            NavBtn { 
                iconTxt: "" // FontAwesome 左箭头
                onClicked: { root.displayMonth--; if (root.displayMonth < 0) { root.displayMonth = 11; root.displayYear--; } root.generateCalendar(); } 
            }
            NavBtn { 
                iconTxt: "" // FontAwesome 右箭头
                onClicked: { root.displayMonth++; if (root.displayMonth > 11) { root.displayMonth = 0; root.displayYear++; } root.generateCalendar(); } 
            }
        }
        
        // 2. 星期表头与分割线
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: ["一", "二", "三", "四", "五", "六", "日"]
                    Item {
                        Layout.fillWidth: true; Layout.preferredHeight: 20
                        Text { 
                            anchors.centerIn: parent; text: modelData
                            color: Appearance.colors.colOnSurfaceVariant; font.family: Sizes.fontFamily; font.pixelSize: 13; font.bold: true 
                        }
                    }
                }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 2; color: Appearance.colors.colLayer4; radius: 1 }
        }
        
        // 3. 日期网格
        GridLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 7; rowSpacing: 2; columnSpacing: 0
            Repeater {
                model: calendarModel
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    
                    Rectangle {
                        width: Math.min(parent.width, parent.height) * 0.9 
                        height: width; radius: width / 2
                        anchors.centerIn: parent
                        color: model.isToday ? Appearance.colors.colPrimary : "transparent"
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: model.dayText
                        font.family: Sizes.fontFamily; font.pixelSize: 14; font.bold: model.isToday
                        color: model.isToday ? Appearance.colors.colOnPrimary : (model.isCurrentMonth ? Appearance.colors.colOnSurface : Appearance.colors.colLayer2Hover)
                    }
                }
            }
        }
    }
}
