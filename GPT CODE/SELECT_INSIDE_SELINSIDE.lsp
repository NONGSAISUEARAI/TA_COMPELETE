; SELECT_INSIDE_SELINSIDE.lsp
; Select all objects inside or crossing a closed LWPOLYLINE boundary.
; Load: (load "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/GPT CODE/SELECT_INSIDE_SELINSIDE.lsp")
; Run: SELECT_INSIDE_SELINSIDE

(defun TA:select_inside_get_vertices (pl_ename_ / pl_entget_ pl_point_list_)
  (setq pl_entget_ (entget pl_ename_))
  (if (and (= (cdr (assoc 0 pl_entget_)) "LWPOLYLINE")
           (= 1 (logand 1 (cdr (assoc 70 pl_entget_)))))
    (progn
      (setq pl_point_list_
        (mapcar
          '(lambda (item_)
             (trans (cdr item_) pl_ename_ 1)
           )
          (vl-remove-if-not
            '(lambda (item_) (= (car item_) 10))
            pl_entget_
          )
        )
      )
      (if (>= (length pl_point_list_) 3) pl_point_list_)
    )
  )
)

; pl_ename_ = closed LWPOLYLINE ename
; filter_   = ssget DXF filter, e.g. '((0 . "CIRCLE")); nil = all types
; Returns a selection set or nil. CP includes crossing objects.
(defun TA:select_inside_boundary (pl_ename_ filter_ / pl_point_list_)
  (if (setq pl_point_list_ (TA:select_inside_get_vertices pl_ename_))
    (ssget "_CP" pl_point_list_ filter_)
  )
)

(defun c:select_inside_selinside (/ pl_ename_ ss_pre_filter_set_xx_)
  (setq pl_ename_ (car (entsel "\nSelect closed LWPOLYLINE boundary: ")))
  (cond
    ((null pl_ename_)
      (princ "\nNo boundary selected.")
    )
    ((null (TA:select_inside_get_vertices pl_ename_))
      (princ "\nBoundary must be a closed LWPOLYLINE with at least 3 vertices.")
    )
    ((setq ss_pre_filter_set_xx_
            (TA:select_inside_boundary
              pl_ename_
              (list
                ; (cons 0 "INSERT") ;type of object
                ; (cons 8 "0")      ;kind of layer
                ; (cons 2 "BLOCK")  ;kind of nameblock
                ; (cons 62 1)       ;kind of color
              )
            ))
      (if (ssmemb pl_ename_ ss_pre_filter_set_xx_)
        (ssdel pl_ename_ ss_pre_filter_set_xx_)
      )
      (if (> (sslength ss_pre_filter_set_xx_) 0)
        (progn
          (sssetfirst nil ss_pre_filter_set_xx_)
          (princ (strcat "\nSelected " (itoa (sslength ss_pre_filter_set_xx_)) " object(s)."))
        )
        (princ "\nNo objects found in or crossing the boundary.")
      )
    )
    (T
      (princ "\nNo objects found in or crossing the boundary.")
    )
  )
  (princ)
)

(princ "\nLoaded SELECT_INSIDE_SELINSIDE. Run SELECT_INSIDE_SELINSIDE.")
(princ)
