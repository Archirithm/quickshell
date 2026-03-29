import QtQuick
import qs.config

QtObject {
    property color background: Colorscheme.background
    property color surface: Colorscheme.surface_container
    property color primary: Colorscheme.primary
    property color error: Colorscheme.error
    property color text: Colorscheme.on_surface
    property color subtext: Colorscheme.on_surface_variant
    property color outline: Colorscheme.outline
    
    // 【修改】：精致的圆角和内边距，适应 420 宽度
    property int radius: 24 
    property int padding: 20 
}
