#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:18
 # @LastEditTime: 2021-02-01 11:01:28
 # @FilePath: \archlinuxInstall\bspwm.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euxo pipefail

function replacestr()
# function : Replaces the string on the next line of the specified row
# $1 : filename
# S2 : string for replace
{
	line=`sed -n "/super + Return/=" $1`
	line=`expr $line + 1`
	echo -e "line=$line\n"
	sed -i "$line  d" $1
	sed -i "/super + Return/a\  $2" $1
}

install_dir="/chrootinstall"
configfile="$install_dir/config/install.conf"
user=`awk -F "=" '$1=="username" {print $2}' $configfile`
userhome="/home/$user"
download="$userhome/Downloads"

pacman -S --noconfirm xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config \
								make gcc picom feh zsh ranger git

# bspwm config file 
if [ -s "$install_dir/config/bspwm/bspwmrc"  ]; then
	install -Dm755 $install_dir/config/bspwm/bspwmrc $userhome/.config/bspwm/bspwmrc
else
	install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc $userhome/.config/bspwm/bspwmrc
fi
# sxhkd config file
if [ -s "$install_dir/config/bspwm/sxhkdrc"  ]; then
	install -Dm755 $install_dir/config/bspwm/sxhkdrc $userhome/.config/sxhkd/sxhkdrc
else
	install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc $userhome/.config/sxhkd/sxhkdrc
fi

# install teiminal : default  -> st
terminal=`awk -F "=" '$1=="terminal" {print $2}' $configfile`
if [ ! -d "$download" ]; then
	mkdir -p "$download"
fi

if [ "$terminal" = "st" ] || [ -z "$terminal" ]; then
	
	# st terminal
	current_dir=`pwd`
	git clone https://github.com/skillf-qf/st.git $download/st
	sleep 2
	cd $download/st
	make clean install
	cd $current_dir
	replacestr $userhome/.config/sxhkd/sxhkdrc st
else
	if  pacman -S --noconfirm pacman -S "$terminal"; then
		# set terminal
		replacestr $userhome/.config/sxhkd/sxhkdrc "$terminal"
	else
		# default terminal
		current_dir=`pwd`
		git clone https://github.com/skillf-qf/st.git $download/st
		sleep 2
		cd $download/st
		make clean install
		cd $current_dir
		replacestr $userhome/.config/sxhkd/sxhkdrc st
	fi
fi

# start startx
if [ -s "$install_dir/config/bash/.bash_profile"  ]; then
	cp $install_dir/config/bash/.bash_profile $userhome/
else
	cat >> $userhome/.bash_profile <<EOF
	if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
		exec startx
	fi 
EOF
fi

# start bspwm
if [ -s "$install_dir/config/xorg-xinit/.xinitrc"  ]; then
	cp $install_dir/config/xorg-xinit/.xinitrc $userhome/
else
	cp /etc/X11/xinit/xinitrc $userhome/.xinitrc
	# Delete the last five lines
	$install_dir/deleteline.sh $userhome/.xinitrc "tem &"
	echo -e "\nexec bspwm\n" >> $userhome/.xinitrc
fi

# autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d
if [ -s "$install_dir/config/autologin/override.conf"  ]; then
	cp $install_dir/config/autologin/override.conf /etc/systemd/system/getty@tty1.service.d/
else
	cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
	[Service]
	# 这行不能少，否则启动不了
	ExecStart=
	# username 替换当前自动登录的用户名字
	ExecStart=-/usr/bin/agetty --autologin $username --noclear %I $TERM
EOF
fi

#  Wallpaper
if [ ! -d "$userhome/.picture" ]; then
	mkdir -p $userhome/.picture
fi
if [ -s "$install_dir/wallpaper/wallpaper.jpg"  ]; then
	cp $install_dir/wallpaper/wallpaper.jpg $userhome/.picture
fi


## Chinese font
#pacman -S --noconfirm wqy-zenhei wqy-bitmapfont wqy-microhei firefox-i18n-zh-cn firefox-i18n-zh-tw
#
##TODO ：安装中文输入法
#pacman -S --noconfirm fcitx
#
#sed -i '/# Last Check/r mirrorlist.temp' $userhome/.xinitrc
#export GTK_IM_MODULE=fcitx
#export QT_IM_MODULE=fcitx
#export XMODIFIERS=@im=fcitx
