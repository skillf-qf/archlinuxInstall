#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-11-02 21:20:10
 # @LastEditTime: 2021-11-03 10:48:22
 # @FilePath: \archlinuxInstall\vmware.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

install_dir="/archlinuxInstall"
configfile="$install_dir/config/install.conf"
#logfile="$install_dir/archlinuxInstall.log"
username=`awk -F "=" '$1=="username" {print $2}' $configfile`
hostshare=`awk -F "=" '$1=="hostshare" {print $2}' $configfile`
guestshare=`awk -F "=" '$1=="guestshare" {print $2}' $configfile`

# In-kernel drivers
sed -i 's/^MODULES=()/MODULES=(vmw_balloon vmw_pvscsi vsock vmw_vsock_vmci_transport)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Open-VM-Tools
pacman -S --noconfirm open-vm-tools gtkmm3
systemctl start vmtoolsd.service
systemctl enable vmtoolsd.service
systemctl start vmware-vmblock-fuse.service
systemctl enable vmware-vmblock-fuse.service

# Xorg configuration
pacman -S --noconfirm xf86-input-vmmouse xf86-video-vmware mesa
echo "needs_root_rights=yes" > /etc/X11/Xwrapper.config

# Shared Folders with vmhgfs-fuse utility
mkdir -p /home/$username/$guestshare

cp $install_dir/config/VMware/guestshare-hostshare.service /etc/systemd/system/
sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
sed -i "s/<host-share-folder>/$hostshare/" /etc/systemd/system/guestshare-hostshare.service
sed -i "s/<guest-share-folder>/\/home\/$username\/$guestshare/" /etc/systemd/system/guestshare-hostshare.service

systemctl enable guestshare-hostshare.service

# Time synchronization
# Host machine as time source
vmware-toolbox-cmd timesync enable
hwclock --hctosys --localtime
