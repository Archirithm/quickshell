import QtQuick
import QtQuick.Layouts
import qs.config 

Item {
    id: root

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20 // 整体边距稍微缩小，留出更多内部空间
        spacing: 15
        
        // 1. 左侧区域 (权重 60%)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 60 
            spacing: 15
            
            // 1.1 左上半部分：日历 + 系统/头像 (高度权重 60%，使其接近正方形)
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 60
                spacing: 15

                CalendarWidget {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                SysInfoWidget {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            // 1.2 左下半部分：扁平化的天气 (高度权重 40%)
            WeatherWidget {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 40 
            }
        }
        
        // 2. 右侧区域：经典的细长长方形课表 (权重 40%)
        ScheduleWidget {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 40 
        }
    }
}
