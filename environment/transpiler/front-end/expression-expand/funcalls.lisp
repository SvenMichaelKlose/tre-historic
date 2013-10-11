;;;;; tré – Copyright (c) 2009–2013 Sven Michael Klose <pixel@copei.de>

(defun %setq-make-call-to-local-function (x)
  (with-%setq place value x
    (expex-body (transpiler-frontend-1 *transpiler* `((%setq ,place (apply ,value. ,(compiled-list .value))))))))

(defun expex-compiled-funcall (x)
  (alet (%setq-value x)
    (? (& (cons? !)
          (| (function-expr? !.)
             (funinfo-find *funinfo* !.)))
       (%setq-make-call-to-local-function x)
       (list x))))
