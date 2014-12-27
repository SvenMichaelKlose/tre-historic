; tré – Copyright (c) 2005–2014 Sven Michael Klose <pixel@copei.de>

(defun cl-expex-initializer (ex)
  (= (expex-argument-filter ex) #'identity
     (expex-setter-filter ex)   #'identity))

(defun cl-frontend (x)
  (aprog1 (transpiler-macroexpand (quasiquote-expand (dot-expand x)))
    (fake-expression-expand (fake-place-expand (lambda-expand (rename-arguments (backquote-expand (compiler-macroexpand !))))))))

(defun cl-sections-before-import ()
  (unless (exclude-base?)
    (list (. 'cl-base *cl-base*))))

(defun make-cl-transpiler ()
  (create-transpiler
      :name                  :common-lisp
      :frontend-only?          t
      :import-variables?       t
      :lambda-export?          nil
      :stack-locals?           nil
      :sections-before-import  #'cl-sections-before-import
      :frontend-init           #'(() (= *cl-builtins* nil))
      :own-frontend            #'cl-frontend
      :expex-initializer       #'cl-expex-initializer
      :postprocessor           #'((&rest x)
                                    (make-lambdas (apply #'+ x)))))

(defvar *cl-transpiler* (copy-transpiler (make-cl-transpiler)))
