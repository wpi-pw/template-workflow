#!/bin/bash

# Workflow Helper - WPI
# by DimaMinka (https://dimaminka.com)
# https://github.com/wpi-pw/app

# Define custom config if exist
if [[ -f wpi-custom.yml ]]; then
	wpi_config="/home/vagrant/config/wpi-custom.yml"
else
  wpi_config="/home/vagrant/config/wpi-default.yml"
fi

# Get wpi-helper for yml parsing, noroot, errors etc
source <(curl -s https://raw.githubusercontent.com/wpi-pw/template-workflow/master/wpi-helper.sh)

# App create, disable, enable
for i in "${!conf_apps__host[@]}"
do
  if [ "${conf_apps__status[$i]}" == "disable" ] || [ "${conf_apps__status[$i]}" == "enable" ]; then

    printf "${GRN}===================================================${NC}\n"
    printf "${GRN}${conf_apps__status[$i]} app ${conf_apps__host[$i]}${NC}\n"
    printf "${GRN}===================================================${NC}\n"

    # Enable/Disable app via WordOps
    yes | sudo wo site ${conf_apps__status[$i]} ${conf_apps__host[$i]}

    # Change app status to enabled/disabled
    sed -i.bak "s/\bstatus: ${conf_apps__status[$i]}\b/status: ${conf_apps__status[$i]}d/g" $wpi_config

  fi

  if [ "${conf_apps__status[$i]}" == "create" ]; then

    printf "${GRN}===================================${NC}\n"
    printf "${GRN}Creating app ${conf_apps__host[$i]}${NC}\n"
    printf "${GRN}===================================${NC}\n"

    # Create app via WordOps
    yes | sudo wo site create ${conf_apps__host[$i]} --mysql --${conf_apps__php[$i]}

    # GIT pull via github/bitbucket
    if [ "${conf_apps__scm[$i]}" == "github" ] || [ "${conf_apps__scm[$i]}" == "bitbucket" ]; then

      printf "${GRN}=======================================${NC}\n"
      printf "${GRN}Git pull for app ${conf_apps__host[$i]}${NC}\n"
      printf "${GRN}=======================================${NC}\n"

      if [ "${conf_apps__scm[$i]}" == "github" ]; then
        scm="github.com"
      else
        scm="bitbucket.org"
      fi

      rm -rf /home/vagrant/apps/${conf_apps__host[$i]}/htdocs
      cd /home/vagrant/apps/${conf_apps__host[$i]}
      git clone --single-branch --branch  ${conf_apps__branch[$i]} --depth=1 --quiet git@$scm:${conf_apps__repo[$i]}.git htdocs

    fi

    # Public path changing in nginx conf via config
    if [ ! -z "${conf_apps__public_path[$i]}" ]; then
      printf "${GRN}=========================================================================${NC}\n"
      printf "${GRN}Change default public directory 'htdocs' to ${conf_apps__public_path[$i]}${NC}\n"
      printf "${GRN}=========================================================================${NC}\n"
      new_path=$(echo "${conf_apps__public_path[$i]}" | sed 's/\//\\\//g')
      sudo sed -i -e "s/htdocs/$new_path/g" "/etc/nginx/sites-available/${conf_apps__host[$i]}"
      sudo service nginx reload
    fi

    # WPI auto instaling for type wpi
    if [[ -f "/home/vagrant/apps/${conf_apps__host[$i]}/htdocs/wpi.sh" ]] && [ "${conf_apps__type[$i]}" == "wpi" ]; then
      printf "${GRN}================================================${NC}\n"
      printf "${GRN}WPI installer running for ${conf_apps__host[$i]}${NC}\n"
      printf "${GRN}================================================${NC}\n"
      cd /home/vagrant/apps/${conf_apps__host[$i]}/htdocs
      bash wpi.sh
    fi

    # Change app status to created
    sed -i.bak "s/\bstatus: create\b/status: created/g" $wpi_config
  fi
done