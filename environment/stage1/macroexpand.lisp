;;;; nix operating system project
;;;; list processor environment
;;;; Copyright (c) 2006-2007 Sven Klose <pixel@copei.de>
;;;;
;;;; Macro expansion

(setq *universe* (cons '*macrop-diversion*
                 (cons '*macrocall-diversion*
                 (cons '%macroexpand-backquote
                 (cons '%macroexpand-list
                 (cons '%macroexpand-call
                 (cons '%macroexpand
                 (cons '%%macrop
                 (cons '%%macrocall
                 (cons '*current-macro*
                 (cons '*macroexpand-hook* *universe*)))))))))))

(setq *macrop-diversion* nil
      *macrocall-diversion* nil
      *current-macro* nil)

(%set-atom-fun %macroexpand-backquote
  #'(lambda (%gsme)
    (cond
      ((not %gsme))
      ((not (consp %gsme))
          %gsme)
      ((not (consp (car %gsme)))
	  (cons (car %gsme)
                (%macroexpand-backquote (cdr %gsme))))
      ((eq (car (car %gsme)) 'QUASIQUOTE)
	  (cons (cons 'QUASIQUOTE
		      (%macroexpand (cdr (car %gsme))))
	        (%macroexpand-backquote (cdr %gsme))))

      ((eq (car (car %gsme)) 'QUASIQUOTE-SPLICE)
	  (cons (cons 'QUASIQUOTE-SPLICE
		      (%macroexpand (cdr (car %gsme))))
	        (%macroexpand-backquote (cdr %gsme))))

      (t  (cons (%macroexpand-backquote (car %gsme))
	        (%macroexpand-backquote (cdr %gsme)))))))

(%set-atom-fun %macroexpand-list
  #'(lambda (%gsme)
    (cond
      ((not %gsme))
      ((not (consp %gsme))
          %gsme)
      (t  (cons (%macroexpand (car %gsme))
                (%macroexpand-list (cdr %gsme)))))))

(%set-atom-fun %macroexpand-call
  #'(lambda (%gsme)
    (cond
      ((consp (car %gsme))
          (cons (%macroexpand (car %gsme))
                (cdr %gsme)))
      ((apply *macrop-diversion* (list (car %gsme)))
          (setq *current-macro* (car %gsme))
          (#'(lambda (%gsmt)
               (setq *current-macro* nil)
               %gsmt)
            (apply *macrocall-diversion* (list (car %gsme) (cdr %gsme)))))
      (t  %gsme))))

(%set-atom-fun %macroexpand
  #'(lambda (%gsme)
    (cond
      ((not %gsme))
      ((not (consp %gsme))
          %gsme)
      ((eq (car %gsme) 'QUOTE)
          %gsme)
      ((eq (car %gsme) 'BACKQUOTE)
          (cons 'BACKQUOTE
                (%macroexpand-backquote (cdr %gsme))))
      (t  (%macroexpand-call (cons (car %gsme)
                                   (%macroexpand-list (cdr %gsme))))))))

(%set-atom-fun %%macrop
  #'(lambda (%gsme)
    (macrop (symbol-function %gsme))))

(%set-atom-fun %%macrocall
  #'(lambda (%gsme %gsmp)
    (%macrocall (symbol-function %gsme) %gsmp)))

(%set-atom-fun *macroexpand-hook*
  #'(lambda (%gsme)
    (setq *macrop-diversion* #'%%macrop
          *macrocall-diversion* #'%%macrocall
          *current-macro* nil)
    (%macroexpand %gsme)))
