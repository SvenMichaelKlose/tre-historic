;;;;; TRE tree processor transpiler
;;;;; Copyright (c) 2008 Sven Klose <pixel@copei.de>
;;;;;
;;;;; Toplevel

(defun transpiler-add-wanted-function (tr fun)
  (when (not (or (member fun (transpiler-wanted-functions tr))
				 (member fun (transpiler-unwanted-functions tr))
				 (assoc fun (expander-macros (expander-get (transpiler-macro-expander tr))))))
	(push fun (transpiler-wanted-functions tr))))

(defun transpiler-expand-and-generate-code (tr forms)
  (transpiler-generate-code tr (transpiler-expand tr forms)))

(defmacro with-gensym-assignments ((&rest pairs) &rest body)
  `(with-gensym ,(mapcar #'first (group pairs 2))
	 `(with ,(mapcar #'((x)
					      (list 'QUASIQUOTE x))
					 pairs)
	    ,(list 'QUASIQUOTE-SPLICE (cons 'QUOTE body)))))
;,,@.'body)))))

(defmacro assoc-update (key value alist)
  (with-gensym-assignments (k key
							v value)
    `(aif (assoc ,k ,alist)
	     `(setf (cdr !) ,v)
	     `(setf ,alist (acons ,k ,v ,alist)))))

;(defun transpiler-sight (tr funlist)
;  (with (out nil)
;    (dolist (x funlist (reverse out))
;	  (with (fun (symbol-function x))
;	    (when (functionp fun)
;		  (if fun
;			  (assoc-update x
;		  	  				(expanded (funcall #'transpiler-expand
;;							 				   tr `((defun ,x ,(function-arguments fun)
;							                          ,@(function-body fun)))))
;							(transpiler-expanded-functions tr))
;			  (error "Unknown function ~A~%" (symbol-name x))))))))

(defun transpiler-wanted (tr pass funlist)
  (with (out nil)
    (dolist (x funlist (reverse out))
	  (with (fun (symbol-function x))
	    (when (functionp fun)
		  (if fun
		  	  (push (funcall pass tr `((defun ,x ,(function-arguments fun)
									     ,@(function-body fun))))
					out)
			  (error "Unknown function ~A~%" (symbol-name x))))))))

(defun transpiler-sight (tr forms)
  (transpiler-expand tr forms))

;; User code must have been sightened by TRANSPILER-SIGHT.
(defun transpiler-transpile (tr forms)
  (unless (eq t (transpiler-unwanted-functions tr))
    (format t "Collecting dependencies...~%")
    (with (w nil
		   n (transpiler-wanted-functions tr))
	  (while (not (equal w n)) nil
        (transpiler-wanted tr #'transpiler-expand (transpiler-wanted-functions tr))
	    (setf w n
			  n (transpiler-wanted-functions tr)))))

  (format t "Generating code...~%")
  (apply #'string-concat
	(list (transpiler-concat-string-tree (transpiler-wanted tr #'transpiler-expand-and-generate-code (transpiler-wanted-functions tr)))
		  (transpiler-generate-code tr forms))))
