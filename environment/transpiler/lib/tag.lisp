;;;;; tré – Copyright (c) 2006–2010,2012 Sven Michael Klose <pixel@copei.de>

(defvar *compiler-tag-counter* 1)

(defun make-compiler-tag ()
  (1+! *compiler-tag-counter*))

(defmacro with-compiler-tag (l &rest body)
  `(let ,l (make-compiler-tag)
     ,@body))
