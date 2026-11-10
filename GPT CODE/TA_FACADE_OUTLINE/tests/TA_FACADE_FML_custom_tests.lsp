;;; v1.13 modes and CUSTOM tests; loaded after the previous FML suite.
(defun TF5:Assert (name ok)
  (if ok (setq tf5-pass (1+ tf5-pass)) (setq tf5-fail (1+ tf5-fail)))
  (write-line (strcat (if ok "PASS " "FAIL ") name) tf5-log)
  (princ (strcat "\n" (if ok "PASS " "FAIL ") name)))
(defun TF5:Labels () (ssget "_X" (list '(0 . "INSERT") (cons 8 layer_maxlength_))))
(defun TF5:ClearLabels (/ ss index)
  (if (setq ss (TF5:Labels))
    (progn (setq index 0) (repeat (sslength ss) (entdel (ssname ss index)) (setq index (1+ index))))))
(setq tf5-log (open (strcat tfot-root "tests/results_fml_custom.txt") "w") tf5-pass 0 tf5-fail 0
  tf5-saved (mapcar '(lambda (name) (cons name (eval name)))
    '(block_maxlength_ mode_maxlength_ name_maxlength_ prefix_maxlength_ factor_maxlength_ precision_maxlength_
      height_maxlength_ offset_maxlength_ layer_maxlength_ color_maxlength_ style_txt_))
  block_maxlength_ "TF5_LABEL" mode_maxlength_ "MAX" name_maxlength_ "TEST CUSTOM"
  prefix_maxlength_ "CUSTOM" factor_maxlength_ 1.0 precision_maxlength_ 2 height_maxlength_ 10.0
  offset_maxlength_ 5.0 layer_maxlength_ "TF5-LABELS" color_maxlength_ 6 style_txt_ "Standard")
(TF5:Assert "New mode names accept preset spaces and legacy aliases but removed LONG 1/SHORT 1 are invalid"
  (and (= "OVERALL" (TFO:FMLMode "OVERALL")) (= "OVERALL" (TFO:FMLMode "ALL"))
    (= "ALL LONG" (TFO:FMLMode "AllLong")) (= "ALL SHORT" (TFO:FMLMode "all short"))
    (= "CUSTOM" (TFO:FMLMode "Custom")) (null (TFO:FMLMode "LONG 1")) (null (TFO:FMLMode "SHORT 1"))))
(setq tf5-bent (TF4:Points '((0.0 300.0) (16.0 300.0) (16.0 224.0) (112.0 16.0)
    (234.0 16.0) (234.0 0.0) (98.0 0.0) (0.0 219.0)) T)
  tf5-before (entget tf5-bent) tf5-count (TF4:Count)
  tf5-result (TFO:SideLengthBuild (TF4:Set (list tf5-bent)) "BENT" "OVERALL"))
(TF5:Assert "OVERALL labels all eight actual sides individually without changing a bent pline"
  (and (= 8 (length tf5-result)) (= (+ 8 tf5-count) (TF4:Count)) (equal tf5-before (entget tf5-bent))
    (equal '(0 1 2 3 4 5 6 7) (mapcar '(lambda (row) (nth 3 row)) tf5-result))))
(TF4:Delete tf5-result)
(setq tf5-result (TFO:SideLengthBuild (TF4:Set (list tf5-bent)) "BENT" "ALL LONG"))
(TF5:Assert "ALL LONG rejects a many-sided bent pline without partial annotations and directs the user to CUSTOM"
  (and (null tf5-result) (= tf5-count (TF4:Count)) (equal tf5-before (entget tf5-bent))))
