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
#set( RPI_LIBRARY_DIR   "-Wl,-rpath ${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf -Wl,-rpath ${RPI_ROOTFS}/lib/arm-linux-gnueabihf")

# Setup C/CXX flags.
#set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${RPI_LIBRARY_DIR}" CACHE STRING "" FORCE)
#set( CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   ${RPI_LIBRARY_DIR}" CACHE STRING "" FORCE)

set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-rpath ${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf -Wl,-rpath ${RPI_ROOTFS}/lib/arm-linux-gnueabihf" CACHE STRING "" FORCE)

project(hellocv)

#include opencv
find_package( OpenCV REQUIRED )
include_directories( ${OpenCV_INCLUDE_DIRS} )

#source
add_executable(hellocv hello.cpp)

#link libraries
target_link_libraries( hellocv ${OpenCV_LIBS} )
