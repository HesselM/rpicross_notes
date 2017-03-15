# Crosscompilation:Setup

At this moment you should have a raspberry pi with functioning camera, rtc and ssh-configuration. The next steps will setup the tools required for crosscompilation.

## RPI: Required packages/dependencies
Several additional packages need to be installed in order to sync or crosscompile `OpenCV` and `ROS`.

- For building/syncing:

  ```
  XCS~$ sudo apt-get install build-essential pkg-config cmake unzip rsync
  XCS~$ ssh rpizero-local
  RPI~$ sudo apt-get install rsync gzip
  ```

- For `OpenCV`
  ```
  XCS~$ ssh rpizero-local
  RPI~$ sudo apt-get install pkg-config python2.7 python-dev python-numpy libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev 
  ```

- For `ROS`
  ```
  XCS~$ sudo apt-get install python-rosdep python-rosinstall-generator python-wstool python-rosinstall python-empy
  XCS~$ ssh rpizero-local
  RPI~$ sudo apt-get install pkg-config python2.7 python-dev sbcl libboost1.55 python-empy python-nose libtinyxml-dev libgtest-dev liblz4-dev libbz2-dev
  ```

- To install all (syncing/`OpenCV`/`ROS`) required packages:
  ```
  XCS~$ sudo apt-get install build-essential pkg-config cmake unzip rsync python-rosdep python-rosinstall-generator python-wstool python-rosinstall python-empy
  XCS~$ ssh rpizero-local
  RPI~$ sudo apt-get install rsync gzip pkg-config python2.7 python-dev python-numpy libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev sbcl libboost1.55 python-empy python-nose libtinyxml-dev libgtest-dev liblz4-dev libbz2-dev
  ```

## SDCard Backup/reset
As syncing or crosscompilation can go wrong, resulting in faulty libraries or libraries installed in wrong locations, having a backup to reinitiate the SDCard might be a good idea.

1. Shutdown RPI
  
  ```
  RPI~$ sudo shutdown now
  ```
1. Disconnect RPI from power, remove SDCard and connect with VM
1. Detect SDCard

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
  ```
1. Create a (compressed) backup

  ```
  XCS~$ sudo dd bs=4M if=/dev/sdb | gzip > /home/pi/rpi/img/rpi_backup.img.gz
  ```
1. To restore a backup, use:
  ```
  XCS~$ gzip -dc /home/pi/rpi/img/rpi_backup.img.gz | sudo dd bs=4M of=/dev/sdb
  ```

## XCS: Setting up `rootfs`

The crosscompile toolchain requires access to rpi-binairies and libraries which are invoked by the to-be-compiled code. Therefore a root-filesystem (`rootfs`) of the rpi is created in the VM.

- Create `rootfs`

  ```
  XCS~$ mkdir -p ~/rpi/rootfs
  ```
- Copy libraries from SDCard

  ```
  XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt 
  XCS~$ rsync -auHWv /home/pi/rpi/mnt/lib /home/pi/rpi/rootfs/
  XCS~$ rsync -auHWv /home/pi/rpi/mnt/usr /home/pi/rpi/rootfs/
  XCS~$ sudo umount /home/pi/rpi/mnt 
  ```
- Alternatively, the libraries can also be copied via ssh.

  ```
  XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt 
  XCS~$ rsync -auHWv rpizero-local-root:/lib /home/pi/rpi/rootfs/
  XCS~$ rsync -auHWv rpizero-local-root:/lib /home/pi/rpi/rootfs/
  XCS~$ sudo umount /home/pi/rpi/mnt 
  ```

- Or from the backup

  ```
  XCS~$ gzip -dc /home/pi/rpi/img/rpi_backup.img.gz > /home/pi/rpi/img/rpi_backup.img
  XCS~$ fdisk -l /home/pi/rpi/img/rpi_backup.img
    Disk /home/pi/rpi/img/rpi_backup.img: 7.3 GiB, 7861174272 bytes, 15353856 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0xa11202a8 
 
    Device                              Boot  Start      End  Sectors  Size Id Type
    /home/pi/rpi/img/rpi_backup.img1           8192   137215   129024   63M  c W95 FAT32 (LBA)
    /home/pi/rpi/img/rpi_backup.img2         137216 15353855 15216640  7.3G 83 Linux
  ```
  > - determine `start` of the filesystem parition, e.g: 137216
  > - determine `unit size`, e.g. 512
  > - multiply these values: 137216 * 512 = 70254592
  > - mount and copy
    
  ```
  XCS~$ sudo mount -o loop,offset=70254592 /home/pi/rpi/img/rpi_backup.img /home/pi/rpi/mnt
  XCS~$ rsync -auHWv /home/pi/rpi/mnt/lib /home/pi/rpi/rootfs/
  XCS~$ rsync -auHWv /home/pi/rpi/mnt/usr /home/pi/rpi/rootfs/
  XCS~$ sudo umount /home/pi/rpi/mnt 
  ```

## Toolchain
In order to compile code for the rpi, a compiler is needed which can build, create and link our c-code with libraries and transform it in to arm-instructions. This is done by a toolchain. Toolchains can be created with e.g. `linearo` or `gcc` (see: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/).  In case of the rpi, we simplify life a bit by using the existing toolchain available at [https://github.com/raspberrypi/]( https://github.com/raspberrypi/).

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
  XCS~$ sudo ln -s /home/pi/rpi/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-ranlib /usr/bin/rpizero-ranlib
  ```
1. Clean up unneeded branches in the tools-directory to save space.

  ```
  XCS~$ rm -rf /home/pi/rpi/tools/arm-bcm2708/arm-bcm2708*
  ```

## Testing the setup
Prerequisites: 
 - Toolchain installed

Steps:
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
