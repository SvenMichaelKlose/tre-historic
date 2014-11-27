;;;;; tré – Copyright (c) 2014 Sven Michael Klose <pixel@copei.de>
;;;;;
;;;;; Common Lisp replacement for the C core.
;;;;;
;;;;; *** UNDER CONTRUCTION!!! ***
;;;;;
;;;;; The interpreter is spoiling everthing. Don't try to use
;;;;; tré before this thing here is working.

(proclaim '(optimize (debug 3)))


;;;; Initialization package

(defpackage :tre-init
  (:use :common-lisp)
  (:export :+renamed-imports+
           :make-keyword
           :cl-peek-char :cl-read-char))

(in-package :tre-init)

;;; Symbols directly imported from package CL-USER.
(defconstant +direct-imports+
    '(nil t eq eql atom setq quote
      cons car cdr rplaca rplacd
      apply function
      progn block return return-from tagbody go
      mod sqrt sin cos atan exp round floor
      last copy-list nthcdr nth mapcar elt length make-string
      make-array aref code-char char-code
      symbol-name make-package package-name
      logxor bit-and
      print
      defvar
      defun
      identity list copy-list
      &rest &body &optional &key
      labels))

;;; Functions we import from CL-USER, wrap and export to package TRE.
(defconstant +renamed-imports+
    '((cons? consp)
      (symbol? symbolp)
      (function? functionp)
      (string? stringp)
      (array? arrayp)
      (character? characterp)
      (number< <)
      (integer< <)
      (character< <)
      (number> >)
      (integer> >)
      (character> >)
      (%error error)
      (%nconc nconc)))

;;; Global variables provided by all tré cores.
(defconstant +core-variables+
    '(*universe* *variables* *defined-functions*
      *environment-path* *environment-filenames*
      *macroexpand-hook* *quasiquoteexpand-hook* *dotexpand-hook*
      *default-listprop* *keyword-package*
      *pointer-size*))

;;; Things we have to implement ourselves.
(defconstant +implementations+
    '(%set-atom-fun %not cpr rplacp %load atan2 pow quit string-concat %load
      %eval %defun early-defun %defvar %defmacro %string %make-symbol
      %symbol-name %symbol-value %symbol-function %symbol-package
      %number? == number== integer== character== %integer %+ %- %* %/ %< %>
      string== list-string
      =-aref
      %make-hash-table href =-href
      ? functional
      builtin? macro?
      %%macroexpand %%macrocall %%%macro?
      %princ %force-output))

(defun make-keyword (x)
  (values (intern (symbol-name x) "KEYWORD")))

