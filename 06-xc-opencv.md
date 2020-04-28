# Guide to Cross Compilation for a Raspberry Pi

1. [Start](readme.md)
1. [Setup XCS and RPi](01-setup.md)
1. [Setup RPi Network and SSH](02-network.md)
1. [Setup RPi Peripherals](03-peripherals.md)
1. [Setup Cross-compile environment](04-xc-setup.md)
1. [Cross-compile and Install Userland](05-xc-userland.md)
1. **> [Cross-compile and Install OpenCV](06-xc-opencv.md)**
1. [Cross-compile and Install ROS](07-xc-ros.md)
1. [Compile and Install OpenCV](08-native-opencv.md)
1. [Compile and Install ROS](09-native-ros.md)
1. [Remote ROS (RPi node and XCS master)](10-ros-remote.md)
1. [ROS package development (RPi/XCS)](11-ros-dev.md)
1. [Compile and Install WiringPi](12-wiringpi.md)

# 7. Cross-compile and Install OpenCV

This section will cross-compile and install OpenCV, its additional modules, gtk support and python bindings.

## Table of Contents

1. [Prerequisites](#prerequisites)
1. [Preparation](#preparation)
1. [Compilation](#compilation)
1. [Installation](#installation)
1. [Testing](#testing)
1. [Troubleshooting](#troubleshooting)

## Prerequisites
- Setup of XCS and RPi
- Setup of RPi Network and SSH
- Setup of the Cross-compile environment
- Compilation and Installation of the Userland libaries.

## Preparation

1. To run OpenCV, additional packages on the RPi are required.

    ```
    XCS~$ ssh rpizero-local
    RPI~$ sudo apt-get install python2.7 python-dev python-numpy python3 python3-dev python3-numpy libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev
    ```

    > Python and numpy need to be installed so `OpenCV` can create the Python-bindings.

    > Other libraries are used to process images, generate GUI's (via X-server) and other imaging processes.

    > Note that this download might take a while as a lot of packages need to be downloaded and installed.

1. Sync RPi with the XCS. This ensures all symbolic links will be corrected.

    ```
    XCS~$ $XC_RPI_BASE/rpicross_notes/scripts/sync-rpi-xcs.sh rpizero-local-root
    ```

## Compilation

1. Download and unzip the `OpenCV` sources.

    ```
    XCS~$ cd $XC_RPI_SRC
    XCS~$ wget https://github.com/opencv/opencv/archive/4.3.0.zip
    XCS~$ unzip 4.3.0.zip
    XCS~$ rm 4.3.0.zip
    XCS~$ wget https://github.com/opencv/opencv_contrib/archive/4.3.0.zip
    XCS~$ unzip 4.3.0.zip
    XCS~$ rm 4.3.0.zip
    ```

1. After downloading, we need to edit the `OpenCV`-arm toolchain as it does not support the Raspberry Pi Zero `armv6 hf` core properly.

    ```
    XCS~$ nano $XC_RPI_SRC/opencv-4.3.0/platforms/linux/arm.toolchain.cmake
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

    > The OpenCV toolchain presumes that a `thumb` instruction-set is available which consists of 32 and 16 bits instructions. As a `thumb` instruction-set uses multiple widths of instructions, this architecture is able to combine instructions and hence speed up processing time. Only `armv7` or higher has this ability, hence it does not apply to the BCM2835 of the RPi.

1. OpenCV comes with it's own toolchain for cross-compilation, but we also need to use our own toolchain as it contains several settings regarding "rootfs". Luckily CMake makes it possible to merge these files. To compile OpenCV a special toolchain (rpi-generic-toolchain-opencv-4.3.0.cmake) is created and placed in this repo. Its contents are:

   ```
   include( $ENV{XC_RPI_BASE}/rpicross_notes/rpi-generic-toolchain.cmake )
   include( $ENV{XC_RPI_SRC}/opencv-4.3.0/cmake/OpenCVMinDepVersions.cmake )
   ```

   > If you use a different OpenCV version or directory structure, please make sure you edit this file accordingly.

1. The commands for building `OpenCV` then becomes:

    ```
    XCS~$ mkdir -p $XC_RPI_BUILD/opencv
    XCS~$ cd $XC_RPI_BUILD/opencv
    XCS~$ cmake \
        -D BUILD_TESTS=NO \
        -D BUILD_PERF_TESTS=NO \
        -D BUILD_PYTHON_SUPPORT=ON \
        -D BUILD_NEW_PYTHON_SUPPORT=ON \
        -D CMAKE_INSTALL_PREFIX=$XC_RPI_ROOTFS/usr \
        -D OPENCV_EXTRA_MODULES_PATH=$XC_RPI_SRC/opencv_contrib-4.3.0/modules \
        -D CMAKE_TOOLCHAIN_FILE=$XC_RPI_BASE/rpicross_notes/rpi-generic-toolchain-opencv-4.3.0.cmake \
        $XC_RPI_SRC/opencv-4.3.0
    ```

    Which produces a summary looking like:

    ```
    -- General configuration for OpenCV 4.3.0 =====================================
    --   Version control:               unknown
    --
    --   Extra modules:
    --     Location (extra):            /home/pi/rpi/src/opencv_contrib-4.3.0/modules
    --     Version control (extra):     unknown
    --
    --   Platform:
    --     Timestamp:                   2020-04-28T10:52:55Z
    --     Host:                        Linux 4.15.0-96-generic x86_64
    --     Target:                      Linux 1 arm
    --     CMake:                       3.10.2
    --     CMake generator:             Unix Makefiles
    --     CMake build tool:            /usr/bin/make
    --     Configuration:               Release
    --
    --   CPU/HW features:
    --     Baseline:
    --       requested:                 DETECT
    --       disabled:                  VFPV3 NEON
    --
    --   C/C++:
    --     Built as dynamic libs?:      YES
    --     C++ standard:                11
    --     C++ Compiler:                /usr/bin/arm-linux-gnueabihf-g++  (ver 4.9.3)
    --     C++ flags (Release):         -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include  -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wsign-promo -Wuninitialized -Winit-self -Wno-delete-non-virtual-dtor -Wno-comment -Wno-missing-field-initializers -fdiagnostics-show-option -pthread -fomit-frame-pointer -ffunction-sections -fdata-sections  -fvisibility=hidden -fvisibility-inlines-hidden -O3 -DNDEBUG  -DNDEBUG
    --     C++ flags (Debug):           -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include  -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wsign-promo -Wuninitialized -Winit-self -Wno-delete-non-virtual-dtor -Wno-comment -Wno-missing-field-initializers -fdiagnostics-show-option -pthread -fomit-frame-pointer -ffunction-sections -fdata-sections  -fvisibility=hidden -fvisibility-inlines-hidden -g  -O0 -DDEBUG -D_DEBUG
    --     C Compiler:                  /usr/bin/arm-linux-gnueabihf-gcc
    --     C flags (Release):           -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include  -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wundef -Winit-self -Wpointer-arith -Wuninitialized -Winit-self -Wno-comment -Wno-missing-field-initializers -fdiagnostics-show-option -pthread -fomit-frame-pointer -ffunction-sections -fdata-sections  -fvisibility=hidden -O3 -DNDEBUG  -DNDEBUG
    --     C flags (Debug):             -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include  -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs -B/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf -B/home/pi/rpi/rootfs/lib/arm-linux-gnueabihf  -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/local/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wundef -Winit-self -Wpointer-arith -Wuninitialized -Winit-self -Wno-comment -Wno-missing-field-initializers -fdiagnostics-show-option -pthread -fomit-frame-pointer -ffunction-sections -fdata-sections  -fvisibility=hidden -g  -O0 -DDEBUG -D_DEBUG
    --     Linker flags (Release):      -Wl,--gc-sections -Wl,--as-needed  
    --     Linker flags (Debug):        -Wl,--gc-sections -Wl,--as-needed  
    --     ccache:                      NO
    --     Precompiled headers:         NO
    --     Extra dependencies:          dl m pthread rt
    --     3rdparty dependencies:
    --
    --   OpenCV modules:
    --     To be built:                 aruco bgsegm bioinspired calib3d ccalib core datasets dnn dnn_objdetect dnn_superres dpm face features2d flann freetype fuzzy gapi hfs highgui img_hash imgcodecs imgproc intensity_transform line_descriptor ml objdetect optflow phase_unwrapping photo plot python2 python3 quality rapid reg rgbd saliency shape stereo stitching structured_light superres surface_matching text tracking video videoio videostab xfeatures2d ximgproc xobjdetect xphoto
    --     Disabled:                    world
    --     Disabled by dependency:      -
    --     Unavailable:                 alphamat cnn_3dobj cudaarithm cudabgsegm cudacodec cudafeatures2d cudafilters cudaimgproc cudalegacy cudaobjdetect cudaoptflow cudastereo cudawarping cudev cvv hdf java js matlab ovis sfm ts viz
    --     Applications:                apps
    --     Documentation:               NO
    --     Non-free algorithms:         NO
    --
    --   GUI:
    --     GTK+:                        YES (ver 2.24.32)
    --       GThread :                  YES (ver 2.58.3)
    --       GtkGlExt:                  NO
    --
    --   Media I/O:
    --     ZLib:                        /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libz.so (ver 1.2.11)
    --     JPEG:                        /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libjpeg.so (ver 62)
    --     WEBP:                        build (ver encoder: 0x020f)
    --     PNG:                         /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpng.so (ver 1.6.36)
    --     TIFF:                        /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libtiff.so (ver 42 / 4.1.0)
    --     JPEG 2000:                   /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libjasper.so (ver 1.900.1)
    --     HDR:                         YES
    --     SUNRASTER:                   YES
    --     PXM:                         YES
    --     PFM:                         YES
    --
    --   Video I/O:
    --     DC1394:                      YES (2.2.5)
    --     FFMPEG:                      NO
    --       avcodec:                   YES (58.35.100)
    --       avformat:                  YES (58.20.100)
    --       avutil:                    YES (56.22.100)
    --       swscale:                   YES (5.3.100)
    --       avresample:                NO
    --     GStreamer:                   NO
    --     v4l/v4l2:                    YES (linux/videodev2.h)
    --
    --   Parallel framework:            pthreads
    --
    --   Trace:                         YES (with Intel ITT)
    --
    --   Other third-party libraries:
    --     Lapack:                      NO
    --     Custom HAL:                  NO
    --     Protobuf:                    build (3.5.1)
    --
    --   OpenCL:                        YES (no extra features)
    --     Include path:                /home/pi/rpi/src/opencv-4.3.0/3rdparty/include/opencl/1.2
    --     Link libraries:              Dynamic load
    --
    --   Python 2:
    --     Interpreter:                 /usr/bin/python2.7 (ver 2.7.17)
    --     Libraries:                   /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so (ver 2.7.16)
    --     numpy:                       /home/pi/rpi/rootfs/usr/lib/python2.7/dist-packages/numpy/core/include (ver undefined - cannot be probed because of the cross-compilation)
    --     install path:                /home/pi/rpi/rootfs/usr/local/lib/python2.7/site-packages/cv2/python-2.7
    --
    --   Python 3:
    --     Interpreter:                 /usr/bin/python3 (ver 3.6.9)
    --     Libraries:                   /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython3.7m.so (ver 3.7.3)
    --     numpy:                       /home/pi/rpi/rootfs/usr/lib/python3/dist-packages/numpy/core/include (ver undefined - cannot be probed because of the cross-compilation)
    --     install path:                /home/pi/rpi/rootfs/usr/local/lib/python3.7/site-packages/cv2/python-3.6
    --
    --   Python (for build):            /usr/bin/python2.7
    --
    --   Install to:                    /home/pi/rpi/rootfs/usr
    -- -----------------------------------------------------------------
    --
    -- Configuring done
    -- Generating done
    -- Build files have been written to: /home/pi/rpi/build/opencv
    ```  

    > Note the detection of libraries such as `gtk`, additional modules such as `freetype` and the proper settings for `Python`.

1. When all is fine, `OpenCV` can be build and installed (which might take a while).

    ```
    XCS~$ make -j 4
    XCS~$ make install
    ```

    > Note that the installation directory is not specified with the installation-call `make install` as the installation directory is already defined during the CMake process: the last line of the CMake overview should state: `Install to: /home/pi/rpi/rootfs/usr`

## Installation

1. Sync the updated "rootfs" with the RPi:

    ```
    XCS~$ $XC_RPI_BASE/rpicross_notes/scripts/sync-xcs-rpi.sh rpizero-local-root
    ```

1. During the building process "rootfs" has been linked in the python-config files of OpenCV for the RPi. We need to fix this on the RPi:

    ```
    XCS~$ ssh rpizero-local
    RPI~$ sudo nano /usr/local/lib/python2.7/site-packages/cv2/config-2.7.py
    RPI~$ sudo nano /usr/local/lib/python2.7/site-packages/cv2/config.py
    RPI~$ sudo nano /usr/local/lib/python3.7/site-packages/cv2/config-3.6.py
    RPI~$ sudo nano /usr/local/lib/python3.7/site-packages/cv2/config.py   
    ```

    > Depending on the python versions on the RPi and on the XCS, multiple configs might require adjustments. Also note that the config-names depend on the python versions and hence might differ from the above overview.

1. For each config, remove the "rootfs" reference from the path. The result should look like:

    - config-X.py:

    ```
    PYTHON_EXTENSIONS_PATHS = [
        os.path.join('/usr/local/lib/python3.7/site-packages/cv2', 'python-3.6')
    ] + PYTHON_EXTENSIONS_PATHS
    ```

    - config.py:

    ```
    BINARIES_PATHS = [
        os.path.join('/usr', 'lib')
    ] + BINARIES_PATHS
    ```

1. You can now test your python-bindings:

    - python2:

    ```
    RPI~$ PYTHONPATH=/usr/local/lib/python2.7/site-packages python -c 'import cv2; print(cv2.__version__)'
    ```

    - python3:

    ```
    RPI~$ PYTHONPATH=/usr/local/lib/python3.7/site-packages python3 -c 'import cv2; print(cv2.__version__)'
    ```

    > Both should print out `4.3.0`. If you encounter any issues, see [Troubleshooting](#troubleshooting).

1. A more permanent way to set `PYTHONPATH` is to use `.bashrc`

    ```
    RPI~$ nano ~/.bashrc
    ```

    Add to following lines:

    ```
    #Ensure Python is able to find packages
    export PYTHONPATH=/usr/local/lib/python2.7/site-packages:$PYTHONPATH
    ```

    > Note that you both python3 and python2 use the same `PYTHONPATH`, hence care should be taken when setting this in `.bashrc`: the different versions are not interchangeable!

1. Reload Bash after you set `PYTHONPATH`

    ```
    RPI~$ source ~/.bashrc
    ```

1. Testing the bindings can now be done with:

    - python2:

    ```
    RPI~$ python -c 'import cv2; print(cv2.__version__)'
    ```

    - python3:

    ```
    RPI~$ python3 -c 'import cv2; print(cv2.__version__)'
    ```


## Testing

To test if OpenCV is compiled and installed properly we're going to [display an image on the RPi](http://docs.opencv.org/4.3.0/db/deb/tutorial_display_image.html). For this we need an image on the RPi. If you have installed the Pi Camera, you can use a previously taken test-image.  

1. Create the build-dir and build the application

    ```
    XCS~$ mkdir -p $XC_RPI_BUILD/hello/ocv
    XCS~$ cd $XC_RPI_BUILD/hello/ocv
    XCS~$ cmake \
        -D CMAKE_TOOLCHAIN_FILE=$XC_RPI_BASE/rpicross_notes/rpi-generic-toolchain.cmake \
        $XC_RPI_BASE/rpicross_notes/hello/ocv
    XCS~$ make
    ```

1. Sync and run.

    ```
    XCS~$ scp hellocv rpizero-local:~/
    XCS~$ ssh -X rpizero-local
    RPI~$ ./hellocv testcam.jpg
    ```

    As a result, a window should be open displaying the image.

    > Depending on the size of the image, this may take a while.


## Troubleshooting

### Python Bindings show "Recursion Error"

```
    raise ImportError('ERROR: recursion is detected during loading of "cv2" binary extensions. Check OpenCV installation.')
ImportError: ERROR: recursion is detected during loading of "cv2" binary extensions. Check OpenCV installation.
```

Check the config (`config-XX.py`) files on the RPi in:
- `/usr/local/lib/python2.7/site-packages/cv2/` or
- `/usr/local/lib/python3.7/site-packages/cv2/`

Make sure that references to `rootfs` are cleared, as specified above.

### Python Bindings are missing configuration files

```
    raise ImportError('OpenCV loader: missing configuration file: {}. Check OpenCV installation.'.format(fnames))
ImportError: OpenCV loader: missing configuration file: ['config-3.7.py', 'config-3.py']. Check OpenCV installation.
```

Check if you have set the proper `PYTHONPATH` for the proper python-version:
- python2: `PYTHONPATH=/usr/local/lib/python2.7/site-packages:$PYTHONPATH`
- python3: `PYTHONPATH=/usr/local/lib/python3.7/site-packages:$PYTHONPATH`

If your HOST had a different python version (e.g. python3.6) then the RPi (e.g. python3.7) you might need to fix the config setting:

```
RPI~$ sudo cp /usr/local/lib/python3.7/site-packages/cv2/config-3.6.py /usr/local/lib/python3.7/site-packages/cv2/config-3.7.py
```

### Gtk-WARNING: cannot open display

```
(process:7909): Gtk-WARNING **: 12:30:05.379: Locale not supported by C library.
	Using the fallback 'C' locale.

(Display window:7909): Gtk-WARNING **: 12:30:05.407: cannot open display:
```

Ensure you are your connected to the RPi with a shell supporting the "-X server". If you do, check if there is a warning upon login on the RPi. If you see "Warning: untrusted X11 forwarding setup failed: xauth key data not generated" you might need to use the "-Y" instead of "-X" option when connecting via SSH.
