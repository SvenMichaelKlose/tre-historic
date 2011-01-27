;;;;; TRE transpiler environment
;;;;; Copyright (c) 2008-2011 Sven Klose <pixel@copei.de>

(defun maparray (fun hash)
  (dotimes (i (length hash))
    (funcall fun (aref hash i))))

(defun maphash (fun hash)
  (dolist (i (%property-list hash))
    (funcall fun i. .i)))

(defun elt (seq idx)
  (if
    (string? seq)
	  (%elt-string seq idx)
    (consp seq)
	  (nth idx seq)
  	(aref seq idx)))

(defun (setf elt) (val seq idx)
  (if
	(string? seq)
	  (error "strings cannot be modified")
	(arrayp seq)
  	  (setf (aref seq idx) val)
	(consp seq)
	  (rplaca (nthcdr idx seq) val)))
