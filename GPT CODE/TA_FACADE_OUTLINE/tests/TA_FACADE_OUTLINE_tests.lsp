;;; Run in a disposable blank drawing, never in a production drawing.
(defun TFOT:Assert (name ok)
  (if ok (setq tfot-pass (1+ tfot-pass)) (setq tfot-fail (1+ tfot-fail)))
  (write-line (strcat (if ok "PASS " "FAIL ") name) tfot-log)
  (princ (strcat "\n" (if ok "PASS " "FAIL ") name)))

(defun TFOT:Rect (x y width height / vertices)
  (setq vertices (mapcar '(lambda (p) (list p 0.0))
    (list (list x y) (list (+ x width) y) (list (+ x width) (+ y height)) (list x (+ y height)))))
  (entmake (TFO:LWData vertices 0.0 "0")) (entlast))

(defun TFOT:Count (/ ss) (if (setq ss (ssget "_X")) (sslength ss) 0))
(defun TFOT:Set (items / ss) (setq ss (ssadd)) (foreach item items (ssadd item ss)) ss)
(defun TFOT:DeleteResult (result / record entity)
  (foreach record result (foreach entity (append (cons (car record) (cadr record)) (list (caddr record)))
    (if (and entity (entget entity)) (entdel entity)))))
(defun TFOT:Values (result / record entity values)
  (foreach record result (foreach entity (cadr record)
    (setq values (cons (cdr (assoc 1 (entget (entnext entity)))) values)))) values)
(defun TFOT:Vertices (record) (TFO:LWVertices (entget (car record))))
(defun TFOT:InfoValues (record / entity data values)
  (setq entity (caddr record))
  (while (and entity (setq entity (entnext entity))
    (/= "SEQEND" (TFO:Get 0 (setq data (entget entity)) "")))
    (if (= "ATTRIB" (cdr (assoc 0 data)))
      (setq values (cons (cons (cdr (assoc 2 data)) (cdr (assoc 1 data))) values))))
  (reverse values))
(defun TFOT:Attribute (entity tag / data found)
  (while (and (setq entity (entnext entity))
    (/= "SEQEND" (TFO:Get 0 (setq data (entget entity)) "")))
    (if (and (= "ATTRIB" (cdr (assoc 0 data))) (= (strcase tag) (strcase (TFO:Get 2 data ""))))
      (setq found data))) found)
(defun TFOT:Definition (name / definition entity data result)
  (setq definition (tblsearch "BLOCK" name) entity (cdr (assoc -2 definition)))
  (while (and entity (/= "ENDBLK" (TFO:Get 0 (setq data (entget entity)) "")))
    (setq result (cons data result) entity (entnext entity))) (cons definition (reverse result)))

(setq tfot-log (open (strcat tfot-root "tests/results.txt") "w") tfot-pass 0 tfot-fail 0)
(TFOT:Assert "Default exceptions contain the separate AREA and LENGTH block names"
  (equal exception_blocks_ (list block_info_ block_length_)))
(TFOT:Assert "v1.4 disables length labels by default" (= label_mode_ "NONE"))
(TFOT:Assert "v1.3 defaults to one overall envelope across gaps" (= outline_mode_ "OVERALL"))
(setq outline_mode_ "SPLIT") ; Regression coverage for the previous strict mode.
(setq label_mode_ "ALL") ; Preserve coverage of the original every-side behavior.
(setq height_txt_ 10.0 offset_txt_ 5.0 prefix_txt_ "facade_1" precision_txt_ 0
      tolerance_fo_ 0.000001 factor_area_ 1.0) ; Deterministic fixture units; keep user's source presets intact.
(setvar "CMDECHO" 0) (setvar "OSMODE" 16383) (setvar "DELOBJ" 1) (setvar "DIMZIN" 8)

