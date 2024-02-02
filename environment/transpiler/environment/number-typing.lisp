(defmacro + (&rest x)       (opt-+ x))
(defmacro - (&rest x)       `(%- ,@x))
(defmacro * (&rest x)       `(%* ,@x))
(defmacro / (&rest x)       `(%/ ,@x))
(defmacro mod (&rest x)     `(%mod ,@x))
(defmacro number+ (&rest x) `(%+ ,@x))

(defmacro == (a b) `(%== ,a ,b))
(defmacro < (a b)  `(%< ,a ,b))
(defmacro > (a b)  `(%> ,a ,b))
(defmacro <= (a b) `(%<= ,a ,b))
(defmacro >= (a b) `(%>= ,a ,b))

(defmacro << (a b)      `(%<< ,a ,b))
(defmacro >> (a b)      `(%>> ,a ,b))
(defmacro bit-or (a b)  `(%bit-or ,a ,b))
(defmacro bit-and (a b) `(%bit-and ,a ,b))
