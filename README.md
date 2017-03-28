This example-live-sdk was cloned from live-sdk by parazyd (Ivan J.) and jaromil (Denis Roio) and then modified by fsmithred. Variables were created so that all configuration can take place in two files. 

The following is not an explanation of all the parts of live-sdk. This is a quick start guide to get you making your own custom isos for live-CD/DVD/USB with a minimum of configuration. For a more in-depth explanation of live-sdk, see Inside Heads by parazyd.  And for a more complex configuration, see the heads sdk. ***(Need links)*** 



Where to start?

- clone or download example-live-sdk (hereafter called 'live-sdk' in this document)
- cd live-sdk   # This is your working directory.

There are two files in the live-sdk directory that you need to edit or create - the config file and the blend file. 

You should not need to change any of the other files, but that is certainly an option, and it may be needed in some cases.

- edit live-sdk/config.
	If you will be making several blends, name it config.<blend-name>
	Absolute minumum contents would be:
	
			#!/usr/bin/env zsh
			blend_name="absolute-minimum"
			blend_location="$R/extra/${blend}.blend"   
			
	Note: $R is the working directory, live-sdk. The blend_location can be a local path as shown, or it can be a url for a blend file online.


- edit the blend file. Name it <blend-name>.blend and save it in live-sdk/extra/.
	Absolute minimum contents of the blend file:
	
			#!/usr/bin/env zsh
			source "$configfile"


Run the build with the following commands. Change arch to amd64 or i386. Change configfile to the name of your config file. (just the name, not the path) 

	zsh -f
	source sdk <configfile>
	load devuan <arch> <blend_name>
	build_iso_dist

That will give you a system built from debootstrap plus core_packages and base_packages
with no user. The root password will be "toor". The iso file will be in live-sdk/dist.

core_packages is a list of packages that corresponds roughly to what you get if you un-check all boxes in the debian/devuan installer's tasksel window.

base_packages is a list of packages that corresponds roughtly to what you get if you leave "standard system utilities" checked at the tasksel window.

