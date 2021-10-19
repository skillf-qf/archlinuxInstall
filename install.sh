#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-10-20 02:49:26
 # @FilePath: \archlinuxInstall\install.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

# Set tty font
setfont /usr/share/kbd/consolefonts/LatGrkCyr-12x22.psfu.gz

install_dir="/root/archlinuxInstall"
configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

computer_platform=`awk -F "=" '$1=="computer_platform" {print $2}' $configfile`
network_connection_type=`awk -F "=" '$1=="network_connection_type" {print $2}' $configfile`
system=`awk -F "=" '$1=="system" {print $2}' $configfile`
ssid=`awk -F "=" '$1=="ssid" {print $2}' $configfile`
psk=`awk -F "=" '$1=="psk" {print $2}' $configfile`
hostname=`awk -F "=" '$1=="hostname" {print $2}' $configfile`
username=`awk -F "=" '$1=="username" {print $2}' $configfile`
userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' $configfile`
rootpasswd=`awk -F "=" '$1=="rootpasswd" {print $2}' $configfile`
root=`awk -F "=" '$1=="root" {print $2}' $configfile`
boot=`awk -F "=" '$1=="boot" {print $2}' $configfile`
home=`awk -F "=" '$1=="home" {print $2}' $configfile`
swap=`awk -F "=" '$1=="swap" {print $2}' $configfile`

var_list="\
        computer_platform network_connection_type system ssid psk  \
        hostname username userpasswd rootpasswd \
        root boot \
        "
empty_var_list=`awk '/=/' $configfile | awk -F "=" '$2=="" {print $1}'`

not_empty_arry=()
num=0
for empty_var in $empty_var_list; do
    if [[ $var_list =~ $empty_var ]]; then
        not_empty_arry[$num]="$empty_var="
        num=`expr $num + 1`
    fi
done

