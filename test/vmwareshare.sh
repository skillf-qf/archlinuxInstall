#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-11-02 21:20:10
 # @LastEditTime: 2021-11-03 16:38:28
 # @FilePath: \undefinedc:\Users\qf132\Desktop\vmwareshare.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
set -x

# host中的共享文件夹
hostshare="host"
# guest中的共享文件夹
guestshare="/home/skillf/guest"
# ##*/ 从左向右截取最后一个 '/' 后的字符串
service=$hostshare-$(echo ${guestshare##*/}).service

# Check VMware share folder
pacman -Sy
pacman -S --noconfirm open-vm-tools
if ! vmware-hgfsclient | grep $hostshare > /dev/null; then
    echo -e "\033[031mERROR: The VMware shared folder \"$hostshare\" is not enabled !\033[0m"
    exit 0
fi

# In-kernel drivers
sed -i 's/^MODULES=()/MODULES=(vmw_balloon vmw_pvscsi vsock vmw_vsock_vmci_transport)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Open-VM-Tools
pacman -S --noconfirm gtkmm3
systemctl start vmtoolsd.service
systemctl enable vmtoolsd.service
systemctl start vmware-vmblock-fuse.service
systemctl enable vmware-vmblock-fuse.service


# Xorg configuration
pacman -S --noconfirm xf86-input-vmmouse xf86-video-vmware mesa
echo "needs_root_rights=yes" > /etc/X11/Xwrapper.config

if df | grep $guestshare$ | grep vmhgfs-fuse > /dev/null; then
	systemctl stop $service
	systemctl disable $service
	rm -rf  /etc/systemd/system/$service
	rm -rf $guestshare
fi
mkdir -p $guestshare
# 改变共享文件夹的所有者
chown -R skillf:users $guestshare

sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
cat > /etc/systemd/system/$service <<EOF
[Unit]
Description=Load VMware shared folders
Requires=vmware-vmblock-fuse.service
After=vmware-vmblock-fuse.service
ConditionPathExists=.host:/$hostshare
ConditionVirtualization=vmware

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/vmhgfs-fuse -o allow_other -o auto_unmount .host:/$hostshare $guestshare

[Install]
WantedBy=multi-user.target
EOF

systemctl start $service
systemctl enable $service

# Time synchronization
# Host machine as time source
vmware-toolbox-cmd timesync enable
hwclock --hctosys --localtime
