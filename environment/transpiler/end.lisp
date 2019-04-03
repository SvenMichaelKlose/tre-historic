(fn sloppy-equal (x needle)
  (& (atom x)
     (atom needle)
     (return (eql x needle)))
  (& (cons? x)
     (not needle)
     (return t))
  (& (cons? x)
     (cons? needle)
     (equal x. needle.)
     (sloppy-equal .x .needle)))

(fn sloppy-tree-equal (x needle)
  (| (sloppy-equal x needle)
     (& (cons? x)
        (| (sloppy-tree-equal x. needle)
           (sloppy-tree-equal .x needle)))))

(fn dump-pass? (name x)
  (& *transpiler*
     (| (!? (dump-passes?)
            (| (eq t !)
               (member name (ensure-list !))))
        (!? (dump-selector)
            (sloppy-tree-equal x !)))))

(fn dump-pass (end pass x)
  (& (| (dump-pass? pass x)
        (dump-pass? end x))
     (? (equal x (last-pass-result))
        (format t "; Pass ~A outputs no difference to previous dump.~%" pass)
        {(format t "~%; **** Dump of pass ~A:~%" pass)
         (print x)
         (format t "~%; **** End of ~A.~%" pass)}))
  x)

(fn transpiler-pass (p list-of-exprs)
  (with-global-funinfo (funcall p list-of-exprs)))

(fn transpiler-end (name passes list-of-lists-of-exprs)
  (| (enabled-end? name)
     (return list-of-lists-of-exprs))
  (& (dump-pass? name list-of-lists-of-exprs)
     (format t "~%~L; #### Compiler end ~A~%~%" name))
  (@ #'((list-of-exprs)
         (& list-of-exprs
            (with (outpass  (cdr (assoc name (output-passes)))
                   out      nil)
              (@ (p passes (? outpass out list-of-exprs))
                (? (enabled-pass? p.)
                   {(& (dump-passes?)
                       (format t "~%~L; #### Running pass ~A in ~A~%" p. name))
                    (= list-of-exprs (dump-pass name p. (transpiler-pass .p list-of-exprs)))
                    (= (last-pass-result) list-of-exprs)
                    (& (eq p. outpass)
                       (= out list-of-exprs))}
                  (& (dump-passes?)
                     (format t "~%~L; #### Skipping pass ~A in ~A~%" p. name)))))))
     list-of-lists-of-exprs))

(defmacro define-transpiler-end (name &rest name-function-pairs)
  (!= (group name-function-pairs 2)
    `(fn ,(make-symbol (symbol-name name)) (list-of-lists-of-exprs)
       (transpiler-end ,name
                       (list ,@(@ [`(. ,@_)]
                                  (pairlist (@ #'make-keyword (carlist !))
                                            (cdrlist !))))
                       list-of-lists-of-exprs))))
