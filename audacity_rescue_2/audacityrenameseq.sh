#!/bin/bash
#

# rename files sequentially according to their time of creation
#
# Handy for renaming Audacity '.au' files when Audacity crashes

namecount=10000000
renamedir="renamed"

for recdir in `ls -ltr --full-time | awk '{print$9}'` ; do

    if [ ! -d "$renamedir" ] ; then
        eval mkdir $renamedir
    fi
    
    if [ -d "$recdir" ] ; then
        eval cd $recdir
        
        for aufile in `ls -ltr --full-time | awk '{print$9}'` ; do
            mv $aufile e${namecount}.au
            namecount=$(( $namecount + 1 ))
        done
        
        eval cp -pf ./* ../$renamedir
        
        eval cd ..
    fi
done

exit 0
