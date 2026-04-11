import QtQuick
import QtQuick.Layouts
import qs.config
import qs.Widget.common

Item {
    id: root
    Theme { id: theme }

    Text {
        anchors.centerIn: parent
        text: "【System Content】\n\n之后可以在这里放置 CPU、\n内存、磁盘的环形进度条。"
        horizontalAlignment: Text.AlignHCenter
        font.family: "LXGW WenKai GB Screen"
        font.pixelSize: 15
        color: theme.subtext
        lineHeight: 1.4
    }
}
