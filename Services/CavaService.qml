pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var values: new Array(30).fill(0)
    property int refCount: 0
    property bool cavaAvailable: false

    // 1. 检查环境是否安装了 cava
    Process {
        id: cavaCheck
        command: ["which", "cava"]
        running: true
        onExited: exitCode => {
            root.cavaAvailable = (exitCode === 0);
        }
    }

    // 2. 核心：运行 Cava 并获取纯文本数字
    Process {
        id: cavaProcess
        // 只有当有组件需要律动 (refCount > 0) 且 cava 存在时才运行，绝不浪费后台性能
        running: root.cavaAvailable && root.refCount > 0
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
            if (!running) root.values = new Array(30).fill(0);
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
