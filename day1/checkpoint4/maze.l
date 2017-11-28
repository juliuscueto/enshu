#!/usr/bin/env roseus

(load "~/catkin_ws/src/robot-programming/turtleboteus/euslisp/turtlebot-interface.l")
;; kobuki_msg::BumperEvent型のmsgを使いたいので、kobuki_msgsというROSパッケージの必要ファイルをloadする
(ros::load-ros-manifest "kobuki_msgs")
(ros::load-ros-manifest "std_msgs")

;; ros::initする
(ros::roseus "button_subscriber")
(turtlebot-init)
(setq *onoff* 0)
(setq *rotate* 6)
;; コールバック関数を定義する
(defun button-cb (msg)
  (format t ";; button ~A is pressed!!~%" (send msg :button))
  (setq *onoff* (send msg :button))
)

(defun bumper-cb (msg)
  (format t ";; bumper ~A is pressed!!~%" (send msg :bumper))
  (case (send msg :state)
  ((0) (if (< *rotate* 3) (setq *rotate* (+ 3 *rotate*))))
  ((1) (setq *rotate* (send msg :bumper))))
)

(defun state-cb (msg)
  (if (equal *rotate* 7)
    (progn
      (format t ";; Current State: ~A~%" (send msg :data))
      (if (equal (send msg :data) "idle") (setq *rotate* 6))
    )
  )
)

;; button sub
(ros::subscribe
  "/mobile_base/events/button" ;; subscribeしたいtopicの名前
  kobuki_msgs::ButtonEvent ;; subscribeしたいtopicの型
  #'button-cb ;; コールバック関数
 )

(ros::subscribe
  "/mobile_base/events/bumper" ;; subscribeしたいtopicの名前
  kobuki_msgs::BumperEvent ;; subscribeしたいtopicの型
  #'bumper-cb ;; コールバック関数
 )

 (ros::subscribe
   "/cmd_vel_mux/active" ;; subscribeしたいtopicの名前
   std_msgs::String ;; subscribeしたいtopicの型
   #'state-cb ;; コールバック関数
 )

;; メインループ
(ros::rate 100) ;; 100[Hz]
(do-until-key
  (format t ";; Ready, onoff is ~A, state is ~A ~%" *onoff* *rotate*)
  (case *onoff*
  ((0) (send *ri* :go-velocity 0 0 0))
  ; ((1) (send *ri* :go-velocity 0.05 0 0))
  ((1) (case *rotate*
    ((0 1 2) (send *ri* :go-velocity -0.05 0 0))
    ((3) (send *ri* :go-pos 0 0 -90) (setq *rotate* 7))
    ((4) (send *ri* :go-pos 0 0 -180) (setq *rotate* 7))
    ((5) (send *ri* :go-pos 0 0 90) (setq *rotate* 7))
    ((6) (send *ri* :go-velocity 0.05 0 0))))
  )
  (ros::spin-once)
  (ros::sleep)
  )
