#!/bin/bash
#

#xset dpms 0 0 300

## if screensaver daemon isn't running, just exit
#status_ss=`ps axu | grep xscreensaver | grep -v grep | grep -o xscreensaver`
#if [ ! "${status_ss}" ] ; then
#  exit 0
#fi


plugstate=`cat /sys/class/power_supply/AC0/online` # 1=plugged  0=unplugged
bat_SS="/home/sef/.xscreensaver-battery"
ac_SS="/home/sef/.xscreensaver-AC"
in_use_SS="/home/sef/.xscreensaver"

current_mode_SS=`cat .xscreensaver | grep -e '^mode' | grep -o blank`

case ${plugstate} in
  1 ) # 1=plugged
    if [ "${current_mode_SS}" ] ; then
      cp ${ac_SS} ${in_use_SS}
    fi
  ;;
  0 ) # 0=unplugged
    if [ ! "${current_mode_SS}" ] ; then
      cp ${bat_SS} ${in_use_SS}
    fi
  ;;
esac

exit 0

