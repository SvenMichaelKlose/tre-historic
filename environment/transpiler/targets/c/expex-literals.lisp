;;;;; TRE transpiler
;;;;; Copyright (c) 2009 Sven Klose <pixel@copei.de>

(defun c-make-decl (name)
  (format nil "treptr ~A;~%"
  	      (transpiler-symbol-string *current-transpiler* name)))

;;;;; Make declarations, initialisations and references to literals.

(defmacro c-define-compiled-literal (name (x table) &key maker setter)
  `(define-compiled-literal ,name (,x ,table)
	   :maker ,maker
	   :setter ,setter
	   :decl-maker #'c-make-decl))

(c-define-compiled-literal c-compiled-number (x number)
  :maker ($ 'trenumber_compiled_ (gensym-number))
  :setter (trenumber_get (%transpiler-native ,x)))

(c-define-compiled-literal c-compiled-char (x char)
  :maker ($ 'trechar_compiled_ (char-code x))
  :setter (trechar_get (%transpiler-native ,(char-code x))))

(c-define-compiled-literal c-compiled-string (x string)
  :maker ($ 'trestring_compiled_ (gensym-number))
  :setter (trestring_get
			  (%transpiler-native
				  (%transpiler-string ,x))))

(c-define-compiled-literal c-compiled-symbol (x symbol)
  :maker ($ 'tresymbol_compiled_ x (if (keywordp x)
	     						'_keyword
		 						""))
  :setter (treatom_get
			  (%transpiler-native
				  (%transpiler-string ,(symbol-name x)))
			   ,(if (keywordp x)
				    'tre_package_keyword
				    'treptr_nil)))

;; An EXPEX-ARGUMENT-FILTER.
;; Just a type dispatcher.
(defun c-expex-literal (x)
  (if
    (characterp x)
      (c-compiled-char x)
    (numberp x)
	  (c-compiled-number x)
    (stringp x)
	  (c-compiled-string x)
	(atom x)
	  (if *expex-funinfo*
 	      (if
			(funinfo-arg? *expex-funinfo* x)
		      x
			(expex-funinfo-defined-variable? x)
	  	  	  `(treatom_get_value ,(c-compiled-symbol x))
			x)
		x)
    (transpiler-import-from-expex x)))
