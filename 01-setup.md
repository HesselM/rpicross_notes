# Guide to Cross Compilation for a Raspberry Pi

1. [Start](readme.md)
1. **> [Setup XCS and RPi](01-setup.md)**
1. [Setup RPi Network and SSH](02-network.md)
1. [Setup RPi Peripherals](03-peripherals.md)
1. [Setup Cross-compile environment](04-xc-setup.md)
1. [Cross-compile and Install Userland](05-xc-userland.md)
1. [Cross-compile and Install OpenCV](06-xc-opencv.md)
1. [Cross-compile and Install ROS](07-xc-ros.md)
1. [Compile and Install OpenCV](08-native-opencv.md)
1. [Compile and Install ROS](09-native-ros.md)
1. [Remote ROS (RPi node and XCS master)](10-ros-remote.md)
1. [ROS package development (RPi/XCS)](11-ros-dev.md)
1. [Compile and Install WiringPi](12-wiringpi.md)

# 2. Setup XCS and RPi

This page describes how to setup a [VirtualBox](https://www.virtualbox.org/) to be used for cross-compilation and how to initialise the Raspberry Pi (RPi).
A [VirtualBox](https://www.virtualbox.org/) is used to ensure we can experiment with compilation and installation of the necessary tools without pushing or messing up our main system to an unfixable state.

Both the Raspberry Pi (RPi) and VirtualBox (aka "Cross-Compile Server" or XCS) will be configured to run headless, that is, without graphical interface (GUI).
The XCS will be configured with a shared folder so you can develop your code in any program on your main machine, while able to cross-compile it in a controlled setup.

Throughout this guide the following prefixes for commands are used:
- `HOST~$` commands executed on the Host, our main system.
- `XCS~$` commands executed on the Cross-Compilation Server / VirtualBox.
- `RPI~$` commands executed on the Raspberry Pi

## Table of Contents

1. [VirtualBox: Setup](#virtualbox-setup)
1. [VirtualBox: First Boot](#virtualbox-first-boot)
1. [VirtualBox: SSH from Host](#virtualbox-ssh-from-host)
1. [VirtualBox: Shared folder](#virtualbox-shared-folder)
1. [VirtualBox: DNS Resolving](#virtualbox-dns-resolving)
1. [VirtualBox: Headless Boot](#virtualbox-headless-boot)
1. [VirtualBox: XC Folders](#virtualbox-xc-folders)
1. [Raspberry Pi: Setup](#raspberry-pi-setup)
1. [Next](#next)

## VirtualBox: Setup

1. Download and install [VirtualBox](https://www.virtualbox.org/)
1. Download [Ubuntu 20.04 or 18.04Server LTS](https://www.ubuntu.com/download/server)
    >> When running ROS2 20.04 is required.
3. Create a new VirtualBox Image:
    - Name: XCS-rpi
    - Type: Linux
    - Version: Ubuntu (64-bit)
    - Memory: 4096 MB
    - Create a virtual hard disk now
        - Size: 25,00 GB
        - Type: VMDK
        - Storage: Dynamically allocated
    - Settings:
        - System > Processor > CPU:	2
        > Exact value depends on your system capabilities. My Host contains 8 CPU's, hence 2 can be used for the XCS

        - Network > Advanced > Port Forwarding > New Rule
        > This rule will be used to connect to the XCS via SSH from the Host

            - Name: SSH
            - Protocol: TCP
            - Host IP: (leave empty)
            - Host Port: 2222
            - Guest IP: (leave empty)
            - Guest Port: 22

        - Storage > Controller IDE > Empty > IDE Secondary Master > Choose Virtual Optical Disk File > ubuntu-XXX-server-amd64.iso
    - Select: Ports > USB > USB3 controller
    > My Host does not support the USB2 controller.

## VirtualBox: First Boot

1. Start VirtualBox / XCS, installing Ubuntu:
    - Hostname: XCS-rpi
    - User: pi
    - Password: raspberry

    > The same username and password as in a default Raspbian setup are used to simplify this guide.

    > You can pretty much leave all options to the default setting.

1. After installation, update XCS (if omitted during installation)

    ```
    XCS~$ sudo apt-get update
    XCS~$ sudo apt-get dist-upgrade
    ```

## VirtualBox: SSH from Host

1. Install SSH-server (if omitted during installation)

    ```
    XCS~$ sudo apt-get install openssh-server
    ```

1. After reboot of the XCS, you should be able to connect to it from the Host via SSH on port 2222 :

    ```
    HOST~$ ssh -p 2222 pi@localhost
    ```

    or, when using X-server:

    ```
    HOST~$ ssh -X -p 2222 pi@localhost
    ```

    > For use of X-server ensure that `X11Forwarding yes` in `/etc/ssh/sshd_config` in the XCS is configured and that `ForwardX11 yes` is set in `~/.ssh/config` on the Host. When changed, restart ssh: `sudo service ssh restart`.


1. To eliminate the need for entering your password each time you open a shell to connect to XCS, we can automate the login process with the use of ssh-keys. On your Host, generate the ssh-keys:

    ```
    HOST~$ cd ~/.ssh
    HOST~$ ssh-keygen -t rsa
      Generating public/private rsa key pair.
      Enter file in which to save the key (/home/XXX/.ssh/id_rsa): xcs_rpi_rsa
      Enter passphrase (empty for no passphrase): <empty>
      Enter same passphrase again: <empty>
      Your identification has been saved in xcs_rpi_rsa.
      Your public key has been saved in xcs_rpi_rsa.pub.
      ...
    ```

    > Optionally you can choose a different rsa-name (required if you are planning to use multiple keys for different systems) and set a passphrase (increasing security). In my setup I left the passphrase empty (just hitting enter).

1. Set correct permissions of the key-set

    ```
    HOST~$ chmod 700 xcs_rpi_rsa xcs_rpi_rsa.pub
    ```

1. Send a copy of the public key to the XCS so the XCS can verify the automated connection upon request.

    ```
    HOST~$ cat ~/.ssh/xcs_rpi_rsa.pub | ssh -p 2222 pi@localhost "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
    ```

1. Setup ssh connection in `ssh_config` so we can login by only using a reference (e.g `xcs-rpi`)

    ```
    HOST~$ sudo nano ~/.ssh/config
    ```

    Add the following lines:

    ```
    # connect to XCS-rpi via hostname
    Host xcs-rpi
      HostName localhost
      IdentityFile ~/.ssh/xcs_rpi_rsa
      User pi
      Port 2222
    ```
    > For Windows users the location should be `C:\Users\username\.ssh` or `%USERPROFILE%\.ssh`

1. Test connection:

    ```
    HOST~$ ssh xcs-rpi
    ```

    You should now be logged in onto the XCS via SSH, without entering your password. Type `exit` to terminate connection.

## VirtualBox: Shared folder

1. Open VirtualBox and start `XCS-rpi`
1. Insert Guest additions: Devices > Insert Guest Additions CD image...
1. Install required packages

    ```
    XCS~$ sudo apt-get install make gcc linux-headers-$(uname -r)
    ```

1. Install the additions

    ```
    XCS~$ sudo mkdir -p /media/cdrom
    XCS~$ sudo mount /dev/cdrom /media/cdrom
    XCS~$ sudo /media/cdrom/VBoxLinuxAdditions.run
    XCS~$ sudo adduser pi vboxsf
    ```

1. Add shared Folder: Machine > Settings > Shared Folders > Add
    - Select Folder Path on your Host machine
    - Name: `<FolderName>`
    - Automount
    - Make permanent

    > You can use any name, but note that you need to remember it to setup a symbolic link later on.

1. Reboot XCS to mount shared folder

    ```
    XCS~$ sudo reboot now
    ```

1. Create link to home-folder so we can access our (user-)code easily.

    ```
    XCS~$ ln -s /media/sf_<FolderName> /home/pi/<FolderName>
    ```

## VirtualBox: DNS Resolving

1. To allow the XCS to resolve (local) addresses (so we can connect later on to the RPi by using its hostname), we need to set the XCS to use the Host's DNS server.
    > the XCS should be turned off before you can execute this command successfully.

    ```
    HOST~$ VBoxManage modifyvm "XCS-rpi" --natdnshostresolver1 on
    ```  

1. After applying the DNS fix, bootup the XCS.
1. In Ubuntu versions > 16.04 we need to set the name-server address manually to the VirtualBox DNS ip (`10.0.2.3`) to ensure the DNS will be picked up properly.

    ```
    XCS~$ sudo apt-get install resolvconf
    XCS~$ sudo nano /etc/resolvconf/resolv.conf.d/head
    ```

    Update the name-server:

    ```
    # Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)
    #     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
    # 127.0.0.53 is the systemd-resolved stub resolver.
    # run "systemd-resolve --status" to see details about the actual nameservers.
    nameserver 10.0.2.3    
    ```

## VirtualBox: Headless Boot

1. Now that we have SSH-access to the XCS, booting and powering down from the Host-shell would allow us to skip almost all (mouse)handling of VirtualBox (and the activation of extra windows). To do so, we add some aliases to `.bashrc` on the Host:

    ```
    HOST~: sudo nano ~/.bashrc
    ```

    Add the following lines:
    ```
    # XCS-Management
    alias xcs-rpi-start='VBoxManage startvm XCS-rpi --type headless'
    alias xcs-rpi-stop='VBoxManage controlvm XCS-rpi poweroff'
    ```

1. As `.bashrc` is only activated when opening a new shell, so we need to do a reload:

    ```
    HOST~: source ~/.bashrc
    ```

1. You can now start the XCS with `xcs-rpi-start`:

    ```
    HOST~: xcs-rpi-start
    Waiting for VM "XCS-rpi" to power on...
    VM "XCS-rpi" has been successfully started.
    ```

1. And stop with `xcs-rpi-stop`:

    ```
    HOST~: xcs-rpi-stop
    0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    ```

## VirtualBox: XC folders

In our setup several folders will be used for different purposes. To keep the setup as generic as possible, these folder-references will be set in environment-variables so you can customise them to your need.

1. Boot the XCS and login.
1. Edit `.bashrc` on the XCS:

    ```
    XCS~: sudo nano ~/.bashrc
    ```

    Add the following lines:

    ```
    # Base directory of the rpi-setup. It contains all cross-compile dependencies,
    #  toolchains, examples, scripts, source&build directories, git-repos, etc
    export XC_RPI_BASE=$HOME/rpi
    # ROOTFS of the RPi on the XCS.
    export XC_RPI_ROOTFS=$XC_RPI_BASE/rootfs
    # Folder at which we mount de SDCard.
    export XC_RPI_MNT=$XC_RPI_BASE/mnt
    # Contains img-files for backup and the downloaded raspbian.
    export XC_RPI_IMG=$XC_RPI_BASE/img
    # Where we download the source-code of libraries which we want to build.
    export XC_RPI_SRC=$XC_RPI_BASE/src
    # Here we build our own code.
    export XC_RPI_BUILD=$XC_RPI_BASE/build
    ```

    > You can change the directories as you wish, however, using the home-dir shortcut (`~/`) will not not work. So make sure that you either use full, absolute paths, or the `$HOME` reference.

1. As `.bashrc` is only activated when opening a new shell, so we need to do a reload:

    ```
    XCS~: source ~/.bashrc
    ```

1. Lets create al folders:

    ```
    XCS~: mkdir -p $XC_RPI_ROOTFS $XC_RPI_MNT $XC_RPI_IMG $XC_RPI_SRC $XC_RPI_BUILD $XC_RPI_GUIDE
    ```

## Raspberry Pi: Setup

Source: https://www.raspberrypi.org/documentation/installation/installing-images/linux.md

1. Download and Unzip the latest Raspbian Lite

    ```    
    XCS~$ cd $XC_RPI_IMG
    XCS~$ wget wget https://downloads.raspberrypi.org/raspios_lite_armhf_latest
    XCS~$ sudo apt-get install unzip
    XCS~$ unzip raspios_lite_armhf_latest
    ```
    > This download is the Lite version of raspbian and hence does not include a GUI or commonly used application. If a GUI is required, you can add it later via `apt-get` or download a different raspios version.

1. Connect SDCard to the XCS.
    For this you have two options: 
    1. Open VirtualBox (in case you are connected to a headless system via SSH) and attach the USB via de user interface
    1. Use `VBoxManage`:
        1. List connectable usb-devices on the host. 
        1. Attach usb (using the UUID) to the XCS
    ```
    HOST~$ VBoxManage list usbhost
    ...
    UUID:               6f73773c-5558-4e06-8de5-d7fdb74b43bf
    VendorId:           0x058f (058F)
    ProductId:          0x8468 (8468)
    Revision:           1.0 (0100)
    Port:               4
    USB version/speed:  0/Super
    Manufacturer:       Generic
    Product:            Mass Storage Device
    SerialNumber:       058F84688461
    Address:            p=0x8468;v=0x058f;s=0x0004a7b1859bfb7b;l=0x01240000
    Current State:      Available
    ...
    
    HOST~$ VBoxManage controlvm XCS-rpi usbattach 6f73773c-5558-4e06-8de5-d7fdb74b43bf
    ```

1. Detect SDCard

    ```
    XCS~$ lsblk
      NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
      sda                           8:0    0   25G  0 disk
      ├─sda1                        8:1    0  487M  0 part /boot
      ├─sda2                        8:2    0    1K  0 part
      └─sda5                        8:5    0 24.5G  0 part
        ├─XCS--rpi--vg-root   252:0    0 20.5G  0 lvm  /
        └─XCS--rpi--vg-swap_1 252:1    0    4G  0 lvm  [SWAP]
      sdb                           8:16   1  7.3G  0 disk       <=== Our SDCard!
      ├─sdb1                        8:17   1   63M  0 part
      └─sdb2                        8:18   1  7.3G  0 part
      sr0                          11:0    1 55.7M  0 rom  
    ```

1. Install Raspbian (this might take a while..)

    ```
    XCS~$ sudo dd bs=4M if=$XC_RPI_IMG/2021-10-30-raspios-bullseye-armhf-lite.img of=/dev/sdb

    [sudo] password for pi:
    441+0 records in
    441+0 records out
    1849688064 bytes (1.8 GB, 1.7 GiB) copied, 71.1205 s, 26.0 MB/s
    ```

1. OPTIONAL: Validate that the image is properly copied

    ```
    XCS~$ sudo dd bs=4M if=/dev/sdb of=from-sd-card.img
    XCS~$ sudo truncate --reference 2021-10-30-raspios-bullseye-armhf-lite.img from-sd-card.img
    XCS~$ sudo diff -s from-sd-card.img 2021-10-30-raspios-bullseye-armhf-lite.img
    Files from-sd-card.img and 2021-10-30-raspios-bullseye-armhf-lite.imgg are identical
    ```

1. Remove images, we do not need these anymore

    ```
    XCS~$ sudo rm *.img
    ```

## Next

Having installed the basic components, lets configure the [network/ssh settings of our RPi!](02-network.md)
