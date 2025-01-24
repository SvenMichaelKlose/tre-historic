(var *body*)

(defmacro metacode-walker (name args
                           &key (if-atom nil)
                                (if-cons nil)
                                (if-setq nil)
                                (if-go nil)
                                (if-go-nil nil)
                                (if-go-not-nil nil)
                                (if-go-cond nil)
                                (if-named-function nil))
  (with-cons x r args
    (with-gensym v
      `(fn ,name ,args
         (when ,x
           (let ,v (car ,x)
             (+ (?
                  (%native? ,v)
                    (error "%%NATIVE in metacode.")
                  (atom ,v)            ,(| if-atom `(… ,v))
                  ,@(!? if-setq        `((%=? ,v) ,!))
                  ,@(!? if-go          `((%go? ,v) ,!))
                  ,@(!? if-go-nil      `((%go-nil? ,v) ,!))
                  ,@(!? if-go-not-nil  `((%go-not-nil? ,v) ,!))
                  ,@(!? if-go-cond     `((%go-cond? ,v) ,!))
                  (%comment? ,v)       (list ,v)
                  (named-lambda? ,v)
                    (with-lambda-funinfo ,v
                      (with-temporary *body* (lambda-body ,v)
                        (list (copy-lambda ,v
                                  :body ,(| if-named-function
                                            `(,name (lambda-body ,v) ,@r))))))
                  (%collection? ,v)
                    (list (append (list '%collection (cadr ,v))
                                  (@ [. _. (,name ._)]
                                     (cddr ,v))))
                  (not (metacode-statement? ,v))
                    (funinfo-error "METACODE-STATEMENT? is NIL for ~A." ,v)
                  ,(| if-cons `(list ,v)))
                (,name (cdr ,x) ,@r))))))))
