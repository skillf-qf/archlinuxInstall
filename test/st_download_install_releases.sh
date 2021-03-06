#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:19
 # @LastEditTime: 2021-02-01 01:34:17
 # @FilePath: \archlinuxInstall\test\st_download_install_releases.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

configfile="/chrootinstall/config/install.conf"
user=`awk -F "=" '$1=="username" {print $2}' $configfile`
userhome="/home/$user"
install_dir="/chrootinstall"

function st_download_install(){
    st_url="https://dl.suckless.org/st/"
    st_place_dir="$userhome/download"
    st_list=`curl -s $st_url | sed -n 's/.*\(st-[0-9]*.[0-9]*.[0-9]*.tar.gz\).*/\1/p' | sort |tail -2`
    st1=`echo $st_list | awk -F " " '{print $1}'`
    st2=`echo $st_list | awk -F " " '{print $2}'`
    st1_str2=`echo $st1 | awk -F "." '{print $2}'`
    st2_str2=`echo $st2 | awk -F "." '{print $2}'`
    st2_str3=`echo $st2 | awk -F "." '{print $3}'`
    #echo -e "str3=$str3\n"
    if [ "$st2_str3" == "tar" ]; then
    	if [ $st1_str2 == $st2_str2 ]; then
    		st_last_release=$st1
    	elif [ $st1_str2 < $st2_str2 ]; then
    		st_last_release=$st2
    	fi
    else
    	st_last_release=$st2
    fi
    #echo -e "st_last_release=$st_last_release\n"
    
    #wget --tries=20 -w 3 -c $st_url$st_last_release
    if [ ! -d "$st_place_dir" ]; then
        mkdir -p "$st_place_dir"
    fi
    wget --tries=20 -w 3 -c -P $st_place_dir $st_url$st_last_release
    echo -e "Download completes !\n"
     
    tar -zxvf $st_place_dir/$st_last_release -C $st_place_dir/
    sleep 3
    st_dir=`echo ${st_last_release/%.tar.gz}`
    
    current_dir=`pwd`
	if [ -f "$install_dir/config/st/config.h"  ]; then
		cp $install_dir/config/st/config.h $st_place_dir/$st_dir
	else
        cd $st_place_dir/$st_dir
        cp $install_dir/config.def.h ./config.h
        sed -i 's/Liberation Mono/Fira Code/g' ./config.h
    fi
    cd $st_place_dir/$st_dir
    make clean install
    cd $current_dir

}

st_download_install_releases


