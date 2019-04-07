(fn warn-unused-functions ()
  (!= (defined-functions)
    (@ [hremove ! _]
       (+ (hashkeys (used-functions))
          (hashkeys (expander-macros (transpiler-macro-expander)))
          (hashkeys (expander-macros (codegen-expander)))
          *macros*))
    (!? (mapcan [!= (symbol-name _)
                  (& (not (tail? ! "_TREEXP")
                          (head? ! "~"))
                     (list !))]
           (hashkeys !))
      (warn "Unused functions: ~A." (symbol-names-string !)))))
