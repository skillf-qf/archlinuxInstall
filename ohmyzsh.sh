#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-11-14 04:30:21
 # @FilePath: \archlinuxInstall\ohmyzsh.sh
###

# Print the command. The script ends when the command fails.
# -o pipefail : As soon as a subcommand fails, the entire pipeline command fails and the script terminates.
set -euo pipefail
# Please uncomment it to see how it works
#set -x


if [ "$USER" == "root" ]; then
	install_dir="/archlinuxInstall"
	pacman -S --noconfirm --needed zsh
elif [ "$USER" == "$username" ]
	install_dir="$HOME/archlinuxInstall"
	sudo pacman -S --noconfirm --needed zsh
fi
source $install_dir/function.sh

echo `date` ": Zsh shell installation is complete !" >> $logfile
echo `date` ": The system starts to install and configure ohmyzsh..." >> $logfile

download="$HOME/Downloads"
ohmyzsh_dir="$download/ohmyzsh"
zshsuggestions_dir="$HOME/.zsh/zsh-autosuggestions"
powerlinefonts_dir="$download/powerlinefonts"


[[ ! -d "$download" ]] && mkdir -p "$download"

# ohmyzsh shell
echo `date` ": Download and install ohmyzsh..." >> $logfile

git_clone https://github.com/ohmyzsh/ohmyzsh.git https://gitee.com/skillf/ohmyzsh.git $ohmyzsh_dir $logfile

chmod +x $ohmyzsh_dir/tools/install.sh $ohmyzsh_dir/tools/uninstall.sh
echo y | $ohmyzsh_dir/tools/uninstall.sh
rm -rf $HOME/.zsh*
echo n | $ohmyzsh_dir/tools/install.sh

echo `date` ": The ohmyzsh installation is successful !" >> $logfile

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
git_clone https://github.com/zsh-users/zsh-autosuggestions.git https://gitee.com/skillf/zsh-autosuggestions.git $zshsuggestions_dir $logfile

sed -i "/^# ZSH_CUSTOM/a\\ZSH_CUSTOM=`echo $zshsuggestions_dir`" $HOME/.zshrc
sed -i '/^# HIST_STAMPS/a\\HIST_STAMPS=\"\%Y-\%m-\%d \%H:\%M:\%S  \" ' $HOME/.zshrc
sed -i 's/^ZSH_THEME/# ZSH_THEME/ ' $HOME/.zshrc
sed -i '/^# ZSH_THEME=/a\\ZSH_THEME="ys"' $HOME/.zshrc

echo `date` ": Zsh-autosuggestions is successfully installed and configured !" >> $logfile

# powerline fonts
echo `date` ": Install powerline fonts ..." >> $logfile

git_clone https://github.com/powerline/fonts.git https://gitee.com/skillf/fonts.git $powerlinefonts_dir $logfile

chmod +x $powerlinefonts_dir/install.sh $powerlinefonts_dir/uninstall.sh
$powerlinefonts_dir/uninstall.sh
$powerlinefonts_dir/install.sh

echo `date` ": The powerline fonts installation is successful !" >> $logfile
echo `date` ": The ohmyzsh is installed and configured successfully !" >> $logfile
