#!/bin/bash

OS_UPDATE=false
BOOT_USB3=false
HIGH_POWER=false
XRDP=false
REMOVE_OFFICE=false


STATE=~/.PyLabState
RUNNING=true

# remove then add to .bashrc to auto restart install process on login
sed --in-place '/~\/JetsonSetup\/setup.sh/d' ~/.bashrc
echo "~/JetsonSetup/setup.sh" >> ~/.bashrc

while $RUNNING; do
  case $([ -f $STATE ] && cat $STATE) in

    INIT)
        sudo apt install -y nano htop rsync
        echo "OFFICE" > $STATE
    ;;

    OFFICE)
        REMOVE_OFFICE=false
        while true; do
            read -p "Do you wish to uninstall LibreOffice. [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) REMOVE_OFFICE=true; break;;
                [Qq]* ) RUNNING=false; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done

        echo "UPDATE" > $STATE

        if [ "$REMOVE_OFFICE" = true ]; then
            sudo apt remove -y --purge libreoffice* && sudo apt clean && sudo apt-get -y autoremove
        fi
        ;;    

    UPDATE)
        OS_UPDATE=false
        while true; do
            read -p "Do you wish to update the Jetson Operating System (Recommended). Note: This will reboot the device. [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) OS_UPDATE=true; break;;
                [Qq]* ) RUNNING=false; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done

        echo "SSD" > $STATE

        if [ "$OS_UPDATE" = true ]; then
            sudo apt update && sudo apt upgrade -y && sudo reboot
            if [ $? -ne 0 ]; then
              echo -e "\nError: Problem with OS Update/Upgrade.\nReboot device if the problem persists.\nRetry.\n"
              echo "UPDATE" > $STATE
            fi

        fi
        ;;    

    SSD)
        BOOT_USB3=false
        while true; do
            echo -e "\nThis script assumes the USB3 SSD Drive is mounted at /dev/sda ready for partitioning and formating" 
            read -p "Do you wish to enable USB3 SSD Boot Support [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) BOOT_USB3=true; break;;
                [Qq]* ) RUNNING=false; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done

        echo "HIGH_POWER" > $STATE

        if [ "$BOOT_USB3" = true ]; then
            echo -e "\np = print partitions, \nd = delete a partition, \nn = new partition -> create a primary partition, \nw = write the partition information to disk, \nq = quit\n"
            echo -e "\nUsage: \n1) p to print existing partitions, \n2) d to delete existing, \n3) n to create new partition, take defaults, \n4) finally w to write changes.\n"
            sudo fdisk /dev/sda
            sudo mkfs.ext4 /dev/sda1
            DISKUUID=$(sudo blkid -s UUID -o value /dev/sda1)
            # sudo mkdir -p /media/usbdrive
            # sudo mount /dev/sda1 /media/usbdrive

            sudo rm -f -r rootOnUSB
            git clone https://github.com/JetsonHacksNano/rootOnUSB.git

            cd rootOnUSB

            ./addUSBToInitramfs.sh
            ./copyRootToUSB.sh -p /dev/sda1

            if [ $? -eq 0 ]; then

                # blkid -s UUID -o value /dev/sda1
                echo "" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "LABEL usbssd" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "      MENU LABEL usbssd kernel" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "      LINUX /boot/Image" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "      INITRD /boot/initrd-xusb.img" | sudo tee -a /boot/extlinux/extlinux.conf
                # echo "      APPEND ${cbootargs} rootfstype=ext4 root=/dev/sda1 rw rootwait" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "      APPEND ${cbootargs} root=UUID=$DISKUUID rootwait rootfstype=ext4" | sudo tee -a /boot/extlinux/extlinux.conf


                sudo sed -i 's/TIMEOUT 30/TIMEOUT 10/g' /boot/extlinux/extlinux.conf
                sudo sed -i 's/DEFAULT primary/DEFAULT usbssd/g' /boot/extlinux/extlinux.conf

                # sudo reboot
            fi            
        fi
        ;;    

    HIGH_POWER)
        HIGH_POWER=false
        while true; do
            read -p "Do you wish to set High Power Mode (This requires 4amp barrel power adapter) [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) HIGH_POWER=true; break;;
                [Qq]* ) RUNNING=false; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done

        if [ "$HIGH_POWER" = true ]; then
            sudo nvpmodel -m 0
        fi

        echo "XRDP" > $STATE
        ;;      

    XRDP)
        XRDP=false
        while true; do
            read -p "Do you wish to enable xRDP (with xfce) [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) XRDP=true; break;;
                [Qq]* ) RUNNING=false; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done        

        if [ "$XRDP" = true ]; then
            # https://medium.com/@vivekteega/how-to-setup-an-xrdp-server-on-ubuntu-18-04-89f7e205bd4e
            sudo apt install -y xrdp xfce4-terminal 
            sudo sed -i.bak '/fi/a #xrdp multiple users configuration \n xfce-session \n' /etc/xrdp/startwm.sh
            sudo /etc/init.d/xrdp restart
        fi

        echo "BREAK" > $STATE
        ;; 

    BREAK)
      RUNNING=false
      ;;
    *)
      echo "INIT" > $STATE
      ;;
  esac
done

rm $STATE
# remove install process from .bashrc
sed --in-place '/~\/JetsonSetup\/setup.sh/d' ~/.bashrc
