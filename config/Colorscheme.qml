pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property color background : "#0f1416"
    property color error : "#ffb4ab"
    property color error_container : "#93000a"
    property color inverse_on_surface : "#2c3134"
    property color inverse_primary : "#09677f"
    property color inverse_surface : "#dee3e6"
    property color on_background : "#dee3e6"
    property color on_error : "#690005"
    property color on_error_container : "#ffdad6"
    property color on_primary : "#003544"
    property color on_primary_container : "#b8eaff"
    property color on_primary_fixed : "#001f28"
    property color on_primary_fixed_variant : "#004d61"
    property color on_secondary : "#1e333c"
    property color on_secondary_container : "#cfe6f1"
    property color on_secondary_fixed : "#071e26"
    property color on_secondary_fixed_variant : "#354a53"
    property color on_surface : "#dee3e6"
    property color on_surface_variant : "#bfc8cc"
    property color on_tertiary : "#2c2d4d"
    property color on_tertiary_container : "#e1e0ff"
    property color on_tertiary_fixed : "#171837"
    property color on_tertiary_fixed_variant : "#434465"
    property color outline : "#8a9296"
    property color outline_variant : "#40484c"
    property color primary : "#88d0ec"
    property color primary_container : "#004d61"
    property color primary_fixed : "#b8eaff"
    property color primary_fixed_dim : "#88d0ec"
    property color scrim : "#000000"
    property color secondary : "#b3cad5"
    property color secondary_container : "#354a53"
    property color secondary_fixed : "#cfe6f1"
    property color secondary_fixed_dim : "#b3cad5"
    property color shadow : "#000000"
    property color source_color : "#669cb1"
    property color surface : "#0f1416"
    property color surface_bright : "#353a3d"
    property color surface_container : "#1b2023"
    property color surface_container_high : "#252b2d"
    property color surface_container_highest : "#303638"
    property color surface_container_low : "#171c1f"
    property color surface_container_lowest : "#0a0f11"
    property color surface_dim : "#0f1416"
    property color surface_tint : "#88d0ec"
    property color surface_variant : "#40484c"
    property color tertiary : "#c3c3eb"
    property color tertiary_container : "#434465"
    property color tertiary_fixed : "#e1e0ff"
    property color tertiary_fixed_dim : "#c3c3eb"

    // 纯净版热重载引擎
    FileView {
        id: colorFile
        path: Quickshell.env("HOME") + "/.cache/quickshell_colors.json"
        watchChanges: true 

        onLoaded: {
            try {
                const text = colorFile.text();
                if (!text) return;
                
                const newColors = JSON.parse(text); 
                for (let key in newColors) {
                    if (key in root && typeof root[key] !== "function") {
                        let newColorValue = Qt.color(newColors[key]);
                        if (root[key] !== newColorValue) {
                            root[key] = newColorValue;
                        }
                    }
                }
            } catch (e) {
                // 静默失败，保持纯净，不输出任何冗余日志
            }
        }
        
        onFileChanged: colorFile.reload()
    }
}
