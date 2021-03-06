#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-03 07:15:04
 # @FilePath: \archlinuxInstall\ohmyzsh.sh
### 

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x

install_dir="/archlinuxInstall"
if [ "$USER" != "root" ]; then
	install_dir="$HOME/archlinuxInstall"
fi

configfile="$install_dir/config/install.conf"
logfile="$install_dir/archlinuxInstall.log"

username=`awk -F "=" '$1=="username" {print $2}' $configfile`
download="$HOME/Downloads"

shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
if [ ! -d "$download" ]; then
	mkdir -p "$download"
fi

# ohmyzsh shell
if [ "$USER" = "$username" ]; then
	sudo pacman -S --noconfirm --needed zsh
else
	pacman -S --noconfirm --needed zsh
fi
echo `date` ": Zsh shell installation is complete !" >> $logfile
rm -rf $download/ohmyzsh
echo `date` ": Download and install ohmyzsh ..." >> $logfile

set +e
while ! git clone https://github.com/skillf-qf/ohmyzsh.git $download/ohmyzsh; do
set -e
	echo `date` ": \"git clone ohmyzsh.git\" tries to reconnect ..." >> $logfile
	echo -e "\033[31m\"git clone ohmyzsh.git\" tries to reconnect ...\033[0m\n"
	sleep 3
done

chmod a+x $download/ohmyzsh/tools/uninstall.sh
echo y | $download/ohmyzsh/tools/uninstall.sh
rm -rf $HOME/.zsh*
echo n | $download/ohmyzsh/tools/install.sh

# change zsh
echo `date` ": Change the $USER shell ..." >> $logfile
if [ "$USER" = "$username" ]; then
	sudo sed -i "s#home/$USER:/bin/bash#home/$USER:/bin/zsh#g" /etc/passwd
	cp $HOME/.bash_profile $HOME/.zprofile
 	sed -i 's/bash/zsh/g' $HOME/.zprofile
else
	sed -i "s#$USER:/bin/bash#$USER:/bin/zsh#g" /etc/passwd
	# Change root shell prompt
	sed -i 's/\$ \%{\$reset_color\%}/\# \%{\$reset_color\%}/g' $HOME/.oh-my-zsh/themes/ys.zsh-theme
fi

# install zsh-autosuggestions | add ohmyzsh history time | change ohmyzsh Theme: ys
echo `date` ": Install zsh-autosuggestions | Add ohmyzsh history time | Change ohmyzsh Theme: ys ..." >> $logfile
zshsuggestions_dir="$HOME/.zsh/zsh-autosuggestions"
rm -rf $HOME/.zsh

set +e
while ! git clone https://github.com/skillf-qf/zsh-autosuggestions.git $zshsuggestions_dir; do
set -e
	echo `date` ": \"git clone zsh-autosuggestions.git\" tries to reconnect ..." >> $logfile
	echo -e "\033[31m\"git clone zsh-autosuggestions.git\" tries to reconnect ...\033[0m\n"
	sleep 3
done

sed -i "/^# ZSH_CUSTOM/a\\ZSH_CUSTOM=`echo $zshsuggestions_dir`" $HOME/.zshrc
sed -i '/^# HIST_STAMPS/a\\HIST_STAMPS=\"\%Y-\%m-\%d \%H:\%M:\%S  \" ' $HOME/.zshrc
sed -i 's/^ZSH_THEME/# ZSH_THEME/g ' $HOME/.zshrc
sed -i '/^# ZSH_THEME=/a\\ZSH_THEME="ys"' $HOME/.zshrc

# powerline fonts
echo `date` ": Install powerline fonts ..." >> $logfile
rm -rf $download/powerlinefonts

set +e
while ! git clone https://github.com/skillf-qf/fonts.git $download/powerlinefonts; do
set -e
	echo `date` ": \"git clone fonts.git\" tries to reconnect ..." >> $logfile
	echo -e "\033[31m\"git clone fonts.git\" tries to reconnect ...\033[0m\n"
	sleep 3
done
chmod a+x $download/powerlinefonts/uninstall.sh
$download/powerlinefonts/uninstall.sh
$download/powerlinefonts/install.sh

echo `date` ": The ohmyzsh installation configuration is complete !" >> $logfile


