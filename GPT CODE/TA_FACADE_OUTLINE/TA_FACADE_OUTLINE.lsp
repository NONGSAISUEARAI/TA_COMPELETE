;presetting
(setq prefix_txt_       (getenv "COMPUTERNAME")) ; Machine running AutoCAD; visible prefix for legacy LENGTH
(setq block_info_       "facade_1_INFO")  ; Reuse this AREA/MAT/STATION/FLOOR block
(setq block_length_     "facade_1_LABEL") ; Reuse this separate LENGTH block
(setq exception_blocks_ (list "facade_1_INFO" "facade_1_LABEL")) ; Add exact block names to skip; (list) = none
(setq outline_mode_     "OVERALL") ; "OVERALL" = one envelope across gaps; "SPLIT" = separate closed groups
(setq style_txt_        "Standard")
(setq layer_outline_    "TA-FACADE-OUTLINE")
(setq color_outline_    4)          ; Cyan
(setq factor_area_ 0.000001) ; พื้นที่ mm² → m²        ; Square drawing units; use 0.000001 for mm2 -> m2
(setq precision_area_   2)          ; AREA decimal places
(setq mat_txt_          "")         ; MAT default value
(setq station_txt_      "")         ; STATION default value
(setq floor_txt_        "")         ; FLOOR default value
(setq height_info_      10.0)       ; Information block text height
(setq spacing_info_     1.6)        ; Row spacing, in text heights
(setq offset_info_      '(0.0 0.0)) ; WCS XY offset from an automatic interior point
(setq layer_info_       "TA-FACADE-INFO")
(setq color_info_       2)          ; Yellow
(setq tolerance_fo_     0.00001)
;
;;; TA_FACADE_OUTLINE v1.8 -- commands FO / FACADEOUTLINE.
;;; Standalone AutoLISP, AutoCAD for Windows with REGION/UNION support.
;;; Input: 2D block references and polylines, on one WCS XY plane.
;;; Output: one overall envelope by default; SPLIT retains separate components.
;;; Read block definitions without changing them, including nested inserts.
;;; Straight edges and circular arcs are retained exactly. Width is ignored.
;;; Xrefs, XCLIP, MINSERT, 3D and nonuniformly scaled curved edges are rejected.
;;; Attribute values are snapshots: run FO again after changing source objects.
;;; Each outline also gets a separate AREA / MAT / STATION / FLOOR block.
;;; FO and FACADEOUTLINE never create LENGTH attribute labels.
(vl-load-com)

;;; Compatibility defaults for internal callers of the older Build API.
;;; These are not FO presets: FO always runs with label_mode_ = NONE.
(setq label_mode_ "NONE" height_txt_ 20.0 offset_txt_ 10.0 precision_txt_ 0
      factor_length_ 1.0 layer_txt_ "TA-FACADE-LABEL" color_txt_ 6)

(defun TFO:Require (ok message)
  (if (not ok) (progn (setq tfo-problem message) (quit))) ok)

(defun TFO:Get (code data fallback / pair)
  (if (setq pair (assoc code data)) (cdr pair) fallback))

(defun TFO:XY (p) (list (car p) (cadr p)))
(defun TFO:Add (a b) (mapcar '+ a b))
(defun TFO:Sub (a b) (mapcar '- a b))
(defun TFO:Scale (a k) (mapcar '(lambda (x) (* x k)) a))
(defun TFO:Dot (a b) (apply '+ (mapcar '* a b)))
(defun TFO:Cross (a b) (- (* (car a) (cadr b)) (* (cadr a) (car b))))
(defun TFO:Angle (a / r)
  (setq r (rem a (* 2.0 pi))) (if (< r 0.0) (+ r (* 2.0 pi)) r))

(defun TFO:Identity ()
  '((1.0 0.0 0.0 0.0) (0.0 1.0 0.0 0.0)
    (0.0 0.0 1.0 0.0) (0.0 0.0 0.0 1.0)))

(defun TFO:MatrixProduct (a b / columns)
  (setq columns (apply 'mapcar (cons 'list b)))
  (mapcar '(lambda (row)
    (mapcar '(lambda (col) (TFO:Dot row col)) columns)) a))

(defun TFO:Transform (matrix p vector)
  (mapcar '(lambda (row)
    (TFO:Dot row (append p (list (if vector 0.0 1.0)))))
    (list (car matrix) (cadr matrix) (caddr matrix))))

(defun TFO:InsertMatrix (data definition / normal x y z sx sy sz c s origin ins shift xx yy)
  (setq normal (TFO:Get 210 data '(0.0 0.0 1.0))
        sx (TFO:Get 41 data 1.0) sy (TFO:Get 42 data 1.0) sz (TFO:Get 43 data 1.0)
        c (cos (TFO:Get 50 data 0.0)) s (sin (TFO:Get 50 data 0.0))
        xx (trans '(1.0 0.0 0.0) normal 0 T)
        yy (trans '(0.0 1.0 0.0) normal 0 T)
        x (TFO:Scale (TFO:Add (TFO:Scale xx c) (TFO:Scale yy s)) sx)
        y (TFO:Scale (TFO:Add (TFO:Scale xx (- s)) (TFO:Scale yy c)) sy)
        z (TFO:Scale normal sz)
        origin (cdr (assoc 10 definition))
        ins (trans (cdr (assoc 10 data)) normal 0)
        shift (TFO:Sub ins (TFO:Add (TFO:Scale x (car origin))
          (TFO:Add (TFO:Scale y (cadr origin)) (TFO:Scale z (caddr origin))))))
  (TFO:Require (and (> (abs sx) tolerance_fo_) (> (abs sy) tolerance_fo_))
    "A selected block has a zero or nearly zero scale.")
  (list (list (car x) (car y) (car z) (car shift))
        (list (cadr x) (cadr y) (cadr z) (cadr shift))
        (list (caddr x) (caddr y) (caddr z) (caddr shift))
        '(0.0 0.0 0.0 1.0)))

(defun TFO:Visible (data / layer)
  (setq layer (tblsearch "LAYER" (TFO:Get 8 data "0")))
  (and (/= 1 (TFO:Get 60 data 0))
       (>= (TFO:Get 62 layer 7) 0)
       (= 0 (logand 1 (TFO:Get 70 layer 0)))))

(defun TFO:ExceptedBlock (data / name)
  (setq name (strcase (TFO:Get 2 data "")))
  (vl-some '(lambda (item) (= name (strcase item))) exception_blocks_))

(defun TFO:Clipped (data / dict filters)
  (and (setq dict (cdr (assoc 360 data)))
       (setq filters (dictsearch dict "ACAD_FILTER"))
       (dictsearch (cdr (assoc -1 filters)) "SPATIAL")))

(defun TFO:PlanePoint (p)
  (if (null tfo-elevation) (setq tfo-elevation (caddr p)))
  (TFO:Require (equal (caddr p) tfo-elevation tolerance_fo_)
    "All source edges must lie on one plane parallel to WCS XY.") p)

(defun TFO:Make (data / entity)
  (TFO:Require (entmake data) "AutoCAD could not create a working entity.")
  (setq entity (entlast) tfo-temp (cons entity tfo-temp)) entity)

(defun TFO:LWVertices (data / result point bulge pair)
  (setq bulge 0.0)
  (foreach pair data
    (cond
      ((= (car pair) 10)
       (if point (setq result (cons (list point bulge) result)))
       (setq point (cdr pair) bulge 0.0))
      ((= (car pair) 42) (setq bulge (cdr pair)))))
  (if point (setq result (cons (list point bulge) result)))
  (reverse result))

(defun TFO:OldVertices (entity / data result)
  (while (and (setq entity (entnext entity))
              (/= "SEQEND" (TFO:Get 0 (setq data (entget entity)) "")))
    (if (= "VERTEX" (cdr (assoc 0 data)))
      (setq result (cons (list (TFO:XY (cdr (assoc 10 data)))
                              (TFO:Get 42 data 0.0)) result))))
  (reverse result))

(defun TFO:LWData (vertices elevation layer / result item)
  (setq result (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") (cons 8 layer)
    '(100 . "AcDbPolyline") (cons 90 (length vertices)) '(70 . 1) (cons 38 elevation)))
  (foreach item vertices
    (setq result (append result (list (cons 10 (car item)) (cons 42 (cadr item))))))
  (append result '((210 0.0 0.0 1.0))))

;;; Map a curve's OCS axes into WCS. A circular arc needs a planar similarity.
(defun TFO:Axes (normal matrix curved / x y nx ny sign)
  (setq x (TFO:Transform matrix (trans '(1.0 0.0 0.0) normal 0 T) T)
        y (TFO:Transform matrix (trans '(0.0 1.0 0.0) normal 0 T) T)
        nx (distance '(0.0 0.0 0.0) x) ny (distance '(0.0 0.0 0.0) y)
        sign (if (< (TFO:Cross x y) 0.0) -1.0 1.0))
  (TFO:Require (and (equal (caddr x) 0.0 tolerance_fo_)
                   (equal (caddr y) 0.0 tolerance_fo_))
    "Tilted polylines or curved edges are not supported; use WCS XY geometry.")
  (if curved
    (TFO:Require (and (> nx tolerance_fo_) (> ny tolerance_fo_)
      (<= (abs (- nx ny)) (* tolerance_fo_ (max 1.0 nx ny)))
      (<= (abs (TFO:Dot x y)) (* tolerance_fo_ (max 1.0 (* nx ny)))))
      "A curved edge is stretched/sheared by its block. Use uniform scale for curved blocks."))
  (list nx sign))

(defun TFO:ReadPolyline (entity data matrix / flags old vertices normal elevation axes out item p curved d)
  (setq old (= "POLYLINE" (cdr (assoc 0 data))) flags (TFO:Get 70 data 0))
  (TFO:Require (= 0 (logand flags 126)) "3D, fitted and mesh polylines are not supported.")
  (setq vertices (if old (TFO:OldVertices entity) (TFO:LWVertices data))
        normal (TFO:Get 210 data '(0.0 0.0 1.0))
        elevation (if old (caddr (cdr (assoc 10 data))) (TFO:Get 38 data 0.0)))
  (foreach item vertices (if (not (equal (cadr item) 0.0 1e-14)) (setq curved T)))
  (setq axes (TFO:Axes normal matrix curved))
  (foreach item vertices
    (setq p (TFO:PlanePoint (TFO:Transform matrix
      (trans (append (car item) (list elevation)) normal 0) nil)))
    (setq out (cons (list (TFO:XY p) (* (cadr axes) (cadr item))) out)))
  (setq out (reverse out))
  (TFO:Require (> (length out) 1) "A source polyline has fewer than two vertices.")
  (setq d (TFO:LWData out tfo-elevation tfo-work-layer))
  (if (= 0 (logand 1 flags)) (setq d (subst '(70 . 0) (assoc 70 d) d)))
  (TFO:Make d))

(defun TFO:ReadCurve (entity data matrix / kind normal center radius axes a b p q)
  (setq kind (cdr (assoc 0 data)))
  (cond
    ((= kind "LINE")
     (setq p (TFO:PlanePoint (TFO:Transform matrix (cdr (assoc 10 data)) nil))
           q (TFO:PlanePoint (TFO:Transform matrix (cdr (assoc 11 data)) nil)))
     (if (> (distance p q) tolerance_fo_)
       (TFO:Make (list '(0 . "LINE") (cons 8 tfo-work-layer) (cons 10 p) (cons 11 q)))))
    ((member kind '("LWPOLYLINE" "POLYLINE")) (TFO:ReadPolyline entity data matrix))
    ((member kind '("ARC" "CIRCLE"))
     (setq normal (TFO:Get 210 data '(0.0 0.0 1.0))
           axes (TFO:Axes normal matrix T)
           center (cdr (assoc 10 data)) radius (cdr (assoc 40 data))
           p (TFO:PlanePoint (TFO:Transform matrix (trans center normal 0) nil)))
     (if (= kind "CIRCLE")
       (TFO:Make (list '(0 . "CIRCLE") (cons 8 tfo-work-layer)
         (cons 10 p) (cons 40 (* radius (car axes)))))
       (progn
         (setq q (TFO:Transform matrix (trans (polar center (cdr (assoc 50 data)) radius) normal 0) nil)
               a (atan (- (cadr q) (cadr p)) (- (car q) (car p)))
               q (TFO:Transform matrix (trans (polar center (cdr (assoc 51 data)) radius) normal 0) nil)
               b (atan (- (cadr q) (cadr p)) (- (car q) (car p))))
         (TFO:Make (list '(0 . "ARC") (cons 8 tfo-work-layer) (cons 10 p)
           (cons 40 (* radius (car axes)))
           (cons 50 (TFO:Angle (if (> (cadr axes) 0.0) a b)))
           (cons 51 (TFO:Angle (if (> (cadr axes) 0.0) b a))))))))))

(defun TFO:Read (entity matrix depth / data kind definition child local flags)
  (setq data (entget entity) kind (cdr (assoc 0 data)))
  (if (TFO:Visible data)
    (cond
      ;; Skip the whole reference before reading its geometry or nested inserts.
      ((and (= kind "INSERT") (TFO:ExceptedBlock data)) nil)
      ((= kind "INSERT")
       (TFO:Require (< depth 32) "Block nesting exceeds 32 levels.")
       (setq definition (tblsearch "BLOCK" (cdr (assoc 2 data))) flags (TFO:Get 70 definition 0))
       (TFO:Require (and definition (= 0 (logand flags 124))) "Xrefs are not supported.")
       (TFO:Require (not (TFO:Clipped data)) "XCLIP blocks are not supported.")
       (TFO:Require (and (<= (TFO:Get 70 data 1) 1) (<= (TFO:Get 71 data 1) 1))
         "MINSERT arrays are not supported.")
       (setq local (TFO:MatrixProduct matrix (TFO:InsertMatrix data definition))
             child (cdr (assoc -2 definition)))
       (while (and child (/= "ENDBLK" (TFO:Get 0 (entget child) "")))
         (TFO:Read child local (1+ depth)) (setq child (entnext child))))
      ((member kind '("LINE" "ARC" "CIRCLE" "LWPOLYLINE" "POLYLINE"))
       (TFO:ReadCurve entity data matrix))
      ((member kind '("TEXT" "MTEXT" "ATTDEF" "ATTRIB" "SEQEND" "VERTEX"
                      "HATCH" "WIPEOUT" "DIMENSION" "LEADER" "MULTILEADER" "POINT")) nil)
      (T (TFO:Require nil (strcat "Unsupported block geometry: " kind "."))))))

(defun TFO:Selection (entities / ss entity)
  (setq ss (ssadd)) (foreach entity entities (if (entget entity) (ssadd entity ss))) ss)

(defun TFO:Since (marker / entity result)
  (setq entity marker)
  (while (setq entity (entnext entity))
    (if (not (member (TFO:Get 0 (entget entity) "") '("VERTEX" "SEQEND" "ATTRIB")))
      (setq result (cons entity result) tfo-temp (cons entity tfo-temp))))
  (reverse result))

(defun TFO:Marker ()
  (TFO:Make (list '(0 . "POINT") (cons 8 tfo-work-layer) '(10 0.0 0.0 0.0))))

(defun TFO:Regions (curves / marker regions ss entity index)
  (setq marker (TFO:Marker))
  (command-s "_.REGION" (TFO:Selection curves) "")
  (foreach entity (TFO:Since marker)
    (if (= "REGION" (TFO:Get 0 (entget entity) "")) (setq regions (cons entity regions))))
  (TFO:Require regions "No closed area found. Close gaps in the selected outlines first.")
  (if (> (length regions) 1) (command-s "_.UNION" (TFO:Selection regions) ""))
  (setq ss (TFO:Selection regions) regions nil)
  (repeat (setq index (sslength ss))
    (setq regions (cons (ssname ss (setq index (1- index))) regions)))
  regions)

(defun TFO:Edges (region / marker parts kind result p q data a sweep bulge entity)
  (setq marker (TFO:Marker))
  (command-s "_.EXPLODE" region "")
  (setq parts (TFO:Since marker))
  (TFO:Require parts "Could not extract the merged region boundary.")
  (foreach entity parts
    (setq data (entget entity) kind (cdr (assoc 0 data)))
    (cond
      ((= kind "REGION") (setq result (append (TFO:Edges entity) result)))
      ((= kind "LINE")
       (setq p (TFO:XY (cdr (assoc 10 data))) q (TFO:XY (cdr (assoc 11 data))))
       (if (> (distance p q) tolerance_fo_) (setq result (cons (list p q 0.0) result))))
      ((= kind "ARC")
       (setq p (TFO:XY (vlax-curve-getStartPoint entity))
             q (TFO:XY (vlax-curve-getEndPoint entity))
             sweep (TFO:Angle (- (cdr (assoc 51 data)) (cdr (assoc 50 data))))
             bulge (/ (sin (/ sweep 4.0)) (cos (/ sweep 4.0))))
       (if (< (caddr (TFO:Get 210 data '(0.0 0.0 1.0))) 0.0) (setq bulge (- bulge)))
       (setq result (cons (list p q bulge) result)))
      ((= kind "CIRCLE")
       (setq p (TFO:XY (polar (cdr (assoc 10 data)) 0.0 (cdr (assoc 40 data))))
             q (TFO:XY (polar (cdr (assoc 10 data)) pi (cdr (assoc 40 data)))))
       (setq result (cons (list p q 1.0) (cons (list q p 1.0) result))))
      (T (TFO:Require nil (strcat "Merged boundary contains unsupported " kind ".")))))
  result)

(defun TFO:ReverseEdge (edge) (list (cadr edge) (car edge) (- (caddr edge))))
(defun TFO:StartTangent (edge) (- (angle (car edge) (cadr edge)) (* 2.0 (atan (caddr edge)))))
(defun TFO:EndTangent (edge) (+ (angle (car edge) (cadr edge)) (* 2.0 (atan (caddr edge)))))

(defun TFO:Loops (edges / result loop edge rest endpoint start candidate best turn bestturn incoming found)
  (while edges
    (setq edge (car edges) edges (cdr edges) start (car edge)
          loop (list (list (car edge) (caddr edge))) endpoint (cadr edge)
          incoming (TFO:EndTangent edge))
    (while (not (equal endpoint start tolerance_fo_))
      (setq best nil bestturn nil found nil)
      (foreach candidate edges
        (cond
          ((equal endpoint (car candidate) tolerance_fo_) (setq edge candidate))
          ((equal endpoint (cadr candidate) tolerance_fo_) (setq edge (TFO:ReverseEdge candidate)))
          (T (setq edge nil)))
        (if edge
          (progn
            (setq turn (atan (sin (- (TFO:StartTangent edge) incoming))
                             (cos (- (TFO:StartTangent edge) incoming))))
            (if (or (null bestturn) (> turn bestturn))
              (setq best edge bestturn turn found candidate)))))
      (TFO:Require best "Merged edges do not form a closed polyline; check the source geometry.")
      (setq edges (vl-remove found edges) loop (cons (list (car best) (caddr best)) loop)
            endpoint (cadr best) incoming (TFO:EndTangent best)))
    (setq result (cons (reverse loop) result)))
  result)

(defun TFO:Simplify (vertices / changed index count prev current next a b)
  (setq changed T)
  (while (and changed (> (length vertices) 2))
    (setq changed nil index 0 count (length vertices))
    (while (and (< index count) (not changed))
      (setq prev (nth (rem (+ index count -1) count) vertices) current (nth index vertices)
            next (nth (rem (1+ index) count) vertices)
            a (TFO:Sub (car current) (car prev)) b (TFO:Sub (car next) (car current)))
      (if (and (equal (cadr prev) 0.0 1e-14) (equal (cadr current) 0.0 1e-14)
               (> (TFO:Dot a b) 0.0)
               (<= (abs (TFO:Cross a b)) (* tolerance_fo_ (max (distance (car prev) (car next)) tolerance_fo_))))
        (setq vertices (vl-remove current vertices) changed T))
      (setq index (1+ index)))) vertices)

;;; Arc descriptor: center, radius, signed sweep, starting angle.
(defun TFO:Arc (p q bulge / chord sweep center)
  (setq chord (distance p q) sweep (* 4.0 (atan bulge))
        center (polar (mapcar '(lambda (a b) (/ (+ a b) 2.0)) p q)
          (+ (angle p q) (/ pi 2.0)) (/ (* chord (- 1.0 (* bulge bulge))) (* 4.0 bulge))))
  (list center (distance p center) sweep (angle center p)))

(defun TFO:LoopArea (vertices / area origin index p q bulge arc)
  (setq area 0.0 origin (caar vertices) index 0)
  (repeat (length vertices)
    (setq p (car (nth index vertices)) q (car (nth (rem (1+ index) (length vertices)) vertices))
          bulge (cadr (nth index vertices))
          area (+ area (/ (TFO:Cross (TFO:Sub p origin) (TFO:Sub q origin)) 2.0)))
    (if (not (equal bulge 0.0 1e-14))
      (progn (setq arc (TFO:Arc p q bulge))
        (setq area (+ area (* 0.5 (cadr arc) (cadr arc) (- (caddr arc) (sin (caddr arc))))))))
    (setq index (1+ index))) area)

(defun TFO:LoopEdges (vertices closed / index result count)
  (setq index 0 count (length vertices))
  (repeat (if closed count (1- count))
    (setq result (cons (list (car (nth index vertices))
      (car (nth (rem (1+ index) count) vertices)) (cadr (nth index vertices))) result)
      index (1+ index))) (reverse result))

(defun TFO:EntityEdges (entity / data kind p q sweep)
  (setq data (entget entity) kind (cdr (assoc 0 data)))
  (cond
    ((= kind "LWPOLYLINE") (TFO:LoopEdges (TFO:LWVertices data) (= 1 (logand 1 (cdr (assoc 70 data))))))
    ((= kind "LINE") (list (list (TFO:XY (cdr (assoc 10 data))) (TFO:XY (cdr (assoc 11 data))) 0.0)))
    ((= kind "ARC")
     (setq sweep (TFO:Angle (- (cdr (assoc 51 data)) (cdr (assoc 50 data)))))
     (list (list (TFO:XY (vlax-curve-getStartPoint entity)) (TFO:XY (vlax-curve-getEndPoint entity))
       (/ (sin (/ sweep 4.0)) (cos (/ sweep 4.0))))))
    ((= kind "CIRCLE")
     (setq p (TFO:XY (polar (cdr (assoc 10 data)) 0.0 (cdr (assoc 40 data))))
           q (TFO:XY (polar (cdr (assoc 10 data)) pi (cdr (assoc 40 data)))))
     (list (list p q 1.0) (list q p 1.0)))))

;;; Exact point-on-segment parameter for either a line or a circular arc.
(defun TFO:EdgeParam (edge point / p q direction divisor parameter arc delta angle-tol)
  (setq p (car edge) q (cadr edge))
  (if (equal (caddr edge) 0.0 1e-14)
    (progn
      (setq direction (TFO:Sub q p) divisor (TFO:Dot direction direction))
      (if (> divisor (* tolerance_fo_ tolerance_fo_))
        (progn
          (setq parameter (/ (TFO:Dot (TFO:Sub point p) direction) divisor))
          (if (and (<= (- tolerance_fo_) parameter (+ 1.0 tolerance_fo_))
            (<= (distance point (TFO:Add p (TFO:Scale direction parameter))) tolerance_fo_))
            (max 0.0 (min 1.0 parameter))))))
    (progn
      (setq arc (TFO:Arc p q (caddr edge))
            delta (TFO:Angle (* (if (> (caddr arc) 0.0) 1.0 -1.0) (- (angle (car arc) point) (nth 3 arc))))
            angle-tol (/ tolerance_fo_ (max tolerance_fo_ (cadr arc))))
      (if (> delta (- (* 2.0 pi) angle-tol)) (setq delta 0.0))
      (if (and (<= (abs (- (distance point (car arc)) (cadr arc))) tolerance_fo_)
               (<= delta (+ (abs (caddr arc)) angle-tol)))
        (max 0.0 (min 1.0 (/ delta (abs (caddr arc)))))))))

(defun TFO:EdgePoint (edge parameter / arc)
  (if (equal (caddr edge) 0.0 1e-14)
    (TFO:Add (car edge) (TFO:Scale (TFO:Sub (cadr edge) (car edge)) parameter))
    (progn (setq arc (TFO:Arc (car edge) (cadr edge) (caddr edge)))
      (polar (car arc) (+ (nth 3 arc) (* (caddr arc) parameter)) (cadr arc)))))

;;; Ray crossing, retaining circular arcs exactly. Shift a ray slightly only
;;; when it would go through a vertex; boundary points are checked separately.
(defun TFO:Inside (point edges / inside y x edge p q arc dy root candidate near-vertex)
  (setq x (car point) y (cadr point))
  (foreach edge edges
    (if (equal y (cadar edge) tolerance_fo_) (setq near-vertex T)))
  (if near-vertex (setq y (+ y (* 0.371 tolerance_fo_))))
  (foreach edge edges
    (setq p (car edge) q (cadr edge))
    (if (equal (caddr edge) 0.0 1e-14)
      (if (and (not (eq (> (cadr p) y) (> (cadr q) y)))
        (< x (+ (car p) (* (- y (cadr p)) (/ (- (car q) (car p)) (- (cadr q) (cadr p)))))))
        (setq inside (not inside)))
      (progn
        (setq arc (TFO:Arc p q (caddr edge)) dy (- y (cadar arc)))
        (if (< (abs dy) (cadr arc))
          (progn
            (setq root (sqrt (max 0.0 (- (* (cadr arc) (cadr arc)) (* dy dy)))))
            (foreach candidate (list (list (+ (caar arc) root) y) (list (- (caar arc) root) y))
              (if (and (> (car candidate) x) (TFO:EdgeParam edge candidate))
                (setq inside (not inside))))))))) inside)

(defun TFO:Covered (point loops / covered edges edge on-edge)
  (foreach edges loops
    (setq on-edge nil)
    (foreach edge edges (if (TFO:EdgeParam edge point) (setq on-edge T)))
    (if (or on-edge (TFO:Inside point edges)) (setq covered T))) covered)

;;; Intersection candidates of lines and circles; trim candidates against
;;; the finite segments/arcs afterwards. Coincident edges use their endpoints.
(defun TFO:Intersections (a b / candidates arca arcb p d center r aa bb cc disc root
                                   c1 c2 r1 r2 distance-c along height base perpendicular candidate result)
  (setq candidates (list (car a) (cadr a) (car b) (cadr b)))
  (cond
    ((and (equal (caddr a) 0.0 1e-14) (equal (caddr b) 0.0 1e-14))
     (if (setq p (inters (car a) (cadr a) (car b) (cadr b) T)) (setq candidates (cons p candidates))))
    ((or (equal (caddr a) 0.0 1e-14) (equal (caddr b) 0.0 1e-14))
     (if (equal (caddr b) 0.0 1e-14) (setq p a a b b p))
     (setq arcb (TFO:Arc (car b) (cadr b) (caddr b)) center (car arcb) r (cadr arcb)
       p (TFO:Sub (car a) center) d (TFO:Sub (cadr a) (car a))
       aa (TFO:Dot d d) bb (* 2.0 (TFO:Dot p d)) cc (- (TFO:Dot p p) (* r r))
       disc (- (* bb bb) (* 4.0 aa cc)))
     (if (and (> aa (* tolerance_fo_ tolerance_fo_)) (>= disc 0.0))
       (progn (setq root (sqrt disc))
         (foreach along (list (/ (+ (- bb) root) (* 2.0 aa)) (/ (- (- bb) root) (* 2.0 aa)))
           (setq candidates (cons (TFO:Add (car a) (TFO:Scale d along)) candidates))))))
    (T
     (setq arca (TFO:Arc (car a) (cadr a) (caddr a)) arcb (TFO:Arc (car b) (cadr b) (caddr b))
       c1 (car arca) c2 (car arcb) r1 (cadr arca) r2 (cadr arcb) distance-c (distance c1 c2))
     (if (and (> distance-c tolerance_fo_) (<= distance-c (+ r1 r2 tolerance_fo_))
              (>= distance-c (- (abs (- r1 r2)) tolerance_fo_)))
       (progn
         (setq along (/ (+ (* r1 r1) (- (* r2 r2)) (* distance-c distance-c)) (* 2.0 distance-c))
           height (sqrt (max 0.0 (- (* r1 r1) (* along along))))
           d (TFO:Scale (TFO:Sub c2 c1) (/ 1.0 distance-c))
           base (TFO:Add c1 (TFO:Scale d along)) perpendicular (list (- (cadr d)) (car d))
           candidates (cons (TFO:Add base (TFO:Scale perpendicular height))
             (cons (TFO:Sub base (TFO:Scale perpendicular height)) candidates)))))))
  (foreach candidate candidates
    (if (and (TFO:EdgeParam a candidate) (TFO:EdgeParam b candidate)) (setq result (cons candidate result)))) result)

(defun TFO:EdgeCovered (edge boundaries / vertices boundary cuts point parameter rest covered)
  (setq cuts '(0.0 1.0) covered T)
  (foreach vertices boundaries
    (foreach boundary vertices
      (foreach point (TFO:Intersections edge boundary)
        (if (setq parameter (TFO:EdgeParam edge point)) (setq cuts (cons parameter cuts))))))
  (setq rest (vl-sort cuts '<))
  (while (and covered (cdr rest))
    (if (not (TFO:Covered (TFO:EdgePoint edge (/ (+ (car rest) (cadr rest)) 2.0)) boundaries))
      (setq covered nil))
    (setq rest (cdr rest))) covered)

(defun TFO:CheckCoverage (curves loops / boundaries vertices curve edge)
  (foreach vertices loops (setq boundaries (cons (TFO:LoopEdges vertices T) boundaries)))
  (foreach curve curves
    (foreach edge (TFO:EntityEdges curve)
      (TFO:Require (TFO:EdgeCovered edge boundaries)
        "Some selected edges lie outside the outline. Check the open source geometry."))))

(defun TFO:OuterLoops (loops / records vertices record other nested result)
  (foreach vertices loops
    (setq vertices (TFO:Simplify vertices))
    (if (> (abs (TFO:LoopArea vertices)) (* tolerance_fo_ tolerance_fo_))
      (setq records (cons (list vertices (abs (TFO:LoopArea vertices)) (TFO:LoopEdges vertices T)) records))))
  (foreach record records
    (setq nested nil)
    (foreach other records
      (if (and (> (cadr other) (+ (cadr record) (* tolerance_fo_ tolerance_fo_)))
               ;; A first vertex near a shared seam can fall inside its neighbor.
               ;; Only discard a loop when its ENTIRE boundary is enclosed.
               (vl-every '(lambda (edge) (TFO:EdgeCovered edge (list (caddr other))))
                 (caddr record))) (setq nested T)))
    (if (not nested) (setq result (cons (car record) result)))) result)

(defun TFO:GeometryLoops (curves / regions edges region)
  (setq regions (TFO:Regions curves))
  (foreach region regions (setq edges (append (TFO:Edges region) edges)))
  (TFO:OuterLoops (TFO:Loops edges)))

;;; Join free ends in disposable copies. Nearest pairs are joined first; an
;;; existing straight segment is never duplicated as a supposed gap closure.
(defun TFO:ClosurePath (a b edges / edge first second outward-a outward-b corner)
  (foreach edge edges
    (if (equal (caddr edge) 0.0 1e-14)
      (progn
        (if (or (equal a (car edge) tolerance_fo_) (equal a (cadr edge) tolerance_fo_))
          (setq first edge outward-a (TFO:Sub a (if (equal a (car edge) tolerance_fo_) (cadr edge) (car edge)))))
        (if (or (equal b (car edge) tolerance_fo_) (equal b (cadr edge) tolerance_fo_))
          (setq second edge outward-b (TFO:Sub b (if (equal b (car edge) tolerance_fo_) (cadr edge) (car edge))))))))
  ;; Extend to a nearby natural corner when both rays point toward it. This
  ;; avoids introducing a tiny diagonal chamfer at a loose square corner.
  (if (and first second (setq corner (inters (car first) (cadr first) (car second) (cadr second) nil))
           (>= (TFO:Dot (TFO:Sub corner a) outward-a) (- tolerance_fo_))
           (>= (TFO:Dot (TFO:Sub corner b) outward-b) (- tolerance_fo_))
           (<= (+ (distance a corner) (distance b corner)) (* 2.0 (+ (distance a b) tolerance_fo_))))
    (list a corner b) (list a b)))

(defun TFO:CloseOpenEnds (curves / edges curve edge point other attached ends a b same-line
                               best-a best-b best-distance candidate added path)
  (foreach curve curves (setq edges (append (TFO:EntityEdges curve) edges)))
  (foreach edge edges
    (foreach point (list (car edge) (cadr edge))
      (setq attached nil)
      (foreach other edges
        (if (and (not (eq edge other)) (TFO:EdgeParam other point)) (setq attached T)))
      (if (and (not attached) (not (vl-some '(lambda (p) (equal point p tolerance_fo_)) ends)))
        (setq ends (cons point ends)))))
  (while (> (length ends) 1)
    (setq best-a nil best-b nil best-distance nil)
    (foreach a ends
      (foreach b ends
        (if (not (equal a b tolerance_fo_))
          (progn
            (setq same-line nil)
            (foreach edge edges
              (if (and (equal (caddr edge) 0.0 1e-14) (TFO:EdgeParam edge a) (TFO:EdgeParam edge b))
                (setq same-line T)))
            (setq candidate (distance a b))
            (if (and (not same-line) (or (null best-distance) (< candidate best-distance)))
              (setq best-a a best-b b best-distance candidate))))))
    (if best-a
      (progn
        (setq path (TFO:ClosurePath best-a best-b edges))
        (while (cdr path)
          (if (> (distance (car path) (cadr path)) tolerance_fo_)
            (setq added (cons (TFO:Make (list '(0 . "LINE") (cons 8 tfo-work-layer)
              (cons 10 (append (car path) (list tfo-elevation)))
              (cons 11 (append (cadr path) (list tfo-elevation))))) added)))
          (setq path (cdr path)))
        (setq ends (vl-remove best-a (vl-remove best-b ends))))
      (setq ends nil)))
  (append curves (reverse added)))

(defun TFO:NearestPoint (edge point / p q delta divisor parameter arc candidate)
  (setq p (car edge) q (cadr edge))
  (if (equal (caddr edge) 0.0 1e-14)
    (progn
      (setq delta (TFO:Sub q p) divisor (TFO:Dot delta delta))
      (if (> divisor (* tolerance_fo_ tolerance_fo_))
        (setq parameter (max 0.0 (min 1.0 (/ (TFO:Dot (TFO:Sub point p) delta) divisor))))
        (setq parameter 0.0))
      (TFO:EdgePoint edge parameter))
    (progn
      (setq arc (TFO:Arc p q (caddr edge))
            candidate (polar (car arc) (angle (car arc) point) (cadr arc)))
      (if (TFO:EdgeParam edge candidate) candidate (if (< (distance p point) (distance q point)) p q)))))

(defun TFO:EdgeDistance (a b / value point)
  (if (TFO:Intersections a b) 0.0
    (progn
      (foreach point (list (car a) (cadr a))
        (setq value (cons (distance point (TFO:NearestPoint b point)) value)))
      (foreach point (list (car b) (cadr b))
        (setq value (cons (distance point (TFO:NearestPoint a point)) value)))
      (apply 'min value))))

;;; A convex hull is used only for a LOCAL joining patch between two edges,
;;; never as the overall outline: existing concave boundaries remain intact.
(defun TFO:PatchHull (points / sorted lower upper point)
  (setq sorted (vl-sort points '(lambda (a b)
    (if (= (car a) (car b)) (< (cadr a) (cadr b)) (< (car a) (car b))))))
  (foreach point sorted
    (while (and (cdr lower) (<= (TFO:Cross (TFO:Sub (car lower) (cadr lower))
      (TFO:Sub point (car lower))) 0.0)) (setq lower (cdr lower)))
    (setq lower (cons point lower)))
  (foreach point (reverse sorted)
    (while (and (cdr upper) (<= (TFO:Cross (TFO:Sub (car upper) (cadr upper))
      (TFO:Sub point (car upper))) 0.0)) (setq upper (cdr upper)))
    (setq upper (cons point upper)))
  (if (and (cdr lower) (cdr upper))
    (mapcar '(lambda (p) (list p 0.0)) (append (reverse (cdr lower)) (reverse (cdr upper))))))

;;; Facing parallel edges use their overlapping span so panel gaps fill
;;; flush with the existing edges, preserving steps at unequal panel heights.
(defun TFO:ParallelPatch (a b / direction span u v t0 t1 s0 s1 offset p q r s points area)
  (if (and (equal (caddr a) 0.0 1e-14) (equal (caddr b) 0.0 1e-14))
    (progn
      (setq direction (TFO:Sub (cadr a) (car a)) span (distance (car a) (cadr a))
            v (TFO:Sub (cadr b) (car b)))
      (if (and (> span tolerance_fo_) (> (distance (car b) (cadr b)) tolerance_fo_))
        (progn
          (setq u (TFO:Scale direction (/ 1.0 span)))
          (if (<= (abs (TFO:Cross u v)) (* tolerance_fo_ (max 1.0 (distance (car b) (cadr b)))))
            (progn
              (setq s0 (TFO:Dot (TFO:Sub (car b) (car a)) u)
                    s1 (TFO:Dot (TFO:Sub (cadr b) (car a)) u)
                    t0 (max 0.0 (min s0 s1)) t1 (min span (max s0 s1))
                    offset (TFO:Cross u (TFO:Sub (car b) (car a))))
              (if (and (> (- t1 t0) tolerance_fo_) (> (abs offset) tolerance_fo_))
                (progn
                  (setq p (TFO:Add (car a) (TFO:Scale u t0))
                        q (TFO:Add (car a) (TFO:Scale u t1))
                        r (TFO:Add (car b) (TFO:Scale v (/ (- t0 s0) (- s1 s0))))
                        s (TFO:Add (car b) (TFO:Scale v (/ (- t1 s0) (- s1 s0))))
                        points (mapcar '(lambda (p) (list p 0.0))
                          (list p q s r))
                        area (abs (TFO:LoopArea points)))
                  (list (abs offset) points area))))))))))

(defun TFO:BetterPatch (candidate best)
  (and candidate (or (null best) (< (car candidate) (- (car best) tolerance_fo_))
    (and (equal (car candidate) (car best) tolerance_fo_) (< (caddr candidate) (caddr best))))))

(defun TFO:Bridge (a-edges b-edges / a b candidate parallel-best fallback-best points area)
  (foreach a a-edges
    (foreach b b-edges
      (setq candidate (TFO:ParallelPatch a b))
      (if (TFO:BetterPatch candidate parallel-best) (setq parallel-best candidate))
      (setq points (list (car a) (cadr a) (car b) (cadr b)))
      (if (not (equal (caddr a) 0.0 1e-14)) (setq points (cons (TFO:EdgePoint a 0.5) points)))
      (if (not (equal (caddr b) 0.0 1e-14)) (setq points (cons (TFO:EdgePoint b 0.5) points)))
      (setq points (TFO:PatchHull points))
      (if (and points (> (setq area (abs (TFO:LoopArea points))) (* tolerance_fo_ tolerance_fo_)))
        (progn
          (setq candidate (list (TFO:EdgeDistance a b) points area))
          (if (TFO:BetterPatch candidate fallback-best) (setq fallback-best candidate))))))
  (if parallel-best parallel-best fallback-best))

;;; A minimum spanning set of local patches joins all components. Open source
;;; edges outside the existing areas participate too, so they are not omitted.
(defun TFO:Overall (curves loops / groups boundaries vertices curve edge index connected remaining
                               a b candidate best best-node patches work result max-gap a-edge b-edge)
  (foreach vertices loops (setq boundaries (cons (TFO:LoopEdges vertices T) boundaries)))
  (setq groups boundaries)
  (foreach curve curves
    (foreach edge (TFO:EntityEdges curve)
      (if (not (TFO:EdgeCovered edge boundaries)) (setq groups (append groups (list (list edge)))))))
  (if (> (length groups) 1)
    (progn
      (setq index 1 connected '(0) max-gap 0.0)
      (repeat (1- (length groups)) (setq remaining (cons index remaining) index (1+ index)))
      (while remaining
        (setq best nil best-node nil)
        (foreach a connected
          (foreach b remaining
            (setq candidate (TFO:Bridge (nth a groups) (nth b groups)))
            (if (TFO:BetterPatch candidate best) (setq best candidate best-node b))))
        (TFO:Require best "Cannot join all selected geometry into an overall area; check degenerate edges.")
        (setq patches (cons (cadr best) patches) max-gap (max max-gap (car best))
              connected (cons best-node connected)
              remaining (vl-remove best-node remaining)))
      ;; Close the other panel seams at the inferred joining scale too. A
      ;; spanning tree alone leaves exterior slots in a two-row panel grid.
      ;; Existing concavities wider than these joins are not filled wholesale.
      (setq a 0)
      (repeat (length groups)
        (setq b (1+ a))
        (while (< b (length groups))
          (foreach a-edge (nth a groups)
            (foreach b-edge (nth b groups)
              (setq candidate (TFO:ParallelPatch a-edge b-edge))
              (if (and candidate (<= (car candidate) (+ max-gap tolerance_fo_)))
                (setq patches (cons (cadr candidate) patches)))))
          (setq b (1+ b)))
        (setq a (1+ a)))
      (foreach vertices (append loops patches)
        (setq work (cons (TFO:Make (TFO:LWData vertices tfo-elevation tfo-work-layer)) work)))
      (setq result (TFO:GeometryLoops work))
      (TFO:Require (= (length result) 1) "Overall joining did not produce one closed boundary. Check the gap connections.")
      result)
    loops))

(defun TFO:Layer (name color / data)
  (if (setq data (tblsearch "LAYER" name))
    (TFO:Require (and (= 0 (logand 5 (TFO:Get 70 data 0))) (> (TFO:Get 62 data 7) 0))
      (strcat "Output layer is locked, frozen or off: " name))
    (TFO:Require (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord")
      '(100 . "AcDbLayerTableRecord") (cons 2 name) '(70 . 0) (cons 62 color) '(6 . "Continuous")))
      (strcat "Cannot create layer: " name))) name)

(defun TFO:CheckBlockTags (name required / definition child data tags tag)
  (setq definition (tblsearch "BLOCK" name))
  (TFO:Require (and definition (= 0 (logand 124 (TFO:Get 70 definition 0))))
    (strcat "Not a local attribute block: " name))
  (setq child (cdr (assoc -2 definition)))
  (while (and child (/= "ENDBLK" (TFO:Get 0 (setq data (entget child)) "")))
    (if (and (= "ATTDEF" (cdr (assoc 0 data))) (= 0 (logand 2 (TFO:Get 70 data 0))))
      (setq tags (cons (strcase (TFO:Get 2 data "")) tags)))
    (setq child (entnext child)))
  (foreach tag required
    (TFO:Require (= 1 (length (vl-remove-if-not '(lambda (item) (= item tag)) tags)))
      (strcat "Block " name " must contain exactly one editable " tag " attribute. No new block name was created.")))
  name)

(defun TFO:LabelBlock (/ name)
  (setq name block_length_)
  ;; Always use this exact name. Existing geometry, style and base point win.
  (if (not (tblsearch "BLOCK" name))
    (progn
      (TFO:Require (tblsearch "STYLE" style_txt_) (strcat "Text style not found: " style_txt_))
      (TFO:Require (entmake (list '(0 . "BLOCK") (cons 2 name) '(70 . 2) '(10 0.0 0.0 0.0)))
        "Cannot create label block.")
      (entmake (list '(0 . "ATTDEF") '(8 . "0") '(62 . 0) '(10 0.0 0.0 0.0)
        '(11 0.0 0.0 0.0) '(40 . 1.0) '(1 . "") '(2 . "LENGTH") '(3 . "Facade edge length")
        '(70 . 0) '(72 . 1) '(74 . 2) (cons 7 style_txt_)))
      (TFO:Require (entmake '((0 . "ENDBLK"))) "Cannot finish label block.")))
  (TFO:CheckBlockTags name '("LENGTH")))

;;; Let AutoCAD instantiate attributes from the existing block definition.
;;; This preserves custom ATTDEF positions, text styles, base points and extra
;;; attributes. Only known values on the NEW reference are changed by tag.
(defun TFO:InsertAttributes (block point scale rotation values layer color /
                                 saved pair world switched before result entity data attribute value)
  (setq saved (mapcar '(lambda (name) (cons name (getvar name)))
    '("ATTREQ" "ATTDIA" "ANGBASE" "ANGDIR" "AUNITS" "UCSFOLLOW" "CLAYER"))
        world (and (equal (getvar "UCSORG") '(0.0 0.0 0.0) 1e-12)
                   (equal (getvar "UCSXDIR") '(1.0 0.0 0.0) 1e-12)
                   (equal (getvar "UCSYDIR") '(0.0 1.0 0.0) 1e-12))
        before (entlast))
  (setq result (vl-catch-all-apply
    '(lambda ()
      (setvar "ATTREQ" 0) (setvar "ATTDIA" 0) (setvar "ANGBASE" 0.0)
      (setvar "ANGDIR" 0) (setvar "AUNITS" 0) (setvar "UCSFOLLOW" 0) (setvar "CLAYER" layer)
      (if (not world) (progn (command-s "_.UCS" "_World") (setq switched T)))
      (command-s "_.-INSERT" block "_Scale" scale "_Rotate"
        (rtos (* rotation (/ 180.0 pi)) 2 12) "_non" point))))
  (setq entity (entlast))
  (if (and entity (not (eq entity before)) (= "INSERT" (TFO:Get 0 (entget entity) "")))
    (setq tfo-output (cons entity tfo-output))
    (setq entity nil))
  (if switched (command-s "_.UCS" "_Previous"))
  (foreach pair saved (setvar (car pair) (cdr pair)))
  (TFO:Require (and entity (not (vl-catch-all-error-p result)))
    (strcat "Cannot insert existing block: " block))
  (setq data (vl-remove-if '(lambda (pair) (member (car pair) '(62 420 430))) (entget entity)))
  (TFO:Require (entmod (append data (list (cons 62 color)))) "Cannot set block reference color.")
  (setq attribute entity)
  (while (and (setq attribute (entnext attribute))
    (/= "SEQEND" (TFO:Get 0 (setq data (entget attribute)) "")))
    (if (and (= "ATTRIB" (cdr (assoc 0 data)))
      (setq value (assoc (strcase (TFO:Get 2 data "")) values)))
      (TFO:Require (entmod (subst (cons 1 (cdr value)) (assoc 1 data) data))
        (strcat "Cannot update attribute " (car value) " in " block))))
  (entupd entity) entity)

(defun TFO:Label (block point rotation edge-length / value)
  (setq value (strcat prefix_txt_ "_" (rtos (* edge-length factor_length_) 2 precision_txt_)))
  (TFO:InsertAttributes block point height_txt_ rotation (list (cons "LENGTH" value)) layer_txt_ color_txt_))

;;; Unit-height row positions, relative to the information block insertion.
(defun TFO:InfoRows ()
  (list (list "AREA" (* 1.5 spacing_info_)) (list "MAT" (* 0.5 spacing_info_))
        (list "STATION" (* -0.5 spacing_info_)) (list "FLOOR" (* -1.5 spacing_info_))))

(defun TFO:InfoSchema (/ result row label-point value-point)
  (foreach row (TFO:InfoRows)
    (setq label-point (list -6.5 (cadr row) 0.0) value-point (list 0.0 (cadr row) 0.0))
    (setq result (append result
      (list
        (list '(0 . "TEXT") '(8 . "0") '(62 . 0) (cons 10 label-point) (cons 11 label-point)
          '(40 . 1.0) (cons 1 (strcat (car row) ":")) '(50 . 0.0) '(72 . 0) '(73 . 2) (cons 7 style_txt_))
        (list '(0 . "ATTDEF") '(8 . "0") '(62 . 0) (cons 10 value-point) (cons 11 value-point)
          '(40 . 1.0) '(1 . "") (cons 2 (car row)) (cons 3 (car row)) '(50 . 0.0)
          '(70 . 0) '(72 . 0) '(74 . 2) (cons 7 style_txt_)))))) result)

(defun TFO:InfoBlock (/ name schema data ok finished)
  (setq name block_info_)
  (if (not (tblsearch "BLOCK" name))
    (progn
      (TFO:Require (tblsearch "STYLE" style_txt_) (strcat "Text style not found: " style_txt_))
      (setq schema (TFO:InfoSchema))
      (TFO:Require (entmake (list '(0 . "BLOCK") (cons 2 name) '(70 . 2) '(10 0.0 0.0 0.0)))
        "Cannot create information block.")
      (setq ok T)
      (foreach data schema (if (not (entmake data)) (setq ok nil)))
      (setq finished (entmake '((0 . "ENDBLK"))))
      (TFO:Require (and ok finished) "Cannot finish information block definition.")))
  (TFO:CheckBlockTags name '("AREA" "MAT" "STATION" "FLOOR")))

;;; Find a point inside even a concave outline. Prefer its actual bounding-box
;;; center; if outside, use the widest interior interval on the center scanline.
;;; Circular-arc extrema and crossings are evaluated without tessellation.
(defun TFO:InfoPoint (vertices / edges points edge arc theta p xs ys lo hi middle y
                              ray cuts point rest candidate best width best-width boundary)
  (setq edges (TFO:LoopEdges vertices T))
  (foreach edge edges
    (setq points (cons (car edge) points))
    (if (not (equal (caddr edge) 0.0 1e-14))
      (progn
        (setq arc (TFO:Arc (car edge) (cadr edge) (caddr edge)))
        (foreach theta (list 0.0 (/ pi 2.0) pi (* 1.5 pi))
          (setq p (polar (car arc) theta (cadr arc)))
          (if (TFO:EdgeParam edge p) (setq points (cons p points)))))))
  (setq xs (mapcar 'car points) ys (mapcar 'cadr points)
        lo (list (apply 'min xs) (apply 'min ys)) hi (list (apply 'max xs) (apply 'max ys))
        middle (mapcar '(lambda (a b) (/ (+ a b) 2.0)) lo hi))
  (foreach edge edges (if (TFO:EdgeParam edge middle) (setq boundary T)))
  (if (and (not boundary) (TFO:Inside middle edges))
    (setq best middle)
    (progn
      (setq y (cadr middle))
      (foreach edge edges
        (if (equal y (cadar edge) tolerance_fo_) (setq y (+ y (* 0.371 tolerance_fo_)))))
      (setq ray (list (list (- (car lo) 1.0) y) (list (+ (car hi) 1.0) y) 0.0))
      (foreach edge edges
        (foreach point (TFO:Intersections edge ray) (setq cuts (cons (car point) cuts))))
      (setq rest (vl-sort cuts '<))
      (while (cdr rest)
        (setq width (- (cadr rest) (car rest)) candidate (list (/ (+ (car rest) (cadr rest)) 2.0) y))
        (if (and (> width tolerance_fo_) (TFO:Inside candidate edges)
                 (or (null best-width) (> width best-width)))
          (setq best candidate best-width width))
        (setq rest (cdr rest)))))
  (TFO:Require best "Could not find an interior point for the information block.")
  (append (TFO:Add best offset_info_) (list tfo-elevation)))

(defun TFO:Info (block point outline-area / values)
  (setq values (list (cons "AREA" (rtos (* outline-area factor_area_) 2 precision_area_))
    (cons "MAT" mat_txt_) (cons "STATION" station_txt_) (cons "FLOOR" floor_txt_)))
  (TFO:InsertAttributes block point height_info_ 0.0 values layer_info_ color_info_))

(defun TFO:EdgeLength (p q bulge / arc)
  (if (equal bulge 0.0 1e-14)
    (distance p q)
    (progn (setq arc (TFO:Arc p q bulge)) (* (cadr arc) (abs (caddr arc))))))

;;; Rank by actual edge length, before unit conversion or display rounding.
;;; Distinct indices preserve equally long sides in vl-sort. Exact ties use
;;; vertex order, so LONGEST2 always selects exactly two sides, even on squares.
(defun TFO:LabelIndices (vertices / index count ranked item selected)
  (setq index 0 count (length vertices))
  (repeat count
    (setq item (nth index vertices)
      ranked (cons (cons index (TFO:EdgeLength (car item)
        (car (nth (rem (1+ index) count) vertices)) (cadr item))) ranked)
      index (1+ index)))
  (if (= (strcase label_mode_) "LONGEST2")
    (progn
      (setq ranked (vl-sort ranked '(lambda (a b)
        (if (= (cdr a) (cdr b)) (< (car a) (car b)) (> (cdr a) (cdr b))))))
      (repeat (min 2 count)
        (setq selected (cons (caar ranked) selected) ranked (cdr ranked))))
    (setq selected (mapcar 'car ranked)))
  (reverse selected))

(defun TFO:Emit (vertices block info-block / data outline index p q bulge arc edge-length midpoint tangent rotation side position labels label-indices info)
  (setq data (TFO:LWData vertices tfo-elevation layer_outline_))
  (TFO:Require (entmake (append data (list (cons 62 color_outline_)))) "Cannot create output polyline.")
  (setq outline (entlast) tfo-output (cons outline tfo-output) index 0
        side (if (> (TFO:LoopArea vertices) 0.0) -1.0 1.0)
        label-indices (if block (TFO:LabelIndices vertices)))
  (repeat (length vertices)
    (if (member index label-indices)
      (progn
        (setq p (car (nth index vertices)) q (car (nth (rem (1+ index) (length vertices)) vertices))
              bulge (cadr (nth index vertices)) edge-length (TFO:EdgeLength p q bulge))
        (if (equal bulge 0.0 1e-14)
          (setq midpoint (mapcar '(lambda (a b) (/ (+ a b) 2.0)) p q) tangent (angle p q))
          (progn (setq arc (TFO:Arc p q bulge)
            midpoint (polar (car arc) (+ (nth 3 arc) (/ (caddr arc) 2.0)) (cadr arc))
            tangent (+ (nth 3 arc) (/ (caddr arc) 2.0) (if (> bulge 0.0) (/ pi 2.0) (- (/ pi 2.0)))))))
        (setq position (append (TFO:XY (polar midpoint (+ tangent (* side (/ pi 2.0)))
          (+ offset_txt_ (/ height_txt_ 2.0)))) (list tfo-elevation))
              rotation (TFO:Angle tangent))
        (if (and (> rotation (+ (/ pi 2.0) 1e-10)) (<= rotation (+ (* 1.5 pi) 1e-10)))
          (setq rotation (TFO:Angle (+ rotation pi))))
        (setq labels (cons (TFO:Label block position rotation edge-length) labels))))
    (setq index (1+ index)))
  (setq info (TFO:Info info-block (TFO:InfoPoint vertices) (abs (TFO:LoopArea vertices))))
  (list outline (reverse labels) info))

(defun TFO:Execute (ss / index entity curves loops block info-block result workbase)
  (TFO:Require (and (= (type prefix_txt_) 'STR) (> (strlen prefix_txt_) 0)) "prefix_txt_ must be a nonempty string.")
  (TFO:Require (and (= (type block_info_) 'STR) (snvalid block_info_)
    (= (type block_length_) 'STR) (snvalid block_length_)
    (/= (strcase block_info_) (strcase block_length_)))
    "block_info_ and block_length_ must be valid, separate block names.")
  (TFO:Require (and (listp exception_blocks_)
    (vl-every '(lambda (name) (and (= (type name) 'STR) (> (strlen name) 0))) exception_blocks_))
    "exception_blocks_ must be a list of nonempty block-name strings, or an empty list.")
  (TFO:Require (and (= (type label_mode_) 'STR) (member (strcase label_mode_) '("NONE" "ALL" "LONGEST2")))
    "label_mode_ must be NONE, ALL or LONGEST2.")
  (TFO:Require (and (= (type outline_mode_) 'STR) (member (strcase outline_mode_) '("OVERALL" "SPLIT")))
    "outline_mode_ must be OVERALL or SPLIT.")
  (TFO:Require (and (numberp tolerance_fo_) (> tolerance_fo_ 0.0)) "Invalid geometry tolerance.")
  (if (/= (strcase label_mode_) "NONE")
    (TFO:Require (and (numberp height_txt_) (> height_txt_ 0.0)
      (numberp offset_txt_) (>= offset_txt_ 0.0) (numberp factor_length_) (> factor_length_ 0.0)
      (= (type precision_txt_) 'INT) (<= 0 precision_txt_ 8)) "Invalid text/length preset values."))
  (TFO:Require (and (numberp factor_area_) (> factor_area_ 0.0)
    (= (type precision_area_) 'INT) (<= 0 precision_area_ 8)
    (numberp height_info_) (> height_info_ 0.0) (numberp spacing_info_) (> spacing_info_ 0.0)
    (listp offset_info_) (= (length offset_info_) 2) (numberp (car offset_info_)) (numberp (cadr offset_info_))
    (= (type mat_txt_) 'STR) (= (type station_txt_) 'STR) (= (type floor_txt_) 'STR))
    "Invalid information preset: check area factor/precision, text size, XY offset and string values.")
  (setq workbase "TA-FACADE-WORK" tfo-work-layer workbase index 1)
  (while (and (setq entity (tblsearch "LAYER" tfo-work-layer))
              (or (/= 0 (logand 5 (TFO:Get 70 entity 0))) (< (TFO:Get 62 entity 7) 0)))
    (setq index (1+ index) tfo-work-layer (strcat workbase "-" (itoa index))))
  (TFO:Layer tfo-work-layer 8)
  (setq index 0)
  (repeat (sslength ss)
    (TFO:Read (ssname ss index) (TFO:Identity) 0) (setq index (1+ index)))
  (setq curves (reverse tfo-temp))
  (TFO:Require curves "No visible supported outline geometry remains after skipping exception_blocks_.")
  (if (= (strcase outline_mode_) "OVERALL") (setq curves (TFO:CloseOpenEnds curves)))
  (setq loops (TFO:GeometryLoops curves))
  (TFO:Require loops "No valid outer outline was found.")
  (if (= (strcase outline_mode_) "OVERALL") (setq loops (TFO:Overall curves loops)))
  (TFO:CheckCoverage curves loops)
  (TFO:Layer layer_outline_ color_outline_)
  (TFO:Layer layer_info_ color_info_)
  (if (/= (strcase label_mode_) "NONE")
    (progn (TFO:Layer layer_txt_ color_txt_) (setq block (TFO:LabelBlock))))
  (setq info-block (TFO:InfoBlock))
  (foreach entity loops (setq result (cons (TFO:Emit entity block info-block) result)))
  (reverse result))

;;; All disposable entities are tracked in this dynamic scope. Failure removes
;;; partial output, and the original selection and block definitions stay intact.
(defun TFO:Build (ss / tfo-temp tfo-output tfo-elevation tfo-work-layer tfo-problem
                        saved result entity pair group)
  (setq saved (mapcar '(lambda (name) (cons name (getvar name))) '("CMDECHO" "OSMODE" "DELOBJ" "DIMZIN")))
  ;; Start an explicit group even inside AutoCAD's automatic command group.
  ;; UNDOCTL bit 8 alone does not guarantee that entmake edits are grouped.
  (command "_.UNDO" "_Begin") (setq group T)
  (setvar "CMDECHO" 0) (setvar "OSMODE" 0) (setvar "DELOBJ" 0) (setvar "DIMZIN" 0)
  (setq result (vl-catch-all-apply 'TFO:Execute (list ss)))
  (foreach entity tfo-temp (if (entget entity) (entdel entity)))
  (if (vl-catch-all-error-p result)
    (progn
      (foreach entity tfo-output (if (entget entity) (entdel entity)))
      (princ (strcat "\nFO: " (if tfo-problem tfo-problem (vl-catch-all-error-message result))))
      (setq result nil)))
  (foreach pair saved (setvar (car pair) (cdr pair)))
  (if group (command "_.UNDO" "_End")) result)

;;; Bind locally so stale ALL/LONGEST2 globals from an earlier loaded version
;;; cannot re-enable length labels in FO. Geometry and INFO share the same undo.
(defun TFO:CommandBuild (ss / label_mode_)
  (setq label_mode_ "NONE") (TFO:Build ss))

(defun c:FO (/ ss result)
  (setq ss (ssget "_I" '((0 . "INSERT,LWPOLYLINE,POLYLINE,LINE,ARC,CIRCLE"))))
  (if (not ss)
    (progn (princ "\nSelect facade blocks and polylines: ")
      (setq ss (ssget '((0 . "INSERT,LWPOLYLINE,POLYLINE,LINE,ARC,CIRCLE"))))))
  (if (and ss (setq result (TFO:CommandBuild ss)))
    (princ (strcat "\nFO: created " (itoa (length result)) " closed outline(s), "
      (itoa (length result)) " AREA/MAT/STATION/FLOOR info block(s). Block: " block_info_))) (princ))

(defun c:FACADEOUTLINE () (c:FO))
(princ "\nTA_FACADE_OUTLINE v1.8 loaded. Commands: FO / FACADEOUTLINE (no LENGTH labels).")
(princ)
