###
 # @Author: skillf
 # @Date: 2021-11-07 17:49:02
 # @LastEditTime: 2021-11-14 02:27:30
 # @FilePath: \archlinuxInstall\grub.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

source $install_dir/function.sh

# Verify the boot mode
pacman -S --noconfirm --needed grub
echo `date` ": Install the boot loader GRUB..." >> $logfile

# BIOS systems
set +e
biosboot_other=`fdisk -l | grep NTFS | grep "*" | awk -F " " '{if(NR==1) print $1}'`
set -e

[[ -z "$boot" ]] && disk_part=`get_disk_part $root`
[[ -n "$boot" ]] && disk_part=`get_disk_part $boot`
[[ -n "$biosboot_other" ]] && disk_part=`get_disk_part $biosboot_other`

if [ -n "$biosboot_other" ]; then
    pacman -S --noconfirm --needed ntfs-3g
    mkdir -p /boot/win_bios_boot
    ntfs-3g $biosboot_other /boot/win_bios_boot
    echo `date` ": Mount the Windows BIOS boot partition to /boot !" >> $logfile
    system="dual"
fi

boot_disk=`echo $disk_part | awk -F " " '{print $1}'`

grub-install --target=i386-pc /dev/$boot_disk
echo `date` ": Install grub into disk /dev/$boot_disk..." >> $logfile

# check MS Windows
if [ "$system" == "dual" ]; then
    pacman -S --noconfirm --needed os-prober
    echo `date` ": Install the so-prober..." >> $logfile
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    source /etc/default/grub
    os-prober
    echo `date` ": Enable os-prober \"GRUB_DISABLE_OS_PROBER=false\" in /etc/default/grub and check the Windows system..." >> $logfile
fi

# Generate the main configuration file
grub-mkconfig -o /boot/grub/grub.cfg
echo `date` ": Use the grub-mkconfig tool to generate /boot/grub/grub.cfg ..." >> $logfile
