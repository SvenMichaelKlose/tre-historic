(fn make-json-object (&rest x)
  (!= (%make-json-object)
    (@ (i (group x 2) !)
      (=-%aref .i. ! (? (symbol? i.)
                        (list-string (camel-notation (string-list (symbol-name i.))))
                        i.)))))
