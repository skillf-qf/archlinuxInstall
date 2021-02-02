#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-02 12:06:37
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
if [ "$type" = "laptop" ]; then
    sudo ip link set dev wlan0 up
    sleep 1
    nmcli device wifi connect $ssid password $psk
    sleep 3
elif [ "$type" = "desktop" ]
    sudo ip link set dev eth0 up
    sleep 1
fi

ping -c 3 www.baidu.com

# user shell
shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
if [ "$shell" = "ohmyzsh" ] || [ -z "$shell" ]; then
    $install_dir/ohmyzsh.sh
fi

# yay
#sudo pacman -S  --noconfirm --needed base-devel git
# Speed up makepkg compilation
sudo sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/g' /etc/makepkg.conf

if [ ! -d "$download" ]; then
    mkdir -p "$download"
fi

cd $download
git clone https://aur.archlinux.org/yay.git
cd $download/yay
echo y | makepkg -si

sudo rm -rf /etc/rc.local
sudo rm -rf /etc/rc.local.d
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers 

cat > $HOME/Done.txt <<EOF
\n\nThe archLinux and $desktop installation is complete !
\n\nEnjoy!
EOF