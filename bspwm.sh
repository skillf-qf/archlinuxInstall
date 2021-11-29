#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-27 10:30:18
 # @LastEditTime: 2021-11-29 15:09:03
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
st_dir="$download/st"
ImageMagick_dir="$download/ImageMagick"
betterlockscreen_dir="$download/betterlockscreen"
polybar_dir="$download/polybar"



echo `date` ": Install the prerequisite software required for BSPWM Tile Window Manager ..." >> $logfile
pacman -S --noconfirm xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config \
								make gcc picom feh zsh ranger git
echo `date` ": xorg xorg-xinit bspwm sxhkd sudo wget ttf-fira-code pkg-config make gcc picom feh zsh ranger git successfully installed !" >> $logfile

# Bspwm config file
if [ -s "$config_dir/bspwm/bspwmrc" ]; then
	install -Dm755 $config_dir/bspwm/bspwmrc $userhome/.config/bspwm/bspwmrc
else
	install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc $userhome/.config/bspwm/bspwmrc
fi
# Sxhkd config file
if [ -s "$config_dir/sxhkd/sxhkdrc"  ]; then
	install -Dm755 $config_dir/bspwm/sxhkdrc $userhome/.config/sxhkd/sxhkdrc
else
	install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc $userhome/.config/sxhkd/sxhkdrc
fi
echo `date` ": Copy the bspwmrc and sxhkdrc configuration files ..." >> $logfile

# Terminal : default -> st
echo `date` ": Installation terminal $terminal ..." >> $logfile

[[ ! -d "$download" ]] && mkdir -p "$download"

if [ "$terminal" = "st" ] || [ -z "$terminal" ] || ! pacman -Fy $terminal; then

	## st terminal
	current_dir=`pwd`
	git_clone https://github.com/skillf-qf/st.git https://gitee.com/skillf/st.git $st_dir $logfile
	cd $st_dir
	make clean install
	cd $current_dir
	replacestr $userhome/.config/sxhkd/sxhkdrc st
else
	if pacman -S --noconfirm --needed $terminal; then
		## Set terminal
		replacestr $userhome/.config/sxhkd/sxhkdrc "$terminal"
	fi
fi
echo `date` ": Installation of terminal $terminal was successful !" >> $logfile

# Startup startx
echo `date` ": Configure the user to automatically start startx after successful login ..." >> $logfile
if [ -s "$config_dir/bash/.bash_profile"  ]; then
	cp $config_dir/bash/.bash_profile $userhome/
