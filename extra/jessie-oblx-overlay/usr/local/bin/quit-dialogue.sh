#!/usr/bin/env bash
# quit-dialogue.4
# For openbox, xscreensaver. Need sudo allowed for halt and reboot.


yad	 --title="Exit Choices" \
        --width=350 --height=60  \
	--button="Lock Screen"!/usr/share/icons/nuoveXT2/22x22/actions/lock.png:0 \
	--button=Logout!/usr/share/icons/nuoveXT2/22x22/actions/application-exit.png:1 \
	--button=Reboot!/usr/share/icons/nuoveXT2/22x22/actions/gtk-refresh.png:2 \
	--button=Shutdown!/usr/share/icons/nuoveXT2/22x22/actions/system-shutdown.png:3 \
	--button=Cancel!/usr/share/icons/nuoveXT2/22x22/actions/gtk-close.png:4
#       --button="gtk-close:4"

	
answer="$?"

	case $answer in
		0) xscreensaver-command -lock ;;
#		1) openbox --exit ;;
		1) pkill -u $USER ;;
		2) sudo /sbin/reboot ;;
		3) sudo /sbin/halt ;;
		4) exit 0 ;;
	esac

exit 0
