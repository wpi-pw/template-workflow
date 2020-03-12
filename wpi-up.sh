#!/bin/bash

# WPI UP - for every vagrant up provision
# by DimaMinka (https://dima.mk)
# https://github.com/wpi-pw/app

# Define custom config if exist
if [[ -f "/home/vagrant/config/wpi-custom.yml" ]]; then
	wpi_config="/home/vagrant/config/wpi-custom.yml"
else
  wpi_config="/home/vagrant/config/wpi-default.yml"
fi

# Get wpi-helper for yml parsing, noroot, errors etc
source <(curl -s https://raw.githubusercontent.com/wpi-pw/template-workflow/master/wpi-helper.sh)

printf "${GRN}==============================${NC}\n"
printf "${GRN} Staring NGINX                ${NC}\n"
printf "${GRN}==============================${NC}\n"
# Start NGINX on vagrant up - not started automatically with symlink to WebRoot WWW
sudo service nginx start

printf "${GRN}==============================${NC}\n"
printf "${GRN} Checking apps from config    ${NC}\n"
printf "${GRN}==============================${NC}\n"
# Create array of app hosts and loop
mapfile -t apps_host < <( wpi_yq 'apps.[*].host' )
# App create, disable, enable
for i in "${!apps_host[@]}"
do
  if [ "$(wpi_yq apps.[$i].status)" == "disable" ] || [ "$(wpi_yq apps.[$i].status)" == "enable" ]; then
    printf "${GRN}==============================                    ${NC}\n"
    printf "${GRN} $(wpi_yq apps.[$i].status) app - ${apps_host[$i]}${NC}\n"
    printf "${GRN}==============================                    ${NC}\n"
    # Enable/Disable app via WordOps
    yes | sudo wo site $(wpi_yq apps.[$i].status) ${apps_host[$i]}
    # Change app status to enabled/disabled
    sed -i.bak "s/\bstatus: $(wpi_yq apps.[$i].status)\b/status: $(wpi_yq apps.[$i].status)d/g" $wpi_config
    printf "${GRN}==============================${NC}\n"
    printf "${GRN} Moving to next app...        ${NC}\n"
    printf "${GRN}==============================${NC}\n"
  fi

  if [ "$(wpi_yq apps.[$i].status)" == "create" ]; then
    printf "${GRN}==============================${NC}\n"
    printf "${GRN} Creating app ${apps_host[$i]}${NC}\n"
    printf "${GRN}==============================${NC}\n"
    # Create app via WordOps
    yes | sudo wo site create ${apps_host[$i]} --mysql --$(wpi_yq apps.[$i].php) --quiet
    # Change app status to created
    sed -i.bak "s/\bstatus: create\b/status: created/g" $wpi_config
    # GIT pull via github/bitbucket
    if [ "$(wpi_yq apps.[$i].git.scm)" == "github" ] || [ "$(wpi_yq apps.[$i].git.scm)" == "bitbucket" ]; then
      printf "${GRN}==============================      ${NC}\n"
      printf "${GRN} Git pull for app - ${apps_host[$i]}${NC}\n"
      printf "${GRN}==============================      ${NC}\n"
      if [ "$(wpi_yq apps.[$i].git.scm)" == "github" ]; then
        scm="github.com"
      else
        scm="bitbucket.org"
      fi
      rm -rf /home/vagrant/apps/${apps_host[$i]}/htdocs
      cd /home/vagrant/apps/${apps_host[$i]}
      git clone --single-branch --branch $(wpi_yq apps.[$i].git.branch) --depth=1 --quiet git@$scm:$(wpi_yq apps.[$i].git.repo).git htdocs 2>/dev/null
    fi
    # Public path changing in nginx conf via config
    if [ ! -z "$(wpi_yq apps.[$i].public_path)" ]; then
      printf "${GRN}==============================                         ${NC}\n"
      printf "${GRN} Public dir changing to $(wpi_yq apps.[$i].public_path)${NC}\n"
      printf "${GRN}==============================                         ${NC}\n"
      new_path=$(echo "$(wpi_yq apps.[$i].public_path)" | sed 's/\//\\\//g')
      sudo sed -i -e "s/htdocs/$new_path/g" "/etc/nginx/sites-available/${apps_host[$i]}"
      sudo service nginx reload
    fi
    printf "${GRN}==============================${NC}\n"
    printf "${GRN} Moving to next app...        ${NC}\n"
    printf "${GRN}==============================${NC}\n"
  fi
done

printf "${GRN}==============================${NC}\n"
printf "${GRN} Displaying Vagrant apps:     ${NC}\n"
printf "${GRN}==============================${NC}\n"

# Script self destruction
rm ${PWD}/wpi-up