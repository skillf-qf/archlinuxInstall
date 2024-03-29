#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime : 2022-03-26 21:50:10
 # @FilePath     : \archlinuxInstall\bootrun.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

# step 2. Import the DISPLAY variable into systemd in the startup script (eg: bootrun.sh) and open the terminal with a delay of a few seconds
systemctl --user import-environment
sleep 5

install_dir="$HOME/archlinuxInstall"
download="$HOME/Downloads"
source $install_dir/function.sh


# Print the string to the new terminal
# The device number of the new "terminal": /dev/pts/0
# If you want to run it locally, you can simply change it to: /dev/null or filename
terminal_id='/dev/pts/0'
$terminal &
sleep 2
sudo echo -e  "\033[33mThe final step of the installation will continue, please be patient while it completes ...\033[0m" > $terminal_id

bridge_list=`ls /sys/class/net`
# Connection Network
set +e
if [ "$network_connection_type" = "wireless" ]; then

    bridge=`echo $bridge_list | awk -F " " '{print $3}'`

    # set bridge
    echo `date` ": Enable the $bridge ..." >> $logfile

    repeat sudo ip link set up dev $bridge  > $terminal_id
    echo `date` ": $bridge enabled successfully !" >> $logfile

    # connect wifi
    echo `date` ": Try to connect to wifi ..." >> $logfile
    repeat nmcli device wifi connect $ssid password $psk > $terminal_id
    echo `date` ": Successfully connected to wifi !" >> $logfile

    repeat ping -c 3 www.baidu.com > $terminal_id
    echo `date` ": Wifi network connected !" >> $logfile

elif [ "$network_connection_type" = "wired" ]; then

    bridge=`echo $bridge_list | awk -F " " '{print $1}'`

    # set bridge
    echo `date` ": Enable the $bridge ..." >> $logfile
    repeat sudo ip link set up dev $bridge > $terminal_id
    echo `date` ": $bridge enabled successfully !" >> $logfile

    dhcpcd $bridge
    repeat ping -c 3 www.baidu.com > $terminal_id
    echo `date` ": Wired network connected !" >> $logfile

fi
set -e
# user shell
if [ -n "$shell" ]; then
    echo `date` ": Install and configure the $shell for $USER ..." >> $logfile
    sudo echo -e "\033[33mInstall and configure the $shell for $USER ...\033[0m" > $terminal_id
    chmod +x $install_dir/$shell.sh
    $install_dir/$shell.sh  > $terminal_id
fi

# yay
echo `date` ": Download and install yay ..." >> $logfile
sudo echo -e "\033[33mDownload and install yay ...\033[0m" > $terminal_id
sudo pacman -S  --noconfirm --needed base-devel git yay  > $terminal_id

# Speed up makepkg compilation
sudo sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/' /etc/makepkg.conf

# Remove the auto start service
echo `date` ": Remove the auto start service ..." >> $logfile
systemctl --user disable bootrun.service  > $terminal_id
rm -rf $HOME/.config/systemd/user/*  > $terminal_id

echo `date` ": Set sudo permissions to have a password ..." >> $logfile
sudo sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

cat >> $logfile <<EOF

The archLinux and $desktop installation is complete !

Enjoy!

EOF

echo -e  "\n\nThe archLinux and $desktop installation is complete !"
echo -e  "\n\nEnjoy!\n\n\n"

# Reload
if [ $desktop = "bspwm" ]; then
    echo -e  "\033[33mRestart the bspwm ...\033[0m\n\n" > $terminal_id
    sleep 3
    bspc quit
else
    echo -e  "\033[33mSystem reboot ...\033[0m\n\n" > $terminal_id
    sleep 3
    reboot
fi
