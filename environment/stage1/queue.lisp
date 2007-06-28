;;;; nix operating system project
;;;; list processor environment
;;;; Copyright (C) 2005-2006 Sven Klose <pixel@copei.de>
;;;;
;;;; Queue functions
;;;;
;;;; Queues are reversed stacks where the first cons' CAR points to the last
;;;; and its CDR to the first element.

(defmacro make-queue ()
  '(cons nil nil))

(defmacro enqueue (queue obj)
  (let ((q (gensym))
	(o (gensym)))
  `(let ((,q ,queue)
	 (,o ,obj))
     (if (car ,q)
       (setf (car ,q) (setf (cdar ,q) (list ,o)))
       (setf (car ,q) (setf (cdr ,q) (list ,o))))
     ,o)))

(defmacro queue-list (queue)
  `(cdr ,queue))

(define-test "ENQUEUE and QUEUE-LIST work"
  ((let ((q (make-queue)))
     (enqueue q 'a)
     (enqueue q 'b)
     (queue-list q)))
  '(a b))
