# Crosscompiling : Setup

Before continuing, please make sure you followed the steps in:
- [Setup](1-setup.md)
- [Network/SSH](2-network.md)
- Optional: [Peripherals](3-peripherals.md)

Most of the commands I use in this and the upcoming guides make use of absolute paths. Therefore, take extra care if you use a different environment/VM or different install paths.   

In this document the setup for our local RPi-filesystem (`rootfs`) and tools to compile for the RPi are introduced. Furthermore additional commands for syncing and maintaining a proper setup are shown.

## Required Packages

Both the RPi and VM need several packages to allow us to sync the `rootfs` and do our crosscompilation.

For compilation a compiler is needed which can build, create and link our c-code with libraries and transform it in to arm-instructions. This is done by a toolchain. Toolchains can be created with e.g. `linearo` or `gcc` (see: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/).  In case of the RPi, we simplify life a bit by using the existing toolchain available at [https://github.com/raspberrypi/]( https://github.com/raspberrypi/).

1. Install the following packages for syncing/crosscompilation:
    ```
    XCS~$ sudo apt-get install build-essential pkg-config cmake unzip gzip rsync
    XCS~$ ssh rpizero-local
    RPI~$ sudo apt-get install rsync
    ```
  
1. Install the tools for compilation (this will create a folder `~/rpi/tools` in the VM)
    ```
    XCS~$ mkdir -p ~/rpi
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
   
## Note on base-directory

This guide assumes `/home/pi/` to be the `~/` home dir. If you have a different directory, make sure you update the `/home/pi` to the proper path. Note that setting it to `~/` will not work.

## Setting up `rootfs`

The crosscompiler requires access to (`/usr` and `/lib`) RPi-binairies and libraries to link properly. Therefore we need to create a local copy of the RPi-filesystem in the VM: `rootfs`. 

1. Shutdown RPi, disconnect the power supply and remove SDCard.
    > As the inital setup might take a while, the initial setup copies data from the SDCard. Future synchronisation actions will do the syncing via SSH.
1. Connect and mount SDCard with the VM.
    ```
    XCS~$ lsblk
      ...
    XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt 
    ```
1. Create the `rootfs` location
    ```
    XCS~$ mkdir -p ~/rpi/rootfs
    ```

1. Copy libraries from SDCard and unmount
    ```
    XCS~$ rsync -auHWv /home/pi/rpi/mnt/lib /home/pi/rpi/rootfs/
    XCS~$ rsync -auHWv /home/pi/rpi/mnt/usr /home/pi/rpi/rootfs/
    ```
        
 1. OPTIONAL (requires [SDCard backup/reset](#sdcard-backupreset)): create `rootfs` from backup
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
    
## SDCard backup/reset

Syncing or crosscompilation can mistakingly result in faulty libraries or libraries installed in wrong locations. To save a lot of (re)installation time, these steps show how to backup or reinitiate the SDCard.

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
## Init Repository  

Several crosscompile steps are simplified by the usage of scripts in this repository. 

1. Clone repository 
    ```
    XCS~$ cd ~/
    XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
    ```
    
1. Allow scripts to be executed
    ```
    XCS~$ chmod +x ~/rpicross_notes/scripts/*
    ```

## Synchronisation

Both `rootfs` and the RPi need to be kept in sync when new libraries are compiled, installed or added. The tool used for this task is `rsync`.

### From RPi to VM

As we do not care much about filepermissions, the call is relatively straighforward:
```
XCS~$ rsync -auHWv rpizero-local-root:{/usr,/lib} ~/rpi/rootfs
```

Which copies all data from `/usr` and `/lib` from the RPi to the VM. Care should be taken with symbolic links (symlinks): links including absolute paths will brake becaue the paths of `/usr` and `/lib` become  `/home/pi/rpi/usr` and `/home/pi/rpi/lib` respectively on the VM. Using the commands `file` and `ln` required links can be fixed:
```
XCS~$ file /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so
  /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so: broken symbolic link to /lib/arm-linux-gnueabihf/librt.so.1

XCS~$:  ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/librt.so.1 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so
```

> IMPORTANT: each time `rsync` is used for retrieving libraries from the RPi, the symlinks are updated to the broken links, hence they should be fixed again. It might be usefull to create a simple shell script to fix this such as [`sync-rpi-vm.sh`](scripts/sync-rpi-vm.sh):

1. Sync RPi with VM-`rootfs` (from: [init repository](#init-repository))
    ```
    XCS~$ ~/rpicross_notes/scripts/sync-rpi-vm.sh
    ```

### From VM to RPi

When copying files from the VM to the RPi we do need to take care of file-permissions. Especially since `~/rpi/rootfs` contains the `bin` folder (and therefore also `sudo`). Synchronizing to the RPi with improper settings might result in `sudo`-errors on the RPi and an instable system.

When taking care of permissions, the sync-command becomes:
```
XCS~$ sudo rsync -auHWv --no-perms --no-owner --no-group /home/pi/rpi/rootfs/ rpizero-local-root:/
```

It should be noted that this command also updates the 'corrected' symbolic links. Therefore we need to fix these on the RPi. Using [`sync-vm-rpi.sh`](sync-vm-rpi.sh), this correction is done for us. 
    
1. Sync VM-`rootfs` with RPi` (from: [init repository](#init-repository))
    ```
    XCS~$ ~/rpicross_notes/scripts/sync-vm-rpi.sh
    ```

# Test Setup
Prerequisites: 
 - Toolchain [installed](#required-packages)
 - Repository [initialised](#init-repository)

Steps:

1. Build the code with the [rpi-generic-toolchain](rpi-generic-toolchain.cmake)
    ```
    XCS~$ mkdir -p ~/rpi/build/hello/pi
    XCS~$ cd ~/rpi/build/hello/pi
    XCS~$ cmake \
        -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
        ~/rpicross_notes/hello/pi
    XCS~$ make
    ```
   
    > When omitting the `-D CMAKE_TOOLCHAIN_FILE` option, cmake wil build the `hellopi` with the default compiler, allowing the execution of the binairy in the VM.
    
1. Sync and run.
    ```
    XCS~$ scp hello rpizero-local:~/ 
    XCS~$ ssh rpizero-local
    RPI~$ ./hello 
      Hello World!
    ```

# Test Setup : Trouble shooting

```
Change Dir: /home/pi/rpi/build/hello/pi/CMakeFiles/CMakeTmp

Run Build Command:"/home/pi/rpi/rootfs/usr/bin/make" "cmTC_cbaa5/fast"
/home/pi/rpi/rootfs/usr/bin/make: 1: /home/pi/rpi/rootfs/usr/bin/make: Syntax error: word unexpected (expecting ")"
```
If you encounter such an error, the toolchain invokes the rpi based arm-`make` executable instead of the system-`make` executable. As your computer does not know how to read the arm-based executable, it throws an error. If this happend, you might be able to fix it as noted by [Skammi](https://github.com/HesselM/rpicross_notes/issues/14) :

> I Got in the same issue as some other people that the running the command:
cmake -D CMAKE_TOOLCHAIN_FILE=~/rpicross_notes/rpi-generic-toolchain.cmake ~/rpicross_notes/hello/pi
would evoke the RPI make program. I think that is due to the statements:
set( RPI_ROOTFS /home/pi/rpi/rootfs )
set( CMAKE_FIND_ROOT_PATH ${RPI_ROOTFS} )
in the "rpi-generic-toolchain.cmake" file. I solved this by adding:
set( CMAKE_MAKE_PROGRAM "/usr/bin/make" CACHE FILEPATH "")
in the "rpi-generic-toolchain.cmake" file.



# Next
Having a functional crosscompilation several steps can be taken next:
- Crosscompile & install [Userland libraries](5-xc-userland.md) (for communication with the RPi GPU)
- Crosscompile & install [OpenCV 3.2 with Python Bindings](6-xc-opencv.md) (for computer vision)
- Crosscompile & install [ROS](7-xc-ros.md) (to run the RPi as Node in a ROS-network)
- Develop your own code.. 
