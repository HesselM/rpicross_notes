# Combining it all together.

ROS Setup:
- ROS master in VM (`roscore`)
- ROS node in VM
- [headless] ROS node on RPi

Process
- `roscore` is started
- ROS node in VM is started
- ROS node in VM sends master-host to RPi
- ROS node in VM starts (headless) ROS node on RPi
- ROS node in VM captures key
    - Message is send to RPi
    - RPi captures image
    - RPi sends back image
    - ROS node in VM displays image with OpenCV.
- ROS node in VM shutsdown
    - ROS node in VM terminates ROS node on RPi
    
    
## Setup

