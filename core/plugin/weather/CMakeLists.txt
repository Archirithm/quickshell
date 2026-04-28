qt_add_library(ClavisWeather SHARED)

set_target_properties(ClavisWeather PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Weather
)

qt_add_qml_module(ClavisWeather
    URI Clavis.Weather
    VERSION 1.0
    SOURCES
        src/weather_plugin.h
        src/weather_plugin.cpp
        src/weather_list_model.h
        src/weather_list_model.cpp
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Clavis/Weather
)

target_include_directories(ClavisWeather PUBLIC src)

target_link_libraries(ClavisWeather PRIVATE
    ClavisWeatherCore
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Network
)
