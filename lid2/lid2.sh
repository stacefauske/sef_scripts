#!/bin/bash
#
# Upon lid close:
#  Suspend laptop if it's unplugged
#  start xscreensaver if it's plugged
#
# Problem we have is that the script will run again if the lid event is passed.
# If the original script is not done running it will not work correctly <-sef>


sleep 5   # give a little time before running the script



##### VARS #####
changemind_1=10 ## original short interval (sec) to allow for a change of mind, if lid is opened
locksleep_time=10 ## sleep time (sec) after locking the screen
# unplugged vars
changemind=60  ## total time (sec) until screensaver or suspend if unplugged?
unplug_inc_time=1 ## increment check time (sec) when unplugged
# plugged vars
plug_inc_time=30 ## increment re-check time (sec) when plugged in
#plugsleeptime
#plugsleeptime=$((hrs*60*60)) --> results in necessary seconds
#plugsleeptime array hrs === [0]=30min [1]=1hr [2]=2hrs [3]=3hrs [4]=4hrs [5]=5hrs [6]=6hrs
#change plugsleeptime array position in 'pluggedsleep' function
aplugsleeptime=(1800 3600 7200 10800 14400 18000 21600) # amount of time (seconds) before PC goes to sleep
plugsleeptime=${aplugsleeptime[4]} # set sleep time here from array above
#~ echo "plugsleeptime is ${plugsleeptime}"   # t/s #
#~ echo "aplugsleeptimes are ${aplugsleeptime[*]}"   # t/s #
#

#~ lockscreen='xscreensaver-command -lock'
elockscreen='enlightenment_remote -desktop-lock'

lidstate=`grep -o open /proc/acpi/button/lid/LID/state`

#~ adapterstate=`acpi -V | grep "Adapter 0" | cut -d\  -f3`
##### END VARS #####



##### FUNCTIONS #####
function pluggedsleep () {
    z=0
    until [ "$z" -ge "${plugsleeptime}" ] ; do
        sleep ${plug_inc_time}
        lidstate=`grep -o open /proc/acpi/button/lid/LID/state` # check lidstate again
        if [ "${lidstate}" = open ] ; then
            exit 0
        fi
        adapterstate=`acpi -V | grep "Adapter 0" | cut -d\  -f3` # check adapterstate again
        if [ "${adapterstate}" = off-line ] ; then
            #~ eval ${elockscreen} # Lock screen
            #~ sleep 3
            sudo pm-suspend
            exit 0
        fi
        z=$(( z + plug_inc_time ))
    done
    sudo pm-suspend
    exit 0
}

#~ function unpluggedsleep () {
  #~ #
#~ }
##### END FUNCTIONS #####



if [ "${lidstate}" = open ] ; then
  exit 0 # Exit if the lid's actually reporting open
  
else
  sleep ${changemind_1} # Allow some time for a change of mind - comment to disable
  changemind=$(( changemind - changemind_1 ))
  
  lidstate=`grep -o open /proc/acpi/button/lid/LID/state` # check lidstate again
  if [ "${lidstate}" = open ] ; then
    exit 0 # Exit if the lid's actually reporting open
    
  else
    # Count to $changemind value, if lid is opened before $changemind, do not lock or suspend
    z=0
    until [ "$z" -ge "$changemind" ] ; do 
        sleep ${unplug_inc_time}
        lidstate=`grep -o open /proc/acpi/button/lid/LID/state` # check lidstate again
        if [ "${lidstate}" = open ] ; then
            exit 0
        fi
        adapterstate=`acpi -V | grep "Adapter 0" | cut -d\  -f3` # check adapterstate again
        if [ "${adapterstate}" = on-line ] ; then # Check if adapter plugged in
            eval ${elockscreen} # Lock screen
            sleep ${locksleep_time}
            pluggedsleep # function
            exit 0
        fi
        z=$(( z + unplug_inc_time ))
    done
    
    adapterstate=`acpi -V | grep "Adapter 0" | cut -d\  -f3` # check adapterstate again
    if [ "${adapterstate}" = on-line ] ; then # Check if adapter plugged in
      eval ${elockscreen} # Lock screen
      sleep ${locksleep_time}
      pluggedsleep # function
      
    else # If adapter is un-plugged
      eval ${elockscreen} # Lock screen
      sleep ${locksleep_time}
      sudo pm-suspend
      exit 0
    fi
  fi
fi

exit 0
