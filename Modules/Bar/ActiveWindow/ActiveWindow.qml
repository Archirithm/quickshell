import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Services
import qs.config

Item {
    id: root

    implicitHeight: 36
    implicitWidth: layout.width + 24

    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    property string activeTitle: "Desktop"
    property string activeAppId: ""

    function updateActiveWindow() {
        let found = false;
        for (let i = 0; i < Niri.windows.count; i++) {
            const win = Niri.windows.get(i);
            if (win.isFocused) {
                activeTitle = win.title;
                activeAppId = win.appId;
                found = true;
                break;
            }
        }
        if (!found) {
            activeTitle = "Desktop";
            activeAppId = "";
        }
    }

    Connections {
        target: Niri
        function onWindowsUpdated() {
            root.updateActiveWindow();
        }
    }

    Component.onCompleted: updateActiveWindow()

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: Colorscheme.background
        radius: height / 2
        visible: false
    }

    MultiEffect {
        source: bgRect
        anchors.fill: bgRect
        shadowEnabled: true
        shadowColor: Qt.alpha(Colorscheme.shadow, 0.4)
        shadowBlur: 0.8
        shadowVerticalOffset: 3
        shadowHorizontalOffset: 0
    }

    RowLayout {
        id: layout
        
        
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        
        anchors.leftMargin: 12 
        
        spacing: 10
        Item {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter

            scale: mouseArea.containsMouse ? 1.15 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Image {
                id: paperPlaneIcon
                source: "file:///home/archirithm/.config/quickshell/assets/icons/Paper-Plane.svg"
                anchors.fill: parent
                sourceSize.width: 18
                sourceSize.height: 18
                fillMode: Image.PreserveAspectFit
                visible: false // 隐藏原黑图
            }

            // 完美复刻 LockSurface 的做法！
            MultiEffect {
                source: paperPlaneIcon
                anchors.fill: paperPlaneIcon
                colorization: 1.0
                colorizationColor: Colorscheme.primary 
                brightness: 1.0  // <--- 加上这一行，瞬间破局！
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // 【核心修改】：点击切换左侧边栏的开关状态
                    WidgetState.leftSidebarOpen = !WidgetState.leftSidebarOpen;
                }
            }
        }

        // --- 2. 右侧：窗口名称 ---
        Text {
            id: windowTitle
            text: root.activeTitle
            
            font.family: "LXGW WenKai GB Screen"
            font.pointSize: 11
            color: Colorscheme.on_surface
            
            Layout.maximumWidth: 250 
            elide: Text.ElideRight
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
