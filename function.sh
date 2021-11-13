#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-11-13 16:18:58
 # @LastEditTime: 2021-11-14 02:42:33
 # @FilePath: \archlinuxInstall\function.sh
###

# Definitions
install_dir="."
configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"
virtualmachine=`awk -F "=" '$1=="virtualmachine" {print $2}' $configfile`
computer_platform=`awk -F "=" '$1=="computer_platform" {print $2}' $configfile`
network_connection_type=`awk -F "=" '$1=="network_connection_type" {print $2}' $configfile`
ssid=`awk -F "=" '$1=="ssid" {print $2}' $configfile`
psk=`awk -F "=" '$1=="psk" {print $2}' $configfile`
hostname=`awk -F "=" '$1=="hostname" {print $2}' $configfile`
username=`awk -F "=" '$1=="username" {print $2}' $configfile`
userpasswd=`awk -F "=" '$1=="userpasswd" {print $2}' $configfile`
rootpasswd=`awk -F "=" '$1=="rootpasswd" {print $2}' $configfile`
root=`awk -F "=" '$1=="root" {print $2}' $configfile`
boot=`awk -F "=" '$1=="boot" {print $2}' $configfile`
home=`awk -F "=" '$1=="home" {print $2}' $configfile`
swap=`awk -F "=" '$1=="swap" {print $2}' $configfile`
hostshare=`awk -F "=" '$1=="hostshare" {print $2}' $configfile`
guestshare=`awk -F "=" '$1=="guestshare" {print $2}' $configfile`
desktop=`awk -F "=" '$1=="desktop" {print $2}' $configfile`
terminal=`awk -F "=" '$1=="terminal" {print $2}' $configfile`
shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`

# Functions
repeat(){
# function : Run the command continuously until the command is successfully executed
# $@ : The whole line command
#
	while :
	do
		$@ && return
		sleep 3
	done
}

replacestr(){
# function : Replaces the string on the next line of the specified row
# $1 : filename
# S2 : string for replace
#
	line=`sed -n "/super + Return/=" $1`
	line=`expr $line + 1`
	echo -e "line=$line\n"
	sed -i "$line  d" $1
	sed -i "/super + Return/a\  $2" $1
}

git_clone(){
# function : Clone git remote repositories
# $1 and $2 are remote repositories addresses
# $3 is the storage path
#
	local rep=
	[[ -d "$3" ]] && rm -rf $3
	while :
    do
		git clone $1 $3 && rep=$1 && {
			echo -e "\033[33m\"git clone $rep\" success !\033[0m\n"
			echo `date` ": \"git clone $rep\" success !" >> $4
			return
		} || echo -e "\033[31m\"git clone $1\" tries to reconnect...\033[0m\n"

		git clone $2 $3 && rep=$2 && {
			echo -e "\033[33m\"git clone $rep\" success !\033[0m\n"
			echo `date` ": \"git clone $rep\" success !" >> $4
			return
		} || echo -e "\033[31m\"git clone $2\" tries to reconnect...\033[0m\n"
		sleep 3
	done
	[[ -z "$rep" ]] && { \
		echo -e "\033[31m\"git clone $1\" failed !\033[0m\n"
		echo `date` ": \"git clone $1\" failed !" >> $4
		echo -e "\033[31m\"git clone $2\" failed !\033[0m\n"
		echo `date` ": \"git clone $2\" failed !" >> $4
	}
}

get_disk_part(){
# function : Detach the disk name and partition number
# $1 is the disk partition name
#
#
    local str="[0-9]"
	if echo $1 | grep nvme > /dev/null; then str="p"$str; fi
    local diskname=`echo $1 | sed "s/$str*$//"`
	local partnum=`echo $1 | sed "s/$diskname//" | sed 's/p//'`
    echo $diskname $partnum
}

deleteline(){
# function : Deletes from the beginning of the specified line to the end of the line
# $1 : filename
# $2 : start line for deleteline
#
  	local line=`sed -n "/$2/=" $1 | sort -r | tail -1`
 	echo -e "line=$line\n"
  	sed -i "$line"',$d' $1
}
