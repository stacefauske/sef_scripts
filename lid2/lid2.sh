#!/bin/bash
#
# Upon lid close:
#  Suspend laptop if it's unplugged
#  start xscreensaver if it's plugged
#
# Problem we have is that the script will run again if the lid event is passed.
# If the original script is not done running it will not work correctly <-sef>



# troubleshooting flag, 1 or 0
ts=0
[ "${ts}" -eq 1 ] && echo -e "\ntroubleshooting mode ON\n"



case ${1} in
  [oO][fF][fF] )
    echo ""
    echo " Disabling suspend on lid close"
    echo 'off' > /usr/sef/.sef-scripts/lid2_unplugged
    exit 0
  ;;
  [oO][nN] )
    if [ ! "${2}" ] ; then
      echo " Enter time in minutes to suspend when UNPLUGGED and lid is closed."
      echo " The time must be >= 1 minute. (If lower it will default to 1 min)"
      echo " Like this --"
      echo "     lid2.sh on 1"
      echo ""
      lid2_onoff=`cat /usr/sef/.sef-scripts/lid2_unplugged | head -1`
      changemind=`cat /usr/sef/.sef-scripts/lid2_unplugged | tail -1`  ## total time (sec) until screensaver or suspend if UNPLUGGED?
      echo "Currently, suspend on lid close is set to --"
      [ "${lid2_onoff}" == "on" ] && echo "    ${lid2_onoff} after ${changemind} minutes"
      [ "${lid2_onoff}" == "off" ] && echo "    ${lid2_onoff}"
      echo ""
      echo " Exiting"
      exit 0
    fi
    
    if [ "${2}" -lt 1 ] ; then
      echo " The time must be >= 1 minute. (If lower it will default to 1 min)"
      echo " Like this --"
      echo "     lid2.sh on 1"
      echo ""
      lid2_onoff=`cat /usr/sef/.sef-scripts/lid2_unplugged | head -1`
      changemind=`cat /usr/sef/.sef-scripts/lid2_unplugged | tail -1`  ## total time (sec) until screensaver or suspend if UNPLUGGED?
      echo "Currently, suspend on lid close is set to --"
      [ "${lid2_onoff}" == "on" ] && echo "    ${lid2_onoff} after ${changemind} minutes"
      [ "${lid2_onoff}" == "off" ] && echo "    ${lid2_onoff}"
      echo ""
      echo " Exiting"
      exit 0
    fi
    
    echo ""
    echo " Enabling suspend on lid close after ${2} minutes"
    echo -e "on\n${2}" > /usr/sef/.sef-scripts/lid2_unplugged
    exit 0
  ;;
  [hH][eE][lL][pP]|?|--[hH][eE][lL][pP]|-h )
    echo ""
    echo "To disable suspend on lid close do --"
    echo "   lid2.sh off"
    echo "To enable suspend on lid close do --"
    echo "   lid2.sh on 1"
    echo ""
    lid2_onoff=`cat /usr/sef/.sef-scripts/lid2_unplugged | head -1`
    changemind=`cat /usr/sef/.sef-scripts/lid2_unplugged | tail -1`  ## total time (sec) until screensaver or suspend if UNPLUGGED?
    echo "Currently, suspend on lid close is set to --"
    [ "${lid2_onoff}" == "on" ] && echo "    ${lid2_onoff} after ${changemind} minutes"
    [ "${lid2_onoff}" == "off" ] && echo "    ${lid2_onoff}"
    exit 0
  ;;
  * )
    echo -e "\nScript is running normally.\n\nFor help or to change options type:\n    lid2.sh -h"
  ;;
esac



sleep 5   # give a little time before running the script



# Only run this section if UNPLUGGED
adapterstate=`acpi -V | grep "Adapter 0" | cut -d\  -f3` # check adapterstate again
if [ "${adapterstate}" = off-line ] ; then
  lid2_onoff=`cat /usr/sef/.sef-scripts/lid2_unplugged | head -1`
  case ${lid2_onoff} in
    off )
        exit 0
    ;;
    * )
      # UNPLUGGED vars
      #~ changemind=60  ## total time (sec) until screensaver or suspend if UNPLUGGED?
      changemind=`cat /usr/sef/.sef-scripts/lid2_unplugged | tail -1`  ## total time (sec) until screensaver or suspend if UNPLUGGED?
      if [ ! "${changemind}" ] ; then
        changemind=1
      elif [ "${changemind}" -lt 1 ] ; then
        changemind=1
      elif [ "${changemind}" == "on" ] ; then
        changemind=1
      elif [ "${changemind}" == "off" ] ; then
        changemind=1
      fi
      # convert ${changemind} from minutes to seconds here so script can process it
      changemind=$(( changemind * 60 ))
      [ "${ts}" -eq 1 ] && echo " TS suspending after ${changemind} seconds" && exit 4
      unplug_inc_time=5 ## increment check time (sec) when UNPLUGGED
    ;;
  esac
else # run if PLUGGED-IN
  changemind=60 # time to change mind before locking the screen if plugged-in
  unplug_inc_time=5 # initial increment check time (sec) when plugged in (the plugged-in increment time changes to $plug_inc_time)
fi


##### VARS #####
changemind_1=10 ## original short interval (sec) to allow for a change of mind, if lid is opened
locksleep_time=10 ## sleep time (sec) after locking the screen
#
# PLUGGED vars
#plugsleeptime
#plugsleeptime=$((hrs*60*60)) --> results in necessary seconds
#plugsleeptime array hrs === [0]=30min [1]=1hr [2]=2hrs [3]=3hrs [4]=4hrs [5]=5hrs [6]=6hrs
#change plugsleeptime array position in 'pluggedsleep' function
aplugsleeptime=(1800 3600 7200 10800 14400 18000 21600) # amount of time (seconds) before PC goes to sleep
plugsleeptime=${aplugsleeptime[4]} # set sleep time here from array above -- [0] is first in array
plug_inc_time=30 ## increment re-check time (sec) when plugged in
#
# screensaver & lock vars
xlockscreen='xscreensaver-command -lock'
elockscreen='enlightenment_remote -desktop-lock'
# change 'lockscreen' var depending on which lock type above is desired
lockscreen="${xlockscreen}"
#~ lockscreen="${elockscreen}"
#
lidstate=`grep -o open /proc/acpi/button/lid/LID/state`
#
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
            # Removed lockscreen here
            #~ eval ${lockscreen} # Lock screen
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
            eval ${lockscreen} # Lock screen
            sleep ${locksleep_time}
            pluggedsleep # function
            exit 0
        fi
        z=$(( z + unplug_inc_time ))
    done
    
    adapterstate=`acpi -V | grep "Adapter 0" | cut -d\  -f3` # check adapterstate again
    if [ "${adapterstate}" = on-line ] ; then # Check if adapter plugged in
      eval ${lockscreen} # Lock screen
      sleep ${locksleep_time}
      pluggedsleep # function
      
    else # If adapter is un-plugged
      eval ${lockscreen} # Lock screen
      sleep ${locksleep_time}
      sudo pm-suspend
      exit 0
    fi
  fi
fi

exit 0
