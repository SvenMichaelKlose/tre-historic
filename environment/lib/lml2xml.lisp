;;;;; TRE environment
;;;;; Copyright (c) 2007-2009,2011 Sven Klose <pixel@copei.de>
;;;;;
;;;;; LML-to-XML conversion

(def-head-predicate %exec)

(defun lml-attr? (x)
  (and (consp x) (consp .x)
       (atom x.)
	   (keywordp x.)
	   (or (atom .x.)
		   (%exec? .x.))))

(defun lml-body (x)
  (when x
	(? (lml-attr? x)
	   (lml-body ..x)
	   x)))

(defun lml2xml-end (s)
  (princ ">" s))

(defun lml2xml-end-inline (s)
  (princ "/>" s))

(defun lml2xml-open (s x)
  (princ (string-concat "<" (lml-attr-string x.)) s))

(defun lml2xml-close (s x)
  (princ (string-concat "</" (lml-attr-string x.) ">") s))

(defun lml2xml-atom (s x)
  (princ x s))

(defun lml2xml-attr (s x)
  (princ (string-concat " "
			            (lml-attr-string x.)
                        "=\""
			            (? (string? .x.)
                           .x.
				           (lml-attr-string .x.))
                        "\"")
         s)
  (lml2xml-attr-or-body s ..x))

(defun lml2xml-body (s x)
  (lml2xml-end s)
  (mapcar (fn lml2xml-0 s _) x))

(defun lml2xml-attr-or-body (s x)
  (when x
    (? (lml-attr? x)
       (lml2xml-attr s x)
       (lml2xml-body s x))))

(defun lml2xml-block (s x)
  (lml2xml-attr-or-body s .x)
  (lml2xml-close s x))

(defun lml2xml-inline (s x)
  (lml2xml-attr-or-body s .x)
  (lml2xml-end-inline s))

(defun lml2xml-error-tagname (x)
  (error "First element is not a tag name: ~A" x))

(defun lml2xml-expr (s x)
  (unless (atom x.)
    (lml2xml-error-tagname x))
  (lml2xml-open s x)
  (? (lml-body .x)
     (lml2xml-block s x)
     (lml2xml-inline s x)))

(defun lml2xml-0 (s x)
  (when x
    (? (consp x)
	   (lml2xml-expr s x)
	   (lml2xml-atom s x))))

(defun lml2xml (x &optional (str nil))
  (with-default-stream s str
	(lml2xml-0 s x)))
