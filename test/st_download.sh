#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:19
 # @LastEditTime: 2021-01-27 10:56:10
 # @FilePath: \archlinuxInstall\test\st_download.sh
### 



#st-0.2.4.tar
#st-0.2.7.tar
#st-1.2.5.tar
#st-1.2.tar
#st-1.8.6.tar
#st-1.3.6.tar
#st-1.8.9.tar
#st-1.8.3.tar
#st-1.8.7.tar


#st_last_release=`curl -s https://dl.suckless.org/st/ | sed -n 's/.*\(st-[0-9]*.[0-9]*.[0-9]*.tar.gz\).*/\1/p' | sort |tail -2 | awk 'NR==1{print}'`

#echo -e "st_last_release: $st_last_release\n"
function st_download_install(){
	st_url="https://dl.suckless.org/st/"
	st_place_dir="$HOME/download/"
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
  if [ -d $st_place_dir ]; then
    mkdir -p $st_place_dir
  fi

	wget --tries=20 -w 3 -c -P $st_place_dir $st_url$st_last_release
	echo -e "Download completes !\n"
  
  tar -zxvf $st_place_dir$st_last_release
  st_dir=`echo ${st_last_release/%.tar.gz}`

  cd $st_place_dir$st_dir
  sudo make clean install
  cd -

}

st_download_install


