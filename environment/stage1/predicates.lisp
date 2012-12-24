;;;;; tré – Copyright (c) 2005–2006,2008–2009,2011–2012 Sven Michael Klose <pixel@copei.de>

(functional atom cons? symbol? number? string? function? array? zero? even? odd? end? symbol? keyword? integer?)

(defun zero? (x)
  (== 0 x))

(defun even? (x)
  (== 0 (mod x 2)))

(defun odd? (x)
  (== 1 (mod x 2)))

(defun end? (x)
  (eq nil x))

(defun keyword? (x)
  (& (symbol? x)
     (eq *keyword-package* (symbol-package x))))

(define-test "NOT works with NIL"
  ((not nil))
  t)

(define-test "NOT works with T"
  ((not t))
  nil)

(define-test "KEYWORDP recognizes keyword-packaged symbols"
  ((keyword? :lisp))
  t)

(define-test "KEYWORDP works with standard symbols"
  ((keyword? 'lisp))
  nil)
