(define-transpiler-end :frontend
    :frontend-input             #'identity
    :dot-expand                 #'dot-expand
    :unquote-expand          #'unquote-expand
    :transpiler-macroexpand     #'transpiler-macroexpand
    :compiler-macroexpand       #'compiler-macroexpand
    :quote-expand               #'quote-expand
    :expand-literal-characters  #'expand-literal-characters
    :thisify                    #'thisify
    :rename-arguments           #'rename-arguments
    :lambda-expand              #'lambda-expand
    :initialize-funinfos        [(place-expand _)
                                 _]
    :expression-expand          #'expression-expand
    :gather-imports             #'gather-imports)
