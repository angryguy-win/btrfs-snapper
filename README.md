# BTRFS Snapper

This is currently a work in progress 


## Boot Arch ISO
From initial Prompt type the following commands:

```
pacman -Sy git
git clone https://github.com/angryguy-win/btrfs-snapper.git
cd btrfs-snapper
./btrfs-snapper.sh
```

## System Description
This is completely automated arch script. 
It includes prompts to select your desired disk drive to install and setup
BTRFS, Snapper, btrfs-grub, snap-pac

Snapper is a tool for managing BTRFS snapshots. It can create and restore snapshots, and provides scheduled auto-snapping. Snap-pac provides a Pacman hook that uses Snapper to create pre- and post- BTRFS snapshots triggered by use of the package manager.

Snapshots can be created manualy or whit the Timeline scheduler.
it will also prune the timeline and install snapshot automaticaly when 
they reach the posted threshold that you set in the config.

which  can be found:

```
/etc/snapper/configs/root
```

You can rollback after bad installs

If you have a major failure you can load any desired snapshot from the Grub menu.
*** Note: that all snapshot whit the exception of the current default will be READ ONLY!.
you will need to enable write priledges to the snapshot of choice.
```
snapper ls                  - List the snapshots
snapper delete 20-30        - Will delete snapshots id 20 to 30  *2* Note:
snapper rollback 20..21     - Will rollback from 20 to 21 reverse the number to chanbe back 21..20

sudo btrfs subvol show /    - Show a list of the of the Subvolumes and other info.
sudo btrfs subvol list /    - List all the subvolumes and there ID's.
sudo snapper -c root create -d "**Base system install**"    - Manual snapshots
```

*2* Note: When deleting a pre snapshot, you should always delete its corresponding post snapshot and vice versa.

*** Note:

    When taking a snapshot of @ (mounted at the root /), other subvolumes are not included in the snapshot. Even if a subvolume is nested below @, a snapshot of @ will not include it. 
    Create snapper configurations for additional subvolumes besides @ of which you want to keep snapshots.

## System rollback the 'Arch Way'
Snapper includes a rollback tool, but on Arch systems the preferred method is a manual rollback.

After booting into a snapshot mounted rw courtesy of overlayfs, mount the toplevel subvolume (subvolid=5). That is, omit any subvolid or subvol mount flags (example: an encrypted device map labelled cryptdev) ...
```
sudo mount /dev/mapper/cryptdev /mnt
```
Move the broken @ subvolume out of the way ...

```
sudo mv /mnt/@ /mnt/@.broken
```
Or simply delete the subvolume ...
```
sudo btrfs subvolume delete /mnt/@
```
Find the number of the snapshot that you want to recover ...
```
sudo grep -r '<date>' /mnt/@snapshots/*/info.xml
[...]
/.snapshots/8/info.xml:  <date>2022-08-20 15:21:53</date>
/.snapshots/9/info.xml:  <date>2022-08-20 15:22:39</date>
```
Create a read-write snapshot of the read-only snapshot taken by Snapper ...
```
sudo btrfs subvolume snapshot /mnt/@snapshots/number/snapshot /mnt/@
```
Where number is the snapshot you wish to restore as the new @.

Unmount /mnt.

Reboot and rollback!



You can proceed to install snapper-gui and btrfs-assitant after the install to help
manage the snapshot nad your btrfa drive.

# Backing-up
The tool used for backing up from BTRFS to another BTRFS is `snap-sync`. It is as simple as running

```sh
sudo snap-sync
```

And it is interactive.

However, this command fails for me after some repeated runs, so I have to use the good old rsync.

```sh
rsync -axXv --exclude-from=$HOME/.rsync/excluded.txt ~/ $EXT_HD_PATH/ (--dry-run)
```


# rollback

## For `/` (root) snapshots

```sh
sudo snapper list
sudo snapper rollback $n
sudo reboot
```

If you can't install or update because of lock file, you may need to delete it.

```sh
sudo rm /var/lib/pacman/db.lck
```

## For non-root snapshots, e.g. `/home`

If you plan to use `snapper -c home create-config /home`, consider adding these, but use a full path for $HOME (i.e. home/$USER)
- $HOME/.cache
- $HOME/.var
- $HOME/Downloads
- $HOME/.local/share/Steam
- $HOME/.local/share/containers
- $HOME/.local/share/Trash

You simply edit `/etc/fstab`.

```sh
# UUID=153398e6-a79c-4a4f-9650-bc435b6a4182	/home   btrfs   rw,noatime,compress=zstd:15,ssd,space_cache,subvolid=258,subvol=/@/home,discard=async	0 0
UUID=153398e6-a79c-4a4f-9650-bc435b6a4182	/home   btrfs   rw,noatime,compress=zstd:15,ssd,space_cache,subvolid=928,subvol=/@/home/.snapshots/1/snapshot,discard=async	0 0
```

More information can be found in the arch wiki:
```
https://wiki.archlinux.org/title/snapper
```

![alt text](image-1.png)

![alt text](image.png)

## Grub boot screen picture

![image](https://github.com/angryguy-win/btrfs-snapper/assets/162399710/8a1a028a-052e-41fc-a820-921efecb182d)

![image](https://github.com/angryguy-win/btrfs-snapper/assets/162399710/a95be1b2-1940-487b-afcd-0c875aee19c2)


