# Guide to Cross Compilation for a Raspberry Pi

1. [Start](readme.md)
1. [Setup XCS and RPi](01-setup.md)
1. [Setup RPi Network and SSH](02-network.md)
1. **> [Setup RPi Peripherals](03-peripherals.md)**
1. [Setup Cross-compile environment](04-xc-setup.md)
1. [Cross-compile and Install Userland](05-xc-userland.md)
1. [Cross-compile and Install OpenCV](06-xc-opencv.md)
1. [Cross-compile and Install ROS](07-xc-ros.md)
1. [Compile and Install OpenCV](08-native-opencv.md)
1. [Compile and Install ROS](09-native-ros.md)
1. [Remote ROS (RPi node and XCS master)](10-ros-remote.md)
1. [ROS package development (RPi/XCS)](11-ros-dev.md)
1. [Compile and Install WiringPi](12-wiringpi.md)

# 4. Setup RPi Peripherals

While not relevant for cross-compilation, this page describes how to setup i2c peripherals or the pi-camera. It is added to this guide for completeness to start you own projects.

## Table of Contents

1. [Prerequisites](#prerequisites)
1. [Setup i2c](#setup-i2c)
1. [i2c: RTC](#i2c-rtc)
1. [i2c: MCP23017 IO Expander](#i2c-mcp23017-io-expander)
1. [Setup Camera](#setup-camera)
1. [Next](#next)

## Prerequisites
- Setup of XCS and RPi
- Setup of RPi Network and SSH

## Setup i2c

Source: https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c

1. Connect to the RPi to install dependencies
    ```
    XCS~$ ssh rpizero-local
    RPI~$ sudo apt-get install python2.7 python3 python-smbus python3-smbus python-dev python3-dev i2c-tools
    ```

1. Edit `boot.txt` so i2c is loaded upon startup
    ```
    RPI~$ sudo nano /boot/config.txt
    ```

    Add the following lines to the bottom of the file
    ```
    #enable i2c
    dtparam=i2c1=on
    dtparam=i2c_arm=on
    ```

1. Edit `modules` so the i2c kernel is loaded
    ```
    RPI~$ sudo nano /etc/modules
    ```

    Add the following lines to the bottom of the file
    ```
    #load i2c
    i2c-bcm2708
    i2c-dev
    ```

1. Allow pi-user to use i2c
    ```
    RPI~$ sudo adduser pi i2c
    ```

1. Shutdown RPi and disconnect from the power supply
    ```
    RPI~$ sudo shutdown now
    ```

1. Connect your i2c device and powerup.

1. Check if an i2c device is found:
    ```
    RPI~$ sudo i2cdetect -y 1
       0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
      00:          -- -- -- -- -- -- -- -- -- -- -- -- --
      10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
      20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
      30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
      40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
      50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
      60: -- -- -- -- -- -- -- -- 68 -- -- -- -- -- -- --
      70: -- -- -- -- -- -- -- --  
   ```

   > The number shown is the i2c address of the device you connected.

## i2c: RTC
Source: https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero

1. Ensure that the RTC is attached to the RPi and that `i2cdetect` lists it as a i2c device.
1. Edit `boot.txt` so the RTC is loaded upon startup
    ```
    XCS~$ ssh rpizero-local
    RPI~$ sudo nano /boot/config.txt
    ```

    Add the following lines to the bottom of the file
    ```
    #enable rtc
    dtoverlay=i2c-rtc,ds1307
    ```

1. Edit `modules` so the RTC kernel is loaded
    ```
    RPI~$ sudo nano /etc/modules
    ```

    Add the following lines to the bottom of the file
    ```
    #load rtc
    rtc-ds1307
    ```

1. Allow (re)setting of the hw-clock
    ```
    RPI~$ sudo nano /lib/udev/hwclock-set
    ```

    Comment out these lines:
    ```
    # if [ -e /run/systemd/system ] ; then
    # exit 0
    # fi
    ```

1. Reboot to load RTC
    ```
    RPI~$ sudo reboot now
    ```

1. Reading and setting the `hwclock` can be done by:

    - Reading:
    ```
    RPI~$ sudo hwclock -r
    ```

    - Writing:
    ```
    RPI~$ sudo date -s "Fri Jan 20 10:53:40 CET 2017"
    RPI~$ sudo hwclock -w  
    ```

## i2c: MCP23017 IO Expander
Source: https://www.kiwi-electronics.nl/io-pi-zero

..

## Setup Camera

1. Shutdown RPi and disconnect from the power supply
1. Connect the camera and powerup.
1. After powerup, login via SSH and enable camera
    ```
    XCS~$ ssh rpizero-local
    RPI~$ sudo raspi-config
    ```

    Goto `Interfacing options > Camera > Select` and reboot

1. To test the camera, login with SSH with X-server enabled:
    ```
    XCS~$ ssh -X rpizero-local
    ```
    >  Take note on the message on login. If you see "Warning: untrusted X11 forwarding setup failed: xauth key data not generated" you might need to use the "-Y" instead of "-X" option.

1. Install the `links2` image viewer
    ```
    RPI~$ sudo apt-get install links2
    ```

1. Test the camera
    ```
    RPI~$ raspistill -v -o test.jpg
    ```  

1. View the preview.
    ```
    RPI~$ links2 -g test.jpg
    ```

    > Depending on the speed of the connection, this might take a while.

    > If you see a message similar to:
    ```
    Could not initialize any graphics driver. Tried the following drivers:
    x:
    Can't open display "(null)"
    fb:
    Could not get VT mode.
    ```
    >  you should review the "ssh"-login-message and might need to use the "-Y" instead of "-X" option of `ssh` as noted above.

## Next

Having installed the peripherals, it is time to [setup the cross-compilation environment](04-xc-setup.md).
