qt_add_library(ClavisSysmon SHARED)

set_target_properties(ClavisSysmon PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Sysmon
)

qt_add_qml_module(ClavisSysmon
    URI Clavis.Sysmon
    VERSION 1.0
    SOURCES
        src/sysmon_plugin.h
        src/sysmon_plugin.cpp
        src/process_model.h
        src/process_model.cpp
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Sysmon
)

target_include_directories(ClavisSysmon PUBLIC src)

target_link_libraries(ClavisSysmon PRIVATE
    ClavisSysmonCore
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
)
