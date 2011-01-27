;;;;; TRE environment - editor
;;;;; Copyright (c) 2008,2011 Sven Klose <pixel@copei.de>
;;;;;
;;;;; Miscellaneous.

(defmacro define-template-macro (name head &optional tail)
   "Define simple head/tail template."
  `(defmacro ,name (n args &rest b)
 	 (with (description (and b (consp b) (string? (first b)) (first b))
			body (if description (cdr b) b))
       `(defun ,,n ,,args
		  ,,@(list description)
          ,@head
          ,,@body
          ,@tail))))

(defmacro define-tail-macro (name tail)
  `(define-template-macro ,name nil ,tail))
