;;;;; tré – Copyright (c) 2005–2008,2010,2012–2013 Sven Michael Klose <pixel@copei.de>

(defun fresh-line? (&optional (str *standard-output*))
  "Test if stream is at the beginning of a line."
  (== (stream-last-char str) (code-char 10)))

(defun read-char-0 (str)
  "Read character from stream."
  (?
    (stream-peeked-char str)
      (prog1
        (stream-peeked-char str)
        (= (stream-peeked-char str) nil))
    (not (end-of-file str))
      (= (stream-last-char str) (funcall (stream-fun-in str) str))))

(defun read-char (&optional (str *standard-input*))
  (%stream-track-input-location str (read-char-0 str)))

(defun peek-char (&optional (str *standard-input*))
  "Read character without stepping to next."
  (| (stream-peeked-char str)
     (= (stream-peeked-char str) (read-char-0 str))))

(defun end-of-file (&optional (str *standard-input*))
  "Test if stream is at file end."
  (& (stream-fun-eof str)
     (funcall (stream-fun-eof str) str)))
