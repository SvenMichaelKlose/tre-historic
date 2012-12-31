;;;;; tré – Copyright (c) 2009–2012 Sven Michael Klose <pixel@copei.de>

(defvar *builtins*
	'(APPLY EVAL
      QUIT LOAD %MACROCALL PRINT GC DEBUG INTERN
	  %MALLOC %MALLOC-EXEC %FREE %FREE-EXEC
	  %%SET %%GET
      %ERROR
      NUMBER+ NUMBER- INTEGER+ INTEGER- CHARACTER+ CHARACTER-
      * / MOD LOGXOR NUMBER?
      == < > NUMBER== NUMBER< NUMBER> INTEGER== INTEGER< INTEGER> CHARACTER== CHARACTER< CHARACTER>
      BIT-OR BIT-AND << >> CODE-CHAR INTEGER CHARACTER?
      EQ EQL MAKE-SYMBOL MAKE-PACKAGE ATOM %TYPE-ID %%ID
      SYMBOL-NAME SYMBOL-VALUE %SETQ-ATOM-VALUE
      SYMBOL-FUNCTION %%U=-SYMBOL-FUNCTION SYMBOL-PACKAGE
      FUNCTION? BUILTIN? MACROP %ATOM-LIST
      NOT CONS LIST CAR CDR RPLACA RPLACD CONS?
      ASSOC MEMBER
      ELT %SET-ELT LENGTH
      STRING? MAKE-STRING STRING== STRING-CONCAT STRING LIST-STRING
      MAKE-ARRAY ARRAY? AREF %%U=-AREF
      MACROEXPAND-1 MACROEXPAND
      %PRINC %FORCE-OUTPUT %READ-CHAR %FOPEN %FEOF %FCLOSE %TERMINAL-RAW %TERMINAL-NORMAL
      END-DEBUG
      ALIEN-DLOPEN ALIEN-DLCLOSE ALIEN-DLSYM ALIEN-CALL
      SYS-IMAGE-CREATE SYS-IMAGE-LOAD
      OPEN-SOCKET ACCEPT RECV SEND CLOSE-CONNECTION CLOSE-SOCKET))

(defvar *specials*
    '(%SET-ATOM-FUN))
