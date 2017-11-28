#!/usr/bin/env roseus

(ros::load-ros-manifest "kobuki_msgs")

(ros::roseus "sound_publisher")

(ros::advertise "/mobile_base/commands/sound" kobuki_msgs::Sound 1)

(ros::rate 1)
(setq *sound-count* 0)
(while (ros::ok)
  (let ((msg (instance kobuki_msgs::Sound :init :value *sound-count*)))
    (ros::ros-info "kobuki sound [~A]" (send msg :value))
    (ros::publish "/mobile_base/commands/sound" msg))
  (ros::sleep)
  (incf *sound-count*)
  (if (> *sound-count* 6) (setq *sound-count* 0))
  )
(exit)
