(= *have-environment-tests* t)

(unix-sh-mkdir "compiled" :parents t)
(make-project "PHP target test"
              `((toplevel . ((environment-tests))))
              :transpiler  *php-transpiler*
              :emitter     [put-file "compiled/test.php" _])
(quit)
