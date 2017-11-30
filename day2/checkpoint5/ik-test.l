(load "package://dxl_armed_turtlebot/euslisp/dxl-armed-turtlebot-interface.l")
(dxl-armed-turtlebot-init)
(objects (list *dxl-armed-turtlebot*))

(send *dxl-armed-turtlebot* :inverse-kinematics
    (make-coords :pos (float-vector 370 0 150) :rpy (list 0 (deg2rad 30) (deg2rad 180)))
    :debug-view :no-message
)

(do-until-key ())

(send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
(send *ri* :wait-interpolation)

(send *dxl-armed-turtlebot* :inverse-kinematics
    (make-coords :pos (float-vector 400 0 200))
    :rotation-axis nil
)

(do-until-key ())

(send *ri* :angle-vector (send *dxl-armed-turtlebot* :angle-vector))
(send *ri* :wait-interpolation)

