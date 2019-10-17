#!/bin/bash

# Workflow shell runner - WPI
# by DimaMinka (https://dima.mk)
# https://github.com/wpi-pw/app

# Download shell scripts from config before project init
curl --silent $1 > tmp-template.sh
# If template downloaded, run the script
if [ -f "${PWD}/tmp-template.sh" ]; then
  bash ${PWD}/tmp-template.sh
  # delete the script after complete
  rm ${PWD}/tmp-template.sh
fi
