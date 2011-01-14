;;;;; TRE transpile1
;;;;; Copyright (c) 2008-2011 Sven Klose <pixel@copei.de>

;; After this pass:
;; - Symbols are obfuscated.
;; - Strings are encapsulated.
;; - Expressions are expanded via code generating macros.
;; - Everything is converted to strings and concatenated.
(defun transpiler-emit-code-compose (tr)
  (transpiler-pass
;      print-o (fn (princ #\o)
;			      (force-output)
;			      _)
	  concat-stringtree #'concat-stringtree
	  to-string (fn transpiler-to-string tr _)
	  obfuscate (fn transpiler-obfuscate tr _)
	  codegen-expander (fn expander-expand (transpiler-macro-expander tr) _)
	  finalize-sexprs #'transpiler-finalize-sexprs
	  encapsulate-strings #'transpiler-encapsulate-strings
	  function-names (fn translate-function-names nil _)))

(defun transpiler-emit-code (tr x)
  (funcall (transpiler-emit-code-compose tr) x))

(defun transpiler-make-places-compose ()
  (transpiler-pass
	  place-assign #'place-assign
      place-expand #'place-expand
      make-function-prologues #'make-function-prologues))

;; After this pass:
;; - Function prologues are generated.
;; - Places are translated into vector ops.
(defun transpiler-generate-code (tr x)
  (if (transpiler-lambda-export? tr)
      (funcall (transpiler-make-places-compose) x)
	  (make-function-prologues x)))

(defun transpiler-backend (tr x)
  (funcall (transpiler-emit-code-compose tr)
  		   (transpiler-generate-code tr x)))
