(defconstant +cl-symbol-imports+
    '(nil t
      setq cond progn block return-from tagbody go labels
      quote function lambda
      &rest &body &optional &key))

(defconstant +cl-core-symbols+
    '(backquote unquote unquote-splice
      brackets braces))

(defconstant +cl-function-imports+
    '(apply
      cons car cdr rplaca rplacd
      length make-string
      mod sqrt sin cos tan asin acos atan exp round floor ceiling
      aref char-code
      make-package package-name find-package
      print))

(defconstant +cl-renamed-imports+
    '((cons?        CONSP)
      (symbol?      SYMBOLP)
      (function?    FUNCTIONP)
      (string?      STRINGP)
      (array?       ARRAYP)
      (number?      NUMBERP)
      (character?   CHARACTERP)
      (integer      FLOOR)
      (%code-char   CODE-CHAR)
      (-            -)
      (*            *)
      (/            /)
      (==           =)
      (<            <)
      (>            >)
      (<=           <=)
      (>=           >=)
      (%*           *)
      (%/           /)
      (number==     =)
      (number+      +)
      (number-      -)
      (number*      *)
      (number/      /)
      (number<      <)
      (number>      >)
      (character==  CHAR=)
      (character<   CHAR<)
      (character>   CHAR>)
      (log          LOG)
      (pow          EXPT)))

(defconstant +cl-special-forms+
    '(%fn-quiet %fn %defvar %defmacro ?))
