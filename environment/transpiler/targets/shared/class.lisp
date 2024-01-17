(fn generic-defclass (constructor-maker class-name args body)
  (print-definition `(defclass ,class-name ,@(!? args (list !))))
  (with (cname    (? (cons? class-name) class-name. class-name)
         bases    (& (cons? class-name) .class-name)
         classes  (defined-classes))
    (& (href classes cname)
       (error "Class ~A already defined." cname))
    (& .bases
       (error "Multiple inheritance is not supported."))
    (& bases
       (not (href classes bases.))
       (error "Undefined base class ~A." bases.))
    (= (href classes cname)
       (make-class :name     cname
                   :base     bases.
                   :members  (& bases (class-members (href classes bases.)))
                   :parent   (& bases (href classes bases.))
                   :constructor-maker
                     (list constructor-maker args body)))
    nil))

(fn get-method-flags-and-rest (x)
  (with (r #'((x flags)
               (? (in? x. :static :protected :private)
                  (? (member x. flags)
                     (error "Double method flag ~A." x.)
                     (r .x (. x. flags)))
                  (values x flags))))
    (r x nil)))

(fn generic-defmethod (x)
  (with ((args flags) (get-method-flags-and-rest x))
    (apply #'((class-name name args body)
               (print-definition `(defmethod ,class-name ,name ,args))
               (!? (href (defined-classes) class-name)
                   (progn
                     (& (assoc name (class-methods !))
                        (error "In class '~A': member '~A' already defined."
                               class-name name))
                     (acons! name (list args body flags)
                             (class-methods !)))
                   (error "Undefined class ~A." class-name)))
             (argument-expand-values nil '(class-name name args &body body)
                                     args)))
  nil)

(fn generic-defmember (class-name names)
  (print-definition `(defmember ,class-name ,@names))
  (!? (href (defined-classes) class-name)
      (+! (class-members !) (@ [list _ t] names))
      (error "Undefined lass ~A." class-name))
  nil)
