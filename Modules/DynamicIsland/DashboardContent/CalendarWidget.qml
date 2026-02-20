import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config 

Rectangle {
    id: root
    
    // 使用主题色替代硬编码
    color: Colorsheme.surface_container_high 
    radius: 16 // 与其他组件对齐

    ListModel { id: calendarModel }
    property string currentMonthName: ""
    property string currentYear: ""
    property int todayDate: new Date().getDate()

    function generateCalendar() {
        calendarModel.clear();
        let now = new Date();
        let year = now.getFullYear();
        let month = now.getMonth();
        let monthNames = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"];
        root.currentMonthName = monthNames[month];
        root.currentYear = year.toString();
        
        let startDay = (new Date(year, month, 1).getDay() + 6) % 7; 
        let daysInMonth = new Date(year, month + 1, 0).getDate();
        let daysInPrevMonth = new Date(year, month, 0).getDate();

        // 填充上个月的尾巴
        for (let i = 0; i < startDay; i++) {
            let isWeekend = (i % 7 === 5 || i % 7 === 6);
            calendarModel.append({ "dayText": daysInPrevMonth - startDay + 1 + i, "isCurrentMonth": false, "isToday": false, "isWeekend": isWeekend });
        }
        // 填充当月
        for (let i = 1; i <= daysInMonth; i++) {
            let currentDayOfWeek = (startDay + i - 1) % 7;
            let isWeekend = (currentDayOfWeek === 5 || currentDayOfWeek === 6);
            calendarModel.append({ "dayText": i, "isCurrentMonth": true, "isToday": (i === root.todayDate), "isWeekend": isWeekend });
        }
        // 填充下个月的开头
        let remaining = 42 - calendarModel.count;
        for (let i = 1; i <= remaining; i++) {
            let currentDayOfWeek = (startDay + daysInMonth + i - 1) % 7;
            let isWeekend = (currentDayOfWeek === 5 || currentDayOfWeek === 6);
            calendarModel.append({ "dayText": i, "isCurrentMonth": false, "isToday": false, "isWeekend": isWeekend });
        }
    }

    Component.onCompleted: generateCalendar()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 // 边距稍微收紧，让内容更舒展
        spacing: 12
        
        // 1. 顶部：月份与年份
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            
            Text {
                text: root.currentMonthName
                color: Colorsheme.on_surface
                font.family: Sizes.fontFamily
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                text: root.currentYear + "年"
                color: Colorsheme.on_surface_variant // 年份稍暗，形成层次感
                font.family: Sizes.fontFamily
                font.pixelSize: 18
                font.bold: true
            }
            Item { Layout.fillWidth: true } // 占位符，把文字推到左边
        }
        
        // 2. 星期表头
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: ["一", "二", "三", "四", "五", "六", "日"]
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 20
                    Text { 
                        anchors.centerIn: parent
                        text: modelData
                        // 周末颜色变暗，工作日高亮
                        color: (index === 5 || index === 6) ? Colorsheme.outline : Colorsheme.on_surface_variant
                        font.family: Sizes.fontFamily
                        font.pixelSize: 12
                        font.bold: true 
                    }
                }
            }
        }
        
        // 3. 日期网格
        GridLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 7; columnSpacing: 0; rowSpacing: 4 // 行距精调，避免过散
            Repeater {
                model: calendarModel
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    
                    // 当天的高亮背景圆圈
                    Rectangle {
                        width: 28; height: 28; radius: 14 // 稍微放大一点点
                        anchors.centerIn: parent
                        color: model.isToday ? Colorsheme.primary : "transparent"
                    }
                    
                    // 日期文字
                    Text {
                        anchors.centerIn: parent
                        text: model.dayText
                        font.family: Sizes.fontFamily
                        font.pixelSize: 13
                        font.bold: model.isToday
                        // 精致的颜色判断逻辑
                        color: {
                            if (model.isToday) return Colorsheme.on_primary; // 当天：使用高亮底色上的文字颜色
                            if (!model.isCurrentMonth) return Colorsheme.outline_variant; // 非本月：极其暗淡
                            if (model.isWeekend) return Colorsheme.on_surface_variant; // 本月周末：稍微暗淡
                            return Colorsheme.on_surface; // 本月工作日：正常高亮
                        }
                    }
                }
            }
        }
    }
}
