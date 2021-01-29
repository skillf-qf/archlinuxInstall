#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:18
 # @LastEditTime: 2021-01-29 16:31:09
 # @FilePath: \archlinuxInstall\bspwm.sh
### 

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
pacman -S --noconfirm xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config \
								make gcc picom feh zsh ranger

# bspwm config file 
if [ -s "./config/bspwm/bspwmrc"  ]; then
	install -Dm755 ./config/bspwm/bspwmrc $HOME/.config/bspwm/bspwmrc
else
	install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc $HOME/.config/bspwm/bspwmrc
fi
# sxhkd config file
if [ -s "./config/bspwm/sxhkdrc"  ]; then
	install -Dm755 ./config/bspwm/sxhkdrc $HOME/.config/sxhkd/sxhkdrc
else
	install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc $HOME/.config/sxhkd/sxhkdrc
fi

# install teiminal : default  -> st
terminal=`awk -F "=" '$1=="terminal" {print $2}' $configfile`
if [ "$terminal" = "st" ] || [ -z "$terminal" ]; then
	./st
	replacestr $HOME/.config/sxhkd/sxhkdrc st
else
    if  pacman -S --noconfirm pacman -S "$terminal"; then
		# set terminal
		replacestr $HOME/.config/sxhkd/sxhkdrc "$terminal"
	else
    # default terminal
		./st
		replacestr $HOME/.config/sxhkd/sxhkdrc st
	fi
fi

# start startx
if [ -s "./config/bash/.bash_profile"  ]; then
	cp ./config/bash/.bash_profile $HOME/
else
	cat >> $HOME/.bash_profile <<EOF
	if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  			exec startx
	fi 
EOF

# start bspwm
if [ -s "./config/xorg-xinit/.xinitrc"  ]; then
	cp ./config/xorg-xinit/.xinitrc $HOME/
else
	cp /etc/X11/xinit/xinitrc $HOME/.xinitrc
	# Delete the last five lines
	./deleteline.sh $HOME/.xinitrc "tem &"
	echo -e "\nexec bspwm\n" >> $HOME/.xinitrc
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
