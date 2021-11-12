#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-11-12 17:28:09
 # @FilePath: \archlinuxInstall\ohmyzsh.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

[[ "$USER" == "root" ]] && \
{ install_dir="/archlinuxInstall"; pacman -S --noconfirm --needed zsh; }

[[ "$USER" == "$username" ]] && \
{ install_dir="$HOME/archlinuxInstall"; sudo pacman -S --noconfirm --needed zsh; }

echo `date` ": Zsh shell installation is complete !" >> $logfile


configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

username=`awk -F "=" '$1=="username" {print $2}' $configfile`
download="$HOME/Downloads"
ohmyzsh_dir="$download/ohmyzsh"
zshsuggestions_dir="$HOME/.zsh/zsh-autosuggestions"
powerlinefonts_dir="$download/powerlinefonts"

shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
[[ ! -d "$download" ]] && mkdir -p "$download"

# ohmyzsh shell
[ -d "$ohmyzsh_dir" ] && rm -rf $ohmyzsh_dir
echo `date` ": Download and install ohmyzsh ..." >> $logfile

set +e
while ! git clone https://github.com/ohmyzsh/ohmyzsh.git $ohmyzsh_dir; do
set -e
	echo `date` ": \"git clone ohmyzsh.git\" tries to reconnect ..." >> $logfile
	echo -e "\033[31m\"git clone ohmyzsh.git\" tries to reconnect ...\033[0m\n"
	sleep 3
done

chmod +x $ohmyzsh_dir/tools/install.sh $ohmyzsh_dir/tools/uninstall.sh
echo y | $ohmyzsh_dir/tools/uninstall.sh
rm -rf $HOME/.zsh*
echo n | $ohmyzsh_dir/tools/install.sh

# change zsh
echo `date` ": Change the $USER shell ..." >> $logfile
if [ "$USER" = "$username" ]; then
	sudo sed -i "s#home/$USER:/bin/bash#home/$USER:/bin/zsh#g" /etc/passwd
	cp $HOME/.bash_profile $HOME/.zprofile
 	sed -i 's/bash/zsh/g' $HOME/.zprofile
else
	sed -i "s#$USER:/bin/bash#$USER:/bin/zsh#g" /etc/passwd
	# Change root shell prompt
	sed -i 's/\$ \%{\$reset_color\%}/\# \%{\$reset_color\%}/' $HOME/.oh-my-zsh/themes/ys.zsh-theme
fi

# Install zsh-autosuggestions & Add ohmyzsh history time & Change ohmyzsh Theme: ys
echo `date` ": Install zsh-autosuggestions | Add ohmyzsh history time | Change ohmyzsh Theme: ys ..." >> $logfile
[[ -d "$HOME/.zsh" ]] && rm -rf $HOME/.zsh

set +e
while ! git clone https://github.com/zsh-users/zsh-autosuggestions.git $zshsuggestions_dir; do
set -e
	echo `date` ": \"git clone zsh-autosuggestions.git\" tries to reconnect ..." >> $logfile
	echo -e "\033[31m\"git clone zsh-autosuggestions.git\" tries to reconnect ...\033[0m\n"
	sleep 3
done

sed -i "/^# ZSH_CUSTOM/a\\ZSH_CUSTOM=`echo $zshsuggestions_dir`" $HOME/.zshrc
sed -i '/^# HIST_STAMPS/a\\HIST_STAMPS=\"\%Y-\%m-\%d \%H:\%M:\%S  \" ' $HOME/.zshrc
sed -i 's/^ZSH_THEME/# ZSH_THEME/ ' $HOME/.zshrc
sed -i '/^# ZSH_THEME=/a\\ZSH_THEME="ys"' $HOME/.zshrc

# powerline fonts
echo `date` ": Install powerline fonts ..." >> $logfile
[[ -d "$powerlinefonts_dir" ]] && rm -rf $powerlinefonts_dir

set +e
while ! git clone https://github.com/powerline/fonts.git $powerlinefonts_dir; do
set -e
	echo `date` ": \"git clone fonts.git\" tries to reconnect ..." >> $logfile
	echo -e "\033[31m\"git clone fonts.git\" tries to reconnect ...\033[0m\n"
	sleep 3
done
chmod +x $powerlinefonts_dir/install.sh $powerlinefonts_dir/uninstall.sh
$powerlinefonts_dir/uninstall.sh
$powerlinefonts_dir/install.sh

echo `date` ": The ohmyzsh installation configuration is complete !" >> $logfile
https://gitee.com/skillf/hardware-design.git
