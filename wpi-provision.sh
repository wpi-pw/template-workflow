#!/usr/bin/env bash
#
# vagrant up provisioning file
#
# Author: Dima Minka
#
# File version 1.1.2

# Define custom config if exist
if [[ -f wpi-custom.yml ]]; then
	wpi_config="/home/vagrant/config/wpi-custom.yml"
else
  wpi_config="/home/vagrant/config/wpi-default.yml"
fi

# Get wpi-helper for yml parsing, noroot, errors etc
source <(curl -s https://raw.githubusercontent.com/wpi-pw/template-workflow/master/wpi-helper.sh)

if [ "$conf_vm_box" == "wpi/box" ]; then
  # Basic provison for new box
  echo "=============================="
  echo "You can replace $conf_wpi_user with your username & $conf_wpi_email by your email in wpi-config.yml"
  echo "=============================="
  sudo chown vagrant:vagrant /home/vagrant/.[^.]*
  sudo echo -e "source ~/.bashrc\n" >> /home/vagrant/.bash_profile 2>/dev/null
  sudo echo -e "[user]\n\tname = $conf_wpi_user\n\temail = $conf_wpi_email" > /home/vagrant/.gitconfig

  echo "=============================="
  echo "Copy gitconfig and bash_profile to www-data directory"
  echo "=============================="
  sudo cp /home/vagrant/{.gitconfig,.bash_profile} /home/vagrant/apps
  sudo chown www-data:www-data /var/www/.[^.]*

  echo "=============================="
  echo "copy keys from vagrant directory to www-data and root"
  echo "=============================="
  ssh-keyscan -H bitbucket.org >> /home/vagrant/.ssh/known_hosts 2>/dev/null
  ssh-keyscan -H github.com >> /home/vagrant/.ssh/known_hosts 2>/dev/null
  sudo cp -r /home/vagrant/.ssh /home/vagrant/apps/.ssh
  sudo chown -R www-data:www-data /home/vagrant/apps/.ssh

  echo "=============================="
  echo "move files to vagrant apps and make the symlink"
  echo "=============================="
  sudo mv /var/www/{.,}* /home/vagrant/apps 2>/dev/null
  sudo mv /var/www /var/www-disabled 2>/dev/null
  sudo ln -s /home/vagrant/apps /var/www
fi
