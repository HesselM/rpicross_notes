cmake_minimum_required (VERSION 2.8.11)

project(hellocam)

SET( COMPILE_DEFINITIONS -Werror )

# include required packages
find_package( Threads REQUIRED )
find_package( PkgConfig REQUIRED )

# MMAL
pkg_search_module(MMAL REQUIRED mmal)
include_directories(${MMAL_INCLUDE_DIRS})
link_directories(${MMAL_LIBRARY_DIRS} )
set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-rpath ${MMAL_LIBRARY_DIRS}" )

# Userland
include_directories(${USERLAND_DIR})
include_directories(${USERLAND_DIR}/host_applications/linux/libs/sm)
include_directories(${USERLAND_DIR}/host_applications/linux/libs/bcm_host/include)

# Projectdirs
include_directories(${CMAKE_SOURCE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/gl_scenes)

# Sources
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
    RaspiCommonSettings.c
    RaspiHelpers.c
    RaspiGPS.c
    libgps_loader.c
)

set (HELLOCAM_SOURCES
    RaspiStill.c
    RaspiTex.c
    RaspiTexUtil.c
    tga.c
)

add_executable(hellocam ${HELLOCAM_SOURCES} ${COMMON_SOURCES} ${GL_SCENE_SOURCES})


# Libraries
target_link_libraries(hellocam ${CMAKE_THREAD_LIBS_INIT})
target_link_libraries(hellocam ${MMAL_LIBRARIES})
target_link_libraries(hellocam bcm_host)
target_link_libraries(hellocam brcmGLESv2)
target_link_libraries(hellocam brcmEGL)
target_link_libraries(hellocam m)
target_link_libraries(hellocam dl)
