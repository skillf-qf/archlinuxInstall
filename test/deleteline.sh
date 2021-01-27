#!/bin/bash

function deleteline()
# function : Deletes from the beginning of the specified line to the end of the line
# $1 : filename
# $2 : start line for deleteline
{
	str=$2
	if [ -z $2 ];then
		str="tem &"
	fi
  	line=`sed -n "/$str/=" $1`
 	echo -e "line=$line\n"
  	sed -i "$line"',$d' $1
}
deleteline ./xinitrc
