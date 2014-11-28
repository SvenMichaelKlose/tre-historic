;;;;; tré – Copyright (c) 2008–2014 Sven Michael Klose <pixel@copei.de>

(defvar *nil-symbol-name* "NIL")
(defvar *t-symbol-name*   "T")

(defun compile-section? (section processed-sections)
  (| (member section (transpiler-sections-to-update *transpiler*))
     (not (assoc section processed-sections))))

(defun accumulated-toplevel? (section)
  (not (eq 'accumulated-toplevel section)))

(defun map-transpiler-sections (fun sections cached-sections)
  (with-queue results
	(dolist (i sections (queue-list results))
      (with-cons section data i
        (with-temporaries ((transpiler-current-section *transpiler*)       section
                           (transpiler-current-section-data *transpiler*)  data)
          (format t "; Working section ~A...~%" section)
          (enqueue results (. section (? (compile-section? section cached-sections)
                                         (funcall fun section data)
                                         (assoc-value section cached-sections)))))))))

(defun codegen-section (section data)
  (with-temporary (transpiler-accumulate-toplevel-expressions? *transpiler*) (not (accumulated-toplevel? section))
    (backend (middleend data))))

(defun generic-compile-2 (sections)
  (alet (map-transpiler-sections #'codegen-section sections (transpiler-compiled-files *transpiler*))
    (= (transpiler-compiled-files *transpiler*) !)
    (cdrlist !)))

(defun generic-load (path)
  (format t "(LOAD \"~A\")~%" path)
  (force-output)
  (frontend (read-file-all path)))

(defun frontend-section (section data)
  (?
    (symbol? section)  (frontend (? (function? data)
                                    (funcall data)
                                    data))
    (string? section)  (generic-load section)
    (error "Don't know what to do with section ~A." section)))

(defun generic-compile-1 (sections)
  (format t "; Front end...~%")
  (alet (map-transpiler-sections #'frontend-section sections (transpiler-frontend-files *transpiler*))
    (= (transpiler-frontend-files *transpiler*) !)))

(defun make-toplevel-function ()
  `((defun accumulated-toplevel ()
      ,@(reverse (transpiler-accumulated-toplevel-expressions *transpiler*)))))

(defun generic-compile-accumulated-toplevels ()
  (format t "; Compiling accumulated top–level expressions...~%")
  (alet *transpiler*
    (& (transpiler-accumulate-toplevel-expressions? !)
       (transpiler-accumulated-toplevel-expressions !)
       (with-temporary (transpiler-sections-to-update !) '(accumulated-toplevel)
	     (backend (middleend (generic-compile-1 (list (. 'accumulated-toplevel
                                                         #'make-toplevel-function)))))))))

(defun tell-number-of-warnings ()
  (alet (length *warnings*)
    (format t "; ~A warning~A.~%"
            (? (zero? !) "No" !)
            (? (== 1 !) "" "s"))))

(def-transpiler generic-codegen (transpiler before-deps deps after-deps)
  (& *show-transpiler-progress?*
     (format t "; Let me think. Hmm...~F"))
  (format t "; Generating code...~%")
  (!? middleend-init (funcall !))
  (with (compiled-before  (generic-compile-2 before-deps)
         compiled-deps    (backend (middleend deps))
         compiled-after   (generic-compile-2 after-deps)
         compiled-acctop  (generic-compile-accumulated-toplevels))
    (!? compiled-deps
        (= (transpiler-imported-deps transpiler) (transpiler-postprocess imported-deps !)))
    (transpiler-postprocess (!? prologue-gen (funcall !))
                            (!? decl-gen (funcall !))
                            compiled-before
                            (reverse (transpiler-raw-decls transpiler))
                            (transpiler-imported-deps transpiler)
                            compiled-after
                            compiled-acctop
                            (!? epilogue-gen (funcall !)))))

(defun generic-import (tr)
  (with-temporary (transpiler-save-argument-defs-only? tr) nil
    (transpiler-import-from-environment tr)))

(def-transpiler generic-compile-0 (transpiler sections)
  (!? frontend-init (funcall !))
  (with (before-deps  (generic-compile-1 (!? sections-before-deps (funcall ! transpiler)))
         after-deps   (generic-compile-1 (+ (!? sections-after-deps (funcall ! transpiler))
                                            sections
                                            (!? ending-sections (funcall ! transpiler))))
         deps         (generic-import transpiler))
    (generic-codegen transpiler before-deps deps after-deps)))

(def-transpiler print-transpiler-stats (transpiler start-time)
  (& obfuscate?
     print-obfuscations?
     (transpiler-print-obfuscations transpiler))
  (warn-unused-functions transpiler)
  (tell-number-of-warnings)
  (& *show-transpiler-progress?*
     (format t "; ~A seconds passed.~%~F" (integer (/ (- (nanotime) start-time) 1000000000)))))

(def-transpiler generic-compile (transpiler sections)
  (let start-time (nanotime)
    (= *warnings* nil)
    (with-temporaries (*recompiling?*  (& sections-to-update t)
                       *transpiler*    transpiler
                       *assert*        (| *assert* assert?))
      (& *have-compiler?*
         (= (transpiler-save-sources? transpiler) t))
      (& sections-to-update
         (clr (transpiler-emitted-decls transpiler)))
      (= (transpiler-host-functions-hash transpiler) (make-host-functions-hash))
      (= (transpiler-host-variables-hash transpiler) (make-host-variables-hash))
      (prog1
        (generic-compile-0 transpiler sections)
        (print-transpiler-stats transpiler start-time)
        (& *show-transpiler-progress?*
           (format t "; Phew!~%"))))))
