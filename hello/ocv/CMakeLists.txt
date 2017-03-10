cmake_minimum_required (VERSION 2.8)

# RPI ROOT
set( RPI_ROOTFS /home/pi/rpi/rootfs)

# Compiler settings
set( CMAKE_C_COMPILER   "/usr/bin/rpizero-gcc" CACHE FILEPATH "" FORCE)
set( CMAKE_CXX_COMPILER "/usr/bin/rpizero-g++" CACHE FILEPATH "" FORCE)
set( CMAKE_AR           "/usr/bin/rpizero-ar"  CACHE FILEPATH "" FORCE)

# Paths for Find and Linking
set( CMAKE_PREFIX_PATH ${RPI_ROOTFS})
set( OpenCV_DIR        ${RPI_ROOTFS}/usr/share/OpenCV/)
set( RPI_LIBRARY_DIR   "-Wl,-rpath ${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf -Wl,-rpath ${RPI_ROOTFS}/lib/arm-linux-gnueabihf")

# Setup C/CXX flags.
set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${RPI_LIBRARY_DIR}" CACHE STRING "" FORCE)

# Projectname
project(hellocv)

# Include opencv
find_package( OpenCV REQUIRED )
include_directories( ${OpenCV_INCLUDE_DIRS} )

# Source
add_executable(hellocv hello.cpp)

# Libraries
target_link_libraries( hellocv ${OpenCV_LIBS} )
