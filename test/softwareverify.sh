#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 15:44:51
 # @LastEditTime: 2021-01-27 15:48:59
 # @FilePath: \archlinuxInstall\test\verifycommand.sh
### 

software=tree

if echo y | pacman -S "$software"; then
  echo -e "$software is exist\n"
else
  echo -e "$software no exist!\n"
fi

