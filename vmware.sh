#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-11-02 21:20:10
 # @LastEditTime: 2021-12-09 17:26:59
 # @FilePath: \archlinuxInstall\vmware.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

source /archlinuxInstall/function.sh

servicename="$hostshare-$guestshare"

# In-kernel drivers
sed -i 's/^MODULES=()/MODULES=(vmw_balloon vmw_pvscsi vsock vmw_vsock_vmci_transport)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Open-VM-Tools
## To enable copy and paste between host and guest "gtkmm3" is required.
pacman -S --noconfirm open-vm-tools gtkmm3 xorg-xinit

## Service responsible for the Virtual Machine status report.
systemctl start vmtoolsd.service
systemctl enable vmtoolsd.service

##  Tool to enable clipboard sharing (copy/paste) between host and guest.
cp /etc/X11/xinit/xinitrc /home/$username/.xinitrc
### Delete the last five lines
deleteline /home/$username/.xinitrc "twm &"
add_startup 'vmware-user' 'vmware-user &'

## Filesystem utility. Enables drag & drop functionality between host and guest through FUSE (Filesystem in Userspace).
systemctl start vmware-vmblock-fuse.service
systemctl enable vmware-vmblock-fuse.service

# Xorg configuration
pacman -S --noconfirm xf86-input-vmmouse xf86-video-vmware mesa
echo "needs_root_rights=yes" > /etc/X11/Xwrapper.config

# Utility for mounting "vmhgfs-fuse" shared folders
mkdir -p /home/$username/$guestshare
# Change the owner permission of a shared folder
chown -R $username:users /home/$username/$guestshare
sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
cat > /etc/systemd/system/$servicename.service <<EOF
[Unit]
Description=Load VMware shared folders
Requires=vmware-vmblock-fuse.service
After=vmware-vmblock-fuse.service
ConditionPathExists=.host:/$hostshare
ConditionVirtualization=vmware

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/vmhgfs-fuse -o allow_other -o auto_unmount .host:/$hostshare /home/$username/$guestshare

[Install]
WantedBy=multi-user.target
EOF

# The automatic mounting service is enabled
systemctl enable $servicename.service

# Time synchronization
## Host machine as time source
vmware-toolbox-cmd timesync enable
hwclock --hctosys --localtime

# Virtunal resolution
add_startup 'xrandr --output' 'xrandr --output Virtual1 --mode 1920x1080 --rate 60'
