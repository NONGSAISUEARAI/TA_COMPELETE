;;; SHW v2.1 - hidden-line overlays through selected WIPEOUT masks.
;;; AutoCAD for Windows, Visual LISP / ActiveX. Standalone; no dependencies.
;;; All working geometry is copied into the active space and deleted afterwards.
;;; Block definitions and original entities are never edited or exploded.
;;; Geometry is evaluated in WCS XY (plan view), independent of the current UCS.
(vl-load-com)

(if (not *TA:SHW-Scale*) (setq *TA:SHW-Scale* 1.0))
(if (not *TA:SHW-Chord*) (setq *TA:SHW-Chord* 0.05))
(setq TA:SHW-Layer "TA-HIDDEN-OVERLAY")
(setq TA:SHW-Version "2.1")

(defun TA:SHW:Delete (obj)
  (vl-catch-all-apply 'vla-Delete (list obj)))

(defun TA:SHW:Track (obj)
  (setq shw-temp (cons obj shw-temp)) obj)

(defun TA:SHW:Require (ok message)
  (if (not ok) (progn (setq shw-problem message) (quit))) ok)

(defun TA:SHW:List (value)
  (if (= (type value) 'VARIANT) (setq value (vlax-variant-value value)))
  (if (= (type value) 'SAFEARRAY)
    (vlax-safearray->list value) value))

(defun TA:SHW:MoveZ (obj dz)
  (if (not (equal dz 0.0 1e-12))
    (vla-Move obj (vlax-3d-point '(0.0 0.0 0.0))
                  (vlax-3d-point (list 0.0 0.0 dz)))) obj)

(defun TA:SHW:Visible (obj / data layer)
  (setq data (entget (vlax-vla-object->ename obj))
        layer (tblsearch "LAYER" (cdr (assoc 8 data))))
  (and (not (eq 1 (cdr (assoc 60 data))))
       (>= (cdr (assoc 62 layer)) 0)
       (= 0 (logand 1 (cdr (assoc 70 layer))))))

(defun TA:SHW:Clipped (obj / dict filters)
  (and (setq dict (cdr (assoc 360 (entget (vlax-vla-object->ename obj)))))
       (setq filters (dictsearch dict "ACAD_FILTER"))
       (dictsearch (cdr (assoc -1 filters)) "SPATIAL")))

;;; Some nonuniform assemblies (particularly those containing WIPEOUT) cannot
;;; be exploded even by AutoCAD. Read their definitions without editing them,
;;; copy only relevant leaves to the active space, and compose insert matrices.
(defun TA:SHW:Identity ()
  '((1.0 0.0 0.0 0.0) (0.0 1.0 0.0 0.0)
    (0.0 0.0 1.0 0.0) (0.0 0.0 0.0 1.0)))

(defun TA:SHW:MatMul (a b / columns)
  (setq columns (list (mapcar 'car b) (mapcar 'cadr b) (mapcar 'caddr b)
    (mapcar '(lambda (row) (nth 3 row)) b)))
  (mapcar '(lambda (row)
    (mapcar '(lambda (column) (apply '+ (mapcar '* row column))) columns)) a))

(defun TA:SHW:ApplyMatrix (matrix point vector / p)
  (setq p (append point (list (if vector 0.0 1.0))))
  (mapcar '(lambda (row) (apply '+ (mapcar '* row p)))
    (list (car matrix) (cadr matrix) (caddr matrix))))

(defun TA:SHW:InsertMatrix (obj def / normal x y z c s sx sy sz origin insertion shift)
  (setq normal (TA:SHW:List (vla-get-Normal obj))
        x (trans '(1.0 0.0 0.0) normal 0 T)
        y (trans '(0.0 1.0 0.0) normal 0 T)
        c (cos (vla-get-Rotation obj)) s (sin (vla-get-Rotation obj))
        sx (vla-get-XScaleFactor obj) sy (vla-get-YScaleFactor obj)
        sz (vla-get-ZScaleFactor obj)
        z (mapcar '(lambda (n) (* sz n)) normal)
        origin (TA:SHW:List (vla-get-Origin def))
        insertion (TA:SHW:List (vla-get-InsertionPoint obj)))
  (setq shift (mapcar '(lambda (xx yy) (* sy (+ (* (- s) xx) (* c yy)))) x y)
        x (mapcar '(lambda (xx yy) (* sx (+ (* c xx) (* s yy)))) x y)
        y shift
        shift (mapcar '- insertion
          (mapcar '(lambda (xx yy zz)
            (+ (* xx (car origin)) (* yy (cadr origin)) (* zz (caddr origin)))) x y z)))
  (list (list (car x) (car y) (car z) (car shift))
        (list (cadr x) (cadr y) (cadr z) (cadr shift))
        (list (caddr x) (caddr y) (caddr z) (caddr shift))
        '(0.0 0.0 0.0 1.0)))

(defun TA:SHW:CopyToSpace (obj / array copies)
  (setq array (vlax-make-safearray vlax-vbObject '(0 . 0)))
  (vlax-safearray-put-element array 0 obj)
  (setq copies (TA:SHW:List (vla-CopyObjects shw-doc (vlax-make-variant array) shw-space)))
  (TA:SHW:Require (= 1 (length copies)) "Could not copy block geometry to the active space.")
  (TA:SHW:Track (car copies)))

(defun TA:SHW:PositiveAngle (y x / a)
  (setq a (atan y x)) (if (< a 0.0) (+ a (* 2.0 pi)) a))

;;; Exact affine image of a circle/arc. Principal axes come from the symmetric
;;; 2x2 matrix A*A^T + B*B^T. A reflection reverses the ellipse interval.
(defun TA:SHW:AffineEllipse (obj matrix / normal r a b center xx xy yy theta disc
                                     major minor ux uy phi0 phi1 p0 p1 out)
  (setq normal (TA:SHW:List (vla-get-Normal obj)) r (vla-get-Radius obj)
        a (TA:SHW:ApplyMatrix matrix
          (mapcar '(lambda (v) (* r v)) (trans '(1.0 0.0 0.0) normal 0 T)) T)
        b (TA:SHW:ApplyMatrix matrix
          (mapcar '(lambda (v) (* r v)) (trans '(0.0 1.0 0.0) normal 0 T)) T)
        center (TA:SHW:ApplyMatrix matrix (TA:SHW:List (vla-get-Center obj)) nil))
  (TA:SHW:Require (and (equal (caddr a) 0.0 shw-eps) (equal (caddr b) 0.0 shw-eps))
    "Affine curved geometry must be parallel to WCS XY.")
  (setq xx (+ (* (car a) (car a)) (* (car b) (car b)))
        xy (+ (* (car a) (cadr a)) (* (car b) (cadr b)))
        yy (+ (* (cadr a) (cadr a)) (* (cadr b) (cadr b)))
        disc (sqrt (+ (* (- xx yy) (- xx yy)) (* 4.0 xy xy)))
        theta (* 0.5 (atan (* 2.0 xy) (- xx yy)))
        major (sqrt (/ (+ xx yy disc) 2.0))
        minor (sqrt (max 0.0 (/ (- (+ xx yy) disc) 2.0)))
        ux (cos theta) uy (sin theta))
  (TA:SHW:Require (> minor shw-eps) "Degenerate block scale collapses a curve.")
  (setq out (TA:SHW:Track (vla-AddEllipse shw-space (vlax-3d-point center)
    (vlax-3d-point (list (* major ux) (* major uy) 0.0)) (/ minor major))))
  (if (= "AcDbArc" (vla-get-ObjectName obj))
    (progn
      (setq p0 (mapcar '- (TA:SHW:ApplyMatrix matrix (vlax-curve-getStartPoint obj) nil) center)
            p1 (mapcar '- (TA:SHW:ApplyMatrix matrix (vlax-curve-getEndPoint obj) nil) center)
            phi0 (TA:SHW:PositiveAngle (/ (+ (* (- uy) (car p0)) (* ux (cadr p0))) minor)
                                      (/ (+ (* ux (car p0)) (* uy (cadr p0))) major))
            phi1 (TA:SHW:PositiveAngle (/ (+ (* (- uy) (car p1)) (* ux (cadr p1))) minor)
                                      (/ (+ (* ux (car p1)) (* uy (cadr p1))) major)))
      (if (< (- (* (car a) (cadr b)) (* (cadr a) (car b))) 0.0)
        (progn (vla-put-StartParameter out phi1) (vla-put-EndParameter out phi0))
        (progn (vla-put-StartParameter out phi0) (vla-put-EndParameter out phi1)))))
  out)

(defun TA:SHW:AffinePolyline (obj matrix layer tolerance / *TA:SHW-Chord* gain points coords p out elevation)
  (setq gain (sqrt (apply '+
    (mapcar '(lambda (row) (apply '+ (mapcar '(lambda (v) (* v v))
      (list (car row) (cadr row) (caddr row)))))
      (list (car matrix) (cadr matrix) (caddr matrix)))))
        *TA:SHW-Chord* (/ tolerance (max gain 1e-12))
        points (TA:SHW:Sample obj 0.0 (TA:SHW:Length obj) 0))
  (if (and (vlax-curve-isClosed obj) (equal (car points) (last points) shw-eps))
    (setq points (reverse (cdr (reverse points)))))
  (setq elevation (caddr (TA:SHW:ApplyMatrix matrix (car points) nil)))
  (foreach p points
    (setq p (TA:SHW:ApplyMatrix matrix p nil))
    (TA:SHW:Require (equal (caddr p) elevation shw-eps)
      "Affine geometry must be parallel to WCS XY.")
    (setq coords (append coords (list (car p) (cadr p)))))
  (setq out (TA:SHW:Track (vlax-invoke shw-space 'AddLightWeightPolyline coords)))
  (vla-put-Elevation out elevation)
  (if (vlax-curve-isClosed obj) (vla-put-Closed out :vlax-true))
  (vla-put-Layer out layer) out)

(defun TA:SHW:AffineHatch (obj matrix layer / loops loop transformed proxy array style)
  (setq loops (TA:SHW:HatchLoops obj)
        style (cdr (assoc 75 (entget (vlax-vla-object->ename obj)))))
  (foreach loop loops
    (setq transformed (cons (TA:SHW:AffinePolyline loop matrix layer 0.001) transformed)))
  (setq proxy (TA:SHW:Track (vla-AddHatch shw-space 0 "SOLID" :vlax-false 0)))
  (foreach loop transformed
    (setq array (vlax-make-safearray vlax-vbObject '(0 . 0)))
    (vlax-safearray-put-element array 0 loop)
    (vla-AppendOuterLoop proxy array))
  (vla-put-HatchStyle proxy style) (vla-Evaluate proxy)
  (vla-put-Layer proxy layer) proxy)

(defun TA:SHW:AffineLeaf (obj matrix layer / copy result parts child objects kind)
  (setq kind (vla-get-ObjectName obj) copy (TA:SHW:CopyToSpace obj))
  (vla-put-Layer copy layer)
  (setq result (vl-catch-all-apply 'vla-TransformBy (list copy (vlax-tmatrix matrix))))
  (if (not (vl-catch-all-error-p result)) (list copy)
    (cond
      ((= kind "AcDbLine")
       (TA:SHW:Delete copy)
       (setq copy (TA:SHW:Track (vla-AddLine shw-space
         (vlax-3d-point (TA:SHW:ApplyMatrix matrix (vlax-curve-getStartPoint obj) nil))
         (vlax-3d-point (TA:SHW:ApplyMatrix matrix (vlax-curve-getEndPoint obj) nil)))))
       (vla-put-Layer copy layer) (list copy))
      ((member kind '("AcDbArc" "AcDbCircle"))
       (TA:SHW:Delete copy)
       (setq copy (TA:SHW:AffineEllipse obj matrix))
       (vla-put-Layer copy layer) (list copy))
      ((member kind '("AcDbPolyline" "AcDb2dPolyline" "AcDb3dPolyline"))
       (setq parts (TA:SHW:List (vla-Explode copy)))
       (foreach child parts (TA:SHW:Track child))
       (foreach child parts
         (setq objects (append objects (TA:SHW:AffineLeaf child matrix layer))))
       objects)
      ((member kind '("AcDbEllipse" "AcDbSpline"))
       (TA:SHW:Delete copy)
       (list (TA:SHW:AffinePolyline obj matrix layer *TA:SHW-Chord*)))
      ((= kind "AcDbHatch")
       (setq result (TA:SHW:AffineHatch copy matrix layer))
       (TA:SHW:Delete copy) (list result))
      (T
       (TA:SHW:Require nil (strcat "Cannot transform " kind ": "
         (vl-catch-all-error-message result)))))))

(defun TA:SHW:AffineLeaves (obj matrix inherited depth / kind layer def child result local)
  (setq kind (vla-get-ObjectName obj) layer (vla-get-Layer obj))
  (if (= layer "0") (setq layer inherited))
  (if (TA:SHW:Visible obj)
    (cond
      ((= kind "AcDbBlockReference")
       (TA:SHW:Require (< depth 32) "Block nesting exceeds 32 levels.")
       (setq def (vla-Item (vla-get-Blocks shw-doc) (vla-get-Name obj)))
       (TA:SHW:Require (and (= :vlax-false (vla-get-IsXRef def))
                           (not (TA:SHW:Clipped obj))) "Xref / XCLIP is not supported.")
       (setq local (TA:SHW:MatMul matrix (TA:SHW:InsertMatrix obj def)))
       (vlax-for child def
         (setq result (append result (TA:SHW:AffineLeaves child local layer (1+ depth))))) result)
      ((or (and (= shw-role "Source") (TA:SHW:Curve obj))
           (and (= shw-role "Mask")
                (or (= kind "AcDbWipeout")
                    (and (not (= shw-mask-kind "Wipeout")) (= kind "AcDbHatch")))))
       (TA:SHW:AffineLeaf obj matrix layer))
      (T nil))))

;;; Recursively explode ONLY disposable copies. ActiveX applies each reference's
;;; insertion, rotation, mirror and scale, including nested references.
(defun TA:SHW:Leaves (obj depth / kind children result child def shw-parent-layer)
  (setq kind (vla-get-ObjectName obj))
  (cond
    ((not (TA:SHW:Visible obj)) nil)
    ((= kind "AcDbBlockReference")
     (TA:SHW:Require (< depth 32) "Block nesting exceeds 32 levels.")
     (setq def (vla-Item (vla-get-Blocks shw-doc) (vla-get-Name obj)))
     (TA:SHW:Require (= :vlax-false (vla-get-IsXRef def))
       "Xrefs are not supported. Select ordinary blocks or drawing curves.")
     (TA:SHW:Require (not (TA:SHW:Clipped obj))
       "XCLIP blocks are not supported. Use an unclipped copy for this version.")
     (setq shw-parent-layer (vla-get-Layer obj))
     (if (and (equal (abs (vla-get-XScaleFactor obj)) (abs (vla-get-YScaleFactor obj)) 1e-10)
              (equal (abs (vla-get-XScaleFactor obj)) (abs (vla-get-ZScaleFactor obj)) 1e-10))
       (setq children (vl-catch-all-apply
         '(lambda () (TA:SHW:List (vla-Explode obj))))))
     (if (or (null children) (vl-catch-all-error-p children))
       (setq result (TA:SHW:AffineLeaves obj (TA:SHW:Identity) shw-parent-layer depth))
       (progn
         (foreach child children (TA:SHW:Track child))
         (foreach child children
           ;; Layer 0 inherits the insertion's layer, including visibility.
           (if (= "0" (vla-get-Layer child))
             (vla-put-Layer child shw-parent-layer))
           (setq result (append result (TA:SHW:Leaves child (1+ depth)))))))
     result)
    ((= kind "AcDbMInsertBlock")
     (TA:SHW:Require nil "MINSERT arrays are not supported."))
    (T (list obj))))

(defun TA:SHW:Copies (entities shw-role / result en obj)
  (foreach en entities
    (setq obj (TA:SHW:Track (vla-Copy (vlax-ename->vla-object en))))
    (setq result (append result (TA:SHW:Leaves obj 0)))) result)

;;; Planar objects are translated to z=0 for projected intersections; their
;;; original elevation is stored for output. Tilted / 3D geometry is rejected.
(defun TA:SHW:Flat (obj / lo hi)
  (vla-GetBoundingBox obj 'lo 'hi)
  (setq lo (TA:SHW:List lo) hi (TA:SHW:List hi))
  (TA:SHW:Require (equal (caddr lo) (caddr hi) shw-eps)
    "This version supports 2D geometry parallel to WCS XY only.")
  (TA:SHW:MoveZ obj (- (caddr lo)))
  (caddr lo))

(defun TA:SHW:Curve (obj)
  (member (vla-get-ObjectName obj)
    '("AcDbLine" "AcDbArc" "AcDbCircle" "AcDbEllipse" "AcDbSpline"
      "AcDbPolyline" "AcDb2dPolyline" "AcDb3dPolyline")))

(defun TA:SHW:Sources (objects / result obj kind z parts part)
  (foreach obj objects
    (setq kind (vla-get-ObjectName obj))
    (if (TA:SHW:Curve obj)
      (progn
        (setq z (TA:SHW:Flat obj))
        (if (member kind '("AcDbPolyline" "AcDb2dPolyline" "AcDb3dPolyline"))
          (progn
            (setq parts (TA:SHW:List (vla-Explode obj)))
            (foreach part parts (TA:SHW:Track part))
            (foreach part parts
              (if (TA:SHW:Curve part)
                (setq result (cons (list part z) result)))))
          (setq result (cons (list obj z) result))))
      (setq shw-skipped (1+ shw-skipped)))) result)

(defun TA:SHW:LWLoop (points / coords obj p)
  (foreach p points (setq coords (append coords (list (car p) (cadr p)))))
  (setq obj (TA:SHW:Track
    (vlax-invoke shw-space 'AddLightWeightPolyline coords)))
  (vla-put-Closed obj :vlax-true) obj)

;;; WIPEOUT clip coordinates use image axes: X right, Y down. The WCS V-vector
;;; points UP. Convert Y using image height - 0.5 - clipY; clipY + 0.5 reflects
;;; sloping boundaries and shifts wide, non-square masks vertically. The image
;;; rectangle can exceed the polygon bounds, so polygon maxY is not a substitute
;;; for the pixel height stored in group 13.
;;; Pure coordinate conversion, shared by production and native DXF tests.
(defun TA:SHW:WipeVertices (data / origin u v size verts p a b points pair)
  (setq origin (cdr (assoc 10 data)) u (cdr (assoc 11 data))
        v (cdr (assoc 12 data)) size (cdr (assoc 13 data)))
  (TA:SHW:Require (and origin u v size) "Incomplete WIPEOUT image geometry.")
  (foreach pair data
    (if (= 14 (car pair)) (setq verts (cons (cdr pair) verts))))
  (setq verts (reverse verts))
  (if (= 1 (cdr (assoc 71 data)))
    (progn
      (setq a (car verts) b (cadr verts))
      (TA:SHW:Require (and a b) "Invalid rectangular WIPEOUT boundary.")
      (setq verts (list a (list (car b) (cadr a)) b (list (car a) (cadr b))))))
  (foreach p verts
    (setq points (cons
      (mapcar '+ origin
        (mapcar '(lambda (x) (* x (+ 0.5 (car p)))) u)
        (mapcar '(lambda (x) (* x (- (cadr size) 0.5 (cadr p)))) v)) points)))
  (setq points (reverse points))
  (if (equal (car points) (last points) shw-eps)
    (setq points (reverse (cdr (reverse points)))))
  (TA:SHW:Require (>= (length points) 3) "Invalid WIPEOUT boundary.")
  points)

(defun TA:SHW:WipeLoop (obj)
  (TA:SHW:LWLoop (TA:SHW:WipeVertices (entget (vlax-vla-object->ename obj)))))

(defun TA:SHW:HatchLoops (obj / before en loops new)
  (setq before (entlast))
  (sssetfirst nil nil)
  (command-s "_.HATCHGENERATEBOUNDARY" (vlax-vla-object->ename obj) "")
  (sssetfirst nil nil)
  (setq en (entnext before))
  (while en
    ;; Ignore POLYLINE vertices and SEQEND subentities.
    (if (not (member (cdr (assoc 0 (entget en))) '("VERTEX" "SEQEND")))
      (progn
        (setq new (TA:SHW:Track (vlax-ename->vla-object en)))
        (TA:SHW:Require (and (TA:SHW:Curve new) (vlax-curve-isClosed new))
          "AutoCAD could not generate a closed hatch boundary.")
        (TA:SHW:Flat new)
        (setq loops (cons new loops))))
    (setq en (entnext en)))
  (TA:SHW:Require loops "No boundary was generated for a selected hatch.") loops)

;;; Each mask is (hatch-style loop ...). Evaluate separate masks as a union;
;;; holes belong to their own hatch and must not cancel another mask.
(defun TA:SHW:Masks (objects / masks obj kind loops style use-wipeout)
  ;; A material hatch is not the silhouette masked by a WIPEOUT. In Auto mode
  ;; prefer WIPEOUTs for the entire selection; never add material hatch areas.
  ;; Wipeout mode explicitly refuses a hatch-only selection instead of silently
  ;; producing the tiny material-overlap fragments seen in the reported case.
  (setq use-wipeout
    (or (= shw-mask-kind "Wipeout")
        (and (not (= shw-mask-kind "Hatch"))
             (vl-some '(lambda (o) (= "AcDbWipeout" (vla-get-ObjectName o))) objects))))
  (foreach obj objects
    (setq kind (vla-get-ObjectName obj))
    (cond
      ((and (not use-wipeout) (= kind "AcDbHatch"))
       (TA:SHW:Flat obj)
       (setq style (cdr (assoc 75 (entget (vlax-vla-object->ename obj))))
             loops (TA:SHW:HatchLoops obj))
       (setq masks (cons (cons style loops) masks)))
      ((and use-wipeout (= kind "AcDbWipeout"))
       (TA:SHW:Flat obj)
       (setq masks (cons (list 0 (TA:SHW:WipeLoop obj)) masks))))) masks)

(defun TA:SHW:Unique (values / result value)
  (foreach value (vl-sort values '<)
    (if (or (null result) (> (- value (car result)) shw-eps))
      (setq result (cons value result)))) (reverse result))

(defun TA:SHW:Intersections (a b / raw result)
  (setq raw (vlax-invoke a 'IntersectWith b 0))
  (while raw
    (setq result (cons (list (car raw) (cadr raw) (caddr raw)) result)
          raw (cdddr raw))) (reverse result))

(defun TA:SHW:Length (obj)
  (vlax-curve-getDistAtParam obj (vlax-curve-getEndParam obj)))

(defun TA:SHW:Wrap (d len)
  (while (< d 0.0) (setq d (+ d len)))
  (while (> d len) (setq d (- d len))) d)

;;; Use a non-axis-aligned ray. Native curve intersections keep circular hatch
;;; boundaries exact. Sample both sides of each hit to reject tangencies and
;;; count shared polyline vertices once (including the closed-loop seam).
(defun TA:SHW:InsideLoop (point loop / nearest lo hi reach ray hits hit ds d len
                                           delta pa pb sa sb tries count)
  (setq nearest (vlax-curve-getClosestPointTo loop point))
  (if (> (distance nearest point) shw-eps)
    (progn
      (vla-GetBoundingBox loop 'lo 'hi)
      (setq lo (TA:SHW:List lo) hi (TA:SHW:List hi))
      (if (and (<= (car lo) (car point) (car hi))
               (<= (cadr lo) (cadr point) (cadr hi)))
        (progn
          (setq reach (+ 1.0 (* 3.0 (+ (distance lo hi) (distance lo point))))
                ray (TA:SHW:Track (vla-AddLine shw-space (vlax-3d-point point)
                      (vlax-3d-point
                        (mapcar '+ point (list reach (* reach 0.3713906763541037) 0.0)))))
                hits (TA:SHW:Intersections ray loop))
          (TA:SHW:Delete ray)
          (setq len (TA:SHW:Length loop) count 0)
          (foreach hit hits
            (setq d (vlax-curve-getDistAtPoint loop
                      (vlax-curve-getClosestPointTo loop hit)))
            (if (equal d len shw-eps) (setq d 0.0))
            (setq ds (cons d ds)))
          (foreach d (TA:SHW:Unique ds)
            (setq delta (min (* len 0.00001) (* shw-eps 16.0)) tries 0
                  sa 0.0 sb 0.0)
            (while (and (< tries 18) (or (< (abs sa) shw-eps) (< (abs sb) shw-eps)))
              (setq pa (vlax-curve-getPointAtDist loop (TA:SHW:Wrap (- d delta) len))
                    pb (vlax-curve-getPointAtDist loop (TA:SHW:Wrap (+ d delta) len))
                    sa (- (- (cadr pa) (cadr point))
                          (* 0.3713906763541037 (- (car pa) (car point))))
                    sb (- (- (cadr pb) (cadr point))
                          (* 0.3713906763541037 (- (car pb) (car point))))
                    delta (min (* len 0.1) (* delta 2.0)) tries (1+ tries)))
            (if (< (* sa sb) 0.0) (setq count (1+ count))))
          (= 1 (rem count 2)))))))

(defun TA:SHW:InsideMask (point mask / count loop)
  (setq count 0)
  (foreach loop (cdr mask)
    (if (TA:SHW:InsideLoop point loop) (setq count (1+ count))))
  (cond ((= 2 (car mask)) (> count 0))
        ((= 1 (car mask)) (= count 1))
        (T (= 1 (rem count 2)))))

(defun TA:SHW:Intervals (obj masks / len cuts mask loop hit d rest a b result)
  (setq len (TA:SHW:Length obj) cuts (list 0.0 len))
  (foreach mask masks
    (foreach loop (cdr mask)
      (foreach hit (TA:SHW:Intersections obj loop)
        (setq d (vlax-curve-getDistAtPoint obj
                  (vlax-curve-getClosestPointTo obj hit)))
        (if d (setq cuts (cons (max 0.0 (min len d)) cuts))))))
  (setq rest (TA:SHW:Unique cuts))
  (while (cdr rest)
    (setq a (car rest) b (cadr rest))
    (if (and (> (- b a) shw-eps)
             (vl-some '(lambda (mask)
               (TA:SHW:InsideMask (vlax-curve-getPointAtDist obj (/ (+ a b) 2.0)) mask)) masks))
      ;; Merge adjacent inside intervals so overlapping masks do not duplicate
      ;; output or reset its dash pattern at their internal boundaries.
      (if (and result (equal a (cadar result) shw-eps))
        (setq result (cons (list (caar result) b) (cdr result)))
        (setq result (cons (list a b) result))))
    (setq rest (cdr rest))) (reverse result))

;;; Ellipse / spline output is a chord-tolerance polyline. Quarter samples avoid
;;; a symmetric S-curve appearing straight when only its midpoint is checked.
(defun TA:SHW:ChordDistance (p a b / ab ap divisor ratio nearest)
  (setq ab (mapcar '- b a) ap (mapcar '- p a)
        divisor (apply '+ (mapcar '* ab ab)))
  (if (< divisor 1e-24) (distance p a)
    (progn
      (setq ratio (max 0.0 (min 1.0 (/ (apply '+ (mapcar '* ap ab)) divisor)))
            nearest (mapcar '+ a (mapcar '(lambda (x) (* ratio x)) ab)))
      (distance p nearest))))

(defun TA:SHW:Sample (obj a b depth / pa pb q1 mid q3 err)
  (setq pa (vlax-curve-getPointAtDist obj a) pb (vlax-curve-getPointAtDist obj b)
        q1 (vlax-curve-getPointAtDist obj (+ a (* 0.25 (- b a))))
        mid (vlax-curve-getPointAtDist obj (/ (+ a b) 2.0))
        q3 (vlax-curve-getPointAtDist obj (+ a (* 0.75 (- b a))))
        err (max (TA:SHW:ChordDistance q1 pa pb)
                 (TA:SHW:ChordDistance mid pa pb) (TA:SHW:ChordDistance q3 pa pb)))
  (if (and (< depth 18) (> err *TA:SHW-Chord*))
    (append (TA:SHW:Sample obj a (/ (+ a b) 2.0) (1+ depth))
            (cdr (TA:SHW:Sample obj (/ (+ a b) 2.0) b (1+ depth))))
    (list pa pb)))

(defun TA:SHW:Style (obj / scale pattern global-scale)
  ;; Track immediately so even a property failure rolls the entity back.
  (setq shw-output (cons obj shw-output))
  (vla-put-Layer obj TA:SHW-Layer)
  (vla-put-Color obj 256)
  (vla-put-Linetype obj "ByLayer")
  (setq scale shw-scale)
  (if (eq scale 'Auto)
    (progn
      (setq pattern (cdr (assoc 40 (tblsearch "LTYPE" "HIDDEN")))
            global-scale (getvar "LTSCALE"))
      ;; Fit at least four complete dash/gap periods to each resulting piece.
      ;; Use the loaded definition (metric or imperial), not a hardcoded size.
      (setq scale (/ (TA:SHW:Length obj) (* 4.0 pattern global-scale)))
      (setq scale (max 1e-8 (min 1.0 scale)))))
  (vla-put-LinetypeScale obj scale)
  (vla-put-Lineweight obj -1) obj)

(defun TA:SHW:Emit (obj z interval / a b pa pb kind center radius start end normal
                                           out coords points p)
  (setq a (car interval) b (cadr interval)
        pa (vlax-curve-getPointAtDist obj a) pb (vlax-curve-getPointAtDist obj b)
        kind (vla-get-ObjectName obj))
  (cond
    ((= kind "AcDbLine")
     (setq out (vla-AddLine shw-space (vlax-3d-point pa) (vlax-3d-point pb))))
    ((member kind '("AcDbArc" "AcDbCircle"))
     (setq center (TA:SHW:List (vla-get-Center obj)) radius (vla-get-Radius obj))
     (if (equal (- b a) (* 2.0 pi radius) shw-eps)
       (setq out (vla-AddCircle shw-space (vlax-3d-point center) radius))
       (progn
         (setq normal (TA:SHW:List (vla-get-Normal obj))
               start (angle center pa) end (angle center pb))
         (if (< (caddr normal) 0.0) (setq start (angle center pb) end (angle center pa)))
         (setq out (vla-AddArc shw-space (vlax-3d-point center) radius start end)))))
    (T
     (setq points (TA:SHW:Sample obj a b 0))
     (foreach p points (setq coords (append coords (list (car p) (cadr p)))))
     (setq out (vlax-invoke shw-space 'AddLightWeightPolyline coords))))
  (TA:SHW:Style out)
  (if (= "AcDbPolyline" (vla-get-ObjectName out))
    (vla-put-LinetypeGeneration out :vlax-true))
  (TA:SHW:MoveZ out z) out)

(defun TA:SHW:PrepareLayer (/ types result filename layer)
  (setq types (vla-get-Linetypes shw-doc))
  (if (not (tblsearch "LTYPE" "HIDDEN"))
    (foreach filename '("acadiso.lin" "acad.lin")
      (if (and (not (tblsearch "LTYPE" "HIDDEN")) (findfile filename))
        (setq result (vl-catch-all-apply 'vla-Load (list types "HIDDEN" (findfile filename)))))))
  (TA:SHW:Require (tblsearch "LTYPE" "HIDDEN")
    "Cannot load HIDDEN. Load it from a LIN file with LINETYPE, then retry.")
  (if (tblsearch "LAYER" TA:SHW-Layer)
    (progn
      (setq layer (vla-Item (vla-get-Layers shw-doc) TA:SHW-Layer))
      (TA:SHW:Require
        (and (= :vlax-false (vla-get-Lock layer))
             (= :vlax-false (vla-get-Freeze layer))
             (= :vlax-true (vla-get-LayerOn layer))
             (= "HIDDEN" (strcase (vla-get-Linetype layer))))
        "TA-HIDDEN-OVERLAY must be on, thawed, unlocked and use HIDDEN linetype."))
    (progn
      (setq layer (vla-Add (vla-get-Layers shw-doc) TA:SHW-Layer))
      (vla-put-Color layer 1)
      (vla-put-Linetype layer "HIDDEN"))))

(defun TA:SHW:Front (objects / dict table array)
  (if objects
    (progn
      (setq dict (vla-GetExtensionDictionary shw-space)
            table (vl-catch-all-apply 'vla-Item (list dict "ACAD_SORTENTS")))
      (if (vl-catch-all-error-p table)
        (setq table (vla-AddObject dict "ACAD_SORTENTS" "AcDbSortentsTable")))
      (setq array (vlax-make-safearray vlax-vbObject (cons 0 (1- (length objects)))))
      (vlax-safearray-fill array objects)
      (vla-MoveToTop table array))))

(defun TA:SHW:Unlock (/ layer)
  ;; Work on disposable copies even when the original's layer is locked.
  ;; Restore every lock after deleting copies, including on cancellation.
  (vlax-for layer (vla-get-Layers shw-doc)
    (if (= :vlax-true (vla-get-Lock layer))
      (progn
        (setq shw-locks (cons layer shw-locks))
        (vla-put-Lock layer :vlax-false)))))

;;; Public build API for batch use and native AutoCAD tests. Returns a list of
;;; new VLA objects, or nil on failure. NIL also means no intersecting geometry;
;;; TA:SHW-LastError distinguishes these cases. One Undo restores the entire run.
(defun TA:SHW:Build (sources blockers scale / shw-doc shw-space shw-temp shw-output
                          shw-problem shw-skipped shw-eps shw-scale shw-locks oldecho oldsnap
                          result objects masks curves record interval obj owner en)
  (setq shw-doc (vla-get-ActiveDocument (vlax-get-acad-object))
        shw-space (if (= 1 (getvar "CVPORT")) (vla-get-PaperSpace shw-doc)
                    (vla-get-ModelSpace shw-doc))
        shw-scale scale shw-eps 1e-7 shw-skipped 0
        oldecho (getvar "CMDECHO") oldsnap (getvar "OSMODE")
        TA:SHW-LastError nil)
  (vla-StartUndoMark shw-doc)
  (setvar "CMDECHO" 0) (setvar "OSMODE" 0)
  (setq result
    (vl-catch-all-apply
      '(lambda ()
         (TA:SHW:Require
           (and sources blockers (or (eq scale 'Auto) (and (numberp scale) (> scale 0.0))))
           "Invalid selection or scale.")
         (foreach en (append sources blockers)
           (setq owner (cdr (assoc 330 (entget en))))
           (TA:SHW:Require (eq owner (vlax-vla-object->ename shw-space))
             "Selections must belong to the active model/paper space."))
         (TA:SHW:PrepareLayer)
         (TA:SHW:Unlock)
         (setq objects (TA:SHW:Copies blockers "Mask") masks (TA:SHW:Masks objects))
         (TA:SHW:Require masks
           (if (= shw-mask-kind "Wipeout")
             "No WIPEOUT found. Select the covering block too, or use SHWHATCH for a hatch mask."
             "No supported mask found in the selected objects."))
         (setq curves (TA:SHW:Sources (TA:SHW:Copies sources "Source")))
         (TA:SHW:Require curves "No supported source curves found.")
         (foreach record curves
           (foreach interval (TA:SHW:Intervals (car record) masks)
             (TA:SHW:Emit (car record) (cadr record) interval)))
         (TA:SHW:Front shw-output)
         (if shw-output (vla-Regen shw-doc 0))
         (reverse shw-output))))
  (foreach obj shw-temp (TA:SHW:Delete obj))
  (if (or shw-problem (vl-catch-all-error-p result))
    (progn
      (foreach obj shw-output (TA:SHW:Delete obj))
      (setq TA:SHW-LastError (if shw-problem shw-problem (vl-catch-all-error-message result))
            result nil)
      (princ (strcat "\nSHW: " TA:SHW-LastError)))
    (princ (strcat "\nSHW: " (itoa (length result)) " hidden overlay(s) created outside blocks."
                   (if (> shw-skipped 0) (strcat " Skipped non-curve entities: " (itoa shw-skipped)) ""))))
  (foreach obj shw-locks (vl-catch-all-apply 'vla-put-Lock (list obj :vlax-true)))
  (setvar "CMDECHO" oldecho) (setvar "OSMODE" oldsnap)
  (vla-EndUndoMark shw-doc) result)

(defun TA:SHW:BuildMode (sources blockers scale shw-mask-kind)
  (TA:SHW:Build sources blockers scale))

(defun TA:SHW:Selection (ss / i result)
  (if ss
    (progn (setq i 0)
      (repeat (sslength ss)
        (setq result (cons (ssname ss i) result) i (1+ i))))) (reverse result))

(defun TA:SHW:Command (mode / sources masks scale kind)
  (setq kind (if (= mode "Wipeout") "WIPEOUT" "HATCH"))
  (princ (strcat "\nSHW v" TA:SHW-Version " - " kind " masks."
    "\nSelect ALL source curves / blocks to reveal (include the covering block if convenient):"))
  (if (setq sources (ssget '((0 . "LINE,ARC,CIRCLE,LWPOLYLINE,POLYLINE,ELLIPSE,SPLINE,INSERT")
                            (8 . "~TA-HIDDEN-OVERLAY"))))
    (progn
      (princ (strcat "\nSelect covering " kind " / blocks <Enter = find masks inside selected source blocks>:"))
      (setq masks (ssget (list (cons 0 (strcat kind ",INSERT")))))
      (initget 6 "Auto")
      (setq scale (getreal "\nHidden linetype scale [Auto] <Auto>: "))
      (if (or (null scale) (= scale "Auto")) (setq scale 'Auto))
      (if (numberp scale) (setq *TA:SHW-Scale* scale))
      (TA:SHW:BuildMode (TA:SHW:Selection sources)
        (if masks (TA:SHW:Selection masks) (TA:SHW:Selection sources)) scale mode)))
  (princ))

(defun c:SHW () (TA:SHW:Command "Wipeout"))
(defun c:SHWHATCH () (TA:SHW:Command "Hatch"))
(defun c:SHOWHIDDEN () (c:SHW))
(princ "\nTA_SHOW_HIDDEN v2.1 loaded. SHW = WIPEOUT; SHWHATCH = HATCH.")
(princ)
