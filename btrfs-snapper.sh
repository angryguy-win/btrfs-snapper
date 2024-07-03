#!/usr/bin/env bash
#github-action genshdoc
#
## This code was made posible by the use of code from Chris Titus..
## Arch Titus install script.
## Added BTRFS/Snapper functionality, and Grub snapshot updates.
## and required configurations.
#
## Create an Install setup script point to the scripts..

# Find the name of the folder the scripts are in
set -a
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPTS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/scripts
CONFIGS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/configs
set +a

    ( bash $SCRIPT_DIR/scripts/startup.sh )|& tee startup.log
      source $CONFIGS_DIR/setup.conf
    cp -v *.log /mnt/home/$USERNAME
