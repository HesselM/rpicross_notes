cmake_minimum_required(VERSION 2.8.3)

# Projectname
project(helloros)

# Find catkin and any catkin packages
find_package(catkin REQUIRED COMPONENTS roscpp rospy std_msgs genmsg)

# Declare a catkin package
catkin_package()

# Include catkin
include_directories(include ${catkin_INCLUDE_DIRS})

# Source
add_executable(helloros hello.cpp)

# Libraries
target_link_libraries(helloros ${catkin_LIBRARIES})
