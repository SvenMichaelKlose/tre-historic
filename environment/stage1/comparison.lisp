;;;;; TRE environment
;;;;; Copyright (C) 2005-2006,2008-2009 Sven Klose <pixel@copei.de>
;;;;;
;;;;; Comparison

(defun equal (x y)
  "Return T if arguments are the same or have the same value."
  (if
	(or (atom x)
		(atom y))
      (eql x y)
    (equal (car x)
		   (car y))
      (equal (cdr x)
			 (cdr y))))

(define-test "EQUAL with CONS"
  ((equal (list 'x)
		  (list 'x)))
  t)

(define-test "EQUAL fails on different lists"
  ((equal '(1 2) '(3 4)))
  nil)

(defun >= (x y)
  (or (= x y)
      (> x y)))

(defun <= (x y)
  (or (= x y)
      (< x y)))

(defun neql (&rest args)
  "Return (not (eql ...)."
  (not (apply #'eql args)))
