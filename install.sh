#/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-03 06:27:00
 # @FilePath: \archlinuxInstall\install.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

# Set tty font
setfont /usr/share/kbd/consolefonts/LatGrkCyr-12x22.psfu.gz

install_dir="/root/archlinuxInstall"
configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

echo `date` ": ##########################################" > $logfile

# Connect to the internet
type=`awk -F "=" '$1=="compute" {print $2}' $configfile`
ssid=`awk -F "=" '$1=="ssid" {print $2}' $configfile`
psk=`awk -F "=" '$1=="psk" {print $2}' $configfile`

if [ "$type" = "laptop" ]; then
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
    echo -e "wifi.conf generated successfully !\n" 
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

ping -c 3 www.baidu.com
echo `date` ": $type network connection successful !" >> $logfile

# Update mirrors
echo `date` ": Try to get the latest image source and sort it by speed ..." >> $logfile
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "\n##======================================================" > mirrorlist.temp

reflector --country China --latest 10 --protocol https --sort rate >> mirrorlist.temp
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
root=`awk -F "=" '$1=="root" {print $2}' $configfile`
boot=`awk -F "=" '$1=="boot" {print $2}' $configfile`
home=`awk -F "=" '$1=="home" {print $2}' $configfile`
swap=`awk -F "=" '$1=="swap" {print $2}' $configfile`

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
    echo "ERROR: root partition does not exist !"
    echo `date` ": ERROR: root partition does not exist !" >> $logfile
    exit
fi

if [ ! -d "/mnt/boot" ]; then
    mkdir -p /mnt/boot
    echo `date` ": Create /mnt/boot mount point !" >> $logfile
fi

system=`awk -F "=" '$1=="system" {print $2}' $configfile`
if [ -n "$boot" ]; then
    if [ "$system" != "dual" ];then
        echo `date` ": The installation target system is a single system ..." >> $logfile
        echo y | mkfs.fat -F32 /dev/$boot
        mount /dev/$boot /mnt/boot
        echo `date` ": Partition /dev/$boot is formatted and mounted to /mnt/boot !" >> $logfile
    else
        echo `date` ": The installation target system is dual system ..." >> $logfile
        mount /dev/$boot /mnt/boot
        echo `date` ": Partition /dev/$boot is mounted only to /mnt/boot !" >> $logfile
        # Remove everything except EFI 
        if [ -d "/mnt/boot/grub" ]; then
            rm -rf /mnt/boot/grub
        fi
        if ls /mnt/boot/*.img > /dev/null 2>&1; then
            rm -rf /mnt/boot/*.img
            rm -rf /mnt/boot/*linux
        fi
    fi
else
    echo "ERROR: boot partition does not exist !"
    echo `date` ": ERROR: boot partition does not exist !" >> $logfile
    exit
fi

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

if [[ -n "$swap" ]] && [[ ! -n "$swapstatus" ]]; then
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
fi
echo `date` ": Change root into the /mnt system and execute the installation script ..." >> $logfile
cp $logfile $chrootinstall/
arch-chroot /mnt /archlinuxInstall/$scriptfile
set +x

echo -e "\n\n"
echo -e "The system will reboot for the final configuration step !\n"
echo -e "\n\n"
for time in `seq 5 -1 0`; do
    echo -n "Restarting for the last configuration $time press Ctrl+c to stop it ..."
    echo -n -e "\r\r"
    sleep 1
done

reboot

