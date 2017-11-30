(load "package://dxl_armed_turtlebot/euslisp/dxl-armed-turtlebot-interface.l")
(load "package://roseus/test/joy.l")
(init-ps3joy)

(dxl-armed-turtlebot-init)
(objects (list *dxl-armed-turtlebot*))


(send *dxl-armed-turtlebot* :gripper :arm :angle-vector #f(50))
(send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000 :gripper-controller)
(send *ri* :wait-interpolation :gripper-controller)

(setq *x-target* 400)
(setq *y-target* 0)
(setq *z-target* 200)

(defun move ()
  (send *dxl-armed-turtlebot* :inverse-kinematics
    (make-coords :pos (float-vector *x-target* *y-target* *z-target*))
    :rotation-axis nil
  )
  (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector) 1000)
; (send *ri* :wait-interpolation)
)

(move)

(ros::rate 10)
(warn "~%press circle to close, cross to open~%")
(setq up_p 0)
(setq down_p 0)
(setq left_p 0)
(setq right_p 0)
(setq r1_p 0)
(setq r2_p 0)
(setq start_p 0)
(do-until-key ()
  (ros::spin-once)
  (ros::sleep)
  (if (= (send *joy* :circle-button) 1)
    (progn
      (warn "~% circle was pressed~%")(setq *y-target* 0)
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
  (if (= up_p 0)
    (if (= (send *joy* :up-button) 1)
      (progn
        (warn "~% up has been pressed, will move arm up~%")
        (setq *x-target* (+ *x-target* 20))
        (move)
      )
    )
  )
  (setq up_p (send *joy* :up-button))
  ;; down_p
  (if (= down_p 0)
    (if (= (send *joy* :down-button) 1)
      (progn
        (warn "~% down has been pressed, will move arm down~%")
        (setq *x-target* (- *x-target* 20))
        (move)
      )
    )
  )
  (setq down_p (send *joy* :down-button))
  ;; left_p
  (if (= left_p 0)
    (if (= (send *joy* :left-button) 1)
      (progn
        (warn "~% left has been pressed, will move arm left~%")
        (setq *y-target* (+ *y-target* 20))
        (move)
      )
    )
  )
  (setq lefp_p (send *joy* :left-button))
    ;; right_p
  (if (= right_p 0)
    (if (= (send *joy* :right-button) 1)
      (progn
        (warn "~% right has been pressed, will move arm right~%")
        (setq *y-target* (- *y-target* 20))
        (move)
      )
    )
  )
  (setq right_p (send *joy* :right-button))
      ;; right_p
  (if (= r1_p 0)
    (if (= (send *joy* :r1-button) 1)
      (progn
        (warn "~% r1 has been pressed, will move arm r1~%")
        (setq *z-target* (+ *z-target* 20))
        (move)
      )
    )
  )
  (setq r1_p (send *joy* :r1-button))
  ;; right_p
  (if (= r2_p 0)
    (if (= (send *joy* :r2-button) 1)
      (progn
        (warn "~% r2 has been pressed, will move arm r2~%")
        (setq *z-target* (- *z-target* 20))
        (move)
      )
    )
  )
  (setq r2_p (send *joy* :r2-button))
  ;; reset
  (if (= start_p 0)
    (if (= (send *joy* :start-button) 1)
      (progn
        (warn "~% start has been pressed, reset~%")
        (setq *x-target* 400)
        (setq *y-target* 0)
        (setq *z-target* 200)
        (move)
      )
    )
  )
  (setq start_p (send *joy* :start-button))
)
;
; (do-until-key ())
;

;
; (do-until-key ())
;
; (send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
; (send *ri* :wait-interpolation)
