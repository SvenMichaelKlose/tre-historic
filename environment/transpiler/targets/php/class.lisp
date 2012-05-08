;;;;; Caroshi - Copyright (c) 2008-2012 Sven Michael Klose <pixel@copei.de>

(defun php-make-constructor (cname bases args body)
  (transpiler-add-defined-function *php-transpiler* cname)
  (transpiler-add-function-args *php-transpiler* cname args)
  `(%setq __construct
      #'(,args
          ; Add class name for debugging.
          ,@(when *transpiler-assert*
              `((setf this.__class ',cname)))
          ; Inject calls to base constructors.
          (let ~%this this
            (%thisify ,cname
              ,@(ignore-body-doc body))))))

(define-php-std-macro defclass (class-name args &rest body)
  (apply #'transpiler_defclass #'php-make-constructor class-name args body))

(define-php-std-macro defmethod (class-name name args &rest body)
  (apply #'transpiler_defmethod class-name name args body))

(define-php-std-macro defmember (class-name &rest names)
  (apply #'transpiler_defmember class-name names))

(defun php-emit-method (class-name x)
  `(%setq (%transpiler-native ,x.)
          #'(,.x.
	          (%thisify ,class-name
		        (let ~%this ,(? (transpiler-continuation-passing-style? *php-transpiler*)
                                '~%cps-this
                                'this)
	              ,@(or (ignore-body-doc ..x.)
				        (list nil)))))))

(defun php-emit-members (class-name cls)
  (awhen (class-members cls)
	(mapcar (fn `(%setq nil (%transpiler-native "var $" ,_.)))
            (reverse !))))

(defun php-emit-methods (class-name cls)
  (awhen (class-methods cls)
	(mapcan (fn `((%setq nil (%transpiler-native (%php-method-head)))
                  ,(php-emit-method class-name _)))
            (reverse !))))

(define-php-std-macro finalize-class (class-name)
  (let classes (transpiler-thisify-classes *current-transpiler*)
    (aif (href classes class-name)
	     `(progn
	        (defun ,($ class-name '?) (x)
	          (and (object? x)
	               (string= x.__class ,(symbol-name class-name))
                   x))
            (%setq nil (%transpiler-native (%php-class-head ,class-name)))
		    ,(assoc-value class-name *delayed-constructors*)
		    ,@(php-emit-members class-name !)
		    ,@(php-emit-methods class-name !)
            (%setq nil (%transpiler-native (%php-class-tail))))
	     (error "Cannot finalize undefined class ~A." class-name))))
