# Crosscompiling : OpenCV

Before continuing, please make sure you followed the steps in:
- [Setup](1-setup.md)
- [Network/SSH](2-network.md)
- [Crosscompile environment](4-xc-setup.md)
- [Userland](5-xc-userland.md)

This section will cross-compile and install OpenCV, its additional modules and python bindings. 

## Required Packages

To crosscompile `OpenCV`, only packages on the RPi need te be installed.

1. Install packages
    ```
    XCS~$ ssh rpizero-local
    RPI~$ sudo apt-get install python2.7 python-dev python-numpy libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev 
    ```
    
    > Python and numpy need to be installed so `OpenCV` can create the Pythonbindings.
    > Other libraries are used to process images, generate GUI's (via X-server) and other imaging processes.
    
1. Sync packages/headers from RPi to the VM-`rootfs`
    1. Clone repository (if not yet done)
        ```
        XCS~$ mkdir -p ~/rpi/build
        XCS~$ cd ~/rpi/build
        XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
        ```
    
    1. Allow script to be executed (if not yet done)
        ```
        XCS~$ chmod +x ~/rpi/build/rpicross_notes/sync-rpi-vm.sh
        ```

    1. Sync RPi with VM-`rootfs`
        ```
        XCS~$ /home/pi/rpi/build/rpicross_notes/sync-rpi-vm.sh
        ```

## Compilation
1. Download and unzip the `OpenCV` sources.
    ```
    XCS~$ cd ~/rpi/src
    XCS~$ wget https://github.com/opencv/opencv/archive/3.2.0.zip
    XCS~$ unzip 3.2.0.zip 
    XCS~$ rm 3.2.0.zip
    XCS~$ wget https://github.com/opencv/opencv_contrib/archive/3.2.0.zip
    XCS~$ unzip 3.2.0.zip 
    XCS~$ rm 3.2.0.zip 
    ```
1. After downloading, we need to edit the `OpenCV`-arm toolchain as it does not support the Raspberry Pi Zero `armv6 hf` core properly. 
    ```
    XCS~$ nano /home/pi/rpi/src/opencv-3.2.0/platforms/linux/arm.toolchain.cmake
    ```
    
    Change the '-mthumb' flags to '-marm'. The resulting file should look similarly to:
    ```
    ...
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL arm)
      set(CMAKE_CXX_FLAGS           "-marm ${CMAKE_CXX_FLAGS}")
      set(CMAKE_C_FLAGS             "-marm ${CMAKE_C_FLAGS}")
      set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} -Wl,-z,nocopyreloc")
    endif()
    ...
    ```
   
    > The toolchain presumes that a `thumb` instruction set is available which consists of 32 and 16 bits instructions. As it uses multiple widths of instructions, the `thumb` architecture is able to combine instructions and hence speed up processing time. Only `armv7` or higher has this ability, hence it does not apply to the BCM2835 of the RPi.
   
1. Edit libc.so and libpthreads.so 
    > Compilation of `OpenCV` uses `libc.so` and `libpthread.so` located in `/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/`. These two files are not real libraries, but link to those required. Unfortunalty, they include the absolute path from `rootfs`, which will produce compile errors as the compiler cannot find it. Hence we need to edit these.
    > A better solution might be available, as this might cause additional issues, but so far all seems to be ok. 
    
    - libc.so:
        ```
        XCS~$ nano /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libc.so
        ```
            
        Change 
        ```
        GROUP ( /lib/arm-linux-gnueabihf/libc.so.6 /usr/lib/arm-linux-gnueabihf/libc_nonshared.a  AS_NEEDED ( /lib/arm-linux-gnueabihf/ld-linux-armhf.so.3 ) )
        ```
            
        into 
        ```
        GROUP ( libc.so.6 libc_nonshared.a  AS_NEEDED ( ld-linux-armhf.so.3 ) )
        ```
            
    - libpthread.so:
        ```
        XCS~$ nano /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpthread.so
        ```
            
        Change 
        ```
        GROUP ( /lib/arm-linux-gnueabihf/libpthread.so.0 /usr/lib/arm-linux-gnueabihf/libpthread_nonshared.a )
        ```
            
        into 
        ```
        GROUP ( libpthread.so.0 libpthread_nonshared.a )
        ```
            
