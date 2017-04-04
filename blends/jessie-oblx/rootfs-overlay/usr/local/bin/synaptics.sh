#!/bin/bash

# script name: synaptics.sh
# script location: /usr/local/bin
# set up synaptics touchpad with basic defaults
# not tested on other than synaptics
# run once (after login) then is automatic on relogin

# check for NOT root
   if [[ ! $EUID -ne 0 ]]; then
    echo "This script should not be run as root" 1>&2
      exit 1
   fi

if ! grep -iq "synaptics" /proc/bus/input/devices; then
echo "No synaptics touchpad was found"
exit 0
fi

####### xfce autostart
if [ -d ~/.config/autostart ]; then

if ! [ -f ~/.config/autostart/synaptics.desktop ]; then
cat > ~/.config/autostart/synaptics.desktop <<EOF

[Desktop Entry]
Comment=Enable synaptics touchpad
Encoding=UTF-8
Exec=/usr/local/bin/synaptics.sh
Hidden=false
Name=synaptics
StartupNotify=false
Terminal=false
Type=Application
Version=0.0.1

EOF
fi
fi

# execute now
echo "starting synclient..."
synclient TapButton1=1 LBCornerButton=2 RBCornerButton=3 MaxTapTime=140 SingleTapTimeout=140 MaxDoubleTapTime=140
