#!/bin/bash

# Workflow Source - WPI
# by DimaMinka (https://dima.mk)
# https://github.com/wpi-pw/app

# Define colors
RED='\033[0;31m' # error
GRN='\033[0;32m' # success
BLU='\033[0;34m' # task
BRN='\033[0;33m' # headline
NC='\033[0m'     # no color

# YAML parser function
parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"

    (
        sed -e '/- [^\“]'"[^\']"'.*: /s|\([ ]*\)- \([[:space:]]*\)|\1-\'$'\n''  \1\2|g' |

        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/[[:space:]]*$//g;' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)${s}[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

        awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |

        sed -e 's/_=/+=/g' |

        awk 'BEGIN {
                FS="=";
                OFS="="
            }
            /(-|\.).*=/ {
                gsub("-|\\.", "_", $1)
            }
            { print }'
    ) < "$yaml_file"
}

# root user change
noroot() {
  sudo -EH -u "vagrant" "$@";
}

# get current environment or return default
get_cur_env() {
  if [ -z "$1" ]; then
    cur_env="local"
  else
    cur_env=$1
  fi
}

# url path builder
url_path() {
  template_path=$1
  repo=$(echo ${template_path} | cut -d"/" -f1)
  file_name=$(echo ${template_path} | cut -d"/" -f2)
  echo "https://raw.githubusercontent.com/wpi-pw/$repo/master/$file_name.sh"
}

# download and run the script with auto removing after complete
template_runner() {
  template=$1
  script_url=$(url_path $2)
  template_conf=$3
  cur_env=$4

  # check template config status
  if [ "$template_conf" != "false" ]; then
    # Template downloader
    if [ "$template" == "default" ]; then
        curl --silent $script_url > tmp-template.sh
      echo ''
    else
        curl --silent $template > tmp-template.sh
    fi

    # If template downloaded, run the script
    if [ -f "${PWD}/tmp-template.sh" ]; then
        bash ${PWD}/tmp-template.sh $cur_env
        # delete the script after complete
        rm ${PWD}/tmp-template.sh
    fi
  fi
}

# dynamic key helper
wpi_key() {
  key_sufix=$1
  wpi_key=$cur_wpi$key_sufix
  echo ${!wpi_key}
}

# ERROR Handler
# ask user to continue on error
continue_error() {
  read -p "$(echo -e "${RED}Do you want to continue anyway? (y/n) ${NC}")" -n 1 -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    printf "\n${RED}»»» aborting WPI app setup! ${NC}\n"
    exit 1
  else
    printf "\n${GRN}»»» continuing WPI app setup... ${NC}\n"
  fi
}
trap 'continue_error' ERR

# Read configs
for i in "${!wpi_confs[@]}"; do
  conf_name=$(echo "${wpi_confs[$i]##*/}" | cut -d'-' -f 2 | cut -d'.' -f 1)
  eval $(parse_yaml ${wpi_confs[$i]} "wpi_${conf_name}_")
done
