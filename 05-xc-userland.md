# Guide to Cross Compilation for a Raspberry Pi

1. [Start](readme.md)
1. [Setup XCS and RPi](01-setup.md)
1. [Setup RPi Network and SSH](02-network.md)
1. [Setup RPi Peripherals](03-peripherals.md)
1. [Setup Cross-compile environment](04-xc-setup.md)
1. **> [Cross-compile and Install Userland](05-xc-userland.md)**
1. [Cross-compile and Install OpenCV](06-xc-opencv.md)
1. [Cross-compile and Install ROS](07-xc-ros.md)
1. [Compile and Install OpenCV](08-native-opencv.md)
1. [Compile and Install ROS](09-native-ros.md)
1. [Remote ROS (RPi node and XCS master)](10-ros-remote.md)
1. [ROS package development (RPi/XCS)](11-ros-dev.md)
1. [Compile and Install WiringPi](12-wiringpi.md)

# 6. Cross-compile and Install Userland

The [userland](https://github.com/raspberrypi/userland) repository of the Pi Foundation contains several libraries to communicate with the RPi's GPU and use GPU related actions such as `mmal`, `GLES` and others. It also contains the camera functions such as `raspivid` and `raspistill`.

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
- Optional: RPi Camera (only used for testing)

## Preparation

1. Sync RPi with the XCS. This ensures all symbolic links will be corrected.

    ```
    XCS~$ $XC_RPI_BASE/rpicross_notes/scripts/sync-rpi-xcs.sh rpizero-local-root
    ```

1. Download userland

    ```
    XCS~$ mkdir -p $XC_RPI_ROOTFS/usr/src/
    XCS~$ cd $XC_RPI_ROOTFS/usr/src/
    XCS~$ git clone https://github.com/raspberrypi/userland.git --depth 1
    ```

    > The `userland` repository is downloaded in `rootfs` because the `make install` does not copy the headers of the libraries.

## Compilation

1. Create the build location for `userland` and run CMake.

    ```
    XCS~$ mkdir -p $XC_RPI_ROOTFS/usr/src/userland/build/arm-linux/release
    XCS~$ cd $XC_RPI_ROOTFS/usr/src/userland/build/arm-linux/release
    XCS~$ cmake \
      -D CMAKE_TOOLCHAIN_FILE=$XC_RPI_BASE/rpicross_notes/rpi-generic-toolchain.cmake \
      -D CMAKE_BUILD_TYPE=Release \
      -D ARM64=OFF \
      $XC_RPI_ROOTFS/usr/src/userland/
    ```

    This should produce an output similar to:

    ```
    -- The C compiler identification is GNU 4.9.3
    -- The CXX compiler identification is GNU 4.9.3
    -- Check for working C compiler: /usr/bin/arm-linux-gnueabihf-gcc
    -- Check for working C compiler: /usr/bin/arm-linux-gnueabihf-gcc -- works
    -- Detecting C compiler ABI info
    -- Detecting C compiler ABI info - done
    -- Detecting C compile features
    -- Detecting C compile features - done
    -- Check for working CXX compiler: /usr/bin/arm-linux-gnueabihf-g++
    -- Check for working CXX compiler: /usr/bin/arm-linux-gnueabihf-g++ -- works
    -- Detecting CXX compiler ABI info
    -- Detecting CXX compiler ABI info - done
    -- Detecting CXX compile features
    -- Detecting CXX compile features - done
    -- Looking for execinfo.h
    -- Looking for execinfo.h - found
    -- The ASM compiler identification is GNU
    -- Found assembler: /usr/bin/arm-linux-gnueabihf-gcc
    -- Found PkgConfig: /usr/bin/pkg-config (found version "0.29.1")
    -- Configuring done
    -- Generating done
    -- Build files have been written to: /home/pi/rpi/rootfs/usr/src/userland/build/arm-linux/release
    ```

1. Next, `make` userland.

    ```
    XCS~$ make -j 4
    ```

    > `-j 4` tells make to use 4 threads, which speeds up the process.

1. Install the created libraries:

    ```
    XCS~$ make install DESTDIR=$XC_RPI_ROOTFS
    ```

1. Remove build and git files from the src (these are not needed on the RPi)

    ```
    XCS~$ cd $XC_RPI_ROOTFS
    XCS~$ rm -rf $XC_RPI_ROOTFS/usr/src/userland/build
    XCS~$ rm -rf $XC_RPI_ROOTFS/usr/src/userland/.git*
    ```

## Installation

1. Sync the updated "rootfs" with the RPi:

    ```
    XCS~$ $XC_RPI_BASE/rpicross_notes/scripts/sync-xcs-rpi.sh rpizero-local-root
    ```

## Testing

Testing the compiled `userland`-libraries is done by building our own version of [`raspicam`](https://github.com/raspberrypi/userland.git/trunk/host_applications/linux/apps/raspicam) and creating a picture. Note that this test requires that the RPi has a camera connected and that you have `links2` installed.

1. Create the build-dir and build the application

    ```
    XCS~$ mkdir -p $XC_RPI_BUILD/hello/raspicam
    XCS~$ cd $XC_RPI_BUILD/hello/raspicam
    XCS~$ cmake \
        -D CMAKE_TOOLCHAIN_FILE=$XC_RPI_BASE/rpicross_notes/rpi-generic-toolchain.cmake \
        $XC_RPI_BASE/rpicross_notes/hello/raspicam
    XCS~$ make
    ```

1. Sync and run.

    ```
    XCS~$ scp hellocam rpizero-local:~/
    XCS~$ ssh -X rpizero-local
    RPI~$ ./hellocam -v -o testcam.jpg

        "hellocam" Camera App (commit Not found)

        Camera Name imx219
        Width 3280, Height 2464, filename testcam.jpg
        Using camera 0, sensor mode 0

        GPS output Disabled

        Quality 85, Raw no
        Thumbnail enabled Yes, width 64, height 48, quality 35
        Time delay 5000, Timelapse 0
        Link to latest frame enabled  no
        Full resolution preview No
        Capture method : Single capture

        Preview Yes, Full screen Yes
        Preview window 0,0,1024,768
        Opacity 255
        Sharpness 0, Contrast 0, Brightness 50
        Saturation 0, ISO 0, Video Stabilisation No, Exposure compensation 0
        Exposure Mode 'auto', AWB Mode 'auto', Image Effect 'none'
        Flicker Avoid Mode 'off'
        Metering Mode 'average', Colour Effect Enabled No with U = 128, V = 128
        Rotation 0, hflip No, vflip No
        ROI x 0.000000, y 0.000000, w 1.000000 h 1.000000
        Camera component done
        Encoder component done
        Starting component connection stage
        Connecting camera preview port to video render.
        Connecting camera stills port to encoder input port
        Opening output file testcam.jpg
        Enabling encoder output port
        Starting capture -1
        Finished capture -1
        Closing down
        Close down completed, all components disconnected, disabled and destroyed

    RPI~$ links2 -g testcam.jpg
    ```

    As a result, a window should be opened and show a snapshot of the camera.

    > Depending on the size of the image, this may take a while.

## Troubleshooting

### Error during build of `userland`:
```
../../../../lib/libvcos.so: undefined reference to `_dl_init_static_tls'
../../../../lib/libvcos.so: undefined reference to `_dl_pagesize'
../../../../lib/libvcos.so: undefined reference to `__pointer_chk_guard_local'
../../../../lib/libvcos.so: undefined reference to `__dlclose'
../../../../lib/libvcos.so: undefined reference to `__dlerror'
../../../../lib/libvcos.so: undefined reference to `_dl_stack_flags'
../../../../lib/libvcos.so: undefined reference to `__dlopen'
../../../../lib/libvcos.so: undefined reference to `__dlsym'
../../../../lib/libvcos.so: undefined reference to `_dl_wait_lookup_done'
../../../../lib/libvcos.so: undefined reference to `__pthread_create'
```

If such message appear during building (`make`) it might be because you need to fix the symlinks of the RPi-filesytem. Try building after syncing (and make sure you remove all build files):

```
XCS~$ $XC_RPI_BASE/rpicross_notes/scripts/sync-rpi-xcs.sh rpizero-local-root
...
XCS~$ cd $XC_RPI_ROOTFS/usr/src/userland/
XCS~$ rm -rf build/*
XCS~$ mkdir -p $XC_RPI_ROOTFS/usr/src/userland/build/arm-linux/release
XCS~$ cd $XC_RPI_ROOTFS/usr/src/userland/build/arm-linux/release
XCS~$ cmake \
  -D CMAKE_TOOLCHAIN_FILE=$XC_RPI_BASE/rpicross_notes/rpi-generic-toolchain.cmake \
  -D CMAKE_BUILD_TYPE=Release \
  -D ARM64=OFF \
  $XC_RPI_ROOTFS/usr/src/userland/
XCS~$ make
```

### Image is not loaded by `links2`:

```
Could not initialize any graphics driver. Tried the following drivers:
x:
Can't open display "(null)"
fb:
Could not get VT mode.
```

Check if there is a warning upon login on the RPi. If you see "Warning: untrusted X11 forwarding setup failed: xauth key data not generated" you might need to use the "-Y" instead of "-X" option when connecting via SSH.
