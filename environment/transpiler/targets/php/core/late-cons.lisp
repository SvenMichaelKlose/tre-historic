; tré – Copyright (c) 2008–2013,2016 Sven Michael Klose <pixel@copei.de>

(= (symbol-function 'cons) "userfun_cons")

(defun car (x)
  (when x
    x.a))

(defun cdr (x)
  (when x
    x.d))

(defun cpr (x)
  (when x
    x.p))

(defun rplaca (x val)
  (= x.a val)
  x)

(defun rplacd (x val)
  (= x.d val)
  x)

(defun rplacp (x val)
  (= x.p val)
  x)

(defun cons? (x)
  (is_a x "__cons"))
