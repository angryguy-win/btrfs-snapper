#!/usr/bin/env bash
# Fixing annoying issue that breaks GitHub Actions
# shellcheck disable=SC2001

#github-action genshdoc
#
# @file Startup
# @brief This script will ask users about their prefrences like disk, file system, timezone, keyboard layout, user name, password, etc.
# @stdout Output routed to startup.log
# @stderror Output routed to startup.log
## Cleaning the TTY.
clear

## (colours for text banners).
RED='\033[0;31m'
BLUE='\033[0;34m'  
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'     ## No Color

## ---------------------------------------------------------------------------
## The Function begin here..

## For printing out the info banners
# @description Print a title with a message.
print_the () {
    
    ## syntax use
    ## print_the info "Some important message"
    ## print_the error "Some important error"

    local info=$2
    local arg1=$1

    if [ "$arg1" == "info" ]; then
        color=${GREEN}
    elif [ "$arg1" == "error" ]; then 
        color=${RED}
    else
        color=${RED} 
        info="Error with the Title check your input"
    fi

    echo -ne "
    ${BLUE}-------------------------------------------------------------------------
               ${color} $info
    ${BLUE}-------------------------------------------------------------------------
    ${RESET}"
}
# @description Print a line with a title.
print_line () {

    ## syntax use
    ## print_line info "Some important message"
    ## print_line error " Some important error"

    local arg2=$1
    local pl=$2

    if [ "$arg2" == "info" ]; then
        color=${GREEN}
    elif [ "$arg2" == "error" ]; then 
        color=${RED}
    else
        color=${RED} 
        info="Error with the Title check your input"
    fi

    echo -ne "
    ${color} $pl
    ${RESET}"
}
# @description Logo banner for the script.
logo () {
    # This will display the Logo banner and a message

    logo_message=$1

    echo -ne "
    ${BLUE}-------------------------------------------------------------------------
    ${GREEN}
     █████╗ ██████╗  ██████╗██╗  ██╗     ██╗████████╗
    ██╔══██╗██╔══██╗██╔════╝██║  ██║     ██║╚══██╔══╝
    ███████║██████╔╝██║     ███████║     ██║   ██║   
    ██╔══██║██╔══██╗██║     ██╔══██║     ██║   ██║   
    ██║  ██║██║  ██║╚██████╗██║  ██║     ██║   ██║    ██║
    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝     ╚═╝   ╚═╝   ╚══╝
    ${BLUE}------------------------------------------------------------------------
                ${GREEN} $logo_message
    ${BLUE}------------------------------------------------------------------------
    ${RESET}"
}
# @description Say thank you to Chris Titus for inspiring this code.
thanks () {
    ## This will show the Thank you banner logo and
    ## Pause for 3 sec's of thank you's 

    echo -ne "
    ${BLUE}-------------------------------------------------------------------------
    ${GREEN}
     █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
    ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
    ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
    ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
    ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
    ${BLUE}------------------------------------------------------------------------
        ${GREEN} A special thank's to Chris Titus for inspiring this code!.             
    ${BLUE}------------------------------------------------------------------------
    ${RESET}
    sleep .3
    "
}
# @description Check the config file for the option and set it.
set_option() {
    if grep -Eq "^${1}.*" "$CONFIG_FILE"; then # check if option exists
        sed -i -e "/^${1}.*/d" "$CONFIG_FILE" # delete option if exists
    fi
    echo "${1}=${2}" >> "$CONFIG_FILE" # add option
}

# @description This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.

filesystem () {
    echo -ne "
    Please Select your file system for both boot and root
    "
    options=("btrfs" "ext4" "luks" "exit")
    select_option $? 1 "${options[@]}"

    case $? in
    0) set_option FS btrfs;;
    1) set_option FS ext4;;
    2) 
        set_password "LUKS_PASSWORD"
        set_option FS luks
        ;;
    3) exit ;;
    *) echo "Wrong option please select again"; filesystem;;
    esac
}

# @description Choose whether drive is SSD or not.
drivessd () {
    echo -ne "
    Is this an ssd? yes/no:
    "

    options=("Yes" "No")
    select_option $? 1 "${options[@]}"

    case ${options[$?]} in
        y|Y|yes|Yes|YES)
        set_option MOUNT_OPTIONS "noatime,compress=zstd,ssd,commit=120";;
        n|N|no|NO|No)
        set_option MOUNT_OPTIONS "noatime,compress=zstd,commit=120";;
        *) echo "Wrong option. Try again";drivessd;;
    esac
}

