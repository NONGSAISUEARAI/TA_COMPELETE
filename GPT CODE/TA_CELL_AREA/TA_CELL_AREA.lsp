;;; ==================== PRESETTING ====================
;;; Edit these values, save, then APPLOAD again to apply them.
;;; T = prompt with preset defaults; nil = use presets after grid selection.
(setq tca:prompt          T)
(setq tca:units           "Millimeters") ; Drawing / Millimeters / Meters
(setq tca:min-area        0.0)           ; Accept only Area > this value, in OUTPUT units
(setq tca:scale           25.0)          ; Uniform information-block scale
(setq tca:mat             "")            ; MAT for all accepted cells
(setq tca:station         "")            ; STATION for all accepted cells
(setq tca:floor           "")            ; FLOOR for all accepted cells
(setq tca:block           "facade_1_INFO") ; Same default as TA_FACADE_OUTLINE
(setq tca:precision       2)             ; AREA decimal places, 0..8
(setq tca:layer-boundary  "TA-CELL-BOUNDARY")
(setq tca:color-boundary  3)             ; ACI colour when creating the layer
(setq tca:layer-info      "TA-FACADE-INFO")
(setq tca:color-info      2)             ; ACI colour when creating the layer
(setq tca:style           "Standard")    ; Used only when creating a missing block
(setq tca:spacing         1.6)           ; Row spacing in a NEW unit-height definition
(setq tca:offset          '(0.0 0.0))    ; Label X/Y offset in current UCS drawing units
;;; ================== END PRESETTING ==================

;;; TA_CELL_AREA -- AutoCAD for Windows
;;; TCA: pick inside cells; TCAP: selected POINT/CIRCLE centres.
;;; v2.3 TCAA: automatic cells, information blocks and editable presets.
;;; Automatic mode builds its own graph and does not call BOUNDARY.
;;; Grid selection includes LINE, open/closed POLYLINE and XLINE.
;;; Requires closed coplanar 2D boundaries. Interior islands are ignored.
(vl-load-com)

;;; Prompt overrides are retained until the file is loaded again.

(defun TCA:Fail (message)
  (princ (strcat "\n" message)) (exit))

(defun TCA:ValidatePresets ()
  (if (not (and (member tca:prompt '(T nil))
                (member tca:units '("Drawing" "Millimeters" "Meters"))
                (numberp tca:min-area) (>= tca:min-area 0.0)
                (numberp tca:scale) (> tca:scale 0.0)
                (= (type tca:precision) 'INT) (<= 0 tca:precision 8)
                (numberp tca:spacing) (> tca:spacing 0.0)
                (listp tca:offset) (= (length tca:offset) 2)
                (vl-every 'numberp tca:offset)
                (vl-every '(lambda (s) (= (type s) 'STR))
                  (list tca:mat tca:station tca:floor tca:style))
                (vl-every '(lambda (s) (and (= (type s) 'STR) (snvalid s)))
                  (list tca:block tca:layer-boundary tca:layer-info))
                (vl-every '(lambda (n) (and (= (type n) 'INT) (<= 1 n 255)))
                  (list tca:color-boundary tca:color-info))))
    (TCA:Fail "Invalid PRESETTING: check units, area, scale, names, strings, precision and colours.")))

(defun TCA:Layer (name colour / data)
  (if (setq data (tblsearch "LAYER" name))
    (if (or (/= 0 (logand 5 (cdr (assoc 70 data))))
            (< (cdr (assoc 62 data)) 0))
      (TCA:Fail (strcat "Output layer is off, frozen or locked: " name)))
    (entmake (list '(0 . "LAYER") '(100 . "AcDbSymbolTableRecord")
                   '(100 . "AcDbLayerTableRecord") (cons 2 name)
                   '(70 . 0) (cons 62 colour) '(6 . "Continuous")))))

