#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-02 02:04:18
 # @FilePath: \archlinuxInstall\bootrun.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

install_dir="/chrootinstall"
configfile="$install_dir/config/install.conf"
user=`awk -F "=" '$1=="username" {print $2}' $configfile`
userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' $configfile`

userhome="/home/$user"
download="$userhome/Downloads"

ssid=`awk -F "=" '$1=="ssid" {print $2}' $configfile`
psk=`awk -F "=" '$1=="psk" {print $2}' $configfile`
type=`awk -F "=" '$1=="compute" {print $2}' $configfile`

## NetworkManager
#set +e
#ps -aux|grep wpa_supplicant
#if  [ $? -eq 0 ]; then
#    sudo killall wpa_supplicant
#    sleep 2
#fi
#set -e
#
#sudo /usr/bin/systemctl disable wpa_supplicant
#sleep 1
#
#sudo /usr/bin/systemctl stop wpa_supplicant
#sleep 1
#
#if [ "$type" = "laptop" ]; then
#    nmcli device wifi connect $ssid password $psk
#    sleep 5
#fi
sleep 5
ping -c 3 www.baidu.com

# yay
#sudo pacman -S  --noconfirm --needed base-devel git

sudo sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/g' /etc/makepkg.conf

download_dir="$HOME/Download/"
if [ ! -d "$download_dir" ]; then
    mkdir -p "$download_dir"
fi
#current_dir=`pwd`
cd $download_dir
git clone https://aur.archlinux.org/yay.git
cd $download_dir/yay
echo y | makepkg -si
#cd $current_dir

sudo rm -rf /etc/rc.local
sudo rm -rf /etc/rc.local.d
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers 
