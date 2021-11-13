#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:18
 # @LastEditTime: 2021-11-13 16:49:16
 # @FilePath: \archlinuxInstall\bspwm.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

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

source ./function.sh

install_dir="/archlinuxInstall"
configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

username=`awk -F "=" '$1=="username" {print $2}' $configfile`
userhome="/home/$username"
download="$userhome/Downloads"

echo `date` ": Install the prerequisite software required for BSPWM Tile Window Manager ..." >> $logfile
pacman -S --noconfirm xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config \
								make gcc picom feh zsh ranger git
echo `date` ": xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config make gcc picom feh zsh ranger git successfully installed !" >> $logfile

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
echo `date` ": Copy the bspwmrc and sxhkdrc configuration files ..." >> $logfile

# install teiminal : default  -> st
terminal=`awk -F "=" '$1=="terminal" {print $2}' $configfile`
echo `date` ": Installation terminal $terminal ..." >> $logfile

if [ ! -d "$download" ]; then
	mkdir -p "$download"
fi

if [ "$terminal" = "st" ] || [ -z "$terminal" ] || ! pacman -Fy $terminal; then

	# st terminal
	current_dir=`pwd`
	git_clone https://github.com/skillf-qf/st.git https://gitee.com/skillf/st.git $download/st $logfile
	cd $download/st
	make clean install
	cd $current_dir
	replacestr $userhome/.config/sxhkd/sxhkdrc st
else
	if  pacman -S --noconfirm --needed $terminal; then
		# set terminal
		replacestr $userhome/.config/sxhkd/sxhkdrc "$terminal"
	fi
fi
echo `date` ": Installation of terminal $terminal was successful !" >> $logfile

# start startx
echo `date` ": Configure the user to automatically start startx after successful login ..." >> $logfile
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
echo `date` ": Run bspwm directly after configuring startx to boot ..." >> $logfile
if [ -s "$install_dir/config/Xorg-xinit/.xinitrc"  ]; then
	cp $install_dir/config/Xorg-xinit/.xinitrc $userhome/
else
	cp /etc/X11/xinit/xinitrc $userhome/.xinitrc
	# Delete the last five lines
	chmod +x $install_dir/deleteline.sh
	$install_dir/deleteline.sh $userhome/.xinitrc "tem &"
	echo -e "\nexec bspwm\n" >> $userhome/.xinitrc
fi

# autologin
echo `date` ": Configure the user to automatically log in the account without password ..." >> $logfile
rm -rf /etc/systemd/system/getty@tty1.service.d
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
# This row cannot be smaller, otherwise it will not start
ExecStart=
# username : Replace the name of the currently auto-logged user
ExecStart=-/usr/bin/agetty --autologin $username --noclear %I \$TERM
EOF

#  Wallpaper
echo `date` ": Copy the wallpaper to $userhome/.picture" >> $logfile
if [ ! -d "$userhome/.picture" ]; then
	mkdir -p $userhome/.picture
fi
if [ -s "$install_dir/wallpaper/wallpaper.jpg"  ]; then
	cp $install_dir/wallpaper/wallpaper.jpg $userhome/.picture
fi

echo `date` ": The bspwm installation configuration is complete !" >> $logfile

## Chinese font | fcitx
pacman -S --noconfirm fcitx fcitx-configtool wqy-zenhei wqy-bitmapfont wqy-microhei firefox-i18n-zh-cn firefox-i18n-zh-tw
#
set +e
fcitx_target=`sed -n '/fcitx/p' $userhome/.xinitrc`
if [ -z "$fcitx_target" ]; then
	sed -i '/bspwm/r "'$install_dir'"/config/fcitx/fcitx.conf' $userhome/.xinitrc
	sed -i '/bspwm/d' $userhome/.xinitrc
	sed -i '/fcitx &/a\exec bspwm' $userhome/.xinitrc
fi
set -e
