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
