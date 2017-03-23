#ssh -o StrictHostKeyChecking=no rpizero-local "mkdir -p /home/pi/ros/rpi_cross/"
rsync -auHWvR --no-perms --no-owner --no-group -e "ssh -o StrictHostKeyChecking=no" /home/pi/ros/rpi_cross/devel_isolated rpizero-local:/
rsync -auHWvR --no-perms --no-owner --no-group -e "ssh -o StrictHostKeyChecking=no" /home/pi/ros/rpi_cross/src rpizero-local:/
