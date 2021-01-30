#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-24 20:22:07
 # @LastEditTime: 2021-01-31 02:12:25
 # @FilePath: \archlinuxInstall\chrootInstall.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

config_dir="/chrootinstall/"
install_config="/chrootinstall/config/install.conf"

# Time zone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

# Localization
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN.GB18030/zh_CN.GB18030/' /etc/locale.gen
sed -i 's/^#zh_CN.GBK/zh_CN.GBK/' /etc/locale.gen
sed -i 's/^#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen
sed -i 's/^#zh_CN GB2312/zh_CN GB2312/' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

# localhost Network configuration
hostname=`awk -F "=" '$1=="hostname" {print $2}' $install_config`
if [ -n "$hostname" ]; then
    echo $hostname > /etc/hostname
else
    echo "ERROR: hostname cannot be empty !"
    exit
fi

cat >> /etc/hosts <<EOF
127.0.0.1    localhost
::1               localhost
127.0.1.1    $hostname.localdomain	$hostname
EOF

# Initramfs
mkinitcpio -P

# Root password
rootpasswd=`awk -F "=" '$1=="rootpasswd" {print $2}' $install_config`
echo root:$rootpasswd | chpasswd

# Boot loader
# Verify the boot mode
pacman -S --noconfirm grub

if ls /sys/firmware/efi/efivars > /dev/null; then
    # UEFI systems
    pacman -S --noconfirm efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    # BIOS systems
    boot=$(echo `awk -F "=" '$1=="boot" {print $2}' $install_config` | sed 's/[0-9]*$//')
    grub-install --target=i386-pc /dev/$boot
fi

# MS Windows
system=`awk -F "=" '$1=="system" {print $2}' $install_config`
if [ "$system" = "dual" ]; then
    pacman -S --noconfirm os-prober
    os-prober
fi

# Microcode
cpu_processor=`lscpu | grep "Intel"`
if [ -n "$cpu_processor" ]; then
    pacman -S --noconfirm intel-ucode
else
    pacman -S --noconfirm amd-ucode
fi

# Generate the main configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Adduser
username=`awk -F "=" '$1=="username" {print $2}' $install_config`
userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' $install_config`

useradd -m -g users -G wheel -s /bin/bash $username
echo $username:$userpasswd | chpasswd

# yay
#pacman -S  --noconfirm --needed base-devel git
#
#sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/g' /etc/makepkg.conf
#
#download_dir="/home/$username/download/"
#  if [ ! -d "$download_dir" ]; then
#        mkdir -p "$download_dir"
#    fi
#current_dir=`pwd`
#cd $download_dir
#git clone https://aur.archlinux.org/yay.git
#cd $download_dir/yay
#echo y | makepkg -si
#cd $current_dir

# NetworkManager 
pacman -S --noconfirm networkmanager network-manager-applet dhcpcd
systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl disable NetworkManager-wait-online


# ALSA
# ALSA is a set of built-in Linux kernel modules. Therefore, manual installation is not necessary.
# alsa-utils contains :
#   alsamixer : provides a more intuitive ncurses based interface for audio device configuration.
#   amixer :  a shell command to change audio settings,
pacman -S --noconfirm alsa-utils  


# Touchpad libinput (laptop)
type=`awk -F "=" '$1=="compute" {print $2}' $install_config`
if [ "$type" = "laptop" ]; then
    pacman -S --noconfirm xf86-input-libinput xorg-xinput
    # default configuration from /usr/share/X11/xorg.conf.d/40-libinput.conf
    if [ -s "./config/touchpad/30-touchpad.conf"  ]; then
        cp ./config/touchpad/30-touchpad.conf /etc/X11/xorg.conf.d/
    else
        cp /usr/share/X11/xorg.conf.d/40-libinput.conf /etc/X11/xorg.conf.d/30-touchpad.conf 
        ./deleteline.sh /etc/X11/xorg.conf.d/30-touchpad.conf  "^Section"
        cat >> /etc/X11/xorg.conf.d/30-touchpad.conf <<EOF
        Section "InputClass"
                Identifier "touchpad"
                Driver "libinput"
                MatchDevicePath "/dev/input/event*"
                MatchIsPointer "on"
                Option "Tapping" "on"
                Option "DisableWhileTypeing" "on"
                Option "TappingButtonMap" "lmr"
                Option "TappingDrag" "on"
        EndSection
EOF
    fi
    #TODO ：Bluetooth（laptop）
    #pacman -S --noconfirm bluez bluez-utils blueman bluedevil

fi

# GPU open source
# Intel
if lspci | grep VGA | grep Intel; then
    pacman -S --noconfirm xf86-video-intel
# AMD
if lspci | grep VGA | grep AMD; then
    pacman -S --noconfirm xf86-video-amdgpu	
# NVIDIA
if lspci | grep VGA | grep NVIDIA; then
    pacman -S --noconfirm nvidia
fi


 # The Chinese Arch Linux Community Warehouse
cat >> /etc/pacman.conf <<EOF
[archlinuxcn]
SigLevel = Optional TrustAll
# 清华大学
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
EOF

#  sudo 
pacman -S --noconfirm sudo
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers 

#TODO ：常用应用(选装)

desktop=`awk -F "=" '$1=="desktop" {print $2}' $install_config`
if [ -n "$desktop" ]; then
    $config_dir/$desktop.sh
    echo -e "The archLinux and $desktop installation is complete !\n"
else
    echo -e "The archLinux minimal system installation is complete !\n"
fi
