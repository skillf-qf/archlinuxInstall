#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-11-02 21:20:10
 # @LastEditTime: 2021-11-14 02:28:42
 # @FilePath: \archlinuxInstall\vmware.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

source $install_dir/function.sh

servicename="$hostshare-$guestshare"

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

systemctl enable $servicename.service

# Time synchronization
# Host machine as time source
vmware-toolbox-cmd timesync enable
hwclock --hctosys --localtime
