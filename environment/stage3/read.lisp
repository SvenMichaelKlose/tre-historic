(fn read-peeked-char (str)
  (prog1 (stream-peeked-char str)
    (= (stream-peeked-char str) nil)))

(fn read-char-0 (str)
  (| (read-peeked-char str)
     (= (stream-last-char str) (~> (stream-fun-in str) str))))

(fn read-char (&optional (str *standard-input*))
  (%track-location (stream-input-location str) (read-char-0 str)))

(fn peek-char (&optional (str *standard-input*))
  (| (stream-peeked-char str)
     (= (stream-peeked-char str) (read-char-0 str))))

(fn read-chars (in num)
  (list-string (@n [read-char in] num)))

(fn read-file (name)
  (with-open-file in-stream (open name :direction 'input)
    (read-all in-stream)))

(fn read-hex (str)
  (with (f [!? (& (peek-char str)
                  (!= (char-upcase (peek-char str))
                    (& (hex-digit? !)
                       !)))
               (progn
                 (read-char str)
                 (f (number+ (* _ 16)
                             (- (char-code !)
                                (? (digit? !)
                                   (char-code #\0)
                                   (- (char-code #\A) 10))))))
               _])
    (| (hex-digit? (peek-char str))
       (error "Illegal character '~A' at begin of hexadecimal number."
              (peek-char str)))
    (prog1
      (f 0)
      (& (symbol-char? (peek-char str))
         (error "Illegal character '~A' in hexadecimal number."
                (peek-char str))))))

(fn read-binary (&optional (in *standard-input*))
  (let n 0
    (while (!? (peek-char in)
               (in? ! #\0 #\1))
           n
      (= n (bit-or (<< n 1) (- (read-byte in) (char-code #\0)))))))

(fn peek-byte (i)
  (!= (peek-char i)
    (& ! (char-code !))))

(fn read-byte (i)
  (!= (read-char i)
    (& ! (char-code !))))

(fn read-word (i)   ; TODO: Flexible endianess.
  (!= (read-byte i)
    (+ (| ! (return))
       (<< (| (read-byte i)
              (return !))
           8))))

(fn read-dword (i)
  (!= (read-word i)
    (+ (| ! (return))
       (<< (| (read-word i)
              (return !))
           16))))

(fn write-byte (x o)
  (princ (code-char x) o))

(fn write-word (x o)
  (write-byte (bit-and x #xff) o)
  (write-byte (>> x 8) o))

(fn write-dword (x o)
  (write-word (bit-and x #xffff) o)
  (write-word (>> x 16) o))

(fn read-byte-string (i num)
  (list-string (@n [read-byte i] num)))

(fn gen-read-array (i reader num)
  (list-array (@n [~> reader i] num)))

(fn read-byte-array (i num)
  (gen-read-array i #'read-byte num))

(fn read-word-array (i num)
  (gen-read-array i #'read-word num))

(fn cr-or-lf? (x)
  (in? (char-code x) 10 13))

(fn read-line (&optional (str *standard-input*))
  (with-default-stream nstr str
    (with-queue q
      (while (!? (peek-char nstr)
                 (not (cr-or-lf? !)))
             (!? (peek-char nstr)
                 (when (cr-or-lf? !)
                   (enqueue q (read-char nstr))
                   (let-when c (peek-char nstr)
                     (& (cr-or-lf? c)
                        (not (character== c !))
                        (enqueue q (read-char nstr))))))
        (enqueue q (read-char nstr)))
      (!? (queue-list q)
          (list-string !)))))

(fn read-all-lines (&optional (str *standard-input*))
  (with-default-stream nstr str
    (with-queue q
      (awhile (read-line nstr)
              (queue-list q)
        (enqueue q !)))))

(fn read-decimal-places-0 (str v s)
  (? (ahead? #'digit? str)
     (read-decimal-places-0 str
                            (+ v (* s (digit-number (read-char str))))
                            (/ s 10))
     v))

(fn read-decimal-places (&optional (str *standard-input*))
  (& (ahead? #'digit? str)
     (read-decimal-places-0 str 0 0.1)))

(fn read-integer-0 (str v)
  (? (ahead? #'digit? str)
     (read-integer-0 str (+ (* v 10) (digit-number (read-char str))))
     v))

(fn read-integer (&optional (str *standard-input*))
  (& (ahead? #'digit? str)
     (integer (read-integer-0 str 0))))

(fn read-number (&optional (str *standard-input*))
  (* (? (ahead? #\- str)
        (prog1 -1 (read-char str))
        1)
     (+ (read-integer str)
        (| (& (ahead? #\. str)
              (read-char str)
              (read-decimal-places str))
           0))))

(fn token-is-quote? (x)
  (in? x :quote :backquote :unquote :unquote-splice))

(fn %read-closing-parens? (x)
  (in? x :parenthesis-close :bracket-close :brace-close))

(fn special-char? (x)
  (in? x #\( #\)
         #\[ #\]
         #\{ #\}
         #\" #\' #\`
         #\, #\: #\;
         #\#))

(fn symbol-char? (x)
  (& x
     (> (char-code x) 32)
     (not (special-char? x))))

(fn ahead? (what str)
  (!= (peek-char str)
    (& (? (function? what)
          (~> what !)
          (eql what !))
       !)))

(fn skip-comment (str)
  (awhen (read-char str)
    (? (== (char-code !) 10)
       (skip-spaces str)
       (skip-comment str))))

(fn skip-spaces (str)
  (when (ahead? #\; str)
    (skip-comment str))
  (when (ahead? #'whitespace? str)
    (read-char str)
    (skip-spaces str)))

(fn seek-char (str)
  (skip-spaces str)
  (peek-char str))

(fn read-symbol (str)
  (with (f [0 & (ahead? #'symbol-char? str)
                (. (read-char str) (f))]
         f2 [0 unless (| (not (peek-char str))
                         (ahead? #\| str))
                 (? (ahead? #\\ str)
                    (progn
                      (read-char str)
                      (. (read-char str) (f2)))
                    (. (read-char str) (f2)))])
    (? (ahead? #\| str)
       (progn
         (read-char str)
         (when (whitespace? (peek-char str))
           (return (… #\|)))
         (prog1 (f2)
           (? (ahead? #\| str)
              (read-char str)
              (error "Expected end of symbol name '|' instead of '~A'."
                     (peek-char str)))))
       (unless (special-char? (seek-char str))
         (filter #'char-upcase (f))))))

(fn read-symbol-and-package (str)
  (!= (read-symbol str)
    (? (ahead? #\: str)
       (progn
         (read-char str)
         (values (| (& ! (list-string !))
                    "KEYWORD")
                 (read-symbol str)))
       (values nil !))))

(fn read-string (str)
  (with (f [0 != (read-char str)
               (unless (eql ! #\")
                 (. (? (eql ! #\\)
                       (read-char str)
                       !)
                    (f)))})
    (list-string (f))))

(fn read-comment-block (str)
  (| (& (eql #\| (read-char str))
        (ahead? #\# str))
    (read-comment-block str)))

(fn list-number? (x)
  (& (| (& .x
           (| (eql #\- x.)
              (eql #\. x.)))
        (digit? x.))
     (? .x
        (every [| (digit? _)
                  (eql #\. _)]
               .x)
        t)))

(fn read-token (str)
  (awhen (read-symbol-and-package str)
    (with ((pkg sym) !)
      (values (? (& sym
                    (not .sym)
                    (eql #\. sym.))
                 :dot
                 (? sym
                    (? (list-number? sym)
                       :number
                       :symbol)
                    (case (read-char str)
                      #\(  :parenthesis-open
                      #\)  :parenthesis-close
                      #\[  :bracket-open
                      #\]  :bracket-close
                      #\{  :brace-open
                      #\}  :brace-close
                      #\'  :quote
                      #\`  :backquote
                      #\"  :dblquote
                      #\,  (? (ahead? #\@ str)
                              (progn
                                (read-char str)
                                :unquote-splice)
                              :unquote)
                      #\#  (case (read-char str)
                             #\\  :char
                             #\x  :hexnum
                             #\'  :function
                             #\(  :array
                             #\|  (read-comment-block str)
                             (error "Reader macro #~A unsupported." !))
                      -1   :eof)))
              (| pkg *package*)
              (list-string sym)))))

(fn read-make-symbol (sym &optional (pkg *package*))
  (| (find-symbol sym pkg)
     (make-symbol sym pkg)))

(fn read-slot-value (x)
  (?
    (not x)
      nil
    .x
      `(slot-value ,(read-slot-value (butlast x))
                   ',(read-make-symbol (car (last x))))
    (string? x.)
      (read-make-symbol x.)
    x.))

(fn read-symbol-or-slot-value (pkg sym)
  (!= (split #\. sym)
    (? (& .! !. (car (last !)))
       (read-slot-value !)
       (read-make-symbol sym pkg))))

(fn read-atom (str token pkg sym)
  (case token :test #'eq
    :dblquote   (read-string str)
    :char       (read-char str)
    :number     (with-stream-string s sym
                  (read-number s))
    :hexnum     (read-hex str)
    :array      (. 'array (read-cons-slot str))
    :function   `(function ,(read-expr str))
    :symbol     (read-symbol-or-slot-value pkg sym)
    (? (%read-closing-parens? token)
       (error "Unexpected closing ~A."
              (case token
                :parenthesis-close  "parenthesis"
                :brace-close        "brace"
                :bracket-close      "bracket"))
       (error "Closing bracket missing."))))

(fn read-quote (str token)
  (… (make-symbol (symbol-name token)) (read-expr str)))

(fn read-cons (str)
  (with (err
           [!= (stream-input-location str)
             (error "~A at line ~A, column ~A in file ~A."
                    _
                    (stream-location-line !)
                    (stream-location-column !)
                    (stream-location-id !))]
         f #'((token pkg sym)
               (unless (%read-closing-parens? token)
                 (. (case token
                      :parenthesis-open  (read-cons-slot str)
                      :bracket-open      (. 'brackets (read-cons-slot str))
                      :brace-open        (. 'braces   (read-cons-slot str))
                      (? (token-is-quote? token)
                         (read-quote str token)
                         (read-atom str token pkg sym)))
                    (!? (read-token str)
                        (with ((token pkg sym) !)
                          (? (eq :dot token)
                             (with (x                (read-expr str)
                                    (token pkg sym)  (read-token str))
                               (| (%read-closing-parens? token)
                                  (err "Only one value allowed after dotted cons"))
                               x)
                             (f token pkg sym)))
                        (err "Closing bracket missing")))))
         (token pkg sym)
           (read-token str))
    (? (eq token :dot)
       (. 'cons (read-cons str))
       (f token pkg sym))))

(fn read-cons-slot (str)
  (!= (read-cons str)
    (? (ahead? #\. str)
       (progn
         (read-char str)
         (with ((token pkg sym) (read-token str))
           (read-slot-value (… ! sym))))
       !)))

(fn read-expr (str)
  (with ((token pkg sym) (read-token str))
    (case token
      nil                nil
      :eof               nil
      :parenthesis-open  (read-cons-slot str)
      :bracket-open      (. 'brackets (read-cons-slot str))
      :brace-open        (. 'braces   (read-cons-slot str))
      (? (token-is-quote? token)
         (read-quote str token)
         (read-atom str token pkg sym)))))

(fn read (&optional (str *standard-input*))
  (& (seek-char str)
     (read-expr str)))

(fn read-all (str)
  (& (seek-char str)
     (. (read str)
        (read-all str))))

(fn read-from-string (x)
  (with-stream-string s x
    (read-all s)))