(setq tf5-result (TFO:CustomLengthBuild (list tf5-bent '(150.0 0.0 0.0)) "BENT"))
(TF5:Assert "CUSTOM labels only the clicked bottom segment of an eight-sided pline, not its perimeter"
  (and (= 1 (length tf5-result)) (= 5 (nth 3 (car tf5-result)))
    (= "CUSTOM,136.00" (TF4:Value (car tf5-result) "LENGTH"))
    (= "BENT" (TF4:Value (car tf5-result) "NAME")) (equal tf5-before (entget tf5-bent))
    (equal '(166.0 -17.5 0.0) (TF4:Position (car tf5-result)) 1e-7)))
(setq tf5-definition (TF4:Definition)) (TF4:Delete tf5-result)
(setq tf5-result (TFO:CustomLengthBuild (list tf5-bent '(64.0 120.0 0.0)) "SLOPING"))
(TF5:Assert "CUSTOM uses the true sloping segment length and its original vertex index"
  (and (= 1 (length tf5-result)) (= 2 (nth 3 (car tf5-result)))
    (equal (distance '(16.0 224.0) '(112.0 16.0)) (nth 2 (car tf5-result)) 1e-7)))
(TF4:Delete tf5-result)
(entmake '((0 . "LINE") (10 100.0 200.0 25.0) (11 400.0 600.0 25.0)))
(setq tf5-line (entlast) tf5-line-before (entget tf5-line)
  tf5-result (TFO:CustomLengthBuild (list tf5-line '(250.0 400.0 25.0)) "LINE"))
(TF5:Assert "CUSTOM LINE inserts one real NAME/LENGTH block at its midpoint clearance and elevation"
  (and (= 1 (length tf5-result)) (= "CUSTOM,500.00" (TF4:Value (car tf5-result) "LENGTH"))
    (equal '(236.0 410.5 25.0) (TF4:Position (car tf5-result)) 1e-7)
    (equal tf5-line-before (entget tf5-line))))
(TF4:Delete tf5-result)
(command "_.UCS" "_Z" 90.0)
(setq tf5-ucs (list (getvar "UCSORG") (getvar "UCSXDIR") (getvar "UCSYDIR"))
  tf5-result (TFO:CustomLengthBuild (list tf5-line (trans '(250.0 400.0 25.0) 0 1)) "UCS"))
(TF5:Assert "CUSTOM interprets nentsel pick points in the active UCS and restores the UCS after insertion"
  (and (= 1 (length tf5-result)) (equal '(236.0 410.5 25.0) (TF4:Position (car tf5-result)) 1e-7)
    (equal tf5-ucs (list (getvar "UCSORG") (getvar "UCSXDIR") (getvar "UCSYDIR")) 1e-9)))
(TF4:Delete tf5-result) (command "_.UCS" "_World")

;;; A genuine nested definition: inner scales/rotates, outer mirrors/translates.
(entmake '((0 . "BLOCK") (2 . "TF5_INNER") (70 . 0) (10 0.0 0.0 0.0)))
(entmake '((0 . "LINE") (10 0.0 0.0 0.0) (11 100.0 0.0 0.0)))
(entmake '((0 . "ENDBLK")))
(setq tf5-child (cdr (assoc -2 (tblsearch "BLOCK" "TF5_INNER"))))
(entmake '((0 . "BLOCK") (2 . "TF5_OUTER") (70 . 0) (10 0.0 0.0 0.0)))
(entmake (list '(0 . "INSERT") '(2 . "TF5_INNER") '(10 0.0 0.0 0.0) '(41 . 2.0) '(42 . 3.0) (cons 50 (/ pi 2.0))))
(entmake '((0 . "ENDBLK")))
(setq tf5-inner (cdr (assoc -2 (tblsearch "BLOCK" "TF5_OUTER"))))
(entmake '((0 . "INSERT") (2 . "TF5_OUTER") (10 500.0 500.0 25.0) (41 . -1.0) (42 . 1.0)))
(setq tf5-nest (entlast) tf5-child-before (mapcar 'entget (list tf5-child tf5-inner tf5-nest))
  tf5-selection (list tf5-child '(500.0 600.0 25.0)
    '((0.0 2.0 0.0) (3.0 0.0 0.0) (0.0 0.0 1.0) (500.0 500.0 25.0)) (list tf5-inner tf5-nest))
  tf5-result (TFO:CustomLengthBuild tf5-selection "NESTED"))
(TF5:Assert "CUSTOM applies the nentsel 4x3 composite matrix to a rotated, mirrored, stretched nested LINE"
  (and (= 1 (length tf5-result)) (= "CUSTOM,200.00" (TF4:Value (car tf5-result) "LENGTH"))
    (equal '(482.5 600.0 25.0) (TF4:Position (car tf5-result)) 1e-7)
    (equal tf5-child-before (mapcar 'entget (list tf5-child tf5-inner tf5-nest)))))
(TF4:Delete tf5-result)
(setq tf5-curve (TF4:Poly '(((0.0 0.0) 0.5) ((200.0 0.0) 0.0) ((200.0 100.0) 0.0) ((0.0 100.0) 0.0)) T 0.0 nil)
  tf5-result (TFO:CustomLengthBuild (list tf5-curve '(100.0 -50.0 0.0)) "ARC"))
(TF5:Assert "CUSTOM picks a curved pline side and writes true arc length rather than its chord"
  (and (= 1 (length tf5-result)) (= 0 (nth 3 (car tf5-result)))
    (= "CUSTOM,231.82" (TF4:Value (car tf5-result) "LENGTH"))
    (equal (vlax-curve-getDistAtParam tf5-curve 1.0) (nth 2 (car tf5-result)) 1e-7)))
(TF4:Delete tf5-result)
(setq tf5-count (TF4:Count) tf5-result (TFO:CustomLengthBuild
  (list tf5-curve '(200.0 -150.0 0.0) '((2.0 0.0 0.0) (0.0 3.0 0.0) (0.0 0.0 1.0) (0.0 0.0 0.0))) "STRETCHED ARC"))
(TF5:Assert "CUSTOM rejects nonuniformly stretched curved plines without approximating or inserting a label"
  (and (null tf5-result) (= tf5-count (TF4:Count))))
(entdel tf5-curve)
(setq tf5-curve (TF4:Poly '(((0.0 0.0) 0.0) ((200.0 0.0) 0.0) ((200.0 100.0) 0.0) ((0.0 100.0) 0.0)) T 25.0 '(0.0 0.0 -1.0))
  tf5-result (TFO:CustomLengthBuild (list tf5-curve '(-200.0 50.0 -25.0)) "REVERSED NORMAL"))
(TF5:Assert "CUSTOM keeps the outside label and WCS elevation for a reversed-normal LWPOLYLINE"
  (and (= 1 (length tf5-result)) (= 1 (nth 3 (car tf5-result)))
    (equal '(-217.5 50.0 -25.0) (TF4:Position (car tf5-result)) 1e-7)))
(TF4:Delete tf5-result) (entdel tf5-curve)
(setq factor_maxlength_ 0.001 precision_maxlength_ 3 prefix_maxlength_ ""
  tf5-result (TFO:CustomLengthBuild (list tf5-line '(250.0 400.0 25.0)) "CONVERTED"))
(TF5:Assert "CUSTOM shares the configured unit conversion, precision and empty-prefix formatting"
  (and (= 1 (length tf5-result)) (= "0.500" (TF4:Value (car tf5-result) "LENGTH"))))
(TF4:Delete tf5-result) (setq factor_maxlength_ 1.0 precision_maxlength_ 2 prefix_maxlength_ "CUSTOM")
(entmake '((0 . "CIRCLE") (10 700.0 500.0 0.0) (40 . 10.0))) (setq tf5-circle (entlast))
(setq tf5-count (TF4:Count) tf5-result (TFO:CustomLengthBuild (list tf5-circle '(710.0 500.0 0.0)) "INVALID"))
(TF5:Assert "Unsupported CUSTOM picks preserve the source and leave no partial label"
  (and (null tf5-result) (= tf5-count (TF4:Count)) (entget tf5-circle)))
(setq tf5-env (mapcar '(lambda (name) (cons name (getvar name))) '("CMDECHO" "OSMODE" "DIMZIN"))
  TF5:SavedInsert TFO:InsertAttributes)
(defun TFO:InsertAttributes (block point scale rotation values layer color)
  (TF5:SavedInsert block point scale rotation values layer color)
  (TFO:Require nil "Simulated failure after CUSTOM insertion."))
(setq tf5-result (TFO:CustomLengthBuild (list tf5-line '(250.0 400.0 25.0)) "FAILURE") TFO:InsertAttributes TF5:SavedInsert)
(TF5:Assert "CUSTOM insertion failure removes only the failed label and restores system variables"
  (and (null tf5-result) (= tf5-count (TF4:Count)) (equal tf5-line-before (entget tf5-line))
    (equal tf5-env (mapcar '(lambda (name) (cons name (getvar name))) '("CMDECHO" "OSMODE" "DIMZIN")))))

;;; Exercise the loop with deterministic picks; the script also tests real nentsel below.
(setq TF5:SavedPick TFO:CustomPick)
(defun TFO:CustomPick (/ item)
  (setq item (car tf5-picks) tf5-picks (cdr tf5-picks))
  (if (eq item 'CANCEL) (quit) item))
(setq tf5-picks (list (list tf5-circle '(710.0 500.0 0.0)) (list tf5-line '(250.0 400.0 25.0))
    (list tf5-bent '(150.0 0.0 0.0)) nil)
  tf5-result (TFO:CustomLengthLoop "LOOP MAT"))
(TF5:Assert "CUSTOM loop continues after invalid picks, inserts immediately per valid pick, and finishes on nil"
  (and (= 2 tf5-result) (= 2 (sslength (TF5:Labels))) (= "CUSTOM" mode_maxlength_) (= "LOOP MAT" name_maxlength_)))
(TF5:ClearLabels)
(setq tf5-picks (list (list tf5-line '(250.0 400.0 25.0)) 'CANCEL (list tf5-bent '(150.0 0.0 0.0)))
  tf5-result (TFO:CustomLengthLoop "CANCEL MAT") TFO:CustomPick TF5:SavedPick)
(TF5:Assert "A cancel-style pick exception ends CUSTOM without losing completed labels or reading more picks"
  (and (= 1 tf5-result) (= 1 (sslength (TF5:Labels))) (= 1 (length tf5-picks))
    (= 0 (logand 8 (getvar "UNDOCTL")))))
(TF5:ClearLabels) (entdel tf5-circle)
(TF5:Assert "CUSTOM and batch modes reuse the original attribute block without changing its definition"
  (and (equal tf5-definition (TF4:Definition)) (not (tblsearch "BLOCK" "TF5_LABEL_2"))))
(defun TF5:AfterNativeCustom (/ ss values index)
  (setq ss (TF5:Labels) index 0)
  (if ss (repeat (sslength ss)
    (setq values (cons (TF4:Value (list nil (ssname ss index)) "LENGTH") values) index (1+ index))))
  (TF5:Assert "Native CUSTOM nentsel loop picks LINE, bent pline segment and nested block then ends on Enter"
    (and ss (= 3 (sslength ss)) (= "CUSTOM" mode_maxlength_) (= "CUSTOM MAT" name_maxlength_)
      (member "CUSTOM,500.00" values) (member "CUSTOM,136.00" values) (member "CUSTOM,200.00" values)
      (equal tf5-before (entget tf5-bent)) (equal tf5-line-before (entget tf5-line))
      (equal tf5-child-before (mapcar 'entget (list tf5-child tf5-inner tf5-nest))))) (princ))
(defun TF5:AfterNativeUndo ()
  (TF5:Assert "One CUSTOM UNDO removes the last pick and retains the previous completed picks"
    (and (TF5:Labels) (= 2 (sslength (TF5:Labels))) (entget tf5-nest)))
  (TF5:ClearLabels) (princ))
(defun TF5:AfterNativeOverall ()
  (TF5:Assert "Native OVERALL labels all sides individually on a many-vertex pline"
    (and (TF5:Labels) (= 8 (sslength (TF5:Labels))) (= "OVERALL" mode_maxlength_)
      (= "OVERALL MAT" name_maxlength_) (equal tf5-before (entget tf5-bent)))) (princ))
(defun TF5:Finish (/ entity pair)
  (TF5:Assert "One OVERALL UNDO removes the entire batch and preserves the bent source"
    (and (not (TF5:Labels)) (equal tf5-before (entget tf5-bent))))
  (foreach entity (list tf5-bent tf5-line tf5-nest) (entdel entity))
  (foreach pair tf5-saved (set (car pair) (cdr pair)))
  (write-line (strcat "TOTAL PASS=" (itoa tf5-pass) " FAIL=" (itoa tf5-fail)) tf5-log) (close tf5-log)
  (princ (strcat "\nCUSTOM TOTAL PASS=" (itoa tf5-pass) " FAIL=" (itoa tf5-fail))) (princ))
(princ)
