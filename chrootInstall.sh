#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-24 20:22:07
 # @LastEditTime: 2021-11-12 11:51:31
 # @FilePath: \archlinuxInstall\chrootInstall.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

install_dir="/archlinuxInstall"
configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

# Time zone
echo `date` ": Set the time zone ..." >> $logfile
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo `date` ": Run hwclock to generate /etc/adjtime ..." >> $logfile
hwclock --systohc

# Localization
echo `date` ": Setting the Localized Language ..." >> $logfile
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN.GB18030/zh_CN.GB18030/' /etc/locale.gen
sed -i 's/^#zh_CN.GBK/zh_CN.GBK/' /etc/locale.gen
sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN GB2312/zh_CN GB2312/' /etc/locale.gen

echo `date` ": locale-gen save the file, and generate the locale ..." >> $logfile
locale-gen

echo `date` ": LANG=en_US.UTF-8 setting the system locale ..." >> $logfile
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# localhost Network configuration
hostname=`awk -F "=" '$1=="hostname" {print $2}' $configfile`
echo $hostname > /etc/hostname
echo `date` ": Create the hostname file ..." >> $logfile

echo `date` ": Add matching entries to hosts ..." >> $logfile
cat >> /etc/hosts <<EOF
127.0.0.1    localhost
::1               localhost
127.0.1.1    $hostname.localdomain	$hostname
EOF

# Microcode
[[ `lscpu | grep Intel` ]] && cpu="intel"
[[ `lscpu | grep AMD` ]] && cpu="amd"
pacman -S --noconfirm --needed $cpu-ucode
echo `date` ": $cpu Microcode installed successfully !" >> $logfile

# Enable the VM shared folder
virtualmachine=`awk -F "=" '$1=="virtualmachine" {print $2}' $configfile`
if [ -n "$virtualmachine" ]; then
    echo `date` ": Enable $virtualmachine shared folders ..." >> $logfile
    echo -e "\033[33Enable $virtualmachine shared folders ...\033[0m\n"
    chmod +x $install_dir/$virtualmachine.sh
    $install_dir/$virtualmachine.sh
    echo `date` ": The $virtualmachine shared folder is enabled successfully !" >> $logfile
    echo -e "\033[32mThe $virtualmachine shared folder is enabled successfully !\033[0m\n"
fi

# Root password
rootpasswd=`awk -F "=" '$1=="rootpasswd" {print $2}' $configfile`
echo root:$rootpasswd | chpasswd
echo `date` ": Set the password for the root account !" >> $logfile

# Boot loader
bootloader="grub"
if ls /sys/firmware/efi/efivars > /dev/null; then bootloader="refind"; fi
chmod +x $install_dir/$bootloader.sh
$install_dir/$bootloader.sh

# Adduser
username=`awk -F "=" '$1=="username" {print $2}' $configfile`
userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' $configfile`

useradd -m -g users -G wheel -s /bin/bash $username
echo $username:$userpasswd | chpasswd
echo `date` ": Create a user account and set a password !" >> $logfile

# ALSA
# ALSA is a set of built-in Linux kernel modules. Therefore, manual installation is not necessary.
# alsa-utils contains :
#   alsamixer : provides a more intuitive ncurses based interface for audio device configuration.
#   amixer :  a shell command to change audio settings,
pacman -S --noconfirm --needed alsa-utils
echo `date` ": Install the sound card driver alsa-utils !" >> $logfile

# GPU open source
# Intel
if lspci | grep VGA | grep Intel; then
    pacman -S --noconfirm --needed xf86-video-intel
    echo `date` ": Install Intel GPU Open Source Driver \"xf86-video-intel\" !" >> $logfile
fi
# AMD
if lspci | grep VGA | grep AMD; then
    pacman -S --noconfirm --needed xf86-video-amdgpu
    echo `date` ": Install AMD GPU Open Source Driver \"xf86-video-amdgpu\" !" >> $logfile
fi
# NVIDIA
if lspci | grep VGA | grep NVIDIA; then
    pacman -S --noconfirm --needed nvidia
    echo `date` ": Install NVIDIA GPU Open Source Driver \"nvidia\" !" >> $logfile
fi

 # The Chinese Arch Linux Community Warehouse
echo `date` ": Add Arch Linux community repository in China !" >> $logfile
cat >> /etc/pacman.conf <<EOF
[archlinuxcn]
SigLevel = Optional TrustAll
# Tsinghua University
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF

