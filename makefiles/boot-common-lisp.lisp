(var *cl-debug?* (getenv "TRE_DEBUG"))

(load "environment/stage0/config-defaults-cl.lisp")

(const +core-variables+
       '(*universe* *variables* *functions*
         *environment-path* *environment-filenames*
         *macroexpand* *quasiquote-expand* *dot-expand*
         *package* *keyword-package*
         *pointer-size* *launchfile*
         *assert?* *targets*
         *endianess* *cpu-type* *libc-path* *rand-max*
         *eval*))

(fn cl-packages ()
  `((defpackage "TRE-CORE"
      (:export
        "*LOAD*"
         ,@(@ #'symbol-name
              (+ +cl-symbol-imports+
                 +cl-core-symbols+
                 +cl-function-imports+
                 *cl-builtins*
                 +cl-special-forms+
                 +core-variables+
                 (carlist +cl-renamed-imports+))))
      (:import-from
         "CL" ,@(@ #'symbol-name
                   (+ +cl-symbol-imports+
                      +cl-function-imports+)))
      (:import-from "SB-EXT" "*POSIX-ARGV*"))
    (defpackage "TRE"
      (:use "TRE-CORE"))))

(fn print-init-decls (o print-info)
  (format o "; Generated by 'makefiles/boot-common.lisp'.~%")
  (? *cl-debug?*
     (format o "(proclaim '(optimize (speed 1) (space 0) (safety 3) (debug ~A)))~%"
             (| (getenv "TRE_DEBUG_LEVEL") 2))
     (format o (+ "(declaim #+sbcl(sb-ext:muffle-conditions compiler-note style-warning))~%"
                  "(proclaim '(optimize (speed 3) (space 0) (safety 1) (debug 0)))~%")))
  (@ (i (cl-packages))
    (late-print i o :print-info print-info))
  (late-print '(cl:defpackage "GLOBAL") o)
  (late-print '(cl:in-package :tre-core) o :print-info print-info))

(fn print-env-loader (o)
  (format o (+ "(cl:in-package :tre)~%"
               "(cl:format t \"; Loading environment…\\~%\")~%"
               "(cl:setq *package* \"TRE\")~%"
               "(env-load \"main.lisp\")~%")))

(!= (copy-transpiler *cl-transpiler*)
  (transpiler-add-defined-variable ! '*macros*)
  (with (c           (compile-sections (list (. 'dummy nil)) :transpiler !)
         print-info  (make-print-info :pretty-print? nil))
    (with-output-file o "boot-common.lisp"
      (print-init-decls o print-info)
      (@ [& _ (late-print _ o :print-info print-info]) c)
      (print-env-loader o))))
(quit)
