#/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-01 08:47:37
 # @FilePath: \archlinuxInstall\install.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

configfile="./config/install.conf"

# Connect to the internet
wificonfig="./wifi.conf"
type=`awk -F "=" '$1=="compute" {print $2}' $configfile`
ssid=`awk -F "=" '$1=="ssid" {print $2}' $configfile`
psk=`awk -F "=" '$1=="psk" {print $2}' $configfile`

if [ "$type" = "laptop" ]; then
    if [ -n $wifiSSID ] && [ -n $wifiPSK ] ; then
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

    rfkill unblock wifi
    ip link set dev wlan0 up
    #  check wpa_supplicant PID
    set +e
    ps -aux|grep wpa_supplicant
    if  [ $? -eq 0 ]; then
        killall wpa_supplicant
        sleep 2
    fi
    set -e
    wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wifi.conf
    dhcpcd wlan0    
    sleep 5
fi

ping -c 3 www.baidu.com

# Update mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "\n##======================================================" > mirrorlist.temp

reflector --verbose --country 'China' -l 20 -p https --sort rate >> mirrorlist.temp

#curl -sSL 'https://www.archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4&use_mirror_status=on' | sed '/^## China/d; s/^#Server/Server/g' >> mirrorlist.temp

echo -e "##======================================================\n" >> mirrorlist.temp
sed -i '1r ./mirrorlist.temp' /etc/pacman.d/mirrorlist
rm mirrorlist.temp

pacman -Syy

# Update the system clock
timedatectl set-ntp true

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

if [ -n "$root" ]; then
    echo y | mkfs.ext4 /dev/$root
    mount /dev/$root /mnt
else
    echo "ERROR: root partition does not exist !"
    exit
fi

if [ ! -d "/mnt/boot" ]; then
    mkdir -p /mnt/boot
fi

system=`awk -F "=" '$1=="system" {print $2}' $configfile`
if [ -n "$boot" ]; then
    if [ "$system" != "dual" ];then
        echo y | mkfs.fat -F32 /dev/$boot
        mount /dev/$boot /mnt/boot
    else
        mount /dev/$boot /mnt/boot
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
    exit
fi

if [ ! -d "/mnt/home" ]; then
    mkdir -p /mnt/home
fi
if [ -n "$home" ]; then
    echo y | mkfs.ext4 /dev/$home
    mount /dev/$home /mnt/home
fi

set +e
swapstatus=`swapon -s | grep "$swap"`
set -e

if [[ -n "$swap" ]] && [[ ! -n "$swapstatus" ]]; then
    mkswap /dev/$swap
    swapon /dev/$swap
fi

# Install essential packages
pacstrap /mnt base linux linux-firmware

# Fstab
genfstab -L /mnt >> /mnt/etc/fstab

# Chroot

rm -rf /mnt/chrootinstall
mkdir -p /mnt/chrootinstall

scriptfile="chrootInstall.sh"
 
if [ -s $scriptfile ]; then
    cp -r ./* /mnt/chrootinstall/
fi
arch-chroot /mnt /chrootinstall/$scriptfile



