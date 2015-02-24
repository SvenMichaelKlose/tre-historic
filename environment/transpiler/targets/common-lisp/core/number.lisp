; tré – Copyright (c) 2014–2015 Sven Michael Klose <pixel@copei.de>

(defbuiltin number? (x)
  (| (cl:numberp x)
     (cl:characterp x)))

(defbuiltin integer (x)
  (cl:floor x))

(defun chars-to-numbers (x)
  (cl:mapcar (lambda (x)
               (? (cl:characterp x)
                  (cl:char-code x)
                  x))
             x))

(defbuiltin == (&rest x) (apply #'cl:= (chars-to-numbers x)))
(defbuiltin number== (&rest x) (apply #'cl:= (chars-to-numbers x)))
(defbuiltin integer== (&rest x) (apply #'cl:= (chars-to-numbers x)))
(defbuiltin character== (&rest x) (apply #'cl:= (chars-to-numbers x)))
(defbuiltin %+ (&rest x) (apply #'cl:+ (chars-to-numbers x)))
(defbuiltin %- (&rest x) (apply #'cl:- (chars-to-numbers x)))
(defbuiltin %* (&rest x) (apply #'cl:* (chars-to-numbers x)))
(defbuiltin %/ (&rest x) (apply #'cl:/ (chars-to-numbers x)))
(defbuiltin %< (&rest x) (apply #'cl:< (chars-to-numbers x)))
(defbuiltin %> (&rest x) (apply #'cl:> (chars-to-numbers x)))
(defbuiltin code-char (x) (cl:code-char (cl:floor x)))
(defbuiltin number+ (&rest x) (apply #'%+ x))
(defbuiltin integer+ (&rest x) (apply #'%+ x))
(defbuiltin character+ (&rest x) (apply #'%+ x))
(defbuiltin number- (&rest x) (apply #'%- x))
(defbuiltin integer- (&rest x) (apply #'%- x))
(defbuiltin character- (&rest x) (apply #'%- x))
(defbuiltin * (&rest x) (apply #'%* x))
(defbuiltin / (&rest x) (apply #'%/ x))
(defbuiltin < (&rest x) (apply #'%< x))
(defbuiltin > (&rest x) (apply #'%> x))
;(defbuiltin bit-or (a b) (cl:bit-or a b))

(defun bits-integer (bits)
  (cl:reduce #'((a b)
                 (+ (* a 2) b))
             bits))

(defun integer-bits (x)
  (with (l nil)
    (cl:dotimes (i 32)
      (cl:multiple-value-bind (i r) (cl:truncate x 2)
        (cl:setq x i)
        (cl:push r l)))
    (cl:coerce l 'cl:bit-vector)))

(defbuiltin bit-and (a b)
  (bits-integer (cl:bit-and (integer-bits a) (integer-bits b))))
