#!/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-12-09 16:50:04
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
else
	install_dir="$HOME/archlinuxInstall"
	sudo pacman -S --noconfirm --needed zsh
fi
source $install_dir/function.sh

echo `date` ": Zsh shell installation is complete !" >> $logfile
echo `date` ": The system starts to install and configure ohmyzsh..." >> $logfile

download="$HOME/Downloads"
ohmyzsh_dir="$download/ohmyzsh"
zshsuggestions_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
powerlinefonts_dir="$download/powerlinefonts"
powerlevel10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

[[ ! -d "$download" ]] && mkdir -p "$download"

# ohmyzsh shell
echo `date` ": Download and install ohmyzsh..." >> $logfile

git_clone https://github.com/ohmyzsh/ohmyzsh.git https://gitee.com/skillf/ohmyzsh.git $ohmyzsh_dir $logfile
chmod +x $ohmyzsh_dir/tools/install.sh $ohmyzsh_dir/tools/uninstall.sh
echo y | $ohmyzsh_dir/tools/uninstall.sh
rm -rf $HOME/.zsh*
echo n | $ohmyzsh_dir/tools/install.sh

echo `date` ": The ohmyzsh installation is successful !" >> $logfile

## change zsh
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

## Add ohmyzsh history time
sed -i '/^# HIST_STAMPS/a\HIST_STAMPS=\"\%Y-\%m-\%d \%H:\%M:\%S  \" ' $HOME/.zshrc
echo `date` ": Add ohmyzsh history time..." >> $logfile

## Change ohmyzsh Theme: ys
sed -i 's/^ZSH_THEME/# ZSH_THEME/ ' $HOME/.zshrc
sed -i '/^# ZSH_THEME=/a\ZSH_THEME="ys"' $HOME/.zshrc
echo `date` ": Change ohmyzsh Theme: ys..." >> $logfile

# Add the zsh plugin : zsh-autosuggestions
echo `date` ": Add-in zsh-autosuggestions configuration..." >> $logfile
git_clone https://github.com/zsh-users/zsh-autosuggestions.git https://gitee.com/skillf/zsh-autosuggestions.git $zshsuggestions_dir $logfile
sed -i '/^plugins=(git)/plugins=(git zsh-autosuggestions)' $HOME/.zshrc
echo `date` ": The zsh-autosuggestions plugin is configured !" >> $logfile

# Add a zsh theme : powerlevel10k
#echo `date` ": Add a powerLevel10K zsh theme..." >> $logfile
#git_clone https://github.com/romkatv/powerlevel10k.git https://gitee.com/romkatv/powerlevel10k.git $powerlevel10k_dir $logfile
#sed -i 's/^ZSH_THEME="ys"/#ZSH_THEME="ys"/ ' $HOME/.zshrc
#sed -i '/^#ZSH_THEME="ys"/a\ZSH_THEME="powerlevel10k/powerlevel10k"' $HOME/.zshrc

# Powerline fonts
echo `date` ": Install powerline fonts ..." >> $logfile
git_clone https://github.com/powerline/fonts.git https://gitee.com/skillf/fonts.git $powerlinefonts_dir $logfile
chmod +x $powerlinefonts_dir/install.sh $powerlinefonts_dir/uninstall.sh
$powerlinefonts_dir/uninstall.sh
$powerlinefonts_dir/install.sh
echo `date` ": The powerline fonts installation is successful !" >> $logfile

echo `date` ": The ohmyzsh is installed and configured successfully !" >> $logfile
