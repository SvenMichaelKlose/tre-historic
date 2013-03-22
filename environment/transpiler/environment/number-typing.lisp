;;;;; tré – Copyright (c) 2008–2013 Sven Michael Klose <pixel@copei.de>

(defmacro + (&rest x)
  (opt-string-concat x '+))

;(defmacro def-typed-transpiler-op (name)
;  `(defmacro ,name (&rest x)
;  	 (?
;	   (some #'string? x)
;         `(,($ 'string name) ,,@x)
;	   (some #'integer? x)
;         `(,($ 'integer name) ,,@(filter [? (integer? _)
;                                            _
;                                            `(%wrap-char-number ,,_)]
;                                         x))
;       `(,name ,,@x))))
;
;(def-typed-transpiler-op -)
;(def-typed-transpiler-op ==)
;(def-typed-transpiler-op <)
;(def-typed-transpiler-op >)
;(def-typed-transpiler-op <=)
;(def-typed-transpiler-op >=)

(defmacro def-transpiler-char-op-inliner (name)
  (with (charname ($ 'character name)
         op		  ($ '%%% name))
    `(progn
       (defmacro ,charname (&rest x)
         (? (== 2 (length x))
            `(,op (slot-value ,,x. 'v)
                  (slot-value ,,.x. 'v))
            `(,charname ,,@x)))
       (defmacro ,($ 'integer name) (&rest x)
		 `(,op ,,@x)))))

;(def-transpiler-char-op-inliner ==)
;(def-transpiler-char-op-inliner <)
;(def-transpiler-char-op-inliner >)
;(def-transpiler-char-op-inliner <=)
;(def-transpiler-char-op-inliner >=)

(defmacro character+ (&rest x)
  (? (== 2 (length x))
     `(code-char (%%%+ (slot-value ,x. 'v)
                       (slot-value ,.x. 'v)))
     `(character+ ,@x)))

(defmacro character- (&rest x)
  `(code-char ,(? (== 1 (length x))
                  `(%transpiler-native "(-" (slot-value ,x. 'v) ")")
                  `(%%%- ,@(mapcar [? (integer? _)
                                       _
                                       `(slot-value ,_ 'v)]
                                   x)))))

(defmacro integer- (&rest x)
  (? (== 1 (length x))
     `(%transpiler-native "(-" ,x. ")")
     `(%%%- ,@x)))

(defmacro integer1+ (x)
  `(%%%+ ,x 1))

(defmacro integer1- (x)
  `(%%%- ,x 1))

(defmacro def-integer-op (op)
  `(defmacro ,($ 'integer op) (&rest x)
     `(,($ '%%% op) ,,@x)))

(def-integer-op +)
(def-integer-op ==)
(def-integer-op <)
(def-integer-op >)
(def-integer-op <=)
(def-integer-op >=)
