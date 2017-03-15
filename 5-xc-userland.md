# Userland

The [userland](https://github.com/raspberrypi/userland) repository of the Pi Foundation contains several libraires to communicate with the GPU and use GPU related actions such as `mmal`, `GLES` and others. 

Installing the userland libraries does not install all headers. Therefore the source will be downloaded into `rootfs`.

## Compilation

1. Download userland
  ```
  XCS~$ mkdir -p ~/rpi/rootfs/usr/src/
  XCS~$ cd ~/rpi/rootfs/usr/src/
  XCS~$ git clone https://github.com/raspberrypi/userland.git --depth 1
  ```
1. Download our generic toolchain 
  ```
  XCS~$ mkdir -p ~/rpi/build
  XCS~$ cd ~/rpi/build
  XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
  ```
1. Create build location for `userland` & build
  ```
  XCS~$ mkdir -p ~/rpi/build/userland
  XCS~$ cd ~/rpi/build/userland
  XCS~$ cmake \
    -D CMAKE_C_COMPILER=/usr/bin/rpizero-gcc \
    -D CMAKE_CXX_COMPILER=/usr/bin/rpizero-g++ \
    -D CMAKE_ASM_COMPILER=/usr/bin/rpizero-gcc \
    -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/build/rpicross_notes/rpi-generic-toolchain.cmake \
    -D CMAKE_BUILD_TYPE=Release \
    /home/pi/rpi/rootfs/usr/src/userland/
  ```
  This should produce an ouput which looks like:
  
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
  -- Build files have been written to: /home/pi/rpi/build/userland
  ```
1. Next, `make` userland.

  ```
  XCS~$ make -j 4
  ```
  > `-j 4` tells make to use 4 threads, which speeds up the process. 
  
1. Finally, we can install the created libraries:

  ```
  XCS~$ make install DESTDIR=/home/pi/rpi/rootfs
  ```
  
## Synchronisation
Update `rootfs` on the rpi:

```
XCS~$ sudo rsync -auHWv --no-perms --no-owner --no-group /home/pi/rpi/rootfs/ rpizero-local-root:/
```

## Testing
Testing the compiled `userland`-libraries
Prerequisites: 
- Toolchain installed
- Userland installed & synced

1. There are two options to test the camera: i) you can download all code from the repo, or ii), you can download the code from the original repo.
  1. Using this repo.
  
    Download the code in [hello/raspicam](hello/raspicam).
    
    ```
    XCS~$ mkdir -p ~/rpi/build
    XCS~$ cd ~/rpi/build
    XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
    ```
    
  1. Using the original repo.

    ```
    XCS~$ sudo apt-get install subversion
    XCS~$ mkdir -p ~/code/hello
    XCS~$ cd ~/code/hello
    XCS~$ svn export https://github.com/raspberrypi/userland.git/trunk/host_applications/linux/apps/raspicam
    ```

    Update `CMakeLists.txt` with [hello/raspicam/CMakeLists.txt](hello/raspicam/CMakeLists.txt).
    ```
    XCS~$ nano ~/code/hello/raspicam/CMakeLists.txt
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
