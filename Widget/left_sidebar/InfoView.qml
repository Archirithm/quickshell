import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.config
import qs.Widget.common
import "../../JS/weather.js" as WeatherService

Item {
    id: root
    Theme { id: theme }

    // ==========================================
    // 全局绑定与状态 (当面板可见时智能运行)
    // ==========================================
    property bool isForeground: WidgetState.leftSidebarOpen && WidgetState.leftSidebarView === "info"

    property string valChassis: "Loading..."
    property string valWeatherIcon: "cloud"
    property string valWeatherDesc: "fetching..."
    property string valTemp: "--°C"
    property string valRam: "Measuring..."
    property string valOsAge: "Calculating..."
    property string valUptime: "Waiting..."
    property double lastWeatherFetchTime: 0

    onIsForegroundChanged: {
        if (isForeground) {
            // 每当展开侧边栏时，直接唤醒快速收集进程以防止用户等待
            if (!ramProc.running) ramProc.running = true;
            if (!detailsProc.running) detailsProc.running = true;

            // 天气具有缓存保护：如果距上一次拉取超过 1 小时 (3600000ms)，才触发新一轮接口。
            let curr = new Date().getTime();
            if (curr - root.lastWeatherFetchTime > 3600000) {
                root.lastWeatherFetchTime = curr;
                WeatherService.fetchLocationAndWeather(function(data) {
                    if (data && data.current) {
                        root.valTemp = data.current.temperature_2m + "°C";
                        root.valWeatherDesc = WeatherService.getWeatherDesc(data.current.weather_code).toLowerCase();
                        root.valWeatherIcon = WeatherService.getMaterialIcon(data.current.weather_code);
                    }
                });
            }
        }
    }

    Timer {
        id: ramTimer
        interval: 5000 // 5 秒监测一次系统资源
        running: root.isForeground 
        repeat: true
        onTriggered: {
            if (!ramProc.running) {
                ramProc.running = true;
            }
        }
    }

    Process {
        id: ramProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/sys_monitor.py"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data.trim());
                    if (d.ram && d.ram.text) {
                        // sys_monitor 默认会输出 X.XG 的样式的字符串
                        root.valRam = d.ram.text + " / 16 GiB";
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: detailsProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/sys_details.py"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    let d = JSON.parse(data.trim());
                    if (d.chassis) root.valChassis = d.chassis;
                    if (d.os_age) root.valOsAge = d.os_age;
                    if (d.uptime) root.valUptime = d.uptime;
                } catch(e) {}
            }
        }
    }

    // ==========================================
    // UI Layout
    // ==========================================
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 40
        spacing: 12

        // 1. 周几 (Day of the week)
        Text {
            Layout.alignment: Qt.AlignHCenter
            // 简单的 JS 取名方式，不再设置定时器，利用 isForeground 更改使得每次拉开面板也会动态刷新
            text: Qt.formatDateTime(new Date(), "dddd") 
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 45
            font.bold: true
            color: theme.error
        }

        // 2. 日期 (Date)
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(new Date(), "dd MMMM yyyy") 
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22
            font.bold: true
            color: theme.subtext
            Layout.topMargin: -8 
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 15
        }

        // 3. 用户头像
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 180
            height: 180

            Image {
                id: avatarImg
                anchors.fill: parent
                source: "file:///home/archirithm/Pictures/avatar/shelby.jpg"
                sourceSize: Qt.size(360, 360) 
                fillMode: Image.PreserveAspectCrop
                mipmap: true
                cache: false
                visible: false 
            }
            
            Rectangle {
                id: mask
                anchors.fill: parent
                radius: 90
                visible: false
                color: "black"
            }
            
            OpacityMask {
                anchors.fill: parent
                source: avatarImg
                maskSource: mask
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 5
        }

        // 4. 用户名
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "archirithm"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 36
            font.bold: true
            color: theme.error
        }

        // 5. 账号名
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "@archlinux"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: theme.subtext
            Layout.topMargin: -6
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 
        }

        // 6 ~ 10. 详细数据列阵
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 320 
            spacing: 24

            // (1) 电脑型号 Chassis
            RowLayout {
                Layout.fillWidth: true
                spacing: 25
                Text {
                    text: "laptop_mac"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: theme.primary
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.valChassis
                    font.family: "LXGW WenKai GB Screen"
                    font.pixelSize: 26 
                    color: theme.text
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // (2) 天气 Weather
            RowLayout {
                Layout.fillWidth: true
                spacing: 25
                Text {
                    text: root.valWeatherIcon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: "#8ab4f8"
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.valWeatherDesc
                    font.family: "LXGW WenKai GB Screen"
                    font.pixelSize: 26 
                    color: theme.text
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // (3) 气温 Temperature
            RowLayout {
                Layout.fillWidth: true
                spacing: 25
                Text {
                    text: "device_thermostat"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: theme.error
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.valTemp
                    font.family: "LXGW WenKai GB Screen"
                    font.pixelSize: 26 
                    color: theme.text
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // (4) 内存占用 RAM
            RowLayout {
                Layout.fillWidth: true
                spacing: 25
                Text {
                    text: "memory"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: "#cba6f7"
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.valRam
                    font.family: "LXGW WenKai GB Screen"
                    font.pixelSize: 26 
                    color: theme.text
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // (5) OS 系统年龄 Age
            RowLayout {
                Layout.fillWidth: true
                spacing: 25
                Text {
                    text: "cake"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: "#81c995"
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.valOsAge
                    font.family: "LXGW WenKai GB Screen"
                    font.pixelSize: 26 
                    color: theme.text
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // (6) 运行时间 Uptime
            RowLayout {
                Layout.fillWidth: true
                spacing: 25
                Text {
                    text: "timer"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: "#fcad70"
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: root.valUptime
                    font.family: "LXGW WenKai GB Screen"
                    font.pixelSize: 26 
                    color: theme.text
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
