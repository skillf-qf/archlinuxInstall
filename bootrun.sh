#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-02 23:31:15
 # @FilePath: \archlinuxInstall\bootrun.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

install_dir="$HOME/chrootinstall"
configfile="$install_dir/config/install.conf"
user=`awk -F "=" '$1=="username" {print $2}' $configfile`
#userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' $configfile`

download="$HOME/Downloads"

ssid=`awk -F "=" '$1=="ssid" {print $2}' $configfile`
psk=`awk -F "=" '$1=="psk" {print $2}' $configfile`
desktop=`awk -F "=" '$1=="desktop" {print $2}' $configfile`
type=`awk -F "=" '$1=="compute" {print $2}' $configfile`

set +e
echo `date` ": ##########################################" >> $HOME/bootrun.log
# Connection Network
if [ "$type" = "laptop" ]; then
    
    bridge=`echo $bridge_list | awk -F " " '{print $3}'`

    # set bridge
    while ! sudo ip link set up dev $bridge; do
	    sleep 3
    done
    echo `date` ": Start the $bridge successfully!" >> $HOME/bootrun.log
    
    # connect wifi
    while ! nmcli device wifi connect $ssid password $psk; do
	    sleep 3
    done

    while ! ping -c 3 www.baidu.com; do
	    sleep 3
    done
    echo `date` ": WiFi Connection Successfully!" >> $HOME/bootrun.log

elif [ "$type" = "desktop" ]; then

    bridge=`echo $bridge_list | awk -F " " '{print $1}'`

    # set bridge
    while ! sudo ip link set up dev $bridge; do
	    sleep 3
    done
    echo `date` ": Start the $bridge successfully!" >> $HOME/bootrun.log
    
    # connect wired
    while ! nmcli device wifi connect $ssid password $psk; do
	    sleep 3
    done

    while ! ping -c 3 www.baidu.com; do
	    sleep 3
    done
    echo `date` ": Wired Connection Successfully!" >> $HOME/bootrun.log
 
fi
set -e

# user shell
shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
if [ "$shell" = "ohmyzsh" ] || [ -z "$shell" ]; then
    $install_dir/ohmyzsh.sh
fi

# yay
sudo pacman -S  --noconfirm --needed base-devel git
# Speed up makepkg compilation
sudo sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/g' /etc/makepkg.conf

if [ ! -d "$download" ]; then
    mkdir -p "$download"
fi

cd $download
git clone https://aur.archlinux.org/yay.git
cd $download/yay
echo y | makepkg -si

# Remove the auto start service
sudo systemctl --user disable bootrun.service
sudo rm -rf /home/$username/.config/systemd/user/*

sudo sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers 

cat >> $HOME/bootrun.log <<EOF

The archLinux and $desktop installation is complete !

Enjoy!

EOF
