## Raspberry Pi Peripherals
This page describes how to add i2c perhiperals and a Pi Camera. The examples below are created with:

1. i2c : [Real Time Clock (RTC)](https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero) 
1. i2c : [MCP23017 IO Exanpeder](https://www.kiwi-electronics.nl/io-pi-zero) 
1. [Noir V2 Raspberry Pi Camera](https://thepihut.com/collections/raspberry-pi-camera/products/raspberry-pi-camera-module) 

These steps assume that the RPi is up and running. 

## Enable i2c

Source: https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c

1. Connect to the RPi
    ```
    XCS~$ ssh rpizero-local
    ```
    
1. Install dependencies
    ```
    sudo apt-get install python-smbus python3-smbus python-dev python3-dev i2c-tools
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
1. Allow pi-user to use i2c & reboot
    ```
    RPI~$ sudo adduser pi i2c
    ```

1. Shutdown RPi and disconnect from the power supply
    ```
    RPI~$ sudo shutdown now
    ```
    
1. Connect your i2c device and powerup.

1. Check if an RTC device is found:
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
  
## Setup RTC
Source: https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero

1. Ensure that the RTC is attached to the RPi and that `i2cdetect` lists it as a i2c device.
1. Edit `boot.txt` so the rtc is loaded upon startup
    ```
    RPI~$ sudo nano /boot/config.txt
    ```
  
    Add the following lines to the bottom of the file
    ```
    #enable rtc
    dtoverlay=i2c-rtc,ds1307
    ```
    
1. Edit `modules` so the rtc kernel is loaded
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
  
## Setup RPi Camera

1. Shutdown RPi and disconnect from the power supply
1. Connect the camera and powerup.
1. After powerup, login via SSH
    ```
    XCS~$ ssh rpizero-local
    ```
    
1. Enable Camera
    ```
    RPI~$ sudo raspi-config
    ```
    
    Goto `Interfacing options > Camera > Select` and reboot
    
1. To test the camera, login with SSH with X-server enabled:
    ```
    XCS~$ ssh -X rpizero-local
    ```
    
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

# Next

Having installed the peripherals, it is time to [setup the crosscompilation environment](04-xc-setup.md).
