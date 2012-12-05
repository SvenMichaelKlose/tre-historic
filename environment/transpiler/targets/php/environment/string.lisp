;;;;; tré – Copyright (c) 2008–2012 Sven Michael Klose <pixel@copei.de>

(dont-obfuscate is_string)

(defun string? (x)
  (is_string x))

(defun string-concat (&rest x)
  (let result ""
    (dolist (i x result)
      (= result (%%%string+ result i)))))

(dont-obfuscate ord strlen substr)

(defun %elt-string (seq idx)
  (when (%%%< idx (strlen seq))
    (code-char (ord (substr seq idx 1)))))

(dont-obfuscate from-char-code)

,(when *transpiler-assert*
   '(defun %=-elt-string (val seq idx)
      (error "cannot modify strings")))

(dont-obfuscate strval)

(defun string (x)
  (?
	(string? x) x
	(character? x) (char-string x)
    (symbol? x) (symbol-name x)
	(not x) "NIL" ;,*nil-symbol-name*
   	(strval x))) ; XXX wrong conversion? got no net to find out.

(defun string== (x y)
  (%%%== x y))

(dont-obfuscate strtoupper)

(defun string-upcase (x)
  (strtoupper x))

(dont-obfuscate strtolower)

(defun string-downcase (x)
  (strtolower x))

(dont-obfuscate substr)

(defun string-subseq (seq start &optional (end 99999))
  (? (== start end)
	 ""
     (substr seq start (- end start))))
