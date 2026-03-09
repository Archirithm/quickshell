import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.Widget.common 
import qs.Services 

SlideWindow {
    id: root
    title: "通知中心"
    icon: "\uf0f3" 
    windowHeight: 560
    
    extraTopMargin: (WidgetState.networkOpen ? 430 : 0) + (WidgetState.audioOpen ? 370 : 0)
    onIsOpenChanged: WidgetState.notifOpen = isOpen

    headerTools: Text {
        text: "\uf1f8" 
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 18
        
        property bool hasAnyNotif: (NotificationManager.appHistoryModel && NotificationManager.appHistoryModel.count > 0) || 
                                   (NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count > 0)
        color: hasAnyNotif ? Colorscheme.error : Colorscheme.on_surface_variant
        opacity: hasAnyNotif ? 1 : 0.5
        
        MouseArea { 
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: NotificationManager.clearAllHistory()
        }
    }

    component NotifCard : Rectangle {
        property string msgSummary: ""
        property string msgBody: ""
        property string msgTime: ""
        property string msgImage: ""
        property bool isSystem: false
        property int msgIndex: -1

        width: ListView.view ? ListView.view.width : parent.width
        height: Math.max(60, contentLayout.implicitHeight + 20)
        radius: 8
        color: "transparent"
        
        border.width: 1
        border.color: ma.containsMouse ? Colorscheme.primary : "transparent"
        Behavior on border.color { ColorAnimation { duration: 150 } }

        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignTop
                width: 40; height: 40; radius: 8
                color: Qt.rgba(Colorscheme.primary.r, Colorscheme.primary.g, Colorscheme.primary.b, 0.1)
                clip: true

                property bool isIconName: msgImage.startsWith("icon:")
                property string cleanPath: isIconName ? msgImage.substring(5) : msgImage

                Image {
                    id: img
                    anchors.fill: parent; anchors.margins: parent.isIconName ? 6 : 0
                    source: parent.isIconName ? ("image://icon/" + parent.cleanPath) : parent.cleanPath
                    fillMode: parent.isIconName ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                    visible: parent.cleanPath !== "" && status === Image.Ready
                    asynchronous: true
                }
            
                Text {
                    anchors.centerIn: parent
                    visible: parent.cleanPath === "" || img.status === Image.Error
                    text: isSystem ? "💬" : "\uf0e5" 
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 20
                    color: Colorscheme.on_surface_variant
                }
            }

            ColumnLayout {
                id: contentLayout
                Layout.fillWidth: true; spacing: 2
                
                RowLayout {
                    Layout.fillWidth: true
                    Text { 
                        text: msgSummary; font.bold: true; font.pixelSize: 13
                        color: Colorscheme.primary; elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    Text { text: msgTime; font.pixelSize: 10; color: Colorscheme.on_surface_variant }
                }

                Text {
                    text: msgBody; font.pixelSize: 12; color: Colorscheme.on_surface_variant
                    wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
            
            Text {
                visible: ma.containsMouse; text: "\uf00d"
                font.family: "Font Awesome 6 Free Solid"; color: Colorscheme.on_surface_variant
                Layout.alignment: Qt.AlignTop
                
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (isSystem) NotificationManager.removeSysHistory(msgIndex)
                        else NotificationManager.removeAppHistory(msgIndex)
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true; Layout.fillHeight: true
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        visible: NotificationManager.appHistoryModel && NotificationManager.appHistoryModel.count === 0 && 
                 NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count === 0
        text: "没有新通知"
        color: Colorscheme.on_surface_variant
        font.pixelSize: 14
    }

    ListView {
        id: mainList
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !((NotificationManager.appHistoryModel && NotificationManager.appHistoryModel.count === 0) && 
                   (NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count === 0))
        clip: true
        spacing: 8
        
        model: NotificationManager.appHistoryModel

        // ============================================================
        // 【核心修复】：改用原生的 Column 排版，彻底阻断 Layout 引擎的间距跳跃！
        // ============================================================
        header: Column {
            id: sysHeaderContainer
            width: mainList.width
            // 注意：这里绝对不加 spacing，所有的间距都在下方的 Wrapper 里用数学算出来！
            
            property bool sysExpanded: false
            visible: NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count > 0

            property int _prevSysCount: NotificationManager.sysHistoryModel ? NotificationManager.sysHistoryModel.count : 0
            property int unreadSysCount: _prevSysCount 
            
            Connections {
                target: NotificationManager.sysHistoryModel
                ignoreUnknownSignals: true
                function onCountChanged() {
                    let current = NotificationManager.sysHistoryModel.count;
                    if (current > sysHeaderContainer._prevSysCount) {
                        sysHeaderContainer.unreadSysCount += (current - sysHeaderContainer._prevSysCount);
                    } else if (current === 0) {
                        sysHeaderContainer.unreadSysCount = 0;
                    }
                    sysHeaderContainer._prevSysCount = current;
                }
            }

            // 1. 【样式伪装】：完全还原成 NotifCard 的长相
            Rectangle {
                width: parent.width
                height: 60 // 与 NotifCard 基础高度对齐
                radius: 8  // 与 NotifCard 圆角对齐
                color: "transparent" // 【去除了高亮底色】
                border.width: 1
                border.color: sysMa.containsMouse ? Colorscheme.primary : "transparent"
                Behavior on border.color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: sysMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sysHeaderContainer.sysExpanded = !sysHeaderContainer.sysExpanded;
                        if (sysHeaderContainer.sysExpanded) sysHeaderContainer.unreadSysCount = 0; 
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10 // 与 NotifCard 的外边距对齐
                    spacing: 12
                    
                    property var latestSysMsg: NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count > 0 ? NotificationManager.sysHistoryModel.get(0) : null

                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 8
                        color: Qt.rgba(Colorscheme.primary.r, Colorscheme.primary.g, Colorscheme.primary.b, 0.1)
                        clip: true

                        property bool isIconName: parent.latestSysMsg && parent.latestSysMsg.imagePath !== undefined && parent.latestSysMsg.imagePath.startsWith("icon:")
                        property string cleanPath: isIconName ? parent.latestSysMsg.imagePath.substring(5) : (parent.latestSysMsg && parent.latestSysMsg.imagePath ? parent.latestSysMsg.imagePath : "")

                        Image {
                            anchors.fill: parent; anchors.margins: parent.isIconName ? 6 : 0
                            source: parent.isIconName ? ("image://icon/" + parent.cleanPath) : parent.cleanPath
                            fillMode: parent.isIconName ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                            visible: parent.cleanPath !== "" && status === Image.Ready
                            asynchronous: true
                        }

                        Text { 
                            anchors.centerIn: parent
                            text: "💬" 
                            font.pixelSize: 20 
                            color: Colorscheme.on_surface_variant
                            visible: parent.cleanPath === "" 
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text {
                            text: parent.latestSysMsg ? parent.latestSysMsg.summary : "系统通知"
                            font.bold: true; font.pixelSize: 13
                            color: Colorscheme.primary // 与 NotifCard 标题颜色对齐
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        Text {
                            text: parent.latestSysMsg ? parent.latestSysMsg.body : ""
                            font.pixelSize: 12; color: Colorscheme.on_surface_variant
                            elide: Text.ElideRight; maximumLineCount: 1; Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: pillText.contentWidth + 16
                        radius: 12
                        color: Colorscheme.primary
                        visible: sysHeaderContainer.unreadSysCount > 0 

                        Text {
                            id: pillText
                            anchors.centerIn: parent
                            text: sysHeaderContainer.unreadSysCount + " 条新消息"
                            font.pixelSize: 11; font.bold: true; color: Colorscheme.on_primary
                        }
                    }
                    
                    Text {
                        text: sysHeaderContainer.sysExpanded ? "\uf077" : "\uf078"
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 14; color: Colorscheme.on_surface_variant
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // 2. 【防跳跃动画层】：把展开后的 8px 间距直接塞进高度里算！
            Item {
                width: parent.width
                // 魔法就在这里：只有展开时，高度才等于 列表内容高度 + 8px间距。收起时，高度和间距一并完美归零！
                height: sysHeaderContainer.sysExpanded ? sysList.contentHeight + 8 : 0
                opacity: sysHeaderContainer.sysExpanded ? 1.0 : 0.0
                clip: true 
                
                Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

                ListView {
                    id: sysList
                    y: 8 // 给列表下移 8px，制造出与上方标题栏的间距
                    width: parent.width
                    height: contentHeight
                    interactive: false 
                    spacing: 8
                    model: NotificationManager.sysHistoryModel
                    
                    delegate: NotifCard {
                        isSystem: true
                        msgIndex: index
                        msgSummary: model.summary !== undefined ? model.summary : ""
                        msgBody: model.body !== undefined ? model.body : ""
                        msgTime: model.time !== undefined ? model.time : ""
                        msgImage: model.imagePath !== undefined ? model.imagePath : ""
                    }
                }
            }
        }

        delegate: NotifCard {
            isSystem: false
            msgIndex: index
            msgSummary: model.summary !== undefined ? model.summary : ""
            msgBody: model.body !== undefined ? model.body : ""
            msgTime: model.time !== undefined ? model.time : ""
            msgImage: model.imagePath !== undefined ? model.imagePath : ""
        }
    }
}
