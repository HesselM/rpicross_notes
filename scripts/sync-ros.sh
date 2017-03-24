#ssh -o StrictHostKeyChecking=no rpizero-local "mkdir -p /home/pi/ros/src_cross/"
rsync -auHWvR --no-perms --no-owner --no-group -e "ssh -o StrictHostKeyChecking=no" /home/pi/ros/src_cross/devel_isolated rpizero-local:/
rsync -auHWvR --no-perms --no-owner --no-group -e "ssh -o StrictHostKeyChecking=no" /home/pi/ros/src_cross/src rpizero-local:/
