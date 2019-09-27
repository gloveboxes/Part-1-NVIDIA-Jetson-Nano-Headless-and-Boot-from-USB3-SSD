git clone https://github.com/JetsonHacksNano/rootOnUSB.git

BOOT_USB3=false

while true; do
    echo -e "\nThis script assumes the USB3 SSD Drive is mounted at /dev/sda ready for partitioning and formating" 
    read -p "Do you wish to enable USB3 SSD Boot Support [yes(y), no(n), or quit(q)] ?" yn
    case $yn in
        [Yy]* ) BOOT_USB3=true; break;;
        [Qq]* ) exit 1;;
        [Nn]* ) exit 1;;
        * ) echo "Please answer yes(y), no(n), or quit(q).";;
    esac
done

if [ "$BOOT_USB3" = true ]; then
    echo -e "\np = print partitions, \nd = delete a partition, \nn = new partition -> create a primary partition, \nw = write the partition information to disk, \nq = quit\n"
    echo -e "\nUsage: p to print existing partitions, d to delete existing, n to create new partition, select p for new primary, take defaults, finally w to write changes.\n"
    sudo fdisk /dev/sda
    sudo mkfs.ext4 /dev/sda1
    sudo mkdir /media/usbdrive
    sudo mount /dev/sda1 /media/usbdrive
fi

cd rootOnUSB

./addUSBToInitramfs.sh

./copyRootToUSB.sh -d /media/usbdrive

# Update Boot Config



#INITRD /boot/initrd-xusb.img
#APPEND ${cbootargs} root=/dev/sda1 rootwait rootfstype=ext4