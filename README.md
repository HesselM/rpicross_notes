# Guide to Setup and Cross Compile for a Raspberry Pi

This repository is a personal guide to setup a cross compilation environment to compile OpenCV and ROS programs on a Raspberry Pi. It contains details on the setup of a VirtualBox, SSH / X-server / network settings, syncing / backing up and of course how to compile and install OpenCV with Python bindings and dynamic library support (such as GTK). Experience with VirtualBox, C, Python and the terminal are assumed. Usage of external keyboards or monitors for the Raspberry Pi is not required: setup is done via card mounting or SSH. 

Disclaimer 1: Many, many, many StackOverflow, Github issues, form-posts and blog-pages have helped me developing these notes. Unfortunatly I haven't written down all these links and hence cannot thank or link all authors, for which my apology. Here an incomplete list of sources:
- VirtualBox SSH: https://forums.virtualbox.org/viewtopic.php?f=8&t=55766
- SSH X-server: http://unix.stackexchange.com/questions/12755/how-to-forward-x-over-ssh-from-ubuntu-machine
- RPI: https://www.raspberrypi.org/documentation/installation/installing-images/linux.md
- RPI RTC: https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c
- RPI RTC: https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero
- PkgConfig: http://dev.gentoo.org/~mgorny/pkg-config-spec.html
- PkgConfig: https://autotools.io/pkgconfig/cross-compiling.html
- OpenCV: http://docs.opencv.org/2.4/doc/tutorials/introduction/linux_gcc_cmake/linux_gcc_cmake.html
- OpenCV/RPI: http://docs.opencv.org/2.4/doc/tutorials/introduction/crosscompilation/arm_crosscompile_with_cmake.html
- OpenCV/Raspicam: https://thinkrpi.wordpress.com/2013/05/22/opencvpi-cam-step-2-compilation/
- OpenCV/AR: http://answers.opencv.org/question/90298/static-lib-cross-compile-zlib-error/
- OpenCV/Python: http://thebbbdiary.blogspot.nl/2015_01_01_archive.html
- Shared Libraries: http://redmine.webtoolkit.eu/projects/wt/wiki/Cross_compile_Wt_on_Raspberry_Pi/

Disclaimer 2: The steps/solutions described in these notes are by now mean the best available. As I'm not an expert, better solutions might be out there. If you happen to know a better (and working) solution, or if you spot a mistaks: feel free to post an issue!

## How to Read?

The notes are more or less in chronological order, hence start from top the bottom. Commands are prefixed with the system on which the commands needs to be run:

- `HOST~$` commands executed on the Host. As this guide is developed using OSX, commands will be unix-styled.
- `XCS~$` commands executed on the Cross-Compiler Server / Virtualbox
- `RPI~$` commands executed on the Raspberry Pi

# Setup