# sudo
echo `date` ": Install sudo and set sudo permissions to be password-free ..." >> $logfile
pacman -Syyy --noconfirm --needed sudo
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# NetworkManager
echo `date` ": Install the NetworkManager ..." >> $logfile
pacman -S --noconfirm --needed networkmanager network-manager-applet nm-connection-editor dhcpcd
echo `date` ": The installation of NetworkManager is complete !" >> $logfile
echo `date` ": Enable NetworkManager and dhcpcd, and disable service NetworkManager-wait-online ..." >> $logfile
systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl disable NetworkManager-wait-online

# desktop
desktop=`awk -F "=" '$1=="desktop" {print $2}' $configfile`
if [ -n "$desktop" ]; then
    echo `date` ": Start the installation and configuration of $desktop ..." >> $logfile
    chmod +x $install_dir/$desktop.sh
    $install_dir/$desktop.sh
else
    echo -e "The archLinux minimal system installation is complete !\n"
    echo `date` ": The archLinux minimal system installation is complete !" >> $logfile
fi

# other software
software_list=`awk -F "=" '$1=="software" {print $2}' $configfile`
echo `date` ": Start installing additional packages..." >> $logfile
echo -e "\033[33mStart installing additional packages...\033[0m\n"
pacman -Fy
for package in $software_list; do
    pacman -F $package && \
    { pacman -S --noconfirm $package; \
    echo `date` ": The $package package is successfully installed !" >> $logfile; } || \
    echo `date` ": The $package package does not exist !" >> $logfile
done
echo `date` ": All additional packages have been installed !" >> $logfile
echo -e "\n\n\033[32mAll additional packages have been installed !\033[0m\n"


# Touchpad libinput (laptop)
computer_platform=`awk -F "=" '$1=="computer_platform" {print $2}' $configfile`
if [ "$computer_platform" = "laptop" ]; then
    echo `date` ": Install and configure the TouchPad ..." >> $logfile
    pacman -S --noconfirm --needed xf86-input-libinput xorg-xinput
    # default configuration from /usr/share/X11/xorg.conf.d/40-libinput.conf
    if [ -s "$install_dir/config/touchpad/30-touchpad.conf"  ]; then
        cp $install_dir/config/touchpad/30-touchpad.conf /etc/X11/xorg.conf.d/
    else
        cp /usr/share/X11/xorg.conf.d/40-libinput.conf /etc/X11/xorg.conf.d/30-touchpad.conf
        chmod +x $install_dir/deleteline.sh
        $install_dir/deleteline.sh /etc/X11/xorg.conf.d/30-touchpad.conf  "^Section"
        cat >> /etc/X11/xorg.conf.d/30-touchpad.conf <<EOF
Section "InputClass"
        Identifier "touchpad"
        Driver "libinput"
        MatchDevicePath "/dev/input/event*"
        MatchIsTouchpad "on"
        Option "Tapping" "on"
        Option "DisableWhileTyping" "on"
        Option "ScrollMethod" "twofinger"
        Option "TappingDrag" "on"
EndSection
EOF
    echo `date` ": The TouchPad installation and configuration is complete !" >> $logfile
    fi
    #TODO ：Bluetooth（laptop）
    #pacman -S --noconfirm --needed bluez bluez-utils blueman bluedevil

fi

# root shell
shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
if [ -n "$shell" ]; then
    echo `date` ": Install and configure the $shell for $USER ..." >> $logfile
    chmod +x $install_dir/$shell.sh
    $install_dir/$shell.sh
fi

# Create the first boot configuration service
echo `date` ": Create the first boot configuration servicee ..." >> $logfile
rm -rf /home/$username/.config/systemd
mkdir -p /home/$username/.config/systemd/user/default.target.wants
cp $install_dir/config/service/bootrun.service /home/$username/.config/systemd/user/bootrun.service
ln -s /home/$username/.config/systemd/user/bootrun.service /home/$username/.config/systemd/user/default.target.wants/bootrun.service

# Import DISPLAY variable into systemd
# Solution to open the terminal error : "can't open display"
# step 1. Add the DISPLAY variable file to all user services folders
# step 2. Import the DISPLAY variable into systemd in the startup script (eg: bootrun.sh) and open the terminal with a delay of a few seconds
mkdir -p /home/$username/.config/environment.d
echo "DISPLAY=:0" > /home/$username/.config/environment.d/display.conf

# Copy the file to the user folder
echo `date` ": Copy the installation script to the /home/$username$install_dir ..." >> $logfile
rm -rf /home/$username$install_dir
cp -r $install_dir /home/$username/

# Change the file user permissions in the user's home directory
echo `date` ": Change the file \"$username:users\" permissions in the user's home directory ..." >> $logfile
chown -R $username:users /home/$username
# Delete install directory
rm -rf $install_dir
