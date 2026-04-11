import Quickshell
import QtQuick

PanelWindow {
    // 1. 给个明显的背景色和大小
    color: "#2E3440" 
    width: 400
    height: 400
    
    // 2. 停靠在屏幕左上角（仅保留布尔值）
    anchors {
        top: true
        left: true
    }

    Image {
        id: testImg
        anchors.centerIn: parent
        width: 200
        height: 200
        
        // 3. 极其重要：绝对路径必须带 file:// 前缀
        source: "file:///home/archirithm/.config/quickshell/assets/icons/Paper-Plane.svg"
        fillMode: Image.PreserveAspectFit

        // 4. 核心排错逻辑：让引擎把状态打印到终端
        onStatusChanged: {
            if (status === Image.Error) {
                console.log("\n❌ [报错] 图片加载失败！");
                console.log("尝试加载的路径: " + source);
                console.log("请检查：1. 文件是否存在 2. 绝对路径前是否有 file://\n");
            } else if (status === Image.Ready) {
                console.log("\n✅ [成功] 图片已完美加载！\n");
            }
        }
    }
    
    // 5. 加一行提示文字，证明 UI 层没有崩溃
    Text {
        anchors.top: testImg.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 20
        text: "如果上面没有图片，请看 Kitty 终端的日志输出"
        color: "white"
        font.pointSize: 12
    }
}
