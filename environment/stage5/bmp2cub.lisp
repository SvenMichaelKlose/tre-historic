;;;;; Copyright (c) 2011 Sven Klose <pixel@copei.de>

(defun bmp2cub-read-slices (files)
  (with (num-slices (length files)
         slices (make-array num-slices)
         i 0)
    (dolist (n files slices)
      (format t "Reading slice ~A..." i)
      (force-output)
      (with ((slice w h) (read-bmp-array n))
        (setf (aref slices i) slice)
        (format t "O.K.~%"))
      (1+! i))))

(defun bmp2cub-make-cub-data (slices x y z)
  (let data (make-queue)
    (dotimes (iz 16 (queue-list data))
      (let mz (aref slices (+ z iz))
        (dotimes (iy 16)
          (dotimes (ix 16)
            (enqueue data (%%get (+ mz (* (+ y iy) 512) x ix)))))))))

(defun cubs-on-axis (x)
  (integer (/ x 16)))

(defun bmp2cub (files)
  (let slices (bmp2cub-read-slices files)
    (dotimes (z (cubs-on-axis (length slices)))
      (dotimes (y (cubs-on-axis 512))
        (dotimes (x (cubs-on-axis 512))
          (let cubname (format nil "~A-~A-~A.cub" z y x)
            (format t "Making cub ~A..." cubname)
            (let cubdata (bmp2cub-make-cub-data slices (* 16 x) (* y 16) (* z 16))
              (with-open-file out (open cubname :direction 'output)
                (map (fn princ (code-char _) out) cubdata)))
            (format t "O.K.~%")))))))
