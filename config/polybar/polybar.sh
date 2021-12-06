###
 # @Author: skillf
 # @Date: 2021-11-07 17:49:15
 # @LastEditTime: 2021-12-06 15:37:26
 # @FilePath: \archlinuxInstall\config\polybar\polybar.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

source /archlinuxInstall/function.sh

download="$HOME/Downloads"
siji_dir="$download/siji"
polybar_dir="$download/polybar"
userhome="/home/$username"

git_clone https://github.com/stark/siji.git https://gitee.com/skillf/siji.git \
	$siji_dir $logfile

chmod +x $siji_dir/install.sh
$siji_dir/install.sh
echo `date` ": Siji was successfully installed..." >> $logfile

add_startup 'xset +fp' 'xset +fp '"$userhome"'/.local/share/fonts'
add_startup 'xset fp' 'xset fp rehash'
echo `date` ":  Add the following snippet in $userhome/.config/startup/startup.sh..." >> $logfile

pacman -S --noconfirm xorg-xfd polybar ttf-font-awesome pulseaudio alsa-utils

# Configuration
[ ! -d "$userhome/.config/polybar" ] && mkdir -p $userhome/.config/polybar
echo `date` ": Create the $userhome/.config/polybar directory..." >> $logfile

if [ -s "$config_dir/polybar/config" ]; then
	cp $config_dir/polybar/config $userhome/.config/polybar/
else
	cp /usr/share/doc/polybar/config $userhome/.config/polybar/
fi
echo `date` ": Copy the polybar config to $userhome/.config/polybar.." >> $logfile

if [ -s "$config_dir/polybar/launch.sh" ]; then
	cp $config_dir/polybar/launch.sh $userhome/.config/polybar/
	chmod +x $userhome/.config/polybar/launch.sh
	launch_target=`sed -n '/launch.sh/p' $userhome/.config/bspwm/bspwmrc`
	if [ -z "$launch_target" ]; then
		sed -i '/pgrep -x sxhkd/a\$HOME/.config/polybar/launch.sh' $userhome/.config/bspwm/bspwmrc
	fi
	echo `date` ": Add the Polybar launch script in bspwmrc.." >> $logfile
fi

echo `date` ": Polybar installation and configuration complete !" >> $logfile
