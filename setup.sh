#!/bin/bash

OS_UPDATE=false
BOOT_USB3=false
HIGH_POWER=false
XRDP=false


STATE=~/.PyLabState
RUNNING=true

# remove then add to .bashrc to auto restart install process on login
sed --in-place '/~\/JetsonSetup\/setup.sh/d' ~/.bashrc
echo "~/JetsonSetup/setup.sh" >> ~/.bashrc

while $RUNNING; do
  case $([ -f $STATE ] && cat $STATE) in

    INIT)
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
        fi
        ;;    

    SSD)
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
            sudo mkdir /media/usbdrive
            sudo mount /dev/sda1 /media/usbdrive

            sudo apt update && sudo apt install rsync

            sudo rm -f -r rootOnUSB
            git clone https://github.com/JetsonHacksNano/rootOnUSB.git

            cd rootOnUSB

            ./addUSBToInitramfs.sh
            ./copyRootToUSB.sh -d /media/usbdrive

            if [ $? -eq 0 ]; then

                sudo sed -i 's/TIMEOUT 30/TIMEOUT 10/g' /boot/extlinux/extlinux.conf
                sudo sed -i 's/LABEL primary/LABEL emmc/g' /boot/extlinux/extlinux.conf
                echo "LABEL primary" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "      MENU LABEL primary kernel" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "      LINUX /boot/Image" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "      INITRD /boot/initrd-xusb.img" | sudo tee -a /boot/extlinux/extlinux.conf
                echo "      APPEND ${cbootargs} root=/dev/sda1 rootwait rootfstype=ext4" | sudo tee -a /boot/extlinux/extlinux.conf

                sudo cat /boot/extlinux/extlinux.conf

                sudo reboot
            fi            
        fi
        ;;    

    HIGH_POWER)
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
