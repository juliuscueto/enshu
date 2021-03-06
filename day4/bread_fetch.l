#!/usr/bin/env roseus

(load "package://dxl_armed_turtlebot/euslisp/dxl-armed-turtlebot-interface.l")
(ros::load-ros-manifest "jsk_recognition_msgs")
(ros::load-ros-manifest "kobuki_msgs")
(ros::load-ros-manifest "std_msgs")
(load "package://roseus/test/joy.l")
(init-ps3joy)

(defvar *topic-name* "/camera/depth_registered/boxes")
(defvar *bounding-box-list* nil)

;; global variables to control button of ps3
(setq *circle-button* 0)
(setq *cross-button* 0)
(setq *square-button* 0)

;; unit-vectors, used to get positions from BoundingBox
(setq e_x (float-vector 1 0 0))
(setq e_y (float-vector 0 1 0))
(setq e_z (float-vector 0 0 1))

;; taret to move-arm, in mm
(setq *x-target* 400)
(setq *y-target* 0)
(setq *z-target* 200)

;; *n-pos* is in meter
(setq *x-pos* 0)
(setq *y-pos* 0)
(setq *z-pos* 0)
(setq *fetch_state* 0)

;; start node "trad_grad" (defined by this program)
(ros::roseus "track_grab")

;; initiate robot object
(dxl-armed-turtlebot-init)

;; define function used to move arm
(defun move-arm ()
    (send *dxl-armed-turtlebot* :inverse-kinematics
      (make-coords :pos (float-vector *x-target* *y-target* *z-target*))
      :rotation-axis nil
      )
      (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000)
)

;; draw simulated robot
(objects (list *dxl-armed-turtlebot*))

;; set arm pos to enable seeing
(send *dxl-armed-turtlebot* :tuckarm-pose3)
(send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
(send *ri* :wait-interpolation)

;; define callback function
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
                        ;; obtain coords to move robot to close position
                        (setq *x-pos* (/ (- (v. e_z *pos*) 87) 1000))
                        (setq *y-pos* (/ (+ (v. e_x *pos*) 12.5) -1000))
                        (setq *z-pos* (+ (/ (v. e_y *pos*) -1000) -0.11))
                        (warn "positions x ~A y ~A z ~A~%" *x-pos* *y-pos* *z-pos*)
                        (setq *fetch_state* 1)
                      )
                    )
                    ((= *fetch_state* 2)
                      (progn
                        ;; obtain coords of target
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

;; subscribe to output of hsi_color_filter
(ros::subscribe *topic-name*
  jsk_recognition_msgs::BoundingBoxArray
  #'bounding-box-array-cb 1)

;; main loop
(do-until-key
  (x::window-main-one)
  ;; obtain button information
  (setq *circle-button* (send *joy* :circle-button))
  (setq *cross-button* (send *joy* :cross-button))
  (setq *square-button* (send *joy* :square-button))
  (warn "circle-button is ~A~%" *circle-button*)
  (warn "cross-button is ~A~%" *cross-button*)
  (warn "fetch_state is ~A~%" *fetch_state*)
  (if (= *circle-button* 1)
    (progn
        (warn "circle-button was pressed!, start grabbing~%")
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

            ;; adjusting *z-target* so ik will not fail. adjustment will differ from environment to environment
            (setq *z-target* (+ *z-target* 30))
            (move-arm)
            (send *ri* :wait-interpolation)
            (send *ri* :start-grasp)
            (warn "caught it!")
            (setq *fetch_state* 4)
          )
        )
      )
    )
  )
  (if (= *cross-button* 1)
    (if (= *fetch_state* 4)
      (progn
        (send *ri* :stop-grasp)
        (send *dxl-armed-turtlebot* :gripper :arm :angle-vector #f(89))
        (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000 :gripper-controller)
        (setq *fetch_state* 0)
      )
    )
  )
  (if (= *square-button* 1)
    (progn
      (warn "square was pressed, reset~%")
      (setq *fetch_state* 0)
      (send *dxl-armed-turtlebot* :tuckarm-pose3)
      (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
      (send *ri* :wait-interpolation)
      (send *ri* :stop-grasp)
      (send *dxl-armed-turtlebot* :gripper :arm :angle-vector #f(89))
      (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000 :gripper-controller)
    )
  )
  (ros::spin-once)
  (ros::sleep)
)
