;;;;; tré – Copyright (c) 2014 Sven Michael Klose <pixel@copei.de>

(proclaim '(optimize (speed 3) (space 0) (safety 3) (debug 3)))

(load "cl/init.lisp")
(load "cl/core.lisp")
(load "cl/user.lisp")

(in-package :tre)

(env-load "stage0/main.lisp")
(env-load "main.lisp") 
