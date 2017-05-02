cmake_minimum_required (VERSION 2.8.11)

# Projectname
project(wpi)

#include required packages
find_package( PkgConfig REQUIRED )

# WiringPi
pkg_search_module(WIRINGPI REQUIRED wiringpi)
include_directories(${WIRINGPI_INCLUDE_DIRS})
link_directories(${WIRINGPI_LIBRARY_DIRS} )

# Source
add_executable(wpi pwm.c)

# Libraries
target_link_libraries(wpi ${WIRINGPI_LIBRARIES})

