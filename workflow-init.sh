#!/bin/bash

# Init - Wp Pro Club
# by DimaMinka (https://dimaminka.com)
# https://github.com/wp-pro-club/init

source ${PWD}/lib/app-init.sh

if [ "$conf_app_setup_workflow" == "bedrock" ]; then
    # Clone the repo
    curl -LOks https://github.com/roots/bedrock/archive/master.zip
    # Unzip the repo
    unzip -q master.zip
    # Prepare the project
    mv bedrock-master/config .
    mv bedrock-master/web .
    mv bedrock-master/composer.json .
    mv bedrock-master/wp-cli.yml .
    # Clean zip and cloned directory
    rm -rf bedrock-master master.zip
    # Setup WordPress version from config
    if [ "$conf_app_setup_wordpress" != "*" ]; then
        composer require roots/wordpress:$conf_app_setup_wordpress --update-no-dev
    else
        # Runing installation via composer
        composer install --no-dev
    fi
elif [ "$conf_app_setup_workflow" == "cdk-comp/bedrock" ]; then
    # Clone the repo
    curl -LOks https://github.com/cdk-comp/bedrock/archive/master.zip
    # Unzip the repo
    unzip -q master.zip
    # Prepare the project
    mv bedrock-master/config .
    mv bedrock-master/web .
    mv bedrock-master/composer.json .
    mv bedrock-master/wp-cli.yml .
    # Clean zip and cloned directory
    rm -rf bedrock-master master.zip
    # Setup WordPress version from config
    if [ "$conf_app_setup_wordpress" != "*" ]; then
        composer require roots/wordpress:$conf_app_setup_wordpress --update-no-dev
    else
        # Runing installation via composer
        composer install --no-dev
    fi
elif [ "$conf_app_setup_workflow" == "cdkrock" ]; then
    # Clone the repo
    curl -LOks https://github.com/cdk-comp/cdkrock/archive/master.zip
    # Unzip the repo
    unzip -q master.zip
    # Prepare the project
    mv cdkrock-master/config .
    mv cdkrock-master/web .
    mv cdkrock-master/composer.json .
    mv cdkrock-master/wp-cli.yml .
    mv cdkrock-master/post-install.sh .
    mv cdkrock-master/post-update.sh .
    # Clean zip and cloned directory
    rm -rf cdkrock-master master.zip
    # Setup WordPress version from config
    if [ "$conf_app_setup_wordpress" != "*" ]; then
        composer require johnpbloch/wordpress:$conf_app_setup_wordpress --update-no-dev
    else
        # Runing installation via composer
        composer install --no-dev
    fi
elif [ "$conf_app_setup_workflow" == "wp-cli" ]; then
    # Setup WordPress version from config
    if [ "$conf_app_setup_wordpress" != "*" ]; then
        wp_version="--version=$conf_app_setup_wordpress"
    fi
    # Define WordPress web path
    echo "path: web" > wp-cli.yml
    # Download Wordpress
    wp core download --path=web
    # Generate wp-config.php
    wp core config --dbname=$conf_app_env_db_name --dbuser=$conf_app_env_db_user --dbpass=$conf_app_env_db_pass --dbhost=localhost
fi
