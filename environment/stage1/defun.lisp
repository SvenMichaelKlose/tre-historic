;;;; tré – Copyright (c) 2005–2008,2010–2013 Sven Michael Klose <pixel@copei.de>

(defvar *function-sources* nil)

; Check and return keyword argument or NIL.
(early-defun %defun-arg-keyword (args)
  (let a (car args)
	(let d (& (cdr args)
			  (cadr args))
      (? (%arg-keyword? a)
         (? d
            (? (%arg-keyword? d)
               (%error "Keyword follows keyword"))
            (%error "Unexpected end of argument list after keyword."))))))

(early-defun %defun-checked-args (args)
  (& args
     (| (%defun-arg-keyword args)
        (cons (car args) (%defun-checked-args (cdr args))))))

(early-defun %defun-name (name)
  (? (atom name)
     name
     (? (eq (car name) '=)
        (make-symbol (string-concat "=-" (string (cadr name)))
                     (symbol-package (cadr name)))
        (progn
	      (print name)
	      (%error "Illegal function name.")))))

(defmacro defun (name args &body body)
  (let name (%defun-name name)
    (setq *function-sources* (cons (cons name (cons args body)) *function-sources*))
    `(block nil
	   (print-definition `(defun ,name ,args))
       (setq *universe* (cons ',name *universe*)
       		 *defined-functions* (cons ',name *defined-functions*))
       (%set-atom-fun ,name
           #'(,(%defun-checked-args args)
               ,@(? *exec-log*
                    `((print ,name)))
               (block ,name
                 ,@(%add-documentation name body))))
	   (return-from nil ',name))))
