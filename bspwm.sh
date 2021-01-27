<<<<<<< HEAD
#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:18
 # @LastEditTime: 2021-01-27 23:19:39
 # @FilePath: \archlinuxInstall\bspwm.sh
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

configfile="./config/install.conf"
echo y | pacman -S xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config \
								make gcc picom feh zsh ranger

# bspwm config file 
if [ -f "./config/bspwm/bspwmrc"  ]; then
	install -Dm755 ./config/bspwm/bspwmrc $HOME/.config/bspwm/bspwmrc
else
	install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc $HOME/.config/bspwm/bspwmrc
fi
# sxhkd config file
if [ -f "./config/bspwm/sxhkdrc"  ]; then
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
    if  echo y | pacman -S "$terminal"; then
		# set terminal
		replacestr $HOME/.config/sxhkd/sxhkdrc "$terminal"
	else
    # default terminal
		./st
		replacestr $HOME/.config/sxhkd/sxhkdrc st
	fi
fi

# start startx
if [ -f "./config/bash/.bash_profile"  ]; then
	cp ./config/bash/.bash_profile $HOME/
else
	cat >> $HOME/.bash_profile <<EOF
	if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  			exec startx
	fi 
EOF

# start bspwm
if [ -f "./config/xorg-xinit/.xinitrc"  ]; then
	cp ./config/xorg-xinit/.xinitrc $HOME/
else
	cp /etc/X11/xinit/xinitrc $HOME/.xinitrc
	# Delete the last five lines
	deleteline $HOME/.xinitrc
	echo -e "\nexec bspwm\n" >> $HOME/.xinitrc
fi

# autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d
if [ -f "./config/autologin/override.conf"  ]; then
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
=======
#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:18
 # @LastEditTime: 2021-01-27 11:34:51
 # @FilePath: \archlinuxInstall\bspwm.sh
### 

echo y | pacman -S xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config \
								make gcc picom feh zsh

wget -c --tries=2 -P $HOME/Downloads https://dl.suckless.org/st/st-0.8.4.tar.gz
tar -zxvf $HOME/Downloads/st-0.8.4.tar.gz
make clean install

# TODO: 修改Fira Code:

install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc $HOME/.config/bspwm/bspwmrc
install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc $HOME/.config/sxhkd/sxhkdrc

# TODO: 修改 sxhkdrc 快捷键启动的terminal：

cat >> $HOME/.bash_profile <<EOF
if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  		exec startx
fi 
EOF

cp /etc/X11/xinit/xinitrc $HOME/.xinitrc

# TODO: 删除 最后5行 的内容并在最后一行加入：

echo "exec bspwm" >> $HOME/.xinitrc

mkdir -p /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
# 这行不能少，否则启动不了
ExecStart=
# username 替换当前自动登录的用户名字
ExecStart=-/usr/bin/agetty --autologin $username --noclear %I $TERM
EOF
>>>>>>> aad536e3ece68c43a9cc953dfa52092d760ec2b3
