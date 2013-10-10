;;;;; tré – Copyright (c) 2005–2013 Sven Michael Klose <pixel@copei.de>

(defun make-lexical-place-expr (fi var)
  (funinfo-add-free-var fi var)
  `(%vec ,(funinfo-ghost fi)
         ,(funinfo-name (funinfo-parent fi))
         ,var))

(defun make-lexical-1 (fi var)
  (? (funinfo-arg-or-var? (funinfo-parent fi) var)
	 (make-lexical-place-expr fi var)
	 (make-lexical-1 (funinfo-parent fi) var)))

(defun make-lexical-0 (fi x)
  (funinfo-setup-lexical-links fi x)
  (let ret (make-lexical-1 fi x)
	`(%vec ,(place-expand-atom fi (make-lexical fi .ret.))
		   ,..ret.
		   ,...ret.)))

(defun make-lexical (fi x)
  (? (eq x (funinfo-ghost fi))
	 (place-expand-atom (funinfo-parent fi) x)
	 (make-lexical-0 fi x)))

(defun place-expand-emit-stackplace (fi x)
  `(%stack ,(funinfo-name fi) ,x))

(defun place-expand-atom (fi x)
  (?
    (not fi)
      (progn
        (print x)
        (error "FUNINFO is missing."))

    (| (constant-literal? x)
       (not (funinfo-var-or-lexical? fi x)))
      x

    (& (transpiler-stack-locals? *transpiler*)
       (eq x (funinfo-lexical fi)))
      (place-expand-emit-stackplace fi x)

    (& (not (eq x (funinfo-lexical fi)))
       (funinfo-lexical? fi x))
      `(%vec ,(place-expand-atom fi (funinfo-lexical fi))
             ,(funinfo-name fi)
             ,x)

    (& (transpiler-stack-locals? *transpiler*)
       (funinfo-var? fi x))
       (place-expand-emit-stackplace fi x)

    (funinfo-arg-or-var? fi x)
      x

    (funinfo-global-variable? fi x)
      `(%global ,x)

    (make-lexical fi x)))

(defun place-expand-fun (x)
  (let fi (get-lambda-funinfo x)
    (| fi
       (error "FUNINFO missing for ~A." (lambda-name x)))
    (copy-lambda x :body (place-expand-0 fi (lambda-body x)))))

(defun place-expand-setter (fi x)
  (let p (place-expand-0 fi (%setq-place x))
    `(%set-vec ,.p. ,..p. ,...p. ,(place-expand-0 fi (%setq-value x)))))

(define-tree-filter place-expand-0 (fi x)
  (not fi)              (error "FUNFINFO is missing.")
  (atom x)              (place-expand-atom fi x)
  (| (%quote? x)
     (%%native? x)
     (%var? x))
                        x
  (named-lambda? x)     (place-expand-fun x)
  (& (%setq? x)
     (%vec? (place-expand-0 fi (%setq-place x))))
                        (place-expand-setter fi x)
  (& (%set-atom-fun? x)
     (%vec? (place-expand-0 fi (%setq-place x))))
                        (place-expand-setter fi x)
  (%%closure? x)        x
  (%slot-value? x)      `(%slot-value ,(place-expand-0 fi .x.) ,..x.)
  (%stackarg? x)        x)

(defun place-expand (x)
  (place-expand-0 (transpiler-global-funinfo *transpiler*) x))

(defun place-expand-closure-lexical (fi)
  (alet (funinfo-parent fi)
    (place-expand-0 ! (funinfo-lexical !))))
