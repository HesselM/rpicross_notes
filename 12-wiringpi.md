# Wiring Pi
Library to control GPIO / PWM on the Raspberry Pi. Original website: http://wiringpi.com/

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
    XCS~$ ~/rpicross-notes/scripts/sync-rpi-vm.sh
    ```

## Testing
Testing the compiled and installed `wiringPi` libraries with a PWM signal.

Prerequisites: 
- Toolchain [installed](4-xc-setup.md#required-packages)
- Repository [initialised](4-xc-setup.md#init-repository)
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

When an application uses both WiringPi and Xserverrunning the application with `sudo` might result in the error:
```
...
    X11 connection rejected because of wrong authentication.
...
```
Meaning that the created connection to Xserver does not allow `root` to setup a window. Presumably, the original connection to the RPi is created by executing:
```
XCS~$ ssh -X pi@rpizero-local`
```

This option can be used by setting the `XAUTHORITY` of `root` to the one of the `pi`-user.

1. The RPi is created by executing:
    ```
    RPi~$ su - root
    RPi~root$ nano ~/.bashrc
    ```
1. Add the following line to the file:
    ```
    export XAUTHORITY=/home/user/.Xauthority
    ```
1. logout
    ```
    RPi~root$ exit
    ```
1. Run flashcam properly
    ```
    RPi~$ su
    RPi~root$ ./flashcam
    RPi~root$ exit
    ```
