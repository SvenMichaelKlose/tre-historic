;;;;; tré - Copyright (c) 2011-2012 Sven Michael Klose <pixel@copei.de>

(setf *gensym-prefix* "~jsG")

(unless (eq '*native-eval-return-value* *native-eval-return-value*)
  (defvar *native-eval-return-value* nil))

(defvar *js-eval-transpiler* nil)

(defun make-js-eval-transpiler ()
  (let tr (copy-array *js-transpiler* :copy-elements? t)
    (transpiler-reset tr)
    (dolist (i *defined-functions*)
      (let-when f (symbol-function i)
        (transpiler-add-defined-function tr i)
        (transpiler-add-function-args tr i (car f.__source))
        (transpiler-add-function-body tr i (cdr f.__source))))
    (setf *js-eval-transpiler* tr)))

(defun js-eval-transpile (expression)
  (with-temporary *js-transpiler* (or *js-eval-transpiler* (make-js-eval-transpiler))
    (let tr *js-transpiler*
      (clr (transpiler-sightened-files tr)
           (transpiler-compiled-files tr)
           (transpiler-raw-decls tr))
	  (concat-stringtree
		  (js-transpile-pre tr)
    	  (target-transpile tr :files-after-deps (list (cons 'eval (list expression)))
		 	                   :dep-gen #'(())
			                   :decl-gen (js-make-decl-gen tr))
    	  (js-transpile-post)))))

(defun eval (x)
  (%%%eval (+ (js-eval-transpile x)
              (transpiler-obfuscated-symbol-string *js-transpiler* '*native-eval-return-value*)
              " = "
              (transpiler-obfuscated-symbol-string *js-transpiler* '~%ret)
              ";"))
  *native-eval-return-value*)
