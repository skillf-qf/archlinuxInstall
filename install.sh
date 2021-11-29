#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-11-29 09:52:56
 # @FilePath: \archlinuxInstall\install.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

# Temporarily set tty1 font
# For permanent Settings, modify the /etc/vconsole.conf
setfont /usr/share/kbd/consolefonts/LatGrkCyr-12x22.psfu.gz

source ./function.sh

var_list="\
        computer_platform network_connection_type \
        hostname username userpasswd rootpasswd \
        root \
        "
if [ -z "$virtualmachine" ]; then
    if [ "$network_connection_type" == "wireless" ]; then
        var_list="$var_list ssid psk"
    fi
else
    var_list=`echo "$var_list hostshare guestshare" | \
                sed 's/computer_platform//' | sed 's/network_connection_type//'`

    network_connection_type=$virtualmachine
fi

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
    exit 0
fi

echo `date` ": ===========================================================================================" > $logfile

# Check Legacy boot
if ! ls /sys/firmware/efi/efivars > /dev/null; then
    set +e
    biosboot_other=`fdisk -l | grep NTFS | grep "*" | awk -F " " '{if(NR==1) print $1}'`
    set -e
    if [ -n "$biosboot_other" ]; then
        if [ "$biosboot_other" == "/dev/$boot" ]; then
            echo -e "\033[31mERROR: In Legacy mode, the Boot partition cannot be the same as the Windows boot partition!\033[0m"
            echo -e "\033[31mERROR: The $biosboot_other partition already exists.Please select another one !\033[0m"
            exit 0
        fi
    else
        str="[0-9]"
        if echo $root | grep nvme > /dev/null; then str="p"$str; fi
        root_disk=/dev/$(echo $root | sed "s/$str*$//")

        set +e
        biosgrub_other=`fdisk -l $root_disk | grep "BIOS boot" | awk -F " " '{if(NR==1) print $1}'`
        set -e
        if [ -z "$biosgrub_other" ]; then
            if fdisk -l $root_disk | grep gpt > /dev/null;then
                echo `date` ": The current GPT partition is under BIOS boot. The bios_grub partition is created..." >> $logfile
                echo -e "\033[33mThe current GPT partition is under BIOS boot. The bios_grub partition is created...\033[0m\n"
                root_partition_number=`echo $root | grep -Eo '[0-9]+$'`
                get_root_start_sectors=`parted $root_disk unit mb print | sed -n '8,$p' | \
                                        awk '$1 == "'$root_partition_number'" {print $2}' | sed "s/MB$//"`
                get_root_end_sectors=`parted $root_disk unit mb print | sed -n '8,$p' | \
                                        awk '$1 == "'$root_partition_number'" {print $3}' | sed "s/MB$//"`
                parted $root_disk rm $root_partition_number
                parted $root_disk mkpart primary ext4 "$get_root_start_sectors"MB "$(($get_root_end_sectors-1))"MB
                parted $root_disk mkpart primary ext3 "$(($get_root_end_sectors-1))"MB "$get_root_end_sectors"MB

                get_bios_boot_number=`parted $root_disk unit mb print | sed -n '8,$p' | \
                                        awk '$2 == "'$(($get_root_end_sectors-1))'MB" {print $1}'`

                parted $root_disk set $get_bios_boot_number bios_grub on
                echo -e "\n\n\033[32mThe bios_grub partition is created successfully !\033[0m\n"
                echo `date` ": The bios_grub partition is created successfully !" >> $logfile
            fi
        fi
    fi
fi

# Connect to the internet
if [ "$network_connection_type" == "wireless" ]; then
    cat > /etc/wpa_supplicant/wifi.conf <<EOF
ctrl_interface=/run/wpa_supplicant
update_config=1

network={
    ssid="$ssid"
    psk="$psk"
}
EOF
    echo -e "\n\n\033[32mwifi.conf generated successfully !\033[0m\n"
    echo `date` ": wifi.conf generated successfully !" >> $logfile

    rfkill unblock wifi
    ip link set dev wlan0 up
    # check wpa_supplicant PID
    set +e
    ps -aux|grep wpa_supplicant
    killall wpa_supplicant
    sleep 1
    set -e

    wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wifi.conf
    dhcpcd wlan0
    sleep 3
fi

echo `date` ": Attempt to connect to a $network_connection_type network ..." >> $logfile
echo -e "\033[33mAttempt to connect to a $network_connection_type network ...\033[0m\n"

repeat ping -c 3 www.baidu.com > /dev/null

