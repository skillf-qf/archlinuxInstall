#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-24 20:22:07
 # @LastEditTime: 2021-01-28 00:21:41
 # @FilePath: \archlinuxInstall\chrootInstall.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

config_dir="/chrootinstall/"
install_config="/chrootinstall/install.conf"

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

# Network configuration
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
echo y | pacman -S grub

if ls /sys/firmware/efi/efivars > /dev/null; then
    # UEFI systems
    echo y | pacman -S efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    # BIOS systems
    boot=$(echo `awk -F "=" '$1=="boot" {print $2}' $install_config` | sed 's/[0-9]*$//')
    grub-install --target=i386-pc /dev/$boot
fi

# MS Windows
system=`awk -F "=" '$1=="system" {print $2}' $install_config`
if [ "$system" = "dual" ]; then
    echo y | pacman -S os-prober
    os-prober
fi

# Microcode
cpu_processor=`lscpu | grep "Intel"`
if [ -n "$cpu_processor" ]; then
    echo y | pacman -S intel-ucode
else
    echo y | pacman -S amd-ucode
fi

# Generate the main configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Adduser
username=`awk -F "=" '$1=="username" {print $2}' $install_config`
userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' $install_config`

useradd -m -g users -G wheel -s /bin/bash $username
echo $username:$userpasswd | chpasswd

## yay
# echo -e "\n" y | pacman -S --needed base-devel git
#
#sed -i 's/^#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$(nproc)\"/g' /etc/makepkg.conf
#
#download_dir="$HOME/download/"
#  if [ ! -d "$download_dir" ]; then
#        mkdir -p "$download_dir"
#    fi
#current_dir=`pwd`
#cd $download_dir
#git clone https://aur.archlinux.org/yay.git
#cd $download_dir/yay
#
#makepkg -si
#cd $current_dir


#TODO ：安装网络配置





desktop=`awk -F "=" '$1=="desktop" {print $2}' $install_config`
if [ -n "$desktop" ]; then
    $config_dir/$desktop.sh
else
    echo -e "The archLinux minimal system installation is complete !\n"
fi
