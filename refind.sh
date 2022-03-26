###
 # @Author: skillf
 # @Date: 2021-11-07 17:49:15
 # @LastEditTime : 2022-03-26 19:13:15
 # @FilePath     : \archlinuxInstall\refind.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

source /archlinuxInstall/function.sh
esp="/boot/efi"

pacman -S --noconfirm --needed refind efibootmgr git
echo `date` ": Install the boot loader rEFInd !" >> $logfile

# Manual installation
echo `date` ": Create the rEFInd directory and copy the executable to the ESP..." >> $logfile
mkdir -p $esp/EFI/refind
cp /usr/share/refind/refind_x64.efi $esp/EFI/refind/

echo `date` ": Use efibootmgr to create boot entry in UEFI NVRAM..." >> $logfile
set +e
bootnum=`efibootmgr | grep "rEFInd Boot Manager" | awk -F " " '{print $1}'`
set -e
if [ -n "$bootnum" ]; then
	efibootmgr -b `echo $bootnum | tr -cd "[0-9]"` -BD
	echo `date` ": Delete the old boot entry \"rEFInd Boot Manager\"..." >> $logfile
fi

[[ -z "$boot" ]] && disk_part=`get_disk_part $root`
[[ -n "$boot" ]] && disk_part=`get_disk_part $boot`
boot_disk=`echo $disk_part | awk -F " " '{print $1}'`
partnum=`echo $disk_part | awk -F " " '{print $2}'`
efibootmgr --create --disk /dev/$boot_disk --part $partnum  --loader /EFI/refind/refind_x64.efi --label "rEFInd Boot Manager" --verbose
echo `date` ": Create a new boot entry \"rEFInd Boot Manager\"..." >> $logfile

mkdir -p $esp/EFI/refind/drivers_x64
cp /usr/share/refind/drivers_x64/* $esp/EFI/refind/drivers_x64/
echo `date` ": Create the drivers_x64 directory and copy the drivers file to the ESP from the rEFInd installation directory..." >> $logfile

cp /usr/share/refind/refind.conf-sample $esp/EFI/refind/refind.conf
echo `date` ": Copy the configuration file refind.conf to ESP..." >> $logfile

cp -r /usr/share/refind/icons $esp/EFI/refind/
cp -r /usr/share/refind/fonts $esp/EFI/refind/
echo `date` ": Copy icons and fonts to ESP..." >> $logfile

# Configuration
sed -i 's/^#extra_kernel_version_strings/extra_kernel_version_strings/' $esp/EFI/refind/refind.conf
echo `date` ": Uncomment extra_kernel_version_strings..." >> $logfile

mkrlconf --force
echo `date` ": Create a Linux kernel configuration file refind_linux.conf for rEFInd..." >> $logfile

disk_part=`get_disk_part $root`
root_disk=`echo $disk_part | awk -F " " '{print $1}'`
partnum=`echo $disk_part | awk -F " " '{print $2}'`
if echo $root_disk | grep nvme > /dev/null; then partnum="p"$partnum; fi
boot_part = $root_disk$partnum

[[ `lscpu | grep Intel` ]] && cpu="intel"
[[ `lscpu | grep AMD` ]] && cpu="amd"
parameters="initrd=\boot\\$cpu-ucode.img initrd=\boot\initramfs-%v.img"
parameters_fallback="initrd=\boot\\$cpu-ucode.img initrd=\boot\initramfs-%v-fallback.img"

cat > /boot/refind_linux.conf <<EOF
"Boot using default options"     "root=/dev/$boot_part rw add_efi_memmap $parameters"
"Boot using fallback initramfs"     "root=/dev/$boot_part rw add_efi_memmap $parameters_fallback"
"Boot to terminal"     "root=/dev/$boot_part rw add_efi_memmap $parameters systemd.unit=multi-user.target"
EOF

echo `date` ": Add kernel pass parameters to file refind_linux.conf..." >> $logfile

# Themes
mkdir -p $esp/EFI/refind/themes
echo `date` ": Clone the rEFInd theme file: https://github.com/kgoettler/ursamajor-rEFInd.git..." >> $logfile

git_clone https://github.com/kgoettler/ursamajor-rEFInd.git https://gitee.com/skillf/ursamajor-rEFInd.git \
	$esp/EFI/refind/themes/ursamajor-rEFInd $logfile

echo `date` ": Use the rEFInd theme ursamajor-rEFInd..." >> $logfile
echo "include themes/ursamajor-rEFInd/theme.conf" >> $esp/EFI/refind/refind.conf

# TODO:Upgrading
