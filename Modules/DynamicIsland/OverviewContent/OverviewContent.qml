import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects 
import Quickshell
import qs.config
import qs.Services

Item {
    id: root
    signal closeRequested() 

    implicitWidth: 860 
    implicitHeight: 520 

    property int activeSliderIndex: 0 

    // ============================================================
    // 【组件：自带动态追踪折射的真实悬浮玻璃卡片】
    // ============================================================
    component FrostedGlassCard : Item {
        id: cardRoot
        default property alias content: innerContainer.data
        anchors.fill: parent

        Item {
            id: blurSourceContainer
            anchors.fill: parent
            visible: false
            clip: true

            Image {
                source: Colorscheme.currentWallpaperPreview
                width: 2560; height: 1440
                sourceSize.width: 2560; sourceSize.height: 1440
                fillMode: Image.PreserveAspectCrop
                
                property real delegateX: cardRoot.parent ? cardRoot.parent.x : 0
                property real delegateY: cardRoot.parent ? cardRoot.parent.y : 0
                x: -1318 - delegateX - 10
                y: -132 - delegateY - 10
                
                cache: false
                asynchronous: true
            }
        }

        FastBlur {
            id: cardBlur
            anchors.fill: blurSourceContainer
            source: blurSourceContainer
            radius: 64 
            transparentBorder: false
            visible: false
        }

        Rectangle { id: cardMask; anchors.fill: parent; radius: 24; visible: false }
        OpacityMask { anchors.fill: parent; source: cardBlur; maskSource: cardMask }

        Rectangle {
            anchors.fill: parent; radius: 24
            color: Qt.rgba(Colorscheme.surface_container_lowest.r, Colorscheme.surface_container_lowest.g, Colorscheme.surface_container_lowest.b, 0.6)
            border.color: Qt.rgba(Colorscheme.primary.r, Colorscheme.primary.g, Colorscheme.primary.b, 0.5)
            border.width: 1.5
        }
        Item { id: innerContainer; anchors.fill: parent; anchors.margins: 16 }
    }

    // ============================================================
    // 【重构：带事件抛出的手风琴动态滑块】
    // ============================================================
    component ExpandableVertSlider : Item {
        id: sliderCol
        property int sliderIndex: 0 
        property string icon: ""
        property real sliderValue: 0.5
        property bool expanded: false
        
        signal sliderMoved(real val) // 【新增】：向外抛出滑块拖动事件！

        property real expandProgress: expanded ? 1.0 : 0.0
        Behavior on expandProgress { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

        width: 48
        implicitHeight: 48 + (128 * expandProgress)

        Rectangle {
            width: 48; height: 48; radius: 24
            color: sliderCol.expanded ? Colorscheme.primary : Colorscheme.surface_container_highest
            Behavior on color { ColorAnimation { duration: 250 } }
            Text {
                anchors.centerIn: parent; text: sliderCol.icon; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 18
                color: sliderCol.expanded ? Colorscheme.on_primary : Colorscheme.on_surface
            }
            MouseArea { 
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                onClicked: root.activeSliderIndex = (root.activeSliderIndex === sliderCol.sliderIndex ? -1 : sliderCol.sliderIndex) 
            }
        }

        Item {
            y: 48 + (8 * sliderCol.expandProgress)
            width: 48
            height: 120 * sliderCol.expandProgress
            opacity: sliderCol.expandProgress
            
            Item {
                anchors.centerIn: parent
                width: 16; height: parent.height - 4
                clip: true

                Rectangle {
                    anchors.fill: parent; radius: 8
                    color: Colorscheme.surface_container_lowest

                    Rectangle {
                        x: parent.width / 2 - width / 2; y: 4
                        width: 4; height: parent.height - 8; radius: 2; color: Colorscheme.surface_container_highest
                        Rectangle {
                            width: parent.width; height: (1.0 - vSlider.visualPosition) * parent.height; y: vSlider.visualPosition * parent.height
                            radius: 2; color: Colorscheme.primary
                        }
                    }
                }
            }

            Slider {
                id: vSlider
                orientation: Qt.Vertical
                anchors.fill: parent; anchors.margins: 4
                value: sliderCol.sliderValue
                hoverEnabled: true
                background: Item {} 
                
                // 【核心联动】：当用户拖拽时，向外抛出事件通知后端！
                onMoved: sliderCol.sliderMoved(value)

                handle: Rectangle {
                    x: vSlider.leftPadding + vSlider.availableWidth / 2 - width / 2
                    y: vSlider.topPadding + vSlider.visualPosition * (vSlider.availableHeight - height)
                    width: 12; height: 12; radius: 6; color: Colorscheme.primary

                    Item {
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36; height: 36
                        visible: vSlider.pressed || vSlider.hovered
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Rectangle { anchors.fill: parent; radius: 18; color: Colorscheme.primary_container }
                        Rectangle { 
                            width: 12; height: 12; radius: 2; color: Colorscheme.primary_container; rotation: 45
                            anchors.left: parent.left; anchors.leftMargin: -4; anchors.verticalCenter: parent.verticalCenter
                            z: -1
                        }
                        Text { 
                            anchors.centerIn: parent
                            text: Math.round(vSlider.value * 100)
                            color: Colorscheme.on_primary_container
                            font.pixelSize: 14; font.bold: true
                            font.family: "JetBrainsMono Nerd Font" 
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

        // ==========================================
        // 【第一列】：绑定真理大脑的实体滑块组
        // ==========================================
        ColumnLayout {
            z: 100 
            Layout.preferredWidth: 48
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            ExpandableVertSlider { 
                sliderIndex: 0; icon: ""; 
                expanded: root.activeSliderIndex === 0 
                // 绑定你原有的 Volume 单例
                sliderValue: Volume.sinkVolume
                onSliderMoved: (val) => Volume.setSinkVolume(val)
            } 
            ExpandableVertSlider { 
                sliderIndex: 1; icon: ""; 
                expanded: root.activeSliderIndex === 1 
                
                // 【修改】：绑定到专门的 Audio 服务大脑！
                sliderValue: Volume.sourceVolume
                onSliderMoved: (val) => Volume.setSourceVolume(val)
            }
            ExpandableVertSlider { 
                sliderIndex: 2; icon: ""; 
                expanded: root.activeSliderIndex === 2 
                // 绑定新建立的 ControlBackend 大脑
                sliderValue: ControlBackend.brightnessValue
                onSliderMoved: (val) => ControlBackend.setBrightness(val)
            }
            
            Item { Layout.fillHeight: true } 
        }

        // ==========================================
        // 【第二列】：系统状态 + 日历 (320px)
        // ==========================================
        ColumnLayout {
            Layout.preferredWidth: 320 
            Layout.maximumWidth: 320 
            Layout.minimumWidth: 320
            Layout.fillHeight: true
            spacing: 20

            SysInfoWidget { Layout.fillWidth: true; Layout.preferredHeight: 115 }
            CalendarWidget { Layout.fillWidth: true; Layout.fillHeight: true }
        }

        // ==========================================
        // 【第三列】：壁纸大洞 + 悬浮外溢卡片 + 点缀箭头
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: wallpaperBase
                anchors.fill: parent
                anchors.leftMargin: 20  
                anchors.rightMargin: 20 

                Item {
                    id: wallpaperWrapper
                    anchors.fill: parent
                    clip: true 
                    visible: false

                    Image {
                        id: rawWallpaper
                        source: Colorscheme.currentWallpaperPreview
                        width: 2560; height: 1440
                        sourceSize.width: 2560; sourceSize.height: 1440
                        fillMode: Image.PreserveAspectCrop
                        
                        x: -1318  
                        y: -132  
                        
                        cache: false
                        asynchronous: true
                    }
                }

                Rectangle { id: holeMask; anchors.fill: parent; radius: 24; visible: false }
                OpacityMask { anchors.fill: parent; source: wallpaperWrapper; maskSource: holeMask }
            }

            // --- 2. 悬浮的毛玻璃轮盘卡片 ---
            Item {
                id: carouselContainer
                anchors.fill: wallpaperBase

                // 【核心修复】：将组件预先打包，避开 ObjectModel
                Component {
                    id: scheduleCard
                    ScheduleWidget { anchors.fill: parent }
                }

                Component {
                    id: controlCard
                    ControlCenterWidget { anchors.fill: parent }
                }

                PathView {
                    id: carouselView
                    anchors.fill: parent
                    
                    // 【核心修复】：直接使用纯数字模型 (0 和 1)
                    model: 2
                    pathItemCount: 2
                    
                    // 使用动态 Loader 进行渲染，100% 稳定不出错
                    delegate: Item {
                        width: carouselView.width
                        height: carouselView.height 
                        
                        FrostedGlassCard { 
                            anchors.fill: parent
                            anchors.margins: 10 
                            
                            Loader {
                                anchors.fill: parent
                                // 根据 index 动态决定加载课表还是控制中心
                                sourceComponent: index === 0 ? scheduleCard : controlCard
                            }
                        }
                    }

                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    highlightRangeMode: PathView.StrictlyEnforceRange
                    snapMode: PathView.SnapToItem
                    
                    clip: true 
                    interactive: false 

                    path: Path {
                        startX: -carouselView.width / 2
                        startY: carouselView.height / 2
                        PathLine { x: carouselView.width * 1.5; y: carouselView.height / 2 }
                    }
                }
            }

            Text {
                id: leftArrow
                anchors.right: wallpaperBase.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "" 
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 20
                color: Colorscheme.on_surface_variant
                opacity: leftMouse.containsMouse ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 150 } }
                
                MouseArea { 
                    id: leftMouse; anchors.fill: parent; anchors.margins: -12; 
                    cursorShape: Qt.PointingHandCursor; 
                    onClicked: carouselView.incrementCurrentIndex() 
                }
            }

            Text {
                id: rightArrow
                anchors.left: wallpaperBase.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "" 
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 20
                color: Colorscheme.on_surface_variant
                opacity: rightMouse.containsMouse ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 150 } }

                MouseArea { 
                    id: rightMouse; anchors.fill: parent; anchors.margins: -12; 
                    cursorShape: Qt.PointingHandCursor; 
                    onClicked: carouselView.decrementCurrentIndex() 
                }
            }
        }
    }
}
