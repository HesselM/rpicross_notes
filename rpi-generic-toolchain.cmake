cmake_minimum_required(VERSION 3.8)

set( RPI_ROOTFS "/home/pi/rpi/rootfs" )
set( CMAKE_SYSROOT ${RPI_ROOTFS})

set( CMAKE_FIND_ROOT_PATH ${RPI_ROOTFS} )
set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set( CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# compilers
set( CMAKE_C_COMPILER   "/usr/bin/arm-linux-gnueabihf-gcc"    CACHE FILEPATH "")
set( CMAKE_CXX_COMPILER "/usr/bin/arm-linux-gnueabihf-g++"    CACHE FILEPATH "")
set( CMAKE_AR           "/usr/bin/arm-linux-gnueabihf-ar"     CACHE FILEPATH "")
set( CMAKE_RANLIB       "/usr/bin/arm-linux-gnueabihf-ranlib" CACHE FILEPATH "")

# Platform
set( CMAKE_SYSTEM_NAME Linux )
set( CMAKE_SYSTEM_VERSION 1 )
set( CMAKE_SYSTEM_PROCESSOR arm )
set( CMAKE_LIBRARY_ARCHITECTURE arm-linux-gnueabihf )
set( FLOAT_ABI_SUFFIX "hf" )
add_definitions( "-mcpu=arm1176jzf-s -mfpu=vfp -mfloat-abi=hard -marm" )

# setup RPI include/lib/pkgconfig directories for compiler/pkgconfig
set( RPI_INCLUDE_DIR "${RPI_INCLUDE_DIR} -isystem ${RPI_ROOTFS}/usr/include/arm-linux-gnueabihf")
set( RPI_INCLUDE_DIR "${RPI_INCLUDE_DIR} -isystem ${RPI_ROOTFS}/usr/include")
set( RPI_INCLUDE_DIR "${RPI_INCLUDE_DIR} -isystem ${RPI_ROOTFS}/usr/local/include")

set( RPI_LIBRARY_DIR "${RPI_LIBRARY_DIR} -Wl,-rpath ${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf")
set( RPI_LIBRARY_DIR "${RPI_LIBRARY_DIR} -Wl,-rpath ${RPI_ROOTFS}/lib/arm-linux-gnueabihf")

set( RPI_PKGCONFIG_LIBDIR "${RPI_PKGCONFIG_LIBDIR}:${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/pkgconfig" )
set( RPI_PKGCONFIG_LIBDIR "${RPI_PKGCONFIG_LIBDIR}:${RPI_ROOTFS}/usr/share/pkgconfig" )
set( RPI_PKGCONFIG_LIBDIR "${RPI_PKGCONFIG_LIBDIR}:${RPI_ROOTFS}/opt/vc/lib/pkgconfig" )
set( RPI_PKGCONFIG_LIBDIR "${RPI_PKGCONFIG_LIBDIR}:/home/pi/ros/src_cross/devel_isolated" )

set( RPI_B_PREFIX "${RPI_B_PREFIX} -B${RPI_ROOTFS}")
set( RPI_B_PREFIX "${RPI_B_PREFIX} -B${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf")
set( RPI_B_PREFIX "${RPI_B_PREFIX} -B${RPI_ROOTFS}/lib/arm-linux-gnueabihf")

# C/CXX flagscd
set( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${RPI_B_PREFIX} ${RPI_INCLUDE_DIR}" CACHE STRING "" FORCE)
set( CMAKE_C_FLAGS    "${CMAKE_C_FLAGS} ${RPI_B_PREFIX} ${RPI_INCLUDE_DIR}" CACHE STRING "" FORCE)
set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${RPI_LIBRARY_DIR}" CACHE STRING "" FORCE)

# Pkg-config settings
set( ENV{PKG_CONFIG_DIR}         "" CACHE FILEPATH "")
set( ENV{PKG_CONFIG_LIBDIR}      "${RPI_PKGCONFIG_LIBDIR}" CACHE FILEPATH "")
set( ENV{PKG_CONFIG_SYSROOT_DIR} "${RPI_ROOTFS}" CACHE FILEPATH "")

# Python2.7
#set( PYTHON_EXECUTABLE          "/usr/bin/python2.7" CACHE STRING "")
#et( PYTHON_LIBRARY_DEBUG       "${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/libpython2.7.so" CACHE STRING "")
set( PYTHON_LIBRARY_RELEASE     "${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/libpython2.7.so" CACHE STRING "")
set( PYTHON_LIBRARY             "${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/libpython2.7.so" CACHE STRING "")
set( PYTHON_INCLUDE_DIR         "${RPI_ROOTFS}/usr/include/python2.7" CACHE STRING "")
set( PYTHON2_NUMPY_INCLUDE_DIRS "${RPI_ROOTFS}/usr/lib/python2.7/dist-packages/numpy/core/include" CACHE STRING "")
set( PYTHON2_PACKAGES_PATH      "${RPI_ROOTFS}/usr/local/lib/python2.7/site-packages" CACHE STRING "")

# Boost
set( BOOST_LIBRARYDIR "${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/" CACHE STRING "")

# OpenCV
set( OpenCV_DIR       "${RPI_ROOTFS}/usr/share/OpenCV/" CACHE STRING "")

# Userland / VideoCore
set( USERLAND_DIR     "${RPI_ROOTFS}/usr/src/userland" CACHE STRING "")
