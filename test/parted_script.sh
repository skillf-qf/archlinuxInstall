#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-10-20 10:47:46
 # @LastEditTime: 2021-10-24 16:24:53
 # @FilePath: \archlinuxInstall\test\parted_script.sh
###

set -x

parted /dev/sdb unit mb print | sed -n '8,$p'
number=`echo $1 |grep -Eo '[0-9]+$'`
disk="/dev/sdb"
start=`parted $disk unit mb print | sed -n '8,$p' | awk '$1 == "'$number'" {print $2}' | \
        sed "s/MB$//"`
end=`parted $disk unit mb print | sed -n '8,$p' | awk '$1 == "'$number'" {print $3}' | \
        sed "s/MB$//"`

echo "start=$start"
echo "end=$end"

parted $disk rm $number
parted $disk mkpart primary ext4 "$start"MB "$(($end-1))"MB
parted $disk mkpart primary ext3 "$(($end-1))"MB "$end"MB

boot_number=`parted $disk unit mb print | sed -n '8,$p' | awk '$2 == "'$(($end-1))'MB" {print $1}'`

parted $disk set $boot_number bios_grub on
