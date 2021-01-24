#/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-01-24 16:47:45
 # @FilePath: \undefinedc:\Users\skillf\Desktop\archScriptbspwmNvim\iniTest\iniTest\install.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

# Connect to the internet
configfile="./wifi.conf"
type=`awk -F "=" '$1=="compute" {print $2}' ./install.conf`
if [ "$type" = "laptop" ]; then
    if [ -s $configfile ]; then
        cp wifi.conf /etc/wpa_supplicant/
    else    
        read -r -p "The wifi.conf file does not exist or is empty. Is it automatically generated? [Y/n]" confirm
        if [[ ! "$confirm" =~ ^(n|N) ]]; then
            read -r -p "Input your wifi ssid: " wifiSSID
            read -r -p "Input your wifi psk: " wifiPSK
            
            cat > wifi.conf <<EOF
            ctrl_interfaces=/run/wpa_supplicant
            update_config=1

            network={
                ssid="$wifiSSID"
                psk="$wifiPSK"
            }
            EOF
            echo -e "wifi.conf generated successfully !\n"
        else
            exit
        fi
    fi
    rfkill unblock wifi
    ip link set dev wlan0 up
    wpa_suppress -B -i wlan0 -c /etc/wpa_supplicant/wifi.conf
    dhcpcd wlan0
    
fi
ping -c 3 www.baidu.com > /dev/null

# Update mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "\n##======================================================" > mirrorlist.temp

reflector --verbose --country 'China' -l 100 -p https --sort rate >> mirrorlist.temp

#curl -sSL 'https://www.archlinux.org/mirrorlist/?country=CN&protocol=https&ip_version=4&use_mirror_status=on' \
     | sed '/^## China/d; s/^#Server/Server/g' >> mirrorlist.temp

echo -e "##======================================================\n" >> mirrorlist.temp

sed -i '/# Last Check/r mirrorlist.temp' /etc/pacman.d/mirrorlist
rm mirrorlist.temp

pacman -Syy

# Update the system clock
timedatectl set-ntp true

# Disks

root=`awk -F "=" '$1=="root" {print $2}' ./install.conf`
boot=`awk -F "=" '$1=="boot" {print $2}' ./install.conf`
home=`awk -F "=" '$1=="home" {print $2}' ./install.conf`
swap=`awk -F "=" '$1=="swap" {print $2}' ./install.conf`

if [ ! -n "$root" ]; then
    mkfs.ext4 /dev/$root
    mount /dev/$root /mnt
else
    echo "ERROR: root partition does not exist !"
    exit 1
fi

if [ ! -d "/mnt/boot" ]; then
    mkdir -p /mnt/boot
fi

if [ ! -n "$boot" ]; then
    if [ "$system" != "dual" ];then
        mkfs.fat -F32 /dev/$boot
    fi
    mount /dev/$boot /mnt/boot
else
    echo "ERROR: boot partition does not exist !"
    exit
fi

if [ ! -d "/mnt/home" ]; then
    mkdir -p /mnt/home
fi
if [ ! -n "$home" ]; then
    mkfs.ext4 /dev/$home
    mount /dev/$home /mnt/home
fi

if [ ! -n "$swap" ]; then
    mkswap /dev/$swap
    swapon /dev/$swap
fi

# Install essential packages
pacstrap /mnt base linux linux-firmware

# Fstab
genfstab -L /mnt >> /mnt/etc/fstab

# Chroot
arch-chroot /mnt

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
echo $hostname > /etc/hostname
cat >> /etc/hosts <<EOF
127.0.0.1    localhost \
::1               localhost \
127.0.1.1    $hostname.localdomain	$hostname \
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
