import QtQuick
import Quickshell.Io
import qs.Common

Item {
    id: audioRoot

    property bool active: false
    signal requestStop()

    property int seconds: 0
    property string audioMode: "mic"
    
    // ================= 配置参数 =================
    // 【高密度化】：线宽2 + 间距1。容纳 50 个红色波形和 18 个灰色待命点
    property int activeBars: 32 
    property int staticBars: 9  
    property int totalBars: activeBars + staticBars 

    onActiveChanged: {
        if (active) {
            seconds = 0;
            recordTimer.start();
            cavaProcess.running = true;
            for (var i = 0; i < waveModel.count; i++) {
                waveModel.setProperty(i, "val", 2);
            }
        } else {
            recordTimer.stop();
            cavaProcess.running = false;
        }
    }

    function formatTime(sec) {
        var m = Math.floor(sec / 60);
        var s = sec % 60;
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
    }

    Timer {
        id: recordTimer
        interval: 1000
        repeat: true
        onTriggered: audioRoot.seconds++
    }

    ListModel {
        id: waveModel
        Component.onCompleted: {
            // 初始化为 2，保证灰点是 2x2 的正圆点
            for (var i = 0; i < audioRoot.totalBars; i++) { append({ val: 2 }) }
        }
    }

    Process {
        id: cavaProcess
        command: ["bash", Paths.scriptPath("audio", "wave_" + audioRoot.audioMode + ".sh")]
        running: false

        stdout: SplitParser {
            onRead: data => {
                if (!audioRoot.active) return;
                var cleanData = data.replace(";", "").trim();
                if (cleanData === "") return;
                
                var rawVolume = parseInt(cleanData);
                if (!isNaN(rawVolume)) {
                    
                    var normalized = rawVolume / 60.0;
                    var curvedVolume = Math.pow(normalized, 1.8) * 60.0; 
                    var newVolume = Math.round(curvedVolume);

                    // 1. 数据整体纯粹左移
                    for (var i = 0; i < audioRoot.totalBars - 1; i++) {
                        waveModel.setProperty(i, "val", waveModel.get(i+1).val);
                    }
                    
                    // 2. 最右侧永远补充高度为 2 的灰点
                    waveModel.setProperty(audioRoot.totalBars - 1, "val", 2);
                    
                    // 3. 播放头强势注入新音量（保底高度为2）
                    var playhead = audioRoot.activeBars - 1;
                    waveModel.setProperty(playhead, "val", Math.max(2, newVolume));
                }
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        // 【极限压缩】：间距设为 1
        spacing: 2

        Repeater {
            model: waveModel
            Rectangle {
                // 【变细】：宽度设为 2
                width: 3 
                height: val 
                radius: 1
                anchors.verticalCenter: parent.verticalCenter 
                
                // 完美还原珊瑚红
                color: index < audioRoot.activeBars ? "#f75459" : "#444444"
                
                // 【核心消灭重影】：持续时间 25ms 严格小于 30fps 的帧间隔 (33ms)
                Behavior on height { NumberAnimation { duration: 25; easing.type: Easing.OutQuad } }
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            text: audioRoot.formatTime(audioRoot.seconds)
            color: "#f75459"
            font.pixelSize: 22
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: "transparent"
            border.color: "white"
            border.width: 2
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 4
                color: "#f75459"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { audioRoot.requestStop(); }
            }
        }
    }
}
