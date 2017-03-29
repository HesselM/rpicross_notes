# OpenCV

In addition to installing `OpenCV` on the RPi, we might need it too in the VM for some projects. 
This guide describes the steps for compiling and installing `OpenCV` in the VM.
The described steps are similair to [6-xc-opencv.md](6-xc-opencv.md) and are take from the official [install page](http://docs.opencv.org/2.4/doc/tutorials/introduction/linux_install/linux_install.html).

## Required Packages

Some packages might already be installed, but in general these are needed:

```
XCS~$ sudo apt-get install build-essential
XCS~$ sudo apt-get install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
XCS~$ sudo apt-get install python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev
```

## Compilation

1. Download and unzip the `OpenCV` sources.
    ```
    XCS~$ cd ~/src
    XCS~$ wget https://github.com/opencv/opencv/archive/3.2.0.zip
    XCS~$ unzip 3.2.0.zip 
    XCS~$ rm 3.2.0.zip
    XCS~$ wget https://github.com/opencv/opencv_contrib/archive/3.2.0.zip
    XCS~$ unzip 3.2.0.zip 
    XCS~$ rm 3.2.0.zip
    ```

    > When using the downloads from [6-xc-opencv.md](6-xc-opencv.md), make sure you revert `OpenCVMinDepVersions.cmake` into its original state.

1. Create build-directory
    ```
    XCS~$ mkdir -p ~/build/opencv
    XCS~$ cd ~/build/opencv
    ```

1. Compile
    ```
    XCS~$ cmake \
        -D BUILD_TESTS=NO \
        -D BUILD_PERF_TESTS=NO \
        -D BUILD_PYTHON_SUPPORT=ON \
        -D OPENCV_EXTRA_MODULES_PATH=/home/pi/src/opencv_contrib-3.2.0/modules \
        /home/pi/src/opencv-3.2.0 
        
        ...

        -- General configuration for OpenCV 3.2.0 =====================================
        --   Version control:               unknown
        -- 
        --   Extra modules:
        --     Location (extra):            /home/pi/src/opencv_contrib-3.2.0/modules
        --     Version control (extra):     unknown
        -- 
        --   Platform:
        --     Timestamp:                   2017-03-23T08:26:57Z
        --     Host:                        Linux 4.4.0-64-generic x86_64
        --     CMake:                       3.5.1
        --     CMake generator:             Unix Makefiles
        --     CMake build tool:            /usr/bin/make
        --     Configuration:               Release
        -- 
        --   C/C++:
        --     Built as dynamic libs?:      YES
        --     C++ Compiler:                /usr/bin/c++  (ver 5.4.0)
        --     C++ flags (Release):         -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wno-narrowing -Wno-delete-non-virtual-dtor -Wno-comment -fdiagnostics-show-option -Wno-long-long -pthread -fomit-frame-pointer -msse -msse2 -mno-avx -msse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -ffunction-sections -fvisibility=hidden -fvisibility-inlines-hidden -O3 -DNDEBUG  -DNDEBUG
        --     C++ flags (Debug):           -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wno-narrowing -Wno-delete-non-virtual-dtor -Wno-comment -fdiagnostics-show-option -Wno-long-long -pthread -fomit-frame-pointer -msse -msse2 -mno-avx -msse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -ffunction-sections -fvisibility=hidden -fvisibility-inlines-hidden -g  -O0 -DDEBUG -D_DEBUG
        --     C Compiler:                  /usr/bin/cc
        --     C flags (Release):           -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wundef -Winit-self -Wpointer-arith -Wshadow -Wno-narrowing -Wno-comment -fdiagnostics-show-option -Wno-long-long -pthread -fomit-frame-pointer -msse -msse2 -mno-avx -msse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -ffunction-sections -fvisibility=hidden -O3 -DNDEBUG  -DNDEBUG
        --     C flags (Debug):             -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wundef -Winit-self -Wpointer-arith -Wshadow -Wno-narrowing -Wno-comment -fdiagnostics-show-option -Wno-long-long -pthread -fomit-frame-pointer -msse -msse2 -mno-avx -msse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -ffunction-sections -fvisibility=hidden -g  -O0 -DDEBUG -D_DEBUG
        --     Linker flags (Release):
        --     Linker flags (Debug):
        --     ccache:                      NO
        --     Precompiled headers:         YES
        --     Extra dependencies:          /usr/lib/x86_64-linux-gnu/libpng.so /usr/lib/x86_64-linux-gnu/libz.so /usr/lib/x86_64-linux-gnu/libtiff.so /usr/lib/x86_64-linux-gnu/libjasper.so /usr/lib/x86_64-linux-gnu/libjpeg.so gtk-x11-2.0 gdk-x11-2.0 pangocairo-1.0 atk-1.0 cairo gdk_pixbuf-2.0 gio-2.0 pangoft2-1.0 pango-1.0 gobject-2.0 glib-2.0 fontconfig freetype gthread-2.0 dc1394 avcodec-ffmpeg avformat-ffmpeg avutil-ffmpeg swscale-ffmpeg dl m pthread rt
        --     3rdparty dependencies:       libwebp IlmImf libprotobuf
        -- 
        --   OpenCV modules:
        --     To be built:                 core flann imgproc ml photo reg surface_matching video dnn freetype fuzzy imgcodecs shape videoio highgui objdetect plot superres xobjdetect xphoto bgsegm bioinspired dpm face features2d line_descriptor saliency text calib3d ccalib datasets rgbd stereo tracking videostab xfeatures2d ximgproc aruco optflow phase_unwrapping stitching structured_light python2
        --     Disabled:                    world contrib_world
        --     Disabled by dependency:      -
        --     Unavailable:                 cudaarithm cudabgsegm cudacodec cudafeatures2d cudafilters cudaimgproc cudalegacy cudaobjdetect cudaoptflow cudastereo cudawarping cudev java python3 ts viz cnn_3dobj cvv hdf matlab sfm
        -- 
        --   GUI: 
        --     QT:                          NO
        --     GTK+ 2.x:                    YES (ver 2.24.30)
        --     GThread :                    YES (ver 2.48.2)
        --     GtkGlExt:                    NO
        --     OpenGL support:              NO
        --     VTK support:                 NO
        -- 
        --   Media I/O: 
        --     ZLib:                        /usr/lib/x86_64-linux-gnu/libz.so (ver 1.2.8)
        --     JPEG:                        /usr/lib/x86_64-linux-gnu/libjpeg.so (ver )
        --     WEBP:                        build (ver 0.3.1)
        --     PNG:                         /usr/lib/x86_64-linux-gnu/libpng.so (ver 1.2.54)
        --     TIFF:                        /usr/lib/x86_64-linux-gnu/libtiff.so (ver 42 - 4.0.6)
        --     JPEG 2000:                   /usr/lib/x86_64-linux-gnu/libjasper.so (ver 1.900.1)
        --     OpenEXR:                     build (ver 1.7.1)
        --     GDAL:                        NO
        --     GDCM:                        NO
        -- 
        --   Video I/O:
        --     DC1394 1.x:                  NO
        --     DC1394 2.x:                  YES (ver 2.2.4)
        --     FFMPEG:                      YES
        --       avcodec:                   YES (ver 56.60.100)
        --       avformat:                  YES (ver 56.40.101)
        --       avutil:                    YES (ver 54.31.100)
        --       swscale:                   YES (ver 3.1.101)
        --       avresample:                NO
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
        --     Use IPP:                     9.0.1 [9.0.1]
        --          at:                     /home/pi/build/opencv/3rdparty/ippicv/ippicv_lnx
        --     Use IPP Async:               NO
        --     Use VA:                      NO
        --     Use Intel VA-API/OpenCL:     NO
        --     Use Lapack:                  NO
        --     Use Eigen:                   YES (ver 3.2.92)
        --     Use Cuda:                    NO
        --     Use OpenCL:                  YES
        --     Use OpenVX:                  NO
        --     Use custom HAL:              NO
        -- 
        --   OpenCL:                        <Dynamic loading of OpenCL library>
        --     Include path:                /home/pi/src/opencv-3.2.0/3rdparty/include/opencl/1.2
        --     Use AMDFFT:                  NO
        --     Use AMDBLAS:                 NO
        -- 
        --   Python 2:
        --     Interpreter:                 /usr/bin/python2.7 (ver 2.7.12)
        --     Libraries:                   /usr/lib/x86_64-linux-gnu/libpython2.7.so (ver 2.7.12)
        --     numpy:                       /usr/lib/python2.7/dist-packages/numpy/core/include (ver 1.11.0)
        --     packages path:               lib/python2.7/dist-packages
        -- 
        --   Python 3:
        --     Interpreter:                 /usr/bin/python3 (ver 3.5.2)
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
        --   Install path:                  /usr/local
        -- 
        --   cvconfig.h is in:              /home/pi/build/opencv
        -- -----------------------------------------------------------------
        -- 
        -- Configuring done
        -- Generating done
        -- Build files have been written to: /home/pi/build/opencv
    ```

1. Build and install
    ```
    make -j 4
    sudo make install
    ```

## Testing
Testing the compiled `OpenCV`-libraries

Prerequisites: 
- OpenCV [installed in VM](#compilation)

Steps:
1. Build the code *without* the [rpi-generic-toolchain](rpi-generic-toolchain.cmake) toolchain
    ```
    XCS~$ mkdir -p ~/rpi/build/hello/ocv
    XCS~$ cd ~/rpi/build/hello/ocv
    XCS~$ cmake rpicross_notes/hello/ocv
    XCS~$ make
    ```
    
1. grab image and run.
    ```
    XCS~$ ./hellocv ~/rpi/build/rpicross_notes/hello/ocv/testimg.jpg
    ```
    
    As a result, a window should be opened displaying the image. 
    > Depending on the size of the image, this may take a while.
    > Make sure you are connected to the VM with X-server (`ssh -X`) enabled.

> Code for this test is taken from http://docs.opencv.org/3.2.0/db/deb/tutorial_display_image.html
