#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-10-20 10:47:46
 # @LastEditTime: 2021-10-20 10:58:15
 # @FilePath: \archlinuxInstall\test\creat_bios_boot_partition.sh
###

#set -x

bp=$1

if echo $bp | grep nvme > /dev/null; then
    str="p[0-9]"
else
    str="[0-9]"
fi
disk=/dev/$(echo $bp | sed "s/$str*$//")

#echo $disk
#exit

partition=`fdisk -l $disk | grep "BIOS boot" | awk -F '{if(NR==1) print $1}'`

bpn=`echo $bp | grep -Eo '[0-9]+$'`
partition_number=`echo $partition | grep -Eo '[0-9]+$'`

#echo $partition_number
#exit
if fdisk -l $disk | grep gpt > /dev/null; then
    echo "It is a GPT disk!"
    if [ -n "$partition" ]; then
        echo "The BIOS_boot partition already exists:"
        echo "  partition: $partition"
        echo "  partition number: $partition_number"
        exit
    else
        echo "d
$bpn
n
$bpn

+1M
t
$bpn
4
w
" | fdisk $disk
    fi
else
    echo "It is a MBR disk!"
fi
