; tré – Copyright (c) 2008–2015 Sven Michael Klose <pixel@copei.de>

(defun update-section? (section cached-sections)
  (| (member section (sections-to-update))
     (not (assoc section cached-sections))))

(defun map-section (x fun sections cached-sections)
  (with-cons section data x
    (with-temporaries ((current-section)       section
                       (current-section-data)  data)
      (. section
         (? (update-section? section cached-sections)
            (funcall fun section data)
            (assoc-value section cached-sections))))))

(defun map-sections (fun sections cached-sections)
  (@ [map-section _ fun sections cached-sections]
     sections))

(defun codegen (x)
  (backend (middleend x)))

(defun codegen-section (section data)
  (developer-note "Codegen ~A.~%" section)
  (apply #'+ (remove-if #'not (codegen data))))

(defun codegen-sections (sections)
  (alet (map-sections #'codegen-section sections (cached-output-sections))
    (= (cached-output-sections) !)
    (@ #'cdr !)))

(defun quick-compile-sections (x)
  (codegen-sections (frontend-sections x)))

(defun gen-toplevel-function ()
  `((defun accumulated-toplevel ()
      ,@(reverse (accumulated-toplevel-expressions)))))

(defun codegen-delayed-exprs ()
  (with-temporary (sections-to-update) '(delayed-exprs)
    (quick-compile-sections (list (. 'delayed-exprs
                                     (delayed-exprs))))))

(defun codegen-accumulated-toplevels ()
  (& (enabled-pass? :accumulate-toplevel)
     (accumulated-toplevel-expressions)
     (with-temporaries ((sections-to-update) '(accumulated-toplevel))
       (push :accumulate-toplevel (disabled-passes))
       (prog1
         (quick-compile-sections (list (. 'accumulated-toplevel
                                          #'gen-toplevel-function)))
         (pop (disabled-passes))))))

(defun dechunk (x)
  (remove-if #'not (apply #'append x)))

(defun generic-codegen (before-import after-import imports)
  (print-status "Let me think. Hmm...~F")
  (funcall (middleend-init))
  (!? (codegen (@ #'list imports))
      (+! (imports) !))
  (with (before-raw-decls  (codegen-sections before-import)
         after-raw-decls   (append (imports)
                                   (codegen-sections after-import)
                                   (codegen-accumulated-toplevels)
                                   (codegen-delayed-exprs)))
    (funcall (postprocessor) (append (!? (funcall (prologue-gen))
                                         (list !))
                                     (dechunk (append before-raw-decls
                                                     (reverse (raw-decls))
                                                     after-raw-decls))
                                     (!? (funcall (epilogue-gen))
                                         (list !))))))

(defun frontend-section-load (path)
  (print-definition `(load ,path))
  (read-file path))

(defun section-comment (section)
  `((%%comment "Section " ,(? (symbol? section)
                              (symbol-name section)
                              section))))

(defun frontend-section (section data)
  (developer-note "Frontend ~A.~%" section)
  (frontend (@ #'list
               (+ (section-comment section)
                  (pcase section
                    symbol?  (? (function? data)
                                (funcall data)
                                data)
                    string?  (frontend-section-load section)
                    (error "Don't know what to do with section ~A." section))))))

(defun frontend-sections (sections)
  (alet (map-sections #'frontend-section sections (cached-frontend-sections))
    (= (cached-frontend-sections) !)))

(defun generic-frontend (sections)
  (funcall (frontend-init))
  (generic-codegen (frontend-sections (funcall (sections-before-import)))
                   (frontend-sections (+ (funcall (sections-after-import))
                                         sections
                                         (funcall (ending-sections))))
                   (import-from-host)))

(defun tell-number-of-warnings ()
  (alet (length *warnings*)
    (format t "~L; ~A warning~A.~%"
              (? (zero? !) "No" !)
              (? (== 1 !) "" "s"))))

(defun print-transpiler-stats (start-time)
  (& (obfuscate?)
     (print-obfuscations?)
     (print-obfuscations))
  (warn-unused-functions)
  (tell-number-of-warnings)
  (print-status "~A seconds passed.~%~F"
                (integer (/ (- (nanotime) start-time) 1000000000))))

(defun compile-sections (sections &key (transpiler nil))
  (let start-time (nanotime)
    (= *warnings* nil)
    (with-temporaries (*transpiler*  (| transpiler
                                        (copy-transpiler *default-transpiler*))
                       *assert*      (| *assert* (assert?)))
      (& (sections-to-update)
         (clr (emitted-decls)))
      (= (host-functions) (make-host-functions))
      (= (host-variables) (make-host-variables))
      (prog1 (generic-frontend (@ [? (string? _) (list _) _]  sections))
        (print-transpiler-stats start-time)
        (print-status "Phew!~%")))))

(defun compile (expression &key (transpiler nil))
  (compile-sections `((t ,expression)) :transpiler transpiler))
