#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:18
 # @LastEditTime: 2021-01-31 01:12:15
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

configfile="./config/install.conf"
user=`awk -F "=" '$1=="username" {print $2}' $configfile`
pacman -S --noconfirm xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config \
								make gcc picom feh zsh ranger

# bspwm config file 
if [ -s "./config/bspwm/bspwmrc"  ]; then
	install -Dm755 ./config/bspwm/bspwmrc /home/$user/.config/bspwm/bspwmrc
else
	install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc /home/$user/.config/bspwm/bspwmrc
fi
# sxhkd config file
if [ -s "./config/bspwm/sxhkdrc"  ]; then
	install -Dm755 ./config/bspwm/sxhkdrc /home/$user/.config/sxhkd/sxhkdrc
else
	install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc /home/$user/.config/sxhkd/sxhkdrc
fi

# install teiminal : default  -> st
terminal=`awk -F "=" '$1=="terminal" {print $2}' $configfile`
if [ "$terminal" = "st" ] || [ -z "$terminal" ]; then
	./st
	replacestr /home/$user/.config/sxhkd/sxhkdrc st
else
    if  pacman -S --noconfirm pacman -S "$terminal"; then
		# set terminal
		replacestr /home/$user/.config/sxhkd/sxhkdrc "$terminal"
	else
    # default terminal
		./st
		replacestr /home/$user/.config/sxhkd/sxhkdrc st
	fi
fi

# start startx
if [ -s "./config/bash/.bash_profile"  ]; then
	cp ./config/bash/.bash_profile /home/$user/
else
	cat >> /home/$user/.bash_profile <<EOF
	if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  			exec startx
	fi 
EOF

# start bspwm
if [ -s "./config/xorg-xinit/.xinitrc"  ]; then
	cp ./config/xorg-xinit/.xinitrc /home/$user/
else
	cp /etc/X11/xinit/xinitrc /home/$user/.xinitrc
	# Delete the last five lines
	./deleteline.sh /home/$user/.xinitrc "tem &"
	echo -e "\nexec bspwm\n" >> /home/$user/.xinitrc
fi

# autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d
if [ -s "./config/autologin/override.conf"  ]; then
	cp ./config/autologin/override.conf /etc/systemd/system/getty@tty1.service.d/
else
	cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
	[Service]
	# 这行不能少，否则启动不了
	ExecStart=
	# username 替换当前自动登录的用户名字
	ExecStart=-/usr/bin/agetty --autologin $username --noclear %I $TERM
EOF
fi

# TODO : Wallpaper


## Chinese font
#pacman -S --noconfirm wqy-zenhei wqy-bitmapfont wqy-microhei firefox-i18n-zh-cn firefox-i18n-zh-tw
#
##TODO ：安装中文输入法
#pacman -S --noconfirm fcitx
#
#sed -i '/# Last Check/r mirrorlist.temp' /home/$user/.xinitrc
#export GTK_IM_MODULE=fcitx
#export QT_IM_MODULE=fcitx
#export XMODIFIERS=@im=fcitx
