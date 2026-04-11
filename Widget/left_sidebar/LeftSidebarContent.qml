import QtQuick
import QtQuick.Layouts
import qs.config
import qs.Widget.common

Item {
    id: root
    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: theme.padding
        spacing: theme.padding

        RowLayout {
            Layout.fillWidth: true
            
            Layout.preferredHeight: 50 
            Layout.maximumHeight: 50 
            Layout.alignment: Qt.AlignTop
            
            spacing: 15

            Repeater {
                // 【核心修改】：将 label 替换为纯英文/缩写
                model: [
                    { id: "info", icon: "info", label: "Info" },
                    { id: "sys", icon: "memory", label: "System" },
                    { id: "weather", icon: "cloud", label: "Weather" }
                ]
                
                delegate: Item {
                    id: tabBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true 
                    
                    property bool isActive: WidgetState.leftSidebarView === modelData.id
                    property bool isHovered: hoverArea.containsMouse
                    
                    property color contentColor: isActive ? "white" : (isHovered ? "white" : "#888888")

                    Column {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -4
                        spacing: 4 
                        
                        Text {
                            text: modelData.icon
                            font.family: "Material Symbols Outlined" 
                            font.pixelSize: 20 
                            color: tabBtn.contentColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        
                        Text {
                            text: modelData.label
                            font.family: "LXGW WenKai GB Screen"
                            font.bold: tabBtn.isActive
                            font.pixelSize: 13 
                            color: tabBtn.contentColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: tabBtn.isActive ? 40 : 0
                        height: 3
                        radius: 1.5
                        color: "white" 
                        opacity: tabBtn.isActive ? 1.0 : 0.0
                        
                        Behavior on width { 
                            NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.5 } 
                        }
                        Behavior on opacity { 
                            NumberAnimation { duration: 200 } 
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WidgetState.leftSidebarView = modelData.id
                    }
                }
            }
        }

        // ============================================================
        // 2. 侧边栏内容区
        // ============================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true 
            color: theme.surface
            radius: theme.radius

            InfoView {
                anchors.fill: parent
                visible: WidgetState.leftSidebarView === "info"
            }

            SystemView {
                anchors.fill: parent
                visible: WidgetState.leftSidebarView === "sys"
            }

            WeatherView {
                anchors.fill: parent
                visible: WidgetState.leftSidebarView === "weather"
            }
        }
    }
}
