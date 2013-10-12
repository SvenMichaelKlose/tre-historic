;;;;; tré – Copyright (c) 2008–2013 Sven Michael Klose <pixel@copei.de>

(transpiler-pass transpiler-frontend-2 (tr)
    thisify                   [thisify (transpiler-thisify-classes tr) _]
    rename-arguments          #'rename-arguments
    lambda-expand             #'lambda-expand
    fake-place-expand         #'fake-place-expand
    fake-expression-expand    #'fake-expression-expand)

(transpiler-pass transpiler-frontend-1 (tr)
    file-input                #'identity
    dot-expand                [? (transpiler-dot-expand? tr)
                                 (dot-expand _)
                                 _]
    quasiquote-expand         #'quasiquote-expand
    transpiler-macroexpand-2  [transpiler-macroexpand tr _]
    compiler-macroexpand      #'compiler-macroexpand
    backquote-expand          #'backquote-expand
    literal-conversion        [funcall (transpiler-literal-converter tr) _])

(defun transpiler-frontend-0 (tr x)
  (transpiler-frontend-2 tr (transpiler-frontend-1 tr x)))

(defun transpiler-frontend (tr x)
  (remove-if #'not (mapcan [(= *default-listprop* nil)
                            (transpiler-frontend-0 tr (list _))] x)))

(defun transpiler-frontend-file (tr file)
  (format t "(LOAD \"~A\")~%" file)
  (force-output)
  (transpiler-frontend tr (read-file-all file)))
