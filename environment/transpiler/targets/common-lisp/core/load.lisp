(fn %load-r (s)
  (when (peek-char s)
    (. (read s)
       (%load-r s))))

(fn %expand (x)
  (!= (unquote-expand (macroexpand (dot-expand x)))
    (? (equal x !)
       x
       (%expand !))))

(var *load* nil)

(defbuiltin load (file-specifier)
  (print-definition `(load ,file-specifier))
  (with-temporary *load* file-specifier
    (@ (i (with-input-file s file-specifier
            (%load-r s)))
      (eval (%expand i)))))
