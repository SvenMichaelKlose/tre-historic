;;;;; tré – Copyright (c) 2008–2009,2011–2013 Sven Michael Klose <pixel@copei.de>

(defun transpiler-translate-symbol (tr from to)
  (acons! from to (transpiler-symbol-translations tr)))

(defun transpiler-special-char? (tr x)
  (not (funcall (transpiler-identifier-char? tr) x)))

(defun global-variable-notation? (x)
  (let l (length x)
    (& (< 2 l)
       (== (elt x 0) #\*)
       (== (elt x (-- l)) #\*))))

(defun transpiler-symbol-string-r (tr s)
  (with (encapsulate-char
		   [string-list (string-concat "T" (format nil "~A" (char-code _)))]
				
		 convert-camel
		   #'((x pos)
                (& x
			       (let c (char-downcase x.)
			         (? (& .x (| (character== #\- c)
                                 (& (== 0 pos)
                                    (character== #\* c))))
                        (? (& (character== #\- c)
                              (not (alphanumeric? .x.)))
                           (+ (string-list "T45")
                              (convert-camel .x (++ pos)))
					       (cons (char-upcase (cadr x))
						         (convert-camel ..x (++ pos))))
					    (cons c (convert-camel .x (++ pos)))))))

         convert-special2
           [& _
              (? (transpiler-special-char? tr _.)
                 (+ (encapsulate-char _.)
                    (convert-special2 ._))
                 (cons _. (convert-special2 ._)))]

		 convert-special
           [& _
              (? (digit-char? _.)
                 (+ (encapsulate-char _.)
                    (convert-special2 ._))
                 (convert-special2 _))]
         convert-global
           [remove-if [== _ #\-]
                      (string-list (string-upcase (subseq _ 1 (-- (length _)))))])
	(? (| (string? s) (number? s))
	   (string s)
       (list-string
           (let str (symbol-name s)
	         (convert-special (? (global-variable-notation? str)
                                 (convert-global str)
    	                         (convert-camel (string-list str) 0))))))))

(defun transpiler-symbol-string-1 (tr s)
  (!? (symbol-package s)
      (transpiler-symbol-string-r tr (make-symbol (string-concat (symbol-name !) ":" (symbol-name s))))
      (transpiler-symbol-string-r tr s)))

(defun transpiler-dot-symbol-string (tr sl)
  (apply #'string-concat (pad (filter [transpiler-symbol-string-0 tr (make-symbol (list-string _))]
		                              (split #\. sl))
                              ".")))

(defun transpiler-symbol-string-0 (tr s)
  (let sl (string-list (symbol-name s))
    (? (position #\. sl)
	   (transpiler-dot-symbol-string tr sl)
	   (transpiler-symbol-string-1 tr s))))

(defun transpiler-symbol-string (tr s)
  (| (href (transpiler-identifiers tr) s)
     (let n (transpiler-symbol-string-0 tr s)
       (awhen (href (transpiler-converted-identifiers tr) n)
         (error "Identifier conversion clash. Symbols ~A and ~A are both converted to ~A."
                (symbol-name s) (symbol-name !) (symbol-name n)))
       (= (href (transpiler-identifiers tr) s) n)
       (= (href (transpiler-converted-identifiers tr) n) s)
       n)))

(defun current-transpiler-symbol-string (s)
  (transpiler-symbol-string *transpiler* s))

(defun transpiler-to-string-cons (tr x)
  (?
    (%%string? x) (funcall (transpiler-gen-string tr) .x.)
    (%%native? x) (transpiler-to-string tr .x)
    x))

(defun transpiler-to-string (tr x)
  (maptree [?
             (cons? _)    (transpiler-to-string-cons tr _)
             (string? _)  _
             (symbol? _)  (| (assoc-value _ (transpiler-symbol-translations tr) :test #'eq)
                             (transpiler-symbol-string tr _))
             (number? _)  (princ _ nil)
             (error "Cannot translate ~A to string." _)]
           x))
