cmake_minimum_required(VERSION 3.16)
project(ClavisCore VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# globally enable MOC to parse Q_OBJECT macros
set(CMAKE_AUTOMOC ON)

# Find Qt 6 basics
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Network)
qt_standard_project_setup(REQUIRES 6.5)

# Base reusable logic
add_subdirectory(src)

# Quickshell plugins
add_subdirectory(plugin/sysmon)
add_subdirectory(plugin/weather)
