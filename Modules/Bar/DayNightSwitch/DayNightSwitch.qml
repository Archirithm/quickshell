import QtQuick
import QtQuick.Shapes 1.15
import Qt5Compat.GraphicalEffects 
import qs.config 

Item {
    id: root

    // --- 1. 引入后端逻辑 ---
    DayNightLogic { id: logic }
    property bool isDark: logic.isDark
    
    // --- 2. 尺寸与动画配置 ---
    implicitHeight: Sizes.barHeight 
    readonly property real s: height / 70
    implicitWidth: 180 * s

    property int animTime: 1000 
    property var cssBezier: [0.56, 1.35, 0.52, 1.0, 1.0, 1.0]

    // =================================================================
    // 3. 视觉渲染层
    // =================================================================
    Item {
        id: switchContent
        anchors.fill: parent
        
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: switchContent.width; height: switchContent.height
                radius: switchContent.height / 2; visible: false
            }
        }

        // [A] 背景
        Rectangle {
            anchors.fill: parent
            color: root.isDark ? "#191e32" : "#4685c0"
            Behavior on color { ColorAnimation { duration: 700 } }
        }

        // [B] 光晕 (跟随滑块)
        Item {
            width: parent.width; height: parent.height
            Repeater {
                model: [
                    // size: 直径
                    // 按钮直径 55
                    
                    // 第1层：直径 100 (单边间距 22.5)，核心光圈够大
                    { size: 100, op: 0.12 }, 
                    
                    // 第2层：直径 140 (单边间距 20)，均匀扩散
                    { size: 140, op: 0.08 }, 
                    
                    // 第3层：直径 180 (单边间距 20)，最外层氛围
                    { size: 180, op: 0.04 }
                ]
                Rectangle {
                    property var d: modelData
                    width: d.size * root.s; height: width; radius: width/2; color: "white"; opacity: d.op
                    
                    // 位置跟随逻辑 (保持不变)
                    y: (mainButton.y + mainButton.height/2) - (height/2) - (5 * root.s)
                    x: (mainButton.x + mainButton.width/2) - (width/2)
                }
            }
        }

        // [C] 云朵 (距离感知斥力)
        Item {
            id: cloudsContainer
            width: parent.width; height: parent.height
            property real dayY: 0 * root.s; property real nightY: 80 * root.s
            
            y: root.isDark ? nightY : dayY
            Behavior on y { NumberAnimation { duration: root.animTime; easing.type: Easing.Bezier; easing.bezierCurve: root.cssBezier } }

            // 移除容器整体的 x 移动，改为在 delegate 内部单独计算
            
            property var cloudData: [
                {r: -20, b: 5, w: 50}, {r: -10, b: -25, w: 60}, {r: 20, b: -40, w: 60}, 
                {r: 50, b: -35, w: 60}, {r: 75, b: -60, w: 75}, {r: 110, b: -50, w: 60}
            ]

            // 背景云
            Item {
                anchors.fill: parent; opacity: 0.5; layer.enabled: true; layer.samples: 4
                Repeater {
                    model: cloudsContainer.cloudData.length
                    delegate: Rectangle {
                        property var d: cloudsContainer.cloudData[index]
                        
                        // --- 【核心修改点：计算斥力】 ---
                        // 1. 基础位置 (从右边算起)
                        property real baseX: root.width - (d.r * root.s) - width - (15 * root.s)
                        
                        // 2. 斥力计算
                        // d.r 越大，说明越靠左(离太阳越近)。我们把 -20 到 110 映射到 0.0 ~ 1.0 的系数
                        // 系数 = (d.r + 20) / 130
                        property real proximityFactor: (d.r + 20) / 130.0
                        
                        // 3. 推力 (只有白天 + 悬停时生效)
                        // 离太阳越近(系数越大)，推得越远(最大 15px)
                        property real pushOffset: (!root.isDark && interactArea.containsMouse) ? (15 * root.s * proximityFactor) : 0

                        width: d.w * root.s; height: width; radius: width/2; color: "white"; opacity: 1.0 
                        
                        // 4. 最终坐标 = 基础坐标 + 推力
                        x: baseX + pushOffset
                        y: root.height - (d.b * root.s) - height - (15 * root.s)
                        
                        // 给 x 加一个平滑过渡，模拟物理惯性
                        Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }

                        // (下方的随机抖动逻辑保持不变)
                        transform: Translate { 
                            id: lightCloudTrans
                            Behavior on x { NumberAnimation { duration: 1200 } } 
                            Behavior on y { NumberAnimation { duration: 1200 } } 
                        }
                        Timer { 
                            running: interactArea.containsMouse; repeat: true; interval: 1200; 
                            onTriggered: { 
                                var range = 2 * root.s; 
                                lightCloudTrans.x = (Math.random() > 0.5 ? range : -range); 
                                lightCloudTrans.y = (Math.random() > 0.5 ? range : -range) 
                            }
                            onRunningChanged: { if (!running) { lightCloudTrans.x = 0; lightCloudTrans.y = 0 } }
                        }
                    }
                }
            }
            
            // 前景云 (逻辑完全相同，为了省事我直接复制一下核心逻辑)
            Repeater {
                model: cloudsContainer.cloudData.length
                delegate: Rectangle {
                    property var d: cloudsContainer.cloudData[index]
                    
                    // --- 【前景云受力逻辑】 ---
                    property real baseX: root.width - (d.r * root.s) - width
                    property real proximityFactor: (d.r + 20) / 130.0
                    // 前景云推得稍微远一点点 (18)，增加立体感
                    property real pushOffset: (!root.isDark && interactArea.containsMouse) ? (18 * root.s * proximityFactor) : 0
                    
                    x: baseX + pushOffset
                    Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                    // -----------------------

                    width: d.w * root.s; height: width; radius: width/2; color: "white"; opacity: 1.0
                    y: root.height - (d.b * root.s) - height
                    
                    transform: Translate { 
                        id: mainCloudTrans
                        Behavior on x { NumberAnimation { duration: 1000 } } 
                        Behavior on y { NumberAnimation { duration: 1000 } } 
                    }
                    Timer { 
                        running: interactArea.containsMouse; repeat: true; interval: 1000; 
                        onTriggered: { 
                            var range = 2 * root.s; 
                            mainCloudTrans.x = (Math.random() > 0.5 ? range : -range); 
                            mainCloudTrans.y = (Math.random() > 0.5 ? range : -range) 
                        }
                        onRunningChanged: { if (!running) { mainCloudTrans.x = 0; mainCloudTrans.y = 0 } }
                    }
                }
            }
        }

        // [D] 星星 (距离感知斥力)
        Item {
            id: starsContainer
            width: parent.width; height: parent.height
            property real dayY: -70 * root.s; property real nightY: 0 * root.s
            y: root.isDark ? nightY : dayY
            Behavior on y { NumberAnimation { duration: root.animTime; easing.type: Easing.Bezier; easing.bezierCurve: root.cssBezier } }

            // 移除容器整体的 pushX
            
            property var starData: [
                {x: 39, y: 11, sz: 7.5, dur: 2200}, {x: 91, y: 39, sz: 7.5, dur: 3500}, 
                {x: 19, y: 26, sz: 5,   dur: 2100}, {x: 66, y: 37, sz: 5,   dur: 2800}, 
                {x: 75, y: 21, sz: 3,   dur: 1800}, {x: 38, y: 51, sz: 3,   dur: 1500}
            ]
            Repeater {
                model: starsContainer.starData.length
                delegate: Item {
                    id: starItem
                    property var d: starsContainer.starData[index]
                    
                    // --- 【核心修改点：计算斥力】 ---
                    // 1. 基础位置
                    property real baseX: d.x * root.s
                    
                    // 2. 斥力计算
                    // 月亮在右边(约 x=110)。
                    // d.x 越大，离月亮越近。系数 = d.x / 100
                    property real proximityFactor: d.x / 100.0
                    
                    // 3. 推力 (只有黑夜 + 悬停时生效)
                    // 离月亮越近(系数越大)，向左被推得越远(最大 -12px)
                    property real pushOffset: (root.isDark && interactArea.containsMouse) ? (-12 * root.s * proximityFactor) : 0
                    
                    // 4. 最终坐标
                    x: baseX + pushOffset
                    
                    // 给 x 加缓冲
                    Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.OutQuad } }
                    // -----------------------------

                    y: d.y * root.s; width: d.sz * 2 * root.s; height: width
                    
                    Shape {
                        anchors.fill: parent; layer.enabled: true; layer.samples: 4
                        ShapePath { strokeWidth: 0; strokeColor: "transparent"; fillColor: "white"; startX: width / 2; startY: 0; PathQuad { x: width; y: height / 2; controlX: width / 2; controlY: height / 2 } PathQuad { x: width / 2; y: height; controlX: width / 2; controlY: height / 2 } PathQuad { x: 0; y: height / 2; controlX: width / 2; controlY: height / 2 } PathQuad { x: width / 2; y: 0; controlX: width / 2; controlY: height / 2 } }
                    }
                    
                    transformOrigin: Item.Center; scale: 1.0

                    // 状态机控制闪烁 (保持不变)
                    states: State {
                        name: "flashing"
                        when: interactArea.containsMouse
                    }
                    transitions: [
                        Transition {
                            from: ""; to: "flashing"
                            SequentialAnimation {
                                loops: Animation.Infinite
                                NumberAnimation { target: starItem; property: "scale"; to: 1.2; duration: d.dur * 0.4; easing.type: Easing.OutQuad }
                                NumberAnimation { target: starItem; property: "scale"; to: 0.3; duration: d.dur * 0.6; easing.type: Easing.InQuad }
                            }
                        },
                        Transition {
                            from: "flashing"; to: ""
                            NumberAnimation { target: starItem; property: "scale"; to: 1.0; duration: 300; easing.type: Easing.OutQuad }
                        }
                    ]
                }
            }
        }

        // [E] 滑块按钮
        Rectangle {
            id: mainButton
            width: 55 * root.s; height: 55 * root.s; radius: width / 2; y: 7.5 * root.s
            property real padding: 7.5 * root.s
            property real startX: padding
            property real endX: root.width - width - padding
            property real hoverOffset: 10 * root.s
            
            // 计算滑块位置 (含 Peak 逻辑)
            x: {
                if (root.isDark) return interactArea.containsMouse ? (endX - hoverOffset) : endX
                else return interactArea.containsMouse ? (startX + hoverOffset) : startX
            }

            color: root.isDark ? "#c3c8d2" : "#ffc323"
            Behavior on x { NumberAnimation { duration: root.animTime; easing.type: Easing.Bezier; easing.bezierCurve: root.cssBezier } }
            Behavior on color { ColorAnimation { duration: root.animTime } }

            layer.enabled: true
            layer.effect: DropShadow { transparentBorder: true; horizontalOffset: 3 * root.s; verticalOffset: 3 * root.s; radius: 12.0 * root.s; samples: 17; color: "#80000000" }

            Rectangle { anchors.fill: parent; radius: width/2; color: "transparent"; opacity: root.isDark?0.2:1.0; Behavior on opacity { NumberAnimation { duration: 500 } } Rectangle { width: parent.width*0.8; height: width; radius: width/2; color: "#ffe650"; anchors.centerIn: parent; anchors.verticalCenterOffset: -2*root.s; anchors.horizontalCenterOffset: -2*root.s; opacity: 0.6 } }
            Item { anchors.fill: parent; opacity: root.isDark?1:0; visible: opacity>0; rotation: root.isDark?0:-90; Behavior on rotation { NumberAnimation { duration: root.animTime; easing.type: Easing.Bezier; easing.bezierCurve: root.cssBezier } } Behavior on opacity { NumberAnimation { duration: 300 } } Repeater { model: [{l:25,t:7.5,w:12.5}, {l:7.5,t:20,w:20}, {l:32.5,t:32.5,w:12.5}]; delegate: Rectangle { color: "#96a0b4"; x: modelData.l*root.s; y: modelData.t*root.s; width: modelData.w*root.s; height: width; radius: width/2 } } }
        }
    }

    // 装饰边框
    Shape {
        id: maskPanel 
        anchors.fill: parent; layer.enabled: true; layer.samples: 4
        property real r: height / 2 
        ShapePath { fillColor: "transparent"; strokeColor: "#20000000"; strokeWidth: 3 * root.s; PathRectangle { x: 0; y: 0; width: maskPanel.width; height: maskPanel.height; radius: maskPanel.r } }
    }

    // 交互层
    MouseArea {
        id: interactArea
        anchors.fill: parent
        hoverEnabled: true 
        cursorShape: Qt.PointingHandCursor
        onClicked: logic.toggle()
    }
}
