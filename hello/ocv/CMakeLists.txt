cmake_minimum_required (VERSION 2.8)

# Projectname
project(hellocv)

# Include opencv
find_package( OpenCV REQUIRED )
include_directories( ${OpenCV_INCLUDE_DIRS} )

# Source
add_executable(hellocv hello.cpp)

# Libraries
target_link_libraries( hellocv ${OpenCV_LIBS} )
