;;; v1.14: fixed drawing-unit offsets and locked attribute positions.
(defun TF6:Assert (name ok)
  (if ok (setq tf6-pass (1+ tf6-pass)) (setq tf6-fail (1+ tf6-fail)))
  (write-line (strcat (if ok "PASS " "FAIL ") name) tf6-log)
  (princ (strcat "\n" (if ok "PASS " "FAIL ") name)))
(defun TF6:Attributes (root / entity data result)
  (setq entity root)
  (while (and (setq entity (entnext entity)) (/= "SEQEND" (TFO:Get 0 (setq data (entget entity)) "")))
    (if (= "ATTRIB" (TFO:Get 0 data "")) (setq result (cons entity result)))) (reverse result))
(defun TF6:Definitions (name / entity data result)
  (setq entity (cdr (assoc -2 (tblsearch "BLOCK" name))))
  (while (and entity (/= "ENDBLK" (TFO:Get 0 (setq data (entget entity)) "")))
    (if (= "ATTDEF" (TFO:Get 0 data "")) (setq result (cons entity result)))
    (setq entity (entnext entity))) (reverse result))
(defun TF6:LockFlags (entity / pair inside result)
  (foreach pair (entget entity)
    (if (= 100 (car pair)) (setq inside (member (cdr pair) '("AcDbAttribute" "AcDbAttributeDefinition"))))
    (if (and inside (= 280 (car pair))) (setq result (cons (cdr pair) result)))) (reverse result))
(defun TF6:AllLocked (entities)
  (and entities (vl-every '(lambda (entity)
    (and (equal '(0 1) (TF6:LockFlags entity)) (= 0 (logand 2 (TFO:Get 70 (entget entity) 0))))) entities)))
(defun TF6:TextGeometry (entity)
  (mapcar '(lambda (code) (assoc code (entget entity))) '(10 11 40 41 50 7 62 70 72 74 210)))
(setq tf6-log (open (strcat tfot-root "tests/results_placement.txt") "w") tf6-pass 0 tf6-fail 0
  tf6-saved (mapcar '(lambda (name) (cons name (eval name)))
    '(block_maxlength_ mode_maxlength_ name_maxlength_ prefix_maxlength_ factor_maxlength_ precision_maxlength_
      height_maxlength_ offset_maxlength_ offset_xy_maxlength_ layer_maxlength_ color_maxlength_ style_txt_
      block_info_ block_length_ height_info_ offset_info_ layer_info_ factor_area_ precision_area_))
  block_maxlength_ "TF6_LABEL" block_info_ "TF6_INFO" block_length_ "TF6_LEGACY"
  prefix_maxlength_ "TF6" factor_maxlength_ 1.0 precision_maxlength_ 2 height_maxlength_ 2.0
  offset_maxlength_ 8.0 offset_xy_maxlength_ '(17.0 -9.0) layer_maxlength_ "TF6-LABELS" color_maxlength_ 6
  style_txt_ "Standard" height_info_ 2.0 offset_info_ '(17.0 -9.0) layer_info_ "TF6-INFO"
  factor_area_ 1.0 precision_area_ 2
  tf6-source (TF4:Rect 200.0 100.0) tf6-before (entget tf6-source)
  tf6-a (TFO:SideLengthBuild (TF4:Set (list tf6-source)) "SMALL" "ALL LONG")
  height_maxlength_ 200.0 tf6-b (TFO:SideLengthBuild (TF4:Set (list tf6-source)) "LARGE" "ALL LONG"))
(TF6:Assert "FML insertion XY stays fixed when block/text scale changes from 2 to 200"
  (and (= 2 (length tf6-a)) (= 2 (length tf6-b))
    (equal '((117.0 -17.0 0.0) (117.0 99.0 0.0)) (mapcar 'TF4:Position tf6-a) 1e-8)
    (equal (mapcar 'TF4:Position tf6-a) (mapcar 'TF4:Position tf6-b) 1e-8)
    (equal 2.0 (TFO:Get 41 (entget (cadar tf6-a)) nil) 1e-8)
    (equal 200.0 (TFO:Get 41 (entget (cadar tf6-b)) nil) 1e-8) (equal tf6-before (entget tf6-source))))
(TF6:Assert "New FML definitions and every inserted NAME/LENGTH reference have Lock Position with version 0 preserved"
  (and (TF6:AllLocked (TF6:Definitions block_maxlength_))
    (vl-every '(lambda (row) (TF6:AllLocked (TF6:Attributes (cadr row)))) (append tf6-a tf6-b))))
(setq tf6-edit (car (TF6:Attributes (cadar tf6-a))) tf6-data (entget tf6-edit))
(TF6:Assert "Lock Position keeps the attribute value editable"
  (and (entmod (subst '(1 . "EDITED MATERIAL") (assoc 1 tf6-data) tf6-data))
    (= "EDITED MATERIAL" (TFO:Get 1 (entget tf6-edit) "")) (equal '(0 1) (TF6:LockFlags tf6-edit))))
(TF4:Delete tf6-a) (TF4:Delete tf6-b)
(setq offset_maxlength_ 0.0 offset_xy_maxlength_ '(0.0 0.0)
  tf6-a (TFO:SideLengthBuild (TF4:Set (list tf6-source)) "ZERO OFFSET" "MAX"))
(TF6:Assert "A zero distance and zero XY offset place the label exactly at the side midpoint even at scale 200"
  (and (= 1 (length tf6-a)) (equal '(100.0 0.0 0.0) (TF4:Position (car tf6-a)) 1e-8)))
(TF4:Delete tf6-a) (setq offset_maxlength_ 8.0 offset_xy_maxlength_ '(17.0 -9.0))
(setq tf6-fo-a (TFO:CommandBuild (TF4:Set (list tf6-source))) height_info_ 200.0
  tf6-fo-b (TFO:CommandBuild (TF4:Set (list tf6-source))))
(TF6:Assert "FO INFO uses the same unscaled WCS XY offset at text/block scales 2 and 200"
  (and (= 1 (length tf6-fo-a)) (= 1 (length tf6-fo-b))
    (equal '(117.0 41.0 0.0) (TFO:Get 10 (entget (caddar tf6-fo-a)) nil) 1e-8)
    (equal (TFO:Get 10 (entget (caddar tf6-fo-a)) nil) (TFO:Get 10 (entget (caddar tf6-fo-b)) nil) 1e-8)))
(TF6:Assert "All four new INFO ATTDEFs and AREA/MAT/STATION/FLOOR references have locked positions and editable values"
  (and (= 4 (length (TF6:Definitions block_info_))) (TF6:AllLocked (TF6:Definitions block_info_))
    (TF6:AllLocked (TF6:Attributes (caddar tf6-fo-a))) (TF6:AllLocked (TF6:Attributes (caddar tf6-fo-b)))))
(TFOT:DeleteResult tf6-fo-a) (TFOT:DeleteResult tf6-fo-b)
(TFO:LabelBlock)
(TF6:Assert "The legacy separate LENGTH block is also created with Lock Position"
  (TF6:AllLocked (TF6:Definitions block_length_)))
(setq tf6-normal (TF4:Poly '(((0.0 0.0) 0.0) ((200.0 0.0) 0.0) ((200.0 100.0) 0.0) ((0.0 100.0) 0.0)) T 25.0 '(0.0 0.0 -1.0))
  tf6-a (TFO:CustomLengthBuild (list tf6-normal '(-200.0 50.0 -25.0)) "WCS OFFSET"))
(TF6:Assert "CUSTOM adds XY in WCS after OCS conversion without mirroring or scaling the offset"
  (and (= 1 (length tf6-a)) (equal '(-191.0 41.0 -25.0) (TF4:Position (car tf6-a)) 1e-8)))
(TF4:Delete tf6-a) (entdel tf6-normal)

;;; Source block scale changes measured geometry, but never multiplies label offsets.
(entmake '((0 . "BLOCK") (2 . "TF6_SOURCE") (70 . 0) (10 0.0 0.0 0.0)))
(entmake '((0 . "LINE") (10 0.0 0.0 0.0) (11 100.0 0.0 0.0))) (entmake '((0 . "ENDBLK")))
(setq tf6-child (cdr (assoc -2 (tblsearch "BLOCK" "TF6_SOURCE")) ))
(entmake '((0 . "INSERT") (2 . "TF6_SOURCE") (10 500.0 0.0 0.0))) (setq tf6-root-a (entlast))
(entmake '((0 . "INSERT") (2 . "TF6_SOURCE") (10 500.0 300.0 0.0) (41 . 3.0) (42 . 3.0) (43 . 3.0))) (setq tf6-root-b (entlast))
(setq tf6-a (TFO:CustomLengthBuild (list tf6-child '(550.0 0.0 0.0)
    '((1.0 0.0 0.0) (0.0 1.0 0.0) (0.0 0.0 1.0) (500.0 0.0 0.0)) (list tf6-root-a)) "SCALE 1")
  tf6-b (TFO:CustomLengthBuild (list tf6-child '(650.0 300.0 0.0)
    '((3.0 0.0 0.0) (0.0 3.0 0.0) (0.0 0.0 3.0) (500.0 300.0 0.0)) (list tf6-root-b)) "SCALE 3"))
(TF6:Assert "CUSTOM source-block scales 1 and 3 keep the same drawing-unit normal and XY offsets"
  (and (= 1 (length tf6-a)) (= 1 (length tf6-b))
    (equal 100.0 (nth 2 (car tf6-a)) 1e-8) (equal 300.0 (nth 2 (car tf6-b)) 1e-8)
    (equal '(567.0 -1.0 0.0) (TF4:Position (car tf6-a)) 1e-8)
    (equal '(667.0 299.0 0.0) (TF4:Position (car tf6-b)) 1e-8)))
(TF4:Delete tf6-a) (TF4:Delete tf6-b) (entdel tf6-root-a) (entdel tf6-root-b)

;;; Reuse an unlocked custom block with a nonzero base point and an extra tag.
(setq block_maxlength_ "TF6_CUSTOM")
(entmake '((0 . "BLOCK") (2 . "TF6_CUSTOM") (70 . 2) (10 10.0 20.0 0.0)))
(foreach tf6-row '(("NAME" 22.0) ("LENGTH" 18.0) ("EXTRA" 14.0))
  (entmake (list '(0 . "ATTDEF") '(100 . "AcDbEntity") '(8 . "0") '(62 . 3) '(100 . "AcDbText")
    (cons 10 (list 15.0 (cadr tf6-row) 0.0)) (cons 11 (list 15.0 (cadr tf6-row) 0.0))
    '(40 . 2.0) '(41 . 0.8) '(50 . 0.2) '(7 . "Standard") '(1 . "OLD DEFAULT")
    '(100 . "AcDbAttributeDefinition") '(280 . 0) (cons 3 (car tf6-row)) (cons 2 (car tf6-row))
    '(70 . 0) '(74 . 0) '(280 . 0))))
(entmake '((0 . "ENDBLK")))
(setq tf6-def-before (TFOT:Definition block_maxlength_) tf6-attreq (getvar "ATTREQ"))
(setvar "ATTREQ" 0)
(command-s "_.-INSERT" block_maxlength_ "_Scale" 2.0 "_Rotate" "30" "_non" '(300.0 300.0 0.0))
(setq tf6-old (entlast) tf6-old-attrs (TF6:Attributes tf6-old) tf6-old-before (mapcar 'entget tf6-old-attrs))
(setvar "ATTREQ" tf6-attreq)
(setq tf6-new (TFO:LengthBuild 'TFO:InsertAttributes (list (TFO:MaxLengthBlock) '(300.0 300.0 0.0) 2.0 (/ pi 6.0)
  '(("NAME" . "NEW MATERIAL") ("LENGTH" . "TF6,99.00")) layer_maxlength_ color_maxlength_)))
(TF6:Assert "Reusing an unlocked definition locks all new attributes including extra tags while preserving the definition and old reference"
  (and tf6-new (= 3 (length (TF6:Attributes tf6-new))) (TF6:AllLocked (TF6:Attributes tf6-new))
    (vl-every '(lambda (entity) (equal '(0 0) (TF6:LockFlags entity))) tf6-old-attrs)
    (equal tf6-old-before (mapcar 'entget tf6-old-attrs)) (equal tf6-def-before (TFOT:Definition block_maxlength_))
    (not (tblsearch "BLOCK" "TF6_CUSTOM_2"))))
(TF6:Assert "Locking a reused block preserves its custom text positions, height, style, width and rotation"
  (and tf6-new (equal (mapcar 'TF6:TextGeometry tf6-old-attrs)
    (mapcar 'TF6:TextGeometry (TF6:Attributes tf6-new)) 1e-8)
    (= "NEW MATERIAL" (TF4:Value (list nil tf6-new) "NAME"))
    (= "TF6,99.00" (TF4:Value (list nil tf6-new) "LENGTH"))
    (= "OLD DEFAULT" (TF4:Value (list nil tf6-new) "EXTRA"))))
(if tf6-new (entdel tf6-new)) (entdel tf6-old)
(setq offset_xy_maxlength_ '(10.0) tf6-count (TF4:Count)
  tf6-a (TFO:SideLengthBuild (TF4:Set (list tf6-source)) "BAD XY" "OVERALL"))
(TF6:Assert "Invalid XY offset size fails before inserting labels and preserves the source"
  (and (null tf6-a) (= tf6-count (TF4:Count)) (equal tf6-before (entget tf6-source))))
(setq offset_xy_maxlength_ '(10.0 "BAD") tf6-a (TFO:CustomLengthBuild (list tf6-source '(100.0 0.0 0.0)) "BAD XY"))
(TF6:Assert "CUSTOM rejects a nonnumeric XY offset without partial output"
  (and (null tf6-a) (= tf6-count (TF4:Count)) (equal tf6-before (entget tf6-source))))
(entdel tf6-source)
(foreach tf6-pair tf6-saved (set (car tf6-pair) (cdr tf6-pair)))
(write-line (strcat "TOTAL PASS=" (itoa tf6-pass) " FAIL=" (itoa tf6-fail)) tf6-log) (close tf6-log)
(princ (strcat "\nPLACEMENT TOTAL PASS=" (itoa tf6-pass) " FAIL=" (itoa tf6-fail))) (princ)
