;;;;; tré – Copyright (c) 2008–2013 Sven Michael Klose <pixel@copei.de>

(defun inverted-%%go (x)
  (case x :test #'eq
    '%%go-nil      '%%go-not-nil
    '%%go-not-nil  '%%go-nil
    (error "Jump expected instead of ~A." x)))

(defun jumps-to-tag (x)
  (count-if [& (vm-jump? _)
               (== x (%%go-tag _))]
            *body*))

(defun constant-jump? (x constant)
  (| (? constant
        (%%go-not-nil? x)
        (%%go-nil? x))
     (%%go? x)))

(defun target-tag (x constant)
  (& x (?
         (number? x.)                 (target-tag .x constant)
         (constant-jump? x. constant) (| (target-tag (member (%%go-tag x.) *body*) constant)
                                         (%%go-tag x.)))))

(defun t|nil? (x)
  (| (not x)
     (t? x)))

(define-optimizer optimize-jumps
  (& (%%go-cond? a)
     (let dest (cdr (tag-code (%%go-tag a)))
       (& (%%go-cond? dest.)
          (eq a. dest..))))
    (. `(,a. ,(%%go-tag (cadr (tag-code (%%go-tag a)))) ,(%%go-value a))
       (optimize-jumps d))
  (& (%=? a)
     (~%ret? (%=-place a))
     (t|nil? (%=-value a))
     (!? (target-tag d (%=-value a))
         (not (will-be-used-again? (member ! *body*) '~%ret))))
    (. `(%%go ,(target-tag d (%=-value a)))
       (optimize-jumps d))
  (& (%=? a)
     (~%ret? (%=-place a))
     (t|nil? (%=-value a))
     (? (%=-value a)
        (%%go-nil? d.)
        (%%go-not-nil? d.)))
    (. a (optimize-jumps .d))
  (& (%%go-cond? a)
     (%%go? d.)
     (number? .d.)
     (== (%%go-tag a) .d.))
    (. `(,(inverted-%%go a.) ,(%%go-tag d.) ,(%%go-value a))
       (optimize-jumps .d)))
