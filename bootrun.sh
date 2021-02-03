#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-03 10:30:26
 # @FilePath: \archlinuxInstall\bootrun.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

install_dir="$HOME/archlinuxInstall"
configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

download="$HOME/Downloads"

ssid=`awk -F "=" '$1=="ssid" {print $2}' $configfile`
psk=`awk -F "=" '$1=="psk" {print $2}' $configfile`
desktop=`awk -F "=" '$1=="desktop" {print $2}' $configfile`
network_connection_type=`awk -F "=" '$1=="network_connection_type" {print $2}' $configfile`
terminal=`awk -F "=" '$1=="terminal" {print $2}' $configfile`

# Print the string to the new terminal
# The device number of the new "terminal": /dev/pts/0
# If you want to run it locally, you can simply change it to: /dev/null or filename
terminal_id=/dev/pts/0
$terminal &
sleep 2
echo -e  "\033[33mThe final step of the installation will continue, please be patient while it completes ...\033[0m" > $terminal_id


set +e
bridge_list=`ls /sys/class/net`
# Connection Network
if [ "$network_connection_type" = "wireless" ]; then
    
    bridge=`echo $bridge_list | awk -F " " '{print $3}'`

    # set bridge
    echo `date` ": Enable the $bridge ..." >> $logfile
    while ! sudo ip link set up dev $bridge  > $terminal_id; do
	    sleep 3
    done
    echo `date` ": $bridge enabled successfully !" >> $logfile
    
    # connect wifi
    echo `date` ": Try to connect to wifi ..." >> $logfile
    while ! nmcli device wifi connect $ssid password $psk  > $terminal_id; do
	    sleep 3
    done
    echo `date` ": Successfully connected to wifi !" >> $logfile

    while ! ping -c 3 www.baidu.com > $terminal_id; do
	    sleep 3
    done
    echo `date` ": Wifi network connected !" >> $logfile

elif [ "$network_connection_type" = "wired" ]; then

    bridge=`echo $bridge_list | awk -F " " '{print $1}'`

    # set bridge
    echo `date` ": Enable the $bridge ..." >> $logfile
    while ! sudo ip link set up dev $bridge > $terminal_id; do
	    sleep 3
    done
    echo `date` ": $bridge enabled successfully !" >> $logfile

    # connect wired
    #while ! nmcli device wifi connect $ssid password $psk; do
	#    sleep 3
    #done
    
    dhcpcd $bridge
    while ! ping -c 3 www.baidu.com > $terminal_id; do
	    sleep 3
    done
    echo `date` ": Wired network connected !" >> $logfile
 
fi
set -e

# user shell
shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
if [ -n "$shell" ]; then
    echo `date` ": Install and configure the $shell for $USER ..." >> $logfile
    $install_dir/$shell.sh  > $terminal_id
fi

# yay
echo `date` ": Download and install yay ..." >> $logfile
sudo pacman -S  --noconfirm --needed base-devel git  > $terminal_id
# Speed up makepkg compilation
sudo sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/g' /etc/makepkg.conf

if [ ! -d "$download" ]; then
    mkdir -p "$download"
fi

cd $download
rm -rf $download/yay
git clone https://aur.archlinux.org/yay.git
cd $download/yay
while ! echo y | makepkg -si  > $terminal_id; do
    sleep 3
done
echo `date` ": yay installation complete !" >> $logfile

# Remove the auto start service
echo `date` ": Remove the auto start service ..." >> $logfile
systemctl --user disable bootrun.service  > $terminal_id
rm -rf $HOME/.config/systemd/user/*  > $terminal_id

echo `date` ": Set sudo permissions to have a password ..." >> $logfile
sudo sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers 

cat >> $logfile <<EOF

The archLinux and $desktop installation is complete !

Enjoy!

EOF

reboot
