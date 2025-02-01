(const *printer-abbreviations* '((quote              "'")
                                 (backquote          "`")
                                 (unquote         ",")
                                 (unquote-splice  ",@")))

(var *print-automatic-newline?* t)
(var *always-print-package-names?* nil)
(var *printer-argument-definitions* (make-hash-table :test #'eq))
(var *invisible-package-names* '("TRE" "TRE-CORE"))

(fn add-printer-argument-definition (name x)
  (| (symbol? name)
     (%error "Function name symbol expected."))
  (| (list? x)
     (function? x)
     (%error "Argument definition list or printer function expected."))
  (= (href *printer-argument-definitions* name) x))

(add-printer-argument-definition '%block  '(&body body))
(add-printer-argument-definition 'progn   '(&body body))
(add-printer-argument-definition 'tagbody '(&body body))
(add-printer-argument-definition 'block   '(name &body body))
(add-printer-argument-definition 'cond    '(&body body))

(@ (i *macros*)
  (add-printer-argument-definition i. .i.))

(fn %get-printer-argument-definition (x)
  (href *printer-argument-definitions* x))

(defstruct print-info
  (pretty-print?  nil)
  (downcase?      nil)
  (indentation    0)
  (columns        nil))

(fn %print-gap (str)
  (| (fresh-line? str)
     (princ " " str)))

(fn %print-indentation (str info)
  (& (print-info-pretty-print? info)
     (fresh-line? str)
     (adotimes ((print-info-indentation info))
       (princ " " str))))

(defmacro %with-indentation (str info &body body)
  `(progn
     (%print-indentation ,str ,info)
     ,@body))

(defmacro %with-parens (str info &body body)
  `(%with-indentation ,str ,info
     (push (stream-location-column (stream-output-location str))
           (print-info-columns ,info))
     (princ "(" ,str)
     ,@body
     (princ ")" ,str)
     (pop (print-info-columns ,info))))

(fn %print-object (x str info)
  (princ "{" str)
  (dolist (i (props-alist x))
    (late-print i. str :print-info info)
    (late-print .i str :print-info info))
  (princ "}" str))

(fn pretty-print-lambda (x str info)
  (%with-parens str info
    (++! (car (print-info-columns info)))
    (%late-print (car .x.) str info)
    (& *print-automatic-newline?*
       (fresh-line str))
    (%print-body (cdr .x.) str info))
    (--! (car (print-info-columns info))))

(fn pretty-print-named-lambda (x str info)
  (%with-parens str info
    (!= (++ (car (print-info-columns info)))
      (princ "FUNCTION " str)
      (%late-print .x. str info)
      (%print-gap str)
      (%late-print (car ..x.) str info)
      (& *print-automatic-newline?*
         (fresh-line str))
      (push ! (print-info-columns info))
      (%print-body (cdr ..x.) str info)
      (pop (print-info-columns info)))))

(fn pretty-print-lambdas (x str info)
  (?
    ..x          (pretty-print-named-lambda x str info)
    (cons? .x.)  (progn
                   (princ "#'" str)
                   (pretty-print-lambda x str info))
    (progn
      (princ "#'" str)
      (%print-symbol .x. str info)))
  t)

(add-printer-argument-definition 'function #'pretty-print-lambdas)

(fn %print-rest (x str info)
  (when x
    (? (cons? x)
       (progn
         (%print-gap str)
         (%late-print x. str info)
         (%print-rest .x str info))
       (progn
         (princ " . " str)
         (%late-print x str info)))))

(fn %body-indentation (info)
  (| (car (print-info-columns info)) 1))

(fn %print-body (x str info)
  (with-temporary (print-info-indentation info) (%body-indentation info)
    (let first? t
      (@ (i x)
        (? first?
           (= first? nil)
           (& *print-automatic-newline?*
              (fresh-line str)))
        (%late-print i str info)))))

(fn %print-call (x argdef str info)
  (%with-parens str info
    (%late-print x. str info)
    (let expanded (argument-expand '%print-call .x argdef)
      (? (eq expanded 'error)
         (%print-rest .x str info)
         (@ (i expanded)
           (%print-gap str)
           (?
             (& (%body? .i) ..i)
               (progn
                 (& *print-automatic-newline?*
                    (fresh-line str))
                 (%print-body ..i str info))
             (%rest? .i)
               (%print-rest ..i str info)
             (%key? .i)
               (progn
                (%print-symbol (make-keyword i.) str info)
                (princ " " str)
                (%late-print ..i str info))
             (with-temporary *print-automatic-newline?* nil
               (%late-print .i str info))))))))

(fn %print-call? (x info)
  (& (print-info-pretty-print? info)
     (cons? x)
     x.
     (symbol? x.)
     (list? .x)
     (| (%get-printer-argument-definition x.)
        (unless (builtin? x.)
          (? (function? (symbol-function x.))
             (function-arguments x.))))))

(fn %print-list (x str info)
  (!? (%print-call? x info)
      (? (function? !)
         (~> ! x str info)
         (%print-call x ! str info))
      (%with-parens str info
        (%late-print x. str info)
        (%print-rest .x str info))))

(fn %print-abbreviation (abbreviation x str info)
  (%with-indentation str info
    (princ .abbreviation. str)
    (%late-print .x. str info)))

(fn %print-cons (x str info)
  (!? (& (cons? .x)
         (not ..x)
         (assoc x. *printer-abbreviations* :test #'eq))
      (%print-abbreviation ! x str info)
      (%print-list x str info)))

(fn %print-string (x str)
  (princ #\" str)
  (@ (i (string-list x))
    (?
      (eql i #\")  (princ "\\\"" str)
      (eql i #\\)  (princ "\\\\" str)
      (princ i str)))
  (princ #\" str))

(fn %print-escaped-symbol (x str)
  (princ #\| str)
  (@ (i (string-list x))
    (?
      (eql i #\|)  (princ "\\|" str)
      (princ i str)))
  (princ #\| str))

(fn symbol-char-needs-escaping? (x)
  (| (eql #\| x)
     (lower-case? x)))

(fn %print-symbol-component (x str)
  (? (some #'symbol-char-needs-escaping? (string-list x))
     (%print-escaped-symbol x str)
     (princ x str)))

(fn abbreviated-package-name (x)
  (? (string== "COMMON-LISP" x)
     "CL"
     x))

(fn %print-symbol-package (name str)
  (%print-symbol-component (abbreviated-package-name name) str))

(fn invisible-package? (x)
  (!= (package-name x)
    (some [string== ! _] *invisible-package-names*)))

(fn invisible-package-name? (x)
  (unless (| (not x)
             (eq t x)
             *always-print-package-names?*)
    (invisible-package? (symbol-package x))))

(fn %print-symbol (x str info)
  (awhen (& x
            (not (eq t x))
            (symbol-package x))
    (unless (invisible-package-name? x)
      (| (keyword? x)
         (%print-symbol-package (package-name !) str))
      (princ #\: str)))
  (%print-symbol-component (symbol-name x) str))

(fn %print-array (x str info)
  (princ "#" str)
  (%print-cons (array-list x) str info))

(fn %print-function (x str info)
  (princ "#'" str)
  (%late-print (. (function-arguments x)
                  (function-body x))
               str info))

(fn %print-character (x str)
  (princ "#\\" str)
  (princ x str))

(fn %late-print (x str info)
  (%with-indentation str info
    (pcase x
      cons?       (%print-cons x str info)
      symbol?     (%print-symbol x str info)
      character?  (%print-character x str)
      number?     (princ x str)
      string?     (%print-string x str)
      array?      (%print-array x str info)
      function?   (%print-function x str info)
      object?     (%print-object x str info)
      json-object? (%print-object x str info)
      (%error "Don't know how to print object."))))

(fn late-print (x &optional (str *standard-output*) &key (print-info (make-print-info)))
  (with-default-stream s str
    (? (& (cons? x)
          (cons? x.))
       (%with-parens s print-info
         (%print-body x s print-info))
       (%late-print x s print-info))
    (& *print-automatic-newline?*
       (not (fresh-line? s))
       (terpri s)))
  x)

(= *definition-printer* #'late-print)

(fn integer-string (x n r)
  (with (f [. (number-digit (mod _ r))
              (unless (== 0 (--! n))
                (f (integer (/ _ r))))])
    (list-string (reverse (f x)))))

(fn print-hex (x n &optional (str *standard-output*))
  (princ (integer-string (integer x) n 16) (default-stream str)))

(fn print-hexbyte (x &optional (str *standard-output*))
  (print-hex x 2 str))

(fn print-hexword (x &optional (str *standard-output*))
  (print-hex x 4 str))

(fn print-hexdword (x &optional (str *standard-output*))
  (print-hex x 8 str))

(fn print-octal (x &optional (str *standard-output*))
  (princ (integer-string x 3 8) (default-stream str)))
