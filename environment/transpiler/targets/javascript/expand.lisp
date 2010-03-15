;;;;; Transpiler: TRE to JavaScript
;;;;; Copyright (c) 2008-2010 Sven Klose <pixel@copei.de>
;;;;;
;;;;; Expansion of alternative standard macros.

;; Define macro that is expanded _before_ standard macros.
(defmacro define-js-std-macro (&rest x)
  `(define-transpiler-std-macro *js-transpiler* ,@x))

;; (FUNCTION symbol | lambda-expression)
;; Add symbol to list of wanted functions or obfuscate arguments of
;; LAMBDA-expression.
(define-js-std-macro function (&rest x)
  (unless x
    (error "FUNCTION expects a symbol or form"))
  (if (and (or (consp x.)
			   (consp .x)))
	  (let frm (if .x .x. x.)
		(if (and (not (simple-argument-list? frm.))
			     (not (eq 'no-args .frm.)))
		    (with-gensym g
		   	  `(#'((,g)
			         (setf ,g (function ,@(when .x
										    (list x.))
						          (,frm. no-args ,@.frm)))
			         (setf (slot-value ,g 'tre-exp)
					       ,(compile-argument-expansion g frm.))
				     ,g) nil))
  			`(function ,@x)))
  	  `(function ,@x)))

;; (DEFUN ...)
;;
;; Assign function to global variable.
;; XXX This could be generic.
(defun js-essential-defun (name args &rest body)
  (when *show-definitions*
    (late-print `(defun ,name ,@(awhen args (list !)))))
  (with (n (%defun-name name)
		 tr *js-transpiler*
		 (fi-sym a) (split-funinfo-and-args args))
    (transpiler-add-function-args tr n a)
    (transpiler-add-function-body tr n (remove 'no-args body :test #'eq))
	(transpiler-add-defined-function tr n)
    `(progn
       (%var ,n)
       (%setq ,n (function ;,n
					 (,@(awhen fi-sym
						  `(%funinfo ,!))
					  ,a
   		              ,@body))))))

(define-js-std-macro define-native-js-fun (name args &rest body)
  (apply #'js-essential-defun name args body))

(define-js-std-macro defun (name args &rest body)
  (with-gensym g
	(let n (%defun-name name)
	  (when (transpiler-defined-function *js-transpiler* n)
		(error "Function ~A already defined" name))
      `(progn
		 (%var ,g)
		 (%setq ,g (%unobfuscated-lookup-symbol ,(symbol-name n) nil))
	     ,(apply #'js-essential-defun name args body)
		 (setf (symbol-function ,g) ,n)))))

(define-js-std-macro defmacro (name &rest x)
  (when *show-definitions*
    (late-print `(defmacro ,name ,x.)))
  (eval (macroexpand `(define-js-std-macro ,name ,@x)))
		  ;(transpiler-macroexpand *js-transpiler*
  nil)

(define-js-std-macro defvar (name val)
  (let tr *js-transpiler*
    (when *show-definitions*
      (late-print `(defvar ,name)))
    (when (transpiler-defined-variable tr name)
      (error "variable ~A already defined" name))
    (transpiler-add-defined-variable tr name)
    `(progn
       (%var ,name)
	   (%setq ,name ,val))))

(define-js-std-macro make-string (&optional len)
  "")

;; Translate SLOT-VALUE to unquoted variant.
(define-js-std-macro slot-value (place slot)
  `(%slot-value ,place ,(second slot)))

;; XXX Can't we do this in one macro?
(define-js-std-macro bind (fun &rest args)
  `(%bind ,(if (%slot-value? fun)
 			 (second fun)
    		 (error "function must be a SLOT-VALUE, got ~A" fun))
		  ,fun))

;; X-browser MAKE-HASH-TABLE.
(defun js-transpiler-make-new-hash (x)
  `(make-hash-table
	 ,@(mapcan (fn (list (if (and (not (stringp _.))
								  (eq :class _.))
							 "class" ; IE6 wants this.
							 _.)
						 (second _)))
			   (group x 2))))

;; Translate arguments for call to native 'new' operator.
(defun js-transpiler-make-new-object (x)
  `(%new ,@x))

;; Make object if first argument is not a keyword, or string.
(define-js-std-macro new (&rest x)
  (unless x
	(error "NEW expects arguments"))
  (if (or (keywordp x.)
		  (stringp x.))
	  (js-transpiler-make-new-hash x)
	  (js-transpiler-make-new-object x)))

;; Iterate over array.
(define-js-std-macro doeach ((var seq &rest result) &rest body)
  (with-gensym (evald-seq idx)
    `(with (,evald-seq ,seq)
	   (when ,evald-seq
	     (dotimes (,idx (%slot-value ,evald-seq length) ,@result)
	       (with (,var (aref ,evald-seq ,idx))
             ,@body))))))

;; Make type predicate function.
(define-js-std-macro js-type-predicate (name &rest types)
  `(defun ,name (x)
     (when x
	   ,(if (< 1 (length types))
       		`(or ,@(mapcar (fn `(%%%= (%js-typeof x) ,_))
						   types))
            `(%%%= (%js-typeof x) ,types.)))))

(define-js-std-macro href (hash key)
  `(aref ,hash ,key))

(define-js-std-macro undefined? (x)
  `(= "undefined" (%js-typeof ,x)))

(define-js-std-macro defined? (x)
  `(not (= "undefined" (%js-typeof ,x))))

; XXX generic function instead of append!
(define-js-std-macro dont-obfuscate (&rest symbols)
  (apply #'transpiler-add-obfuscation-exceptions
		 *js-transpiler* symbols)
  nil)

(define-js-std-macro dont-inline (x)
  (transpiler-add-inline-exception *js-transpiler* x)
  (transpiler-add-dont-inline *js-transpiler* x)
  nil)

(define-js-std-macro assert (x &optional (txt nil) &rest args)
  (when *transpiler-assert*
    (make-assertion x txt args)))

(define-js-std-macro %lx (lexicals fun)
  (eval (macroexpand `(with ,(mapcan (fn `(,_ ',_)) .lexicals.)
                        ,fun))))

;; Convert MAPCAR to faster FILTER if possible.
(define-js-std-macro mapcar (fun &rest lsts)
  `(,(if (= 1 (length lsts))
	   'filter
	   'mapcar)
    ,fun ,@lsts))