(defun TCA:Boundary (ss point / before en result)
  (setq before (entlast))
  (command-s "_.-BOUNDARY" "_Advanced" "_Boundary" "_New" ss ""
             "_Island" "_No" "_Object" "_Polyline" "" "_non" point "")
  (setq en (if before (entnext before) (entnext)))
  (while en
    (if (and (member (cdr (assoc 0 (entget en))) '("LWPOLYLINE" "POLYLINE"))
             (vlax-curve-isClosed en))
      (setq result (cons en result)))
    (setq en (entnext en)))
  (cond
    ((= 1 (length result)) (car result))
    (T (foreach en result (entdel en)) nil)))

(defun TCA:InfoBlock (/ name definition child data tags tag row y ok)
  (setq name tca:block)
  (if (not (tblsearch "BLOCK" name))
    (progn
      (if (not (tblsearch "STYLE" tca:style)) (TCA:Fail (strcat "Text style was not found: " tca:style)))
      (if (not (entmake (list '(0 . "BLOCK") (cons 2 name) '(70 . 2) '(10 0.0 0.0 0.0))))
        (TCA:Fail (strcat "Cannot create block: " name)))
      (setq ok T)
      (foreach row '(("AREA" 1.5) ("MAT" 0.5) ("STATION" -0.5) ("FLOOR" -1.5))
        (setq y (* (cadr row) tca:spacing))
        (if (not (entmake (list '(0 . "TEXT") '(8 . "0") '(62 . 0)
              (cons 10 (list -6.5 y 0.0)) (cons 11 (list -6.5 y 0.0))
              '(40 . 1.0) (cons 1 (strcat (car row) ":")) '(50 . 0.0)
              '(72 . 0) '(73 . 2) (cons 7 tca:style)))) (setq ok nil))
        (if (not (entmake (list '(0 . "ATTDEF") '(100 . "AcDbEntity")
              '(8 . "0") '(62 . 0) '(100 . "AcDbText")
              (cons 10 (list 0.0 y 0.0)) (cons 11 (list 0.0 y 0.0))
              '(40 . 1.0) '(1 . "") '(50 . 0.0) '(72 . 0) (cons 7 tca:style)
              '(100 . "AcDbAttributeDefinition") '(280 . 0)
              (cons 3 (car row)) (cons 2 (car row)) '(70 . 0) '(74 . 2) '(280 . 1))))
          (setq ok nil)))
      (if (not (and (entmake '((0 . "ENDBLK"))) ok))
        (TCA:Fail (strcat "Cannot finish block definition: " name)))))
  (setq definition (tblsearch "BLOCK" name))
  (if (/= 0 (logand 124 (cdr (assoc 70 definition))))
    (TCA:Fail (strcat name " must be a local block, not an xref.")))
  (setq child (cdr (assoc -2 definition)))
  (while (and child (/= "ENDBLK" (cdr (assoc 0 (setq data (entget child))))))
    (if (and (= "ATTDEF" (cdr (assoc 0 data))) (= 0 (logand 2 (cdr (assoc 70 data)))))
      (setq tags (cons (strcase (cdr (assoc 2 data))) tags)))
    (setq child (entnext child)))
  (foreach tag '("AREA" "MAT" "STATION" "FLOOR")
    (if (/= 1 (length (vl-remove-if-not '(lambda (item) (= item tag)) tags)))
      (TCA:Fail (strcat name " must contain exactly one editable " tag " attribute."))))
  name)

;;; Same position-lock handling as TFO:LockAttributeData. Keep attribute
;;; version/Xrecord fields; update only position-lock flag on new references.
(defun TCA:LockAttribute (data / inside count result pair)
  (setq count 0)
  (foreach pair data
    (cond
      ((= (car pair) 100)
       (if (and inside (< count 2)) (setq result (cons '(280 . 1) result)))
       (setq inside (member (cdr pair) '("AcDbAttribute" "AcDbAttributeDefinition")) count 0))
      ((and inside (= (car pair) 280))
       (setq count (1+ count)) (if (= count 2) (setq pair '(280 . 1)))))
    (setq result (cons pair result)))
  (if (and inside (< count 2)) (setq result (cons '(280 . 1) result)))
  (reverse result))

(defun TCA:Label (point height area / block saved result before en attr data values value pair)
  (TCA:Layer tca:layer-info tca:color-info)
  (setq block (TCA:InfoBlock)
        values (list (cons "AREA" (rtos area 2 tca:precision)) (cons "MAT" tca:mat)
                     (cons "STATION" tca:station) (cons "FLOOR" tca:floor))
        saved (mapcar '(lambda (v) (cons v (getvar v)))
                 '("ATTREQ" "ATTDIA" "ANGBASE" "ANGDIR" "AUNITS" "CLAYER"))
        before (entlast))
  (setq result (vl-catch-all-apply
    '(lambda ()
       (setvar "ATTREQ" 0) (setvar "ATTDIA" 0) (setvar "ANGBASE" 0.0)
       (setvar "ANGDIR" 0) (setvar "AUNITS" 0) (setvar "CLAYER" tca:layer-info)
       ;; Insert in current UCS: same plane and orientation as the new cell.
       ;; AutoCAD instantiates the existing ATTDEF layout and custom defaults.
       (command-s "_.-INSERT" block "_Scale" height "_Rotate" "0" "_non"
         (mapcar '+ point (append tca:offset '(0.0)))))))
  (setq en (entlast))
  (foreach pair saved (setvar (car pair) (cdr pair)))
  (if (and (not (vl-catch-all-error-p result)) en (not (eq en before))
           (= "INSERT" (cdr (assoc 0 (entget en)))))
    (progn
      (setq attr en)
      (while (and (setq attr (entnext attr))
                  (/= "SEQEND" (cdr (assoc 0 (setq data (entget attr))))))
        (if (= "ATTRIB" (cdr (assoc 0 data)))
          (progn
            (if (setq value (assoc (strcase (cdr (assoc 2 data))) values))
              (setq data (subst (cons 1 (cdr value)) (assoc 1 data) data)))
            (if (not (entmod (TCA:LockAttribute data)))
              (progn (entdel en) (TCA:Fail "Cannot populate information block attributes."))))))
      (entupd en) en)
    (progn (if (and en (not (eq en before))) (entdel en)) nil)))

(defun TCA:ReadValue (tag previous / answer)
  (setq answer (getstring T (strcat "\n" tag " for ALL accepted cells <" previous ">: ")))
  (if (= answer "") previous answer))

(defun TCA:InputInfo ()
  (setq tca:mat (TCA:ReadValue "MAT" tca:mat)
        tca:station (TCA:ReadValue "STATION" tca:station)
        tca:floor (TCA:ReadValue "FLOOR" tca:floor)))

;;; Canonical edge signatures suppress repeat measurements within one run.
(defun TCA:Key (en / i stop a b mid edges)
  (setq i 0 stop (fix (vlax-curve-getEndParam en)))
  (repeat stop
    (setq a (vlax-curve-getPointAtParam en i)
          b (vlax-curve-getPointAtParam en (1+ i))
          mid (vlax-curve-getPointAtParam en (+ i 0.5)))
    (if (< (vl-prin1-to-string b) (vl-prin1-to-string a))
      (setq edges (cons (list b mid a) edges))
      (setq edges (cons (list a mid b) edges)))
    (setq i (1+ i)))
  (vl-sort edges '(lambda (x y) (< (vl-prin1-to-string x)
                                  (vl-prin1-to-string y)))))

(defun TCA:Measure (ss point height factor suffix keys number minimum / en raw key)
  (if (setq en (TCA:Boundary ss point))
    (progn
      (setq raw (vlax-curve-getArea en) key (TCA:Key en))
      (cond
        ((and raw (<= (* raw factor) minimum)) (entdel en) nil)
        ((vl-some '(lambda (old) (equal key old 1e-7)) keys)
         (entdel en) (princ "\nSkipped: this cell was already measured.") nil)
        ((and raw (> raw 0.0))
         (if (TCA:Label point height (* raw factor))
           (progn
             (princ (strcat "\nCell " (itoa number) " = "
                            (rtos (* raw factor) 2 4) suffix))
             (list key (* raw factor)))
           (progn (entdel en) (TCA:Fail "Could not create area label."))))
        (T (entdel en) (princ "\nSkipped: no positive closed area.") nil)))
    (progn (princ "\nSkipped: no single closed boundary. Check gaps/view/plane.") nil)))

;;; Classify a straight segment in the current UCS; never silently accept
;;; diagonal edges, curved bulges or geometry in different planes.
(defun TCA:Axis (a b / dx dy)
  (if (not (equal (caddr a) (caddr b) 1e-7))
    (TCA:Fail "TCAA requires coplanar geometry parallel to the UCS XY plane."))
  (setq dx (- (car b) (car a)) dy (- (cadr b) (cadr a)))
  (cond
    ((and (equal dx 0.0 1e-7) (not (equal dy 0.0 1e-7)))
     (list 'X (car a) (caddr a)))
    ((and (equal dy 0.0 1e-7) (not (equal dx 0.0 1e-7)))
     (list 'Y (cadr a) (caddr a)))
    ((and (equal dx 0.0 1e-7) (equal dy 0.0 1e-7)) nil)
    (T (TCA:Fail "TCAA: align UCS with the grid first. Diagonal edges are unsupported."))))

(defun TCA:Unique (values / result value)
  (foreach value (vl-sort values '<)
    (if (or (not result) (not (equal value (car result) 1e-7)))
      (setq result (cons value result))))
  (reverse result))

(defun TCA:Midpoints (values / result)
  (while (cdr values)
    (setq result (cons (/ (+ (car values) (cadr values)) 2.0) result)
          values (cdr values)))
  (reverse result))

(defun TCA:AutoSeeds (ss / index en data kind edges a b mid j stop edge
                            xs ys z xs-mid ys-mid points x y)
  (setq index 0)
  (repeat (sslength ss)
    (setq en (ssname ss index) data (entget en) kind (cdr (assoc 0 data))
          index (1+ index) edges nil)
    (cond
      ((= kind "XLINE")
       (setq a (trans (cdr (assoc 10 data)) 0 1)
             b (mapcar '+ a (trans (cdr (assoc 11 data)) 0 1 T))
             edges (list (TCA:Axis a b))))
      ((= kind "LINE")
       (setq edges (list (TCA:Axis
         (trans (cdr (assoc 10 data)) 0 1)
         (trans (cdr (assoc 11 data)) 0 1)))))
      ((member kind '("LWPOLYLINE" "POLYLINE"))
       (setq j 0 stop (fix (vlax-curve-getEndParam en)))
       (repeat stop
         (setq a (trans (vlax-curve-getPointAtParam en j) 0 1)
               b (trans (vlax-curve-getPointAtParam en (1+ j)) 0 1)
               mid (trans (vlax-curve-getPointAtParam en (+ j 0.5)) 0 1))
         (if (not (equal mid (mapcar '(lambda (u v) (/ (+ u v) 2.0)) a b) 1e-7))
           (TCA:Fail "TCAA requires straight polyline segments; curved bulges are unsupported."))
         (setq edges (cons (TCA:Axis a b) edges) j (1+ j))))
      (T (TCA:Fail "TCAA accepts only LINE, POLYLINE and XLINE. Select the grid only.")))
    (foreach edge edges
      (if edge
        (progn
          (if (and z (not (equal z (caddr edge) 1e-7)))
            (TCA:Fail "TCAA: selected objects have different elevations."))
          (setq z (caddr edge))
          (if (= (car edge) 'X) (setq xs (cons (cadr edge) xs))
            (setq ys (cons (cadr edge) ys)))))))
  (setq xs-mid (TCA:Midpoints (TCA:Unique xs))
        ys-mid (TCA:Midpoints (TCA:Unique ys)))
  (if (or (not xs-mid) (not ys-mid))
    (TCA:Fail "TCAA needs at least two vertical and two horizontal grid coordinates."))
  (if (> (* (length xs-mid) (length ys-mid)) 100000)
    (TCA:Fail "Too many candidate cells. Select a smaller grid area."))
  (foreach y ys-mid
    (foreach x xs-mid (setq points (cons (list x y z) points))))
  (princ (strcat "\nAutomatic candidates: " (itoa (length points))))
  (reverse points))

;;; Segment records: (axis coordinate low high elevation).
;;; NIL low/high denotes the infinite span of an XLINE.
(defun TCA:Segment (a b infinite / axis lo hi)
  (if (setq axis (TCA:Axis a b))
    (progn
      (if (= (car axis) 'X)
        (setq lo (min (cadr a) (cadr b)) hi (max (cadr a) (cadr b)))
        (setq lo (min (car a) (car b)) hi (max (car a) (car b))))
      (list (car axis) (cadr axis) (if infinite nil lo)
            (if infinite nil hi) (caddr axis)))))

(defun TCA:Segments (ss / i en data kind a b mid j edges segment z result)
  (setq i 0)
  (repeat (sslength ss)
    (setq en (ssname ss i) data (entget en) kind (cdr (assoc 0 data))
          i (1+ i) edges nil)
    (cond
      ((= kind "XLINE")
       (setq a (trans (cdr (assoc 10 data)) 0 1)
             b (mapcar '+ a (trans (cdr (assoc 11 data)) 0 1 T))
             edges (list (TCA:Segment a b T))))
      ((= kind "LINE")
       (setq edges (list (TCA:Segment (trans (cdr (assoc 10 data)) 0 1)
                                     (trans (cdr (assoc 11 data)) 0 1) nil))))
      ((member kind '("LWPOLYLINE" "POLYLINE"))
       (setq j 0)
       (repeat (fix (vlax-curve-getEndParam en))
         (setq a (trans (vlax-curve-getPointAtParam en j) 0 1)
               b (trans (vlax-curve-getPointAtParam en (1+ j)) 0 1)
               mid (trans (vlax-curve-getPointAtParam en (+ j 0.5)) 0 1))
         (if (not (equal mid (mapcar '(lambda (u v) (/ (+ u v) 2.0)) a b) 1e-7))
           (TCA:Fail "TCAA: curved polyline segments are unsupported."))
         (setq edges (cons (TCA:Segment a b nil) edges) j (1+ j))))
      (T (TCA:Fail "TCAA: select only LINE, POLYLINE and XLINE grid objects.")))
    (foreach segment edges
      (if segment
        (progn
          (if (and z (not (equal z (nth 4 segment) 1e-7)))
            (TCA:Fail "TCAA: all grid objects must have the same elevation."))
          (setq z (nth 4 segment) result (cons segment result))))))
  result)

(defun TCA:Index (value values / i)
  (setq i 0)
  (while (and values (not (equal value (car values) 1e-7)))
    (setq values (cdr values) i (1+ i)))
  (if values i))

(defun TCA:Link (graph a b / entry)
  (setq entry (assoc a graph))
  (if entry
    (if (member b (cdr entry)) graph
      (subst (cons a (cons b (cdr entry))) entry graph))
    (cons (list a b) graph)))

(defun TCA:Direction (a b)
  (cond ((> (car b) (car a)) 0) ((> (cadr b) (cadr a)) 1)
        ((< (car b) (car a)) 2) (T 3)))

;;; Follow the face on the left: first clockwise edge from the incoming twin.
(defun TCA:Next (graph previous at / reverse-dir best score n delta)
  (setq reverse-dir (TCA:Direction at previous) score 5)
  (foreach n (cdr (assoc at graph))
    (setq delta (rem (+ 4 (- reverse-dir (TCA:Direction at n))) 4))
    (if (= delta 0) (setq delta 4))
    (if (< delta score) (setq score delta best n)))
  best)

(defun TCA:SignedArea (points / first a b area origin)
  (setq first (car points) origin first area 0.0)
  (while points
    (setq a (car points) b (if (cdr points) (cadr points) first)
          area (+ area (- (* (- (car a) (car origin)) (- (cadr b) (cadr origin)))
                          (* (- (car b) (car origin)) (- (cadr a) (cadr origin)))))
          points (cdr points)))
  (/ area 2.0))

;;; Remove split collinear vertices and backtracking dangling branches.
(defun TCA:Simplify (points / changed i count prev at next result)
  (setq changed T)
  (while (and changed (> (length points) 3))
    (setq changed nil i 0 count (length points) result nil)
    (while (< i count)
      (setq prev (nth (rem (+ i count -1) count) points)
            at (nth i points) next (nth (rem (1+ i) count) points))
      (if (and (not changed)
               (or (and (= (car prev) (car at)) (= (car at) (car next)))
                   (and (= (cadr prev) (cadr at)) (= (cadr at) (cadr next)))))
        (setq changed T)
        (setq result (cons at result)))
      (setq i (1+ i)))
    (setq points (reverse result)))
  points)

(defun TCA:Inside (point polygon / a b rest inside x y cross)
  (setq x (car point) y (cadr point) a (last polygon) rest polygon)
  (while rest
    (setq b (car rest))
    (if (not (eq (> (cadr a) y) (> (cadr b) y)))
      (progn
        (setq cross (+ (car a) (* (- y (cadr a))
                         (/ (- (car b) (car a)) (- (cadr b) (cadr a))))))
        (if (< x cross) (setq inside (not inside)))))
    (setq a b rest (cdr rest)))
  inside)

(defun TCA:FaceSeed (a b xs ys z / i j direction)
  (setq direction (TCA:Direction a b)
        i (min (car a) (car b)) j (min (cadr a) (cadr b)))
  (if (= direction 2) (setq j (1- j)))
  (if (= direction 1) (setq i (1- i)))
  (list (/ (+ (nth i xs) (nth (1+ i) xs)) 2.0)
        (/ (+ (nth j ys) (nth (1+ j) ys)) 2.0) z))

(defun TCA:GridFaces (ss / segments xs ys z s span fixed i coords mid a b graph
                         entry n visited start edge next ring physical simple
                         area seed center faces)
  (setq segments (TCA:Segments ss))
  (foreach s segments
    (setq z (nth 4 s))
    (if (= (car s) 'X)
      (progn (setq xs (cons (cadr s) xs))
        (if (nth 2 s) (setq ys (cons (nth 2 s) (cons (nth 3 s) ys)))))
      (progn (setq ys (cons (cadr s) ys))
        (if (nth 2 s) (setq xs (cons (nth 2 s) (cons (nth 3 s) xs)))))))
  (setq xs (TCA:Unique xs) ys (TCA:Unique ys))
  (if (> (* (length xs) (length ys)) 10000)
    (TCA:Fail "TCAA: select a smaller grid area (over 10000 grid nodes)."))
  (foreach s segments
    (setq coords (if (= (car s) 'X) ys xs)
          fixed (TCA:Index (cadr s) (if (= (car s) 'X) xs ys)) i 0)
    (while (cdr coords)
      (setq mid (/ (+ (car coords) (cadr coords)) 2.0))
      (if (or (null (nth 2 s))
              (and (> mid (nth 2 s)) (< mid (nth 3 s))))
        (progn
          (setq a (if (= (car s) 'X) (list fixed i) (list i fixed))
                b (if (= (car s) 'X) (list fixed (1+ i)) (list (1+ i) fixed))
                graph (TCA:Link (TCA:Link graph a b) b a))))
      (setq coords (cdr coords) i (1+ i))))
  (foreach entry graph
    (foreach n (cdr entry)
      (setq start (list (car entry) n))
      (if (not (member start visited))
        (progn
          (setq edge start ring nil)
          (while (not (member edge visited))
            (setq visited (cons edge visited) ring (cons (car edge) ring)
                  next (TCA:Next graph (car edge) (cadr edge))
                  edge (list (cadr edge) next)))
          (setq ring (reverse ring)
                physical (mapcar '(lambda (p) (list (nth (car p) xs) (nth (cadr p) ys) z)) ring)
                area (TCA:SignedArea physical))
          (if (> area 1e-12)
            (progn
              (setq seed (TCA:FaceSeed (car ring) (cadr ring) xs ys z)
                    simple (TCA:Simplify ring)
                    physical (mapcar '(lambda (p) (list (nth (car p) xs) (nth (cadr p) ys) z)) simple)
                    center (list (/ (+ (apply 'min (mapcar 'car physical))
                                       (apply 'max (mapcar 'car physical))) 2.0)
                                 (/ (+ (apply 'min (mapcar 'cadr physical))
                                       (apply 'max (mapcar 'cadr physical))) 2.0) z))
              (if (TCA:Inside center physical) (setq seed center))
              (setq faces (cons (list physical seed area) faces))))))))
  (princ (strcat "\nTA CELL AREA v2.3 - bounded cells found: " (itoa (length faces))))
  (if (not faces)
    (princ "\nNo closed cells found. Check grid selection, gaps and UCS alignment."))
  (reverse faces))

(defun TCA:PutFace (face height factor suffix number minimum / points area normal ocs en)
  (setq points (car face) area (* (caddr face) factor))
  (if (> area minimum)
    (progn
      (setq normal (trans '(0.0 0.0 1.0) 1 0 T)
            ocs (mapcar '(lambda (p) (trans p 1 normal)) points))
      (if (entmake (append (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity")
             (cons 8 tca:layer-boundary) '(100 . "AcDbPolyline")
             (cons 90 (length points)) '(70 . 1) (cons 38 (caddr (car ocs))))
             (mapcar '(lambda (p) (cons 10 (list (car p) (cadr p)))) ocs)
             (list (cons 210 normal))))
        (progn
          (setq en (entlast))
          (if (TCA:Label (cadr face) height area)
            (progn (princ (strcat "\nCell " (itoa number) " = " (rtos area 2 4) suffix))
                   (list nil area))
            (progn (entdel en) (TCA:Fail "Could not create area label."))))
        (TCA:Fail "Could not create cell boundary.")))))

(defun TCA:Run (batch / *error* saved marked ss seeds points i ed point
                      units factor suffix height keys count total result pair minimum faces)
  (defun *error* (msg)
    (foreach pair saved (setvar (car pair) (cdr pair)))
    (if marked (command-s "_.UNDO" "_End"))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*EXIT*")))
      (princ (strcat "\nTCA error: " msg)))
    (princ))
  (TCA:ValidatePresets)
  (princ "\nSelect grid LINE/PLINE/XLINE objects (exclude red seed circles): ")
  (if (setq ss (ssget '((0 . "LINE,LWPOLYLINE,POLYLINE,XLINE,ARC,CIRCLE,ELLIPSE,SPLINE,INSERT"))))
    (progn
      (if (eq batch 'Auto) (setq faces (TCA:GridFaces ss)))
      (if (eq batch T)
        (progn
          (princ "\nSelect seed POINT/CIRCLE objects inside the cells: ")
          (if (setq seeds (ssget '((0 . "POINT,CIRCLE"))))
            (progn
              (setq i 0)
              (repeat (sslength seeds)
                (setq ed (entget (ssname seeds i)) i (1+ i))
                (setq points
                  (cons (trans (cdr (assoc 10 ed))
                         (if (= "CIRCLE" (cdr (assoc 0 ed))) (cdr (assoc -1 ed)) 0)
                         1) points)))
              (setq points (reverse points))))))
      (if (or (not batch) points faces)
        (progn
          (setq units tca:units)
          (if tca:prompt
            (progn
              (initget "Drawing Millimeters Meters")
              (setq units (getkword (strcat "\nDrawing units [Drawing/Millimeters/Meters] <" tca:units ">: ")))
              (if (not units) (setq units tca:units))))
          (setq tca:units units factor (if (= units "Millimeters") 1e-6 1.0)
                suffix (if (member units '("Millimeters" "Meters")) " m2" " sq.units"))
          (setq minimum tca:min-area)
          (if (eq batch 'Auto)
            (progn
              (if tca:prompt
                (progn
                  (initget 4)
                  (setq minimum (getreal (strcat "\nOnly write cells with area GREATER THAN (" suffix ") <"
                                                (rtos tca:min-area 2 4) ">: ")))
                  (if (not minimum) (setq minimum tca:min-area))))
              (setq tca:min-area minimum)
              (setq faces (vl-remove-if-not '(lambda (face) (> (* (caddr face) factor) minimum)) faces))
              (princ (strcat "\nCells above threshold: " (itoa (length faces))))
              (if (not faces)
                (TCA:Fail "No cells exceed the threshold. No outlines or labels were created."))))
          (setq height tca:scale)
          (if tca:prompt
            (progn
              (initget 6)
              (setq height (getdist (strcat "\nInfo block scale (unit-height text) <" (rtos tca:scale 2 2) ">: ")))
              (if (not height) (setq height tca:scale))
              (TCA:InputInfo)))
          (setq tca:scale height)
          (setq saved (mapcar '(lambda (v) (cons v (getvar v)))
                      '("CMDECHO" "OSMODE" "CLAYER" "PLINETYPE" "HPGAPTOL")))
          (command-s "_.UNDO" "_Begin") (setq marked T)
          (TCA:Layer tca:layer-boundary tca:color-boundary) (TCA:Layer tca:layer-info tca:color-info)
          (TCA:InfoBlock)
          (setvar "CMDECHO" 0) (setvar "OSMODE" 0)
          (setvar "PLINETYPE" 2) (setvar "HPGAPTOL" 0.0)
          (setvar "CLAYER" tca:layer-boundary)
          (setq count 0 total 0.0)
          (if batch
            (foreach point (if (eq batch 'Auto) faces points)
              (if (setq result
                    (if (eq batch 'Auto)
                      (TCA:PutFace point height factor suffix (1+ count) minimum)
                      (TCA:Measure ss point height factor suffix keys (1+ count) minimum)))
                (setq keys (cons (car result) keys) count (1+ count)
                      total (+ total (cadr result)))))
            (while (setq point (getpoint "\nPick INSIDE a cell, Enter to finish: "))
              (if (setq result (TCA:Measure ss point height factor suffix keys (1+ count) minimum))
                (setq keys (cons (car result) keys) count (1+ count)
                      total (+ total (cadr result))))))
          (foreach pair saved (setvar (car pair) (cdr pair)))
          (setq saved nil)
          (command-s "_.UNDO" "_End") (setq marked nil)
          (princ (strcat "\nMeasured " (itoa count) " cells; total = "
                         (rtos total 2 4) suffix ". Use U to undo this run."))))))
  (princ))

(defun c:TCA () (TCA:Run nil))
(defun c:TCAP () (TCA:Run T))
(defun c:TCAA () (TCA:Run 'Auto))
(defun c:TCAA2 () (TCA:Run 'Auto))
(princ "\nLoaded TA_CELL_AREA v2.3 (PRESETTING + info attributes). Commands: TCA, TCAP, TCAA / TCAA2.")
(princ)
