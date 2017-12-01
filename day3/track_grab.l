#!/usr/bin/env roseus

; (load "~/catkin_ws/src/robot-programming/turtleboteus/euslisp/turtlebot-interface.l")
(load "package://dxl_armed_turtlebot/euslisp/dxl-armed-turtlebot-interface.l")
(ros::load-ros-manifest "jsk_recognition_msgs")
(ros::load-ros-manifest "kobuki_msgs")
(ros::load-ros-manifest "std_msgs")

(defvar *topic-name* "/camera/depth_registered/boxes")
(defvar *bounding-box-list* nil)

(ros::roseus "track_grab")

(dxl-armed-turtlebot-init)
; (turtlebot-init)
(objects (list *dxl-armed-turtlebot*))
(send *dxl-armed-turtlebot* :tuckarm-pose3)
(send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
(send *ri* :wait-interpolation)
(setq e_x (float-vector 1 0 0))
(setq e_y (float-vector 0 1 0))
(setq e_z (float-vector 0 0 1))
(setq *x-pos* 0)
(setq *y-pos* 0)
(setq *z-pos* 0)
(setq *stop* 0)

(defun bounding-box-array-cb (msg)
  (setq *bounding-box-list* (send msg :boxes)) ;; boxesは、BoundingBoxのArray(Euslispではlist)
  ;; BoundingBoxがあれば表示する
  (when *bounding-box-list*
    (send *irtviewer* :draw-objects :flush nil)
    (mapcar #'(lambda (b)
                ;; BoundingBoxは、dimsntion(直方体の幅・奥行き・高さ)をもつ
                (let* ((dims (ros::tf-point->pos (send b :dimensions)))
                       (bx (make-cube (elt dims 0) (elt dims 1) (elt dims 2)))
                       ;; (1) BoundingBoxのカメラ相対の座標系は、geometry_msgs/Poseという型で得られるので、Euslispのcoordsに変換する
                       (cam->obj-coords (ros::tf-pose->coords (send b :pose)))
                       ;; (2) *dxl-armed-turtlebot*モデルがカメラの座標系をもってるので、取得する
                       (cam-coords (send (send *dxl-armed-turtlebot* :camera_rgb_optical_frame_lk) :copy-worldcoords)))
                  ;; (3) Euslisp内部でのworld座標系の値にして、そこにmake-cubeの箱を設置する
                  (send bx :newcoords (send cam-coords :transform cam->obj-coords))
                  (send bx :worldcoords)
                  (send bx :draw-on :flush nil :color #f(1 0 0))
                  (warn "if first time start moving~%")
                  (if (= *stop* 0)
                    (progn
                      (warn "first time start~%")
                      (setq *pos* (send (send bx :worldcoords) :pos))
                      (setq *x-pos* (v. e_x *pos*))
                      (setq *y-pos* (v. e_y *pos*))
                      (setq *z-pos* (v. e_z *pos*))
                      (warn "~A ~A ~A~%" *x-pos* *y-pos* *z-pos*)
                      (setq *stop* 1)
                    )
                  )
                  (warn "~A~%" (send (send bx :worldcoords) :pos))
                  bx))
            *bounding-box-list*)
    (send *irtviewer* :viewer :viewsurface :flush)

  )
)

(ros::subscribe *topic-name*
  jsk_recognition_msgs::BoundingBoxArray
  #'bounding-box-array-cb 1)

(do-until-key
  (x::window-main-one)
  (if (= *stop* 1)
    (progn
      (warn "start moving~%")
      (send *ri* :go-pos  *x-pos* *y-pos* 0)
      (warn "~A *x-pos*~%" *x-pos*)
      (warn "stop moving!")
      (setq *stop* 2)
    )
  )
  (ros::spin-once)
  (ros::sleep)
)

; (send *dxl-armed-turtlebot* :gripper :arm :angle-vector #f(50))
; (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000 :gripper-controller)
; (send *ri* :wait-interpolation :gripper-controller)
;
; (setq *x-target* 400)
; (setq *y-target* 0)
; (setq *z-target* 200)
;
; (defun move ()
;   (send *dxl-armed-turtlebot* :inverse-kinematics
;     (make-coords :pos (float-vector *x-target* *y-target* *z-target*))
;     :rotation-axis nil
;   )
;   (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000)
; ; (send *ri* :wait-interpolation)
; )
;
; (move)
;
; (ros::rate 10)
; (warn "~%press circle to close, cross to open~%")
; (setq up_p 0)
; (setq down_p 0)
; (setq left_p 0)
; (setq right_p 0)
; (setq r1_p 0)
; (setq r2_p 0)
; (setq start_p 0)
; (do-until-key ()
;   (ros::spin-once)
;   (ros::sleep)
;   (if (= (send *joy* :circle-button) 1)
;     (progn
;       (warn "~% circle was pressed~%")(setq *y-target* 0)
;       (send *ri* :start-grasp)
;       ; (send *ri* :wait-interpolation)
;     )
;   )
;   (if (= (send *joy* :cross-button) 1)
;     (progn
;       (warn "~% cross was pressed~%")
;       (send *ri* :stop-grasp)
;       ; (send *ri* :wait-interpolation)
;     )
;   )
;   (if (= up_p 0)
;     (if (= (send *joy* :up-button) 1)
;       (progn
;         (warn "~% up has been pressed, will move arm up~%")
;         (setq *x-target* (+ *x-target* 20))
;         (move)
;       )
;     )
;   )
;   (setq up_p (send *joy* :up-button))
;   ;; down_p
;   (if (= down_p 0)
;     (if (= (send *joy* :down-button) 1)
;       (progn
;         (warn "~% down has been pressed, will move arm down~%")
;         (setq *x-target* (- *x-target* 20))
;         (move)
;       )
;     )
;   )
;   (setq down_p (send *joy* :down-button))
;   ;; left_p
;   (if (= left_p 0)
;     (if (= (send *joy* :left-button) 1)
;       (progn
;         (warn "~% left has been pressed, will move arm left~%")
;         (setq *y-target* (+ *y-target* 20))
;         (move)
;       )
;     )
;   )
;   (setq lefp_p (send *joy* :left-button))
;     ;; right_p
;   (if (= right_p 0)
;     (if (= (send *joy* :right-button) 1)
;       (progn
;         (warn "~% right has been pressed, will move arm right~%")
;         (setq *y-target* (- *y-target* 20))
;         (move)
;       )
;     )
;   )
;   (setq right_p (send *joy* :right-button))
;       ;; right_p
;   (if (= r1_p 0)
;     (if (= (send *joy* :r1-button) 1)
;       (progn
;         (warn "~% r1 has been pressed, will move arm r1~%")
;         (setq *z-target* (+ *z-target* 20))
;         (move)
;       )
;     )
;   )
;   (setq r1_p (send *joy* :r1-button))
;   ;; right_p
;   (if (= r2_p 0)
;     (if (= (send *joy* :r2-button) 1)
;       (progn
;         (warn "~% r2 has been pressed, will move arm r2~%")
;         (setq *z-target* (- *z-target* 20))
;         (move)
;       )
;     )
;   )
;   (setq r2_p (send *joy* :r2-button))
;   ;; reset
;   (if (= start_p 0)
;     (if (= (send *joy* :start-button) 1)
;       (progn
;         (warn "~% start has been pressed, reset~%")
;         (setq *x-target* 400)
;         (setq *y-target* 0)
;         (setq *z-target* 200)
;         (move)
;       )
;     )
;   )
;   (setq start_p (send *joy* :start-button))
; )
