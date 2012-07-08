;;;;; tré – Copyright (c) 2006–2009,2012 Sven Michael Klose <pixel@copei.de>

(setq *show-definitions?* t)

(setq
	*universe* ; The garbage collector roots here.
	(cons 'last
	(cons '%nconc
	(cons 'copy-tree
	(cons '*variables*
		  *universe*)))))

(setq
	*defined-functions*
	(cons 'copy-tree
	(cons 'last
	(cons '%nconc
		  nil))))

(setq
	*variables*
	(cons (cons '*variables* nil)
	(cons (cons '*defined-functions* nil)
	(cons (cons '*universe* nil)
	(cons (cons '*keyword-package* nil)
	(cons (cons '*show-definitions?* nil)
	(cons (cons '*environment-path* nil)
	(cons (cons '*endianess* nil)
	(cons (cons '*pointer-size* nil)
	(cons (cons '*cpu-type* nil)
	(cons (cons '*libc-path* nil)
	(cons (cons '*have-environment-tests* nil)
		  *variables*))))))))))))

(%set-atom-fun copy-tree
  #'((x)
      (? x
		 (? (atom x)
            x
            (cons (copy-tree (car x))
              	  (copy-tree (cdr x)))))))

(%set-atom-fun last
  #'((x)
      (? x
		 (? (cdr x)
            (last (cdr x))
            x))))

(%set-atom-fun %nconc
  #'((a b)
      (? a
         (progn
		   (rplacd (last a) b)
    	   a)
		 b)))