In order to be able to experiment with compilation and installation of the necessary tools without messing op the main system, all tools will be installed in a clean and headless [VirtualBox](https://www.virtualbox.org/) environment. Development will be done on the host with VirtualBox accesing the code via shared folders.

## Virtualbox

### Installation
1. Download VirtualBox
1. Download Ubuntu 16.04 Server LTS [https://www.ubuntu.com/download/server]
1. Create new VirtualBox Image:
  - Name: XCS-rpizero
  - Type: Linux
  - Version: Ubuntu (64-bit)
  - Memory: 4096 MB
  - + Create a virtual hard disk now
    - Size:		25,00 GB
    - Type:	VMDK
    - Storage:	Dynamically allocated	
  - + Settings:
    - System > Processor > CPU:	3
    - Network > Advanced > Port Forwarding > New Rule
      - Name: SSH
      - Protocol: TCP
      - Host IP: (leave empty)
      - Host Port: 2222
      - Guest IP: (leave empty)
      - Guest Port: 22
    - Storage > Controller IDE > Empty > IDE Secondary Master > Choose Virtual Optical Disk File > ubuntu-16.04.2-server-amd64.iso
    - Ports > USB > USB3 controller
1. To be able to resolve (local) DNS-addresses: allow guest to use the host DNS server.

  ```
  HOST~$ VBoxManage modifyvm "XCS-rpizero" --natdnshostresolver1 on
  ```
1. Start VirtualBox/VM, installing Ubuntu:
  - Hostname: XCS-server
  - User: pi
  - Password: raspberry
1. After installation, update VM

  ```
  XCS~$ sudo apt-get update
  XCS~$ sudo apt-get dist-upgrade
  ```
1. Install SSH-server (if omitted during Ubuntu installation)

  ```
  XCS~$ sudo apt-get install openssh-server
  ```
1. After reboot of the VM, you should be able to connect to the VM via port 2222:

  ```
  HOST~$ ssh -p 2222 pi@localhost
  ```
  
  or, when using X-server:
  
  ```
  HOST~$ ssh -X -p 2222 pi@localhost
  ```
  NOTE: For use of X-server ensure that `X11Forwarding yes` in `/etc/ssh/sshd_config` in the VM and `ForwardX11 yes` in `~/.ssh/config` on the Host. When changed, restart ssh: `sudo service ssh restart`.



### XCS directory structure

1. Create directory structure for code and cross compilation

  ```
  XCS~$ mkdir -p ~/build ~/code ~/rpi/rootfs ~/rpi/src ~/rpi/build ~/rpi/img ~/rpi/mnt
  ```
  These folders will be used as follow:
  ```
  ~/code        : shared folder containing user-code
  ~/build       : VM-only folder in which the user-code is build
  ~/rpi/rootfs  : root of the rpi cross-compilation file system. This directory equals '/' on the rpi.
  ~/rpi/src     : source-directory for rpi-tools and libraries
  ~/rpi/build   : build-directory for rpi-tools and libraries
  ~/rpi/img     : .img files for installation/backup of the rpi SDCard
  ~/rpi/mnt     : mount-point at which the rpi will be mounted.
  ```

### XCS Shared folder setup
1. Select/start `XCS-rpizero` in VirtualBox
1. Insert Guest additions: Devices > Insert Guest Additions CD image...
1. Install the additions in the VM

  ```
  XCS~$ sudo mount /dev/cdrom /media/cdrom
  XCS~$ sudo /media/cdrom/VBoxLinuxAdditions.run
  XCS~$ sudo adduser pi vboxsf
  ```
1. Add shared Folder: Machine > Settings > Shared Folders > Add
  - Select Folder Path
  - Name: code
  - + Automount
  - + Make permanent

1. Reboot VM to mount shared folder

  ```
  XCS~$ sudo reboot now
  ```
1. Create link to home-folder so we can acces the all code easily.

  ```
  XCS~$ ln -s /media/sf_code /home/pi/code
  ```

## Raspberry Pi
Source: https://www.raspberrypi.org/documentation/installation/installing-images/linux.md

1. Download and Unzip: Raspbian Jessie Lite (~292Mb)

  ```
  XCS~$ cd ~/rpi/img
  XCS~$ wget https://downloads.raspberrypi.org/raspbian_lite_latest
  XCS~$ unzip raspbian_lite_latest
  ```
  NOTE: the download is the lite version of raspbian and hence does not include a GUI or commonly used application. If a GUI is required, you can add it later, or download a different raspbian version.
1. Connect SDCard to the VM.
1. Detect SDCard & install img

  ```
  XCS~$ lsblk
    NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda                           8:0    0   25G  0 disk 
    ├─sda1                        8:1    0  487M  0 part /boot
    ├─sda2                        8:2    0    1K  0 part 
    └─sda5                        8:5    0 24.5G  0 part 
      ├─XCS--rpizero--vg-root   252:0    0 20.5G  0 lvm  /
      └─XCS--rpizero--vg-swap_1 252:1    0    4G  0 lvm  [SWAP]
    sdb                           8:16   1  7.3G  0 disk       <=== Our 8Gb SDCard!
    ├─sdb1                        8:17   1   63M  0 part 
    └─sdb2                        8:18   1  7.3G  0 part 
    sr0                          11:0    1 55.7M  0 rom  
    
  XCS~$ sudo dd bs=4M if=/home/pi/rpi/img/2017-03-02-raspbian-jessie-lite.img of=/dev/sdb
  ```
- Validate that image is properly copied

  ```
  XCS~$ sudo dd bs=4M if=/dev/sdb of=from-sd-card.img
  XCS~$ sudo truncate --reference 2017-03-02-raspbian-jessie-lite.img  from-sd-card.img
  XCS~$ sudo diff -s from-sd-card.img 2017-03-02-raspbian-jessie-lite.img 
  XCS~$ sync
  ```
- Remove images, we do not need these anymore

  ```
  XCS~$ sudo rm *.img
  ```

## Connection

After installing raspbian on the image, lets setup a connection!  

### Network settings

1. If not connected, connect SDCard to the VM.
1. Detect SDCard & find largest partition (the rpi filesystem)

  ```
  XCS~$ lsblk
    NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda                           8:0    0   25G  0 disk 
    ├─sda1                        8:1    0  487M  0 part /boot
    ├─sda2                        8:2    0    1K  0 part 
    └─sda5                        8:5    0 24.5G  0 part 
      ├─XCS--rpizero--vg-root   252:0    0 20.5G  0 lvm  /
      └─XCS--rpizero--vg-swap_1 252:1    0    4G  0 lvm  [SWAP]
    sdb                           8:16   1  7.3G  0 disk 
    ├─sdb1                        8:17   1   63M  0 part 
    └─sdb2                        8:18   1  7.3G  0 part       <=== Largest partion
    sr0                          11:0    1 55.7M  0 rom  
  ```
1. Mount SDCard

  ```
  XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt 
  ```
1. If required, setup static ipadress, DNS-servers and/or router IP:
  
  ```
  XCS~$ sudo nano /home/pi/rpi/mnt/etc/dhcpcd.conf
  ```
  - Edit and add the following lines to `dhcpcd.conf` as is required for your setup: 
  
  ```
  # we do not use eth0, only wifi
  #interface eth0

  profile static_wlan0
  static ip_address=172.16.60.200
  static routers=172.16.254.254
  static domain_name_servers=172.16.1.11 172.16.1.9

  # 1) try static settings
  # 2) if fails, just settle with dhcp
  interface wlan0
  arping static_wlan0
  ```
  
1. Setup WiFi credentials

  ```
  XCS~$ sudo nano /home/pi/rpi/mnt/etc/wpa_supplicant/wpa_supplicant.conf
  ```
  - Add the required credentials. In this example, the order equals connection order. So first `network1` is tried, after which `network2` is tested if `network1` cannot be reached.
  ```
  network={
    ssid="<network1>"
    psk="<password_of_network1>"
  }

  network={
    ssid="<network2>"
    psk="<password_of_network2>"
  }
  ```

### Hostname

By default, the hostname of a rpi is `raspberrypi`, hence the rpi can be accessed via the dns `raspberrypi.local`. As multiple rpi's migh be functioning in the environment, it might be a good idea to change the hostname.


1. Mount largest partion of the SDCard if it isn't mounted anymore.

  ```
  XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt 
  ```
1. Edit `hostname`

  ```
  XCS~$ nano /home/pi/rpi/mnt/etc/hostname
  ```
1. Change `raspberrypi` in e.g. `rpizw`
1. Edit `hosts`

  ```
  XCS~$ nano /home/pi/rpi/mnt/etc/hosts
  ```
1. Change `127.0.0.1 raspberrypi` in e.g. `127.0.0.1 rpizw`. Note that the hostname should equal the name you've chosen previously.
1. Finish setup by unmounting the mounted partition

  ```
  XCS~$ sudo umount /home/pi/rpi/mnt
  ```

### Enable SSH

1. To enable SSH on the rpi, detect disk & mount SMALLEST partition

  ```
  XCS~$ lsblk
    NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda                           8:0    0   25G  0 disk 
    ├─sda1                        8:1    0  487M  0 part /boot
    ├─sda2                        8:2    0    1K  0 part 
    └─sda5                        8:5    0 24.5G  0 part 
      ├─XCS--rpizero--vg-root   252:0    0 20.5G  0 lvm  /
      └─XCS--rpizero--vg-swap_1 252:1    0    4G  0 lvm  [SWAP]
    sdb                           8:16   1  7.3G  0 disk 
    ├─sdb1                        8:17   1   63M  0 part       <=== Smallest partition
    └─sdb2                        8:18   1  7.3G  0 part
    sr0                          11:0    1 55.7M  0 rom  

  XCS~$ sudo mount /dev/sdb1 /home/pi/rpi/mnt 
  ```
1. Add ssh file

  ```
  XCS~$ sudo touch /home/pi/rpi/mnt/ssh
  ```
1. Finish setup by unmounting the mounted partition

  ```
  XCS~$ sudo umount /home/pi/rpi/mnt
  ```

## First Boot
Hooray! We can now finally boot the rpi. Insert the SDCard and power it up.
Before we can continue our quest to cross-compiling, we need to do some maintenance. 

1. SSH to the rpi (use hostname or ipadress if known)

  ```
  XCS~$ ssh pi@rpizw.local
  ```
1. Expand filesystem & reboot

  ```
  RPI~$ sudo sudo raspi-config --expand-rootfs
  RPI~$ sudo reboot now
  ```
1. After boot, connect again & update rpi

  ```
  XCS~$ ssh pi@rpizw.local
  RPI~$ sudo apt-get update
  RPI~$ sudo apt-get dist-upgrade
  ```
  
## Setup SSH-keys
Currently, you need to type your password each time you connect with the rpi. With the use of ssh-keys, we can automate this process.

1. Generate ssh-keys in the VM. Optionally you can choose a different rsa-name (required if you are planning to use multie keys for different systems) and set a passphrase (increasing security). In my setup I left the passphrase empty (just hitting enter). 

  ```
  XCS~$ cd~/.ssh
  XCS~$ ssh-keygen -t rsa
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/pi/.ssh/id_rsa): rpizero_rsa
    Enter passphrase (empty for no passphrase): <empty>
    Enter same passphrase again: <empty>
    Your identification has been saved in rpizero_rsa.
    Your public key has been saved in rpizero_rsa.pub.
    ...
  ```
1. Set correct permisions of the key-set

  ```
  XCS~$ chmod 700 rpizero_rsa rpizero_rsa.pub
  ```
1. Send a copy of the public key to the rpi so it can verify the connection  

  ```
  cat ~/.ssh/rpizero_rsa.pub | ssh pi@rpizw.local "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
  ```
1. Configure ssh connection in `ssh_config`

  ```
  XCS~$ sudo nano /etc/ssh/ssh_config
  ```
  - Depending on the configuration of `dhcpcd.conf` on the rpi, add the following lines:
  
  ```
  #connect via static ip
  Host rpizero
    HostName 172.16.60.200
    IdentityFile ~/.ssh/rpizero_rsa
    User pi
    Port 22
  
  # connect via hostname
  Host rpizero-local
    HostName rpizw.local
    IdentityFile ~/.ssh/rpizero_rsa
    User pi
    Port 22
  ```
1. Allow bash to invoke the config upon a ssh-call

  ```
  XCS~$ ssh-agent bash
  XCS~$ ssh-add /home/pi/.ssh/rpizero_rsa
  ```
1. Test connection:

  ```
  XCS~$ ssh rpizero-local 
  ```
  - You should now be logged in onto the rpi via ssh, without entering your password.

## Setup SSH-keys: root
For synchronisation of the rpi-rootfs in our cross-compile environment and the root of the 'real' rpi, ssh needs root acces.

1. Configure ssh connection in `ssh_config`

  ```
  XCS~$ sudo nano /etc/ssh/ssh_config
  ```
  - Depending on the configuration of `dhcpcd.conf` on the rpi, add the following lines:
  
  ```
  #connect via static ip
  Host rpizero-root
    HostName 172.16.60.200
    IdentityFile ~/.ssh/rpizero_rsa
    User root
    Port 22
  
  # connect via hostname
  Host rpizero-local-root
    HostName rpizw.local
    IdentityFile ~/.ssh/rpizero_rsa
    User root
    Port 22
  ```
1. Login to the rpi the enable root.

  ```
  XCS~$ ssh rpizero-local
  ```
1. Setup root-password. Note: this should be the same as the password for the user `pi` !!
  
  ```
  RPI~$ sudo passwd root
  ```
1. Enable root-login

  ```
  RPI~$ sudo nano /etc/ssh/sshd_config
  ```
  - set `PermitRootLogin XXXX` to `PermitRootLogin yes`.
1. Restart ssh service

  ```
  RPI~$ sudo service ssh restart
  ```
1. Send a copy of the ssh-keys for the root user to the rpi:

  ```
  XCS~$ cat ~/.ssh/rpizero_rsa.pub | ssh root@rpizw.local "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
  ```


## Raspberry Pi Peripherals
The used setup contains both a Real Time Clock (RTC - https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero ) and a raspberry pi Camera ( https://thepihut.com/collections/raspberry-pi-camera/products/raspberry-pi-camera-module ). Hence, to be complete, I included the taken steps to install these peripherals. 

## Real-time Clock
For the RTC we first need to enable i2c, after which the RTC can be configured

### Enable i2c
Source: https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c

1. Connect to the rpi

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
  - Add the following lines to the bottom of the file
  
  ```
  #enable i2c
  dtparam=i2c1=on
  dtparam=i2c_arm=on
  ```
1. Edit `modules` so the i2c kernel is loaded

  ```
  RPI~$ sudo nano /etc/modules
  ```
  - Add the following lines to the bottom of the file
  
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

1. Connect to the rpi

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
  - Add the following lines to the bottom of the file
  
  ```
  #enable rtc
  dtoverlay=i2c-rtc,ds1307
  ```
1. Edit `modules` so the rtc kernel is loaded

  ```
  RPI~$ sudo nano /etc/modules
  ```
  - Add the following lines to the bottom of the file
  
  ```
  #load rtc
  rtc-ds1307
  ```
1. Allow (re)setting of the hw-clock

  ```
  RPI~$ sudo nano /lib/udev/hwclock-set
  ```
 - Comment out these lines:
  
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
  - Reading
  
  ```
  RPI~$ sudo hwclock -r
  ```
  
  - Writing
  
  ```
  RPI~$ sudo date -s "Fri Jan 20 10:53:40 CET 2017"
  RPI~$ sudo hwclock -w  
  ```

## Camera

1. Connect the camera when the rpi is turned off and not connected with power
1. After powerup, login via SSH

  ```
  XCS~$ ssh rpizero-local
  ```
1. Enable Camera

  ```
  RPI~$ sudo raspi-config
  ```
  - Goto `Interfacing options > Camera > Select` and reboot
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
1. View the preview. (depending on the speed of the connection, this might take a while)

  ```
  RPI~$ links2 -g test.jpg
  ```

# Crosscompilation

## Setup

## Userland

## OpenCV

# Testing
## Hello Pi!
## Hello Camera!
## Hello OpenCV!



