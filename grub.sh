###
 # @Author: skillf
 # @Date: 2021-11-07 17:49:02
 # @LastEditTime: 2021-11-10 11:37:05
 # @FilePath: \archlinuxInstall\grub.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

install_dir="/archlinuxInstall"
configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

boot=`awk -F "=" '$1=="boot" {print $2}' $configfile`
root=`awk -F "=" '$1=="root" {print $2}' $configfile`
#system=`awk -F "=" '$1=="system" {print $2}' $configfile`

# Verify the boot mode
pacman -S --noconfirm --needed grub
echo `date` ": Install the multi-boot loader GRUB !" >> $logfile

# BIOS systems
str="[0-9]"
if echo $boot | grep nvme > /dev/null; then str="p"$str; fi
root_disk=/dev/$(echo $root | sed "s/$str*$//")

set +e
biosboot_other=`fdisk -l | grep NTFS | grep "*" | awk -F " " '{if(NR==1) print $1}'`
set -e
if [ -z "$biosboot_other" ]; then
    grub-install --target=i386-pc $root_disk
    echo `date` ": Install grub-install under BIOS boot !" >> $logfile
else
    echo `date` ": Install GRUB to the disk where Windows 10 resides !" >> $logfile
    str="[0-9]"
    if echo $biosboot_other | grep nvme > /dev/null; then str="p"$str; fi
    biosboot_other_disk=`echo $biosboot_other | sed "s/$str*$//"`
    grub-install --target=i386-pc $biosboot_other_disk
    echo `date` ": Mount the Windows BIOS boot partition to /boot !" >> $logfile
    pacman -S --noconfirm --needed ntfs-3g
    mkdir -p /boot/win_bios_boot
    ntfs-3g $biosboot_other /boot/win_bios_boot
    system="dual"
fi

# check MS Windows
if [ "$system" == "dual" ]; then
    echo `date` ": Install os-prober for dual systems and check the Windows system ..." >> $logfile
    pacman -S --noconfirm --needed os-prober
    os-prober
    echo `date` ": Enable OS-prober in GRUB ..." >> $logfile
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    source /etc/default/grub
fi

# Generate the main configuration file
echo `date` ": Use the grub-mkconfig tool to generate /boot/grub/grub.cfg ..." >> $logfile
grub-mkconfig -o /boot/grub/grub.cfg
