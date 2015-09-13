; tré – Copyright (c) 2008–2015 Sven Michael Klose <pixel@copei.de>

(declare-cps-exception make-symbol make-package symbol-name symbol-value symbol-function symbol-package symbol?)

(defun make-symbol (x &optional (pkg nil))
  (symbol x pkg))

(defun make-package (x)
  (symbol x nil))

(defvar *keyword-package* (make-package "KEYWORD"))

(defun symbol-name (x)
  (?
    (%%%eq t x)     "T"
    (%%%eq false x) "FALSE"
    x               x.n
    "NIL"))

(defun symbol-value (x)
  (?
    (%%%eq t x)  t
    x            x.v))

(defun symbol-function (x)
  (?
    (%%%eq t x)  nil
    x            x.f))

(defun symbol-package (x)
  (?
    (%%%eq t x)  nil
    x            (!? x.p ! 'tre)))

(defun symbol? (x)
  (| (not x)
     (%%%eq t x)
     (& (object? x)
	     x.__class
         (%%%== x.__class ,(obfuscated-identifier 'symbol)))))

(defun package-name (x)
  (? (eq x *keyword-package*)
     "KEYWORD"
     "TRE"))
