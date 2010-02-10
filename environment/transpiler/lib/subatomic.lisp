;;;; TRE compiler
;;;; Copyright (c) 2006-2010 Sven Klose <pixel@copei.de>
;;;;
;;;; Subatomic expression utilities.

(mapcar-macro x
	'(%quote %new
	  vm-scope vm-go vm-go-nil
	  %stack %vec %setq
	  %transpiler-native %transpiler-string
	  %function-prologue
	  %function-epilogue
	  %function-return)
  `(def-head-predicate ,x))

(defun atomic? (x)
  (or (atom x)
	  (in? x. '%stack '%vec '%slot-value)))

(defun atomic-or-without-side-effects? (x)
  (or (atomic? x)
	  (and (consp x)
	  	   (in? x. '%quote 'car '%car 'cdr '%cdr))))

(defun vm-jump? (e)
  (and (consp e)
	   (in? e. 'VM-GO 'VM-GO-NIL)))

(defun vm-jump-tag (x)
  (if
	(vm-go? x)
	  .x.
	(vm-go-nil? x)
	  ..x.))

(defun vm-scope-body (x)
  .x)

(defun %var? (x)
  (and (consp x)
	   (eq '%VAR x.)
	   (eq nil ..x)))

(defun %setqret? (x)
  (and (consp x)
	   (eq '%SETQ x.)
	   (eq '~%RET .x.)))

(defun %setq-place (x)
  .x.)

(defun %setq-value (x)
  ..x.)

(defun %setq-value-atom? (x)
    (atom (%setq-value x)))

(defun %slot-value-obj (x)
  .x.)

(defun %slot-value-slot (x)
  ..x.)

(defun ~%ret? (x)
  (eq '~%ret x))

(defun %setq-lambda? (x)
  (and (%setq? x)
	   (lambda? (third x))))

(defun atom-or-quote? (x)
  (or (atom x)
	  (%quote? x)))
