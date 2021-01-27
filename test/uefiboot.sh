#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:19
 # @LastEditTime: 2021-01-27 11:33:59
 # @FilePath: \archlinuxInstall\test\uefiboot.sh
### 



if ls /sys/firmware/efi/efivar > /dev/null; then
	echo "right"
else
	echo "error"
fi
