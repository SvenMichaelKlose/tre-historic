;;;;; nix operating system project lisp compiler
;;;;; Copyright (c) 2006-2008 Sven Klose <pixel@copei.de>
;;;;;
;;;;; User-defineable expansion.

(defvar *expanders* nil)

(defstruct expander
  macros
  pred
  call
  pre
  post)

(defun expander-get (name)
  (cdr (assoc name *expanders*)))

(defun define-expander (expander-name &key (pre nil) (post nil) (pred nil) (call nil))
  (with (e  (make-expander :macros nil
						   :pred pred
						   :call call
						   :pre #'(lambda ())
						   :post #'(lambda  ())))
    (acons! expander-name e *expanders*)
    (unless pred
      (setf (expander-pred e) #'(lambda (x)
							      (cdr (assoc x (expander-macros e))))))
    (unless call
      (setf (expander-call e) #'(lambda (fun x)
                                  (apply (cdr (assoc fun (expander-macros e))) x))))))

(defmacro define-expander-macro (expander-name name args body)
  (unless (atom name)
    (error "Atom expected instead of ~A for expander ~A." name expander-name))
  `(acons! ',name
			#'(,args
			    ,@(macroexpand body))
		   (expander-macros (expander-get ,expander-name))))

(defun expander-expand (expander-name expr)
  (with (e  (expander-get expander-name))
    (prog1
      (with-temporary *macrop-diversion* (expander-pred e)
        (with-temporary *macrocall-diversion* (expander-call e)
	      (funcall (expander-pre e))
	      (repeat-while-changes #'%macroexpand expr)))
      (funcall (expander-post e)))))

(defun expander-has-macro? (expander-name macro-name)
  (cdr (assoc macro-name (expander-macros (expander-get expander-name)))))
