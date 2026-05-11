import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Common

FocusScope {
    id: root
    property var context: null
    
    signal requestUnlock()
    
    Layout.fillWidth: true
    Layout.preferredHeight: 50

    Component.onCompleted: input.forceActiveFocus()
    onActiveFocusChanged: if (activeFocus) input.forceActiveFocus()

    Rectangle {
        id: inputFrame
        anchors.fill: parent
        color: Appearance.colors.colLayer4 
        radius: 25 
        border.width: 1
        border.color: input.activeFocus ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.5)
            : root.context && root.context.showFailure ? Qt.rgba(Appearance.colors.colError.r, Appearance.colors.colError.g, Appearance.colors.colError.b, 0.7)
            : "transparent"
        
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: parent; property: "x"; from: 0; to: 10; duration: 50 }
            NumberAnimation { target: parent; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: parent; property: "x"; to: 0; duration: 50 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 10
            spacing: 10

            // 1. 左侧锁图标
            Text {
                text: root.context && root.context.unlockInProgress ? "sync" : "lock"
                color: Appearance.colors.colOnSurfaceVariant
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter 

                RotationAnimation on rotation {
                    running: root.context && root.context.unlockInProgress
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 900
                }
            }

            // 2. 核心输入区
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true 

                // 幽灵输入框
                TextInput {
                    id: input
                    anchors.fill: parent
                    color: "transparent" 
                    selectionColor: "transparent"
                    selectedTextColor: "transparent"
                    focus: true
                    echoMode: TextInput.Password
                    
                    onAccepted: {
                        if (!root.context || !root.context.unlockInProgress)
                            root.requestUnlock()
                    }
                    
                    onTextChanged: {
                        if(root.context) root.context.currentText = text
                        
                        // 【核心修复】：精准同步密码点模型，不牵连旧数据，彻底解决闪烁
                        var len = text.length
                        while (dotsModel.count < len) {
                            dotsModel.append({})
                        }
                        while (dotsModel.count > len) {
                            dotsModel.remove(dotsModel.count - 1)
                        }
                    }
                    
                    Connections {
                        target: root.context ? root.context : null
                        ignoreUnknownSignals: true
                        function onCurrentTextChanged() {
                            if (root.context && input.text !== root.context.currentText) {
                                input.text = root.context.currentText
                                if (input.text === "") shakeAnim.start()
                            }
                        }
                    }
                }

                // 数据模型
                ListModel {
                    id: dotsModel
                }

                Text {
                    anchors.centerIn: parent
                    text: root.context && root.context.unlockInProgress ? "Checking..." : "Enter password"
                    visible: input.text.length === 0
                    opacity: visible ? 0.8 : 0
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: 13

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.expressiveEffects.duration
                            easing.type: Appearance.animation.expressiveEffects.type
                            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                        }
                    }
                }

                // 居中的自定义密码点：改用 ListView 以支持完美退场动画
                ListView {
                    id: dotsList
                    
                    property int dotSize: 10
                    property int dotSpacing: 8 // 【样式修改】：调小间距，让密码看起来更紧凑
                    
                    // 动态计算总宽度，驱动外层阻尼挤压感
                    width: count === 0 ? 0 : (count * dotSize) + ((count - 1) * dotSpacing)
                    height: dotSize
                    
                    // 保持绝对居中
                    x: parent ? (parent.width - width) / 2 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    
                    orientation: ListView.Horizontal
                    spacing: dotSpacing
                    interactive: false // 禁止滚动干扰

                    model: dotsModel

                    // 挤压与回弹的物理阻尼
                    Behavior on x {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    delegate: Rectangle {
                        width: dotsList.dotSize
                        height: dotsList.dotSize
                        radius: dotsList.dotSize / 2
                        color: Appearance.colors.colOnSurface
                    }

                    // 进场动画：新圆球弹出淡入
                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 }
                            NumberAnimation { property: "scale"; from: 0.3; to: 1; duration: 250; easing.type: Easing.OutBack }
                        }
                    }

                    // 退场动画：旧圆球删除时的平滑缩小淡出
                    remove: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; to: 0; duration: 150 }
                            NumberAnimation { property: "scale"; to: 0.3; duration: 150; easing.type: Easing.InBack }
                        }
                    }
                }
            }
            
            // 3. 提交按钮
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 32; height: 32; radius: 16
                
                property bool hasText: input.text.length > 0
                
                color: hasText ? Appearance.colors.colPrimary : "transparent"
                border.width: hasText ? 0 : 1
                border.color: hasText ? "transparent" : Appearance.colors.colOutline
                Behavior on color { ColorAnimation { duration: 200 } }
                
                Text { 
                    anchors.centerIn: parent
                    text: "arrow_forward"
                    color: parent.hasText ? Appearance.colors.colOnPrimary : Appearance.colors.colOutline
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                }
                
                MouseArea { 
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: parent.hasText && (!root.context || !root.context.unlockInProgress)
                    onClicked: {
                        input.forceActiveFocus()
                        if(parent.hasText) root.requestUnlock()
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onClicked: (mouse) => {
            input.forceActiveFocus()
            mouse.accepted = false
        }
    }
}
