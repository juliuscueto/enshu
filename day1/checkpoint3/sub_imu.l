#!/usr/bin/env roseus

(ros::load-ros-manifest "kobuki_msgs")
(ros::roseus "bumper_subscriber")

(defun imu-cb (msg) (format t ";; imu x: ~A, y: ~A, z: ~A, w: ~A is pressed!!~%" (send msg :orientation :x) (send msg :orientation :y) (send msg :orientation :z) (send msg :orientation :w)))
(ros::subscribe "/mobile_base/sensors/imu_data" sensor_msgs::Imu #'imu-cb)

(ros::rate 100)
(do-until-key
 (ros::spin-once)
 (ros::sleep)
 )
