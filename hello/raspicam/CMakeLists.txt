cmake_minimum_required (VERSION 2.8.11)

project(hellocam)

################
# RPI SETTINGS

#rpi-dirs
set(RPI_ROOTFS /home/pi/rpi/rootfs)
set(USERLAND /usr/src/userland)

#compiler
set(CMAKE_C_COMPILER rpizero-gcc)
set(CMAKE_CXX_COMPILER rpizero-g++)
set(ARM_LINUX_SYSROOT ${RPI_ROOTFS})

################
# COMPILER SETTINGS

SET(COMPILE_DEFINITIONS -Werror)

################
# LOCATIONS / 

#include threads
find_package( Threads REQUIRED )

#include userland
include_directories(${RPI_ROOTFS}${USERLAND})
include_directories(${RPI_ROOTFS}${USERLAND}/host_applications/linux/libs/bcm_host/include)
include_directories(${RPI_ROOTFS}${USERLAND}/host_applications/linux/libs/sm)

#include opt/vc
include_directories(${RPI_ROOTFS}/opt/vc/include)

#include projectdirs
include_directories(${CMAKE_SOURCE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/gl_scenes)

#location of rpi-libraries
link_directories(${RPI_ROOTFS}/opt/vc/lib )

################
# SOURCES

set (GL_SCENE_SOURCES
    gl_scenes/models.c
    gl_scenes/mirror.c
    gl_scenes/yuv.c
    gl_scenes/sobel.c
    gl_scenes/square.c
    gl_scenes/teapot.c
    gl_scenes/vcsm_square.c
)

set (COMMON_SOURCES
    RaspiCamControl.c
    RaspiCLI.c
    RaspiPreview.c
)

set (HELLOCAM_SOURCES
    RaspiStill.c  
    RaspiTex.c 
    RaspiTexUtil.c 
    tga.c
)

add_executable(hellocam ${HELLOCAM_SOURCES} ${COMMON_SOURCES} ${GL_SCENE_SOURCES})

################
# LIBS

#libraries..
target_link_libraries(hellocam ${CMAKE_THREAD_LIBS_INIT})

target_link_libraries(hellocam mmal_core)
target_link_libraries(hellocam mmal_util)
target_link_libraries(hellocam mmal_vc_client)

target_link_libraries(hellocam vcos)
target_link_libraries(hellocam vcsm)
target_link_libraries(hellocam bcm_host)
target_link_libraries(hellocam brcmGLESv2)
target_link_libraries(hellocam brcmEGL)

target_link_libraries(hellocam m)
