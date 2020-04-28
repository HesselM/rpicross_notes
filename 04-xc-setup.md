# Guide to Cross Compilation for a Raspberry Pi

1. [Start](readme.md)
1. [Setup XCS and RPi](01-setup.md)
1. [Setup RPi Network and SSH](02-network.md)
1. [Setup RPi Peripherals](03-peripherals.md)
1. **> [Setup Cross-compile environment](04-xc-setup.md)**
1. [Cross-compile and Install Userland](05-xc-userland.md)
1. [Cross-compile and Install OpenCV](06-xc-opencv.md)
1. [Cross-compile and Install ROS](07-xc-ros.md)
1. [Compile and Install OpenCV](08-native-opencv.md)
1. [Compile and Install ROS](09-native-ros.md)
1. [Remote ROS (RPi node and XCS master)](10-ros-remote.md)
1. [ROS package development (RPi/XCS)](11-ros-dev.md)
1. [Compile and Install WiringPi](12-wiringpi.md)

# 5. Setup Cross-compile environment

You are now at a point to create the foundation of the cross-compilation environment. In the next steps a "rootfs" will be created in XCS, mimicking the RPi filesystem. This "rootfs" contains all necessary headers and libraries to compile new ARM (system) binaries or applications for the RPi. Using a cross-compiler and toolchain these new binaries or applications can be created, after which these can be synchronised with the RPi.

An important note has to be made: most of the commands and scripts used for compilation and synchronisation makes use of absolute system-paths. As such, if you decided previously in this guide to deviate with system or user names, extra care needs to be taken to verify that your paths are still ok.

## Table of Contents

