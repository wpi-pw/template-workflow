#!/bin/bash

# WPI Workflow
# by DimaMinka (https://dima.mk)
# https://github.com/wpi-pw/app

printf "${GRN}===================================${NC}\n"
printf "${GRN}Running workflow $wpi_init_workflow${NC}\n"
printf "${GRN}===================================${NC}\n"

if [ "$wpi_init_workflow" == "bedrock" ]; then
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
    if [ "$wpi_init_wordpress" != "*" ]; then
        composer require roots/wordpress:$wpi_init_wordpress --update-no-dev
    else
        # Runing installation via composer
        composer install --no-dev
    fi
elif [ "$wpi_init_workflow" == "cdk-comp/bedrock" ]; then
    # Clone the repo
    curl -LOks https://github.com/cdk-comp/bedrock/archive/master.zip
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
    if [ "$wpi_init_wordpress" != "*" ]; then
        composer require roots/wordpress:$wpi_init_wordpress --update-no-dev
    else
        # Runing installation via composer
        composer install --no-dev
    fi
elif [ "$wpi_init_workflow" == "wp-cli" ]; then
    # Setup WordPress version from config
    if [ "$wpi_init_wordpress" != "*" ]; then
        wp_version="--version=$wpi_init_wordpress"
    fi
    # Define WordPress web path
    echo "path: web" > wp-cli.yml
    # Download Wordpress
    wp core download --path=web --quiet
    # Generate wp-config.php
#    wp core config --dbname=$conf_app_env_db_name --dbuser=$conf_app_env_db_user --dbpass=$conf_app_env_db_pass --dbhost=localhost --quiet
fi
