#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:18
 # @LastEditTime: 2021-11-15 02:22:46
 # @FilePath: \archlinuxInstall\bspwm.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

source /archlinuxInstall/function.sh
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
cp /etc/X11/xinit/xinitrc $userhome/.xinitrc
# Delete the last five lines
deleteline $userhome/.xinitrc "twm &"
echo -e "\nexec bspwm\n" >> $userhome/.xinitrc

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
echo `date` ": Fcitx and Chinese fonts are installed !" >> $logfile
set +e
fcitx_target=`sed -n '/fcitx/p' $userhome/.xinitrc`
if [ -z "$fcitx_target" ]; then
	sed -i "/bspwm/r $install_dir/config/fcitx/fcitx.conf" $userhome/.xinitrc
	sed -i '/bspwm/d' $userhome/.xinitrc
	sed -i '/fcitx &/a\exec bspwm' $userhome/.xinitrc
	echo `date` ": Add FCITx to enable startup !" >> $logfile
fi
set -e
