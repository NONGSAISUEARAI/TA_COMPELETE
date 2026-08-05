(defun c:SOLIDINFO (/ ent obj minPt maxPt cen vol)
  (vl-load-com)

  (setq ent (car (entsel "\nSelect 3D Solid: ")))

  (cond
    ((null ent)
     (princ "\nNothing selected.")
    )

    ((/= (cdr (assoc 0 (entget ent))) "3DSOLID")
     (princ "\nSelected object is not a 3DSOLID.")
    )

    (T
     (setq obj (vlax-ename->vla-object ent))

     ;; Bounding box
     (vla-GetBoundingBox obj 'minPt 'maxPt)
     (setq minPt (vlax-safearray->list minPt))
     (setq maxPt (vlax-safearray->list maxPt))

     ;; Volume
     (setq vol (vla-get-Volume obj))

     ;; Centroid
     (setq cen
       (vlax-safearray->list
         (vlax-variant-value
           (vla-get-Centroid obj)
         )
       )
     )

     (princ
       (strcat
         "\nObject type: 3DSOLID"
         "\nMin point: " (vl-princ-to-string minPt)
         "\nMax point: " (vl-princ-to-string maxPt)

         "\nBounding X: "
         (rtos (- (car maxPt) (car minPt)) 2 3)

         "\nBounding Y: "
         (rtos (- (cadr maxPt) (cadr minPt)) 2 3)

         "\nBounding Z: "
         (rtos (- (caddr maxPt) (caddr minPt)) 2 3)

         "\nVolume: "
         (rtos vol 2 3)

         "\nCentroid: "
         (vl-princ-to-string cen)
       )
     )
    )
  )

  (princ)
)