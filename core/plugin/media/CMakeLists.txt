qt_add_library(ClavisMedia SHARED)

set_target_properties(ClavisMedia PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Media
)

qt_add_qml_module(ClavisMedia
    URI Clavis.Media
    VERSION 1.0
    SOURCES
        src/media_palette_plugin.h
        src/media_palette_plugin.cpp
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Media
)

target_include_directories(ClavisMedia PUBLIC src)

target_link_libraries(ClavisMedia PRIVATE
    ClavisMediaCore
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
)
