import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 160
    
    // 使用全局配置的颜色和圆角
    color: Colorscheme.surface_container
    radius: Sizes.lockCardRadius

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Sizes.lockCardPadding
        spacing: 0

        // 左上角引号
        Text {
            text: "“"
            // 使用次级文字颜色，或者用 primary 强调色
            color: Colorscheme.on_surface_variant 
            font.pixelSize: 60
            font.family: Sizes.fontFamily
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.preferredHeight: 40
        }

        // 中间正文
        Text {
            text: "休息一下，\n马上回来。"
            color: Colorscheme.on_surface
            font.family: Sizes.fontFamily
            font.pixelSize: 26
            font.bold: true
            font.italic: true
            
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            lineHeight: 1.3
        }

        // 右下角引号
        Text {
            text: "”"
            color: Colorscheme.on_surface_variant
            font.pixelSize: 60
            font.family: Sizes.fontFamily
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Layout.preferredHeight: 40
        }
    }
}
