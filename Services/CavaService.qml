pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config 

Singleton {
    id: root

    property var values: new Array(30).fill(0)
    property int refCount: 0
    property bool cavaAvailable: false

    // 内部运行状态锁，用于配合钩子打破声明式绑定
    property bool _internalRun: true

    Process {
        id: cavaCheck
        command: ["which", "cava"]
        running: true
        onExited: exitCode => {
            root.cavaAvailable = (exitCode === 0);
        }
    }

    // 重启缓冲定时器
    Timer {
        id: reviveTimer
        interval: 500 
        onTriggered: root._internalRun = true
    }

    // ============================================================
    // 【保留】：精准打击的主题变更钩子
    // ============================================================
    Connections {
        target: Appearance.colors
        function onColLayer0Changed() {
            if (root.refCount > 0) {
                // 监听到主题切换，主动打断 cava 进程并触发重启缓冲
                root._internalRun = false; 
                reviveTimer.restart();
            }
        }
    }

    Process {
        id: cavaProcess
        running: root.cavaAvailable && root.refCount > 0 && root._internalRun
        
        command: ["sh", "-c", `cat <<'EOF' | cava -p /dev/stdin
[general]
framerate=60
bars=30
autosens=1
[output]
method=raw
raw_target=/dev/stdout
data_format=ascii
ascii_max_range=100
channels=mono
mono_option=average
[smoothing]
noise_reduction=35
integral=90
gravity=95
ignore=2
monstercat=1.5
EOF`]

        onRunningChanged: {
            if (!running) {
                root.values = new Array(30).fill(0);
            }
        }

        // 保留最基础的意外退出捕获，防止 cava 自己崩溃时彻底罢工
        onExited: exitCode => {
            if (root.refCount > 0) {
                root._internalRun = false;
                reviveTimer.restart();
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (root.refCount > 0 && data.length > 0) {
                    const parts = data.split(";");
                    if (parts.length >= 30) {
                        let arr = new Array(30);
                        for (let i = 0; i < 30; i++) {
                            arr[i] = parseInt(parts[i], 10) || 0;
                        }
                        root.values = arr;
                    }
                }
            }
        }
    }
}

