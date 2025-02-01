(%fn %unquote-expand (x)
  (?
    (atom x)                  x
    (atom x.)                 (. x. (%unquote-expand .x))
    (eq x.. 'quote)           (. x. (%unquote-expand .x))
    (eq x.. 'backquote)       (. x. (%unquote-expand .x))
    (eq x.. 'unquote)         (. (eval (macroexpand (car (cdr x.))))
                                 (%unquote-expand .x))
    (eq x.. 'unquote-splice)  (append (eval (macroexpand (car (cdr x.))))
                                      (%unquote-expand .x))
    (. (%unquote-expand x.)
       (%unquote-expand .x))))

(%fn unquote-expand (x)
  (car (%unquote-expand (list x))))

(%fn unquote-expand (x)
  (unquote-expand x))

(%defvar *unquote-expand* #'unquote-expand)
(%defvar *unquote-expand* #'unquote-expand)
