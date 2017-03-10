cmake_minimum_required (VERSION 2.8.11)

set(RPI_ROOTFS /home/pi/rpi/rootfs)
project(hello)

#compiler settings
set(CMAKE_C_COMPILER rpizero-gcc)
set(CMAKE_CXX_COMPILER rpizero-g++)
set(ARM_LINUX_SYSROOT ${RPI_ROOTFS})

#source
add_executable(hello hello.cpp)
