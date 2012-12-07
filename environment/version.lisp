;;;;; tré – Copyright (c) 2009,2011–2012 Sven Michael Klose <pixel@copei.de>

(defvar *tre-revision*
    ,(with-open-file in (open "_current-version" :direction 'input)
       (let l (string-list (read-line in))
         (list-string
           (alet (subseq l
                         (!? (position #\: l)
                             (1+ !)
                             0)
                         (1- (length l)))
             (? (== #\M (car (last !)))
                (butlast !)
                !))))))

(format t "; Revision ~A.~%" *tre-revision*)