(defun make-keywords (x)
  (mapcar #'make-keyword x))

(defun all-exports ()
  (make-keywords (append +core-variables+
                         +direct-imports+
                         (mapcar #'car +renamed-imports+)
                         +implementations+)))

(defun cl-peek-char (&rest x)
  (apply #'peek-char x))

(defun cl-read-char (&rest x)
  (apply #'read-char x))


;;;; The core package where the action happens.

(defmacro define-core-package ()
  `(defpackage :tre-core
     (:use :common-lisp :tre-init)
     (:shadow :*macroexpand-hook*
              :read :peek-char :read-char)
     (:export ,@(all-exports))))

(define-core-package)

(defpackage :tre
  (:use :tre-core)
  (:export :%backquote :backquote :quasiquote :quasiquote-splice
           :square :curly :accent-circonflex))

(in-package :tre-core)

;;; Wrapped functions.

(defmacro define-wrappers ()
  `(progn
     ,@(mapcar #'(lambda (x)
                   `(defun ,(values (intern (symbol-name (car x)) "TRE-CORE")) (&rest x)
                      (apply (function ,(cadr x)) x)))
               +renamed-imports+)))

(define-wrappers)

;;; Global variables.

(defvar *universe* nil)
(defvar *variables* nil)
(defvar *defined-functions* nil)
(defvar *environment-path* ".")
(defvar *environment-filenames* nil)
(defvar *macroexpand-hook* nil)
(defvar *quasiquoteexpand-hook* nil)
(defvar *dotexpand-hook* nil)
(defvar *default-listprop* nil)
(defvar *keyword-package* (find-package "KEYWORD"))
(defvar *pointer-size* 4)

(defvar *macros* nil)
(defvar *builtins* (make-hash-table :test #'eq))
(defvar *function-sources* (make-hash-table :test #'eq))

;;; Implementations.

(defun group (x size)
  (cond
    ((not x) nil)
    ((< (length x) size) (list x))
    (t (cons (subseq x 0 size)
             (group (nthcdr size x) size)))))

(defmacro ? (&body body)
  (let* ((tests (group body 2))
         (end   (car (last tests))))
    (unless body
      (error "Body is missing."))
    `(cond
       ,@(if (= 1 (length end))
             (append (butlast tests) (list (cons t end)))
             tests))))

(defun %not (&rest x) (every #'not x))

(defun cpr (x) x nil)
(defun rplacp (v x) x v)

(defun builtin? (x) (gethash x *builtins*))
(defun macro? (x) (rassoc x *macros* :test #'eq))

(defun =-aref (v x &rest indexes) v x (apply #'aref x indexes))

(defun %make-hash-table (&key (test #'eql))
  (make-hash-table :test (? (eq test #'==)
                            #'eql
                            test)))

(defun href (x i) (gethash i x))
(defun =-href (v x i) (setf (gethash i x) v))

(defun file-exists? (pathname) pathname (error "Not implemented."))
(defun %fopen (pathname access-mode) pathname access-mode (error "Not implemented."))

(defun quit (x) x (error "Not implemented."))

(defun %malloc (num-bytes) num-bytes (error "Not implemented."))
(defun %malloc-exec (num-bytes) num-bytes (error "Not implemented."))
(defun %free (address) address (error "Not implemented."))
(defun %free-exec (address) address (error "Not implemented."))
(defun %%set (address byte) address byte (error "Not implemented."))
(defun %%get (address) address (error "Not implemented."))

(defun function-native (x) x)
(defun function-bytecode (x) x (error "Not implemented."))
(defun =-function-bytecode (v x) v x (error "Not implemented."))
(defun function-source (x) x (gethash x *function-sources*))
(defun =-function-source (v x) v x (setf (gethash x *function-sources*) v))

(defun bit-or (a b) (bit-or a b))
(defun << (x num-bits-to-left) x num-bits-to-left (error "Not implemented."))
(defun >> (x num-bits-to-right) x num-bits-to-right (error "Not implemented."))

(defun =-symbol-value (x) x (error "Not implemented."))
(defun %setq-atom-value (value symbol) value symbol (error "Not implemented."))
(defun =-symbol-function (x) x (error "Not implemented."))

(defun filter (fun x) (mapcar fun x))
(defun %set-elt (object sequence index) object sequence index (error "Not implemented."))

(defun %fclose (stream-handle) stream-handle (error "Not implemented."))
(defun %directory (pathname) pathname (error "Not implemented."))
(defun %stat (pathname) pathname (error "Not implemented."))
(defun readlink (pathname) pathname (error "Not implemented."))

(defun %terminal-raw () (error "Not implemented."))
(defun %terminal-normal () (error "Not implemented."))
(defun end-debug () (error "Not implemented."))

(defun alien-dlopen (path-to-shared-library) path-to-shared-library (error "Not implemented."))
(defun alien-dlsym (handle) handle (error "Not implemented."))
(defun alien-call (address) address (error "Not implemented."))

(defun open-socket (port-number) port-number (error "Not implemented."))
(defun accept () (error "Not implemented."))
(defun recv () (error "Not implemented."))
(defun send (string) string (error "Not implemented."))
(defun close-connection () (error "Not implemented."))
(defun close-socket () (error "Not implemented."))

(defun %type-id (x) x (error "Not implemented."))
(defun %%id (x) x (error "Not implemented."))
(defun %error (x) x (error x))
(defun %strerror (x) x (error "Not implemented."))
(defun atan2 (x) x (error "Not implemented."))
(defun pow (x) x (error "Not implemented."))
(defun quit (x) x (error "Not implemented."))
(defun %nconc (&rest x) x (apply #'nconc x))
(defun string-concat (&rest x) x (apply #'concatenate 'string x))

(defun %string (x)
  (? (numberp x)
     (format nil "~A" x)
     (string x)))

(defun %make-symbol (x)
  (intern x "TRE"))

(defun %symbol-value (x)
  (? (boundp x)
     (symbol-value x)
     x))

(defun %symbol-function (x)
  (? (fboundp x)
     (symbol-function x)))

(defun %symbol-package (x)
  (? (boundp x)
     (symbol-package x)))

(defun %number? (x)
  (or (numberp x)
      (characterp x)))

(defun %integer (x)
  (floor x))

(defun chars-to-numbers (x)
  (mapcar #'(lambda (x)
              (? (characterp x)
                 (char-code x)
                 x))
          x))


(defun == (&rest x) (apply #'= (chars-to-numbers x)))
(defun number== (&rest x) (apply #'= (chars-to-numbers x)))
(defun integer== (&rest x) (apply #'= (chars-to-numbers x)))
(defun character== (&rest x) (apply #'= (chars-to-numbers x)))
(defun %+ (&rest x) (apply #'+ (chars-to-numbers x)))
(defun %- (&rest x) (apply #'- (chars-to-numbers x)))
(defun %* (&rest x) (apply #'* (chars-to-numbers x)))
(defun %/ (&rest x) (apply #'/ (chars-to-numbers x)))
(defun %< (&rest x) (apply #'< (chars-to-numbers x)))
(defun %> (&rest x) (apply #'> (chars-to-numbers x)))

(defun string== (a b) (string= a b))

(defun list-string (x)
  (apply #'concatenate 'string (mapcar #'(lambda (x)
                                           (string (? (numberp x)
                                                      (code-char x)
                                                      x)))
                                       x)))

(defun =-aref (v x i) (setf (aref x i) v))

(defun %princ (x stream) (princ x stream))
(defun %force-output (stream) (force-output stream))

(defmacro %set-atom-fun (x v) `(setf (symbol-function ',x) ,v))

(defmacro %defvar (name &optional (init nil))
  (print `(%defvar ,name))
  `(progn
     (push ',name *variables*)
     (defvar ,name ,init)))

(defmacro %defun (name args &body body)
  (print `(%defun ,name ,args))
  `(progn
     (push ',name *defined-functions*)
     (defun ,name ,args ,@body)))

(defmacro early-defun (name args &body body)
  `(%defun ,name ,args ,@body))

(load "cl/tree-walk.lisp")
(load "cl/backquote-expand.lisp")
(load "cl/read.lisp")
(load "cl/argument-expand.lisp")

(defun %%macroexpand (x)
  (!? *macroexpand-hook*
      (funcall ! x)
      x))

(defmacro %defmacro (name args &body body)
  (print `(%defmacro ,name ,args))
  `(push (cons ',name
               (cons ',args
                     #'(lambda ,(argument-expand-names '%defmacro args)
                         ,@body)))
         *macros*))

(defun %%macrocall (x)
  (alet (cdr (assoc (car x) *macros* :test #'eq))
    (apply (cdr !) (cdrlist (argument-expand (car x) (car !) (cdr x))))))

(defun %%%macro? (x)
  (assoc x *macros* :test #'eq))

(defun function-expr? (x)
  (and (consp x)
       (eq 'function (car x))
       (not (atom (cadr x)))))

(defun make-lambdas (x)
  (cond
    ((atom x)                  x)
    ((function-expr? (car x))  `(labels ((~ja ,@(make-lambdas (cadar x))))
                                  (~ja ,@(make-lambdas (cdr x)))))
    ((function-expr? x)        `#'(lambda ,@(make-lambdas (cadr x))))
    (t (mapcar #'make-lambdas x))))

(defun quasiquote-expand (x)
  (!? *quasiquoteexpand-hook*
      (funcall ! x)
      x))

(defun dot-expand (x)
  (!? *dotexpand-hook*
      (funcall ! x)
      x))

(defun %eval (x)
  (eval (make-lambdas (car (backquote-expand (list x))))))


;;; Loader

(defun %load-r (s)
  (when (peek-char s)
    (cons (read s)
          (%load-r s))))

(defun %expand (x)
  (alet (quasiquote-expand (%%macroexpand (dot-expand x)))
    (? (equal x !)
       x
       (%expand !))))

(defun %load (pathname)
  (print `(%load ,pathname))
  (dolist (i (with-open-file (s pathname)
               (%load-r s)))
    (%eval (%expand i))))


;;;; User package.

(in-package :tre)

(defun eval (x) (%eval x))
(defun macroexpand (x) (%%macroexpand x))
(defun string (x) (%string x))
(defun not (&rest x) (apply #'%not x))
(defun make-symbol (x) (%make-symbol x))
(defun symbol-value (x) (%symbol-value x))
(defun symbol-function (x) (%symbol-function x))
(defun symbol-package (x) (%symbol-package x))
(defun number? (x) (%number? x))
(defun integer (x) (%integer x))
(defun number+ (&rest x) (apply #'%+ x))
(defun integer+ (&rest x) (apply #'%+ x))
(defun character+ (&rest x) (apply #'%+ x))
(defun number- (&rest x) (apply #'%- x))
(defun integer- (&rest x) (apply #'%- x))
(defun character- (&rest x) (apply #'%- x))
(defun * (&rest x) (apply #'%* x))
(defun / (&rest x) (apply #'%/ x))
(defun < (&rest x) (apply #'%< x))
(defun > (&rest x) (apply #'%> x))
(defun filter (fun x) (mapcar fun x))
(defun make-hash-table (&key (test #'eql)) (%make-hash-table :test test))

(%load "environment/env-load-cl.lisp")
