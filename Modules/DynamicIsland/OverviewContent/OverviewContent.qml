import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services

Item {
    id: root
    signal closeRequested() 

    implicitWidth: 860 
    implicitHeight: 520 

    property int activeSliderIndex: 0 

    // ============================================================
    // 【挖孔浮动卡片组件】
    // 外层透明区域对齐 DynamicIsland.qml 中的物理挖孔，
    // 内层纯色卡片悬浮在洞内，四周保留桌面透视边。
    // ============================================================
    component FloatingHoleCard : Item {
        id: cardRoot
        default property alias content: innerContainer.data
        property real floatMargin: 10
        property real contentMargin: 14

        Rectangle {
            id: cardBackground
            anchors.fill: parent
            anchors.margins: cardRoot.floatMargin
            radius: 20
            color: Appearance.colors.colLayer0
            border.width: 0
            border.color: "transparent"
        }

        Item {
            id: innerContainer
            anchors.fill: cardBackground
            anchors.margins: cardRoot.contentMargin
        }
    }

    component ExpandableVertSlider : Item {
        id: sliderCol
        property int sliderIndex: 0 
        property string icon: ""
        property real sliderValue: 0.5
        property bool expanded: false
        signal sliderMoved(real val)

        property real expandProgress: expanded ? 1.0 : 0.0
        Behavior on expandProgress { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

        width: 48
        implicitHeight: 48 + (128 * expandProgress)

        Rectangle {
            width: 48; height: 48; radius: 24
            color: sliderCol.expanded ? Appearance.colors.colPrimary : Appearance.colors.colLayer4
            Behavior on color { ColorAnimation { duration: 250 } }
            Text {
                anchors.centerIn: parent; text: sliderCol.icon; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 18
                color: sliderCol.expanded ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
            }
            MouseArea { 
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                onClicked: root.activeSliderIndex = (root.activeSliderIndex === sliderCol.sliderIndex ? -1 : sliderCol.sliderIndex) 
            }
        }

        Item {
            y: 48 + (8 * sliderCol.expandProgress)
            width: 48; height: 120 * sliderCol.expandProgress; opacity: sliderCol.expandProgress
            
            Item {
                anchors.centerIn: parent; width: 16; height: parent.height - 4; clip: true
                Rectangle {
                    anchors.fill: parent; radius: 8; color: Appearance.colors.colLayer0
                    Rectangle {
                        x: parent.width / 2 - width / 2; y: 4; width: 4; height: parent.height - 8; radius: 2; color: Appearance.colors.colLayer4
                        Rectangle {
                            width: parent.width; height: (1.0 - vSlider.visualPosition) * parent.height; y: vSlider.visualPosition * parent.height
                            radius: 2; color: Appearance.colors.colPrimary
                        }
                    }
                }
            }

            Slider {
                id: vSlider
                orientation: Qt.Vertical; anchors.fill: parent; anchors.margins: 4
                value: sliderCol.sliderValue; hoverEnabled: true; background: Item {} 
                onMoved: sliderCol.sliderMoved(value)

                handle: Rectangle {
                    x: vSlider.leftPadding + vSlider.availableWidth / 2 - width / 2
                    y: vSlider.topPadding + vSlider.visualPosition * (vSlider.availableHeight - height)
                    width: 12; height: 12; radius: 6; color: Appearance.colors.colPrimary
                    Item {
                        anchors.left: parent.right; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 36; visible: vSlider.pressed || vSlider.hovered; opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Rectangle { anchors.fill: parent; radius: 18; color: Appearance.colors.colPrimaryContainer }
                        Rectangle { 
                            width: 12; height: 12; radius: 2; color: Appearance.colors.colPrimaryContainer; rotation: 45
                            anchors.left: parent.left; anchors.leftMargin: -4; anchors.verticalCenter: parent.verticalCenter; z: -1
                        }
                        Text { 
                            anchors.centerIn: parent; text: Math.round(vSlider.value * 100); color: Appearance.colors.colOnPrimaryContainer
                            font.pixelSize: 14; font.bold: true; font.family: "JetBrainsMono Nerd Font" 
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 32 
        spacing: 24 

        // 第一列：滑块
        ColumnLayout {
            z: 100; Layout.preferredWidth: 48; Layout.fillHeight: true; Layout.alignment: Qt.AlignTop; spacing: 12
            ExpandableVertSlider { sliderIndex: 0; icon: ""; expanded: root.activeSliderIndex === 0; sliderValue: Volume.sinkVolume; onSliderMoved: (val) => Volume.setSinkVolume(val) } 
            ExpandableVertSlider { sliderIndex: 1; icon: ""; expanded: root.activeSliderIndex === 1; sliderValue: Volume.sourceVolume; onSliderMoved: (val) => Volume.setSourceVolume(val) }
            ExpandableVertSlider { sliderIndex: 2; icon: ""; expanded: root.activeSliderIndex === 2; sliderValue: Brightness.brightnessValue; onSliderMoved: (val) => Brightness.setBrightness(val) }
            Item { Layout.fillHeight: true } 
        }

        // 第二列：系统信息与日历
        ColumnLayout {
            Layout.preferredWidth: 320; Layout.maximumWidth: 320; Layout.minimumWidth: 320; Layout.fillHeight: true; spacing: 20
            SysInfoWidget { Layout.fillWidth: true; Layout.preferredHeight: 115 }
            CalendarWidget { Layout.fillWidth: true; Layout.fillHeight: true }
        }

        // 第三列：日程卡片
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            FloatingHoleCard {
                width: 340
                anchors.left: parent.left
                anchors.leftMargin: 30
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                ScheduleWidget {
                    anchors.fill: parent
                }
            }
        }
    }
}
