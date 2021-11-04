#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-11-04 09:16:22
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
virtualmachine=`awk -F "=" '$1=="virtualmachine" {print $2}' $configfile`
hostshare=`awk -F "=" '$1=="hostshare" {print $2}' $configfile`
guestshare=`awk -F "=" '$1=="guestshare" {print $2}' $configfile`


var_list="\
        computer_platform network_connection_type \
        hostname username userpasswd rootpasswd \
        root boot \
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
                echo `date` ": Prepare to create the biOS_GRUB partition ..." >> $logfile
                echo -e "\033[33mPrepare to create the biOS_GRUB partition ...\033[0m\n"
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
                echo -e "\n\n\033[32mThe biOS_GRUB partition is created successfully !\033[0m\n"
                echo `date` ": The biOS_GRUB partition is created successfully !" >> $logfile
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
    #  check wpa_supplicant PID
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

#set +e
while ! ping -c 3 www.baidu.com > /dev/null; do
#set -e
    echo `date` ": $network_connection_type network connection failed. The system is trying again ..." >> $logfile
    echo -e "\033[31m$network_connection_type network connection failed. The system is trying again ...\033[0m\n"
    sleep 1
done
echo `date` ": $network_connection_type network connection successful !" >> $logfile
echo -e "\033[32m$network_connection_type network connection successful !\033[0m\n"

# Check VMware share folder
if [ "$virtualmachine" == "VMware" ]; then
    pacman -Sy
    pacman -S --noconfirm open-vm-tools
    if ! vmware-hgfsclient | grep $hostshare > /dev/null; then
        echo -e "\033[031mERROR: The VMware shared folder \"$hostshare\" is not enabled !\033[0m"
        echo `date` ": ERROR: The VMware shared folder \"$hostshare\" is not enabled !" >> $logfile
        exit 0
    fi
fi

# Update mirrors
echo `date` ": Gets the latest mirrors list ..." >> $logfile
echo -e "\033[33mGets the latest mirrors list ...\033[0m\n"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "\n##======================================================" > mirrorlist.temp

counter=0
#set +e
while ! reflector --country China --latest 10 --protocol https --sort rate >> mirrorlist.temp; do
#set -e
    if [ $counter -lt 10 ];then
    	echo `date` ": \"reflector\" tries to reconnect to the network ..." >> $logfile
    	echo -e "\033[31m\"reflector\" tries to reconnect to the network ...\033[0m\n"
        sleep 3
        counter=`expr $counter + 1`
    else
        echo -e "\033[31mERROR: Network error, please check network and try again !\033[0m"
        exit 0
    fi
done

#reflector --country China --latest 10 --protocol https --sort rate >> mirrorlist.temp
# If the above is not available please uncomment below and comment above as well
#curl -sSL 'https://www.archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4&use_mirror_status=on' | sed '/^## China/d; s/^#Server/Server/g' >> mirrorlist.temp

echo -e "##======================================================\n" >> mirrorlist.temp
sed -i '1r ./mirrorlist.temp' /etc/pacman.d/mirrorlist
rm mirrorlist.temp
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
# Note that With UEFI booting, Windows can only be installed to a GPT disk.
# Note that With BIOS booting, Windows can only be installed to a MBR disk.
if [ ! -d "/mnt/boot" ]; then
    mkdir -p /mnt/boot
    echo `date` ": Create /mnt/boot mount point !" >> $logfile
fi
if ls /sys/firmware/efi/efivars > /dev/null; then
    echo `date` ": UEFI boot found and ready to create EFI partition..." >> $logfile
    set +e
    efi_boot=`fdisk -l | grep "EFI System" | awk -F " " '{print $1}'`
    set -e

    if [ "$efi_boot" == "/dev/$boot" ]; then
        mount /dev/$boot /mnt/boot
        echo `date` ": Partition /dev/$boot is mounted only to /mnt/boot !" >> $logfile
        # Remove everything except EFI
        rm -rf /mnt/boot/grub
        rm -rf /mnt/boot/*.img
        rm -rf /mnt/boot/*linux
    else
        echo y | mkfs.fat -F32 /dev/$boot
        mount /dev/$boot /mnt/boot
        echo `date` ": Partition /dev/$boot is mounted only to /mnt/boot !" >> $logfile
    fi

else
    echo `date` ": This system will boot using BIOS..." >> $logfile
    echo y | mkfs.ext4 /dev/$boot
    mount /dev/$boot /mnt/boot

    #set +e
    #bios_boot=`fdisk -l | grep NTFS | grep "*" | awk -F " " '{if(NR==1) print $1}'`
    #set -e
    #
    #
    #str="[0-9]"
    #if echo $boot | grep nvme > /dev/null; then str="p"$str; fi
    #boot_disk=/dev/$(echo $boot | sed "s/$str*$//")
    #boot_partition=`echo $boot | sed "s/$str*$//"`
    #
    #if [ - z "$bios_boot" ]; then
    #   # Single system
    #   if fdisk -l $boot_disk | grep gpt > /dev/null;then
    #       boot_partition_number=`echo $boot | grep -Eo '[0-9]+$'`
    #
    #       set +e
    #       biosboot_other=`fdisk -l $boot_disk | grep "BIOS boot" | awk -F " " '{if(NR==1) print $1}'`
    #       set -e
    #
    #       if [ -n "$biosboot_other" ]; then
    #            biosboot_other_number=`echo $biosboot_other | grep -Eo '[0-9]+$'`
    #            partition_number=$biosboot_other_number
    #       else
    #            echo `date` ": Create a 1M BIOS boot partition..." >> $logfile
    #            # Create a 1M BIOS boot partition
    #            echo "d\n$boot_partition_number\nn\n$boot_partition_number\n\n+1M\nt\n$boot_partition_number\n4\nw\n" | fdisk $boot_disk
    #            partition_number=$boot_partition_number
    #       fi
    #       echo `date` ": Activate the BIOS Boot partition..." >> $logfile
    #       parted $boot_disk set $partition_number bios_grub on
    #   fi
    #
    #
    #
    #else
    #    # Dual system
    #    #if fdisk -l $boot_disk | grep dos > /dev/null;then
    #    echo y | mkfs.ext4 /dev/$boot
    #    mount /dev/$boot /mnt/boot
   #fi
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
    exit 0
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
