#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:19
 # @LastEditTime: 2021-01-27 11:32:10
 # @FilePath: \archlinuxInstall\test\software.sh
### 




#software=a b c d

ss=`awk -F "=" '$1=="software" {print $2}' install.conf`

for s in $ss; do
	echo -e "$s\n"
done	