if [ ${#not_empty_arry[*]} -gt 0 ]; then
    echo -e "\n===========================================================================================\n"
    echo -e "\033[31mERROR: The following variables cannot be empty !\033[0m"
    echo -e "\033[31mPlease modify the variable in file : \033[33marchlinuxInstall/config/install.conf \033[0m\n"
    for var in ${not_empty_arry[*]}; do
        echo $var
    done
    echo -e "\n===========================================================================================\n\n"
    exit
fi

echo `date` ": ===========================================================================================" > $logfile

# Connect to the internet
if [ "$network_connection_type" = "wireless" ]; then
    if [ -n $ssid ] && [ -n $psk ] ; then
        wifiSSID=$ssid
        wifiPSK=$psk
    else
        read -r -p "The wifi ssid or wifi psk is empty. Is it automatically generated? [y/n]" confirm
        if [[ ! "$confirm" =~ ^(n|N) ]]; then
            read -r -p "Input your wifi ssid: " wifiSSID
            read -r -p "Input your wifi psk: " wifiPSK
        else
            exit
        fi
    fi
    cat > /etc/wpa_supplicant/wifi.conf <<EOF
ctrl_interface=/run/wpa_supplicant
update_config=1

network={
    ssid="$wifiSSID"
    psk="$wifiPSK"
}
EOF
    echo -e "\n\n\033[33mwifi.conf generated successfully !\033[0m\n"
    echo `date` ": wifi.conf generated successfully !" >> $logfile

    rfkill unblock wifi
    ip link set dev wlan0 up
    #  check wpa_supplicant PID
    set +e
    ps -aux|grep wpa_supplicant
    if  [ $? -eq 0 ]; then
        killall wpa_supplicant
        sleep 1
    fi
    set -e
    wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wifi.conf
    dhcpcd wlan0
    sleep 3
fi

set +e
while ! ping -c 3 www.baidu.com; do
set -e
        echo `date` ": \"ping\" tries to reconnect to the network ..." >> $logfile
        echo -e "\033[31m\"ping\" tries to reconnect to the network ...\033[0m\n"
    sleep 3
done
echo `date` ": $network_connection_type network connection successful !" >> $logfile

# Update mirrors
echo `date` ": Try to get the latest image source and sort it by speed ..." >> $logfile
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "\n##======================================================" > mirrorlist.temp

counter=0
set +e
while ! reflector --country China --latest 10 --protocol https --sort rate >> mirrorlist.temp; do
set -e
    if [ $counter -lt 10 ];then
    	echo `date` ": \"reflector\" tries to reconnect to the network ..." >> $logfile
    	echo -e "\033[31m\"reflector\" tries to reconnect to the network ...\033[0m\n"
        sleep 3
        counter=`expr $counter + 1`
    else
        echo -e "\033[31mERROR: Network error, please check network and try again !\033[0m"
        exit
    fi
done

#reflector --country China --latest 10 --protocol https --sort rate >> mirrorlist.temp
# If the above is not available please uncomment below and comment above as well
#curl -sSL 'https://www.archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4&use_mirror_status=on' | sed '/^## China/d; s/^#Server/Server/g' >> mirrorlist.temp

echo -e "##======================================================\n" >> mirrorlist.temp
sed -i '1r ./mirrorlist.temp' /etc/pacman.d/mirrorlist
rm mirrorlist.temp
echo `date` ": Latest image source obtained successfully !" >> $logfile

pacman -Syy

# Update the system clock
timedatectl set-ntp true
echo `date` ": Update system time successfully !" >> $logfile

# Disks
set +e
umount /dev/$boot
umount /dev/$home
umount /dev/$root
set -e
echo `date` ": Read the partition information and process the mounted partition !" >> $logfile

if [ -n "$root" ]; then
    echo y | mkfs.ext4 /dev/$root
    mount /dev/$root /mnt
    echo `date` ": Format partition /dev/$root and mount it to partition /mnt !" >> $logfile
else
    echo -e "\033[031mERROR: root partition does not exist !\033[0m"
    echo `date` ": ERROR: root partition does not exist !" >> $logfile
    exit
fi

#TODO

# booted
# 注意在EFI系统上，Windows只能安装到GPT磁盘

if ls /sys/firmware/efi/efivars > /dev/null; then
    echo `date` ": The installation target system is a single system ..." >> $logfile

    if [ "$system" = "single" ]; then
        echo y | mkfs.fat -F32 /dev/$boot
    fi
    mount /dev/$boot /mnt/boot
    echo `date` ": Partition /dev/$boot is mounted only to /mnt/boot !" >> $logfile
    # Remove everything except EFI
    rm -rf /mnt/boot/grub
    rm -rf /mnt/boot/*.img
    rm -rf /mnt/boot/*linux
else
    if echo $boot | grep nvme > /dev/null; then
        str="p[0-9]"
    else
        str="[0-9]"
    fi
    boot_disk=/dev/$(echo $boot | sed "s/$str*$//")
    if fdisk -l $boot_disk | grep gpt > /dev/null;then
        #boot_disk=/dev/$(echo $boot | sed "s/$str[0-9]*$//")
        boot_partition_number=`echo $boot | grep -Eo '[0-9]+$'`

        set +e
        biosboot_other=`fdisk -l $boot_disk | grep "BIOS boot" | awk -F " " '{if(NR==1) print $1}'`
        set -e

        if [ -n "$biosboot_other" ]; then
            biosboot_other_number=`echo $biosboot_other | grep -Eo '[0-9]+$'`
        fi

        if [ -z "$biosboot_other" ]; then
            echo "d
$boot_partition_number
n
$boot_partition_number

+1M
t
$boot_partition_number
4
w
" | fdisk $boot_disk
            partition_number=$boot_partition_number
        else
            partition_number=$biosboot_other_number
        fi

        parted $boot_disk set $partition_number bios_grub on

    fi
fi

#if ls /sys/firmware/efi/efivars > /dev/null; then
#    # UEFI systems
#    if [ ! -d "/mnt/boot" ]; then
#        mkdir -p /mnt/boot
#        echo `date` ": Create /mnt/boot mount point !" >> $logfile
#    fi
#    echo `date` ": The installation target system is dual system ..." >> $logfile
#    echo y | mkfs.fat -F32 /dev/$boot
#    mount /dev/$boot /mnt/boot
#    echo `date` ": Partition /dev/$boot is mounted only to /mnt/boot !" >> $logfile
#    # Remove everything except EFI
#    rm -rf /mnt/boot/grub
#    rm -rf /mnt/boot/*.img
#    rm -rf /mnt/boot/*linux
#
#else
#    # BIOS systems
#    if fdisk -l $boot_disk | grep gpt > /dev/null;then
#
#        if echo $boot | grep nvme > /dev/null;then
#            str="p"
#        fi
#        boot_disk=/dev/$(echo $boot | sed "s/$str[0-9]*$//")
#        boot_partition_number=`echo $boot | grep -Eo '[0-9]+$'`
#
#        biosboot_other=`fdisk -l $boot_disk | grep "BIOS boot" | awk -F " " '{if(NR==1) print $1}'`
#        if [  -n biosboot_other ]; then
#            biosboot_other_number=`echo $biosboot_other | grep -Eo '[0-9]+$'`
#        fi
#
#        if [ -z "$biosboot_other" ];then
#            echo "d
#$boot_partition_number
#n
#$boot_partition_number
#
#+1M
#t
#$boot_partition_number
#4
#w
#" | fdisk $ boot_disk
#            partition_number=$boot_partition_number
#        else
#            partition_number=$biosboot_other_number
#        fi
#
#        parted $boot_disk set $partition_number bios_grub on
#
#    fi
#fi
#
#if [ -n "$boot" ]; then
#    if [ "$system" = "single" ];then
#        echo `date` ": The installation target system is a single system ..." >> $logfile
#        echo y | mkfs.fat -F32 /dev/$boot
#        mount /dev/$boot /mnt/boot
#        echo `date` ": Partition /dev/$boot is formatted and mounted to /mnt/boot !" >> $logfile
#    elif [ "$system" = "dual" ];then
#        echo `date` ": The installation target system is dual system ..." >> $logfile
#        mount /dev/$boot /mnt/boot
#        echo `date` ": Partition /dev/$boot is mounted only to /mnt/boot !" >> $logfile
#        # Remove everything except EFI
#        rm -rf /mnt/boot/grub
#        rm -rf /mnt/boot/*.img
#        rm -rf /mnt/boot/*linux
#    fi
#else
#    echo -e "\033[31mERROR: boot partition does not exist !\033[0m"
#    echo `date` ": ERROR: boot partition does not exist !" >> $logfile
#    exit
#fi

if [ ! -d "/mnt/home" ]; then
    mkdir -p /mnt/home
    echo `date` ": Create /mnt/home mount point !" >> $logfile
fi
if [ -n "$home" ]; then
    echo y | mkfs.ext4 /dev/$home
    mount /dev/$home /mnt/home
    echo `date` ": Partition /dev/$home is formatted and mounted to /mnt/home !" >> $logfile
fi

set +e
swapstatus=`swapon -s | grep "$swap"`
set -e

if [[ -n "$swap" ]] && [[ -z "$swapstatus" ]]; then
    mkswap /dev/$swap
    swapon /dev/$swap
    echo `date` ": Create swap partition /dev/$swap and enable it !" >> $logfile
fi

# Install essential packages
pacstrap /mnt base linux linux-firmware
echo `date` ": Install the base package, Linux kernel, and firmware successfully !" >> $logfile

# Fstab
genfstab -L /mnt >> /mnt/etc/fstab
echo `date` ": Generate an fstab file !" >> $logfile

# Chroot
echo `date` ": Copy the installation script to the /mn system ..." >> $logfile
chrootinstall="/mnt/archlinuxInstall"
rm -rf $chrootinstall
mkdir -p $chrootinstall
scriptfile="chrootInstall.sh"

if [ -s $scriptfile ]; then
    cp -r ./* $chrootinstall/
else
    echo -e "\033[31mERROR: $scriptfile is empty !\033[0m"
    exit
fi
echo `date` ": Change root into the /mnt system and execute the installation script ..." >> $logfile
cp $logfile $chrootinstall/
arch-chroot /mnt /archlinuxInstall/$scriptfile
set +x

echo -e "\n\nThe system will reboot for the final configuration step !\n\n"
for time in `seq 5 -1 0`; do
    echo -e "\033[33mRestarting for the last configuration $time press Ctrl+c to stop it ...\033[0m\r\r"
    sleep 1
done

# Unmount all mount partitions
umount -R /mnt
sleep 1

reboot
