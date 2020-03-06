# Setup

In order to be able to experiment with compilation and installation of the necessary tools without messing op the main system, all tools will be installed in a clean and headless [VirtualBox](https://www.virtualbox.org/) environment. 

Communication, installation and synchronisation of all required dependencies and libraries will be done via commandline. 

As I prefer the development enviroment of my HOST-system, developed code will be accessible by the toolchain in the virtual machine (VM) via a shared folder construction.

## Virtualbox / VM / XCS

### Installation
1. Download VirtualBox
1. Download Ubuntu 18.04 (or 16.04) Server LTS [https://www.ubuntu.com/download/server]
1. Create new VirtualBox Image:
    - Name: XCS-rpizero
    - Type: Linux
    - Version: Ubuntu (64-bit)
    - Memory: 4096 MB
    - Create a virtual hard disk now
        - Size: 25,00 GB
        - Type: VMDK
        - Storage: Dynamically allocated	
    - Settings:
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
      
    > My Host does not support the USB2 controller.
    
### First Boot
1. Start VirtualBox/VM, installing Ubuntu:
    - Hostname: XCS-server
    - User: pi
    - Password: raspberry
    > You can pretty much leave all options to the default setting. 

1. After installation, update VM (if omitted during installation)

    ```
    XCS~$ sudo apt-get update
    XCS~$ sudo apt-get dist-upgrade
    ```
1. Install SSH-server (if omitted during installation)

    ```
    XCS~$ sudo apt-get install openssh-server
    ```
1. After reboot of the VM, you should be able to connect to the VM via port 2222:

    > Connecting a local shell via SSH eases copy-paste operations from/to the VM!

    ```
    HOST~$ ssh -p 2222 pi@localhost
    ```
    
    or, when using X-server:
  
    ```
    HOST~$ ssh -X -p 2222 pi@localhost
    ```
  
    > For use of X-server ensure that `X11Forwarding yes` in `/etc/ssh/sshd_config` in the VM and `ForwardX11 yes` in `~/.ssh/config` on the Host. When changed, restart ssh: `sudo service ssh restart`.
     
### SSH keys

Currently, you need to type your password each time you connect with the VM from the Host via SSH. With the use of ssh-keys, we can automate this process.

1. Generate ssh-keys on the Host (assuming linux or OSX). 

    ```
    HOST~$ cd ~/.ssh
    HOST~$ ssh-keygen -t rsa
      Generating public/private rsa key pair.
      Enter file in which to save the key (/home/XXX/.ssh/id_rsa): xcs_server_rsa
      Enter passphrase (empty for no passphrase): <empty>
      Enter same passphrase again: <empty>
      Your identification has been saved in xcs_server_rsa.
      Your public key has been saved in xcs_server_rsa.pub.
      ...
    ```
    > Optionally you can choose a different rsa-name (required if you are planning to use multiple keys for different systems) and set a passphrase (increasing security). In my setup I left the passphrase empty (just hitting enter). 

1. Set correct permisions of the key-set

    ```
    XCS~$ chmod 700 xcs_server_rsa xcs_server_rsa.pub
    ```
   
1. Send a copy of the public key to the RPi so it can verify the connection  
    ```
    cat ~/.ssh/xcs_server_rsa.pub | ssh -p 2222 pi@localhost "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
    ```

1. Configure ssh connection in `ssh_config`

    ```
    HOST~$ sudo nano ~/.ssh/config
    ```
  
    Add the following lines:
    ```
    # connect via hostname
    Host xcs-server
      HostName localhost
      IdentityFile ~/.ssh/xcs_server_rsa
      User pi
      Port 2222
    ```

1. Test connection:
    ```
    HOST~$ ssh xcs-server
    ```
    
    You should now be logged in onto the VM via SSH, without entering your password. Type `exit` to terminate connection.
  
### VM booting from shell

1. Now we have SSH-access to the VM, booting and powering down from the Host-shell would allow us to skip all (mouse)handling of Virtual Box (and the activation of extra windows). To do so, add the following alias to your `.bashrc`:

    ```
    HOST~: sudo nano ~/.bashrc
    ```

    ```
    # VM-Management
    alias xcs-server-start='VBoxManage startvm XCS-server --type headless'
    alias xcs-server-stop='VBoxManage controlvm XCS-server poweroff'
    ```

1. As `.bashrc` is only activated by opening a new shell, we need to do a reload:

    ```
    HOST~: source ~/.bashrc
    ```
    
1. You can now start the VM with `xcs-server-start`:
 
    ```
    HOST~: xcs-server-start
    Waiting for VM "XCS-server" to power on...
    VM "XCS-server" has been successfully started.
    ```
    
1. And stop with `xcs-server-stop`:

    ```
    HOST~: xcs-server-stop
    0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
    ```

### DNS resolving
  
1. To allow the VM to resolve (local) DNS-addresses: set it use the host DNS server. 
    > VM should be turned off before you can execute this command succesfully.

    ```
    HOST~$ VBoxManage modifyvm "XCS-rpizero" --natdnshostresolver1 on
    ```  

### Shared Folder
1. Select/start `XCS-rpizero` in VirtualBox
1. Insert Guest additions: Devices > Insert Guest Additions CD image...
1. When using a Linux-based system: install necessary package

    ```
    XCS~$ sudo apt-get install make gcc linux-headers-$(uname -r)
    ```
1. Install the additions in the VM

    ```
    XCS~$ sudo mkdir -P /media/cdrom
    XCS~$ sudo mount /dev/cdrom /media/cdrom
    XCS~$ sudo /media/cdrom/VBoxLinuxAdditions.run
    XCS~$ sudo adduser pi vboxsf
    ```
1. Add shared Folder: Machine > Settings > Shared Folders > Add
    - Select Folder Path
    - Name: code
    - Automount
    - Make permanent

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

1. Download and Unzip latest Raspbian Lite

    ```
    XCS~S mkdir -p ~/rpi/img
    XCS~$ cd ~/rpi/img
    XCS~$ wget https://downloads.raspberrypi.org/raspbian_lite_latest
    XCS~$ unzip raspbian_lite_latest
    ```
    > This download is the Lite version of raspbian and hence does not include a GUI or commonly used application. If a GUI is required, you can add it later via `apt-get` or download a different raspbian version.
1. Connect SDCard to the VM.
    > For this you need to open Virtual Box (in case you are connected to a headless system via SSH). 
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
      sdb                           8:16   1  7.3G  0 disk       <=== Our 8Gb SDCard!
      ├─sdb1                        8:17   1   63M  0 part 
      └─sdb2                        8:18   1  7.3G  0 part 
      sr0                          11:0    1 55.7M  0 rom  
    ```
    
1. Install Raspbian (this might take a while..)
     
    ```
    XCS~$ sudo dd bs=4M if=/home/pi/rpi/img/2020-02-13-raspbian-buster-lite.img of=/dev/sdb
    
    [sudo] password for pi: 
    441+0 records in
    441+0 records out
    1849688064 bytes (1.8 GB, 1.7 GiB) copied, 71.1205 s, 26.0 MB/s
    ```
    
1. Validate that the image is properly copied

    ```
    XCS~$ sudo dd bs=4M if=/dev/sdb of=from-sd-card.img
    XCS~$ sudo truncate --reference 2020-02-13-raspbian-buster-lite.img from-sd-card.img 
    XCS~$ sudo diff -s from-sd-card.img 2020-02-13-raspbian-buster-lite.img 
    Files from-sd-card.img and 2020-02-13-raspbian-buster-lite.img are identical
    ```
    
1. Remove images, we do not need these anymore

    ```
    XCS~$ sudo rm *.img
    ```
# Next

Having installed the basic components, lets [setup the network/ssh!](02-network.md)