##set +e
#while ! ping -c 3 www.baidu.com > /dev/null; do
##set -e
#    echo `date` ": $network_connection_type network connection failed. The system is trying again ..." >> $logfile
#    echo -e "\033[31m$network_connection_type network connection failed. The system is trying again ...\033[0m\n"
#    sleep 1
#done
echo `date` ": $network_connection_type network connection successful !" >> $logfile
echo -e "\033[32m$network_connection_type network connection successful !\033[0m\n"

# Check VMware share folder
if [ "$virtualmachine" == "VMware" ]; then
    pacman -Syy --noconfirm open-vm-tools
    if ! vmware-hgfsclient | grep $hostshare > /dev/null; then
        echo -e "\033[031mERROR: The VMware shared folder \"$hostshare\" is not enabled !\033[0m"
        echo `date` ": ERROR: The VMware shared folder \"$hostshare\" is not enabled !" >> $logfile
        exit 0
    fi
fi

# Update mirrors
echo `date` ": Gets the latest mirrors list ..." >> $logfile
echo -e "\033[33mGets the latest mirrors list ...\033[0m\n"

repeat reflector --country China --latest 20 --protocol https,https --threads 20  --ipv4 --sort rate --save /etc/pacman.d/mirrorlist
# If the above is not available please uncomment below and comment above as well
#curl -sSL 'https://www.archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4&use_mirror_status=on' | sed '/^## China/d; s/^#Server/Server/' >> mirrorlist.temp
echo `date` ": The mirrors list is successfully created !" >> $logfile
echo -e "\033[32mThe mirrors list is successfully created !\033[0m\n"

pacman -Syy

# Update the system clock
timedatectl set-ntp true
echo `date` ": Update system time successfully !" >> $logfile

# Disks
set +e
if [ -n "$boot" ]; then umount /dev/$boot; fi
if [ -n "$home" ]; then umount /dev/$home; fi
if [ -n "$root" ]; then umount /dev/$root; fi
if swapon -s | grep /dev/$swap; then swapoff /dev/$swap; fi
set -e

echo `date` ": Read the partition information and process the mounted partition !" >> $logfile

# root
if [ -n "$root" ]; then
    echo y | mkfs.ext4 /dev/$root
    mount /dev/$root /mnt
    echo `date` ": Format partition /dev/$root and mount it to partition /mnt !" >> $logfile
else
    echo -e "\033[031mERROR: root partition does not exist !\033[0m"
    echo `date` ": ERROR: root partition does not exist !" >> $logfile
    exit 0
fi

# /boot
## Note that With UEFI booting, Windows can only be installed to a GPT disk.
## Note that With BIOS booting, Windows can only be installed to a MBR disk.
if ls /sys/firmware/efi/efivars > /dev/null; then
    echo `date` ": This system will boot using UEFI..." >> $logfile
    echo `date` ": Create a mount point /mnt/boot/efi for ESP !" >> $logfile
    [[ ! -d "/mnt/boot" ]] && mkdir -p /mnt/boot/efi
    if [ -n "$boot" ]; then
        echo `date` ": UEFI boot found and ready to create EFI partition..." >> $logfile
        set +e
        efi_boot=`fdisk -l | grep "EFI System" | awk -F " " '{print $1}'`
        set -e

        [[ "$efi_boot" != "/dev/$boot" ]] && echo y | mkfs.fat -F32 /dev/$boot
        mount /dev/$boot /mnt/boot/efi
        echo `date` ": Mount partition /dev/$boot to /mnt/boot/efi !" >> $logfile
    fi

else
    echo `date` ": This system will boot using BIOS..." >> $logfile
    echo `date` ": Create /mnt/boot mount point !" >> $logfile
    [[ ! -d "/mnt/boot" ]] && mkdir -p /mnt/boot
    if [ -n "$boot" ]; then
        echo y | mkfs.ext4 /dev/$boot
        mount /dev/$boot /mnt/boot
        echo `date` ": Mount partition /dev/$boot to /mnt/boot !" >> $logfile
    fi
fi

# /home
if [ -n "$home" ]; then
    if [ ! -d "/mnt/home" ]; then
        mkdir -p /mnt/home
        echo `date` ": Create /mnt/home mount point !" >> $logfile
    fi
    echo y | mkfs.ext4 /dev/$home
    mount /dev/$home /mnt/home
    echo `date` ": Partition /dev/$home is formatted and mounted to /mnt/home !" >> $logfile
fi

# swap
if [ -n "$swap" ]; then
    echo `date` ": Create swap partition /dev/$swap and enable it !" >> $logfile
    mkswap /dev/$swap
    swapon /dev/$swap
fi

# Install essential packages
pacstrap /mnt base linux linux-firmware reflector
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
    exit 0
fi
echo `date` ": Change root into the /mnt system and execute the installation script ..." >> $logfile
cp $logfile $chrootinstall/
chmod +x $chrootinstall/$scriptfile
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
