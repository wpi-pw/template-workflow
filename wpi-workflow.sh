#!/bin/bash

# WPI Workflow
# by DimaMinka (https://dima.mk)
# https://github.com/wpi-pw/app

# Get config files and put to array
wpi_confs=()
for ymls in wpi-config/*
do
  wpi_confs+=("$ymls")
done

# Get wpi-source for yml parsing, noroot, errors etc
source <(curl -s https://raw.githubusercontent.com/wpi-pw/template-workflow/master/wpi-source.sh)

cur_env=$(cur_env)

printf "${GRN}========================================${NC}\n"
printf "${GRN}Running workflow $(wpi_yq init.workflow)${NC}\n"
printf "${GRN}========================================${NC}\n"

if [ "$(wpi_yq init.workflow)" == "bedrock" ] && ! [ -d ${PWD}/web ]; then
  # Clone the repo
  curl -LOks https://github.com/roots/bedrock/archive/master.zip
  # Unzip the repo
  unzip -q master.zip
  # Prepare the project
  mv bedrock-master/.env.example .
  mv bedrock-master/config .
  mv bedrock-master/web .
  mv bedrock-master/composer.json .
  mv bedrock-master/wp-cli.yml .
  # Clean zip and cloned directory
  rm -rf bedrock-master master.zip
  # Setup WordPress version from config
  if [ "$(wpi_yq init.wordpress)" != "null" ] && [ "$(wpi_yq init.wordpress)" ] && [ "$(wpi_yq init.wordpress)" != "*" ]; then
      composer require roots/wordpress:$(wpi_yq init.wordpress) --update-no-dev --quiet
  else
      # Runing installation via composer
      composer install --no-dev --quiet
  fi
  # Remove MU Plugin Disallow Indexing if not DEV or Staging
  if [ "$cur_env" != "development" ] && [ "$cur_env" != "staging" ] && [ "$(wpi_yq env.$cur_env.app_noindex)" != "true" ]; then
    rm -rf ${PWD}/web/app/mu-plugins/bedrock-disallow-indexing
  fi  
elif [ "$(wpi_yq init.workflow)" == "wp-cli" ]; then
  # Get current env from arg if exist
  wpi_db_name="env.$cur_env.db_name"
  wpi_db_user="env.$cur_env.db_user"
  wpi_db_pass="env.$cur_env.db_pass"
  wpi_db_prefix="env.$cur_env.db_prefix"
  wp_version=""

  # Setup WordPress version from config
  if [ "$(wpi_yq init.wordpress)" != "*" ]; then
      wp_version="--version=$(wpi_yq init.wordpress)"
  fi
  # Define WordPress web path
  echo "path: web" > wp-cli.yml
  # Download Wordpress
  wp core download --path=web $wp_version --force --quiet
  # Generate wp-config.php
  wp core config --dbname=$(wpi_yq $wpi_db_name) --dbuser=$(wpi_yq $wpi_db_user) --dbpass=$(wpi_yq $wpi_db_pass) --dbprefix=$(wpi_yq $wpi_db_prefix) --dbhost=localhost --quiet
fi
