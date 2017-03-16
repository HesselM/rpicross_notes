## Raspberry Pi Peripherals
The used setup contains both a Real Time Clock (RTC - https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero ) and a Raspberry Pi Camera ( https://thepihut.com/collections/raspberry-pi-camera/products/raspberry-pi-camera-module ). Hence, to be complete, I included the taken steps to install these peripherals. 

## Real-time Clock
For the RTC we first need to enable i2c, after which the RTC can be configured.

### Enable i2c
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
    RPI~$ sudo reboot
    ```

### Enable RTC
Source: https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero

1. Shutdown RPi and disconnect from the power supply
1. Connect the RTC and powerup.
1. After powerup, login via SSH
    ```
    XCS~$ ssh rpizero-local
    ```
  
1. Check if the RTC clock is found:
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
  
## Camera

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

Having installed the peripherals, it is time to [setup the crosscompilation environment](4-xc-setup.md).
