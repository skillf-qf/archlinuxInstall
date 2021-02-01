#/bin/bash
###
 # @Author: skillf
 # @Date: 2021-01-23 23:51:42
 # @LastEditTime: 2021-02-01 13:17:26
 # @FilePath: \archlinuxInstall\ohmyzsh.sh
### 

install_dir="/chrootinstall"
configfile="$install_dir/config/install.conf"
user=`awk -F "=" '$1=="username" {print $2}' $configfile`
userhome="/home/$user"
download="$userhome/Downloads"

shell=`awk -F "=" '$1=="shell" {print $2}' $configfile`
if [ ! -d "$download" ]; then
	mkdir -p "$download"
fi

if [ "$shell" = "ohmyzsh" ] || [ -z "$shell" ]; then
	
    # ohmyzsh shell
    pacman -S --noconfirm zsh
	git clone https://github.com/skillf-qf/ohmyzsh.git $download/ohmyzsh
	sleep 2
	echo n | $download/ohmyzsh/tools/install.sh
	
    # change zsh
    sed -i 's/\/home\/$user:\/bin\/bash/\/home\/$user:\/bin\/zsh/g' /etc/passwd
    cp $userhome/.bash_profile $userhome/.zprofile
    sed -i 's/bash/zsh/g' $userhome/.zprofile
    
    # zsh suggestions | add history time | change Theme: ys
    zshsuggestions_dir="$userhome/.zsh/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $zshsuggestions_dir
    sed -i '/^# ZSH_CUSTOM/a\\ZSH_CUSTOM=$zshsuggestions_dir ' $userhome/.zshrc
    sed -i '/^# HIST_STAMPS/a\\HIST_STAMPS=\"\%Y-\%m-\%d \%H:\%M:\%S  \" ' $userhome/.zshrc
    sed -i 's/^ZSH_THEME/# ZSH_THEME/g ' $userhome/.zshrc
    sed -i '/^# ZSH_THEME=/a\\ZSH_THEME="ys"' $userhome/.zshrc

    # powerline fonts
    git clone https://github.com/powerline/fonts.git $download/powerlinefonts
    $download/powerlinefonts/install.sh
fi


