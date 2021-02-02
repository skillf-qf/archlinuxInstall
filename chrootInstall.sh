#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-24 20:22:07
 # @LastEditTime: 2021-02-02 23:22:46
 # @FilePath: \archlinuxInstall\chrootInstall.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

install_dir="/chrootinstall"
configfile="$install_dir/config/install.conf"

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
hostname=`awk -F "=" '$1=="hostname" {print $2}' $configfile`
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

# Microcode
cpu_processor=`lscpu | grep "Intel"`
if [ -n "$cpu_processor" ]; then
    pacman -S --noconfirm --needed intel-ucode
else
    pacman -S --noconfirm --needed amd-ucode
fi

# Initramfs
mkinitcpio -P

# Root password
rootpasswd=`awk -F "=" '$1=="rootpasswd" {print $2}' $configfile`
echo root:$rootpasswd | chpasswd

# Boot loader
# Verify the boot mode
pacman -S --noconfirm --needed grub

if ls /sys/firmware/efi/efivars > /dev/null; then
    # UEFI systems
    pacman -S --noconfirm --needed efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
else
    # BIOS systems
    boot=$(echo `awk -F "=" '$1=="boot" {print $2}' $configfile` | sed 's/[0-9]*$//')
    grub-install --target=i386-pc /dev/$boot
fi

# check MS Windows
system=`awk -F "=" '$1=="system" {print $2}' $configfile`
if [ "$system" = "dual" ]; then
    pacman -S --noconfirm --needed os-prober
    os-prober
    sleep 1
fi

# Generate the main configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Adduser
username=`awk -F "=" '$1=="username" {print $2}' $configfile`
userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' $configfile`

useradd -m -g users -G wheel -s /bin/bash $username
echo $username:$userpasswd | chpasswd

# ALSA
# ALSA is a set of built-in Linux kernel modules. Therefore, manual installation is not necessary.
# alsa-utils contains :
#   alsamixer : provides a more intuitive ncurses based interface for audio device configuration.
#   amixer :  a shell command to change audio settings,
pacman -S --noconfirm --needed alsa-utils  

# GPU open source
# Intel
if lspci | grep VGA | grep Intel; then
    pacman -S --noconfirm --needed xf86-video-intel
fi
# AMD
if lspci | grep VGA | grep AMD; then
    pacman -S --noconfirm --needed xf86-video-amdgpu
fi	
# NVIDIA
if lspci | grep VGA | grep NVIDIA; then
    pacman -S --noconfirm --needed nvidia
fi

 # The Chinese Arch Linux Community Warehouse
cat >> /etc/pacman.conf <<EOF
[archlinuxcn]
SigLevel = Optional TrustAll
# 清华大学
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF
pacman -Syy

#  sudo 
pacman -S --noconfirm --needed sudo
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers 
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers 

# desktop
desktop=`awk -F "=" '$1=="desktop" {print $2}' $configfile`
if [ -n "$desktop" ]; then
    $install_dir/$desktop.sh
    #echo -e "The archLinux and $desktop installation is complete !\n"
else
    echo -e "The archLinux minimal system installation is complete !\n"
fi

# other software
software_list=`awk -F "=" '$1=="software" {print $2}' $configfile`
if [ -n "$software_list" ]; then
    pacman -S --noconfirm --needed $software_list
fi

# Touchpad libinput (laptop)
type=`awk -F "=" '$1=="compute" {print $2}' $configfile`
if [ "$type" = "laptop" ]; then
    pacman -S --noconfirm --needed xf86-input-libinput xorg-xinput
    # default configuration from /usr/share/X11/xorg.conf.d/40-libinput.conf
    if [ -s "$install_dir/config/touchpad/30-touchpad.conf"  ]; then
        cp $install_dir/config/touchpad/30-touchpad.conf /etc/X11/xorg.conf.d/
    else
        cp /usr/share/X11/xorg.conf.d/40-libinput.conf /etc/X11/xorg.conf.d/30-touchpad.conf 
        $install_dir/deleteline.sh /etc/X11/xorg.conf.d/30-touchpad.conf  "^Section"
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
    #pacman -S --noconfirm --needed bluez bluez-utils blueman bluedevil

fi

# root shell
shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
if [ "$shell" = "ohmyzsh" ] || [ -z "$shell" ]; then
    $install_dir/ohmyzsh.sh
fi

# NetworkManager
pacman -S --noconfirm --needed networkmanager network-manager-applet nm-connection-editor dhcpcd
systemctl enable NetworkManager
systemctl enable dhcpcd
systemctl disable NetworkManager-wait-online

# Configure starts the configuration service for the first time
rm -rf /home/$username/.config/systemd
mkdir -p /home/$username/.config/systemd/user/default.target.wants
cp $install_dir/config/service/bootrun.service /home/$username/.config/systemd/user/bootrun.service
ln -s /home/$username/.config/systemd/user/bootrun.service /home/$username/.config/systemd/user/default.target.wants/bootrun.service

# Copy the file to the user folder 
rm -rf /home/$username/chrootinstall
cp -r /chrootinstall /home/$username/
 
# Change the file user permissions in the user's home directory
chown -R $username:users /home/$username

echo -e "The system will reboot for the final configuration step !\n"

echo -e "\n\n"
for time in `seq 5 -1 0`; do
    echo -n "Restarting for the last configuration $time press A to stop it ..."
    echo -n -e "\r\r"
    sleep 1
done

reboot