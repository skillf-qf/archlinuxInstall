#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 16:48:05
 # @LastEditTime: 2021-01-27 17:51:20
 # @FilePath: \archlinuxInstall\test\replacestrng.sh
### 



function replacestr()
# function : Replaces the default string with the specified string
# $1 : filename
# S2 : string for replace
{
  	line=`sed -n "/super + Return/=" $1`
  	line=`expr $line + 1`
  	echo -e "line=$line\n"
  	sed -i "$line  d" $1
	sed -i "/super + Return/a\  $2" $1
}

replacestr ./sxhkdrc hello
