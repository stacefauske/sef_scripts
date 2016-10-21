#!/bin/bash
#Recover from an Audacity crash by reassembling the saved data files


if [ $# != 2 ]; then
    echo -e "\nERROR: Not enough arguments\n  USAGE:"
    echo "$0   /source/path/   /destination/file.au"
    echo ""
    echo "  /source/path/"
    echo "      Must be a directory. Path containing *.au files, like 'project#####'"
    echo "      (Recursively finds *.au files. Relative to current directory, if desired)"
    echo "  /destination/file.au"
    echo "      Path to the desired output file."
    echo "      (Relative to current directory, if desired)"
    exit 1
fi

#~ DATA="$1/"
DATA="`basename $1`"
OUT=$2

if [ -e $OUT ]; then
    # Hope the path exists
    echo "ERROR: Output file exists ($OUT)"
    exit 1
fi

# Rename files according to timestamp
if [ ! -e "${DATA}/renamed" ] ; then
  mkdir -v ${DATA}/renamed
else
  echo "ERROR: Rename directory exists (${DATA}/renamed)"
fi

origfiles=`find ${DATA} -name "*.au"`

for i in ${origfiles} ; do
  timename=`ls -l --full-time ${i} | awk -F" " '{print$6,$7}' | tr -d '\-:\ ' | cut -d. -f1`
  #~ cp -vp ${i} ./renamed/e${timename}
  cp -vp ${i} ${DATA}/renamed/e${timename}.au
done

sleep 3

COUNT=1

newfiles=`ls -t1r ${DATA}/renamed/*.au`

#~ find ${DATA}/renamed/ -name "*.au" -print0 | while read -d $'\0' FILE ; do
for FILE in ${newfiles} ; do
  #The offsets are probably all going to be the same, but best check it
  OFFSET=$(echo $(od -i -j4 -N4 -An < $FILE) ) # Use echo for easy trim
  if [ $COUNT -eq 1 ]; then
    # Write the header
    dd ibs=$OFFSET count=1 if=$FILE of=$OUT
  fi
   echo "Adding $FILE (offset=$OFFSET)"
   dd ibs=$OFFSET skip=1 conv=notrunc oflag=append if=$FILE of=$OUT
   
   let COUNT+=1
done

echo "Done"

exit 0