;;; Adjacent block and polyline: union removes the join and collinear vertices.
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0))
(entmake '((0 . "BLOCK") (2 . "TFOT_RECT") (70 . 0) (10 0.0 0.0 0.0)))
(TFOT:Rect 0.0 0.0 100.0 100.0)
(entmake '((0 . "ATTDEF") (10 50.0 50.0 0.0) (40 . 5.0) (1 . "SOURCE") (2 . "ID") (3 . "ID") (70 . 0)))
(entmake '((0 . "ENDBLK")))
(entmake '((0 . "INSERT") (2 . "TFOT_RECT") (10 100.0 0.0 0.0)))
(setq tfot-b (entlast) tfot-before-a (entget tfot-a) tfot-before-b (entget tfot-b)
      tfot-count (TFOT:Count) tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Mixed Block + Pline creates one closed four-sided outline"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Vertices (car tfot-result))))
       (= 1 (cdr (assoc 70 (entget (caar tfot-result)))))))
(TFOT:Assert "Internal join is removed and outside area is 20000"
  (and tfot-result (equal (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 20000.0 1e-6)))
(TFOT:Assert "Every visible attribute includes prefix and edge length"
  (and (= 4 (length (TFOT:Values tfot-result)))
    (= 2 (length (vl-remove-if-not '(lambda (v) (= v "facade_1_200")) (TFOT:Values tfot-result))))
    (= 2 (length (vl-remove-if-not '(lambda (v) (= v "facade_1_100")) (TFOT:Values tfot-result))))))
(TFOT:Assert "Only one outline, four length inserts and one info insert remain; temporary geometry removed"
  (= (TFOT:Count) (+ tfot-count 6)))
(TFOT:Assert "Source entities are unchanged" (and (equal tfot-before-a (entget tfot-a)) (equal tfot-before-b (entget tfot-b))))
(TFOT:Assert "System variables restored" (and (= (getvar "OSMODE") 16383) (= (getvar "DELOBJ") 1) (= (getvar "DIMZIN") 8)))
(setq tfot-offset-ok T tfot-mid-ok T tfot-attribute-ok T)
(foreach tfot-label (cadar tfot-result)
  (setq tfot-data (entget tfot-label) tfot-pos (cdr (assoc 10 tfot-data))
        tfot-att (entget (entnext tfot-label)))
  (if (not (or (equal tfot-pos '(100.0 -10.0 0.0) 1e-6) (equal tfot-pos '(100.0 110.0 0.0) 1e-6)
               (equal tfot-pos '(-10.0 50.0 0.0) 1e-6) (equal tfot-pos '(210.0 50.0 0.0) 1e-6)))
    (setq tfot-mid-ok nil))
  (if (not (and (= "ATTRIB" (cdr (assoc 0 tfot-att))) (= "LENGTH" (cdr (assoc 2 tfot-att)))
    (= 1 (cdr (assoc 72 tfot-att))) (= 2 (cdr (assoc 74 tfot-att))))) (setq tfot-attribute-ok nil)))
(TFOT:Assert "Labels are at side midpoints with outward clearance" tfot-mid-ok)
(TFOT:Assert "Labels are real middle-centered LENGTH attributes" tfot-attribute-ok)
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Overlap, concavity, separate components and an unlabelled hole.
(setq tfot-a (TFOT:Rect 0.0 0.0 150.0 100.0) tfot-b (TFOT:Rect 100.0 0.0 100.0 100.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Overlapping plines union to the actual outer boundary"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Vertices (car tfot-result))))
       (equal 20000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)
(setq tfot-a (TFOT:Rect 0.0 0.0 200.0 100.0) tfot-b (TFOT:Rect 0.0 100.0 100.0 100.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Concave L outline retains six sides and actual area"
  (and (= 1 (length tfot-result)) (= 6 (length (TFOT:Vertices (car tfot-result))))
       (equal 30000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0) tfot-b (TFOT:Rect 200.0 0.0 100.0 100.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Disconnected objects produce two outlines and eight labels"
  (and (= 2 (length tfot-result)) (= 8 (length (TFOT:Values tfot-result)))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)
(setq tfot-sources (list (TFOT:Rect 0.0 0.0 300.0 100.0) (TFOT:Rect 0.0 200.0 300.0 100.0)
  (TFOT:Rect 0.0 100.0 100.0 100.0) (TFOT:Rect 200.0 100.0 100.0 100.0))
      tfot-result (TFO:Build (TFOT:Set tfot-sources)))
(TFOT:Assert "Ring of panels labels outer loop only, omitting its hole"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Values tfot-result)))
       (equal 90000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)))
(TFOT:DeleteResult tfot-result) (foreach tfot-e tfot-sources (entdel tfot-e))

;;; A semicircular bulge and exact arc length.
(setq precision_txt_ 2)
(entmake (TFO:LWData '(((0.0 0.0) 1.0) ((100.0 0.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Circular arc remains a true bulge, not a faceted line"
  (and tfot-result (= 2 (length (TFOT:Vertices (car tfot-result))))
    (equal (* pi 1250.0) (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-5)))
(TFOT:Assert "Arc labels use actual arc length and explicit decimal precision"
  (and (member "facade_1_157.08" (TFOT:Values tfot-result)) (member "facade_1_100.00" (TFOT:Values tfot-result))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (setq precision_txt_ 0)

;;; Nested mirrored/nonuniform straight block with a nonzero block base point.
(entmake '((0 . "BLOCK") (2 . "TFOT_BASE") (70 . 0) (10 10.0 20.0 0.0)))
(TFOT:Rect 10.0 20.0 100.0 50.0) (entmake '((0 . "ENDBLK")))
(entmake '((0 . "BLOCK") (2 . "TFOT_NESTED") (70 . 0) (10 0.0 0.0 0.0)))
(entmake '((0 . "INSERT") (2 . "TFOT_BASE") (10 0.0 0.0 0.0) (41 . -2.0) (42 . 3.0) (43 . 1.0)))
(entmake '((0 . "ENDBLK")))
(entmake (list '(0 . "INSERT") '(2 . "TFOT_NESTED") '(10 1000.0 2000.0 0.0) (cons 50 (/ pi 2.0))))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Nested block applies mirror, independent XY scales, rotation and base point"
  (and (= 1 (length tfot-result)) (equal 30000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-5)
       (member "facade_1_200" (TFOT:Values tfot-result)) (member "facade_1_150" (TFOT:Values tfot-result))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; Failure is atomic and restores settings.
(entmake (TFO:LWData '(((0.0 0.0) 0.0) ((100.0 0.0) 0.0) ((100.0 100.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast))
(entmod (subst '(70 . 0) (assoc 70 (entget tfot-a)) (entget tfot-a)))
(setq tfot-count (TFOT:Count) tfot-before-a (entget tfot-a) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Open unclosed area fails without output, leaks or source edits"
  (and (null tfot-result) (= tfot-count (TFOT:Count)) (equal tfot-before-a (entget tfot-a))))
(TFOT:Assert "Failure restores OSMODE, DELOBJ and DIMZIN"
  (and (= (getvar "OSMODE") 16383) (= (getvar "DELOBJ") 1) (= (getvar "DIMZIN") 8)))
(entdel tfot-a)

;;; A selected open tail must not be silently omitted when another area closes.
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0))
(entmake '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline")
  (90 . 2) (70 . 0) (10 100.0 50.0) (10 150.0 50.0)))
(setq tfot-b (entlast) tfot-count (TFOT:Count) tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "An open selected tail outside a closed shape fails atomically"
  (and (null tfot-result) (= tfot-count (TFOT:Count))))
(entdel tfot-a) (entdel tfot-b)

;;; Lines inside a block can form the closed outline, with open panel dividers.
(entmake '((0 . "BLOCK") (2 . "TFOT_LINES") (70 . 0) (10 0.0 0.0 0.0)))
(foreach tfot-pair '(((0.0 0.0 0.0) (200.0 0.0 0.0)) ((200.0 0.0 0.0) (200.0 100.0 0.0))
  ((200.0 100.0 0.0) (0.0 100.0 0.0)) ((0.0 100.0 0.0) (0.0 0.0 0.0))
  ((50.0 0.0 0.0) (50.0 100.0 0.0)) ((100.0 0.0 0.0) (100.0 100.0 0.0)))
  (entmake (list '(0 . "LINE") '(8 . "0") (cons 10 (car tfot-pair)) (cons 11 (cadr tfot-pair)))))
(entmake '((0 . "ENDBLK")))
(entmake '((0 . "INSERT") (2 . "TFOT_LINES") (10 0.0 0.0 0.0)))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Block made from lines and internal panel dividers creates one outside loop"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Values tfot-result)))
       (equal 20000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; Geometry follows the reference trapezoid; all labels stay beside each edge.
(setq precision_txt_ 2)
(entmake (TFO:LWData '(((0.0 0.0) 0.0) ((2000.0 0.0) 0.0) ((2010.0 120.0) 0.0) ((0.0 120.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))) tfot-slant-ok nil)
(foreach tfot-label (cadar tfot-result)
  (setq tfot-att (entget (entnext tfot-label)) tfot-data (entget tfot-label))
  (if (= (cdr (assoc 1 tfot-att)) "facade_1_120.42")
    (setq tfot-slant-ok (and (equal (cdr (assoc 50 tfot-data)) (atan 120.0 10.0) 1e-8)
      (> (car (cdr (assoc 10 tfot-data))) 2005.0)))))
(TFOT:Assert "Sloping side has prefix_120.42, midpoint offset outward and parallel rotation" tfot-slant-ok)
(TFOT:Assert "Reference trapezoid includes both long lengths with prefix"
  (and (member "facade_1_2010.00" (TFOT:Values tfot-result)) (member "facade_1_2000.00" (TFOT:Values tfot-result))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (setq precision_txt_ 0)

;;; A late failure after output begins must remove all newly created inserts.
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0) tfot-count (TFOT:Count)
      TFOT:SavedLabel TFO:Label tfot-label-calls 0)
(defun TFO:Label (block point rotation edge-length)
  (setq tfot-label-calls (1+ tfot-label-calls))
  (TFO:Require (< tfot-label-calls 3) "Intentional test failure after two labels.")
  (TFOT:SavedLabel block point rotation edge-length))
(setq tfot-result (TFO:Build (TFOT:Set (list tfot-a))) TFO:Label TFOT:SavedLabel)
(TFOT:Assert "Late error rolls back outline and already-created attribute blocks"
  (and (= tfot-label-calls 3) (null tfot-result) (= tfot-count (TFOT:Count)) (entget tfot-a)))
(entdel tfot-a)

;;; Uniformly mirrored circular block and a full circle preserve curvature.
(entmake '((0 . "BLOCK") (2 . "TFOT_CIRCLE") (70 . 0) (10 0.0 0.0 0.0)))
(entmake '((0 . "CIRCLE") (8 . "0") (10 0.0 0.0 0.0) (40 . 50.0)))
(entmake '((0 . "ENDBLK")))
(entmake '((0 . "INSERT") (2 . "TFOT_CIRCLE") (10 500.0 500.0 0.0) (41 . -2.0) (42 . 2.0)))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Mirrored uniformly scaled circle remains two exact semicircular segments"
  (and (= 1 (length tfot-result)) (= 2 (length (TFOT:Values tfot-result)))
       (equal (* pi 10000.0) (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-4)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)
(entmake '((0 . "INSERT") (2 . "TFOT_CIRCLE") (10 500.0 500.0 0.0) (41 . 2.0) (42 . 3.0)))
(setq tfot-a (entlast) tfot-count (TFOT:Count) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Nonuniformly stretched curved block is rejected without approximation or leaks"
  (and (null tfot-result) (= tfot-count (TFOT:Count))))
(entdel tfot-a)

;;; Legacy 2D POLYLINE and a translated elevation.
(entmake '((0 . "POLYLINE") (8 . "0") (66 . 1) (70 . 1) (10 0.0 0.0 25.0)))
(foreach tfot-p '((0.0 0.0 0.0) (100.0 0.0 0.0) (100.0 50.0 0.0) (0.0 50.0 0.0))
  (entmake (list '(0 . "VERTEX") (cons 10 tfot-p))))
(entmake '((0 . "SEQEND")))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Legacy 2D POLYLINE retains common WCS elevation"
  (and (= 1 (length tfot-result)) (equal 25.0 (cdr (assoc 38 (entget (caar tfot-result)))) 1e-8)
    (equal 25.0 (caddr (cdr (assoc 10 (entget (caadar tfot-result))))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; Overlapping curved outlines exercise arc/arc intersection and union.
(entmake (TFO:LWData '(((-50.0 0.0) 1.0) ((50.0 0.0) 1.0)) 0.0 "0"))
(setq tfot-a (entlast))
(entmake (TFO:LWData '(((0.0 0.0) 1.0) ((100.0 0.0) 1.0)) 0.0 "0"))
(setq tfot-b (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Overlapping circular plines retain the exact merged curved area"
  (and (= 1 (length tfot-result))
    (equal (+ (/ (* 10000.0 pi) 3.0) (* 1250.0 (sqrt 3.0)))
      (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-4)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Current UCS rotation must not rotate WCS output or move labels.
(command-s "_.UCS" "_Z" "30")
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Rotated UCS preserves WCS outline and label geometry"
  (and (= 1 (length tfot-result)) (equal 5000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-5)
    (member "facade_1_100" (TFOT:Values tfot-result))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (command-s "_.UCS" "_World")

;;; v1.1 label selection is independent of the complete closed outline.
(setq label_mode_ "LONGEST2")
(entmake (TFO:LWData '(((0.0 0.0) 0.0) ((2000.0 0.0) 0.0) ((2010.0 120.0) 0.0) ((0.0 120.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast) tfot-count (TFOT:Count) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "LONGEST2 labels only 2010 and 2000 on the reference trapezoid"
  (and (= 1 (length tfot-result)) (= 2 (length (TFOT:Values tfot-result)))
    (member "facade_1_2010" (TFOT:Values tfot-result)) (member "facade_1_2000" (TFOT:Values tfot-result))))
(TFOT:Assert "LONGEST2 retains full closed outline with two length inserts and one info insert"
  (and (= 4 (length (TFOT:Vertices (car tfot-result))))
    (= 1 (cdr (assoc 70 (entget (caar tfot-result)))))
    (equal 240600.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)
    (= (TFOT:Count) (+ tfot-count 4))))
(setq tfot-mid-ok (= 2 (length (cadar tfot-result))))
(foreach tfot-label (cadar tfot-result)
  (setq tfot-data (entget tfot-label) tfot-pos (cdr (assoc 10 tfot-data)))
  (if (not (and (or (equal tfot-pos '(1005.0 130.0 0.0) 1e-6)
                    (equal tfot-pos '(1000.0 -10.0 0.0) 1e-6))
                (equal 0.0 (cdr (assoc 50 tfot-data)) 1e-8))) (setq tfot-mid-ok nil)))
(TFOT:Assert "Two longest labels retain outward midpoint placement and readable rotation" tfot-mid-ok)
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; Four equal edges must yield two labels, not four labels at the cutoff.
(setq label_mode_ "longest2" tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Equal-length square and lowercase mode still create exactly two real attributes"
  (and (= 2 (length (TFOT:Values tfot-result)))
    (= 2 (length (vl-remove-if-not '(lambda (v) (= v "facade_1_100")) (TFOT:Values tfot-result))))))
(TFOT:Assert "Exact length ties resolve consistently by vertex order"
  (equal '(0 1) (TFO:LabelIndices '(((0.0 0.0) 0.0) ((100.0 0.0) 0.0)
    ((100.0 100.0) 0.0) ((0.0 100.0) 0.0)))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; Two labels for each disconnected outline, not just two for the selection.
(setq label_mode_ "LONGEST2" tfot-a (TFOT:Rect 0.0 0.0 2000.0 50.0)
      tfot-b (TFOT:Rect 3000.0 0.0 100.0 20.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Each disconnected component gets its own two longest labels"
  (and (= 2 (length tfot-result)) (= 4 (length (TFOT:Values tfot-result)))
    (= 2 (length (vl-remove-if-not '(lambda (v) (= v "facade_1_2000")) (TFOT:Values tfot-result))))
    (= 2 (length (vl-remove-if-not '(lambda (v) (= v "facade_1_100")) (TFOT:Values tfot-result))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Rank the transformed block geometry, not its definition's dimensions.
(entmake '((0 . "INSERT") (2 . "TFOT_RECT") (10 0.0 0.0 0.0) (41 . 0.5) (42 . 3.0)))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Stretched block selects its two transformed 300-unit sides"
  (and (= 2 (length (TFOT:Values tfot-result)))
    (= 2 (length (vl-remove-if-not '(lambda (v) (= v "facade_1_300")) (TFOT:Values tfot-result))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; A 314.16-unit semicircular side outranks 250-unit lines even though its
;;; chord is only 200 units. Display precision is not the ranking criterion.
(setq precision_txt_ 2)
(entmake (TFO:LWData '(((0.0 0.0) 1.0) ((200.0 0.0) 0.0) ((200.0 250.0) 0.0) ((0.0 250.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "LONGEST2 ranks actual arc length rather than chord or display text"
  (and (= 2 (length (TFOT:Values tfot-result)))
    (member "facade_1_314.16" (TFOT:Values tfot-result)) (member "facade_1_250.00" (TFOT:Values tfot-result))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (setq precision_txt_ 0)

(setq label_mode_ "INVALID" tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0)
      tfot-count (TFOT:Count) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Invalid label mode fails before creating geometry and retains source"
  (and (null tfot-result) (= tfot-count (TFOT:Count)) (entget tfot-a)))
(entdel tfot-a) (setq label_mode_ "ALL")

;;; v1.2: a separate four-attribute information block belongs to each outline.
(setq label_mode_ "LONGEST2" mat_txt_ "ACP-3MM" station_txt_ "ST-A" floor_txt_ "F02"
      factor_area_ 1.0 precision_area_ 2 height_info_ 10.0 spacing_info_ 1.6 offset_info_ '(0.0 0.0)
      tfot-a (TFOT:Rect 0.0 0.0 200.0 100.0) tfot-result (TFO:Build (TFOT:Set (list tfot-a)))
      tfot-info (TFOT:InfoValues (car tfot-result)))
(TFOT:Assert "Information is one separate INSERT containing exactly AREA MAT STATION FLOOR attributes"
  (and (= 1 (length tfot-result)) (caddar tfot-result)
    (= "INSERT" (cdr (assoc 0 (entget (caddar tfot-result)))))
    (/= (cdr (assoc 2 (entget (caddar tfot-result)))) (cdr (assoc 2 (entget (caadar tfot-result)))))
    (equal '("AREA" "MAT" "STATION" "FLOOR") (mapcar 'car tfot-info))))
(TFOT:Assert "AREA is the numeric outer-polyline area and metadata defaults fill independent fields"
  (equal '(("AREA" . "20000.00") ("MAT" . "ACP-3MM") ("STATION" . "ST-A") ("FLOOR" . "F02")) tfot-info))
(TFOT:Assert "Information block is centered inside a rectangle at the outline elevation"
  (equal '(100.0 50.0 0.0) (cdr (assoc 10 (entget (caddar tfot-result)))) 1e-6))
(setq tfot-info-name (cdr (assoc 2 (entget (caddar tfot-result)))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; Each disconnected outline has its own area, with the same reusable definition.
(setq tfot-a (TFOT:Rect 0.0 0.0 200.0 100.0) tfot-b (TFOT:Rect 500.0 0.0 100.0 300.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))) tfot-areas nil tfot-info-names nil tfot-match T)
(foreach tfot-record tfot-result
  (setq tfot-info (TFOT:InfoValues tfot-record)
        tfot-areas (cons (cdr (assoc "AREA" tfot-info)) tfot-areas)
        tfot-info-names (cons (cdr (assoc 2 (entget (caddr tfot-record)))) tfot-info-names))
  (if (not (equal (atof (cdr (assoc "AREA" tfot-info)))
    (abs (TFO:LoopArea (TFOT:Vertices tfot-record))) 1e-6)) (setq tfot-match nil)))
(TFOT:Assert "Disconnected outlines each receive their own area value"
  (and (= 2 (length tfot-result)) tfot-match (member "20000.00" tfot-areas) (member "30000.00" tfot-areas)))
(TFOT:Assert "Compatible information definitions are reused across outlines and runs"
  (and (= 2 (length tfot-info-names)) (= tfot-info-name (car tfot-info-names) (cadr tfot-info-names))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Area precision and conversion are independent from length display presets.
(setq factor_area_ 0.000001 precision_area_ 4 factor_length_ 0.001)
(entmake (TFO:LWData '(((0.0 0.0) 0.0) ((2000.0 0.0) 0.0) ((2010.0 120.0) 0.0) ((0.0 120.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "AREA conversion from mm2 to m2 uses its own factor and decimal precision"
  (= "0.2406" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)
(setq factor_area_ 1.0 precision_area_ 2 factor_length_ 1.0)
(entmake (TFO:LWData '(((0.0 0.0) 1.0) ((100.0 0.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "AREA includes exact circular-arc sector area"
  (= "3926.99" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; Bounding-box center lies outside this C shape; the block must remain inside.
(entmake (TFO:LWData '(((0.0 0.0) 0.0) ((300.0 0.0) 0.0) ((300.0 50.0) 0.0)
  ((50.0 50.0) 0.0) ((50.0 250.0) 0.0) ((300.0 250.0) 0.0) ((300.0 300.0) 0.0) ((0.0 300.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a)))
      tfot-info-pos (cdr (assoc 10 (entget (caddar tfot-result)))))
(TFOT:Assert "Concave outline places information at an interior point instead of outside bbox center"
  (and (TFO:Inside (TFO:XY tfot-info-pos) (TFO:LoopEdges (TFOT:Vertices (car tfot-result)) T))
    (equal '(25.0 150.0 0.0) tfot-info-pos 1e-6)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

(setq height_info_ 7.0 offset_info_ '(15.0 -7.0))
(entmake (TFO:LWData '(((0.0 0.0) 0.0) ((200.0 0.0) 0.0) ((200.0 100.0) 0.0) ((0.0 100.0) 0.0)) 25.0 "0"))
(setq tfot-a (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a)))
      tfot-info-data (entget (caddar tfot-result)) tfot-info-att (entget (entnext (caddar tfot-result))))
(TFOT:Assert "Information offset, text height, row spacing and elevation follow presets"
  (and (equal '(115.0 43.0 25.0) (cdr (assoc 10 tfot-info-data)) 1e-6)
    (equal 7.0 (cdr (assoc 41 tfot-info-data)) 1e-8)
    (equal 7.0 (cdr (assoc 40 tfot-info-att)) 1e-8)
    (equal '(115.0 59.8 25.0) (cdr (assoc 11 tfot-info-att)) 1e-6)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (setq height_info_ 10.0 offset_info_ '(0.0 0.0))

;;; A foreign block using our preferred name must remain unchanged.
(setq prefix_txt_ "info_collision" block_info_ "info_collision_INFO")
(entmake '((0 . "BLOCK") (2 . "info_collision_INFO") (70 . 0) (10 0.0 0.0 0.0)))
(entmake '((0 . "TEXT") (8 . "0") (10 0.0 0.0 0.0) (40 . 1.0) (1 . "USER BLOCK")))
(entmake '((0 . "ENDBLK")))
(setq tfot-foreign (cdr (assoc -2 (tblsearch "BLOCK" "info_collision_INFO")))
      tfot-foreign-data (entget tfot-foreign) tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Existing block missing required tags is preserved without creating a suffixed name"
  (and (null tfot-result) (not (tblsearch "BLOCK" "info_collision_INFO_2"))
    (equal tfot-foreign-data (entget tfot-foreign))
    (entget tfot-a)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (setq prefix_txt_ "facade_1" block_info_ "facade_1_INFO")

;;; A late error after creating information on two components rolls it all back.
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0) tfot-b (TFOT:Rect 500.0 0.0 100.0 50.0)
      tfot-count (TFOT:Count) TFOT:SavedInfo TFO:Info tfot-info-calls 0)
(defun TFO:Info (block point outline-area / entity)
  (setq entity (TFOT:SavedInfo block point outline-area) tfot-info-calls (1+ tfot-info-calls))
  (TFO:Require (< tfot-info-calls 2) "Intentional failure after creating information blocks.") entity)
(setq tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))) TFO:Info TFOT:SavedInfo)
(TFOT:Assert "Late failure removes information blocks together with outlines and length labels"
  (and (= tfot-info-calls 2) (null tfot-result) (= tfot-count (TFOT:Count)) (entget tfot-a) (entget tfot-b)))
(entdel tfot-a) (entdel tfot-b)
(setq factor_area_ -1.0 tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0) tfot-count (TFOT:Count)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Invalid area factor fails without partial output or source edits"
  (and (null tfot-result) (= tfot-count (TFOT:Count)) (entget tfot-a)))
(entdel tfot-a)
(setq factor_area_ 1.0 mat_txt_ "" station_txt_ "" floor_txt_ "" label_mode_ "ALL")

;;; v1.3 overall envelope includes gaps while retaining actual boundary steps.
(setq outline_mode_ "OVERALL" label_mode_ "LONGEST2"
      tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0) tfot-b (TFOT:Rect 110.0 0.0 100.0 100.0)
      tfot-count (TFOT:Count) tfot-before-a (entget tfot-a) tfot-before-b (entget tfot-b)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Separated panels create one full-width overall outline across their gap"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Vertices (car tfot-result))))
    (equal 21000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)))
(TFOT:Assert "Overall lengths and AREA include the joining gap, with only one information block"
  (and (= 2 (length (TFOT:Values tfot-result))) (= (TFOT:Count) (+ tfot-count 4))
    (= "21000.00" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result)))))
    (= 2 (length (vl-remove-if-not '(lambda (v) (= v "facade_1_210")) (TFOT:Values tfot-result))))))
(TFOT:Assert "Overall joining leaves separated originals unchanged"
  (and (equal tfot-before-a (entget tfot-a)) (equal tfot-before-b (entget tfot-b))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Like the reference: the right panel has a genuine bottom-right step.
(setq tfot-a (TFOT:Rect 0.0 0.0 180.0 100.0) tfot-b (TFOT:Rect 190.0 10.0 30.0 90.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Overall preserves the reference bottom-right step rather than making a bounding box"
  (and (= 1 (length tfot-result)) (= 6 (length (TFOT:Vertices (car tfot-result))))
    (equal 21600.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)
    (not (TFO:Covered '(200.0 5.0) (list (TFO:LoopEdges (TFOT:Vertices (car tfot-result)) T))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

(setq tfot-sources (list (TFOT:Rect 0.0 0.0 100.0 40.0) (TFOT:Rect 110.0 0.0 100.0 40.0)
  (TFOT:Rect 0.0 50.0 100.0 40.0) (TFOT:Rect 110.0 50.0 100.0 40.0))
      tfot-result (TFO:Build (TFOT:Set tfot-sources)))
(TFOT:Assert "Two-row panel grid closes all exterior seams into one complete overall rectangle"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Vertices (car tfot-result))))
    (equal 18900.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)))
(TFOT:DeleteResult tfot-result) (foreach tfot-e tfot-sources (entdel tfot-e))

;;; Joining scale must not bridge the large intended notch of a U assembly.
(setq tfot-sources (list (TFOT:Rect 0.0 0.0 300.0 50.0) (TFOT:Rect 0.0 51.0 50.0 249.0)
  (TFOT:Rect 250.0 51.0 50.0 249.0)) tfot-result (TFO:Build (TFOT:Set tfot-sources)))
(TFOT:Assert "Small assembly seams close without filling a large concave U opening"
  (and (= 1 (length tfot-result)) (= 8 (length (TFOT:Vertices (car tfot-result))))
    (equal 40000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)
    (not (TFO:Covered '(150.0 200.0) (list (TFO:LoopEdges (TFOT:Vertices (car tfot-result)) T))))))
(TFOT:DeleteResult tfot-result) (foreach tfot-e tfot-sources (entdel tfot-e))

;;; No fixed maximum panel gap; arbitrary positive separation still combines.
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0) tfot-b (TFOT:Rect 5100.0 0.0 100.0 100.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Large panel separation is still included in one overall outline"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Vertices (car tfot-result))))
    (equal 520000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-5)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Mixed nested block and polyline with a real gap.
(entmake '((0 . "INSERT") (2 . "TFOT_NESTED") (10 500.0 0.0 0.0)))
(setq tfot-a (entlast) tfot-b (TFOT:Rect 510.0 0.0 100.0 150.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Overall combines transformed nested blocks and plines across a gap"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Vertices (car tfot-result))))
    (equal 46500.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-5)))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Four open lines have two missing corner connections, matching loose CAD lines.
(setq tfot-sources nil)
(foreach tfot-pair '(((0.0 0.0 0.0) (100.0 0.0 0.0)) ((100.0 0.0 0.0) (100.0 99.0 0.0))
  ((99.0 100.0 0.0) (0.0 100.0 0.0)) ((0.0 99.0 0.0) (0.0 0.0 0.0)))
  (entmake (list '(0 . "LINE") '(8 . "0") (cons 10 (car tfot-pair)) (cons 11 (cadr tfot-pair))))
  (setq tfot-sources (cons (entlast) tfot-sources)))
(setq tfot-result (TFO:Build (TFOT:Set tfot-sources)))
(TFOT:Assert "Loose LINE endpoints restore a natural square corner without source edits"
  (and (= 1 (length tfot-result)) (= 1 (cdr (assoc 70 (entget (caar tfot-result)))))
    (equal 10000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)
    (= 4 (length (vl-remove-if-not 'entget tfot-sources)))))
(TFOT:DeleteResult tfot-result) (foreach tfot-e tfot-sources (entdel tfot-e))

;;; An open three-sided pline can now infer its missing closing side.
(entmake (TFO:LWData '(((0.0 0.0) 0.0) ((100.0 0.0) 0.0) ((100.0 100.0) 0.0) ((0.0 100.0) 0.0)) 0.0 "0"))
(setq tfot-a (entlast))
(entmod (subst '(70 . 0) (assoc 70 (entget tfot-a)) (entget tfot-a)))
(setq tfot-before-a (entget tfot-a) tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "OVERALL closes a missing side in copies and preserves the original open polyline"
  (and (= 1 (length tfot-result)) (equal 10000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)
    (equal tfot-before-a (entget tfot-a))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)

;;; Open outside edge must participate in the envelope instead of being dropped.
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0))
(entmake '((0 . "LINE") (8 . "0") (10 100.0 50.0 0.0) (11 150.0 50.0 0.0)))
(setq tfot-b (entlast) tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Overall includes a selected open outside edge in its envelope"
  (and (= 1 (length tfot-result))
    (TFO:Covered '(150.0 50.0) (list (TFO:LoopEdges (TFOT:Vertices (car tfot-result)) T)))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Metadata and length options remain independent from overall construction.
(setq label_mode_ "ALL" tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0) tfot-b (TFOT:Rect 110.0 0.0 100.0 50.0)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "ALL labels the final overall sides, with one AREA MAT STATION FLOOR block"
  (and (= 1 (length tfot-result)) (= 4 (length (TFOT:Values tfot-result)))
    (equal '("AREA" "MAT" "STATION" "FLOOR") (mapcar 'car (TFOT:InfoValues (car tfot-result))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

(setq outline_mode_ "INVALID" tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0) tfot-count (TFOT:Count)
      tfot-result (TFO:Build (TFOT:Set (list tfot-a))))
(TFOT:Assert "Invalid outline mode fails atomically" (and (null tfot-result) (= tfot-count (TFOT:Count))))
(entdel tfot-a) (setq outline_mode_ "OVERALL")

;;; v1.4: exercise the exact build path used by FO, not the legacy label API.
(setq prefix_txt_ "fo14" label_mode_ "ALL" layer_txt_ "TFOT-UNUSED-LENGTH-LAYER"
      tfot-a (TFOT:Rect 0.0 0.0 100.0 100.0))
(entmake '((0 . "INSERT") (2 . "TFOT_RECT") (10 110.0 0.0 0.0)))
(setq tfot-b (entlast) tfot-count (TFOT:Count)
      TFOT:SavedLengthBlock TFO:LabelBlock TFOT:SavedLengthLabel TFO:Label tfot-length-called nil)
(defun TFO:LabelBlock ()
  (setq tfot-length-called T) (TFO:Require nil "FO must not create a LENGTH block definition."))
(defun TFO:Label (block point rotation edge-length)
  (setq tfot-length-called T) (TFO:Require nil "FO must not insert a LENGTH attribute."))
(setq tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a tfot-b)))
      TFO:LabelBlock TFOT:SavedLengthBlock TFO:Label TFOT:SavedLengthLabel)
(TFOT:Assert "FO creates only the overall polyline and one information insert, even with stale ALL mode"
  (and (= 1 (length tfot-result)) (null (cadar tfot-result)) (= (TFOT:Count) (+ tfot-count 2))))
(TFOT:Assert "FO never invokes LENGTH creation or creates its unused definition and layer"
  (and tfot-result (not tfot-length-called) (not (tblsearch "BLOCK" "fo14_LABEL"))
    (not (tblsearch "LAYER" "TFOT-UNUSED-LENGTH-LAYER"))))
(TFOT:Assert "FO retains the correct overall AREA and four metadata attributes"
  (and tfot-result (= "21000.00" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result)))))
    (equal '("AREA" "MAT" "STATION" "FLOOR") (mapcar 'car (TFOT:InfoValues (car tfot-result))))))
(TFOT:Assert "FO's local NONE override preserves the caller's global label mode" (= label_mode_ "ALL"))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

;;; Obsolete length settings must not prevent FO from drawing its outline.
(setq label_mode_ "LONGEST2" height_txt_ 0.0 offset_txt_ -1.0 precision_txt_ "UNUSED" factor_length_ nil
      tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0) tfot-count (TFOT:Count)
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a))))
(TFOT:Assert "FO ignores obsolete length settings and still emits only outline plus information"
  (and (= 1 (length tfot-result)) (null (cadar tfot-result)) (= (TFOT:Count) (+ tfot-count 2))
    (= "5000.00" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result)))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a)
(setq prefix_txt_ "facade_1" layer_txt_ "TA-FACADE-LABEL" label_mode_ "ALL"
      height_txt_ 10.0 offset_txt_ 5.0 precision_txt_ 0 factor_length_ 1.0)

;;; The changed command must not delete or rewrite labels from previous runs.
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0)
      tfot-old-result (TFO:Build (TFOT:Set (list tfot-a))) tfot-old-entities nil)
(foreach tfot-label (cadar tfot-old-result)
  (setq tfot-old-entities (cons tfot-label (cons (entnext tfot-label) tfot-old-entities))))
(setq tfot-old-data (mapcar 'entget tfot-old-entities)
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a))))
(TFOT:Assert "FO retains previously created LENGTH inserts and their attribute values"
  (and (= 1 (length tfot-result)) (null (cadar tfot-result))
    (= 8 (length tfot-old-entities)) (equal tfot-old-data (mapcar 'entget tfot-old-entities))))
(TFOT:DeleteResult tfot-result) (TFOT:DeleteResult tfot-old-result) (entdel tfot-a)

(setq outline_mode_ "SPLIT" tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0)
      tfot-b (TFOT:Rect 500.0 0.0 100.0 50.0) tfot-count (TFOT:Count)
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "FO's SPLIT mode also creates only outlines and information blocks without LENGTH labels"
  (and (= 2 (length tfot-result)) (= (TFOT:Count) (+ tfot-count 4))
    (null (cadr (car tfot-result))) (null (cadr (cadr tfot-result)))
    (= 4 (length (TFOT:InfoValues (car tfot-result))))
    (= 4 (length (TFOT:InfoValues (cadr tfot-result))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)
(setq outline_mode_ "OVERALL")

;;; v1.5: fixed, independent names and insertion from customized definitions.
(setq block_info_ "TFOT_FIXED_INFO" block_length_ "TFOT_FIXED_LENGTH")
(entmake '((0 . "BLOCK") (2 . "TFOT_FIXED_INFO") (70 . 2) (10 10.0 20.0 0.0)))
(entmake '((0 . "TEXT") (8 . "0") (10 8.0 24.0 0.0) (40 . 1.0) (1 . "CUSTOM INFO")))
(foreach tfot-row '(("AREA" 24.0) ("MAT" 22.0) ("STATION" 20.0) ("FLOOR" 18.0) ("EXTRA" 16.0))
  (entmake (list '(0 . "ATTDEF") '(8 . "0") '(62 . 3) '(7 . "Standard")
    (cons 10 (list 13.0 (cadr tfot-row) 0.0)) (cons 11 (list 13.0 (cadr tfot-row) 0.0))
    '(40 . 2.0) '(41 . 0.7) '(50 . 0.25) (cons 2 (car tfot-row)) (cons 3 (car tfot-row))
    '(1 . "KEEP") '(70 . 0) '(72 . 0) '(74 . 2))))
(entmake '((0 . "ENDBLK")))
(entmake '((0 . "BLOCK") (2 . "TFOT_FIXED_LENGTH") (70 . 2) (10 1.0 1.0 0.0)))
(entmake '((0 . "LINE") (8 . "0") (10 0.0 0.0 0.0) (11 8.0 0.0 0.0)))
(entmake '((0 . "ATTDEF") (8 . "0") (62 . 5) (7 . "Standard") (10 4.0 5.0 0.0) (11 4.0 5.0 0.0)
  (40 . 2.0) (41 . 0.8) (50 . 0.125) (2 . "LENGTH") (3 . "LENGTH") (1 . "OLD") (70 . 0) (72 . 2) (74 . 2)))
(entmake '((0 . "ATTDEF") (8 . "0") (7 . "Standard") (10 4.0 2.0 0.0) (40 . 1.0)
  (2 . "NOTE") (3 . "NOTE") (1 . "KEEP-LENGTH") (70 . 0)))
(entmake '((0 . "ENDBLK")))
(setq tfot-fixed-info-data (TFOT:Definition block_info_) tfot-fixed-length-data (TFOT:Definition block_length_)
      prefix_txt_ "first_prefix" style_txt_ "UNUSED_STYLE_NOT_IN_DRAWING" spacing_info_ 9.5 height_info_ 3.0
      mat_txt_ "MAT-A" station_txt_ "ST-1" floor_txt_ "F1")
(setvar "AUNITS" 0) (setvar "ANGBASE" 0.0) (setvar "ANGDIR" 0)
(command-s "_.UCS" "_Z" "30")
(setq tfot-user-ucs (list (getvar "UCSORG") (getvar "UCSXDIR") (getvar "UCSYDIR")))
(setvar "ATTREQ" 1) (setvar "ATTDIA" 1) (setvar "AUNITS" 2) (setvar "ANGBASE" 0.3) (setvar "ANGDIR" 1)
(setq tfot-user-settings (mapcar '(lambda (v) (cons v (getvar v)))
  '("ATTREQ" "ATTDIA" "AUNITS" "ANGBASE" "ANGDIR" "CLAYER" "UCSFOLLOW"))
      tfot-a (TFOT:Rect 0.0 0.0 200.0 100.0) tfot-first (TFO:CommandBuild (TFOT:Set (list tfot-a)))
      tfot-first-info (caddar tfot-first) tfot-area-data (TFOT:Attribute tfot-first-info "AREA"))
(TFOT:Assert "AREA insertion always reuses its configured block despite prefix style and spacing changes"
  (and (= "TFOT_FIXED_INFO" (TFO:Get 2 (entget tfot-first-info) ""))
    (not (tblsearch "BLOCK" "TFOT_FIXED_INFO_2")) (not (tblsearch "BLOCK" "first_prefix_INFO"))
    (equal tfot-fixed-info-data (TFOT:Definition block_info_))))
(TFOT:Assert "Existing AREA base point position height width rotation color and style are preserved"
  (and (= "20000.00" (TFO:Get 1 tfot-area-data ""))
    (equal '(109.0 62.0 0.0) (TFO:Get 11 tfot-area-data nil) 1e-6)
    (equal 6.0 (TFO:Get 40 tfot-area-data 0.0) 1e-8)
    (equal 0.7 (TFO:Get 41 tfot-area-data 0.0) 1e-8)
    (equal 0.25 (TFO:Get 50 tfot-area-data 0.0) 1e-8)
    (= 3 (TFO:Get 62 tfot-area-data 0)) (= "Standard" (TFO:Get 7 tfot-area-data ""))))
(TFOT:Assert "Additional attributes in an existing AREA block keep their defaults"
  (= "KEEP" (TFO:Get 1 (TFOT:Attribute tfot-first-info "EXTRA") "")))
(TFOT:Assert "Native insertion restores the user's UCS and attribute angle and layer settings"
  (and (equal tfot-user-ucs (list (getvar "UCSORG") (getvar "UCSXDIR") (getvar "UCSYDIR")) 1e-9)
    (equal tfot-user-settings (mapcar '(lambda (v) (cons v (getvar v)))
      '("ATTREQ" "ATTDIA" "AUNITS" "ANGBASE" "ANGDIR" "CLAYER" "UCSFOLLOW")) 1e-9)))
(setq tfot-first-values (TFOT:InfoValues (car tfot-first)) prefix_txt_ "second_prefix"
      mat_txt_ "MAT-B" floor_txt_ "F2" tfot-second (TFO:CommandBuild (TFOT:Set (list tfot-a))))
(TFOT:Assert "Changing prefix reuses the same AREA block while only the new reference gets new values"
  (and (= "TFOT_FIXED_INFO" (TFO:Get 2 (entget (caddar tfot-second)) ""))
    (equal tfot-first-values (TFOT:InfoValues (car tfot-first)))
    (= "MAT-B" (cdr (assoc "MAT" (TFOT:InfoValues (car tfot-second)))))
    (= "F2" (cdr (assoc "FLOOR" (TFOT:InfoValues (car tfot-second)))))
    (not (tblsearch "BLOCK" "second_prefix_INFO"))))
(TFOT:DeleteResult tfot-first) (TFOT:DeleteResult tfot-second) (entdel tfot-a)

;;; The legacy LENGTH function has its own fixed block and uses its own ATTDEF.
(setq height_txt_ 2.0 prefix_txt_ "length_A")
(TFO:Layer layer_txt_ color_txt_)
(setq tfot-label-block (TFO:LabelBlock) tfot-label-a (TFO:Label tfot-label-block '(10.0 20.0 0.0) (/ pi 2.0) 123.0)
      tfot-length-data (TFOT:Attribute tfot-label-a "LENGTH") prefix_txt_ "length_B"
      tfot-label-b (TFO:Label (TFO:LabelBlock) '(20.0 30.0 0.0) 0.0 456.0))
(TFOT:Assert "LENGTH independently reuses its configured original block across different prefixes"
  (and (= "TFOT_FIXED_LENGTH" (TFO:Get 2 (entget tfot-label-a) ""))
    (= "TFOT_FIXED_LENGTH" (TFO:Get 2 (entget tfot-label-b) ""))
    (= "length_A_123" (TFO:Get 1 tfot-length-data ""))
    (= "length_B_456" (TFO:Get 1 (TFOT:Attribute tfot-label-b "LENGTH") ""))
    (not (tblsearch "BLOCK" "TFOT_FIXED_LENGTH_2"))
    (not (tblsearch "BLOCK" "length_A_LABEL")) (not (tblsearch "BLOCK" "length_B_LABEL"))))
(TFOT:Assert "LENGTH honors its existing custom ATTDEF layout and leaves AREA definition separate"
  (and (equal '(2.0 26.0 0.0) (TFO:Get 11 tfot-length-data nil) 1e-6)
    (equal 4.0 (TFO:Get 40 tfot-length-data 0.0) 1e-8)
    (equal (+ (/ pi 2.0) 0.125) (TFO:Get 50 tfot-length-data 0.0) 1e-8)
    (= "KEEP-LENGTH" (TFO:Get 1 (TFOT:Attribute tfot-label-a "NOTE") ""))
    (equal tfot-fixed-length-data (TFOT:Definition block_length_))
    (equal tfot-fixed-info-data (TFOT:Definition block_info_))))
(entdel tfot-label-a) (entdel tfot-label-b)
(setvar "AUNITS" 0) (setvar "ANGBASE" 0.0) (setvar "ANGDIR" 0)
(command-s "_.UCS" "_World")

;;; An existing LENGTH name with a missing tag must fail, never get a new name.
(setq block_length_ "TFOT_BAD_LENGTH")
(entmake '((0 . "BLOCK") (2 . "TFOT_BAD_LENGTH") (70 . 0) (10 0.0 0.0 0.0)))
(entmake '((0 . "TEXT") (8 . "0") (10 0.0 0.0 0.0) (40 . 1.0) (1 . "KEEP USER BLOCK")))
(entmake '((0 . "ENDBLK")))
(setq tfot-bad-before (TFOT:Definition block_length_) tfot-check (vl-catch-all-apply 'TFO:LabelBlock nil))
(TFOT:Assert "Missing LENGTH tag fails without changing the original or creating another block"
  (and (vl-catch-all-error-p tfot-check) (not (tblsearch "BLOCK" "TFOT_BAD_LENGTH_2"))
    (equal tfot-bad-before (TFOT:Definition block_length_))))
(setq block_length_ block_info_ tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0) tfot-count (TFOT:Count)
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a))))
(TFOT:Assert "AREA and LENGTH cannot be configured to share one block name"
  (and (null tfot-result) (= tfot-count (TFOT:Count)) (entget tfot-a)))
(entdel tfot-a)
(setq block_info_ "facade_1_INFO" block_length_ "facade_1_LABEL" prefix_txt_ "facade_1"
      style_txt_ "Standard" spacing_info_ 1.6 height_info_ 10.0 height_txt_ 10.0
      mat_txt_ "" station_txt_ "" floor_txt_ "")

;;; v1.6: exclude named references, including nested blocks, before geometry checks.
(setq tfot-saved-exceptions exception_blocks_
      exception_blocks_ (list "tfot_except_frame"))
(entmake '((0 . "BLOCK") (2 . "TFOT_EXCEPT_FRAME") (70 . 0) (10 0.0 0.0 0.0)))
(TFOT:Rect 0.0 0.0 100.0 50.0) (entmake '((0 . "ENDBLK")))
(setq tfot-except-definition (TFOT:Definition "TFOT_EXCEPT_FRAME")
      tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0))
(entmake '((0 . "INSERT") (2 . "TFOT_RECT") (10 100.0 0.0 0.0)))
(setq tfot-b (entlast))
(entmake '((0 . "INSERT") (2 . "TFOT_EXCEPT_FRAME") (10 2000.0 0.0 100.0)))
(setq tfot-except (entlast) tfot-except-before (entget tfot-except)
      tfot-count (TFOT:Count) tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-except tfot-a tfot-b))))
(TFOT:Assert "Mixed selection skips named blocks regardless of case and their different Z does not affect AREA"
  (and (= 1 (length tfot-result)) (null (cadar tfot-result))
    (equal 15000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)
    (= "15000.00" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result)))))))
(TFOT:Assert "Excluded source references and definitions remain unchanged with no temporary geometry leaked"
  (and (= (+ tfot-count 2) (TFOT:Count)) (equal tfot-except-before (entget tfot-except))
    (equal tfot-except-definition (TFOT:Definition "TFOT_EXCEPT_FRAME"))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)

(entmake '((0 . "BLOCK") (2 . "TFOT_EXCEPT_PARENT") (70 . 0) (10 0.0 0.0 0.0)))
(TFOT:Rect 0.0 0.0 100.0 50.0)
(entmake '((0 . "INSERT") (2 . "TFOT_RECT") (10 100.0 0.0 0.0)))
(entmake '((0 . "INSERT") (2 . "TFOT_EXCEPT_FRAME") (10 2000.0 0.0 100.0)))
(entmake '((0 . "ENDBLK")))
(entmake '((0 . "INSERT") (2 . "TFOT_EXCEPT_PARENT") (10 0.0 0.0 0.0)))
(setq tfot-parent (entlast) tfot-parent-definition (TFOT:Definition "TFOT_EXCEPT_PARENT")
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-parent))))
(TFOT:Assert "Nested exceptions are skipped while ordinary geometry and sibling blocks remain in the outline"
  (and (= 1 (length tfot-result))
    (equal 15000.0 (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1e-6)
    (equal tfot-parent-definition (TFOT:Definition "TFOT_EXCEPT_PARENT"))))
(TFOT:DeleteResult tfot-result)
(setq exception_blocks_ (list "TFOT_EXCEPT_PARENT") tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0)
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-parent tfot-a))))
(TFOT:Assert "Excluding a parent skips its entire subtree including otherwise unlisted child blocks"
  (and (= 1 (length tfot-result))
    (= "5000.00" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result)))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-parent)

(entmake '((0 . "BLOCK") (2 . "TFOT_EXCEPT_FRAME_2") (70 . 0) (10 0.0 0.0 0.0)))
(TFOT:Rect 0.0 0.0 100.0 50.0) (entmake '((0 . "ENDBLK")))
(entmake '((0 . "INSERT") (2 . "TFOT_EXCEPT_FRAME_2") (10 100.0 0.0 0.0)))
(setq tfot-b (entlast) exception_blocks_ (list "TFOT_EXCEPT_FRAME")
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Exception names match whole names without excluding similar names"
  (and (= 1 (length tfot-result))
    (= "10000.00" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result)))))))
(TFOT:DeleteResult tfot-result)
(setq exception_blocks_ (list "TFOT_EXCEPT_*")
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "Exception entries are literal block names rather than wildcard patterns"
  (and (= 1 (length tfot-result))
    (= "10000.00" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result)))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-b)
(entmake '((0 . "INSERT") (2 . "TFOT_EXCEPT_FRAME") (10 100.0 0.0 0.0)))
(setq tfot-b (entlast) exception_blocks_ (list)
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a tfot-b))))
(TFOT:Assert "An empty exception list restores ordinary inclusion of a previously excluded name"
  (and (= 1 (length tfot-result))
    (= "10000.00" (cdr (assoc "AREA" (TFOT:InfoValues (car tfot-result)))))))
(TFOT:DeleteResult tfot-result) (entdel tfot-a) (entdel tfot-b)
(setq exception_blocks_ (list "TFOT_EXCEPT_FRAME") tfot-count (TFOT:Count)
      tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-except))))
(TFOT:Assert "Selecting only excluded blocks creates no output and preserves the selected references"
  (and (null tfot-result) (= tfot-count (TFOT:Count)) (equal tfot-except-before (entget tfot-except))))
(entdel tfot-except)
(setq exception_blocks_ (list "TFOT_EXCEPT_FRAME" 42) tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0)
      tfot-count (TFOT:Count) tfot-result (TFO:CommandBuild (TFOT:Set (list tfot-a))))
(TFOT:Assert "Invalid exception entries fail before output or source changes"
  (and (null tfot-result) (= tfot-count (TFOT:Count)) (entget tfot-a)))
(entdel tfot-a) (setq exception_blocks_ tfot-saved-exceptions)

;;; v1.7: a near-coincident shared seam is not proof that an entire panel is a hole.
(load (strcat tfot-root "tests/fixtures/near_coincident_panels.lsp"))
(setq tfot-saved-tolerance tolerance_fo_ tolerance_fo_ 0.01 tfot-sources nil)
(foreach tfot-vertices tfot-near-coincident-panels
  (entmake (TFO:LWData tfot-vertices 0.0 "0")) (setq tfot-sources (cons (entlast) tfot-sources)))
(setq tfot-source-data (mapcar 'entget tfot-sources) tfot-count (TFOT:Count)
      tfot-result (TFO:CommandBuild (TFOT:Set tfot-sources)))
(TFOT:Assert "Actual near-coincident panel seams retain all panels in one overall outline with one INFO"
  (and (= 1 (length tfot-result)) (null (cadar tfot-result))
    (= (+ tfot-count 2) (TFOT:Count))
    (equal '("AREA" "MAT" "STATION" "FLOOR") (mapcar 'car (TFOT:InfoValues (car tfot-result))))))
(setq tfot-near-area (if tfot-result (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result))))))
(TFOT:Assert "Near-coincident outline covers the left panel while preserving the genuine lower-left notch and sources"
  (and tfot-result
    (TFO:Covered '(3176.5 2211.0) (list (TFO:LoopEdges (TFOT:Vertices (car tfot-result)) T)))
    (not (TFO:Covered '(3176.5 1800.0) (list (TFO:LoopEdges (TFOT:Vertices (car tfot-result)) T))))
    (equal tfot-source-data (mapcar 'entget tfot-sources))))
(TFOT:DeleteResult tfot-result)
(setq tfot-result (TFO:CommandBuild (TFOT:Set (reverse tfot-sources))))
(TFOT:Assert "Reversing selection order retains the same overall area for near-coincident seams"
  (and (= 1 (length tfot-result)) tfot-near-area
    (equal tfot-near-area (abs (TFO:LoopArea (TFOT:Vertices (car tfot-result)))) 1.0)))
(TFOT:DeleteResult tfot-result) (foreach tfot-e tfot-sources (entdel tfot-e))
(setq tolerance_fo_ tfot-saved-tolerance)

;;; One undo must remove the whole operation together.
;;; Execute UNDO from the next script command, after the Lisp call returns;
;;; undoing inside a still-running LOAD is not an interactive command test.
(setq tfot-a (TFOT:Rect 0.0 0.0 100.0 50.0) tfot-count (TFOT:Count))
(defun TFOT:AfterUndo ()
  (TFOT:Assert "One UNDO removes all output together and retains the source"
    (and (= tfot-count (TFOT:Count)) (entget tfot-a)))
  (if (entget tfot-a) (entdel tfot-a))
  (write-line (strcat "TOTAL PASS=" (itoa tfot-pass) " FAIL=" (itoa tfot-fail)) tfot-log)
  (close tfot-log)
  (princ (strcat "\nTOTAL PASS=" (itoa tfot-pass) " FAIL=" (itoa tfot-fail) "\n")) (princ))
(princ)
