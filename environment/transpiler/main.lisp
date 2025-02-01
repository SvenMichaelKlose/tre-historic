(env-load "transpiler/print.lisp")

(env-load "transpiler/transpiler.lisp")

(env-load "transpiler/funinfo/funinfo.lisp")
(env-load "transpiler/funinfo/environment.lisp")
(env-load "transpiler/funinfo/lexical.lisp")
(env-load "transpiler/funinfo/local-function-args.lisp")
(env-load "transpiler/funinfo/types.lisp")
(env-load "transpiler/funinfo/debug-printers.lisp")

(env-load "transpiler/lambda.lisp")
(env-load "transpiler/quote.lisp")
(env-load "transpiler/tag.lisp")

(env-load "transpiler/simple-argument-list-p.lisp")
(env-load "transpiler/argument-expander.lisp")

(env-load "transpiler/metacode/assignment.lisp")
(env-load "transpiler/metacode/predicates.lisp")
(env-load "transpiler/metacode/walker.lisp")

(env-load "transpiler/end.lisp")
(env-load "transpiler/back-end/main.lisp")
(env-load "transpiler/middle-end/main.lisp")
(env-load "transpiler/front-end/main.lisp")
(env-load "transpiler/warn-unused-functions.lisp")
(env-load "transpiler/tests.lisp")
(env-load "transpiler/import.lisp")
(env-load "transpiler/compile.lisp")
(env-load "transpiler/targets/main.lisp")
;(env-load "transpiler/eval.lisp")
(env-load "transpiler/make-project.lisp" :cl)
