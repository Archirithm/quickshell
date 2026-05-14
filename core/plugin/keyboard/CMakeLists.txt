qt_add_library(ClavisKeyboard SHARED)

set_target_properties(ClavisKeyboard PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Keyboard
)

qt_add_qml_module(ClavisKeyboard
    URI Clavis.Keyboard
    VERSION 1.0
    SOURCES
        src/keyboard_lock_plugin.h
        src/keyboard_lock_plugin.cpp
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Keyboard
)

target_include_directories(ClavisKeyboard PUBLIC src)

target_link_libraries(ClavisKeyboard PRIVATE
    Qt6::Core
    Qt6::Qml
)
