#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-24 20:22:07
 # @LastEditTime: 2021-01-24 20:58:56
 # @FilePath: \undefinedc:\Users\skillf\Desktop\archScriptbspwmNvim\iniTest\iniTest\chrootInstall.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

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
hostname=`awk -F "=" '$1=="hostname" {print $2}' ./install.conf`
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
rootpasswd=`awk -F "=" '$1=="rootpasswd" {print $2}' ./install.conf`
echo root:$rootpasswd | chpasswd

# Boot loader
# Verify the boot mode
set +e
ls /sys/firmware/efi/efivars > /dev/null
if [[ "$?" == "0" ]]; then
    # UEFI systems
    pacman -S efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    # BIOS systems
    grub-install --target=i386-pc /dev/`echo "$boot" | tr -d [:digit:]`
fi
set -e

# MS Windows
system=`awk -F "=" '$1=="system" {print $2}' ./install.conf`
if [ "$system" = "dual" ]; then
    pacman -S os-prober
    os-prober
fi

# Microcode
cpu_processor=`lscpu | grep "Intel"`
if [ -n $cpu_processor ]; then
    pacman -S intel-ucode
else
    pacman -S amd-ucode
fi

# Generate the main configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Adduser
username=`awk -F "=" '$1=="username" {print $2}' ./install.conf`
userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' ./install.conf`

useradd -m -g users -G wheel -s /bin/bash $username
echo $username:$userpasswd | chpasswd

echo -e "The ArchLinux installation was successful.\n"
