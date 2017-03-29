#!/bin/bash

# Default ssh-host?
host="$1"
if [ -z "$1" ]; then
  host="rpizero-local"
fi

# Find all 'devel*' folders: contain compiled source
files=$(find ~/ros -name "devel*" -type d)

# Sync folders with rpi
rsync -auHWvRO --no-perms --no-owner --no-group --delete -e "ssh -o StrictHostKeyChecking=no" $files $host:/

# Copy ROS-source too
rsync -auHWvRO --no-perms --no-owner --no-group --delete -e "ssh -o StrictHostKeyChecking=no" /home/pi/ros/src_cross/src $host:/
