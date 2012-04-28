;;;;; tré - Copyright (c) 2008-2010,2012 Sven Michael Klose <pixel@copei.de>

(defmacro define-tree-filter (name args &body body)
  (let iter (car (last args))
    `(defun ,name ,args
       (?
         ,@body
         (atom ,iter) ,iter
         (cons (,name ,@(butlast args) (car ,iter))
               (,name ,@(butlast args) (cdr ,iter)))))))

(defmacro define-concat-tree-filter (name args &body body)
  (let iter (car (last args))
    `(defun ,name ,args
       (mapcan #'((,iter)
                   (?
                     ,@body
                     (atom ,iter) (list ,iter)
                     (list (,name ,@(butlast args) ,iter))))
               ,iter))))
