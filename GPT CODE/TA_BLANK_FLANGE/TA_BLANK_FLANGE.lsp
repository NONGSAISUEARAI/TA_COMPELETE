;; TA_COMPELETE - blank outline with individually selected folding flanges.
;; Command: TA_BLANK_FLANGE
;; Input: one closed, straight-segment LWPOLYLINE (no arcs).
;; Pick adjacent vertices in either direction and in any edge order.
;; X is the perpendicular developed flange width, in drawing units.
;; Ang1: measured from P1 toward P2, turning toward the outside.
;; Ang2: measured from P2 toward P1, turning toward the outside.
;; Both 45 degrees produce inward mitres; both 90 produce square ends.
;; Each flanged source edge gets its own open bend-line polyline.
;; Unflanged edges do not get bend lines. Bend styling is independent.
;; No material thickness, bend allowance, bend deduction or corner relief
;; is calculated. Supply the required developed width as X.
;; Enter/Done at Point 1 keeps the result; Undo removes the last edit;
;; Esc cancels this run and removes its outline and bend lines. Source is retained.
;; *TA:BF:Width*, *TA:BF:Ang1*, *TA:BF:Ang2* deliberately remain GLOBAL.
;; Remember the last valid input between command runs in this drawing.
;; Do not initialize them on load or add them after / in the command.

