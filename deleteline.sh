#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-28 09:23:43
 # @LastEditTime: 2021-01-29 15:51:20
 # @FilePath: \archlinuxInstall\deleteline.sh
### 

filename=$1
startline=$2
function deleteline()
# function : Deletes from the beginning of the specified line to the end of the line
# $1 : filename
# $2 : start line for deleteline
{
  	line=`sed -n "/$str/=" $1 | sort -r | tail -1`
 	echo -e "line=$line\n"
  	sed -i "$line"',$d' $1
}
deleteline $filename $startline
