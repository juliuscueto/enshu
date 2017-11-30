(load "package://dxl_armed_turtlebot/euslisp/dxl-armed-turtlebot-interface.l")
(load "package://roseus/test/joy.l")
(init-ps3joy)

(dxl-armed-turtlebot-init)
(objects (list *dxl-armed-turtlebot*))


(send *dxl-armed-turtlebot* :gripper :arm :angle-vector #f(50))
(send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000 :gripper-controller)
(send *ri* :wait-interpolation :gripper-controller)

(ros::rate 10)
(warn "~%press circle to open, cross to close~%")
(do-until-key ()
  (ros::spin-once)
  (ros::sleep)
  (if (= (send *joy* :circle-button) 1)
    (progn
      (warn "~% circle was pressed~%")
      (send *ri* :start-grasp)
      ; (send *ri* :wait-interpolation)
    )
  )
  (if (= (send *joy* :cross-button) 1)
    (progn
      (warn "~% cross was pressed~%")
      (send *ri* :stop-grasp)
      ; (send *ri* :wait-interpolation)
    )
  )
)

; (send *dxl-armed-turtlebot* :inverse-kinematics
;     (make-coords :pos (float-vector 370 0 150) :rpy (list 0 (deg2rad 30) (deg2rad 180)))
;     :debug-view :no-message
; )
;
; (do-until-key ())
;
; (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
; (send *ri* :wait-interpolation)
;
; (send *dxl-armed-turtlebot* :inverse-kinematics
;     (make-coords :pos (float-vector 400 0 200))
;     :rotation-axis nil
; )
;
; (do-until-key ())
;
; (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
; (send *ri* :wait-interpolation)
