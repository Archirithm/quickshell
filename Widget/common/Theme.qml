import QtQuick
import qs.config

QtObject {
    property color background: Colorscheme.background
    property color surface: Colorscheme.surface
    property color primary: Colorscheme.primary
    property color error: Colorscheme.error
    property color text: Colorscheme.inverse_primary
    property color subtext: Colorscheme.secondary
    property color outline: Colorscheme.outline
    property int radius: 12
    property int padding: 16
}
