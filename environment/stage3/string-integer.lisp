;;;; TRE environment
;;;; Copyright (c) 2008 Sven Klose <pixel@copei.de>

(defun string-integer (str)
  (let s (make-string-stream)
    (format s "~A" str)
    (read-integer s)))

; XXX tests missing
