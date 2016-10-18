#!/bin/bash

DIR=/root/gopro
CONTAINER=gopro

export ST_AUTH=https://sjc01.objectstorage.softlayer.net/auth/v1.0/
export ST_USER=changeme
export ST_KEY=changeme

files=`ls $DIR/*.MP4`
echo `date` starting..

for file in $files
do
  fname=`echo $file | cut -d "/" -f4`
  echo `date` upload $file
  success=1
  while [ $success -ne 0 ]
  do
    echo `date` attempting upload
    pref=`date +%s`
    /usr/local/bin/swift upload --object-name $pref.$fname $CONTAINER $file
    success=$?
  done

  echo `date` "uploaded.. removing" $file
  rm $file
done

echo `date` "all done"
