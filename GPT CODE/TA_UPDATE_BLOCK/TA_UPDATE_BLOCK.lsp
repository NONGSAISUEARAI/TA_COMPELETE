;;; TA_UPDATE_BLOCK.lsp v1.3 - normalize .NET folder-picker return values
;;; Redefine one block from the current/source DWG in many closed DWG files.
;;; Command: TAUPDATEBLOCK (alias: TAUB)

(vl-load-com)

;; Deployment fallback for APPLOAD by absolute path (not necessarily in Support Path).
;; If installed elsewhere, set *TAUB:install-dir* before calling TAUB.
(if (not (= 'STR (type *TAUB:install-dir*)))
  (setq *TAUB:install-dir*
    "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/GPT CODE/TA_UPDATE_BLOCK"))

(defun TAUB:_function-p (symbol)
  (if (member (type (eval symbol)) '(SUBR USUBR EXRXSUBR)) T nil))

(defun TAUB:_ready-p ()
  (and (TAUB:_function-p 'TA-UPDATE-BLOCK)
       (TAUB:_function-p 'TAUB-PICK-FOLDER)))

(defun TAUB:_dll-path (/ lsp roots root path)
  (setq lsp (findfile "TA_UPDATE_BLOCK.lsp")
        roots (list *TAUB:install-dir* (if lsp (vl-filename-directory lsp))))
  (foreach root roots
    (if (and root (not path))
      (progn
        (setq path (findfile (strcat (vl-string-right-trim "\\/" root)
                                    "/bin/Release/net8.0-windows/TA_UPDATE_BLOCK.dll")))
        (if (not path)
          (setq path (findfile (strcat (vl-string-right-trim "\\/" root) "/TA_UPDATE_BLOCK.dll")))))))
  (if path path (findfile "TA_UPDATE_BLOCK.dll")))

(defun TAUB:LoadDLL (/ dll filedia result)
  (cond
    ((TAUB:_ready-p) T)
    ((not (setq dll (TAUB:_dll-path)))
     (princ "\nTA_UPDATE_BLOCK.dll was not found. Keep the DLL with the LISP or in bin/Release/net8.0-windows.")
     nil)
    (T
     (princ (strcat "\nLoading TA UPDATE BLOCK DLL: " dll))
     (setq filedia (getvar "FILEDIA"))
     (setvar "FILEDIA" 0)
     (setq result (vl-catch-all-apply '(lambda () (vl-cmdf "_.NETLOAD" dll)) nil))
     (setvar "FILEDIA" filedia)
     (cond
       ((TAUB:_ready-p)
        (princ "\nTA UPDATE BLOCK DLL ready (update + Explorer folder picker).")
        T)
       (T
        (if (vl-catch-all-error-p result)
          (princ (strcat "\nNETLOAD failed: " (vl-catch-all-error-message result))))
        (princ "\nDLL is not ready: TA-UPDATE-BLOCK and TAUB-PICK-FOLDER must both be registered.")
        (princ "\nIf an older DLL is already loaded, restart AutoCAD and APPLOAD this LISP again.")
        (princ "\nOtherwise check the NETLOAD error above and the DLL folder in TRUSTEDPATHS.")
        nil)))))

(defun TAUB:_normalize-folder-result (result)
  ;; ResultBuffer containing one value arrives as ("path") or (nil), not a scalar.
  ;; Accept scalar values too, for compatibility with other picker implementations.
  (if (and (listp result) (= 1 (length result)))
    (car result)
    result))

(defun TAUB:_pick-folder (/ initial result)
  ;; Native Explorer folder dialog in the DLL; Cancel returns nil.
  (setq *TAUB:pick-status* 'ERROR)
  (if (TAUB:LoadDLL)
    (progn
      (setq initial (if (and (= 'STR (type *TAUB:folder*))
                             (vl-file-directory-p *TAUB:folder*))
                      *TAUB:folder* (getvar "DWGPREFIX")))
      (setq result
        (vl-catch-all-apply
          '(lambda () (TAUB-PICK-FOLDER initial))
          nil))
      (setq result (TAUB:_normalize-folder-result result))
      (cond
        ((vl-catch-all-error-p result)
         (princ (strcat "\nCannot open folder picker: " (vl-catch-all-error-message result)))
         nil)
        ((null result)
         (setq *TAUB:pick-status* 'CANCEL)
         nil)
        ((and (= 'STR (type result)) (vl-file-directory-p result))
         (setq *TAUB:pick-status* 'OK)
         (setq *TAUB:folder* result))
        ((= 'STR (type result))
         (princ (strcat "\nSelected folder does not exist or is inaccessible: " result))
         nil)
        (T
         (princ (strcat "\nUnexpected folder picker result: " (vl-princ-to-string result)))
         nil)))))

(defun TAUB:_folder-files (folder / item out)
  (foreach item (vl-directory-files folder "*.dwg" 1)
    (setq out (cons (strcat (vl-string-right-trim "\\/" folder) "\\" item) out)))
  (reverse out))

(defun TAUB:_pick-files (/ file out done)
  (while (not done)
    (setq file (getfiled (if out "Add target DWG (Cancel = finish)" "Select target DWG") "" "dwg" 16))
    (if file
      (if (not (member (strcase file) (mapcar 'strcase out))) (setq out (append out (list file))))
      (setq done T)))
  out)

(defun TAUB:_source-block (/ ent obj name)
  (if (setq ent (car (entsel "\nSelect MASTER block reference from the current drawing: ")))
    (progn
      (setq obj (vlax-ename->vla-object ent))
      (if (= "AcDbBlockReference" (vla-get-objectname obj))
        (setq name (if (vlax-property-available-p obj 'EffectiveName)
                     (vla-get-EffectiveName obj) (vla-get-Name obj))))))
  name)

(defun TAUB:_print-result (result / ok fail report)
  (if (and (listp result) (= 3 (length result)))
    (progn
      (setq ok (nth 0 result) fail (nth 1 result) report (nth 2 result))
      (princ (strcat "\n\nTA UPDATE BLOCK: " (itoa ok) " succeeded, " (itoa fail) " failed."))
      (foreach line (TAUB:_split-lines report) (princ (strcat "\n" line))))
    (princ "\nTA UPDATE BLOCK: invalid response from DLL.")))

(defun TAUB:_split-lines (text / pos out)
  (while (setq pos (vl-string-search "\n" text))
    (setq out (cons (substr text 1 pos) out) text (substr text (+ pos 2))))
  (reverse (cons text out)))

(defun TAUB:Run (source block files backup / packed f result)
  ;; Public API. files is a list of full DWG paths; backup is T/nil.
  ;; Catch an unavailable NETLOAD function or invocation error using AutoLISP.
  (if (TAUB:LoadDLL)
    (progn
      (setq packed (if files (car files) ""))
      (foreach f (cdr files) (setq packed (strcat packed "|" f)))
      (setq result
        (vl-catch-all-apply
          '(lambda () (TA-UPDATE-BLOCK source block packed (if backup 1 0)))
          nil))
      (if (vl-catch-all-error-p result)
        (progn
          (princ (strcat "\nCannot call TA-UPDATE-BLOCK: " (vl-catch-all-error-message result)))
          nil)
        (progn (TAUB:_print-result result) result)))))

(defun c:TAUPDATEBLOCK (/ *error* doc source block mode folder files backup)
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*EXIT*")))
      (princ (strcat "\nError: " msg))) (princ))
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object))
        source (vla-get-FullName doc))
  (cond
    ((not (TAUB:LoadDLL)) nil)
    ((or (= "" source) (= 0 (getvar "DWGTITLED")))
     (princ "\nSave the MASTER drawing first."))
    ((not (setq block (TAUB:_source-block)))
     (princ "\nA block reference was not selected."))
    (T
     (initget "Folder Files")
     (setq mode (getkword "\nTargets [Folder/Files] <Folder>: "))
     (if (or (null mode) (= mode "Folder"))
       (if (setq folder (TAUB:_pick-folder))
         (progn
           (princ (strcat "\nTarget folder: " folder))
           (setq files (TAUB:_folder-files folder))
           (if files
             (princ (strcat "\nFound " (itoa (length files)) " DWG file(s)."))
             (princ "\nNo DWG files found in this folder (subfolders are excluded).")))
         (if (= 'CANCEL *TAUB:pick-status*) (princ "\nFolder selection cancelled.")))
       (progn
         (setq files (TAUB:_pick-files))
         (if (null files) (princ "\nFile selection cancelled; no DWG files were selected."))))
     (if files
       (progn
         (initget "Yes No")
         (setq backup (/= "No" (getkword "\nCreate timestamped .bak files? [Yes/No] <Yes>: ")))
         (princ (strcat "\nUpdating block \"" block "\" in " (itoa (length files)) " drawing(s)..."))
         (TAUB:Run source block files backup)))))
  (princ))

(defun c:TAUB () (c:TAUPDATEBLOCK))

(defun c:TAUBFOLDER (/ folder)
  ;; Preview/test the folder picker only. Does not update any drawing.
  (if (setq folder (TAUB:_pick-folder))
    (princ (strcat "\nTarget folder: " folder)))
  (princ))

(princ "\nTA_UPDATE_BLOCK v1.3 loaded (Explorer folder result fix). Commands: TAUPDATEBLOCK / TAUB / TAUBFOLDER")
(princ)