# @description Disk selection for drive to be used with installation.
diskpart () {
    print_the info "DANGER!!!\n
        THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
        Please make sure you know what you are doing because
        after formatting your disk there is no way to get data back"

    PS3='
    Select the disk to install on: '
    options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

    select_option $? 1 "${options[@]}"
    disk=${options[$?]%|*}

    echo -e "\n${disk%|*} selected \n"
    set_option DISK "${disk%|*}"

    drivessd
}
# @description Install pre requisites for BTRFS-Snapper.
install_pre_req1 () {
    print_the info "Installing Prerequisites"

    print_line info "installing: gptfdisk btrfs-progs glibc btrfs-grub snap-pac snapper rsync"
    pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc btrfs-grub snap-pac snapper rsync
}
# @description Format the disk and create partitions.
disk_format () {

    print_the info "Creating the Partition"

    umount -A --recursive /mnt # make sure everything is unmounted before we start
    # disk prep
    sgdisk -Z "${DISK}" # zap all on disk
    sgdisk -a 2048 -o "${DISK}" # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "${DISK}" # partition 1 (BIOS Boot Partition)
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' "${DISK}" # partition 2 (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}" # partition 3 (Root), default start, remaining
    if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
        sgdisk -A 1:set:2 "${DISK}"
    fi
    partprobe "${DISK}" # reread partition table to ensure it is correct

    if [[ "${DISK}" =~ "nvme" ]]; then
        partition2="${DISK}p2"
        partition3="${DISK}p3"
    else
        partition2="${DISK}2"
        partition3="${DISK}3"
    fi

    print_the info "Formatting the Disk"

    if [[ "${FS}" == "btrfs" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" "${partition2}"
        mkfs.btrfs -L ROOT "${partition3}" -f
        mount -t btrfs "${partition3}" /mnt
        subvolumesetup
    elif [[ "${FS}" == "ext4" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" "${partition2}"
        mkfs.ext4 -L ROOT "${partition3}"
        mount -t ext4 "${partition3}" /mnt
    elif [[ "${FS}" == "luks" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" "${partition2}"
        # enter luks password to cryptsetup and format root partition
        echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat "${partition3}" -
        # open luks container and ROOT will be place holder 
        echo -n "${LUKS_PASSWORD}" | cryptsetup open "${partition3}" ROOT -
        # now format that container
        mkfs.btrfs -L ROOT "${partition3}"
        # create subvolumes for btrfs
        mount -t btrfs "${partition3}" /mnt
        subvolumesetup
        # store uuid of encrypted partition for grub
        echo "ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value "${partition3}")" >> "$CONFIGS_DIR/setup.conf"
    fi

    # mount target
    mkdir -p /mnt/boot/efi
    mount -t vfat -L EFIBOOT /mnt/boot/

    if ! grep -qs '/mnt' /proc/mounts; then
        echo "Drive is not mounted can not continue"
        echo "Rebooting in 3 Seconds ..." && sleep 1
        echo "Rebooting in 2 Seconds ..." && sleep 1
        echo "Rebooting in 1 Second ..." && sleep 1
        reboot now
    fi
}

# @description Creates the btrfs subvolumes. 
createsubvolumes () {
    # make filesystems
    print_the info "Creating Filesystems"
    print_line info "Creating subvolumes: @, @home, @var, @tmp, @.snapshots"
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@.snapshots
}

# @description Mount all btrfs subvolumes after root has been mounted.
mountallsubvol () {
    print_the info "Creating the fstab and mounting the subvolumes"
    mount -o "${MOUNT_OPTIONS},subvol=@home" "${partition3}" /mnt/home
    mount -o "${MOUNT_OPTIONS},subvol=@tmp" "${partition3}" /mnt/tmp
    mount -o "${MOUNT_OPTIONS},subvol=@var" "${partition3}" /mnt/var
    mount -o "${MOUNT_OPTIONS},subvol=@.snapshots" "${partition3}" /mnt/.snapshots
}

# @description BTRFS subvolume creation and mounting. 
subvolumesetup () {
    # create nonroot subvolumes
    createsubvolumes     
    # unmount root to remount with subvolume 
    umount /mnt
    # mount @ subvolume
    mount -o "${MOUNT_OPTIONS},subvol=@" "${partition3}" /mnt
    # make directories home, .snapshots, var, tmp
    mkdir -p /mnt/{home,var,tmp,.snapshots}
    # mount subvolumes
    mountallsubvol
}
# @description Enable important services for BTRFS-Snapper.
ena_essential_services () {

    print_the info "Enabling Essential Services"

    # Enabling various services.
    print_line info "Enabling automatic snapshots, BTRFS scrubbing and systemd-oomd."
    services=(snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfsd.service systemd-oomd)
    for service in "${services[@]}"; do
        systemctl enable "$service" --root=/mnt &>/dev/null
    done
    
}
# @description Set up grub hooks to backup /boot when pacman transactions are made.
setup_grub_hooks () {
    # Boot backup hook.
    print_the info "Configuring /boot backup when pacman transactions are made."
    mkdir /mnt/etc/pacman.d/hooks
    cat > /mnt/etc/pacman.d/hooks/50-bootbackup.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF
}

# @description Verify that the OS is Arch Linux.
arch_check() {
    if [[ ! -e /etc/arch-release ]]; then
        print_line error "ERROR! This script must be run in Arch Linux!\n"
        exit 0
    fi
}
# @description Check if pacman is available to use.
pacman_check() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        print_line error "ERROR! Pacman is blocked."
        print_line info "If not running remove /var/lib/pacman/db.lck.\n"
        exit 0
    fi
}
# @description Create selection menu for user to choose options.
select_option() {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "$2   $1 "; }
    print_selected()   { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    get_cursor_col()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${COL#*[}; }
    key_input()         {
                        local key
                        IFS= read -rsn1 key 2>/dev/null >&2
                        if [[ $key = ""      ]]; then echo enter; fi;
                        if [[ $key = $'\x20' ]]; then echo space; fi;
                        if [[ $key = "k" ]]; then echo up; fi;
                        if [[ $key = "j" ]]; then echo down; fi;
                        if [[ $key = "h" ]]; then echo left; fi;
                        if [[ $key = "l" ]]; then echo right; fi;
                        if [[ $key = "a" ]]; then echo all; fi;
                        if [[ $key = "n" ]]; then echo none; fi;
                        if [[ $key = $'\x1b' ]]; then
                            read -rsn2 key
                            if [[ $key = [A || $key = k ]]; then echo up;    fi;
                            if [[ $key = [B || $key = j ]]; then echo down;  fi;
                            if [[ $key = [C || $key = l ]]; then echo right;  fi;
                            if [[ $key = [D || $key = h ]]; then echo left;  fi;
                        fi 
    }

    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0
        
        curr_idx=$(( $curr_col + $curr_row * $colmax ))
        
        for option in "${options[@]}"; do

            row=$(( $idx/$colmax ))
            col=$(( $idx - $row * $colmax ))

            cursor_to $(( $startrow + $row + 1)) $(( $offset * $col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_selected "$option"
            else
                print_option "$option"
            fi
            ((idx++))
        done
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local return_value=$1
    local lastrow=$(get_cursor_row)
    local lastcol=$(get_cursor_col)
    local startrow=$(($lastrow - $#))
    local startcol=1
    local lines=$(tput lines)
    local cols=$(tput cols) 
    local colmax=$2
    local offset=$(( $cols / $colmax ))

    local size=$4
    shift 4

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local active_row=0
    local active_col=0
    while true; do
        print_options_multicol $active_col $active_row 
        # user key control
        case $(key_input) in
            enter)  break;;
            up)     ((active_row--));
                    if [ $active_row -lt 0 ]; then active_row=0; fi;;
            down)   ((active_row++));
                    if [ $active_row -ge $(( ${#options[@]} / $colmax ))  ]; then active_row=$(( ${#options[@]} / $colmax )); fi;;
            left)     ((active_col=$active_col - 1));
                    if [ $active_col -lt 0 ]; then active_col=0; fi;;
            right)     ((active_col=$active_col + 1));
                    if [ $active_col -ge $colmax ]; then active_col=$(( $colmax - 1 )) ; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $(( $active_col + $active_row * $colmax ))
}
# @description Create and copy the snapper configuration file.
create_and_copy_snapper_config() {
    local filename="root"
    local snapper_dir="/etc/snapper/configs"

    # Create the text file
    echo "
    # /etc/snapper/configs/root
    # subvolume to snapshot
    SUBVOLUME="/"

    # filesystem type
    FSTYPE="btrfs"

    # btrfs qgroup for space aware cleanup algorithms
    QGROUP=""

    # fraction or absolute size of the filesystems space the snapshots may use
    SPACE_LIMIT="0.5"

    # fraction or absolute size of the filesystems space that should be free
    FREE_LIMIT="0.2"

    # users and groups allowed to work with config
    ALLOW_USERS=""
    ALLOW_GROUPS="wheel"

    # sync users and groups from ALLOW_USERS and ALLOW_GROUPS to .snapshots
    # directory
    SYNC_ACL="yes"

    # start comparing pre- and post-snapshot in background after creating
    # post-snapshot
    BACKGROUND_COMPARISON="yes"

    # run daily number cleanup
    NUMBER_CLEANUP="yes"

    # limit for number cleanup
    NUMBER_MIN_AGE="3600"
    NUMBER_LIMIT="10"
    NUMBER_LIMIT_IMPORTANT="10"

    # create hourly snapshots
    TIMELINE_CREATE="yes"

    # cleanup hourly snapshots after some time
    TIMELINE_CLEANUP="yes"

    # limits for timeline cleanup
    TIMELINE_MIN_AGE="3600"
    TIMELINE_LIMIT_HOURLY="5"
    TIMELINE_LIMIT_DAILY="7"
    TIMELINE_LIMIT_WEEKLY="0"
    TIMELINE_LIMIT_MONTHLY="0"
    TIMELINE_LIMIT_QUARTERLY="0"
    TIMELINE_LIMIT_YEARLY="0"

    # cleanup empty pre-post-pairs
    EMPTY_PRE_POST_CLEANUP="yes"

    # limits for empty pre-post-pair cleanup
    EMPTY_PRE_POST_MIN_AGE="3600"
    " > "$filename"

    # Copy to snapper directory
    sudo mv "$filename" "$snapper_dir"
}
# @description Create a snapper configuration and update /etc/conf.d/snapper
snapper_root_config() {
    local config_name="root"
    local content="## Path: System/Snapper
## Type:        string
## Default:     \"\"
# List of snapper configurations.
SNAPPER_CONFIGS=\"$config_name\""

    # Create the text file
    echo "$content" > snapper.txt

    # Move to /etc/conf.d/snapper
    sudo mv snapper.txt /etc/conf.d/snapper
}

## ^^^ The function are all above
## ----------------------------------------------------------------------------------------
## Starting the script

## Prepare the system, create tempoary config file

# @setting CONFIG_FILE string[$CONFIGS_DIR/setup.conf] Location of setup.conf to be used by set_option and all subsequent scripts. 
CONFIG_FILE=$CONFIGS_DIR/setup.conf
if [ ! -f $CONFIG_FILE ]; then # check if file exists
    touch -f $CONFIG_FILE # create file if not exists
fi

## System Checks
arch_check
pacman_check

# @description set options in setup.conf
set_option

## 
source $CONFIGS_DIR/setup.conf
source $HOME/ArchTitus/configs/setup.conf

## Display the Thank you logo banner
thanks
## Display the goal of this script
logo "Welcome this script is made to simplify the process of installing BTRFS-Snapper.\n"
PS3="Please follow the prompts: "
clear
logo "Please select presetup settings for your system"


## Prepare the Disk/SSD
filesystem
diskpart
print_the info "Formating Disk"
disk_format

## Install the require files/apps
install_pre_req1
ena_essential_services
setup_grub_hooks
create_and_copy_snapper_config
snapper_root_config
## Arch Install on main drive


## Finishing up.
print_line info "We are all done installing BTRFS-Snapper.\n"
print_line info "Cleaning up\n"

rm -r $HOME/ArchTitus
rm -r /home/$USERNAME/ArchTitus

## Replace in the same state
cd $pwd
print_line info "You may now wish to reboot."
# exit