else
	cat >> $userhome/.bash_profile <<EOF
	if systemctl -q is-active graphical.target && [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
		exec startx
	fi
EOF
fi

# Startup bspwm
echo `date` ": Run bspwm directly after configuring startx to boot ..." >> $logfile
if [ ! -s "$userhome/.xinitrc" ]; then
	cp /etc/X11/xinit/xinitrc $userhome/.xinitrc
	## Delete the last five lines
	deleteline $userhome/.xinitrc "twm &"
	echo -e "exec bspwm\n" >> $userhome/.xinitrc
else
	echo -e "exec bspwm\n" >> $userhome/.xinitrc
fi

# Autologin
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

# Background
echo `date` ": Copy the background to $userhome/.config/background/" >> $logfile
[[ ! -d "$userhome/.config/background" ]] && mkdir -p $userhome/.config/background

if [ -s "$config_dir/background/background.jpg" ]; then
	cp $config_dir/background/background.jpg $userhome/.config/background
	feh_target=`sed -n '/feh --bg-scale/p' $userhome/.config/bspwm/bspwmrc`
	if [ -z "$feh_target" ]; then
		sed -i '/pgrep -x sxhkd/a\feh --bg-scale ~/.config/background/background.jpg' $userhome/.config/bspwm/bspwmrc
	fi
	echo `date` ": Enable feh to set the wallpaper..." >> $logfile
fi

# Picom config file
[[ ! -d "$userhome/.config/picom" ]] && mkdir -p $userhome/.config/picom
echo `date` ": Create the $userhome/.config/picom directory..." >> $logfile

if [ -s "$config_dir/picom/picom.conf" ]; then
	cp $config_dir/picom/picom.conf $userhome/.config/picom/picom.conf
else
	cp /etc/xdg/picom.conf $userhome/.config/picom/picom.conf
fi
echo `date` ": Copy the picom.conf to $userhome/.config/picom .." >> $logfile

picom_target=`sed -n '/picom -b/p' $userhome/.config/bspwm/bspwmrc`
if [ -z "$picom_target" ]; then
	sed -i '/pgrep -x sxhkd/a\picom -b --config ~/.config/picom/picom.conf' $userhome/.config/bspwm/bspwmrc
fi
echo `date` ": Make the wallpaper transparent by enabling picom in the bspwmrc file  ..." >> $logfile

# Chinese font | fcitx
pacman -S --noconfirm fcitx fcitx-configtool wqy-zenhei wqy-bitmapfont wqy-microhei firefox-i18n-zh-cn firefox-i18n-zh-tw
echo `date` ": Fcitx and Chinese fonts are installed !" >> $logfile
fcitx_target=`sed -n '/fcitx/p' $userhome/.xinitrc`
if [ -z "$fcitx_target" ] && [ -s "$config_dir/fcitx/fcitx.conf" ] ; then
	line=`sed -n "/bspwm/=" $userhome/.xinitrc`
	line=`expr $line - 1`
	sed -i "$line r $config_dir/fcitx/fcitx.conf" $userhome/.xinitrc
	echo `date` ": Add fcitx to enable startup !" >> $logfile
fi

# The status bar
## Polybar
if [ -s "$config_dir/polybar/polybar.sh"  ]; then
	echo `date` ": Start configuring the polybar..." >> $logfile
    chmod +x $config_dir/polybar/polybar.sh
    $config_dir/polybar/polybar.sh
fi

# lock screen
## betterlockscreen
### System Requirements
pacman -S --noconfirm i3lock-color

[[ ! -d "$ImageMagick_dir" ]] && mkdir -p $ImageMagick_dir
echo `date` ": Create the $ImageMagick_dir directory..." >> $logfile
current_dir=`pwd`
git_clone https://github.com/ImageMagick/ImageMagick.git https://gitee.com/skillf/ImageMagick.git $ImageMagick_dir $logfile
cd $ImageMagick_dir
./configure
make clean && make uninstall
make && make install
cd $current_dir
echo `date` ": ImageMagick installation is complete..." >> $logfile

### install betterlockscreen
[[ ! -d "$userhome/.config/locksreen" ]] && mkdir -p $userhome/.config/locksreen
echo `date` ": Create the $userhome/.config/locksreen directory..." >> $logfile
cp $config_dir/background/lockscreen.jpg $userhome/.config/locksreen
current_dir=`pwd`
git_clone https://github.com/betterlockscreen/betterlockscreen.git https://gitee.com/skillf/betterlockscreen.git $betterlockscreen_dir $logfile
cd $betterlockscreen_dir
./install system latest true
# -u Update lock screen image
# --blur Blur image N amount(0.0 - 1.0)
betterlockscreen -u $userhome/.config/locksreen/lockscreen.jpg --blur 1.0
# -l Lock screen with cached image
# dimblur :
#  --dim <N>
#      Dim image N percent (0-100)
#  --blur <N>
#      Blur image N amount (0.0-1.0)
betterlockscreen_target=`sed -n '/betterlockscreen/p' $userhome/.config/sxhkd/sxhkdrc`
if [ -z "$betterlockscreen_target" ]; then
	sed -i '/# program launcher/i\# lock screen' $userhome/.config/sxhkd/sxhkdrc
	sed -i '/# lock screen/a\super + l' $userhome/.config/sxhkd/sxhkdrc
	sed -i '/super + l/a\        betterlockscreen -l dimblur' $userhome/.config/sxhkd/sxhkdrc
	echo `date` ": Add the betterlockscreen hotkey in sxhkdrc.." >> $logfile
fi
cd $current_dir
echo `date` ": betterlockscreen installation is complete..." >> $logfile

# TODO:dmenu

echo `date` ": The bspwm installation configuration is complete !" >> $logfile
