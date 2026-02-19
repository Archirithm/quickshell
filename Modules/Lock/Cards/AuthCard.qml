import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

FocusScope {
    id: root
    
    // 接收 context，并设置默认值为 null
    property var context: null
    
    Layout.fillWidth: true
    Layout.preferredHeight: 50

    // 自动聚焦逻辑
    Component.onCompleted: input.forceActiveFocus()
    onActiveFocusChanged: if (activeFocus) input.forceActiveFocus()

    // 背景胶囊
    Rectangle {
        anchors.fill: parent
        color: Colorsheme.surface_container_highest 
        radius: 25 

        // 焦点指示器 (微弱的边框)
        border.width: 1
        border.color: input.activeFocus ? Qt.rgba(Colorsheme.primary.r, Colorsheme.primary.g, Colorsheme.primary.b, 0.5) : "transparent"
        
        // 错误震动动画 (可选)
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

            // 1. 左侧锁图标 (垂直居中)
            Text {
                text: ""
                color: Colorsheme.on_surface_variant
                font.family: Sizes.fontFamilyMono
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter // 确保居中
            }

            // 2. 输入框
            TextInput {
                id: input
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                
                color: Colorsheme.on_surface
                
                // 【样式修改】增大字号让圆点看起来更大
                font.family: Sizes.fontFamilyMono
                font.pixelSize: 24 
                font.bold: true
                
                // 垂直居中修正 (因为字号变大了)
                verticalAlignment: TextInput.AlignVCenter
                
                // 密码模式
                echoMode: TextInput.Password
                // 使用更圆润的实心圆点，而不是默认的星号或小点
                passwordCharacter: "●" 
                
                focus: true
                enabled: true 
                
                // 回车解锁
                onAccepted: {
                    // 【核心修复】再次尝试获取 context，防止Loader传递延迟
                    if (root.context) {
                        root.context.tryUnlock()
                    } else {
                        // 尝试从 parent (Loader) 获取
                        if (parent && parent.context) {
                            parent.context.tryUnlock()
                        } else {
                            console.log("Error: Context is still null!")
                            shakeAnim.start()
                        }
                    }
                }
                
                // 实时同步
                onTextChanged: {
                    if(root.context) root.context.currentText = text
                }
                
                // 监听外部清空信号 (例如密码错误)
                Connections {
                    target: root.context ? root.context : null
                    ignoreUnknownSignals: true
                    function onCurrentTextChanged() {
                        if (root.context && input.text !== root.context.currentText) {
                            input.text = root.context.currentText
                            // 如果被清空了，触发震动反馈
                            if (input.text === "") shakeAnim.start()
                        }
                    }
                }
            }
            
            // 3. 提交按钮 (根据是否有输入改变样式)
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 32; height: 32; radius: 16
                
                // 【Feature 实现】有密码时显示主色，无密码时透明/灰色
                property bool hasText: input.text.length > 0
                
                color: hasText ? Colorsheme.primary : "transparent"
                border.width: hasText ? 0 : 1
                border.color: hasText ? "transparent" : Colorsheme.outline
                
                // 动画过渡
                Behavior on color { ColorAnimation { duration: 200 } }
                
                Text { 
                    anchors.centerIn: parent
                    text: "➜"
                    // 有密码时文字反色，无密码时灰色
                    color: parent.hasText ? Colorsheme.on_primary : Colorsheme.outline
                    font.pixelSize: 14
                    font.bold: true
                }
                
                MouseArea { 
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    // 只有有输入时才允许点击
                    enabled: parent.hasText
                    onClicked: {
                        input.forceActiveFocus()
                        if(root.context) root.context.tryUnlock()
                    }
                }
            }
        }
    }

    // 点击空白聚焦
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onClicked: (mouse) => {
            input.forceActiveFocus()
            mouse.accepted = false
        }
    }
}
