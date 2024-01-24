(defconstant +php-array-methods+ '("AREF?" "AREF" "=-AREF" "DELETE-AREF"))

(def-php-transpiler-macro defclass (class-name args &body body)
  (generic-defclass #'php-constructor class-name args body))

(fn php-constructor-name (class-name)
  ($ class-name '-constructor))

(fn php-compiled-constructor-name (cls)
  (compiled-function-name (php-constructor-name (class-name cls))))

(fn php-constructor (class-name unused-base args body)
  (add-defined-function class-name args body)
  `(function ,(php-constructor-name class-name) (,(. 'this args)
     (let ~%this this
       (%thisify ,class-name
         (macrolet ((super (&rest args)
                     `((%%native "parent::__construct" ,,@args))))
           ,@body)))
     this)))

(def-php-transpiler-macro defmember (class-name &rest names)
  (generic-defmember class-name names))

(fn php-members (cls)
  (@ [`(%%native ,(? (cons? _.)
                     (downcase (symbol-name _..))
                     "var")
                 " $" ,(!? (cons? _.) (cadr _.) _.) ,*php-separator*)]
     (class-members cls)))

(def-php-transpiler-macro defmethod (&rest x)
  (generic-defmethod x))

(fn php-method-name-w/o-class (x)
  (case x
    'aref?        'offset-exists
    'aref         'offset-get
    '=-aref       'offset-set
    'delete-aref  'offset-unset
    x))

(fn php-method-name (cls name)
  ($ (class-name cls) '- (php-method-name-w/o-class name)))

(fn php-compiled-method-name (cls name)
  (compiled-function-name (php-method-name cls name)))

(fn php-method-function (cls x)
  `(function ,(php-method-name cls x.) (,(. 'this .x.)
     (let ~%this this
       (%thisify ,(class-name cls)
         ,@(| ..x. (list nil)))))))

(fn php-method-flags (x)
  (flatten (list (pad (@ [downcase (symbol-name _)] x) " ")
                 " ")))

(fn php-method (cls x)
  (!= (argument-expand-names 'php-method .x.)
    `(,@(!? ...x.
            (list (php-method-flags !)))
      "function " ,(php-method-name-w/o-class x.)
                  ,(php-argument-list (? (eq x. '=-aref)
                                         `(("mixed $" ,.!.) ("mixed $" ,!.))
                                         !))
                " : " ,(?
                         (eq x. 'aref?) "bool"
                         (in? x. '=-aref 'delete-aref) "void"
                         "mixed")
                " " ,*terpri*
      "{" ,*terpri*
      ,*php-indent* ,@(unless (in? x. '=-aref 'delete-aref)
                        '("return "))
          ,(php-compiled-method-name cls x.)
          ,(php-argument-list (. 'this !))
          ,*php-separator*
      "}" ,*terpri*)))

(fn php-method-functions (cls)
  (@ [php-method-function cls _]
     (class-methods cls)))

(fn php-methods (cls)
  (+@ [php-method cls _]
      (class-methods cls)))

(fn class-method-names (cls)
  (@ #'symbol-name (carlist (class-methods cls))))

(fn class-array-methods (cls)
  (intersect +php-array-methods+ (class-method-names cls)
             :test #'string==))

(fn class-has-all-array-methods? (cls)
  (subseq? ! +php-array-methods+ :test #'string==))

(fn php-class (cls)
  (!= (carlist (class-methods cls))
    (!? (class-array-methods cls)
       (| (subseq? ! +php-array-methods+)
          (error (+ "With PHP interface 'ArrayAccess' its methods must "
                    "be implemented.  Missing: ~A")
                 (set-difference (print !) (print +php-array-methods+))))))
  `((%php-class-head ,cls ,@(& (class-array-methods cls)
                               '(:implements "ArrayAccess")))
    ,(!= (argument-expand-names 'php-constructor
                                (cadr (class-constructor-maker cls)))
       `("function __construct " ,(php-argument-list !) ,*terpri*
       "{" ,*terpri*
       ,*php-indent* "return "
           ,(php-compiled-constructor-name cls)
           ,(php-argument-list (. 'this !))
           ,*php-separator*
       "}")) ,*terpri*
    ,@(php-members cls)
    ,@(php-methods cls)
    (%php-class-tail)))

(def-php-transpiler-macro finalize-class (class-name)
  (with (classes  (defined-classes)
         !        (| (href classes class-name)
                     (error "Cannot finalize undefined class ~A." class-name)))
    `(progn
       (fn ,($ class-name '?) (x)
         (& (object? x)
            (is_a x ,(convert-identifier class-name))
            x))
       ,(apply (car (class-constructor-maker !))
               class-name (class-base !)
               (cdr (class-constructor-maker !)))
       ,@(php-method-functions !)
       (%= nil (%%native ,@(php-class !))))))
