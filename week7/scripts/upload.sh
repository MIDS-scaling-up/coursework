#!/bin/bash

# add this file to crontab

DIR=/root/gopro
CONTAINER=gopro

#is there another instance running?

old=`pgrep sw_upload.sh`
if [ $? -eq 0 ]
then
  echo `date` another pid $old of sw_upload.sh running. exiting
  exit 1
fi

$DIR/sw_upload.sh > $DIR/out.log 2>&1
