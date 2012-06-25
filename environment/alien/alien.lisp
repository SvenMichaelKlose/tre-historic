;;;; tré – Copyright (c) 2008–2009,2012 Sven Michael Klose <pixel@copei.de>

(defvar *dl-libs* (make-hash-table :test #'string==))

(defun alien-import-lib (name)
  (or (href *dl-libs* name)
	  (setf (href *dl-libs* name)
	        (or (alien-dlopen (string-concat name))))))
