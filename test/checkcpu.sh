#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:19
 # @LastEditTime: 2021-01-27 11:33:27
 # @FilePath: \archlinuxInstall\test\checkcpu.sh
### 



cpuinfo=`lscpu | grep "Intel"`

if [ -n "$cpuinfo" ]; then
	echo "cpu is intel"
else
	echo "cpu is amd"
fi
