(env-load "tests/apply.lisp")
(env-load "tests/eq.lisp")
(env-load "tests/backquote.lisp")
(env-load "tests/predicates.lisp")
(env-load "tests/math.lisp")
(env-load "tests/count.lisp")
(env-load "tests/builtins.lisp")
(env-load "tests/stage0.lisp")
(env-load "tests/equal.lisp")
(env-load "tests/nthcdr.lisp")
(env-load "tests/queue.lisp")
(env-load "tests/member.lisp")
(env-load "tests/scope.lisp")
(env-load "tests/lambda.lisp")
(env-load "tests/lexical-scope.lisp" :cl)
(env-load "tests/dollar.lisp")
(env-load "tests/reverse.lisp")
(env-load "tests/nconc.lisp")
(env-load "tests/adjoin.lisp")
(env-load "tests/butlast.lisp")
(env-load "tests/elt.lisp")
(env-load "tests/subseq.lisp")
(env-load "tests/search-sequence.lisp")
(env-load "tests/string.lisp" :cl)
(env-load "tests/empty-stringp.lisp")
(env-load "tests/digit-charp.lisp")
(env-load "tests/hash.lisp")
(env-load "tests/split.lisp")
(env-load "tests/trim.lisp")
(env-load "tests/argument-expand.lisp")

(= *tests* (reverse *tests*))
