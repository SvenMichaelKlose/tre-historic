(fn make-symbol-identifier (x)
  ($ (!? (symbol-package x)
         (+ (abbreviated-package-name (symbol-name !)) "_p_")
         "")
     x))

(defmacro define-compiled-literal (name (x table)
                                   &key maker
                                        initializer
                                        (declaration nil))
  (let transpiler-slot `(,($ 'compiled- table 's))
    `(fn ,name (,x)
       (cache (href ,transpiler-slot ,x)
              (aprog1 ,maker
                (unless (funinfo-var? (global-funinfo) !)
                  (funinfo-var-add (global-funinfo) !))
                ,@(when declaration
                     `((push (~> ,declaration !)
                             (compiled-decls))))
                (push `(= ,,! ,(… 'unquote initializer))
                      (compiled-inits)))))))
