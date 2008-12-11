;;;;; TRE environment
;;;;; Copyright (C) 2005,2008 Sven Klose <pixel@copei.de>
;;;;;
;;;;; Basic conditional operators

(%defun compiler-and (x)
  (if (cdr x)
      `(if ,(car x)
		   ,(compiler-and (cdr x)))
      (car x)))

(defmacro and (&rest x)
  (compiler-and x))

(%defun compiler-or (x)
  (if (cdr x)
      (let g (gensym)
        `(let ,g ,(car x)
          (if (not ,g)
			  ,(compiler-or (cdr x))
              ,g)))
      (car x)))

(defmacro or (&rest exprs)
  (compiler-or exprs))
