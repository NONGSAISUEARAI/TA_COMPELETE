;; TA_COMPELETE - blank outline with individually selected folding flanges.
;; Commands: FF1 (outside), FF2 (inside).
;; Input: one closed, straight-segment LWPOLYLINE (no arcs).
;; FF1: pick any two points on ONE original straight edge, in either direction.
;; FF2: pick adjacent vertices. Both commands allow any edge order.
;; FF1 keeps one editable flange range per original edge; repicking replaces it.
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
  (if (and (> (length points_) 1) (equal (car points_) (last points_) tol_))
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

(defun TA:BF:Lerp_ (a_ b_ t_)
  (mapcar '(lambda (x_ y_) (+ x_ (* t_ (- y_ x_)))) a_ b_)
)

(defun TA:BF:Edge_points_ (points_ spec_ / i_ a_ b_ t1_ t2_)
  ;; Optional range parameters preserve compatibility with full-edge specs.
  ;; Spec = (edge-index width angle-at-start angle-at-end [t-start t-end]).
  (setq i_ (car spec_))
  (if (and (eq (type i_) 'INT) (<= 0 i_) (< i_ (length points_)))
    (progn
      (setq a_ (nth i_ points_))
      (setq b_ (nth (rem (1+ i_) (length points_)) points_))
      (setq t1_ (cond ((nth 4 spec_)) (0.0)))
      (setq t2_ (cond ((nth 5 spec_)) (1.0)))
      (list (TA:BF:Lerp_ a_ b_ t1_) (TA:BF:Lerp_ a_ b_ t2_))
    )
  )
)

(defun TA:BF:Point_on_edges_
  (point_ entity_ points_ tol_ / ocs_ elevation_ radius_ i_ a_ b_ dx_ dy_ len2_ t_ p_ d_ result_)
  ;; Keep both incident edges at a vertex until Point 2 resolves the edge.
  (setq ocs_ (trans point_ 1 entity_))
  (setq elevation_ (cond ((cdr (assoc 38 (entget entity_)))) (0.0)))
  (setq radius_ (max tol_ (* 12.0 (/ (getvar "VIEWSIZE") (max 1 (cadr (getvar "SCREENSIZE")))))))
  (setq i_ 0)
  (while (< i_ (length points_))
    (setq a_ (nth i_ points_))
    (setq b_ (nth (rem (1+ i_) (length points_)) points_))
    (setq dx_ (- (car b_) (car a_)))
    (setq dy_ (- (cadr b_) (cadr a_)))
    (setq len2_ (+ (* dx_ dx_) (* dy_ dy_)))
    (if (> len2_ (* tol_ tol_))
      (progn
        (setq t_ (max 0.0 (min 1.0 (/ (+ (* (- (car ocs_) (car a_)) dx_) (* (- (cadr ocs_) (cadr a_)) dy_)) len2_))))
        ;; Snap numerically exact endpoint hits to 0/1.
        (if (<= (* t_ (sqrt len2_)) tol_) (setq t_ 0.0))
        (if (<= (* (- 1.0 t_) (sqrt len2_)) tol_) (setq t_ 1.0))
        (setq p_ (TA:BF:Lerp_ a_ b_ t_))
        (setq d_ (distance ocs_ (list (car p_) (cadr p_) elevation_)))
        (if (<= d_ radius_) (setq result_ (cons (list i_ t_ d_ (sqrt len2_)) result_)))
      )
    )
    (setq i_ (1+ i_))
  )
  (reverse result_)
)

(defun TA:BF:Pair_range_ (first_ second_ tol_ / a_ b_ score_ best_ result_)
  (foreach a_ first_
    (foreach b_ second_
      (if (and (= (car a_) (car b_)) (> (* (abs (- (cadr a_) (cadr b_))) (nth 3 a_)) tol_))
        (progn
          (setq score_ (+ (caddr a_) (caddr b_)))
          (if (or (null best_) (< score_ best_))
            (progn
              (setq best_ score_)
              (setq result_ (list (car a_) (cadr a_) (cadr b_)))
            )
          )
        )
      )
    )
  )
  result_
)

(defun TA:BF:Range_spec_ (range_ width_ ang1_ ang2_)
  (if (< (cadr range_) (caddr range_))
    (list (car range_) width_ ang1_ ang2_ (cadr range_) (caddr range_))
    (list (car range_) width_ ang2_ ang1_ (caddr range_) (cadr range_))
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

(defun TA:BF:Contour_ (points_ specs_ tol_ / side_ i_ n_ spec_ cap_ result_ ok_ a_ b_ ends_)
  (setq side_ (if (> (TA:BF:Area_ points_) 0.0) -1.0 1.0)
        i_ 0 n_ (length points_) ok_ T)
  (while (and ok_ (< i_ n_))
    (setq a_ (nth i_ points_)
          b_ (nth (rem (1+ i_) n_) points_)
          result_ (cons a_ result_))
    (if (setq spec_ (assoc i_ specs_))
      (progn
        (setq ends_ (TA:BF:Edge_points_ points_ spec_))
        (if (setq cap_ (TA:BF:Flange_ (car ends_) (cadr ends_) (nth 1 spec_) (nth 2 spec_) (nth 3 spec_) side_ tol_))
          (progn
            (if (not (equal a_ (car ends_) tol_)) (setq result_ (cons (car ends_) result_)))
            (setq result_ (cons (cadr cap_) (cons (car cap_) result_)))
            (if (not (equal b_ (cadr ends_) tol_)) (setq result_ (cons (cadr ends_) result_)))
          )
          (setq ok_ nil)
        )
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
   / outline_ bend_preset_ remaining_ ends_ bend_ bends_ failed_)
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
            (setq ends_ (TA:BF:Edge_points_ vertices_ (car remaining_)))
            (setq bend_
              (if ends_
                    (vl-catch-all-apply 'TA:BF:Make_polyline_
                      (list source_ ends_ bend_preset_ nil))
              )
            )
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

(defun c:FF1
  (/ *error* preset_ tol_ source_ selection_ data_ vertices_ selecting_
     osmode_ cmdecho_ undo_open_ output_ bend_entities_ new_result_ width_ ang1_ ang2_
     history_ specs_ candidate_ spec_ previous_ contour_ point1_ point2_
     pick1_ pick2_ range_ running_ keep_source_ delete_result_ source_deleted_)

  (defun *error* (message_)
    (TA:BF:Erase_entities_ (cons output_ bend_entities_))
    (if new_result_
      (TA:BF:Erase_entities_ (cons (car new_result_) (cadr new_result_))))
    (if source_deleted_ (entdel source_))
    (if (and source_ (entget source_)) (redraw source_ 4))
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
          (setvar "OSMODE" 515) ; Endpoint + Midpoint + Nearest
          (redraw source_ 3)
          ;; Use remembered values; Preset is the first-run fallback only.
          (setq width_ (cond (*TA:BF:Width*) ((cdr (assoc 'Width preset_))))
                ang1_ (cond (*TA:BF:Ang1*) ((cdr (assoc 'Ang1 preset_))))
                ang2_ (cond (*TA:BF:Ang2*) ((cdr (assoc 'Ang2 preset_))))
                history_ (list nil) running_ T)
          (princ "\nPick any two points on ONE original edge. Partial edges and reverse picking are allowed.")
          (princ "\nPicking the same original edge again replaces its previous flange range.")
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
              ((null (setq pick1_ (TA:BF:Point_on_edges_ point1_ source_ vertices_ tol_)))
                (princ "\nPick a point on an original panel edge."))
              (T
                (setq point2_ (getpoint point1_ "\nPoint 2 <cancel this pair>: "))
                (cond
                  ((null point2_) (princ "\nPair cancelled."))
                  ((null (setq pick2_ (TA:BF:Point_on_edges_ point2_ source_ vertices_ tol_)))
                    (princ "\nPick a point on an original panel edge."))
                  ((null (setq range_ (TA:BF:Pair_range_ pick1_ pick2_ tol_)))
                    (princ "\nPick two DIFFERENT points on the SAME original straight edge."))
                  (T
                    (princ (strcat "\nOriginal edge " (itoa (1+ (car range_))) ": selected range only."))
                    ;; Save each accepted input immediately, including Enter.
                    ;; Thus a later Esc does not lose earlier entered values.
                    (setq width_ (TA:BF:Get_real_ "Flange width X" width_ nil))
                    (setq *TA:BF:Width* width_)
                    (setq ang1_ (TA:BF:Get_real_ "Ang1 (P1 -> P2, toward outside)" ang1_ T))
                    (setq *TA:BF:Ang1* ang1_)
                    (setq ang2_ (TA:BF:Get_real_ "Ang2 (P2 -> P1, toward outside)" ang2_ T))
                    (setq *TA:BF:Ang2* ang2_)
                    (setq spec_ (TA:BF:Range_spec_ range_ width_ ang1_ ang2_))
                    (setq previous_ (assoc (car spec_) specs_))
                    (setq candidate_ (if previous_ (subst spec_ previous_ specs_) (cons spec_ specs_)))
                    (setq contour_ (TA:BF:Contour_ vertices_ candidate_ tol_))
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
      (if output_
        (progn
          (initget "Yes No")
          (setq keep_source_ (getkword "\nKeep original polyline? [Yes/No] <Yes>: "))
          (if (equal keep_source_ "No")
            (progn
              (setq delete_result_ (vl-catch-all-apply 'entdel (list source_)))
              (if (or (vl-catch-all-error-p delete_result_) (null delete_result_))
                (princ "\nCould not delete the original polyline; it was retained.")
                (setq source_deleted_ T)
              )
            )
          )
          (entupd output_)
          (princ (strcat "\nClosed blank outline created. Flanged edges: " (itoa (length specs_))
                         "; bend lines: " (itoa (length bend_entities_)))))
        (princ "\nNo blank outline created.")
      )
      (setvar "OSMODE" osmode_)
      (setvar "CMDECHO" cmdecho_)
      (command-s "_.UNDO" "_End")
      (setq undo_open_ nil)
    )
  )
  (princ)
)

;; FF2 shares the BF geometry/entity/input helpers above. Its settings are
;; independent: *TA:BFI:Width*, *TA:BFI:Ang1*, *TA:BFI:Ang2* stay GLOBAL.
;; Ang1/Ang2 are measured toward the INSIDE for this command.
(defun TA:BFI:Point_inside_p_ (p_ points_ tol_ / a_ b_ inside_ boundary_)
  (setq a_ (last points_))
  (foreach b_ points_
    (if (TA:BF:On_segment_ p_ a_ b_ tol_)
      (setq boundary_ T)
    )
    (if
      (and
        (not (eq (> (cadr a_) (cadr p_)) (> (cadr b_) (cadr p_))))
        (< (- (car p_) (car a_))
           (* (- (cadr p_) (cadr a_))
              (/ (- (car b_) (car a_)) (- (cadr b_) (cadr a_)))))
      )
      (setq inside_ (not inside_))
    )
    (setq a_ b_)
  )
  (or boundary_ inside_)
)

(defun TA:BFI:Segment_inside_p_
  (a_ b_ points_ tol_ / len_ dx_ dy_ c_ d_ hit_ hits_ params_ p_ t_ prev_ ok_)
  ;; Split at ALL boundary contacts, then test each interval. Testing only
  ;; endpoints would miss a segment leaving and re-entering a concave panel.
  (setq ok_ (and (TA:BFI:Point_inside_p_ a_ points_ tol_) (TA:BFI:Point_inside_p_ b_ points_ tol_)))
  (setq len_ (distance a_ b_))
  (if (and ok_ (> len_ tol_))
    (progn
      (setq dx_ (- (car b_) (car a_)))
      (setq dy_ (- (cadr b_) (cadr a_)))
      (setq c_ (last points_))
      (foreach d_ points_
        (if (setq hit_ (inters a_ b_ c_ d_ T))
          (setq hits_ (cons hit_ hits_))
        )
        (if (TA:BF:On_segment_ d_ a_ b_ tol_)
          (setq hits_ (cons d_ hits_))
        )
        (setq c_ d_)
      )
      (setq params_ '(0.0 1.0))
      (foreach p_ hits_
        (setq t_ (/ (+ (* (- (car p_) (car a_)) dx_) (* (- (cadr p_) (cadr a_)) dy_)) (* len_ len_)))
        (setq params_ (cons (max 0.0 (min 1.0 t_)) params_))
      )
      (setq params_ (vl-sort params_ '<))
      (setq prev_ (car params_))
      (foreach t_ (cdr params_)
        (if (> (* (- t_ prev_) len_) tol_)
          (progn
            (setq p_ (list (+ (car a_) (* dx_ (/ (+ prev_ t_) 2.0))) (+ (cadr a_) (* dy_ (/ (+ prev_ t_) 2.0)))))
            (if (not (TA:BFI:Point_inside_p_ p_ points_ tol_))
              (setq ok_ nil)
            )
          )
        )
        (setq prev_ t_)
      )
    )
  )
  ok_
)

(defun TA:BFI:Clean_contour_ (points_ tol_ / changed_ n_ i_ a_ b_ c_ k_ kept_ p_)
  ;; Remove zero-length edges and zero-area retracing tips. In particular,
  ;; 90-degree end cuts can retrace a neighbour, and two 45-degree mitres
  ;; can meet at the same point. Keep ordinary forward collinear vertices.
  (setq changed_ T)
  (while (and changed_ (> (length points_) 2))
    (setq changed_ nil)
    (setq n_ (length points_))
    (setq i_ 0)
    (while (and (not changed_) (< i_ n_))
      (setq a_ (nth (rem (+ i_ n_ -1) n_) points_))
      (setq b_ (nth i_ points_))
      (setq c_ (nth (rem (1+ i_) n_) points_))
      (if
        (or
          (equal b_ c_ tol_)
          (TA:BF:On_segment_ c_ a_ b_ tol_)
          (TA:BF:On_segment_ a_ b_ c_ tol_)
        )
        (progn
          (setq k_ 0)
          (setq kept_ nil)
          (foreach p_ points_
            (if (/= k_ i_) (setq kept_ (cons p_ kept_)))
            (setq k_ (1+ k_))
          )
          (setq points_ (reverse kept_))
          (setq changed_ T)
        )
      )
      (setq i_ (1+ i_))
    )
  )
  points_
)

(defun TA:BFI:Contour_
  (points_ specs_ tol_ / side_ i_ n_ spec_ cap_ result_ ok_ a_ b_)
  ;; Flange_ already accepts a normal direction: reuse it with the inward
  ;; sign. Do not alter BF:Contour_ or the outward FF1 behaviour.
  (setq side_ (if (> (TA:BF:Area_ points_) 0.0) 1.0 -1.0))
  (setq i_ 0)
  (setq n_ (length points_))
  (setq ok_ T)
  (while (and ok_ (< i_ n_))
    (setq a_ (nth i_ points_))
    (setq b_ (nth (rem (1+ i_) n_) points_))
    (setq result_ (cons a_ result_))
    (if (setq spec_ (assoc i_ specs_))
      (progn
        (setq cap_ (TA:BF:Flange_ a_ b_ (nth 1 spec_) (nth 2 spec_) (nth 3 spec_) side_ tol_))
        (if
          (and cap_
            (TA:BFI:Segment_inside_p_ a_ (car cap_) points_ tol_)
            (TA:BFI:Segment_inside_p_ (car cap_) (cadr cap_) points_ tol_)
            (TA:BFI:Segment_inside_p_ (cadr cap_) b_ points_ tol_)
          )
          (setq result_ (cons (cadr cap_) (cons (car cap_) result_)))
          (setq ok_ nil)
        )
      )
    )
    (setq i_ (1+ i_))
  )
  (if ok_
    (progn
      (setq result_ (TA:BFI:Clean_contour_ (reverse result_) tol_))
      (if
        (and
          (TA:BF:Simple_polygon_p_ result_ tol_)
          (> (* side_ (TA:BF:Area_ result_)) (* tol_ tol_))
        )
        result_
      )
    )
  )
)

(defun c:FF2
  (/ *error* preset_ tol_ source_ selection_ data_ vertices_ selecting_
     osmode_ cmdecho_ undo_open_ output_ bend_entities_ new_result_ width_ ang1_ ang2_
     history_ specs_ candidate_ spec_ previous_ contour_ point1_ point2_
     i_ j_ running_ keep_source_ delete_result_ source_deleted_)

  (defun *error* (message_)
    (TA:BF:Erase_entities_ (cons output_ bend_entities_))
    (if new_result_
      (TA:BF:Erase_entities_ (cons (car new_result_) (cadr new_result_)))
    )
    (if source_deleted_ (entdel source_))
    (if (and source_ (entget source_)) (redraw source_ 4))
    (if osmode_ (setvar "OSMODE" osmode_))
    (if cmdecho_ (setvar "CMDECHO" cmdecho_))
    (if undo_open_ (command-s "_.UNDO" "_End"))
    (if (and message_ (not (wcmatch (strcase message_) "*CANCEL*,*QUIT*,*BREAK*")))
      (princ (strcat "\nError: " message_))
      (princ "\nCancelled. Source retained; FF2 outline and bend lines removed.")
    )
    (princ)
  )

  (setq preset_ (TA:BF:Preset_))
  (setq tol_ (cdr (assoc 'Tolerance preset_)))
  (setq selecting_ T)
  (while selecting_
    (setq selection_ (entsel "\nFF2 - Select closed panel polyline: "))
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
          ((not (TA:BF:Simple_polygon_p_ (setq vertices_ (TA:BF:Vertices_ (car selection_) tol_)) tol_))
            (princ "\nPanel boundary is degenerate, overlapping or self-intersecting."))
          (T
            (setq source_ (car selection_))
            (setq selecting_ nil)
          )
        )
      )
    )
  )

  (if source_
    (progn
      (setq osmode_ (getvar "OSMODE"))
      (setq cmdecho_ (getvar "CMDECHO"))
      (setvar "CMDECHO" 0)
      (command-s "_.UNDO" "_Begin")
      (setq undo_open_ T)
      (if (and (TA:BF:Ensure_style_ preset_) (TA:BF:Ensure_style_ (TA:BF:Bend_preset_ preset_)))
        (progn
          (setvar "OSMODE" 1)
          (redraw source_ 3)
          (setq width_ (cond (*TA:BFI:Width*) ((cdr (assoc 'Width preset_)))))
          (setq ang1_ (cond (*TA:BFI:Ang1*) ((cdr (assoc 'Ang1 preset_)))))
          (setq ang2_ (cond (*TA:BFI:Ang2*) ((cdr (assoc 'Ang2 preset_)))))
          (setq history_ (list nil))
          (setq running_ T)
          (princ "\nFF2: flanges go INSIDE the original polyline. Select two adjacent vertices.")
          (while running_
            (initget "Undo Done")
            (setq point1_ (getpoint "\nPoint 1 [Undo/Done] <Done>: "))
            (cond
              ((or (null point1_) (equal point1_ "Done")) (setq running_ nil))
              ((equal point1_ "Undo")
                (if (cdr history_)
                  (progn
                    (setq candidate_ (cadr history_))
                    (setq new_result_ (TA:BF:Make_result_ source_ vertices_ candidate_ (TA:BFI:Contour_ vertices_ candidate_ tol_) preset_))
                    (if new_result_
                      (progn
                        (TA:BF:Erase_entities_ (cons output_ bend_entities_))
                        (setq output_ (car new_result_))
                        (setq bend_entities_ (cadr new_result_))
                        (setq specs_ candidate_)
                        (setq history_ (cdr history_))
                        (setq new_result_ nil)
                        (princ "\nLast inward edge edit undone.")
                      )
                      (princ "\nCould not update outline; previous result retained.")
                    )
                  )
                  (princ "\nNo edge edit to undo.")
                )
              )
              ((null (setq i_ (TA:BF:Nearest_vertex_ point1_ source_ vertices_)))
                (princ "\nPick a vertex of the original panel."))
              (T
                (setq point2_ (getpoint point1_ "\nPoint 2 <cancel this pair>: "))
                (cond
                  ((null point2_) (princ "\nPair cancelled."))
                  ((null (setq j_ (TA:BF:Nearest_vertex_ point2_ source_ vertices_)))
                    (princ "\nPick a vertex of the original panel."))
                  ((null (TA:BF:Edge_spec_ i_ j_ (length vertices_) 1.0 90.0 90.0))
                    (princ "\nSelect two adjacent vertices of ONE original edge."))
                  (T
                    (setq width_ (TA:BF:Get_real_ "Inside flange width X" width_ nil))
                    (setq *TA:BFI:Width* width_)
                    (setq ang1_ (TA:BF:Get_real_ "Ang1 (P1 -> P2, toward inside)" ang1_ T))
                    (setq *TA:BFI:Ang1* ang1_)
                    (setq ang2_ (TA:BF:Get_real_ "Ang2 (P2 -> P1, toward inside)" ang2_ T))
                    (setq *TA:BFI:Ang2* ang2_)
                    (setq spec_ (TA:BF:Edge_spec_ i_ j_ (length vertices_) width_ ang1_ ang2_))
                    (setq previous_ (assoc (car spec_) specs_))
                    (setq candidate_ (if previous_ (subst spec_ previous_ specs_) (cons spec_ specs_)))
                    (setq contour_ (TA:BFI:Contour_ vertices_ candidate_ tol_))
                    (cond
                      ((null contour_)
                        (princ "\nInward flange leaves the panel, collapses, or overlaps another edge. Adjust X/angles; edit rejected."))
                      ((setq new_result_ (TA:BF:Make_result_ source_ vertices_ candidate_ contour_ preset_))
                        (TA:BF:Erase_entities_ (cons output_ bend_entities_))
                        (setq output_ (car new_result_))
                        (setq bend_entities_ (cadr new_result_))
                        (setq specs_ candidate_)
                        (setq history_ (cons specs_ history_))
                        (setq new_result_ nil)
                        (princ "\nInside outline and bend lines updated. Select another edge or press Enter.")
                      )
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
      (if output_
        (progn
          (initget "Yes No")
          (setq keep_source_ (getkword "\nKeep original polyline? [Yes/No] <Yes>: "))
          (if (equal keep_source_ "No")
            (progn
              (setq delete_result_ (vl-catch-all-apply 'entdel (list source_)))
              (if (or (vl-catch-all-error-p delete_result_) (null delete_result_))
                (princ "\nCould not delete the original polyline; it was retained.")
                (setq source_deleted_ T)
              )
            )
          )
          (entupd output_)
          (princ (strcat "\nFF2 complete. Inside edges: " (itoa (length specs_)) "; bend lines: " (itoa (length bend_entities_))))
        )
        (princ "\nNo inside outline created.")
      )
      (setvar "OSMODE" osmode_)
      (setvar "CMDECHO" cmdecho_)
      (command-s "_.UNDO" "_End")
      (setq undo_open_ nil)
    )
  )
  (princ)
)

(princ "\nLoaded: TA_BLANK_FLANGE - FF1 (outside), FF2 (inside)")
(princ)
