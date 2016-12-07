#!/bin/bash
#

# This script will ping the network for a range
# of ip addresses.
#
# If a single -q switch is appended, there will not be verbose output
#
# Set the variables below appropriately:


echo ""


# checking to make sure script is running with root privileges
if [ "$(whoami)" != "root" ] ; then
    echo " This script will perform better as root or run with sudo."
    echo " But you can still run it without being sudo."
    echo "   To quit hit <ctrl + c>"
    echo -n "   To continue hit <return>  "
    read redy
    echo " ---------------------------"
    echo ""
fi


#######################################################
### set these vars for ping address and output file

# log file in current directory
fileforlog="pingsuccesses.txt"

# first 3 fields of ip address:
ipstart="192.168.0"


# starting ip address (last field) to ping
startip="1"

# ending ip address (last field) to ping
endip="254"

# # # # # # # # # # # # # # # # # # # # # # # # # # # #

# these can probably be left as-is:
#
# ping command to use
# default = ping -c2 -W1
pngcmd="ping -c1 -W1"
# arping command to use
# default = arping -c1 -I p2p1 ${ipstart}.${i}
apngcmd="arping -c1 -I p2p1"
#~ apngcmd="arp -an"
arpcmd="arp -an"
nmapcmd="nmap -sP -PE -PA"

#######################################################

if [ "$1" ] ; then
  ipstart="${1}"
  if [ "$2" ] ; then
    fileforlog="$2"
  else
    cat << NOLOG
 You need to specify a log file if you are
 specifying an IP mask from the command line.

 You can force your own IP mask and log file
 from the command line like this:
    ./range_ping.sh 10.0.0 logfile.txt

 You cannot overwrite an existing log file.
 Current files in this directory:
NOLOG
    ls -Fb1
    echo ""
    echo " EXITING"
    exit 0
  fi
else
  cat << MESSAGE1
 Range to be pinged will be:
    ${ipstart}.${startip} thru ${endip}
 Log file will be:
    ${fileforlog}

 You can force your own IP mask and log file
 from the command line like this:
    ./range_ping.sh 10.0.0 logfile.txt

  To quit hit <ctrl + c>  
  To continue as-is hit <return>
MESSAGE1
  read redy
  echo " ---------------------------"
fi



if [ -e "${fileforlog}" ] ; then
  cat << FILEEXISTS

 File "${fileforlog}" already exists!
 Cannot overwrite an existing file!
   EXITING
FILEEXISTS
  exit 0
fi


touch ./${fileforlog}
chmod 664 ./${fileforlog}


echo "" > ./${fileforlog}
echo " -- Started -- `date`" | tee -a ./${fileforlog}
echo "" | tee -a ./${fileforlog}
echo "   ==========================" | tee -a ./${fileforlog}
echo "  /" | tee -a ./${fileforlog}
echo " <  PINGING ${ipstart}.xxx" | tee -a ./${fileforlog}
echo "  \\" | tee -a ./${fileforlog}
echo "   ==========================" | tee -a ./${fileforlog}

#~ echo ""
#~ echo " -- Started -- `date`"
#~ echo " PINGING ${ipstart}.xxx"
echo ""
echo ""
echo ""


for i in $(seq ${startip} ${endip}); do
  case "$1" in
    -q )
    ;;
    * )
      echo ""
      echo -n " === pinging ${ipstart}.${i} ==="
    ;;
  esac
  try=`${pngcmd} ${ipstart}.${i} | tail -2 | grep -v errors | grep -v pipe | grep -v '100% packet loss'`
  if [ "${try}" ] ; then
    case "$1" in
      -q )
      ;;
      * )
        echo -e "\n ========================================="
        echo      " === pinging ${ipstart}.${i} === FOUND ==="
        echo      " ========================================="
        echo "${try}"
      ;;
    esac
    echo " ---------------------------" >> ./${fileforlog}
    echo "" | tee -a ./${fileforlog}
    echo "Found at ${ipstart}.${i}" | tee -a ./${fileforlog}
    echo ""
    echo ${try} >> ./${fileforlog}
    ${apngcmd} ${ipstart}.${i} | tee -a ./${fileforlog}
    ${arpcmd} ${ipstart}.${i} | tee -a ./${fileforlog}
    ${nmapcmd} ${ipstart}.${i} | tee -a ./${fileforlog}
    echo "" | tee -a ./${fileforlog}
    echo " ---------------------------"
  fi
done

#~ echo "" >> ./${fileforlog}
#~ echo " -- Ended --   `date`" >> ./${fileforlog}
#~ echo "" >> ./${fileforlog}

echo "" | tee -a ./${fileforlog}
echo "" | tee -a ./${fileforlog}
echo " ---------------------------" | tee -a ./${fileforlog}
echo " ---------------------------" | tee -a ./${fileforlog}
echo " ---------------------------" | tee -a ./${fileforlog}
echo "" | tee -a ./${fileforlog}
echo " -- Ended --   `date`" | tee -a ./${fileforlog}
echo "" | tee -a ./${fileforlog}

exit 0
