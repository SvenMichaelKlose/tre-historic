;;;; TRE environment
;;;; Copyright (c) 2005-2006,2008 Sven Klose <pixel@copei.de>

(defmacro return (&optional (expr nil))
  `(return-from nil ,expr))

(defun funcall (fun &rest args)
  (apply fun args))

(defmacro prog1 (&rest body)
  (let g (gensym)
    `(let ,g ,(car body)
      ,@(cdr body)
      ,g)))
