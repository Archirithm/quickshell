import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.Widget.common 
import qs.Services 

WidgetPanel {
    id: root
    title: "通知中心"
    icon: "\uf0f3" 
    closeAction: () => WidgetState.notifOpen = false

    headerTools: Text {
        text: "\uf1f8" 
        font.family: "Font Awesome 6 Free Solid"
        font.pixelSize: 18
        
        property bool hasAnyNotif: (NotificationManager.appHistoryModel && NotificationManager.appHistoryModel.count > 0) || (NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count > 0)
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
        height: Math.max(80, contentLayout.implicitHeight + 24) // 增高基础卡片高度
        radius: 12
        color: "transparent"
        border.width: 1
        border.color: ma.containsMouse ? Colorscheme.primary : "transparent"
        Behavior on border.color { ColorAnimation { duration: 150 } }

        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true }

        RowLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 16
            Rectangle {
                Layout.alignment: Qt.AlignTop
                width: 56; height: 56; radius: 12 // 放大头像框
                color: Qt.rgba(Colorscheme.primary.r, Colorscheme.primary.g, Colorscheme.primary.b, 0.1)
                clip: true

                property bool isIconName: msgImage.startsWith("icon:")
                property string cleanPath: isIconName ? msgImage.substring(5) : msgImage

                Image {
                    id: img; anchors.fill: parent; anchors.margins: parent.isIconName ? 8 : 0
                    source: parent.isIconName ? ("image://icon/" + parent.cleanPath) : parent.cleanPath
                    fillMode: parent.isIconName ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                    visible: parent.cleanPath !== "" && status === Image.Ready; asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: parent.cleanPath === "" || img.status === Image.Error
                    text: isSystem ? "💬" : "\uf0e5" 
                    font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 28; color: Colorscheme.on_surface_variant // 放大默认图标
                }
            }

            ColumnLayout {
                id: contentLayout
                Layout.fillWidth: true; spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: msgSummary; font.bold: true; font.pixelSize: 18; color: Colorscheme.primary; elide: Text.ElideRight; Layout.fillWidth: true } // 放大标题
                    Text { text: msgTime; font.pixelSize: 14; color: Colorscheme.on_surface_variant } // 放大时间
                }
                Text {
                    text: msgBody; font.pixelSize: 16; color: Colorscheme.on_surface_variant // 放大正文
                    wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
            
            Text {
                visible: ma.containsMouse; text: "\uf00d"
                font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 18; color: Colorscheme.on_surface_variant
                Layout.alignment: Qt.AlignTop
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (isSystem) NotificationManager.removeSysHistory(msgIndex); else NotificationManager.removeAppHistory(msgIndex); }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true; Layout.fillHeight: true
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        visible: NotificationManager.appHistoryModel && NotificationManager.appHistoryModel.count === 0 && NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count === 0
        text: "没有新通知"; color: Colorscheme.on_surface_variant; font.pixelSize: 14
    }

    ListView {
        id: mainList
        Layout.fillWidth: true; Layout.fillHeight: true
        visible: !((NotificationManager.appHistoryModel && NotificationManager.appHistoryModel.count === 0) && (NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count === 0))
        clip: true; spacing: 8
        model: NotificationManager.appHistoryModel

        header: Column {
            id: sysHeaderContainer
            width: mainList.width
            property bool sysExpanded: false
            visible: NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count > 0

            property int _prevSysCount: NotificationManager.sysHistoryModel ? NotificationManager.sysHistoryModel.count : 0
            property int unreadSysCount: _prevSysCount 
            
            Connections {
                target: NotificationManager.sysHistoryModel
                ignoreUnknownSignals: true
                function onCountChanged() {
                    let current = NotificationManager.sysHistoryModel.count;
                    if (current > sysHeaderContainer._prevSysCount) { sysHeaderContainer.unreadSysCount += (current - sysHeaderContainer._prevSysCount); } 
                    else if (current === 0) { sysHeaderContainer.unreadSysCount = 0; }
                    sysHeaderContainer._prevSysCount = current;
                }
            }

            Rectangle {
                width: parent.width; height: 60; radius: 8; color: "transparent"
                border.width: 1; border.color: sysMa.containsMouse ? Colorscheme.primary : "transparent"
                Behavior on border.color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: sysMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { sysHeaderContainer.sysExpanded = !sysHeaderContainer.sysExpanded; if (sysHeaderContainer.sysExpanded) sysHeaderContainer.unreadSysCount = 0; }
                }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 12
                    property var latestSysMsg: NotificationManager.sysHistoryModel && NotificationManager.sysHistoryModel.count > 0 ? NotificationManager.sysHistoryModel.get(0) : null

                    Rectangle {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 8
                        color: Qt.rgba(Colorscheme.primary.r, Colorscheme.primary.g, Colorscheme.primary.b, 0.1); clip: true
                        property bool isIconName: parent.latestSysMsg && parent.latestSysMsg.imagePath !== undefined && parent.latestSysMsg.imagePath.startsWith("icon:")
                        property string cleanPath: isIconName ? parent.latestSysMsg.imagePath.substring(5) : (parent.latestSysMsg && parent.latestSysMsg.imagePath ? parent.latestSysMsg.imagePath : "")

                        Image {
                            anchors.fill: parent; anchors.margins: parent.isIconName ? 6 : 0
                            source: parent.isIconName ? ("image://icon/" + parent.cleanPath) : parent.cleanPath
                            fillMode: parent.isIconName ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                            visible: parent.cleanPath !== "" && status === Image.Ready; asynchronous: true
                        }
                        Text { anchors.centerIn: parent; text: "💬"; font.pixelSize: 20; color: Colorscheme.on_surface_variant; visible: parent.cleanPath === "" }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: parent.latestSysMsg ? parent.latestSysMsg.summary : "系统通知"; font.bold: true; font.pixelSize: 13; color: Colorscheme.primary; elide: Text.ElideRight; Layout.fillWidth: true }
                        Text { text: parent.latestSysMsg ? parent.latestSysMsg.body : ""; font.pixelSize: 12; color: Colorscheme.on_surface_variant; elide: Text.ElideRight; maximumLineCount: 1; Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter; Layout.preferredHeight: 24; Layout.preferredWidth: pillText.contentWidth + 16
                        radius: 12; color: Colorscheme.primary; visible: sysHeaderContainer.unreadSysCount > 0 
                        Text { id: pillText; anchors.centerIn: parent; text: sysHeaderContainer.unreadSysCount + " 条新消息"; font.pixelSize: 11; font.bold: true; color: Colorscheme.on_primary }
                    }
                    Text { text: sysHeaderContainer.sysExpanded ? "\uf077" : "\uf078"; font.family: "Font Awesome 6 Free Solid"; font.pixelSize: 14; color: Colorscheme.on_surface_variant; Layout.alignment: Qt.AlignVCenter }
                }
            }

            Item {
                width: parent.width
                height: sysHeaderContainer.sysExpanded ? sysList.contentHeight + 8 : 0
                opacity: sysHeaderContainer.sysExpanded ? 1.0 : 0.0; clip: true 
                Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

                ListView {
                    id: sysList; y: 8; width: parent.width; height: contentHeight; interactive: false ; spacing: 8
                    model: NotificationManager.sysHistoryModel
                    delegate: NotifCard {
                        isSystem: true; msgIndex: index
                        msgSummary: model.summary !== undefined ? model.summary : ""
                        msgBody: model.body !== undefined ? model.body : ""
                        msgTime: model.time !== undefined ? model.time : ""
                        msgImage: model.imagePath !== undefined ? model.imagePath : ""
                    }
                }
            }
        }

        delegate: NotifCard {
            isSystem: false; msgIndex: index
            msgSummary: model.summary !== undefined ? model.summary : ""
            msgBody: model.body !== undefined ? model.body : ""
            msgTime: model.time !== undefined ? model.time : ""
            msgImage: model.imagePath !== undefined ? model.imagePath : ""
        }
    }
}
