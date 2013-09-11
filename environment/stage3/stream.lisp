;;;; tré – Copyright (c) 2005–2006,2010,2012–2013 Sven Michael Klose <pixel@copei.de>

(defvar *default-stream-tabsize* 8)

(defstruct stream-location
  (track?   nil)
  (id       nil)
  (line     1)
  (column   1)
  (tabsize  *default-stream-tabsize*))

(defstruct stream
  (handle nil)

  fun-in
  fun-out
  fun-eof

  (last-char	nil)
  (peeked-char	nil)

  (input-location         (make-stream-location))
  (output-location        (make-stream-location :track? nil))

  (user-detail nil))

(defun next-tabulator-column (column size)
  (++ (* size (++ (integer (/ (-- column) size))))))

(def-stream-location %track-location (stream-location x)
  (when track?
    (? (string? x)
       (adolist ((string-list x))
         (%track-location stream-location !))
       (? (== 10 x)
          (progn
            (= (stream-location-column stream-location) 1)
            (++! (stream-location-line stream-location)))
          (?
            (== 9 x) (= (stream-location-column stream-location) (next-tabulator-column column tabsize))
            (< 31 x) (++! (stream-location-column stream-location))))))
  x)
