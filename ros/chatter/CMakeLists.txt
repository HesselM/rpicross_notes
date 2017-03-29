cmake_minimum_required(VERSION 2.8.3)

# Projectname
project(chatter)

# Find catkin and any catkin packages
find_package(catkin REQUIRED COMPONENTS roscpp std_msgs)

# Declare a catkin package
catkin_package()

# Include catkin
include_directories(include ${catkin_INCLUDE_DIRS})

# Source: Publisher
add_executable(publisher publisher.cpp)
target_link_libraries(publisher ${catkin_LIBRARIES})

# Source: Subscriber
add_executable(subscriber subscriber.cpp)
target_link_libraries(subscriber ${catkin_LIBRARIES})


