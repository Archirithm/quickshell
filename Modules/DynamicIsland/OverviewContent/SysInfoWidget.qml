import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Io
import qs.config 

Rectangle {
    id: root
    color: Colorscheme.surface_container_high
    radius: 24 

    // ================== 数据获取逻辑 ==================
    property string sysUser: Quickshell.env("USER") || "archirithm"
    property string sysWm: (Quickshell.env("XDG_SESSION_DESKTOP") || "niri").toLowerCase()
    property string sysHost: "archlinux"
    property string sysChassis: "Computer"

    Process {
        id: fetchProc
        // 【核心修复】：彻底抛弃 JSON 拼装，改用纯净的自定义分隔符输出，绝对免疫转义符丢失
        command: ["sh", "-c", "echo \"$(cat /etc/hostname 2>/dev/null)|||$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)|||$(cat /sys/class/dmi/id/chassis_type 2>/dev/null)\""]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                let parts = data.split("|||");
                if (parts.length >= 3) {
                    if (parts[0].trim() !== "") root.sysHost = parts[0].trim();
                    
                    let vendor = parts[1].trim().replace(" Inc.", "").replace(" Corporation", "");
                    if (vendor === "") vendor = "Unknown";
                    
                    let type = parseInt(parts[2]);
                    let typeStr = "Computer";
                    if ([3, 4, 6, 7].includes(type)) typeStr = "Desktop";
                    else if ([8, 9, 10, 11, 31, 32].includes(type)) typeStr = "Notebook";
                    
                    root.sysChassis = typeStr + (vendor !== "Unknown" ? (" " + vendor) : "");
                }
            }
        }
    }

    // ================== 垂直居中布局 ==================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16 
        spacing: 20

        // 左侧：头像
        Item {
            Layout.preferredWidth: 72 
            Layout.preferredHeight: 72
            Layout.alignment: Qt.AlignVCenter
            
            Image {
                id: avatarImg
                anchors.fill: parent
                source: "file:///home/archirithm/Pictures/avatar/shelby.jpg"
                sourceSize: Qt.size(144, 144) 
                fillMode: Image.PreserveAspectCrop
                visible: false 
            }
            Rectangle {
                id: mask
                anchors.fill: parent; radius: 36; visible: false; color: "black"
            }
            OpacityMask {
                anchors.fill: parent; source: avatarImg; maskSource: mask
            }
            Rectangle {
                anchors.fill: parent; radius: 36; color: "transparent"
            }
        }

        // 右侧：信息
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter 
            spacing: 6 

            Text { 
                text: root.sysUser + " @ " + root.sysHost
                color: Colorscheme.on_surface 
                font.pixelSize: 15 
                font.family: Sizes.fontFamily 
                font.bold: true
            }
            Text { 
                text: "Chassis : " + root.sysChassis
                color: Colorscheme.on_surface_variant 
                font.pixelSize: 12
                font.family: Sizes.fontFamily 
            }
            Text { 
                text: "WM : " + root.sysWm
                color: Colorscheme.on_surface_variant 
                font.pixelSize: 12
                font.family: Sizes.fontFamily 
            }
        }
    }
}
