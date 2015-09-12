; tré – Copyright (c) 2014–2015 Sven Michael Klose <pixel@hugbox.org>

(defun cl-packages ()
  `((defpackage "TRE-CORE"
      (:export       ,@(@ #'symbol-name
                          (+ +cl-symbol-imports+
                             +cl-core-symbols+
                             +cl-function-imports+
                             *cl-builtins*
                             +cl-special-forms+
                             +core-variables+
                             (carlist +cl-renamed-imports+))))
      (:import-from  "CL" ,@(@ #'symbol-name
                               (+ +cl-symbol-imports+
                                  +cl-function-imports+))))
    (defpackage "TRE"
      (:use "TRE-CORE"))))

(alet (copy-transpiler *cl-transpiler*)
  (with-temporary *transpiler* !
    (add-defined-variable '*macros*))
;  (= (transpiler-dump-passes? !) t)
  (with (c           (compile-sections (list (. 'dummy nil)) :transpiler !)
         print-info  (make-print-info :pretty-print? nil))
    (with-output-file o "boot-common.lisp"
      (format o "; tré Common Lisp core, generated by 'makefiles/boot-common.lisp'.~%")
      (format o "(declaim #+sbcl(sb-ext:muffle-conditions compiler-note style-warning))~%")
      ; Use to debug...
      (format o "(proclaim '(optimize (speed 0) (space 0) (safety 3) (debug 2)))~%")
      (adolist ((cl-packages))
        (late-print ! o :print-info print-info))
      (late-print '(cl:in-package :tre-core) o :print-info print-info)
      (@ [late-print _ o :print-info print-info] c)
      (format o (+ "(cl:in-package :tre)~%"
                   "(cl:format t \"Loading environment...\\~%\")~%"
                   "(env-load \"main.lisp\")~%")))))
(quit)