YOU SHOULD NOT NEED TO CHANGE THE CORE PACKAGES OR BASE PACKAGES LISTS. (They're in live-sdk/lib/libdevuansdk/config if you want to change them.)
These lists are my best approximation at this time. They might need tweaking.

ADD PACKAGES by populating the extra_packages list in your config file.

You can customize functions by bringing them up into the blend file and by defining some variables in the config file. 
Some examples are explained below.


___ SIMPLE BLEND ___

CONFIG FILE:
Look at live-sdk/config.simple. Some items are self-explanatory. Some need some explanation.

rootfs_overlay - Files placed in this tree will be copied into the system after packages have been installed. Use this for any custom configs or other files you want to add to the system.
isolinux_overlay - Files placed here will be copied to the isolinux directory in the iso. Put isolinux boot splash and/or boot help files here.

The overlay for the simple example contains a few files for icewm settings (replaces the debian logo on the panel with a devuan swoosh), xdg-user-dir files to prevent the automatic creation of a bunch of directories in your home, and an apt-config file to prevent automatic installation of Recommends. Note that this apt-config will not be active during the build, because it gets added after packages are installed. If you want to exclude Recommends during the build, you need to dig deeper (zlibs/bootstrap) and edit the 'apt-get install' lines.

```
extra/simple-overlay/
├── etc
│   ├── apt
│   │   └── apt.conf.d
│   │       └── 00norecommends
│   ├── X11
│   │   └── icewm
│   │       ├── focus_mode
│   │       └── theme
│   └── xdg
│       ├── user-dirs.conf
│       └── user-dirs.defaults
└── usr
    └── share
        └── icewm
            └── taskbar
                └── icewm.xpm
```

The extra_packages list contains a few items to give you a working graphical environment.


BLEND FILE:
Look at live-sdk/extra/simple.blend. Some functions have been copied from the deeper files and modified. Their presence in the blend file will override the unmodified functions.

blend_preinst() and blend_postinst() are copied and modified from live-sdk/lib/libdevuansdk/zlibs/helpers.

blend_preinst() calls the add-user function, which adds an unprivileged user with the login and password set in your config file.

blend_postinst() copies the rootfs-overlay files into place. Note that this example is set for copying from local files. Use the commented code if the overlay files are in a git repository.
The last thing the postinstall function does is call blend_finalize(). 

blend_finalize() only exists in the blend file and contains code for whatever you want to do to the system before it gets squashed and put in the iso.
Everything between 'cat <<EOF' and 'EOF' gets put into a script that runs in the chroot environment. Commands inside this shell script will be run with root privileges. 
In this example, the user gets added to some groups, user's default shell is set, user is given ownership of files and /etc/fstab is removed. (live-boot will create an appropriate fstab when you boot the live system.)

Other commands in the function that will not be included in the shell script may require sudo. 
The last two lines in this function copy some error logs to live-sdk/extra/logs.

To build this example blend, run:

	zsh -f
	source sdk config.simple
	load devuan amd64 simple
	build_iso_dist
	


___ MORE COMPLEX BLEND __

Look at config.jessie-oblx and jessie-oblx.blend. This will build a Devuan jessie with openbox and lxpanel. The build will include some custom packages and desktop clutter, a custom isolinux boot menu and will be bootable on uefi hardware.

The config file starts with a line to initialize the list of custom packages to be installed. The actual list is at the end of the config file. Put the packages in live-sdk/extra/custom-packages. 

Only those packages that are in the list will be installed. Other packages in that directory will be ignored.

Custom packages will be installed in alphanumeric order. If you have a package that needs to be installed before the others, put it in a separate list that comes ahead of the others. In this example, yad will be installed before the refracta tools that require yad will be installed.
For packages that have i386 and amd64 versions, put them in separate lists and comment out the list you don't want for the current build.

efi_work is a work directory for building the uefi boot files. You don't need to do anything with this variable or with this directory. It's where it is because I couldn't get it to work inside $workdir.

Look at live-sdk/extra/jessie-oblx.blend. 
- blend_postinst() has calls to iso_make_efi and install-custdebs. 
- iso_setup_isolinux has an added line to copy the isolinux_overlay files.
- iso_write_isolinux()_cfg has a modified boot menu. (Tired of that 30-second boot delay yet?)
- iso_squash_strap() has -noappend added (this might have been merged upstream.) and more aggressive compression. (read: smaller but slower to squash, and specific to x86 arch.)
- iso_xorriso_build() has an added line for uefi boot. (line starts with -eltorito-alt-boot)
- iso_make_efi() creates the uefi boot files.
- purge_packages contains a list of packages (only one) to be purged at the end. In this example, libsystemd0 has been added in case it sneaks in during the build.

To build this example blend, run:

	zsh -f
	source sdk config.jessie-oblx
	load devuan amd64 jessie-oblx
	build_iso_dist


___ TROUBLESHOOTING ___

Look in the output in the terminal.

Look in the log files in live-sdk/extra/logs.

One reason for failure of a section or the entire build is if any of the packages in the lists can't be found (like if you have a spelling error).



___ NOTES ON BUILDING ASCII/TESTING IMAGES ___

Right now (March 2017) rsyslog is getting removed at the end of the build. 
Workaround is to insert the following line into the debootstrap command at lines 42-44 of zlibs/bootstrap.
	
	--include=busybox,busybox-syslogd --exclude=rsyslog,alsa-base \



--------------------------------------------------
Original readme file for live-sdk is copied below.
--------------------------------------------------







live-sdk
========

live-sdk is simple distro build system aimed at creating liveCDs

## Requirements

live-sdk is designed to be used interactively from a terminal.
It requires the following packages to be installed in addition to the
[dependencies required for libdevuansdk](https://github.com/dyne/libdevuansdk/blob/master/README.md#requirements).

`sudo` permissions are required for the user that is running the build.

```
xorriso squashfs-tools live-boot
```

## Initial setup

After cloning the live-sdk git repository, enter it and issue:

```
git submodule update --init
```

### Updating

To update live-sdk, go to the root dir of the git repo and issue:

```
git pull && git submodule update --init --recursive
```

## Quick start

Edit the `config` file to match your needs. Sensible defaults are
already there. Then run zsh. To avoid issues, it's best to start a
vanilla version, without preloaded config files so it doesn't cause
issues with libdevuansdk/live-sdk functions.

```
; zsh -f -c 'source sdk'
```

Now is the time you choose the OS, architecture, and (optionally) a
blend you want to build the image for.

### Currently supported distros

* `devuan`

```
; load devuan amd64
```

Once initialized, you can run the helper command:

```
; build_iso_dist
```

The image will automatically be build for you. Once finished, you will be
able to find it in the `dist/` directory in live-sdk's root.

For more info, see the `doc/` directory.

## Acknowledgments

Devuan's SDK was originally conceived during a period of residency at the
Schumacher college in Dartington, UK. Greatly inspired by the laborious and
mindful atmosphere of its wonderful premises.

The Devuan SDK is Copyright (c) 2015-2017 by the Dyne.org Foundation

Devuan SDK components were designed, and are written and maintained by:

- Ivan J. <parazyd@dyne.org>
- Denis Roio <jaromil@dyne.org>
- Enzo Nicosia <katolaz@freaknet.org>

This source code is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This software is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with this source code. If not, see <http://www.gnu.org/licenses/>.
