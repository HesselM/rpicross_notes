# Guide to Setup and Cross Compile for a Raspberry Pi

This repository is a personal guide to setup a cross compilation environment to compile OpenCV and ROS programs for a Raspberry Pi. It contains details on how to setup a VirtualBox, configure SSH / X-server / network settings, how to sync syncing / back up files to the Raspberry Pi and of course how to compile and install OpenCV and ROS. Experience with VirtualBox, C, Python and the terminal/nano are assumed. Usage of external keyboards or monitors for the Raspberry Pi is not required: setup is done via card mounting or SSH. 

At the end of this list you should have:
- A Virtualbox running Ubuntu Server 16.04 LTS, with:
  - SSH connectivity from HOST to GUEST and from GUEST to the Raspberry Pi
  - Crosscompilation environment including:
    - Toolchain /  compilers to compile for the Raspberry Pi
    - Userland libraries (GPU support for the Raspberry Pi)
    - OpenCV with additional modules and library support such as GTK+
    - Synchronisation tools to update the Raspberry Pi with our compiled libraries.
  - ROS Master environment [TODO]
- A Raspberry Pi running Jessie Lite, including
  - X-Server
  - OpenCV with Python Bindings
  - Running PiCamera
  - i2c and a Real Time Clock (RTC)
  - ROS and autoset sccript to connect with an external ROS-Master. [TODO]

Before the required steps are explained, some disclaimers:

1. Many, many, many StackOverflow questions, Github issues, form-posts and blog-pages have helped me developing these notes. Unfortunatly I haven't written down all these links and hence cannot thank or link all authors, for which my apology. Here is an incomplete list of used sources:
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
1. There is no guarantee that the steps described in these notes are the best available. As I'm not an expert, better solutions might be out there. The provided steps however resulted in a working/workable setup for me.
1. If you happen to know a better (and working) solution, have a question, suggestion or if you spot a mistake: feel free to post an issue!

## How to Read?

The notes are more or less in chronological order, hence start from top the bottom. Commands are prefixed with the system on which the commands needs to be run:

- `HOST~$` commands executed on the Host. As this guide is developed using OSX, commands will be unix-styled.
- `XCS~$` commands executed on the Cross-Compiler Server / Virtualbox
- `RPI~$` commands executed on the Raspberry Pi

# Setup

