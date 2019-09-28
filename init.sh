#!/bin/bash

rm -r -f ~/JetsonSetup
echo 'Git Cloning the Setup Libraries'
git clone --depth=1 https://github.com/gloveboxes/Part-1-NVIDIA-Jetson-Nano-Headless-and-Boot-from-USB3-SSD.git ~/JetsonSetup

cd ~/JetsonSetup
echo "sudo required to mark setup.sh as executable."
sudo chmod +x *.sh
./setup.sh
