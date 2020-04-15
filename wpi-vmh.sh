#!/bin/bash

# WPI Vagrant Must Have Provision
# by DimaMinka (https://dima.mk)
# https://github.com/wpi-pw/app

echo "=============================="
echo "System update and packages cleanup"
echo "=============================="
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
sudo echo grub-pc hold | sudo dpkg --set-selections
sudo add-apt-repository ppa:rmescandon/yq
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

echo "=============================="
echo "Unzip, yq installing"
echo "=============================="
sudo apt install yq unzip -y

echo "=============================="
echo "Default .bashrc and .profile downloading"
echo "=============================="
sudo wget -O /home/vagrant/.profile https://raw.githubusercontent.com/wpi-pw/ubuntu-nginx-web-server/master/var/www/.profile
sudo wget -O /home/vagrant/.bashrc https://raw.githubusercontent.com/wpi-pw/ubuntu-nginx-web-server/master/var/www/.bashrc
