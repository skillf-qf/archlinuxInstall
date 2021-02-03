#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-03 08:40:16
 # @FilePath: \archlinuxInstall\bootrun.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

install_dir="$HOME/archlinuxInstall"
configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

download="$HOME/Downloads"

ssid=`awk -F "=" '$1=="ssid" {print $2}' $configfile`
psk=`awk -F "=" '$1=="psk" {print $2}' $configfile`
desktop=`awk -F "=" '$1=="desktop" {print $2}' $configfile`
type=`awk -F "=" '$1=="compute" {print $2}' $configfile`

set +e
bridge_list=`ls /sys/class/net`
# Connection Network
if [ "$type" = "laptop" ]; then
    
    bridge=`echo $bridge_list | awk -F " " '{print $3}'`

    # set bridge
    echo `date` ": Enable the $bridge ..." >> $logfile
    while ! sudo ip link set up dev $bridge; do
	    sleep 3
    done
    echo `date` ": $bridge enabled successfully !" >> $logfile
    
    # connect wifi
    echo `date` ": Try to connect to wifi ..." >> $logfile
    while ! nmcli device wifi connect $ssid password $psk; do
	    sleep 3
    done
    echo `date` ": Successfully connected to wifi !" >> $logfile

    while ! ping -c 3 www.baidu.com; do
	    sleep 3
    done
    echo `date` ": Wifi network connected !" >> $logfile

elif [ "$type" = "desktop" ]; then

    bridge=`echo $bridge_list | awk -F " " '{print $1}'`

    # set bridge
    echo `date` ": Enable the $bridge ..." >> $logfile
    while ! sudo ip link set up dev $bridge; do
	    sleep 3
    done
    echo `date` ": $bridge enabled successfully !" >> $logfile

    # connect wired
    #while ! nmcli device wifi connect $ssid password $psk; do
	#    sleep 3
    #done
    
    dhcpcd $bridge
    while ! ping -c 3 www.baidu.com; do
	    sleep 3
    done
    echo `date` ": Wired network connected !" >> $logfile
 
fi
set -e

# user shell
shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
if [ -n "$shell" ]; then
    echo `date` ": Install and configure the $shell for $USER ..." >> $logfile
    $install_dir/$shell.sh
fi

# yay
echo `date` ": Download and install yay ..." >> $logfile
sudo pacman -S  --noconfirm --needed base-devel git
# Speed up makepkg compilation
sudo sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/g' /etc/makepkg.conf

if [ ! -d "$download" ]; then
    mkdir -p "$download"
fi

cd $download
rm -rf $download/yay
git clone https://aur.archlinux.org/yay.git
cd $download/yay
while ! echo y | makepkg -si; do
    sleep 3
done
echo `date` ": yay installation complete !" >> $logfile

# Remove the auto start service
echo `date` ": Remove the auto start service ..." >> $logfile
systemctl --user disable bootrun.service
rm -rf $HOME/.config/systemd/user/*

echo `date` ": Set sudo permissions to have a password ..." >> $logfile
sudo sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers 

cat >> $logfile <<EOF

The archLinux and $desktop installation is complete !

Enjoy!

EOF
