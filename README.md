### Installation

**------------**

#### Use Arch's USB installation disk

If using a USB installation disk, you should clone the source code first:

```bash
git clone https://https://github.com/skillf-qf/archlinuxInstall.git
```

Then put the source code in the root directory of ARCH's USB installation disk.

#### Boot the live environment

If you put the source code in the root directory of your USB installation disk,

you should copy the source code to `/root`:

```bash
cp -r /run/archiso/bootmnt/archlinuxInstall /root
```

Of course, if you have Internet access, you can clone the source code directly to the `/root` directory:

```bash
pacman -Syy git
git clone https://https://github.com/skillf-qf/archlinuxInstall.git /root/archlinuxInstall
```

Modify the parameters of the "archlinuxInstall/config/install.conf" variable

```bash
cd /root/archlinuxInstall
vim ./config/install.conf
```

Note : Please take a close look at the parameter comments of install.conf

Finally, execute the installation script

```bash
./install.sh
```

The installation process will be restarted twice.

After the first restart, the final installation configuration will be executed.

Please wait patiently. At this time, the terminal printing installation process will be automatically opened.

The second restart indicates that the whole installation process has been completed.

You can use `journalctl --user-unit bootrun.service` command to view the configuration of the bootstrap script.



### sxhkd

**------------**

Shortcuts are configured using sxhkd.

Sxhkd is a simple X hotkey daemon, by the developer of bspwm, that reacts to input events by executing commands.

The shortcut key to open `st` terminal (default) under bspwm is `Super + Return` .

The shortcut key configuration file is in `$HOME/.config/sxhkd/sxhkdrc` .



### bspwm

**------------**

The bspwm configuration file is in `$HOME/.config/bspwm/bspwmrc` .





Good Luck  !
