;;;;; tré – Copyright (c) 2009–2013 Sven Michael Klose <pixel@copei.de>

(defvar *builtin-argdefs*
	'((NOT          &rest objects)
      (EQ           &rest objects)
      (EQL          &rest objects)
      (ATOM         &rest objects)
      (SYMBOL?      object)
      (FUNCTION?    object)
      (BUILTIN?     object)
      (MACROP       object)
      (%TYPE-ID     &rest objects) ;object)
      (%%ID         &rest objects) ;object)

      (MOD          &rest x) ;x modulo)
      (SQRT         &rest x) ;x)
      (SIN          &rest x) ;x)
      (COS          &rest x) ;x)
      (ATAN         &rest x) ;x)
      (ATAN2        &rest x) ;a b)
      (EXP          &rest x) ;x)
      (POW          &rest x) ;a b)
      (ROUND        &rest x) ;x)
      (NUMBER+      &rest numbers)
      (INTEGER+     &rest integers)
      (CHARACTER+   &rest characters)
      (NUMBER-      &rest numbers)
      (INTEGER-     &rest integers)
      (CHARACTER-   &rest characters)
      (==           a b)
      (NUMBER==     a b)
      (INTEGER==    a b)
      (CHARACTER==  a b)
      (<            a b)
      (NUMBER<      a b)
      (INTEGER<     a b)
      (CHARACTER<   a b)
      (>            a b)
      (NUMBER>      a b)
      (INTEGER>     a b)
      (CHARACTER>   a b)

      (MAKE-ARRAY   &rest sizes)
      (ARRAY?       object)
      (AREF         array &rest indexes)
      (=-AREF       object array &rest indexes)

      (%ERROR       &rest x) ;message-string)

      (%FOPEN       &rest x) ;path access-mode)

      (NUMBER?      &rest x) ;object)
      (APPLY        &rest x) ;function &rest args)
      (EVAL         &rest x) ;expression)
      (QUIT         &rest x) ;exit-code)
      (LOAD         &rest x) ;path)
      (PRINT        &rest x) ;object)
      (GC)
      (DEBUG)
      (INTERN       &rest x) ;name &optional (package nil))
	  (%MALLOC      &rest x) ;number-of-bytes)
      (%MALLOC-EXEC &rest x) ;number-of-bytes)
      (%FREE        &rest x) ;return-value-of-%malloc)
      (%FREE-EXEC   &rest x) ;return-value-of-%malloc-exec)
	  (%%SET        &rest x) ;address byte-value)
      (%%GET        &rest x) ;address)

      (FUNCTION-NATIVE      function)
      (FUNCTION-BYTECODE    function)
      (=-FUNCTION-BYTECODE  array function)
      (FUNCTION-SOURCE      function)
      (=-FUNCTION-SOURCE    args-and-body function)

      (*                &rest numbers)
      (/                &rest numbers)
      (LOGXOR           &rest x) ;a b)
      (BIT-OR           &rest x) ;a b)
      (BIT-AND          &rest x) ;a b)
      (<<               &rest x) ;x num-bits-to-left)
      (>>               &rest x) ;x num-bits-to-right)
      (CODE-CHAR        &rest x) ;number)
      (INTEGER          &rest x) ;number)
      (CHARACTER?       &rest x) ;object)
      (MAKE-SYMBOL      &rest x) ;name &optional (package nil))
      (MAKE-PACKAGE     &rest x) ;name)
      (SYMBOL-NAME      &rest x) ;symbol)
      (SYMBOL-VALUE     symbol)
      (=-SYMBOL-VALUE   value symbol)
      (%SETQ-ATOM-VALUE     &rest x) ;value symbol)
      (SYMBOL-FUNCTION      symbol)
      (=-SYMBOL-FUNCTION    function symbol)
      (SYMBOL-PACKAGE       &rest x) ;symbol)
      (CONS             a d)
      (LIST             &rest objects)
      (CAR              list)
      (CDR              list)
      (CPR              list)
      (RPLACA           object list)
      (RPLACD           object list)
      (RPLACP           object list)
      (CONS?            object)
      (ELT              &rest x) ;sequence index)
      (%SET-ELT         &rest x) ;object sequence index)
      (LENGTH           &rest x) ;sequence)
      (STRING?          object)
      (MAKE-STRING      &rest x) ;&optional (length nil))
      (STRING==         &rest strings)
      (STRING-CONCAT    &rest strings)
      (STRING           &rest x) ;object)
      (LIST-STRING      &rest x) ;list)
      (MACROEXPAND      &rest x) ;expression)
      (%PRINC           &rest x) ;object stream-handle)
      (%FORCE-OUTPUT    &rest x) ;stream-handle)
      (%READ-CHAR       &rest x) ;stream-handle)
      (%FEOF            &rest x) ;stream-handle)
      (%FCLOSE          &rest x) ;stream-handle)
      (%TERMINAL-RAW)
      (%TERMINAL-NORMAL)
      (END-DEBUG)
      (ALIEN-DLOPEN     &rest x) ;path-to-shared-library)
      (ALIEN-DLCLOSE    &rest x) ;handle)
      (ALIEN-DLSYM      &rest x) ;handle symbol-string)
      (ALIEN-CALL       &rest x) ;address)
      (SYS-IMAGE-CREATE &rest x) ;path)
      (SYS-IMAGE-LOAD   &rest x) ;path)
      (OPEN-SOCKET      &rest x) ;port-number)
      (ACCEPT)
      (RECV)
      (SEND             &rest x) ;string)
      (CLOSE-CONNECTION)
      (CLOSE-SOCKET)))

(defun sanity-check-builtin-argdefs ()
  (alet (carlist *builtin-argdefs*)
    (while ! nil
      (& (member !. .!)
         (error "~A occurs more than once in argument definitions." !.))
      (= ! .!))))

(sanity-check-builtin-argdefs)
