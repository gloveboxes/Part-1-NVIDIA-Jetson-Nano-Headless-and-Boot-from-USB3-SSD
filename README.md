# Part 1: nVidia Jetson Nano Headless and Boot from USB3 SSD

[rootOnUSB](https://github.com/JetsonHacksNano/rootOnUSB)

## Clone JetsonHacksNano rootOnUSB Repo

```bash
git clone https://github.com/JetsonHacksNano/rootOnUSB.git
```

## Prepare USB3 SSD Drive

```bash
sudo fdisk /dev/sda
sudo mkfs.ext4 /dev/sda1
sudo mkdir /media/usbdrive
sudo mount /dev/sda1 /media/usbdrive
```

## Copy Root to USB3 SSD

## Update Boot Configuration

