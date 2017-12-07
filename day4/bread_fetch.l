#!/usr/bin/env roseus

; (load "~/catkin_ws/src/robot-programming/turtleboteus/euslisp/turtlebot-interface.l")
(load "package://dxl_armed_turtlebot/euslisp/dxl-armed-turtlebot-interface.l")
(ros::load-ros-manifest "jsk_recognition_msgs")
(ros::load-ros-manifest "kobuki_msgs")
(ros::load-ros-manifest "std_msgs")

(defvar *topic-name* "/camera/depth_registered/boxes")
(defvar *bounding-box-list* nil)

;; taret to move-arm, in mm
(setq *x-target* 400)
(setq *y-target* 0)
(setq *z-target* 200)

(setq e_x (float-vector 1 0 0))
(setq e_y (float-vector 0 1 0))
(setq e_z (float-vector 0 0 1))

;; *n-pos* is in meter
(setq *x-pos* 0)
(setq *y-pos* 0)
(setq *z-pos* 0)
(setq *fetch_state* 0)

(ros::roseus "track_grab")

(dxl-armed-turtlebot-init)

(defun move-arm ()
  (send *dxl-armed-turtlebot* :inverse-kinematics
    (make-coords :pos (float-vector *x-target* *y-target* *z-target*))
    :rotation-axis nil
  )
  (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000)
)

(objects (list *dxl-armed-turtlebot*))

;; set arm pos to see
(send *dxl-armed-turtlebot* :tuckarm-pose3)
(send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
(send *ri* :wait-interpolation)

(defun bounding-box-array-cb (msg)
  (setq *bounding-box-list* (send msg :boxes))
  ;; boxesは、BoundingBoxのArray(Euslispではlist)
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
                  (setq *pos* (send cam->obj-coords :pos))
                  (cond
                    ((= *fetch_state* 0)
                      (progn
                        ; (cam->obj-coords (ros::tf-pose->coords (send b :pose)))
                        ; (setq *pos* (send (send bx :worldcoords) :pos))
                        (setq *x-pos* (/ (- (v. e_z *pos*) 87) 1000))
                        (setq *y-pos* (/ (+ (v. e_x *pos*) 12.5) -1000))
                        (setq *z-pos* (+ (/ (v. e_y *pos*) -1000) -0.11))
                        ; (setq *x* (send (send b :dimensions) :x))
                        ; (setq *y* (send (send b :dimensions) :y))
                        ; (setq *z* (send (send b :dimensions) :z))
                        (warn "positions x ~A y ~A z ~A~%" *x-pos* *y-pos* *z-pos*)
                        (setq *fetch_state* 1)
                      )
                    )
                    ((= *fetch_state* 2)
                      (progn
                        (warn "near object, recalculate ~A ~%" *pos*)
                        (setq *x-target* (- (v. e_z *pos*) 87))
                        (setq *y-target* (* (v. e_x *pos*) -1))
                        (setq *z-target* (+ (* (v. e_y *pos*) -1) 300))
                        (warn "target x ~A y ~A z ~A~%" *x-target* *y-target* *z-target*)
                        (setq *fetch_state* 3)
                      )
                    )
                  )
              bx)
            )
            *bounding-box-list*)
    (send *irtviewer* :viewer :viewsurface :flush)

  )
)

(ros::subscribe *topic-name*
  jsk_recognition_msgs::BoundingBoxArray
  #'bounding-box-array-cb 1)

(do-until-key
  (x::window-main-one)
  (cond
    ((= *fetch_state* 1)
      (progn
       (send *ri* :go-pos 0 0 (* (/ 180 pi) (atan *y-pos* *x-pos*)))
       (send *ri* :go-pos (- (sqrt (+ (* *x-pos* *x-pos*) (* *y-pos* *y-pos*))) 0.475) 0 0)
       (setq *fetch_state* 2)
       (warn "arrived near!")
      )
    )
    ((= *fetch_state* 3)
      (progn
       (send *dxl-armed-turtlebot* :reset-pose)
       (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
       (send *ri* :wait-interpolation)
              (send *ri* :stop-grasp)
       (send *dxl-armed-turtlebot* :gripper :arm :angle-vector #f(89))
       (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000 :gripper-controller)
       ; (send *ri* :go-pos 0.15 0 0)
       ; (setq *x-target* (- *x-target* 150))
       (setq *z-target* (+ *z-target* 30))
       (move-arm)
       (send *ri* :wait-interpolation)
       (send *ri* :start-grasp)
       (warn "caught it!")
       (setq *fetch_state* 4)
      )
    )
  )
  (ros::spin-once)
  (ros::sleep)
)
