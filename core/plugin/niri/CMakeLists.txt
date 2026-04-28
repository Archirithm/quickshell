qt_add_library(ClavisNiri SHARED)

set_target_properties(ClavisNiri PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Niri
)

qt_add_qml_module(ClavisNiri
    URI Clavis.Niri
    VERSION 1.0
    SOURCES
        src/niri_plugin.h
        src/niri_plugin.cpp
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Niri
)

target_include_directories(ClavisNiri PUBLIC src)

target_link_libraries(ClavisNiri PRIVATE
    ClavisNiriCore
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Network
)