1. [Prerequisites](#prerequisites)
1. [Preparation](#preparation)
1. [SDCard backup](#sdcard-backup)
1. [Setup rootfs](#setup-rootfs)
1. [Synchronisation of rootfs](#synchronisation-of-rootfs)
1. [Testing](#testing)
1. [Next](#next)

## Prerequisites
- Setup of XCS and RPi
- Setup of RPi Network and SSH

## Preparation

1. First we need to install some system packages on both the XCS and RPi to ensure our build tools and synchronisation scripts will function.

    ```
    XCS~$ sudo apt-get install build-essential pkg-config cmake unzip gzip rsync python2.7 python3
    XCS~$ ssh rpizero-local
    RPI~$ sudo apt-get install rsync
    ```

1. Now we can install the cross-compiler.

    ```
    XCS~$ cd $XC_RPI_BASE
    XCS~$ git clone https://github.com/raspberrypi/tools.git --depth 1
    ```

    > This will create a folder "tools" at "$XC_RPI_BASE/tools" in which the cross-compiler is installed.

    > For compilation of source code a compiler is needed which can build, create and link the sources with libraries and transform it into arm-instructions. This is done via a toolchain, consisting of a cross-compiler, libraries and several other settings. Toolchains can be created with e.g [`linearo` or `gcc`](http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/).  In case of the RPi, life is simplified by using the existing toolchain developed by the RPi Foundation available at [https://github.com/raspberrypi/]( https://github.com/raspberrypi/).

1. Create links to the proper gcc-binaries.

    ```
    XCS~$ sudo ln -s $XC_RPI_BASE/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc /usr/bin/arm-linux-gnueabihf-gcc
    XCS~$ sudo ln -s $XC_RPI_BASE/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-g++ /usr/bin/arm-linux-gnueabihf-g++
    XCS~$ sudo ln -s $XC_RPI_BASE/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-ar /usr/bin/arm-linux-gnueabihf-ar
    XCS~$ sudo ln -s $XC_RPI_BASE/tools/arm-bcm2708/arm-rpi-4.9.3-linux-gnueabihf/bin/arm-linux-gnueabihf-ranlib /usr/bin/arm-linux-gnueabihf-ranlib
    ```

1. To save space, unneeded folders from the tools-directory can be deleted.

    ```
    XCS~$ rm -rf $XC_RPI_BASE/tools/arm-bcm2708/arm-bcm2708*
    ```

1. Install the repo of this guide. It contains several scripts and examples to ease the cross-compilation steps.

    ```
    XCS~$ cd $XC_RPI_BASE
    XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
    ```

    > This will create a folder "rpicross_notes" at "$XC_RPI_BASE/rpicross_notes" in which tools, scripts and samples for this cross-compile setup can be found.

1. Allow scripts to be executed

    ```
    XCS~$ chmod +x $XC_RPI_BASE/rpicross_notes/scripts/*
    ```

## SDCard backup

Errors and mistakes may occur and happen during syncing, cross-compilation or installation, resulting in faulty libraries or libraries installed in wrong locations. To save (re)installation time, these steps show how to backup or reinitiate the SDCard.

1. Shutdown the RPi and connect SDCard to the XCS

    ```
    RPI~$ sudo shutdown now
    ...
    XCS~$ lsblk
      NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
      sda                           8:0    0   25G  0 disk
      ├─sda1                        8:1    0  487M  0 part /boot
      ├─sda2                        8:2    0    1K  0 part
      └─sda5                        8:5    0 24.5G  0 part
        ├─XCS--rpizero--vg-root   252:0    0 20.5G  0 lvm  /
        └─XCS--rpizero--vg-swap_1 252:1    0    4G  0 lvm  [SWAP]
      sdb                           8:16   1  7.3G  0 disk       <=== Our RPi SDCard!
      ├─sdb1                        8:17   1   63M  0 part
      └─sdb2                        8:18   1  7.3G  0 part
      sr0                          11:0    1 55.7M  0 rom  
    ```

1. Create a (compressed) backup

    ```
    XCS~$ sudo dd bs=4M if=/dev/sdb | gzip > $XC_RPI_IMG/rpi_backup.img.gz
    ```

    > Depending on de SDCard size, this might take several minutes.

1. To restore a backup, use:

    ```
    XCS~$ gzip -dc $XC_RPI_IMG/rpi_backup.img.gz | sudo dd bs=4M of=/dev/sdb
    ```

    > Depending on de SDCard size, this might take several minutes.

## Setup rootfs

The cross-compiler requires access to (`/usr` and `/lib`) RPi-binaries, headers and libraries to link properly. Therefore we need to create a local copy of the RPi-filesystem in the XCS: "rootfs".

For the initial setup of "rootfs" it is advised to connect the SDCard with the XCS, as this will synchronise in less time when compared to synchronisation over SSH. Future syncs will be done via scripts utilising the SSH setup.

1. Connect and mount the largest partition of the SDCard.

    ```
    XCS~$ lsblk
      ...
    XCS~$ sudo mount /dev/sdb2 $XC_RPI_MNT
    ```

1. Copy libraries from SDCard

    ```
    XCS~$ rsync -auHWv $XC_RPI_MNT/lib $XC_RPI_ROOTFS/
    XCS~$ rsync -auHWv $XC_RPI_MNT/usr $XC_RPI_ROOTFS/
    ```

 1. OPTIONAL (requires [SDCard backup](#sdcard-backup)): create "rootfs" from backup:

    ```
    XCS~$ gzip -dc $XC_RPI_IMG/rpi_backup.img.gz > $XC_RPI_IMG/rpi_backup.img
    XCS~$ fdisk -l $XC_RPI_IMG/rpi_backup.img
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

     - determine `start` of the filesystem parition, e.g: 137216
     - determine `unit size`, e.g. 512
     - multiply these values: 137216 * 512 = 70254592
     - mount and copy

    ```
    XCS~$ sudo mount -o loop,offset=70254592 $XC_RPI_IMG/rpi_backup.img $XC_RPI_MNT
    XCS~$ rsync -auHWv $XC_RPI_MNT/lib $XC_RPI_ROOTFS/
    XCS~$ rsync -auHWv $XC_RPI_MNT/usr $XC_RPI_ROOTFS/
    XCS~$ sudo umount $XC_RPI_MNT
    ```

## Synchronisation of rootfs

Both "rootfs" and the RPi need to be kept in sync when new libraries are compiled, installed or added. Synchronisation is done with [rsync](https://linux.die.net/man/1/rsync), but an additional step is required to fix broken symbolic links. To ease the full sync-process, dedicated scripts have been developed:

1. Sync RPi with "rootfs"

    ```
    XCS~$ $XC_RPI_BASE/rpicross_notes/scripts/sync-rpi-xcs.sh rpizero-local-root
    ```

    > "rpizero-local-root" can be replaced with the root(!!) hostname or ip-address of your RPi system.

1. Sync "rootfs" with RPi

    ```
    XCS~$ $XC_RPI_BASE/rpicross_notes/scripts/sync-xcs-rpi.sh rpizero-local-root
    ```

    > "rpizero-local-root" can be replaced with the root(!!) hostname or ip-address of your RPi system.

> BACKGROUND INFORMATION ON SYNCHRONISATION
>
> For synchronising files between the RPi and XCS, `rsync` is used. This is an advanced synchronisation tool supporting control over settings and restrictions for file-permissions, ownership of files, symbolic link copying and much more.
>
> To sync from the RPi to the XCS, we do not care about file-permissions as we are moving from a (potentially restricted) RPi to a less restricted "rootfs" in the XCS. We also do not care about broken symbolic links (as we will correct those later), so synchronisation can be done with:

```
XCS~$ rsync -auHWv rpizero-local-root:{/usr,/lib} $XC_RPI_ROOTFS
```

> This copies all data from `/usr` and `/lib` from the RPi to the XCS.
>
> As symbolic links are copied without correction, links with absolute paths will brake because the paths of `/usr` and `/lib` on the RPi become `$XC_RPI_ROOTFS/usr` and `$XC_RPI_ROOTFS/lib` respectively on the XCS. Using the command `file` we can detect these files and fix the links with `ln`:

```
XCS~$ file $XC_RPI_ROOTFS/usr/lib/arm-linux-gnueabihf/librt.so
  /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so: broken symbolic link to /lib/arm-linux-gnueabihf/librt.so.1

XCS~$ ln -sf $XC_RPI_ROOTFS/lib/arm-linux-gnueabihf/librt.so.1 $XC_RPI_ROOTFS/usr/lib/arm-linux-gnueabihf/librt.so
```

> The synchronisation-script "sync-rpi-xcs.sh" contains a process which does this automatically for the symbolic links in "usr/lib/arm-linux-gnueabihf" (as these are for now the only links which require patching to allow us to cross compile).
>
> When we sync files from the XCS to the RPi we DO need to take care of file-permissions. Especially since `$XC_RPI_ROOTFS` contains the `/usr/bin` folder (and therefore also `sudo`). Synchronising to the RPi with improper file-permissions might result in `sudo`-errors on the RPi and an unstable system.
>
> To take into account file-permissions, syncing from "rootfs" to the RPi is done with:

```
XCS~$ sudo rsync -auHWv --no-perms --no-owner --no-group $XC_RPI_ROOTFS/ rpizero-local-root:/
```
>
> It should be noted that the "corrected" symbolic links will brake again: the prefix `$XC_RPI_ROOTFS/usr` should be corrected to `/usr`. The script "sync-xcs-rpi.sh" takes care of this.

## Testing

Having setup the basic structure for cross-compilation, it's time to build the hello-world example!

1. First we create a specific build-directory in which al build-files will be put. This is part of proper development and eases the search of fixing errors or clearing a build.

    ```
    XCS~$ mkdir -p $XC_RPI_BUILD/hello/pi
    XCS~$ cd $XC_RPI_BUILD/hello/pi
    ```

1. Compilation is done with [CMake](https://cmake.org), a tool which eases the process of grouping, linking and building our binary. To compile for the RPi, we invoke a specific toolchain-file, which contains settings on where to find "rootfs", which compiler to use and for what target platform (ARM) we want to build.

    ```
    XCS~$ cmake \
        -D CMAKE_TOOLCHAIN_FILE=$XC_RPI_BASE/rpicross_notes/rpi-generic-toolchain.cmake \
        $XC_RPI_BASE/rpicross_notes/hello/pi
    ```

    > When omitting the `-D CMAKE_TOOLCHAIN_FILE` option, cmake wil build the `hellopi` with the default compiler, allowing the execution of the binary in the XCS.

1. When CMake completed successfully, we can build the program.

    ```
    XCS~$ make
    ```

1. Now we only need to sync and run the program.

    ```
    XCS~$ scp hello rpizero-local:~/
    XCS~$ ssh rpizero-local
    RPI~$ ./hello
      Hello World!
    ```

## Next

Having a functional cross-compilation environment, several steps can be taken next:
- Cross-compile & install the [Userland libraries](05-xc-userland.md) (for communication with the RPi GPU)
- Cross-compile & install [OpenCV with Python Bindings](06-xc-opencv.md) (for computer vision)
- Cross-compile & install [ROS](07-xc-ros.md) (to run the RPi as Node in a ROS-network)
- Or develop your own code..
