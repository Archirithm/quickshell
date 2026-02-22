import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Io
import qs.config 

Rectangle {
    id: root
    color: Colorscheme.surface_container_high
    radius: 16

    // ================== 极致轻量的数据获取逻辑 ==================
    // 1. 环境变量直读 (绝对零开销)
    property string sysUser: Quickshell.env("USER") || "archirithm"
    property string sysWm: (Quickshell.env("XDG_SESSION_DESKTOP") || "niri").toLowerCase()

    // 2. 硬件与主机名缓存
    property string sysHost: "archlinux"
    property string sysChassis: "Computer"

    // 3. 原生 sh + cat 读取内存虚拟文件系统 (耗时 < 1ms，无 I/O 负担)
    Process {
        id: fetchProc
        command: ["sh", "-c", "echo \"{\\\"host\\\": \\\"$(cat /etc/hostname 2>/dev/null)\\\", \\\"vendor\\\": \\\"$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)\\\", \\\"chassis\\\": \\\"$(cat /sys/class/dmi/id/chassis_type 2>/dev/null)\\\"}\""]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    var json = JSON.parse(data);
                    if (json.host && json.host.trim() !== "") root.sysHost = json.host.trim();
                    
                    // 清理厂商名称中冗余的后缀 (例如 "HP Inc." 变成 "HP")
                    var vendor = json.vendor ? json.vendor.trim().replace(" Inc.", "").replace(" Corporation", "") : "Unknown";
                    
                    // 解析 Linux Chassis 代码
                    var type = parseInt(json.chassis);
                    var typeStr = "Computer";
                    if ([3, 4, 6, 7].includes(type)) typeStr = "Desktop";
                    else if ([8, 9, 10, 11, 31, 32].includes(type)) typeStr = "Notebook";
                    
                    // 组合成 "Notebook HP" 的格式
                    root.sysChassis = typeStr + (vendor !== "Unknown" ? (" " + vendor) : "");
                } catch(e) { console.log("Fetch JSON error: " + e); }
            }
        }
    }

    Item {
        anchors.fill: parent

        // ==========================================
        // 1. 头像区域 (靠上锚定，极限放大，绝美正圆)
        // ==========================================
        Item {
            width: 120 
            height: 120
            
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: avatarImg
                anchors.fill: parent
                source: "file:///home/archirithm/Pictures/avatar/shelby.jpg"
                sourceSize: Qt.size(240, 240) 
                fillMode: Image.PreserveAspectCrop
                visible: false 
                cache: true
            }

            Rectangle {
                id: mask
                anchors.fill: parent
                radius: 60 
                visible: false 
                color: "black"
            }

            OpacityMask {
                anchors.fill: parent
                source: avatarImg
                maskSource: mask
            }

            // 主题色光环
            Rectangle {
                anchors.fill: parent
                radius: 60
                color: "transparent"
                border.color: Colorscheme.primary
                border.width: 2
                opacity: 0.8
            }
        }

        // ==========================================
        // 2. 底部动态 Fetch 信息 (极致规整的三行排布)
        // ==========================================
        ColumnLayout {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 2 

            Text { 
                text: root.sysUser + " @ " + root.sysHost
                color: Colorscheme.on_surface_variant 
                font.pixelSize: 14 
                font.family: Sizes.fontFamily 
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text { 
                text: "Chassis : " + root.sysChassis
                color: Colorscheme.on_surface_variant 
                font.pixelSize: 14
                font.family: Sizes.fontFamily 
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Text { 
                text: "WM : " + root.sysWm
                color: Colorscheme.on_surface_variant 
                font.pixelSize: 14
                font.family: Sizes.fontFamily 
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