In order to be able to experiment with compilation and installation of the necessary tools without messing op the main system, all tools will be installed in a clean and headless [VirtualBox](https://www.virtualbox.org/) environment. 

Communication, installation and synchronisation of all required dependencies and libraries will be done via commandline. 

As I prefer the development enviroment of my HOST-system, developed code will be accessible by the toolchain in the virtual machine (VM) via a shared folder construction.

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
    - Size: 25,00 GB
    - Type: VMDK
    - Storage: Dynamically allocated	
  - + Settings:
    - System > Processor > CPU:	3

      > Exact value depends on your system capabilities. My Host contains 8 CPU's, hence 3 can be used for the VM
    - Network > Advanced > Port Forwarding > New Rule
      
      > Used to connect to the Guest via SSH from the Host
      - Name: SSH
      - Protocol: TCP
      - Host IP: (leave empty)
      - Host Port: 2222
      - Guest IP: (leave empty)
      - Guest Port: 22
    - Storage > Controller IDE > Empty > IDE Secondary Master > Choose Virtual Optical Disk File > ubuntu-16.04.2-server-amd64.iso
    - Ports > USB > USB3 controller
      
      > My Host did not support the USB2 controller.
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
  
  > For use of X-server ensure that `X11Forwarding yes` in `/etc/ssh/sshd_config` in the VM and `ForwardX11 yes` in `~/.ssh/config` on the Host. When changed, restart ssh: `sudo service ssh restart`.
1. To be able to resolve (local) DNS-addresses: allow guest to use the host DNS server.

  ```
  HOST~$ VBoxManage modifyvm "XCS-rpizero" --natdnshostresolver1 on
  ```

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
  ~/rpi/mnt     : mount-point to which rpi-images will be mounted.
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
1. Create link to home-folder so we can access our (user-)code easily.

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
  > This download is the Lite version of raspbian and hence does not include a GUI or commonly used application. If a GUI is required, you can add it later via `apt-get` or download a different raspbian version.
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
- Validate that the image is properly copied

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

After installing raspbian on the SDCard, lets setup a connection!  

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
  Edit and add the following lines to `dhcpcd.conf` as required for your setup: 
  
  ```
  # we do not use eth0, only wifi
  #interface eth0

  profile 172.16.254.254
  static ip_address=172.16.60.200
  static routers=172.16.254.254
  static domain_name_servers=172.16.1.11 172.16.1.9

  # 1) try static settings
  # 2) if fails, just settle with dhcp
  interface wlan0
  arping 172.16.254.254
  ```
  > Somehow, this approach does not work in conjunction with multiple WiFi network configurations. The exact reason why this fails is (yet) unkown to me. Perhaps a wrong settting is messing up my setup?
1. Setup WiFi credentials

  ```
  XCS~$ sudo nano /home/pi/rpi/mnt/etc/wpa_supplicant/wpa_supplicant.conf
  ```
  Add the required credentials. In this example, the order equals the connection order. So initially `network1` is tried to setup a connection, when failing (e.g. not available), `network2` is tested.
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

1. Mount largest partion of the SDCard in the VM.

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
1. Change `127.0.0.1 raspberrypi` in e.g. `127.0.0.1 rpizw`. 

  > The hostname in `hosts` should equal the name written down in `hostname` previously.
1. Finish setup by unmounting the mounted partition

  ```
  XCS~$ sudo umount /home/pi/rpi/mnt
  ```

### Enable SSH

1. To enable SSH on the rpi, detect SDCard & mount SMALLEST partition

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
Hooray! We can now finally boot the rpi. Insert the SDCard in the rpi and power it up.
Before we can continue our quest to cross-compiling, we need to do some rpi-maintenance. 

1. SSH to the rpi (use hostname or ipadress if known)

  ```
  XCS~$ ssh pi@rpizw.local
  ```
1. Expand filesystem to use full size of SDCard & reboot

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

1. Generate ssh-keys in the VM. 

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
  > Optionally you can choose a different rsa-name (required if you are planning to use multie keys for different systems) and set a passphrase (increasing security). In my setup I left the passphrase empty (just hitting enter). 
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
1. Allow bash to invoke the configuration upon a ssh-call

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
  Depending on the configuration of `dhcpcd.conf` on the rpi, add the following lines:
  
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
1. Setup root-password. 
  
  ```
  RPI~$ sudo passwd root
  ```
  > IMPORTANT: the given password should equal the password for the user `pi` !!
1. Enable root-login

  ```
  RPI~$ sudo nano /etc/ssh/sshd_config
  ```
  set `PermitRootLogin XXXX` to `PermitRootLogin yes`.
1. Restart ssh service

  ```
  RPI~$ sudo service ssh restart
  ```
1. Send a copy of the ssh-keys for the root user to the rpi:

  ```
  XCS~$ cat ~/.ssh/rpizero_rsa.pub | ssh root@rpizw.local "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
  ```


## Raspberry Pi Peripherals
The used setup contains both a Real Time Clock (RTC - https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero ) and a Raspberry Pi Camera ( https://thepihut.com/collections/raspberry-pi-camera/products/raspberry-pi-camera-module ). Hence, to be complete, I included the taken steps to install these peripherals. 

## Real-time Clock
For the RTC we first need to enable i2c, after which the RTC can be configured.

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
  Reading:
  
  ```
  RPI~$ sudo hwclock -r
  ```
  Writing:
  
  ```
  RPI~$ sudo date -s "Fri Jan 20 10:53:40 CET 2017"
  RPI~$ sudo hwclock -w  
  ```

## Camera

1. Shutdown rpi and disconnect from the power supply
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

# Crosscompilation
At this moment you should have a raspberry pi with functioning camera, rtc and ssh-configuration. This section will explain the steps required to compile `userland` (headers to communicate with the rpi-GPU) and `OpenCV` with Python bindings and support of external libraries such as GTK+. 

## Install required packages, backup and create rootfs
1. First we need to install some additional packages on the rpi for e.g. synchronisation and OpenCV building

  ```
  XCS~$ ssh rpizero-local
  RPI~$ sudo apt-get install libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev python2.7 python-dev python-numpy libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev rsync
  ```
1. Before continuing, lets backup the SDCard
  - Shutdown RPI
  
  ```
  RPI~$ sudo shutdown now
  ```
  - Disconnect RPI from power and remove SDCard
  - Connect SDCard with VM, locate in terminal and make a full copy. 
  
  ```
  XCS~$ lsblk
    NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda                           8:0    0   25G  0 disk 
    ├─sda1                        8:1    0  487M  0 part /boot
    ├─sda2                        8:2    0    1K  0 part 
    └─sda5                        8:5    0 24.5G  0 part 
      ├─XCS--rpizero--vg-root   252:0    0 20.5G  0 lvm  /
      └─XCS--rpizero--vg-swap_1 252:1    0    4G  0 lvm  [SWAP]
    sdb                           8:16   1  7.3G  0 disk       <=== Our RPI SDCard!
    ├─sdb1                        8:17   1   63M  0 part 
    └─sdb2                        8:18   1  7.3G  0 part 
    sr0                          11:0    1 55.7M  0 rom  
    
  XCS~$ sudo dd bs=4M if=/dev/sdb of=/home/pi/rpi/img/rpizero_clean.img
  ```
  > This copy equals the size of the SDCard. Ensure you have enough space!
  - Creating the backup might take a while, so grab a coffee :)
  - When needed, the SDCard can be reset, without the need to reinstalling all previously set settings:
    
  ```
  sudo dd bs=4M if=/home/pi/rpi/img/rpizero_clean.img of=/dev/sdb
  ```
  > Optionally, the .img can be compressed using gzip:
  
  ```
  XCS~$ gzip /home/pi/rpi/img/rpizero_clean.img
  ```
  > This replaces `rpizero_clean.img` with `rpizero_clean.img.gz`. To deflate use:
  
  ```
  XCS~$ gzip -d /home/pi/rpi/img/rpizero_clean.img.gz
  ```
  > Creating a compressed backup/restore can also done directly using `gzip` and `dd`:
  
  ```
  XCS~$ gzip -dc /home/pi/rpi/img/rpizero_clean.img.gz | sudo dd bs=4M of=/dev/sdb
  XCS~$ sudo dd bs=4M if=/dev/sdb | gzip > /home/pi/rpi/img/rpizero_clean.img.gz
  ```  
1. Next, lets build the rpi filesystem used for crosscompiling. 
  - Mount the largest partition of the SDCard and copy the `usr` and `lib` directories
  
  ```
  XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt 
  XCS~$ rsync -auHWv /home/pi/rpi/mnt/lib /home/pi/rpi/rootfs/
  XCS~$ rsync -auHWv /home/pi/rpi/mnt/usr /home/pi/rpi/rootfs/
  XCS~$ sudo umount /home/pi/rpi/mnt 
  ```

  > Instead of using the SDCard, `rpizero_clean.img` could als be used to create a new `rootfs`
  > - List .img properties
    
    ```
    XCS~$ fdisk -l /home/pi/rpi/img/rpizero_clean.img
      Disk /home/pi/rpi/img/rpizero_clean.img: 7.3 GiB, 7861174272 bytes, 15353856 sectors
      Units: sectors of 1 * 512 = 512 bytes
      Sector size (logical/physical): 512 bytes / 512 bytes
      I/O size (minimum/optimal): 512 bytes / 512 bytes
      Disklabel type: dos
      Disk identifier: 0xa11202a8 
 
      Device                              Boot  Start      End  Sectors  Size Id Type
      /home/pi/rpi/img/rpizero_clean.img1        8192   137215   129024   63M  c W95 FAT32 (LBA)
      /home/pi/rpi/img/rpizero_clean.img2      137216 15353855 15216640  7.3G 83 Linux
    ```
  > - determine `start` of the filesystem parition, e.g: 137216
  > - determine `unit size`, e.g. 512
  > - multiply these values: 137216 * 512 = 70254592
  > - mount and copy
    
  ```
  XCS~$ sudo mount -o loop,offset=70254592 /home/pi/rpi/img/rpizero_clean.img /home/pi/rpi/mnt
  XCS~$ rsync -auHWv /home/pi/rpi/mnt/lib /home/pi/rpi/rootfs/
  XCS~$ rsync -auHWv /home/pi/rpi/mnt/usr /home/pi/rpi/rootfs/
  XCS~$ sudo umount /home/pi/rpi/mnt 
  ```
1. Finally, we need to install several packages on the VM in order to build/compile our libraries

  ```
  XCS~$ sudo apt-get install build-essential
  XCS~$ sudo apt-get install pkg-config cmake unzip
  ```
  
## Toolchain
In order to compile code for the rpi, a compiler is needed which can build, create and link our c-code with libraries and transform it in to arm-instructions. This is done by a toolchain. Toolchains can be created with e.g. `linearo` or `gcc` (see: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/).  In case of the rpi, we can simplify life a bit by using the existing toolchain available at [https://github.com/raspberrypi/]( https://github.com/raspberrypi/).

1. Download toolchain. This wil create a folder called `tools` in `~/rpi` in the VM.

  ```
  XCS~$ cd ~/rpi
  XCS~$ git clone https://github.com/raspberrypi/tools.git --depth 1
  ```
1. Create links to the proper gcc-binairies.

  ```
  XCS~$ sudo ln -s /home/pi/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc /usr/bin/rpizero-gcc
  XCS~$ sudo ln -s /home/pi/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-g++ /usr/bin/rpizero-g++
  XCS~$ sudo ln -s /home/pi/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-ar /usr/bin/rpizero-ar
  ```
1. Clean up unneeded branches in the tools-directory to save space.

  ```
  XCS~$ rm -rf /home/pi/rpi/tools/arm-bcm2708/arm-bcm2708*
  ```

## Userland
The [userland](https://github.com/raspberrypi/userland) repository of the Pi Foundation contains several libraires to communicate with the GPU and use GPU related actions such as `mmal`, `GLES` and others. 

> Using the toolchain the userland libraries can be compiled and installed in `~/rpi/rootfs`. While it is advisable to download and build libraries outside the targeted `rootfs` (using e.g. `~/rpi/build` and `~/rpi/src`), the build commands for userland do not install all headers. Therefore, in the next steps, userland will be build in `rootfs`. 

1. Create userland (`opt/vc`) directory and download repository

  ```
  XCS~$ mkdir -p ~/rpi/rootfs/opt/vc/
  XCS~$ cd ~/rpi/rootfs/opt/vc/
  XCS~$ git clone https://github.com/raspberrypi/userland.git --depth 1
  ```
1. Edit the `userland` toolchain to invoke the proper compiler

  ```
  XCS~$ nano /home/pi/rpi/rootfs/opt/vc/userland/makefiles/cmake/toolchains/arm-linux-gnueabihf.cmake
  ```
  Comment out these lines:
  
  ```
  # set(CMAKE_C_COMPILER ..
  # set(CMAKE_CXX_COMPILER ..
  # set(CMAKE_ASM_COMPILER ..
  ```
1. Create build directory and build userland.
  
  ```
  XCS~$ mkdir -p userland/build/arm-linux/release
  XCS~$ cd userland/build/arm-linux/release
  XCS~$ cmake \
    -D CMAKE_C_COMPILER=/usr/bin/rpizero-gcc \
    -D CMAKE_CXX_COMPILER=/usr/bin/rpizero-g++ \
    -D CMAKE_ASM_COMPILER=/usr/bin/rpizero-gcc \
    -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/rootfs_tst/opt/vc/userland/makefiles/cmake/toolchains/arm-linux-gnueabihf.cmake \
    -D CMAKE_BUILD_TYPE=Release \
    /home/pi/rpi/rootfs_tst/opt/vc/userland/
  ```
  This should produce an output which looks like:
  
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
  -- Build files have been written to: /home/pi/rpi/rootfs/opt/vc/userland/build/arm-linux/release
  ```
1. Next, `make` userland.

  ```
  XCS~$ make -j 4
  ```
  > `-j 4` tells make to use 4 threads, which speeds up the process. 
  
  ```
  ...
  [100%] Linking C shared library ../../../../lib/libopenmaxil.so
  [100%] Linking C executable ../../../../../../bin/raspistill
  [100%] Built target openmaxil
  [100%] Built target raspistill
  ```
  > `make` will produce a lot of messages, but should finish with something similar as shown above.
  
1. Finally, we can install the created libraries:

  ```
  XCS~$ make install DESTDIR=/home/pi/rpi/rootfs
  ```
1. As `userland` is now created and installed, we should remove the build-directory before we sync with the rpi.

  ```
  XCS~$ rm -rf /home/pi/rpi/rootfs/opt/vc/userland/build
  ```
1. For testing the userland libraries, see [Syncing, Compiling and Testing](#syncing-compiling-and-testing)

## OpenCV
This section will cross-compile and install OpenCV, its additional modules and python bindings. 

1. Download and unzip the `OpenCV` sources.

  ```
  XCS~$ cd ~/rpi/src
  XCS~$ wget https://github.com/opencv/opencv/archive/3.2.0.zip
  XCS~$ unzip 3.2.0.zip 
  XCS~$ rm 3.2.0.zip
  XCS~$ wget https://github.com/opencv/opencv_contrib/archive/3.2.0.zip
  XCS~$ unzip 3.2.0.zip 
  XCS~$ rm 3.2.0.zip 
  ```
1. After downloading, we need to edit the `OpenCV`-arm toolchain as it does not support the Raspberry Pi Zero `armv6 hf` core properly. 
  
  ```
  XCS~$ nano /home/pi/rpi/src/opencv-3.2.0/platforms/linux/arm.toolchain.cmake
  ```
  Change the '-mthumb' flags to '-marm'. The resulting file should look similarly to:
  
  ```
  ...
  if(CMAKE_SYSTEM_PROCESSOR STREQUAL arm)
    set(CMAKE_CXX_FLAGS           "-marm ${CMAKE_CXX_FLAGS}")
    set(CMAKE_C_FLAGS             "-marm ${CMAKE_C_FLAGS}")
    set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} -Wl,-z,nocopyreloc")
  endif()
 ...
 ```
 > The toolchain presumes that a `thumb` instruction set is available which consists of 32 and 16 bits instructions. As it uses multiple widths of instructions, the `thumb` architecture is able to combine instructions and hence speed up processing time. Only `armv7` or higher has this ability, hence it does not apply to the BCM2835 of the rpi.
1. Edit libc.so and libpthreads.so 
  > Compilation of `OpenCV` uses `libc.so` and `libpthread.so` located in `/home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/`. These two files are not real libraries, but link to those required. Unfortunalty, they include the absolute path from `rootfs`, which will produce compile errors as the compiler cannot find it. Hence we need to edit these.
  > A better solution might be available, as this might cause additional issues, but so far all seems to be ok. 
   - libc.so:
   
     ```
     XCS~$ nano /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libc.so
     ```
     Change 
   
     ```
     GROUP ( /lib/arm-linux-gnueabihf/libc.so.6 /usr/lib/arm-linux-gnueabihf/libc_nonshared.a  AS_NEEDED ( /lib/arm-linux-gnueabihf/ld-linux-armhf.so.3 ) )
     ```
     to 
  
     ```
     GROUP ( libc.so.6 libc_nonshared.a  AS_NEEDED ( ld-linux-armhf.so.3 ) )
     ```
   - libpthread.so:
   
     ```
     XCS~$ nano /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpthread.so
     ```
     Change 
   
     ```
     GROUP ( /lib/arm-linux-gnueabihf/libpthread.so.0 /usr/lib/arm-linux-gnueabihf/libpthread_nonshared.a )
     ```
     to 
   
     ```
     GROUP ( libpthread.so.0 libpthread_nonshared.a )
     ```
1. Several `CMAKE` settings need to be configured to compile OpenCV and the Python bindings properly. For convenience `OpenCVMinDepVersions.cmake` is adjusted. 

  ```
  XCS~$ nano /home/pi/rpi/src/opencv-3.2.0/cmake/OpenCVMinDepVersions.cmake 
  ```
  Add the following lines to the cmake file:
  
  ```
  # set compiler options
  set( CMAKE_C_COMPILER   "/usr/bin/rpizero-gcc" )
  set( CMAKE_CXX_COMPILER "/usr/bin/rpizero-g++" )
  # - include AR, as it is not cached by default by OpenCV
  set( CMAKE_AR           "/usr/bin/rpizero-ar"     CACHE FILEPATH "")
  set( CMAKE_RANLIB       "/usr/bin/rpizero-ranlib" CACHE FILEPATH "")

  #Pkg-config settings
  # - use host pkg-config
  set( PKG_CONFIG_EXECUTABLE "/usr/bin/pkg-config" CACHE FILEPATH "")
  # - but search target-tree
  # - See: https://autotools.io/pkgconfig/cross-compiling.html
  set( ENV{PKG_CONFIG_DIR}         "" CACHE FILEPATH "")
  set( ENV{PKG_CONFIG_LIBDIR}      "${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf/pkgconfig:${RPI_ROOTFS}/usr/share/pkgconfig:${RPI_ROOTFS}/opt/vc/lib/pkgconfig" CACHE FILEPATH "")
  set( ENV{PKG_CONFIG_SYSROOT_DIR} "${RPI_ROOTFS}" CACHE FILEPATH "")

  # setup rpi (target) directories for compiler
  # - paths where headers are located
  set( RPI_INCLUDE_DIR "-isystem ${RPI_ROOTFS}/usr/include/arm-linux-gnueabihf -isystem ${RPI_ROOTFS}/usr/include" CACHE STRING "" FORCE)
  # - paths where libraries (.so) are located.
  #   => PkgConfig is able to find these libs, but does not add these paths to the linker.
  #   => It should also be noted that the paths in the .pc files are for the rpi-root, and hence cannot be used on the host.
  set( RPI_LIBRARY_DIR "-Wl,-rpath ${RPI_ROOTFS}/usr/lib/arm-linux-gnueabihf -Wl,-rpath ${RPI_ROOTFS}/lib/arm-linux-gnueabihf" CACHE STRING "" FORCE)

  # Setup C/CXX flags.
  set( CMAKE_CXX_FLAGS        "${CMAKE_CXX_FLAGS} ${RPI_INCLUDE_DIR}" CACHE STRING "" FORCE)
  set( CMAKE_C_FLAGS          "${CMAKE_CXX_FLAGS} ${RPI_INCLUDE_DIR}" CACHE STRING "" FORCE)
  set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${RPI_LIBRARY_DIR}" CACHE STRING "" FORCE)

  # install dir
  set( CMAKE_INSTALL_PREFIX ${RPI_ROOTFS}/usr CACHE STRING "")

  #Python2.7
  set( PYTHON_EXECUTABLE          /usr/bin/python2.7 CACHE STRING "") 
  set( PYTHON_LIBRARY_DEBUG       /usr/lib/python2.7 CACHE STRING "")
  set( PYTHON_LIBRARY_RELEASE     /usr/lib/python2.7 CACHE STRING "")
  set( PYTHON_LIBRARY             /usr/lib/python2.7 CACHE STRING "")
  set( PYTHON_INCLUDE_DIR         "${RPI_ROOTFS}/usr/include/python2.7" CACHE STRING "")
  set( PYTHON2_NUMPY_INCLUDE_DIRS "${RPI_ROOTFS}/usr/lib/python2.7/dist-packages/numpy/core/include" CACHE STRING "")
  set( PYTHON2_PACKAGES_PATH      "${RPI_ROOTFS}/usr/local/lib/python2.7/site-packages" CACHE STRING "")
  ```
  - Several notes should be made on these settings.
    - `CACHE STRING/FILEPATH "" (FORCE)` ensures that, when `cmake` reads the file, the selected values are written to the cache and available during the build process of additional targets. It was added because some runs of `cmake` produced variating results as values where not properly updated.
    - `CMAKE_C_COMPILER`, `CMAKE_CXX_COMPILER`, `CMAKE_AR`, `CMAKE_RANLIB` are set to the proper linked binaires for the crosscompiler. The values of `CMAKE_AR` and `CMAKE_RANLIB` are set additionally as they are needed to link the arm-libraries properly. When not set several linking errors will be produced.
    - `cmake` and the `OpenCV`-cmake files use internally `pkgconfig` to find .pc files. These .pc files indicate which libaries are installed and where to find them. As the crosscompiler runs in a 64 bit x84 Ubuntu environment, it cannot use the 32bit arm `pkgconfig` of the rpi and hence uses the Ubuntu `pkgconfig` binairy. Since this binairy is configured to find .pc files on Ubuntu, it does not search `~/rpi/rootfs`. Therefore `PKG_CONFIG_DIR`, `PKG_CONFIG_LIBDIR` and `PKG_CONFIG_SYSROOT_DIR` are set to point to the proper locations. 
    - The `include` and `lib` paths of the detected .pc files are not cached properly, which will result in several errors during linking and building. Usally a linker (`ld`) searches paths specified in `ld.so.conf` in the root of the filesystem, but in my experience, the rpi-linker apperently does not. Therefore `RPI_INCLUDE_DIR` and `RPI_INCLUDE_LIB` are set to point to the appropiate headers and libraries. By inserting these values into the `CMAKE_CXX_FLAGS`/`CMAKE_C_FLAGS` and `CMAKE_EXE_LINKER_FLAGS`, `cmake` ensures that `gcc` and `ld` are still able to find the required files.
    - Commonly `OpenCV` is installed in `/usr/local`. This however gave several linking errors when compiling user-code such as the tests described in [Syncing, Compiling and Testing](#syncing-compiling-and-testing). These errors are solved by installing `OpenCV` directly in the usr directory, as done by setting `CMAKE_INSTALL_PREFIX`.
    - Since the rpi libraries are build for an arm-platform and the compiler only understands x84 binaries, `cmake` is unable to detect the proper Python parameters for python-bindings. The values specified at the bottom of the code-snippet enable `cmake` to find the proper files. It should be noted that this action only works when the same Python versions are installed on both the rpi and in the VM! Furthermore, the provided setup only creates Python-bindings for Python2.7. To use Python3.0, the proper `numpy` need to be installed and probably similar settings need to be set. 
    - Ideally, the `CMAKE_SYSROOT` command should be used to set to rootfs for a crosscompilation target. However, I did not succeed at setting the parameter properly and therefor use the `sysroot` located at:

      ```
      /home/pi/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/arm-linux-gnueabihf/sysroot
      ```
      The encountered error message was:
    
      ```
      /home/pi/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/../lib/gcc/arm-linux-gnueabihf/4.9.3/../../../../arm-linux-gnueabihf/bin/ld:
    cannot find crt1.o: No such file or directory
      ```
  
      While using these additional settings:
    
      ```
      set( CMAKE_SYSROOT     "${RPI_ROOTFS}" CACHE FILEPATH "")
      set( CMAKE_FIND_ROOT_PATH "${RPI_ROOTFS}" CACHE FILEPATH "")
      set( CMAKE_LIBRARY_ARCHITECTURE "arm-linux-gnueabihf" CACHE STRING "")
      set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
      #set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
      #set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
      #set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
      ```
1. The commands for building `OpenCV` then become: 

  ```
  XCS~$ mkdir -p ~/rpi/build/opencv
  XCS~$ cd ~/rpi/build/opencv
  XCS~$ cmake \
    -D RPI_ROOTFS=/home/pi/rpi/rootfs \
    -D BUILD_TESTS=NO \
    -D BUILD_PERF_TESTS=NO \
    -D BUILD_PYTHON_SUPPORT=ON \
    -D OPENCV_EXTRA_MODULES_PATH=/home/pi/rpi/src/opencv_contrib-3.2.0/modules \
    -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/src/opencv-3.2.0/platforms/linux/arm.toolchain.cmake \
    /home/pi/rpi/src/opencv-3.2.0
  ```
  Which produces a summary looking like: 
  
  ```
  -- General configuration for OpenCV 3.2.0 =====================================
--   Version control:               unknown
-- 
--   Extra modules:
--     Location (extra):            /home/pi/rpi/src/opencv_contrib-3.2.0/modules
--     Version control (extra):     unknown
-- 
--   Platform:
--     Timestamp:                   2017-03-10T15:02:12Z
--     Host:                        Linux 4.4.0-64-generic x86_64
--     Target:                      Linux 1 arm
--     CMake:                       3.5.1
--     CMake generator:             Unix Makefiles
--     CMake build tool:            /usr/bin/make
--     Configuration:               Release
-- 
--   C/C++:
--     Built as dynamic libs?:      YES
--     C++ Compiler:                /usr/bin/rpizero-g++  (ver 4.9.3)
--     C++ flags (Release):         -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wno-narrowing -Wno-delete-non-virtual-dtor -Wno-comment -fdiagnostics-show-option -pthread -fomit-frame-pointer -mfp16-format=ieee -ffunction-sections -fvisibility=hidden -fvisibility-inlines-hidden -O3 -DNDEBUG  -DNDEBUG
--     C++ flags (Debug):           -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wundef -Winit-self -Wpointer-arith -Wshadow -Wsign-promo -Wno-narrowing -Wno-delete-non-virtual-dtor -Wno-comment -fdiagnostics-show-option -pthread -fomit-frame-pointer -mfp16-format=ieee -ffunction-sections -fvisibility=hidden -fvisibility-inlines-hidden -g  -O0 -DDEBUG -D_DEBUG
--     C Compiler:                  /usr/bin/rpizero-gcc
--     C flags (Release):           -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wundef -Winit-self -Wpointer-arith -Wshadow -Wno-narrowing -Wno-comment -fdiagnostics-show-option -pthread -fomit-frame-pointer -mfp16-format=ieee -ffunction-sections -fvisibility=hidden -O3 -DNDEBUG  -DNDEBUG
--     C flags (Debug):             -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include -isystem /home/pi/rpi/rootfs/usr/include/arm-linux-gnueabihf -isystem /home/pi/rpi/rootfs/usr/include   -fsigned-char -W -Wall -Werror=return-type -Werror=non-virtual-dtor -Werror=address -Werror=sequence-point -Wformat -Werror=format-security -Wmissing-declarations -Wmissing-prototypes -Wstrict-prototypes -Wundef -Winit-self -Wpointer-arith -Wshadow -Wno-narrowing -Wno-comment -fdiagnostics-show-option -pthread -fomit-frame-pointer -mfp16-format=ieee -ffunction-sections -fvisibility=hidden -g  -O0 -DDEBUG -D_DEBUG
--     Linker flags (Release):
--     Linker flags (Debug):
--     ccache:                      NO
--     Precompiled headers:         NO
--     Extra dependencies:          gtk-x11-2.0 gdk-x11-2.0 pangocairo-1.0 atk-1.0 cairo gdk_pixbuf-2.0 gio-2.0 pangoft2-1.0 pango-1.0 gobject-2.0 fontconfig freetype gthread-2.0 glib-2.0 dc1394 dl m pthread rt
--     3rdparty dependencies:       zlib libjpeg libwebp libpng libtiff libjasper IlmImf libprotobuf tegra_hal
-- 
--   OpenCV modules:
--     To be built:                 core flann imgproc ml photo reg surface_matching video dnn freetype fuzzy imgcodecs shape videoio highgui objdetect plot superres xobjdetect xphoto bgsegm bioinspired dpm face features2d line_descriptor saliency text calib3d ccalib datasets rgbd stereo tracking videostab xfeatures2d ximgproc aruco optflow phase_unwrapping stitching structured_light python2
--     Disabled:                    world contrib_world
--     Disabled by dependency:      -
--     Unavailable:                 cudaarithm cudabgsegm cudacodec cudafeatures2d cudafilters cudaimgproc cudalegacy cudaobjdetect cudaoptflow cudastereo cudawarping cudev java python3 ts viz cnn_3dobj cvv hdf matlab sfm
-- 
--   GUI: 
--     QT:                          NO
--     GTK+ 2.x:                    YES (ver 2.24.25)
--     GThread :                    YES (ver 2.42.1)
--     GtkGlExt:                    NO
--     OpenGL support:              NO
--     VTK support:                 NO
-- 
--   Media I/O: 
--     ZLib:                        zlib (ver 1.2.8)
--     JPEG:                        libjpeg (ver 90)
--     WEBP:                        build (ver 0.3.1)
--     PNG:                         build (ver 1.6.24)
--     TIFF:                        build (ver 42 - 4.0.2)
--     JPEG 2000:                   build (ver 1.900.1)
--     OpenEXR:                     build (ver 1.7.1)
--     GDAL:                        NO
--     GDCM:                        NO
-- 
--   Video I/O:
--     DC1394 1.x:                  NO
--     DC1394 2.x:                  YES (ver 2.2.3)
--     FFMPEG:                      NO
--       avcodec:                   YES (ver 56.1.0)
--       avformat:                  YES (ver 56.1.0)
--       avutil:                    YES (ver 54.3.0)
--       swscale:                   YES (ver 3.0.0)
--       avresample:                YES (ver 2.1.0)
--     GStreamer:                   NO
--     OpenNI:                      NO
--     OpenNI PrimeSensor Modules:  NO
--     OpenNI2:                     NO
--     PvAPI:                       NO
--     GigEVisionSDK:               NO
--     Aravis SDK:                  NO
--     UniCap:                      NO
--     UniCap ucil:                 NO
--     V4L/V4L2:                    NO/YES
--     XIMEA:                       NO
--     Xine:                        NO
--     gPhoto2:                     NO
-- 
--   Parallel framework:            pthreads
-- 
--   Other third-party libraries:
--     Use IPP:                     NO
--     Use VA:                      NO
--     Use Intel VA-API/OpenCL:     NO
--     Use Lapack:                  NO
--     Use Eigen:                   NO
--     Use Cuda:                    NO
--     Use OpenCL:                  YES
--     Use OpenVX:                  NO
--     Use custom HAL:              YES (carotene (ver 0.0.1))
-- 
--   OpenCL:                        <Dynamic loading of OpenCL library>
--     Include path:                /home/pi/rpi/src/opencv-3.2.0/3rdparty/include/opencl/1.2
--     Use AMDFFT:                  NO
--     Use AMDBLAS:                 NO
-- 
--   Python 2:
--     Interpreter:                 /usr/bin/python2.7 (ver 2.7.12)
--     Libraries:                   /usr/lib/python2.7 (ver 2.7.9)
--     numpy:                       /home/pi/rpi/rootfs/usr/lib/python2.7/dist-packages/numpy/core/include (ver undefined - cannot be probed because of the cross-compilation)
--     packages path:               /home/pi/rpi/rootfs/usr/local/lib/python2.7/site-packages
-- 
--   Python 3:
--     Interpreter:                 NO
-- 
--   Python (for build):            /usr/bin/python2.7
-- 
--   Java:
--     ant:                         NO
--     JNI:                         NO
--     Java wrappers:               NO
--     Java tests:                  NO
-- 
--   Matlab:                        Matlab not found or implicitly disabled
-- 
--   Documentation:
--     Doxygen:                     NO
-- 
--   Tests and samples:
--     Tests:                       NO
--     Performance tests:           NO
--     C/C++ Examples:              NO
-- 
--   Install path:                  /home/pi/rpi/rootfs/usr
-- 
--   cvconfig.h is in:              /home/pi/rpi/build/opencv
-- -----------------------------------------------------------------
-- 
-- Configuring done
-- Generating done
-- Build files have been written to: /home/pi/rpi/build/opencv
  ```  
  > Note the detection of libraries such as `gtk`, additional modules such as `freetype` and the proper settings for `Python`.
1. When all is fine, `OpenCV` can be build and installed.

  ```
  XCS~$ make -j 4
  XCS~$ make install
  ```
1. Due to crosscompilation, the installation of `OpenCV` produces and invalid .pc file. This needs to be corrected.
  Move file to appropiate location
  
  ```
  XCS~$ mv /home/pi/rpi/rootfs/usr/lib/pkgconfig/opencv.pc /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/pkgconfig/opencv.pc
  ```
  Update prefix-path in the .pc file. It should become `prefix=/usr`
  
  ```
  XCS~$ nano /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/pkgconfig/opencv.pc
  ```
1. To use the Python-bindings on the rpi, `PYTHONPATH` has to be set properly
  
  ```
  XCS~$ ssh rpizero-local
  RPI~$ nano ~/.bashrc
  ```
  
  Add to following lines:
  ```
  #Ensure Python is able to find packages
  export PYTHONPATH=/usr/local/lib/python2.7/site-packages:$PYTHONPATH
  ```
  
  Reload Bash
  ```
  RPI~$ source ~/.bashrc
  ```

# Syncing, Compiling and Testing
After building and compiling source code, the binairies need to be transferred to the rpi. The next sections describe how to sync and how to test the setup.

## Syncing and Transferring
Transferring files from `~/rpi/rootfs` to the rpi is made easy with `rsync`. Additionally `rsync` can be set to ensure that only new files are updated and that the copied files will have the correct properties. Since `~/rpi/rootfs` contains the `bin` folder (and therefore also `sudo`), setting the proper rights is important for a stable system. When user rights are not properly set during syncing, `sudo`-errors on the rpi may occur.

Syncing `~/rpi/rootfs` towards the rpi can be done using:
```
XCS~$ sudo rsync -auHWv --no-perms --no-owner --no-group /home/pi/rpi/rootfs/ rpizero-local-root:/
```
As we are syncing to the root of the rpi, `rpizero-local-root` is invoked instead of `rpizero-local`.

Next to syncing freshly compiled user-binaries should also be send to the rpi. Generally we do not care that much about the user settings, hence `scp` can be used:
```
XCS~$ scp <binairy> rpizero-local:~/ 
```
This will copy the binary `<binairy>` to the user-folder (`~/`) of the `pi`-user.

## Hello Pi!
Testing our the toolchain.
Prerequisites: 
- Toolchain installed

1. Download the code in [hello/pi](hello/pi).
  
  ```
  XCS~$ cd ~/code
  XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth 1
  ```
1. Build the code 

  ```
  XCS~$ mkdir -p ~/build/hello/pi
  XCS~$ cd ~/build/hello/pi
  XCS~$ cmake ~/code/hello/pi
  XCS~$ make
  ```
1. Sync and run.

  ```
  XCS~$ scp hello rpizero-local:~/ 
  XCS~$ ssh rpizero-local
  RPI~$ ./hello 
   Hello World!
  ```

## Hello Camera!
Testing the compiled `userland`-libraries
Prerequisites: 
- Toolchain installed
- Userland installed & synced
- Subversion:

  ```
  XCS~$ sudo apt-get install subversion
  ```


1. There are two options to test the camera: i) you can download all code from the repo, or ii), you can download the code from the original repo.
  1. Using this repo.
    Download the code in [hello/raspicam](hello/raspicam).
  
    ```
    XCS~$ cd ~/code
    XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth 1
    ```
  
  1. Using the original repo.
    
    ```
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
  XCS~$ mkdir -p ~/build/hello/raspicam
  XCS~$ cd ~/build/hello/raspicam
  XCS~$ cmake ~/code/hello/raspicam
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

## Hello OpenCV!
Testing the compiled `OpenCV`-libraries
Prerequisites: 
- Toolchain installed
- Userland installed & synced
- OpenCV installed & synced
- An image on the rpi. (e.g. `testcam.jpg` if [Hello-Camera](#hello-camera) is performed).

1. Download the code in [hello/ocv](hello/ocv).
  
  ```
  XCS~$ cd ~/code
  XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth 1
  ```
1. Build the code 

  ```
  XCS~$ mkdir -p ~/build/hello/ocv
  XCS~$ cd ~/build/hello/ocv
  XCS~$ cmake ~/code/hello/ocv
  XCS~$ make
  ```
1. Sync and run.

  ```
  XCS~$ scp hellocv rpizero-local:~/ 
  XCS~$ ssh -X rpizero-local
  RPI~$ ./hellocv testcam.jpg
  ```
  As a result, a window should be opened displaying the image. 
  > Depending on the size of the image, this may take a while.

