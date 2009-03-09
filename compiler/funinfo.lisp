;;;; TRE compiler
;;;; Copyright (C) 2006-2007,2009 Sven Klose <pixel@copei.de>

;;; Function information.
;;;
;;; This structure contains all information required to generate a native function.
(defstruct funinfo
  ; Lists of stack variables. The rest contains the parent environments.
  (env        (cons nil nil))

  ; List of arguments.
  (args       nil)

  ; List of variables defined outside the function.
  (free-vars  nil)

  ; List of exported functions.
  (closures nil)

  (gathered-closure-infos nil)

  ; List of lexical variables exported to child functions.
  (lexicals nil)

  (parent niL)

  (ghost niL)
  (lexical niL)

  ; Function code. The format depends on the compilation pass.
  first-cblock)

(defun funinfo-free-var? (fi var)
  (member var (funinfo-free-vars fi)))

(defun funinfo-add-free-var (fi var)
  (unless (funinfo-free-var? fi var)
    (nconc! (funinfo-free-vars fi) (list var)))
  var)

(defun funinfo-env-parent (fi)
  (funinfo-env (funinfo-parent fi)))

(defun funinfo-env-add-args (fi args)
  (setf (funinfo-env fi) (append (funinfo-env fi) args))
  args)

(defun funinfo-arg? (fi var)
  (member var (funinfo-args fi)))

(defun funinfo-env-all (fi)
  (cons (funinfo-env fi)
		(awhen (funinfo-parent fi)
		  (funinfo-env-all !))))

(defun funinfo-env-add (fi arg)
  (unless (funinfo-env-pos fi arg)
    (funinfo-env-add-args fi (list arg))))

(defun funinfo-in-this-or-parent-env? (fi var)
  (or (funinfo-env-pos fi var)
	  (awhen (funinfo-parent fi)
		(funinfo-in-this-or-parent-env? ! var))))

,(macroexpand
	`(progn
	  ,@(mapcar (fn `(defun ,($ 'funinfo- (first _)) (fi var)
				   	    (position var (,($ 'funinfo- (second _)) fi))))
		    (group `(free-var-pos free-vars
					 env-pos env
					 lexical-pos lexicals)
				   2))))

(define-slot-setter-acons! funinfo-add-closure fi
  (funinfo-closures fi))

(defun funinfo-add-gathered-closure-info (fi fi-closure)
  (nconc! (funinfo-gathered-closure-infos fi) (list fi-closure)))

(defun funinfo-add-lexical (fi name)
  (unless (funinfo-lexical-pos fi name)
    (nconc! (funinfo-lexicals fi) (list name))))

(defun funinfo-get-child-funinfo (fi)
  (pop (funinfo-gathered-closure-infos fi)))

(defmacro with-funinfo-env-temporary (fi args &rest body)
  (with-gensym old-env
    `(let ,old-env (copy-tree (funinfo-env ,fi))
       (funinfo-env-add-args ,fi ,args)
       (prog1
         (progn
           ,@body)
	     (setf (funinfo-env ,fi) ,old-env)))))

(defvar *funinfos* (make-hash-table))

(defun make-lambda-funinfo (fi)
  (with-gensym g
	(setf (href g *funinfos*) fi)
	`(%funinfo ,g)))

(defun get-lambda-funinfo (x)
  (href x *funinfos*))

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
