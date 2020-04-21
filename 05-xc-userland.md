# Crosscompiling : Userland

Before continuing, please make sure you followed the steps in:
- [Setup](01-setup.md)
- [Network/SSH](02-network.md)
- [Crosscompile environment](04-xc-setup.md)
- Optional (only for testing): [Peripherals](03-peripherals.md)

The [userland](https://github.com/raspberrypi/userland) repository of the Pi Foundation contains several libraires to communicate with the GPU and use GPU related actions such as `mmal`, `GLES` and others.

## Required Packages

No additional packages should be required for the RPi or the VM.

## Compilation

1. Download userland
    ```
    XCS~$ mkdir -p ~/rpi/rootfs/usr/src/
    XCS~$ cd ~/rpi/rootfs/usr/src/
    XCS~$ git clone https://github.com/raspberrypi/userland.git --depth 1
    ```
    > The `userland` repository is downloaded in `rootfs` because the `make install` does not copy the headers of the libraries. 
        
1. Create build location for `userland` and build with [rpi-generic-toolchain](rpi-generic-toolchain.cmake)
   
   > NOTE: make sure you sync the RPi with the VM before compiling userland, otherwise linking might fail due too symlinks which have not been corrected.
 
    ```
    XCS~$ mkdir -p ~/rpi/rootfs/usr/src/userland/build/arm-linux/release
    XCS~$ cd ~/rpi/rootfs/usr/src/userland/build/arm-linux/release
    XCS~$ cmake \
      -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
      -D CMAKE_BUILD_TYPE=Release \
      -D ARM64=OFF \
      /home/pi/rpi/rootfs/usr/src/userland/
    ```
    This should produce an ouput similar to:
  
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
    XCS~$ make install DESTDIR=/home/pi/rpi/rootfs
    ```
  
1. Remove build files from the src.
    ```
    XCS~$ cd ~/
    XCS~$ rm -rf /home/pi/rpi/rootfs/usr/src/userland/build
    ```
 
## Synchronisation
    
1. Send the created/updated headers and binaries from `rootfs` on the rpi:
    ```
    XCS~$ /home/pi/rpicross_notes/scripts/sync-vm-rpi.sh
    ```

## Testing
Testing the compiled `userland`-libraries

Prerequisites: 
- Toolchain [installed](04-xc-setup.md#required-packages)
- Repository [initialised](04-xc-setup.md#init-repository)
- Userland [installed](#compilation) & [synced](#synchronisation)
- RPi Camera [connected and activated](03-peripherals.md#camera)

Steps:

1. Build the code with the [rpi-generic-toolchain](rpi-generic-toolchain.cmake)
    ```
    XCS~$ mkdir -p ~/rpi/build/hello/raspicam
    XCS~$ cd ~/rpi/build/hello/raspicam
    XCS~$ cmake \
        -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
        ~/rpicross_notes/hello/raspicam
    XCS~$ make
    ```
  
1. Sync and run.
    ```
    XCS~$ scp hellocam rpizero-local:~/ 
    XCS~$ ssh -X rpizero-local
    RPI~$ ./hellocam -v -o testcam.jpg
    
        hellocam Camera App v1.3.11

        Width 3280, Height 2464, quality 85, filename testcam.jpg
        Time delay 5000, Raw no
        Thumbnail enabled Yes, width 64, height 48, quality 35
        Link to latest frame enabled  no
        Full resolution preview No
        Capture method : Single capture

        Preview Yes, Full screen Yes
        Preview window 0,0,1024,768
        Opacity 255
        Sharpness 0, Contrast 0, Brightness 50
        Saturation 0, ISO 0, Video Stabilisation No, Exposure compensation 0
        Exposure Mode 'auto', AWB Mode 'auto', Image Effect 'none'
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
  
> Code for this test is taken from https://github.com/raspberrypi/userland.git/trunk/host_applications/linux/apps/raspicam. To test the camera with the original code, follow these steps:

1. Download code from original repo
    ```
    XCS~$ sudo apt-get install subversion
    XCS~$ mkdir -p ~/code/hello
    XCS~$ cd ~/code/hello
    XCS~$ svn export https://github.com/raspberrypi/userland.git/trunk/host_applications/linux/apps/raspicam
    ```

1. Update `CMakeLists.txt` with [hello/raspicam/CMakeLists.txt](hello/raspicam/CMakeLists.txt).
    ```
    XCS~$ nano ~/code/hello/raspicam/CMakeLists.txt
    ```
    
1. Build the code 
    ```
    XCS~$ mkdir -p ~/rpi/build/hello/raspicam
    XCS~$ cd ~/rpi/build/hello/raspicam
    XCS~$ cmake ~/code/hello/raspicam/
    XCS~$ make
    ```
  
1. Sync and run.
    ```
    XCS~$ scp hellocam rpizero-local:~/ 
    XCS~$ ssh -X rpizero-local
    RPI~$ ./hellocam -v -o testcam.jpg
     ...
     ...
     ...
    RPI~$ links2 -g testcam.jpg