;; PRESETTING - edit these values before loading/running the command.
(defun TA:BF:Preset_ ()
  (list
    (cons 'Layer    "TA_BLANK_SIZE")
    (cons 'Color    3)               ; ACI: 3=green, 256=ByLayer
    (cons 'Linetype "Continuous")    ; e.g. "HIDDEN" (must be loadable)
    ;; Bend-line preset (only edges with accepted flanges).
    (cons 'BendLayer    "TA_BEND_LINE")
    (cons 'BendColor    7)           ; ACI: white/black depending on background
    (cons 'BendLinetype "HIDDEN")
    (cons 'BendLinetypeScale 1.0)    ; entity linetype scale
    (cons 'Width    25.0)
    (cons 'Ang1     45.0)            ; degrees, strictly between 0 and 180
    (cons 'Ang2     45.0)
    (cons 'Tolerance 1.0e-7)
  )
)

;; Geometry is calculated in the source entity's OCS, independent of UCS.
(defun TA:BF:Cross_ (a_ b_ c_)
  (-
    (* (- (car b_) (car a_)) (- (cadr c_) (cadr a_)))
    (* (- (cadr b_) (cadr a_)) (- (car c_) (car a_)))
  )
)

(defun TA:BF:Area_ (points_ / origin_ a_ b_ sum_)
  ;; Translate to the first vertex to avoid cancellation at large coordinates.
  (setq origin_ (car points_) a_ (car points_) sum_ 0.0)
  (foreach b_ (append (cdr points_) (list (car points_)))
    (setq sum_ (+ sum_ (TA:BF:Cross_ origin_ a_ b_)) a_ b_)
  )
  (/ sum_ 2.0)
)

(defun TA:BF:On_segment_ (p_ a_ b_ tol_)
  (and
    (<= (abs (TA:BF:Cross_ a_ b_ p_)) (* tol_ (distance a_ b_)))
    (<= (- (min (car a_) (car b_)) tol_) (car p_)
        (+ (max (car a_) (car b_)) tol_))
    (<= (- (min (cadr a_) (cadr b_)) tol_) (cadr p_)
        (+ (max (cadr a_) (cadr b_)) tol_))
  )
)

(defun TA:BF:Segments_hit_ (a_ b_ c_ d_ tol_ / c1_ c2_ c3_ c4_ e1_ e2_)
  (setq c1_ (TA:BF:Cross_ a_ b_ c_)
        c2_ (TA:BF:Cross_ a_ b_ d_)
        c3_ (TA:BF:Cross_ c_ d_ a_)
        c4_ (TA:BF:Cross_ c_ d_ b_)
        e1_ (* tol_ (distance a_ b_))
        e2_ (* tol_ (distance c_ d_)))
  (or
    (and
      (or (and (> c1_ e1_) (< c2_ (- e1_)))
          (and (< c1_ (- e1_)) (> c2_ e1_)))
      (or (and (> c3_ e2_) (< c4_ (- e2_)))
          (and (< c3_ (- e2_)) (> c4_ e2_))))
    (TA:BF:On_segment_ c_ a_ b_ tol_)
    (TA:BF:On_segment_ d_ a_ b_ tol_)
    (TA:BF:On_segment_ a_ c_ d_ tol_)
    (TA:BF:On_segment_ b_ c_ d_ tol_)
  )
)

(defun TA:BF:Simple_polygon_p_ (points_ tol_ / n_ i_ j_ a_ b_ c_ d_ ok_)
  (setq n_ (length points_)
        ok_ (and (>= n_ 3) (> (abs (TA:BF:Area_ points_)) (* tol_ tol_)))
        i_ 0)
  (while (and ok_ (< i_ n_))
    (setq a_ (nth i_ points_)
          b_ (nth (rem (1+ i_) n_) points_)
          c_ (nth (rem (+ i_ 2) n_) points_))
    ;; Reject zero edges and adjacent edges that retrace each other.
    (if (or (<= (distance a_ b_) tol_)
            (TA:BF:On_segment_ c_ a_ b_ tol_)
            (TA:BF:On_segment_ a_ b_ c_ tol_))
      (setq ok_ nil)
    )
    (setq j_ (+ i_ 2))
    (while (and ok_ (< j_ n_))
      (if (not (and (= i_ 0) (= j_ (1- n_))))
        (progn
          (setq c_ (nth j_ points_)
                d_ (nth (rem (1+ j_) n_) points_))
          (if (TA:BF:Segments_hit_ a_ b_ c_ d_ tol_) (setq ok_ nil))
        )
      )
      (setq j_ (1+ j_))
    )
    (setq i_ (1+ i_))
  )
  ok_
)

(defun TA:BF:Vertices_ (entity_ tol_ / points_ item_)
  (foreach item_ (entget entity_)
    (if (= (car item_) 10) (setq points_ (cons (cdr item_) points_)))
  )
  (setq points_ (reverse points_))
  ;; Some closed polylines also repeat the first vertex at the end.
  (if (and (> (length points_) 1) (equal (car points_) (car (last points_)) tol_))
    (setq points_ (reverse (cdr (reverse points_))))
  )
  points_
)

(defun TA:BF:Edge_spec_ (i_ j_ n_ width_ ang1_ ang2_)
  ;; Store settings in source-vertex order, even when clicked backwards.
  (cond
    ((= j_ (rem (1+ i_) n_)) (list i_ width_ ang1_ ang2_))
    ((= i_ (rem (1+ j_) n_)) (list j_ width_ ang2_ ang1_))
  )
)

(defun TA:BF:Flange_ (a_ b_ width_ ang1_ ang2_ side_ tol_
                     / len_ ux_ uy_ nx_ ny_ rad1_ rad2_ run1_ run2_)
  (if (and (> width_ tol_) (< 0.0 ang1_ 180.0) (< 0.0 ang2_ 180.0)
           (> (setq len_ (distance a_ b_)) tol_))
    (progn
      (setq ux_ (/ (- (car b_) (car a_)) len_)
            uy_ (/ (- (cadr b_) (cadr a_)) len_)
            nx_ (* side_ (- uy_))
            ny_ (* side_ ux_)
            rad1_ (* pi (/ ang1_ 180.0))
            rad2_ (* pi (/ ang2_ 180.0))
            run1_ (* width_ (/ (cos rad1_) (sin rad1_)))
            run2_ (* width_ (/ (cos rad2_) (sin rad2_))))
      ;; A negative/zero top span means the end cuts cross or collapse.
      (if (> (- len_ run1_ run2_) tol_)
        (list
          (list (+ (car a_) (* ux_ run1_) (* nx_ width_))
                (+ (cadr a_) (* uy_ run1_) (* ny_ width_)))
          (list (+ (car b_) (- (* ux_ run2_)) (* nx_ width_))
                (+ (cadr b_) (- (* uy_ run2_)) (* ny_ width_)))
        )
      )
    )
  )
)

(defun TA:BF:Contour_ (points_ specs_ tol_ / side_ i_ n_ spec_ cap_ result_ ok_ a_ b_)
  (setq side_ (if (> (TA:BF:Area_ points_) 0.0) -1.0 1.0)
        i_ 0 n_ (length points_) ok_ T)
  (while (and ok_ (< i_ n_))
    (setq a_ (nth i_ points_)
          b_ (nth (rem (1+ i_) n_) points_)
          result_ (cons a_ result_))
    (if (setq spec_ (assoc i_ specs_))
      (if (setq cap_ (TA:BF:Flange_ a_ b_ (nth 1 spec_) (nth 2 spec_)
                                    (nth 3 spec_) side_ tol_))
        (setq result_ (cons (cadr cap_) (cons (car cap_) result_)))
        (setq ok_ nil)
      )
    )
    (setq i_ (1+ i_))
  )
  (if ok_ (reverse result_))
)

(defun TA:BF:Nearest_vertex_ (point_ entity_ points_ / ocs_ elevation_ i_ best_ dist_ d_ p_)
  (setq ocs_ (trans point_ 1 entity_)
        elevation_ (cond ((cdr (assoc 38 (entget entity_)))) (0.0))
        i_ 0)
  (foreach p_ points_
    (setq d_ (distance ocs_ (list (car p_) (cadr p_) elevation_)))
    (if (or (null dist_) (< d_ dist_)) (setq best_ i_ dist_ d_))
    (setq i_ (1+ i_))
  )
  ;; Accept a click near a vertex (12 screen pixels), never an arbitrary point.
  (if (<= dist_ (max 1.0e-6 (* 12.0 (/ (getvar "VIEWSIZE")
                                      (max 1 (cadr (getvar "SCREENSIZE")))))))
    best_
  )
)

(defun TA:BF:Get_real_ (label_ previous_ angle_p_ / value_ ready_)
  (while (not ready_)
    (initget 6)
    (setq value_
      (cond
        ((getreal (strcat "\n" label_ " <" (rtos previous_ 2 3) ">: ")))
        (previous_)
      )
    )
    (if (and angle_p_ (>= value_ 180.0))
      (princ "\nAngle must be greater than 0 and less than 180 degrees.")
      (setq ready_ T)
    )
  )
  value_
)

(defun TA:BF:Ensure_style_ (preset_ / layer_ color_ ltype_ file_ data_)
  (setq layer_ (cdr (assoc 'Layer preset_))
        color_ (cdr (assoc 'Color preset_))
        ltype_ (cdr (assoc 'Linetype preset_)))
  (if (not (tblsearch "LTYPE" ltype_))
    (if (setq file_ (cond ((findfile "acadiso.lin")) ((findfile "acad.lin"))))
      (command-s "_.-LINETYPE" "_Load" ltype_ file_ "")
    )
  )
  (cond
    ((not (tblsearch "LTYPE" ltype_))
      (princ (strcat "\nLinetype not found. Load it first: " ltype_)) nil)
    (T
      (if (not (tblsearch "LAYER" layer_))
        (entmake
          (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord")
                '(100 . "AcDbLayerTableRecord") (cons 2 layer_) '(70 . 0)
                (cons 62 (if (< 0 color_ 256) color_ 7)) (cons 6 ltype_))
        )
      )
      (setq data_ (tblsearch "LAYER" layer_))
      (if (and data_ (= 0 (logand 5 (cdr (assoc 70 data_))))
               (> (cdr (assoc 62 data_)) 0))
        T
        (progn (princ "\nOutput layer must exist, be on, thawed and unlocked.") nil)
      )
    )
  )
)

(defun TA:BF:Bend_preset_ (preset_)
  (list
    (cons 'Layer (cdr (assoc 'BendLayer preset_)))
    (cons 'Color (cdr (assoc 'BendColor preset_)))
    (cons 'Linetype (cdr (assoc 'BendLinetype preset_)))
    (cons 'LinetypeScale (cdr (assoc 'BendLinetypeScale preset_)))
  )
)

(defun TA:BF:Make_polyline_ (source_ points_ preset_ closed_p_ / data_ result_)
  (setq data_ (entget source_))
  ;; entmake supplies ownership; unlike an ownerless entmakex object, this
  ;; polyline is saved with the drawing. Preserve space, plane and elevation.
  (setq result_
    (entmake
      (append
        (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity")
              (cons 67 (cond ((cdr (assoc 67 data_))) (0)))
              (cons 410 (cond ((cdr (assoc 410 data_))) ((getvar "CTAB"))))
              (cons 8 (cdr (assoc 'Layer preset_)))
              (cons 62 (cdr (assoc 'Color preset_)))
              (cons 6 (cdr (assoc 'Linetype preset_)))
              (cons 48 (cond ((cdr (assoc 'LinetypeScale preset_))) (1.0)))
              '(100 . "AcDbPolyline") (cons 90 (length points_))
              (cons 70 (if closed_p_ 1 0)) '(43 . 0.0)
              (cons 38 (cond ((cdr (assoc 38 data_))) (0.0)))
              (cons 210 (cond ((cdr (assoc 210 data_))) ('(0.0 0.0 1.0)))))
        (mapcar '(lambda (p_) (cons 10 p_)) points_)
      )
    )
  )
  (if result_ (entlast))
)

(defun TA:BF:Make_outline_ (source_ points_ preset_)
  (TA:BF:Make_polyline_ source_ points_ preset_ T)
)

(defun TA:BF:Erase_entities_ (entities_ / entity_)
  (foreach entity_ entities_
    ;; entget prevents a repeated entdel from restoring an erased entity.
    (if (and entity_ (entget entity_)) (entdel entity_))
  )
  (princ)
)

(defun TA:BF:Make_result_
  (source_ vertices_ specs_ contour_ preset_
   / outline_ bend_preset_ remaining_ index_ bend_ bends_ failed_)
  ;; Build a complete replacement before the caller erases its previous result.
  ;; Return (outline-ename bend-enames), or nil on failure.
  ;; Empty specs are the valid empty result used when Undo removes the last edge.
  (if (null specs_)
    (list nil nil)
    (progn
      (setq outline_ (vl-catch-all-apply 'TA:BF:Make_outline_
                       (list source_ contour_ preset_)))
      (if (or (null outline_) (vl-catch-all-error-p outline_))
        nil
        (progn
          (setq bend_preset_ (TA:BF:Bend_preset_ preset_)
                remaining_ specs_)
          (while (and remaining_ (not failed_))
            (setq index_ (caar remaining_)
                  bend_
                    (vl-catch-all-apply 'TA:BF:Make_polyline_
                      (list source_
                        (list (nth index_ vertices_)
                              (nth (rem (1+ index_) (length vertices_)) vertices_))
                        bend_preset_ nil)))
            (if (or (null bend_) (vl-catch-all-error-p bend_))
              (setq failed_ T)
              (setq bends_ (cons bend_ bends_))
            )
            (setq remaining_ (cdr remaining_))
          )
          (if failed_
            (progn (TA:BF:Erase_entities_ (cons outline_ bends_)) nil)
            (list outline_ (reverse bends_))
          )
        )
      )
    )
  )
)

(defun c:TA_BLANK_FLANGE
  (/ *error* preset_ tol_ source_ selection_ data_ vertices_ selecting_
     osmode_ cmdecho_ undo_open_ output_ bend_entities_ new_result_ width_ ang1_ ang2_
     history_ specs_ candidate_ spec_ previous_ contour_ point1_ point2_
     i_ j_ running_ DELETE_OBJ_)

  (defun *error* (message_)
    (TA:BF:Erase_entities_ (cons output_ bend_entities_))
    (if new_result_
      (TA:BF:Erase_entities_ (cons (car new_result_) (cadr new_result_))))
    (if source_ (redraw source_ 4))
    (if osmode_ (setvar "OSMODE" osmode_))
    (if cmdecho_ (setvar "CMDECHO" cmdecho_))
    (if undo_open_ (command-s "_.UNDO" "_End"))
    (if (and message_ (not (wcmatch (strcase message_) "*CANCEL*,*QUIT*,*BREAK*")))
      (princ (strcat "\nError: " message_))
      (princ "\nCancelled. Source retained; new outline and bend lines removed.")
    )
    (princ)
  )

  (setq preset_ (TA:BF:Preset_)
        tol_ (cdr (assoc 'Tolerance preset_))
        selecting_ T)
  (while selecting_
    (setq selection_ (entsel "\nSelect closed panel polyline: "))
    (cond
      ((null selection_) (setq selecting_ nil))
      (T
        (setq data_ (entget (car selection_)))
        (cond
          ((/= (cdr (assoc 0 data_)) "LWPOLYLINE")
            (princ "\nSelect a 2D lightweight polyline."))
          ((/= 1 (logand 1 (cdr (assoc 70 data_))))
            (princ "\nThe panel polyline must be closed."))
          ((vl-some '(lambda (d_) (and (= (car d_) 42) (/= (cdr d_) 0.0))) data_)
            (princ "\nCurved edges are not supported. Use straight segments."))
          ((not (TA:BF:Simple_polygon_p_
                   (setq vertices_ (TA:BF:Vertices_ (car selection_) tol_)) tol_))
            (princ "\nPanel boundary is degenerate, overlapping or self-intersecting."))
          (T (setq source_ (car selection_) selecting_ nil))
        )
      )
    )
  )

  (if source_
    (progn
      (setq osmode_ (getvar "OSMODE") cmdecho_ (getvar "CMDECHO"))
      (setvar "CMDECHO" 0)
      (command-s "_.UNDO" "_Begin")
      (setq undo_open_ T)
      (if (and (TA:BF:Ensure_style_ preset_)
               (TA:BF:Ensure_style_ (TA:BF:Bend_preset_ preset_)))
        (progn
          (setvar "OSMODE" 1)
          (redraw source_ 3)
          ;; Use remembered values; Preset is the first-run fallback only.
          (setq width_ (cond (*TA:BF:Width*) ((cdr (assoc 'Width preset_))))
                ang1_ (cond (*TA:BF:Ang1*) ((cdr (assoc 'Ang1 preset_))))
                ang2_ (cond (*TA:BF:Ang2*) ((cdr (assoc 'Ang2 preset_))))
                history_ (list nil) running_ T)
          (princ "\nSelect any edge by its two adjacent vertices. Reverse picking is allowed.")
          (princ "\nX = developed width; Ang1/Ang2 = local end-cut angles in degrees.")
          (while running_
            (initget "Undo Done")
            (setq point1_ (getpoint "\nPoint 1 [Undo/Done] <Done>: "))
            (cond
              ((or (null point1_) (equal point1_ "Done")) (setq running_ nil))
              ((equal point1_ "Undo")
                (if (cdr history_)
                  (progn
                    (setq candidate_ (cadr history_)
                          new_result_ (TA:BF:Make_result_ source_ vertices_ candidate_
                            (TA:BF:Contour_ vertices_ candidate_ tol_) preset_))
                    (if new_result_
                      (progn
                        (TA:BF:Erase_entities_ (cons output_ bend_entities_))
                        (setq output_ (car new_result_) bend_entities_ (cadr new_result_)
                              specs_ candidate_ history_ (cdr history_) new_result_ nil)
                        (princ "\nLast edge edit undone.")
                      )
                      (princ "\nCould not update outline; previous result retained.")
                    )
                  )
                  (princ "\nNo edge edit to undo.")
                ))
              ((null (setq i_ (TA:BF:Nearest_vertex_ point1_ source_ vertices_)))
                (princ "\nPick a vertex of the original panel."))
              (T
                (setq point2_ (getpoint point1_ "\nPoint 2 <cancel this pair>: "))
                (cond
                  ((null point2_) (princ "\nPair cancelled."))
                  ((null (setq j_ (TA:BF:Nearest_vertex_ point2_ source_ vertices_)))
                    (princ "\nPick a vertex of the original panel."))
                  ((null (TA:BF:Edge_spec_ i_ j_ (length vertices_) 1.0 90.0 90.0))
                    (princ "\nThe vertices must bound ONE edge; select each bent segment separately."))
                  (T
                    (princ (strcat "\nVertex " (itoa (1+ i_)) " -> " (itoa (1+ j_))))
                    ;; Save each accepted input immediately, including Enter.
                    ;; Thus a later Esc does not lose earlier entered values.
                    (setq width_ (setq *TA:BF:Width*
                                    (TA:BF:Get_real_ "Flange width X" width_ nil))
                          ang1_ (setq *TA:BF:Ang1*
                                   (TA:BF:Get_real_ "Ang1 (P1 -> P2, toward outside)" ang1_ T))
                          ang2_ (setq *TA:BF:Ang2*
                                   (TA:BF:Get_real_ "Ang2 (P2 -> P1, toward outside)" ang2_ T))
                          spec_ (TA:BF:Edge_spec_ i_ j_ (length vertices_) width_ ang1_ ang2_)
                          previous_ (assoc (car spec_) specs_)
                          candidate_ (if previous_ (subst spec_ previous_ specs_) (cons spec_ specs_))
                          contour_ (TA:BF:Contour_ vertices_ candidate_ tol_))
                    (cond
                      ((null contour_)
                        (princ "\nEnd cuts cross/collapse. Reduce width or adjust angles; edit rejected."))
                      ((not (TA:BF:Simple_polygon_p_ contour_ tol_))
                        (princ "\nOutline crosses/touches itself. Adjust this flange; edit rejected."))
                      ((setq new_result_
                         (TA:BF:Make_result_ source_ vertices_ candidate_ contour_ preset_))
                        (TA:BF:Erase_entities_ (cons output_ bend_entities_))
                        (setq output_ (car new_result_) bend_entities_ (cadr new_result_)
                              specs_ candidate_ history_ (cons specs_ history_) new_result_ nil)
                        (princ "\nOutline and bend lines updated. Pick another pair, or press Enter to finish."))
                      (T (princ "\nCould not create complete result; previous result retained."))
                    )
                  )
                )
              )
            )
          )
        )
      )
      (redraw source_ 4)
      (setvar "OSMODE" osmode_)
      (setvar "CMDECHO" cmdecho_)
      (command-s "_.UNDO" "_End")
      (setq undo_open_ nil)
      (if output_
        (progn
          (entupd output_)
          (princ (strcat "\nClosed blank outline created. Flanged edges: " (itoa (length specs_))
                         "; bend lines: " (itoa (length bend_entities_)))))
        (princ "\nNo blank outline created.")
      )
    )
  )
  (initget "Yes No")
  (setq ss_ ;Detect the variable's result in case of a function error
    (vl-catch-all-apply 
      (function 
        (lambda () 
          (setq DELETE_OBJ_ (not (eq "No" (getkword "\nKeep Existing point with object? [Yes/No] <Y>: "))))
        )
      )
    )
  )
  (if (/= DELETE_OBJ_ T )
    (progn
      (vla-delete (vlax-ename->vla-object selection_))
    )
  )
  (princ)
)

(princ "\nLoaded: TA_BLANK_FLANGE")
(princ)
