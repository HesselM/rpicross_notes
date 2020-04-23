# Guide to Cross Compilation for a Raspberry Pi

1. [Start](readme.md)
1. [Setup XCS and RPi](01-setup.md)
1. [Setup RPi Network and SSH](02-network.md)
1. [Setup RPi Peripherals](03-peripherals.md)
1. [Setup Cross-compile environment](04-xc-setup.md)
1. [Cross-compile and Install Userland](05-xc-userland.md)
1. [Cross-compile and Install OpenCV](06-xc-opencv.md)
1. [Cross-compile and Install ROS](07-xc-ros.md)
1. [Compile and Install OpenCV](08-native-opencv.md)
1. [Compile and Install ROS](09-native-ros.md)
1. [Remote ROS (RPi node and XCS master)](10-ros-remote.md)
1. [ROS package development (RPi/XCS)](11-ros-dev.md)
1. **> [Compile and Install WiringPi](12-wiringpi.md)**

# 13. Compile and Install WiringPi

TO BE UPDATED. GUIDE MIGHT STILL WORK.

Library to control GPIO / PWM on the Raspberry Pi using [wiringPi](http://wiringpi.com/)

Steps on this page are derived from http://wiringpi.com/download-and-install/

## Required Packages

No additional packages are required

## Compilation & Synchronisation

Note: As compilation-process of the library polls several hardware features, the library itself cannot be crosscompiled and needs to be build on the RPi itself.

1. Download code in `src` dir of `rootfs`.
    ```
    XCS~$ cd ~/rpi/rootfs/usr/src
    XCS~$ git clone git://git.drogon.net/wiringPi
    ```

1. Copy the PkgConfig .pc file for wiringPi from this repository to `rootfs`. The upcoming build process does not create it, while it is needed for cmake to build and cross-compile code depending on wiringPi.
    ```
    XCS~$ cp ~/rpicross_notes/hello/wiringpi/wiringpi.pc ~/rpi/rootfs/usr/share/pkgconfig/
    ```

1. Sync `rootfs` to RPi
    ```
    XCS~$ ~/rpicross-notes/scripts/sync—vm-rpi.sh
    ```

1. Build on RPi
    ```
    XCS~$ ssh rpizer-local
    RPI~$ cd /usr/src/wiringPi
    RPI~$ sudo ./build
    ```

1. Sync updates to VM
    ```
    XCS~$ ~/rpicross-notes/scripts/sync-rpi-xcs.sh
    ```

## Testing
Testing the compiled and installed wiringPi libraries with a PWM signal.

Prerequisites:
- Toolchain [installed](04-xc-setup.md#required-packages)
- Repository [initialised](04-xc-setup.md#init-repository)
- WiringPi [installed and synchronised](#compilation--synchronisation)
- wiringpi.pc [installed](#compilation--synchronisation)

Steps:

1. To see a fading LED, you should connect a LED to [GPIO18](https://pinout.xyz/). How to connect the LED is described [here](https://thepihut.com/blogs/raspberry-pi-tutorials/27968772-turning-on-an-led-with-your-raspberry-pis-gpio-pins).

1. Build the code with the [rpi-generic-toolchain](rpi-generic-toolchain.cmake)
    ```
    XCS~$ mkdir -p ~/rpi/build/hello/wiringpi
    XCS~$ cd ~/rpi/build/hello/wiringpi
    XCS~$ cmake \
     -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
     ~/rpicross_notes/hello/wiringpi
    XCS~$ make
    ```

1. Sync and run.
    ```
    XCS~$ scp wpi rpizero-local:~/
    XCS~$ ssh -X rpizero-local
    RPI~$ sudo ./wpi
     Raspberry Pi wiringPi PWM test program
     Iteration:  5/ 5 - Brightness:    0/1024
     Done
   ```

## Note application utilising X server.

When an application uses both `wiringPi` and requires Xserver to run the application, errors might be encountered when using `sudo`:
```
...
    X11 connection rejected because of wrong authentication.
...
```
This error means that the created connection to Xserver does not allow `root` to setup a window. Presumably, the original connection to the RPi was created by the user `pi`:
```
XCS~$ ssh -X pi@rpizero-local
```
When connecting via SSH as `root` does not pose a (security) problem, this might solve the problem:
```
XCS~$ ssh -X root@rpizero-local
```

### Proper solution

Luckily, a simple and more secure solution exists:
```
XCS~$ ssh -X pi@rpizero-local
RPi~$ su -pc ./flashcam
```
This will execute the application with root-privileges, while maintaining the current environment variables (and hence the `XAUTHORITY` settings of the `pi` user).

### Deprecated solution..
~~A more secure way is to allow `root` to use the same `XAUTHORITY` settings as the `pi`-user:~~

1. ~~Setup SSH connection and start editing `bashrc` of `root` :~~
    ```
    XCS~$ ssh -X pi@rpizero-local
    RPi~$ su - root
    RPi~root$ nano ~/.bashrc
    ```
1. ~~Add the following line to the file:~~
    ```
    export XAUTHORITY=/home/user/.Xauthority
    ```
1. ~~Logout~~
    ```
    RPi~root$ exit
    ```
1. ~~Run application~~
    ```
    RPi~$ su
    RPi~root$ ./flashcam
    RPi~root$ exit
    ```
