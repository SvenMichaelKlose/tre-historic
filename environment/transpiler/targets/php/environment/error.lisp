;;;;; Transpiler: TRE to JavaScript
;;;;; Copyright (c) 2008-2009 Sven Klose <pixel@copei.de>

(dont-inline %error)

(defun %error (msg)
  (alert msg)
  (invoke-native-debugger))

(dont-inline error)

(defun error (fmt &rest args)
  (alert (+ "Error :" (apply #'format nil fmt args)))
  (terpri *standard-log*)
  (invoke-native-debugger))
