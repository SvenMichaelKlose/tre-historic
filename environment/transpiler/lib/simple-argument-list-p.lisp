;;;;; tré – Copyright (c) 2010–2012 Sven Michael Klose <pixel@copei.de>

(defun simple-argument-list? (x)
  (? x
     (not (member-if [| (cons? _)
	                    (argument-keyword? _)]
				     x))
	 t))
