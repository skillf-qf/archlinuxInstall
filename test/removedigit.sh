#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:19
 # @LastEditTime: 2021-01-27 11:32:50
 # @FilePath: \archlinuxInstall\test\removedigit.sh
### 



#str=test22
#echo -e "str=$str\n"
str=$(echo `awk -F "=" '$1=="boot" {print $2}' install.conf` | sed 's/[0-9]*$//')

echo -e "str=$str\n"
