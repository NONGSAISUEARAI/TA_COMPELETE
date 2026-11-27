;;; 3D_UNFOLD.lsp
;;; User-facing AutoLISP command; B-Rep analysis is implemented by the
;;; companion AutoCAD 2026 .NET DLL.

(vl-load-com)

(defun TA3DU:ResolveFolder (/ source)
  (setq source
    (cond
      ((and (boundp '*load-truename*) *load-truename*)
        *load-truename*)
      ((findfile "3D_UNFOLD.lsp"))
      (T nil)))
  (if source
    (vl-filename-directory source)
    (vl-string-right-trim "\\/" (getvar "DWGPREFIX")))
)

(setq *TA3DU:Folder* (TA3DU:ResolveFolder))

(defun TA3DU:FirstExistingFile (paths / path found)
  (foreach path paths
    (if (and (null found) path (vl-file-size path))
      (setq found path)))
  found
)

(defun TA3DU:LoadDll (/ beside built support dll result)
  (setq beside (strcat *TA3DU:Folder* "\\TA_3D_UNFOLD.dll")
        built   (strcat *TA3DU:Folder* "\\bin\\Release\\net8.0-windows\\TA_3D_UNFOLD.dll")
        support (findfile "TA_3D_UNFOLD.dll")
        dll     (TA3DU:FirstExistingFile (list beside built support)))
  (cond
    ((null dll)
      (princ
        (strcat
          "\nTA3DUNFOLD DLL was not found."
          "\nLISP folder: " *TA3DU:Folder*
          "\nExpected DLL beside LISP: " beside
          "\nOr build output: " built))
      nil)
    (T
      (setq result (vl-catch-all-apply 'command-s (list "_.NETLOAD" dll)))
      (if (vl-catch-all-error-p result)
        (progn
          (princ (strcat "\nCannot load TA_3D_UNFOLD.dll: " (vl-catch-all-error-message result)))
          nil)
        T)))
)

(defun c:TA3DUNFOLD ()
  (if (TA3DU:LoadDll)
    (command "TA3DUNFOLDDLL"))
  (princ)
)

(defun c:TA3DINSPECT ()
  (if (TA3DU:LoadDll)
    (command "TA3DINSPECT"))
  (princ)
)

(defun c:SOLIDINFO (/ ent obj minPt maxPt cen vol)
  (setq ent (car (entsel "\nSelect 3D Solid: ")))
  (cond
    ((null ent) (princ "\nNothing selected."))
    ((/= (cdr (assoc 0 (entget ent))) "3DSOLID")
      (princ "\nSelected object is not a 3DSOLID."))
    (T
      (setq obj (vlax-ename->vla-object ent))
      (vla-GetBoundingBox obj 'minPt 'maxPt)
      (setq minPt (vlax-safearray->list minPt)
            maxPt (vlax-safearray->list maxPt)
            vol (vla-get-Volume obj)
            cen (vlax-safearray->list (vlax-variant-value (vla-get-Centroid obj))))
      (princ
        (strcat "\nObject type: 3DSOLID"
                "\nMin point: " (vl-princ-to-string minPt)
                "\nMax point: " (vl-princ-to-string maxPt)
                "\nBounding X: " (rtos (- (car maxPt) (car minPt)) 2 3)
                "\nBounding Y: " (rtos (- (cadr maxPt) (cadr minPt)) 2 3)
                "\nBounding Z: " (rtos (- (caddr maxPt) (caddr minPt)) 2 3)
                "\nVolume: " (rtos vol 2 3)
                "\nCentroid: " (vl-princ-to-string cen)))))
  (princ)
)

(princ "\n3D_UNFOLD loaded. Commands: TA3DUNFOLD / TA3DINSPECT / SOLIDINFO")
(princ)
