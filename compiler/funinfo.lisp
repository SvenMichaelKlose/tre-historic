;;;;; TRE compiler
;;;;; Copyright (C) 2006-2007,2009 Sven Klose <pixel@copei.de>
;;;;;
;;;;; METACODE FUNCTION INFORMATION
;;;;;
;;;;; This structure contains all information required to generate
;;;;; a native function. They're referenced by %FUNINFO-expressions in
;;;;; metacode-functions.

(defstruct funinfo
  ; Lists of stack variables. The rest contains the parent environments.
  (env nil)

  ; List of arguments.
  (args nil)

  (renamed-vars nil)

  ; List of variables defined outside the function.
  (free-vars nil)

  ; List of exported functions.
  (closures nil)

  (gathered-closure-infos nil)

  ; List of lexical variables exported to child functions.
  (lexicals nil)

  (parent niL)

  (ghost niL)
  (lexical niL)

  ; Number of jump tags in body.
  (num-tags nil)

  (sym nil)
  ; Function code. The format depends on the compilation pass.
  first-cblock)

(defun funinfo-topmost (fi)
  (aif (funinfo-parent fi)
	   (funinfo-topmost !)
	   fi))

;;;; ARGUMENTS

(defun funinfo-arg? (fi var)
  (member var (funinfo-args fi)))

;;;; FREE VARIABLES

(defun funinfo-free-var? (fi var)
  (member var (funinfo-free-vars fi)))

(defun funinfo-add-free-var (fi var)
  (unless (funinfo-free-var? fi var)
    (nconc! (funinfo-free-vars fi) (list var)))
  var)

;;;; ARGUMENTS & ENVIRONMENT

(defun funinfo-in-args-or-env? (fi x)
  (or (funinfo-arg? fi x)
	  (funinfo-env-pos fi x)))

(defun funinfo-in-this-or-parent-env? (fi var)
  (when fi
    (or (funinfo-in-args-or-env? fi var)
	    (awhen (funinfo-parent fi)
		  (funinfo-in-this-or-parent-env? ! var)))))

;;;; ENVIRONMENT

(defmacro with-funinfo-env-temporary (fi args &rest body)
  (with-gensym old-env
    `(let ,old-env (copy-tree (funinfo-env ,fi))
       (funinfo-env-add-args ,fi ,args)
       (prog1
         (progn
           ,@body)
	     (setf (funinfo-env ,fi) ,old-env)))))

,(macroexpand
	`(progn
	  ,@(mapcar (fn `(defun ,($ 'funinfo- _.) (fi var)
				   	    (position var (,($ 'funinfo- ._.) fi))))
		    (group `(free-var-pos free-vars
					 env-pos env
					 lexical-pos lexicals)
				   2))))

(defun funinfo-env-parent (fi)
  (funinfo-env (funinfo-parent fi)))

(defun funinfo-env-add (fi arg)
  (unless (funinfo-env-pos fi arg)
	  ;(error "double definition of ~A in ~A" arg (funinfo-env fi))
      (append! (funinfo-env fi) (list arg))))

(defun funinfo-env-add-many (fi arg)
  (dolist (x arg)
	(funinfo-env-add fi x)))

(defun funinfo-make-stackplace (fi x)
  (funinfo-env-add fi x)
  `(%stack ,(funinfo-env-pos fi x)))

;;;; CLOSURES

(define-slot-setter-push! funinfo-add-closure fi
  (funinfo-closures fi))

(defun funinfo-add-gathered-closure-info (fi fi-closure)
  (nconc! (funinfo-gathered-closure-infos fi) (list fi-closure)))

;; XXX not POP! ?
(defun funinfo-get-child-funinfo (fi)
  (pop (funinfo-gathered-closure-infos fi)))

;;;; LEXICALS AND GHOST ARGUMENTS

(defun funinfo-add-lexical (fi name)
  (unless (funinfo-lexical-pos fi name)
    (nconc! (funinfo-lexicals fi) (list name))))

(defun funinfo-make-lexical (fi)
  (unless (funinfo-lexical fi)
    (let lexical (gensym)
	  (setf (funinfo-lexical fi) lexical)
	  (funinfo-env-add fi lexical))))

(defun funinfo-make-ghost (fi)
  (unless (funinfo-ghost fi)
    (let ghost (gensym)
	  (setf (funinfo-ghost fi) ghost)
	  (setf (funinfo-args fi)
		    (cons ghost
				  (funinfo-args fi)))
	  (funinfo-env-add fi ghost))))

(defun funinfo-link-lexically (fi)
  (funinfo-make-lexical (funinfo-parent fi))
  (funinfo-make-ghost fi))

;; Make lexical path to desired variable.
(defun funinfo-setup-lexical-links (fi var)
  (let fi-parent (funinfo-parent fi)
    (unless fi-parent
	  (error "couldn't find ~A in environment" var))
    (funinfo-add-free-var fi var)
    (funinfo-link-lexically fi)
    (if (funinfo-env-pos fi-parent var)
	    (funinfo-add-lexical fi-parent var)
        (funinfo-setup-lexical-links fi-parent var))))

;;;; LAMBDA FUNINFO

(defvar *funinfos* (make-hash-table))
(defvar *funinfos-reverse* (make-hash-table))

(defun make-lambda-funinfo (fi)
  (when (href *funinfos-reverse* fi)
	(error "funinfo already memorized"))
  (setf (href *funinfos-reverse* fi) t)
  (with-gensym g
	(transpiler-add-obfuscation-exceptions *js-transpiler* g)
	(setf (funinfo-sym fi) g)
	(setf (href *funinfos* g) fi)
	`(%funinfo ,g)))

(defun replace-lambda-funinfo (fi)
  (setf (href *funinfos-reverse* fi) t)
  (with-gensym g
	(setf (funinfo-sym fi) g)
	(setf (href *funinfos* g) fi)
	`(%funinfo ,g)))

(defun make-lambda-funinfo-if-missing (x fi)
  (or (lambda-funinfo-expr x)
	  (make-lambda-funinfo fi)))

(defun get-lambda-funinfo (x)
  (let fi (href *funinfos* (lambda-funinfo x))
    (when (not (eq (funinfo-sym fi)
				   (lambda-funinfo x)))
	  (print fi)
	  (print (lambda-funinfo x))
	  (error "foo"))
	fi))

;;;; DEBUG PRINTERS

(defun print-funinfo (fi)
  (format t "Arguments: ~A~%" (funinfo-args fi))
  (format t "Ghost sym:   ~A~%" (funinfo-ghost fi))
  (format t "Stack:       ~A~%" (funinfo-env fi))
  (format t "Lexicals:  ~A~%" (funinfo-lexicals fi))
  (format t "Lexical sym: ~A~%" (funinfo-lexical fi))
  (format t "Free vars: ~A~%" (funinfo-free-vars fi))
  (format t "-~%")
  fi)

(defun print-funinfo-stack (fi)
  (when fi
    (print-funinfo fi)
    (print-funinfo-stack (funinfo-parent fi)))
  fi)
