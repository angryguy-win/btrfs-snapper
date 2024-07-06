#!/usr/bin/env bash

set_option() {
    if grep -Eq "^${1}.*" "$CONFIG_FILE"; then # check if option exists
        sed -i -e "/^${1}.*/d" "$CONFIG_FILE" # delete option if exists
    fi
    echo "${1}=${2}" >> "$CONFIG_FILE" # add option
}

set_option SSD "Yes"
