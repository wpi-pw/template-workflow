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
script_url="" # script_url var reset

# text font weight
bold=$(tput bold)
normal=$(tput sgr0)

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

# global current environment via wpi-env.yml
cur_env() {
  echo $(yq r "${PWD}/wpi-env.yml" cur_env)
}

# get current environment or return default
get_cur_env() {
  if [ -z "$1" ]; then
    echo local
  else
    echo $1
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

# helper for yq parser
wpi_yq() {
  key=$1
  output_keys=$2
  # get config files
  for i in "${!wpi_confs[@]}";
  do
    # clean config path
    conf_name=$(echo "${wpi_confs[$i]##*/}" | cut -d'-' -f 2 | cut -d'.' -f 1)
    # get curent config name
    cur_conf=$(echo ${key} | cut -d"." -f1)
    # prepare config key
    conf_key=${key//$cur_conf./}
    if [ "$conf_name" == "$cur_conf" ] && [ "$output_keys" == "top_keys" ]; then
      # output top keys only
      yq r ${wpi_confs[$i]} | grep -v '  .*' | sed -n -e '/^\([^ ]\([^:]\+\)\?\):/  s/:.*// p'
    elif [ "$conf_name" == "$cur_conf" ] && [ "$output_keys" == "keys" ]; then
      # output keys only
      yq r ${wpi_confs[$i]} $conf_key | sed -n -e '/^\([^ ]\([^:]\+\)\?\):/  s/:.*// p'
    elif [ "$conf_name" == "$cur_conf" ]; then
      yq r ${wpi_confs[$i]} $conf_key
    fi
  done
}

# helper for shell scripts array
shell_runner() {
  shell_array=$1
  cur_env=$2

  # create yml with current environment
  if [ "$shell_array" == "before_install" ]; then
    echo "cur_env: $cur_env" > wpi-env.yml
  fi

  # Create array of scripts
  mapfile -t shell_scripts < <( wpi_yq shell.$shell_array )

  # Run shell runner after app install
  if [ "$(wpi_yq init.shell)" == "true" ]; then
    for script in "${shell_scripts[@]}"
    do
      if [ "$script" != "null" ] && [ "$script" ]; then
        # prepare the url before run
        script_url=${script:2}
        bash <(curl -s $(url_path "template-workflow/wpi-shell")) $script_url
      fi
    done
  fi
}

# symlinks creator
wpi_dir_symlinks() {
  symlinks_path=${PWD}
  wpi_symlink=$1
  cur_env=$(cur_env)
  app_content=$(wpi_yq "env.$cur_env.app_content")
  wpi_workflow_path="wp-content"
  if [ "$cur_env" != "local" ]; then
    # symlinks for bedrock workflow
    if [ "$(wpi_yq init.workflow)" == "bedrock" ]; then
      wpi_workflow_path="app"
    fi
    # create storage directory if not exist
    if [ ! -d "$symlinks_path$app_content" ]; then
      mkdir $symlinks_path$app_content
    fi
    # remove the symlink if exist
    if [ -L "$symlinks_path/web/$wpi_workflow_path/$wpi_symlink" ]; then
      rm $symlinks_path/web/$wpi_workflow_path/$wpi_symlink
    fi
    # remove uploads if release uploads directory exist
    if [ -d "$symlinks_path$app_content/$wpi_symlink" ]; then
      rm -rf $symlinks_path/web/$wpi_workflow_path/$wpi_symlink
    elif [ -d "$symlinks_path/web/$wpi_workflow_path/$wpi_symlink" ]; then
      # move uploads firectory to storage if exist
      mv $symlinks_path/web/$wpi_workflow_path/$wpi_symlink $symlinks_path$app_content
    fi
    # make storage directory if not exist
    if [ ! -d "$symlinks_path$app_content$wpi_symlink" ]; then
      mkdir $symlinks_path$app_content$wpi_symlink
    fi
    # create symlinks for uploads to the storage directory if not exist
    ln -s $symlinks_path$app_content$wpi_symlink $symlinks_path/web/$wpi_workflow_path/$wpi_symlink
  fi
}

# sync runner for wpi
sync() {
  bash <(curl -s -L sync.wpi.pw) && exit 1
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

# Check if the function exists (bash specific)
if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
fi