(%defvar *macros* nil)          ; All macros defined in the host environment.

(%defvar *macro?* nil)          ; Predicate if symbol belongs to a named macro.
(%defvar *macrocall* nil)       ; Function expanding a macro.
(%defvar *macroexpand* nil)     ; The function called by DEFMACRO.

(%defvar *current-macro* nil)   ; For debugging.

(%fn %macroexpand-backquote (x)
  (?
    (atom x)                     x
    (atom x.)                    (. x. (%macroexpand-backquote .x))
    (eq x.. 'unquote)         (. (. 'unquote
                                       (%macroexpand (cdr x.)))
                                    (%macroexpand-backquote .x))
    (eq x.. 'unquote-splice)  (. (. 'unquote-splice
                                       (%macroexpand (cdr x.)))
                                    (%macroexpand-backquote .x))
    (. (%macroexpand-backquote x.)
       (%macroexpand-backquote .x))))

(%defvar *macroexpand-backquote* #'%macroexpand-backquote)

(%fn %macroexpand-rest (x)
  (? (atom x)
     x
     (. (%macroexpand x.)
        (%macroexpand-rest .x))))

(%fn %macroexpand (x)
  (?
    (atom x)                    x
    (apply *macro?* (list x))   (#'((x)
                                     (? (cons? x)
                                        (. x. (%macroexpand-rest .x))
                                        x))
                                   (apply *macrocall* (list x)))
    (eq x. 'quote)              x
    (eq x. 'backquote)          (. 'backquote (apply *macroexpand-backquote* (list .x)))
    (eq x. 'unquote)         (. 'unquote (%macroexpand .x))
    (eq x. 'unquote-splice)  (. 'unquote-splice (%macroexpand .x))
    (. (%macroexpand x.)
       (%macroexpand-rest .x))))

(%fn native-macroexpand (x)
  (#'((predicate caller current-macro)
        (setq *macro?*         #'%%macro?
              *macrocall*      #'%%macrocall
              *current-macro*  nil)
        (#'((x)
              (setq *macro?*         predicate
                    *macrocall*      caller
                    *current-macro*  current-macro)
              x)
          (%macroexpand x)))
     *macro?* *macrocall* *current-macro*))

(setq *macroexpand* #'native-macroexpand)
