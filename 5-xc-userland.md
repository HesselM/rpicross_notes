# Userland

The [userland](https://github.com/raspberrypi/userland) repository of the Pi Foundation contains several libraires to communicate with the GPU and use GPU related actions such as `mmal`, `GLES` and others.

Before you can proceed with the following steps, make sure you setup the [crosscompile environment](4-xc-setup.md) properly.

## Required Packages

No additional packages should be required for the RPi or the VM.

## Compilation

1. Download userland
    ```
    XCS~$ mkdir -p ~/rpi/rootfs/usr/src/
    XCS~$ cd ~/rpi/rootfs/usr/src/
    XCS~$ git clone https://github.com/raspberrypi/userland.git --depth 1
    ```
  
1. Clone repository (if not yet done)
    ```
    XCS~$ mkdir -p ~/rpi/build
    XCS~$ cd ~/rpi/build
    XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
    ```
    > The repository contains a [generic toolchain](rpi-generic-toolchain.cmake) which will be used to compile the userland libraries. See [toolchain:info](rpi-generic-toolchai.md) for more information.
    
1. Create build location for `userland` & build

    ```
    XCS~$ mkdir -p ~/rpi/rootfs/usr/src/userland/build/arm-linux/release
    XCS~$ cd ~/rpi/rootfs/usr/src/userland/build/arm-linux/release
    XCS~$ cmake \
      -D CMAKE_ASM_COMPILER=/usr/bin/rpizero-gcc \
      -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/build/rpicross_notes/rpi-generic-toolchain.cmake \
      -D CMAKE_BUILD_TYPE=Release \
      /home/pi/rpi/rootfs/usr/src/userland/
    ```
    This should produce an ouput similar to:
  
    ```
    -- The C compiler identification is GNU 4.9.3
    -- The CXX compiler identification is GNU 4.9.3
    -- Check for working C compiler: /usr/bin/rpizero-gcc
    -- Check for working C compiler: /usr/bin/rpizero-gcc -- works
    -- Detecting C compiler ABI info
    -- Detecting C compiler ABI info - done
    -- Detecting C compile features
    -- Detecting C compile features - done
    -- Check for working CXX compiler: /usr/bin/rpizero-g++
    -- Check for working CXX compiler: /usr/bin/rpizero-g++ -- works
    -- Detecting CXX compiler ABI info
    -- Detecting CXX compiler ABI info - done
    -- Detecting CXX compile features
    -- Detecting CXX compile features - done
    -- Looking for execinfo.h
    -- Looking for execinfo.h - found
    -- The ASM compiler identification is GNU
    -- Found assembler: /usr/bin/rpizero-gcc
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
    XCS~$ rm -rf /home/pi/rpi/rootfs/usr/src/userland/build
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

## Testing
Testing the compiled `userland`-libraries

Prerequisites: 
- Toolchain installed
- Userland installed & synced
- RPi Camera connected and activated

Steps:
1. Clone repository (if not yet done)
    ```
    XCS~$ mkdir -p ~/rpi/build
    XCS~$ cd ~/rpi/build
    XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
    ```
    
1. Build the code 
    ```
    XCS~$ mkdir -p ~/rpi/build/hello/raspicam
    XCS~$ cd ~/rpi/build/hello/raspicam
    XCS~$ cmake ~/rpi/build/rpicross_notes/hello/raspicam
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
