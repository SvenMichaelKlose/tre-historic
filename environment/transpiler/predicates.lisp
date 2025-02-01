(progn
  ,@(@ [`(def-head-predicate ,_)]
       '(identity quote backquote unquote unquote-splice)))

(fn sharp-quote? (x)
  (& (function-expr? x)
     (atom .x.)
     (not ..x)))

(fn simple-argument-list? (x)
  (? x
     (notany [| (cons? _)
                (argument-keyword? _)]
             x)
     t))

(fn constant-literal? (x)
  (| (bool? x)
     (number? x)
     (character? x)
     (string? x)
     (array? x)
     (hash-table? x)))
