#!/bin/bash

# WPI UP - for every vagrant up provision
# by DimaMinka (https://dima.mk)
# https://github.com/wpi-pw/app

# Define custom config if exist
if [[ -f /home/vagrant/config/wpi-custom.yml ]]; then
	wpi_config="/home/vagrant/config/wpi-custom.yml"
else
  wpi_config="/home/vagrant/config/wpi-default.yml"
fi

# Get wpi-helper for yml parsing, noroot, errors etc
source <(curl -s https://raw.githubusercontent.com/wpi-pw/template-workflow/master/wpi-helper.sh)

printf "${GRN}==============================${NC}\n"
printf "${GRN} Staring NGINX ${NC}\n"
printf "${GRN}==============================${NC}\n"
# Start NGINX on vagrant up - not started automatically with symlink to WebRoot WWW
sudo service nginx start

printf "${GRN}==============================${NC}\n"
printf "${GRN} Delete self ${NC}\n"
printf "${GRN}==============================${NC}\n"
rm -- "$0"
