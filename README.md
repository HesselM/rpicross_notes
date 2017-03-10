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

# Connection

## Network settings

## SSH

# Raspberry Pi Peripherals

## Real-time Clock
### Enable i2c
### Enable RTC

## Camera


# Crosscompilation

## Setup

## Userland

## OpenCV

# Testing
## Hello Pi!
## Hello Camera!
## Hello OpenCV!