1. Several `CMAKE` settings need to be configured to compile OpenCV and the Python bindings properly. For convenience `OpenCVMinDepVersions.cmake` is adjusted. 

    ```
    XCS~$ nano /home/pi/rpi/src/opencv-3.2.0/cmake/OpenCVMinDepVersions.cmake 
    ```
    Add the following lines to the cmake file:
  
    ```
    # install dir
    set( CMAKE_INSTALL_PREFIX ${RPI_ROOTFS}/usr CACHE STRING "")
    set( CMAKE_FIND_ROOT_PATH "${RPI_ROOTFS}" CACHE FILEPATH "")
    set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )

    # compilers
    set( CMAKE_C_COMPILER   "/usr/bin/rpizero-gcc"    CACHE FILEPATH "")
    set( CMAKE_CXX_COMPILER "/usr/bin/rpizero-g++"    CACHE FILEPATH "")
    set( CMAKE_AR           "/usr/bin/rpizero-ar"     CACHE FILEPATH "")
    set( CMAKE_RANLIB       "/usr/bin/rpizero-ranlib" CACHE FILEPATH "")

    #Pkg-config settings
    set( RPI_PKGCONFIG_LIBDIR "${RPI_PKGCONFIG_LIBDIR}:${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/pkgconfig" )
    set( RPI_PKGCONFIG_LIBDIR "${RPI_PKGCONFIG_LIBDIR}:${RPI_ROOTFS}/usr/share/pkgconfig" )
    set( RPI_PKGCONFIG_LIBDIR "${RPI_PKGCONFIG_LIBDIR}:${RPI_ROOTFS}/opt/vc/lib/pkgconfig" )

    set( PKG_CONFIG_EXECUTABLE "/usr/bin/pkg-config" CACHE FILEPATH "")
    set( ENV{PKG_CONFIG_DIR}         "" CACHE FILEPATH "")
    set( ENV{PKG_CONFIG_LIBDIR}      "${RPI_PKGCONFIG_LIBDIR}" CACHE FILEPATH "")
    set( ENV{PKG_CONFIG_SYSROOT_DIR} "${RPI_ROOTFS}" CACHE FILEPATH "")

    # setup rpi (target) directories for compiler
    set( RPI_INCLUDE_DIR "${RPI_INCLUDE_DIR} -isystem ${RPI_ROOTFS}/usr/include/arm-linux-gnueabihf")
    set( RPI_INCLUDE_DIR "${RPI_INCLUDE_DIR} -isystem ${RPI_ROOTFS}/usr/include")
    set( RPI_INCLUDE_DIR "${RPI_INCLUDE_DIR} -isystem ${RPI_ROOTFS}/usr/local/include")

    set( RPI_LIBRARY_DIR "${RPI_LIBRARY_DIR} -Wl,-rpath ${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf")
    set( RPI_LIBRARY_DIR "${RPI_LIBRARY_DIR} -Wl,-rpath ${RPI_ROOTFS}/lib/arm-linux-gnueabihf")

    # Setup C/CXX flags.
    set( CMAKE_CXX_FLAGS        "${CMAKE_CXX_FLAGS} ${RPI_INCLUDE_DIR}" CACHE STRING "" FORCE)
    set( CMAKE_C_FLAGS          "${CMAKE_CXX_FLAGS} ${RPI_INCLUDE_DIR}" CACHE STRING "" FORCE)
    set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${RPI_LIBRARY_DIR}" CACHE STRING "" FORCE)

    #Python2.7
    set( PYTHON_EXECUTABLE          /usr/bin/python2.7 CACHE STRING "") 
    set( PYTHON_LIBRARY_DEBUG       "${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/libpython2.7.so" CACHE STRING "")
    set( PYTHON_LIBRARY_RELEASE     "${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/libpython2.7.so" CACHE STRING "")
    set( PYTHON_LIBRARY             "${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/libpython2.7.so" CACHE STRING "")
    set( PYTHON_INCLUDE_DIR         "${RPI_ROOTFS}/usr/include/python2.7" CACHE STRING "")
    set( PYTHON2_NUMPY_INCLUDE_DIRS "${RPI_ROOTFS}/usr/lib/python2.7/dist-packages/numpy/core/include" CACHE STRING "")
    set( PYTHON2_PACKAGES_PATH      "${RPI_ROOTFS}/usr/local/lib/python2.7/site-packages" CACHE STRING "")
    ```
    
    > Several notes should be made on these settings.
    
    - `CACHE STRING/FILEPATH "" (FORCE)` ensures that, when `cmake` reads the file, the selected values are written to the cache and available during the build process of additional targets. It was added because some runs of `cmake` produced variating results as values where not properly updated.
    - `CMAKE_C_COMPILER`, `CMAKE_CXX_COMPILER`, `CMAKE_AR`, `CMAKE_RANLIB` are set to the proper linked binaires for the crosscompiler. The values of `CMAKE_AR` and `CMAKE_RANLIB` are set additionally as they are needed to link the arm-libraries properly. When not set several linking errors will be produced.
    - `cmake` and the `OpenCV`-cmake files use internally `pkgconfig` to find .pc files. These .pc files indicate which libaries are installed and where to find them. As the crosscompiler runs in a 64 bit x84 Ubuntu environment, it cannot use the 32bit arm `pkgconfig` of the RPi and hence uses the Ubuntu `pkgconfig` binairy. Since this binairy is configured to find .pc files on Ubuntu, it does not search `~/rpi/rootfs`. Therefore `PKG_CONFIG_DIR`, `PKG_CONFIG_LIBDIR` and `PKG_CONFIG_SYSROOT_DIR` are set to point to the proper locations. 
    - The `include` and `lib` paths of the detected .pc files are not cached properly, which will result in several errors during linking and building. Usally a linker (`ld`) searches paths specified in `ld.so.conf` in the root of the filesystem, but in my experience, the RPi-linker apperently does not. Therefore `RPI_INCLUDE_DIR` and `RPI_INCLUDE_LIB` are set to point to the appropiate headers and libraries. By inserting these values into the `CMAKE_CXX_FLAGS`/`CMAKE_C_FLAGS` and `CMAKE_EXE_LINKER_FLAGS`, `cmake` ensures that `gcc` and `ld` are still able to find the required files.
    - Commonly `OpenCV` is installed in `/usr/local`. This however gave several linking errors when compiling user-code such as the tests described in [Syncing, Compiling and Testing](#syncing-compiling-and-testing). These errors are solved by installing `OpenCV` directly in the usr directory, as done by setting `CMAKE_INSTALL_PREFIX`.
    - Since the RPi libraries are build for an arm-platform and the compiler only understands x84 binaries, `cmake` is unable to detect the proper Python parameters for python-bindings. The values specified at the bottom of the code-snippet enable `cmake` to find the proper files. It should be noted that this action only works when the same Python versions are installed on both the RPi and in the VM! Furthermore, the provided setup only creates Python-bindings for Python2.7. To use Python3.0, the proper `numpy` need to be installed and probably similar settings need to be set. 
    - Ideally, the `CMAKE_SYSROOT` command should be used to set to rootfs for a crosscompilation target. However, I did not succeed at setting the parameter properly and therefor use the `sysroot` located at:
        ```
        /home/pi/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/arm-linux-gnueabihf/sysroot
        ```
        
        The encountered error message was:
        ```
        /home/pi/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/../lib/gcc/arm-linux-gnueabihf/4.9.3/../../../../arm-linux-gnueabihf/bin/ld:
        cannot find crt1.o: No such file or directory
        ```
        
        While using these additional settings:
        ```
        set( CMAKE_SYSROOT     "${RPI_ROOTFS}" CACHE FILEPATH "")
        set( CMAKE_FIND_ROOT_PATH "${RPI_ROOTFS}" CACHE FILEPATH "")
        set( CMAKE_LIBRARY_ARCHITECTURE "arm-linux-gnueabihf" CACHE STRING "")
        set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
        #set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
        #set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
        #set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
        ```
1. The commands for building `OpenCV` then become: 
    ```
    XCS~$ mkdir -p ~/rpi/build/opencv
    XCS~$ cd ~/rpi/build/opencv
    XCS~$ cmake \
        -D RPI_ROOTFS=/home/pi/rpi/rootfs \
        -D BUILD_TESTS=NO \
        -D BUILD_PERF_TESTS=NO \
        -D BUILD_PYTHON_SUPPORT=ON \
        -D OPENCV_EXTRA_MODULES_PATH=/home/pi/rpi/src/opencv_contrib-3.2.0/modules \
        -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/src/opencv-3.2.0/platforms/linux/arm.toolchain.cmake \
        /home/pi/rpi/src/opencv-3.2.0
    ```
    
    Which produces a summary looking like: 
  
    ```
    -- General configuration for OpenCV 3.2.0 =====================================
    --   Version control:               unknown
    -- 
    --   Extra modules:
    --     Location (extra):            /home/pi/rpi/src/opencv_contrib-3.2.0/modules
    --     Version control (extra):     unknown
    -- 
    --   Platform:
    --     Timestamp:                   2017-03-16T15:34:20Z
    --     Host:                        Linux 4.4.0-64-generic x86_64
    --     Target:                      Linux 1 arm
    --     CMake:                       3.5.1
    --     CMake generator:             Unix Makefiles
    --     CMake build tool:            /usr/bin/make
    --     Configuration:               Release
    -- 
    --   C/C++:
    --     Built as dynamic libs?:      YES
    --     C++ Compiler:                /usr/bin/rpizero-g++  (ver 4.9.3)
    --     C++ flags (Release):         -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wno-narrowing -Wno-delete-non-virtual-dtor -Wno-comment -fdiagnostics-show-option -pthread -fomit-frame-pointer -mfp16-format=ieee -ffunction-sections -fvisibility=hidden -fvisibility-inlines-hidden -O3 -DNDEBUG  -DNDEBUG
    --     C++ flags (Debug):           -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wno-narrowing -Wno-delete-non-virtual-dtor -Wno-comment -fdiagnostics-show-option -pthread -fomit-frame-pointer -mfp16-format=ieee -ffunction-sections -fvisibility=hidden -fvisibility-inlines-hidden -g  -O0 -DDEBUG -D_DEBUG
    --     C Compiler:                  /usr/bin/rpizero-gcc
    --     C flags (Release):           -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wundef -Winit-self -Wpointer-arith -Wshadow -Wno-narrowing -Wno-comment -fdiagnostics-show-option -pthread -fomit-frame-pointer -mfp16-format=ieee -ffunction-sections -fvisibility=hidden -O3 -DNDEBUG  -DNDEBUG
    --     C flags (Debug):             -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wundef -Winit-self -Wpointer-arith -Wshadow -Wno-narrowing -Wno-comment -fdiagnostics-show-option -pthread -fomit-frame-pointer -mfp16-format=ieee -ffunction-sections -fvisibility=hidden -g  -O0 -DDEBUG -D_DEBUG
    --     Linker flags (Release):
    --     Linker flags (Debug):
    --     ccache:                      NO
    --     Precompiled headers:         NO
    --     Extra dependencies:          gtk-x11-2.0 gdk-x11-2.0 pangocairo-1.0 atk-1.0 cairo gdk_pixbuf-2.0 gio-2.0 pangoft2-1.0 pango-1.0 gobject-2.0 fontconfig freetype gthread-2.0 glib-2.0 dc1394 dl m pthread rt
    --     3rdparty dependencies:       zlib libjpeg libwebp libpng libtiff libjasper IlmImf libprotobuf tegra_hal
    -- 
    --   OpenCV modules:
    --     To be built:                 core flann imgproc ml photo reg surface_matching video dnn freetype fuzzy imgcodecs shape videoio highgui objdetect plot superres xobjdetect xphoto bgsegm bioinspired dpm face features2d line_descriptor saliency text calib3d ccalib datasets rgbd stereo tracking videostab xfeatures2d ximgproc aruco optflow phase_unwrapping stitching structured_light python2
    --     Disabled:                    world contrib_world
    --     Disabled by dependency:      -
    --     Unavailable:                 cudaarithm cudabgsegm cudacodec cudafeatures2d cudafilters cudaimgproc cudalegacy cudaobjdetect cudaoptflow cudastereo cudawarping cudev java python3 ts viz cnn_3dobj cvv hdf matlab sfm
    -- 
    --   GUI: 
    --     QT:                          NO
    --     GTK+ 2.x:                    YES (ver 2.24.25)
    --     GThread :                    YES (ver 2.42.1)
    --     GtkGlExt:                    NO
    --     OpenGL support:              NO
    --     VTK support:                 NO
    -- 
    --   Media I/O: 
    --     ZLib:                        zlib (ver 1.2.8)
    --     JPEG:                        libjpeg (ver 90)
    --     WEBP:                        build (ver 0.3.1)
    --     PNG:                         build (ver 1.6.24)
    --     TIFF:                        build (ver 42 - 4.0.2)
    --     JPEG 2000:                   build (ver 1.900.1)
    --     OpenEXR:                     build (ver 1.7.1)
    --     GDAL:                        NO
    --     GDCM:                        NO
    -- 
    --   Video I/O:
    --     DC1394 1.x:                  NO
    --     DC1394 2.x:                  YES (ver 2.2.3)
    --     FFMPEG:                      NO
    --       avcodec:                   YES (ver 56.1.0)
    --       avformat:                  YES (ver 56.1.0)
    --       avutil:                    YES (ver 54.3.0)
    --       swscale:                   YES (ver 3.0.0)
    --       avresample:                YES (ver 2.1.0)
    --     GStreamer:                   NO
    --     OpenNI:                      NO
    --     OpenNI PrimeSensor Modules:  NO
    --     OpenNI2:                     NO
    --     PvAPI:                       NO
    --     GigEVisionSDK:               NO
    --     Aravis SDK:                  NO
    --     UniCap:                      NO
    --     UniCap ucil:                 NO
    --     V4L/V4L2:                    NO/YES
    --     XIMEA:                       NO
    --     Xine:                        NO
    --     gPhoto2:                     NO
    -- 
    --   Parallel framework:            pthreads
    -- 
    --   Other third-party libraries:
    --     Use IPP:                     NO
    --     Use VA:                      NO
    --     Use Intel VA-API/OpenCL:     NO
    --     Use Lapack:                  NO
    --     Use Eigen:                   NO
    --     Use Cuda:                    NO
    --     Use OpenCL:                  YES
    --     Use OpenVX:                  NO
    --     Use custom HAL:              YES (carotene (ver 0.0.1))
    -- 
    --   OpenCL:                        <Dynamic loading of OpenCL library>
    --     Include path:                /home/pi/rpi/src/opencv-3.2.0/3rdparty/include/opencl/1.2
    --     Use AMDFFT:                  NO
    --     Use AMDBLAS:                 NO
    -- 
    --   Python 2:
    --     Interpreter:                 /usr/bin/python2.7 (ver 2.7.12)
    --     Libraries:                   /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so (ver 2.7.9)
    --     numpy:                       /home/pi/rpi/rootfs/usr/lib/python2.7/dist-packages/numpy/core/include (ver undefined - cannot be probed because of the cross-compilation)
    --     packages path:               /home/pi/rpi/rootfs/usr/local/lib/python2.7/site-packages
    -- 
    --   Python 3:
    --     Interpreter:                 NO
    -- 
    --   Python (for build):            /usr/bin/python2.7
    -- 
    --   Java:
    --     ant:                         NO
    --     JNI:                         NO
    --     Java wrappers:               NO
    --     Java tests:                  NO
    -- 
    --   Matlab:                        Matlab not found or implicitly disabled
    -- 
    --   Documentation:
    --     Doxygen:                     NO
    -- 
    --   Tests and samples:
    --     Tests:                       NO
    --     Performance tests:           NO
    --     C/C++ Examples:              NO
    -- 
    --   Install path:                  /home/pi/rpi/rootfs/usr
    -- 
    --   cvconfig.h is in:              /home/pi/rpi/build/opencv
    -- -----------------------------------------------------------------
    -- 
    -- Configuring done
    -- Generating done
    -- Build files have been written to: /home/pi/rpi/build/opencv
    ```  
    
    > Note the detection of libraries such as `gtk`, additional modules such as `freetype` and the proper settings for `Python`.
1. When all is fine, `OpenCV` can be build and installed.
    ```
    XCS~$ make -j 4
    XCS~$ make install
    ```
    
1. Due to crosscompilation, the installation of `OpenCV` produces and invalid .pc file. This needs to be corrected.
    - Move file to appropiate location
        ```
        XCS~$ mv /home/pi/rpi/rootfs/usr/lib/pkgconfig/opencv.pc /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/pkgconfig/opencv.pc
        ```
        
    - Update prefix-path in the .pc file. It should become `prefix=/usr`
        ```
        XCS~$ nano /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/pkgconfig/opencv.pc
        ```
        
## Synchronisation
Update `rootfs` on the rpi:

1. Use a direct call:
    ```
    XCS~$ sudo rsync -auHWv --no-perms --no-owner --no-group /home/pi/rpi/rootfs/ rpizero-local-root:/
    ```
    
1. Or use the link-correcting script:
    1. Clone repository (if not yet done)
        ```
        XCS~$ mkdir -p ~/rpi/build
        XCS~$ cd ~/rpi/build
        XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
        ```
    
    1. Allow script to be executed (if not yet done)
        ```
        XCS~$ chmod +x ~/rpi/build/rpicross_notes/sync-vm-rpi.sh
        ```

    1. Sync VM-`rootfs` with RPi`
        ```
        XCS~$ /home/pi/rpi/build/rpicross_notes/sync-vm-rpi.sh
        ```

## Python Bindings

1. To use the Python-bindings on the rpi, `PYTHONPATH` has to be set properly
    ```
    XCS~$ ssh rpizero-local
    RPI~$ nano ~/.bashrc
    ```
  
    Add to following lines:
    ```
    #Ensure Python is able to find packages
    export PYTHONPATH=/usr/local/lib/python2.7/site-packages:$PYTHONPATH
    ```
  
1. Reload Bash
    ```
    RPI~$ source ~/.bashrc
    ```
    
1. Test in Python
    ```
    RPI~$ python
    Python 2.7.9 (default, Sep 17 2016, 20:26:04) 
    [GCC 4.9.2] on linux2
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import cv2
    >>> 
    ```
    If `import cv2` does not produce an error, then the bindings are properly set. 
  
## Testing
Testing the compiled `OpenCV`-libraries

Prerequisites: 
- Toolchain installed
- Userland installed & synced
- OpenCV installed & synced
- An image on the rpi. (e.g. `testcam.jpg`).

Steps:
1. Download the code in [hello/ocv](hello/ocv).
    ```
    XCS~$ mkdir -p ~/rpi/build
    XCS~$ cd ~/rpi/build
    XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
    ```
    
1. Build the code with the [rpi-generic-toolchain](rpi-generic-toolchain.cmake) toolchain
    ```
    XCS~$ mkdir -p ~/rpi/build/hello/ocv
    XCS~$ cd ~/rpi/build/hello/ocv
    XCS~$ cmake \
        cmake -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/build/rpicross_notes/rpi-generic-toolchain.cmake \
        ~/rpi/build/rpicross_notes/hello/ocv
    XCS~$ make
    ```
    
1. Sync and run.
    ```
    XCS~$ scp hellocv rpizero-local:~/ 
    XCS~$ ssh -X rpizero-local
    RPI~$ ./hellocv testcam.jpg
    ```
    
    As a result, a window should be opened displaying the image. 
    > Depending on the size of the image, this may take a while.

> Code for this test is taken from http://docs.opencv.org/3.2.0/db/deb/tutorial_display_image.html
