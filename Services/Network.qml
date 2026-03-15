pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: activeConnectionType != ""
    property string activeConnection: "Disconnected"
    property string activeConnectionType: ""
    // 【新增】信号强度属性
    property int signalStrength: 100 

    function refresh() {
        refreshProcess.running = true;
        // 每次刷新网络状态时，顺便抓取一次信号强度
        signalProcess.running = true; 
    }

    Process {
        id: refreshProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "con", "show", "--active"]
        
        stdout: StdioCollector {
            onStreamFinished: () => {
                if (this.text.trim() === "") {
                    root.activeConnectionType = ""
                    root.activeConnection = "Disconnected"
                    root.signalStrength = 0
                    return
                }
                
                const interfaces = this.text.split("\n");
                const activeInterface = interfaces[0];
                const fields = activeInterface.split(":");
                
                if (fields.length < 2) return;
                const connectionType = refreshProcess.getConnectionType(fields[1]);
                root.activeConnectionType = connectionType;
                root.activeConnection = connectionType != "" ? fields[0] : "Disconnected";
            }
        }

        function getConnectionType(nmcliOutput) {
            if (nmcliOutput.includes("ethernet")) return "ETHERNET";
            else if (nmcliOutput.includes("wireless")) return "WIFI";
            return "";
        }
    }

    // 【新增】利用 shell 管道精确抓取当前带 '*' 号的 WiFi 信号值
    Process {
        id: signalProcess
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi | grep '^\\*' | cut -d':' -f2"]
        stdout: StdioCollector {
            onStreamFinished: () => {
                const val = parseInt(this.text.trim());
                if (!isNaN(val)) {
                    root.signalStrength = val;
                }
            }
        }
    }

    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.refresh()
        }
    }
}
