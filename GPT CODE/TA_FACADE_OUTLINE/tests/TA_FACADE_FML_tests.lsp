;;; FML integration tests. Use a disposable drawing; continued by run_fml.scr.
(defun TF4:Assert (name ok)
  (if ok (setq tf4-pass (1+ tf4-pass)) (setq tf4-fail (1+ tf4-fail)))
  (write-line (strcat (if ok "PASS " "FAIL ") name) tf4-log)
  (princ (strcat "\n" (if ok "PASS " "FAIL ") name)))
(defun TF4:Poly (vertices closed z normal / data)
  (setq data (TFO:LWData vertices z "0"))
  (if (not closed) (setq data (subst '(70 . 0) (assoc 70 data) data)))
  (if normal (setq data (subst (cons 210 normal) (assoc 210 data) data)))
  (if (not (entmake data)) (progn (princ "\nCannot create FML fixture.") (quit))) (entlast))
(defun TF4:Points (points closed)
  (TF4:Poly (mapcar '(lambda (point) (list point 0.0)) points) closed 0.0 nil))
(defun TF4:Rect (width height)
  (TF4:Points (list '(0.0 0.0) (list width 0.0) (list width height) (list 0.0 height)) T))
(defun TF4:Set (entities / ss entity)
  (setq ss (ssadd)) (foreach entity entities (ssadd entity ss)) ss)
(defun TF4:Count (/ ss) (if (setq ss (ssget "_X")) (sslength ss) 0))
(defun TF4:Delete (result / row) (foreach row result (if (entget (cadr row)) (entdel (cadr row)))))
(defun TF4:Value (row tag / entity data value)
  (setq entity (cadr row))
  (while (and (setq entity (entnext entity)) (/= "SEQEND" (TFO:Get 0 (setq data (entget entity)) "")))
    (if (and (= "ATTRIB" (TFO:Get 0 data "")) (= (strcase tag) (strcase (TFO:Get 2 data ""))))
      (setq value (TFO:Get 1 data "")))) value)
(defun TF4:Position (row) (TFO:Get 10 (entget (cadr row)) nil))
(defun TF4:Definition (/ child data result)
  (setq child (cdr (assoc -2 (tblsearch "BLOCK" block_maxlength_))))
  (while (and child (/= "ENDBLK" (TFO:Get 0 (setq data (entget child)) "")))
    (setq result (cons data result) child (entnext child))) (reverse result))

(setq tf4-log (open (strcat tfot-root "tests/results_fml.txt") "w") tf4-pass 0 tf4-fail 0
      tf4-saved (mapcar '(lambda (name) (cons name (eval name)))
        '(block_maxlength_ mode_maxlength_ name_maxlength_ prefix_maxlength_ factor_maxlength_
          precision_maxlength_ height_maxlength_ offset_maxlength_ layer_maxlength_ color_maxlength_ style_txt_))
      block_maxlength_ "TF4_LABEL" mode_maxlength_ "MAX" name_maxlength_ "TEST MAT"
      prefix_maxlength_ "TF4" factor_maxlength_ 1.0 precision_maxlength_ 2
      height_maxlength_ 10.0 offset_maxlength_ 5.0 layer_maxlength_ "TF4-LABELS" color_maxlength_ 6 style_txt_ "Standard")

(setq tf4-a (TF4:Rect 200.0 100.0) tf4-before (entget tf4-a) tf4-count (TF4:Count)
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "ALU" "LONG")
      tf4-definition (TF4:Definition))
(TF4:Assert "Closed rectangle Long selects both opposite long sides and writes material plus current prefix format"
  (and (= 2 (length tf4-result)) (= (+ tf4-count 2) (TF4:Count))
    (equal '(0 2) (mapcar '(lambda (row) (nth 3 row)) tf4-result))
    (vl-every '(lambda (row) (and (equal 200.0 (nth 2 row) 1e-7)
      (= "ALU" (TF4:Value row "NAME")) (= "TF4,200.00" (TF4:Value row "LENGTH")))) tf4-result)
    (equal tf4-before (entget tf4-a))))
(TF4:Assert "Closed Long labels are outside the top and bottom midpoints"
  (and (= 2 (length tf4-result))
    (equal '((100.0 -17.5 0.0) (100.0 117.5 0.0)) (mapcar 'TF4:Position tf4-result) 1e-7)))
(TF4:Delete tf4-result)
(setq tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "ALU" "SHORT"))
(TF4:Assert "Closed rectangle Short selects both opposite short sides"
  (and (= 2 (length tf4-result)) (equal '(1 3) (mapcar '(lambda (row) (nth 3 row)) tf4-result))
    (vl-every '(lambda (row) (= "TF4,100.00" (TF4:Value row "LENGTH"))) tf4-result)))
(TF4:Assert "Closed Short labels are outside both vertical sides and remain readable"
  (and (= 2 (length tf4-result))
    (equal '((217.5 50.0 0.0) (-17.5 50.0 0.0)) (mapcar 'TF4:Position tf4-result) 1e-7)
    (vl-every '(lambda (row) (equal (/ pi 2.0) (TFO:Get 50 (entget (cadr row)) 0.0) 1e-7)) tf4-result)))
(TF4:Delete tf4-result)
(setq tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "ALU" "ALL"))
(TF4:Assert "All retains all four original rectangle sides" (= 4 (length tf4-result)))
(TF4:Delete tf4-result)
(setq tf4-result (TFO:MaxLengthBuild (TF4:Set (list tf4-a)) "ALU"))
(TF4:Assert "Legacy Max API still returns only one longest side on a four-vertex pline"
  (and (= 1 (length tf4-result)) (= 0 (nth 3 (car tf4-result))) (equal 200.0 (nth 2 (car tf4-result)) 1e-7)))
(TF4:Delete tf4-result) (entdel tf4-a)

;;; Like the supplied image: right side absent, top/bottom present.
(setq tf4-a (TF4:Points '((200.0 100.0) (0.0 100.0) (0.0 0.0) (200.0 0.0)) nil)
      tf4-before (entget tf4-a) tf4-count (TF4:Count)
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "OPEN U" "SHORT"))
(TF4:Assert "Open four-vertex U has just one real Short side and creates no missing-side geometry"
  (and (= 1 (length tf4-result)) (= (+ tf4-count 1) (TF4:Count)) (= 1 (nth 3 (car tf4-result)))
    (equal 100.0 (nth 2 (car tf4-result)) 1e-7) (equal tf4-before (entget tf4-a))))
(TF4:Assert "Open U Short label is outside the left side as in the reference image"
  (and tf4-result (equal '(-17.5 50.0 0.0) (TF4:Position (car tf4-result)) 1e-7)))
(TF4:Delete tf4-result)
(setq tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "OPEN U" "LONG"))
(TF4:Assert "Open U Long labels only its existing top and bottom sides"
  (and (= 2 (length tf4-result)) (equal '(0 2) (mapcar '(lambda (row) (nth 3 row)) tf4-result))
    (equal '((100.0 117.5 0.0) (100.0 -17.5 0.0)) (mapcar 'TF4:Position tf4-result) 1e-7)))
(TF4:Delete tf4-result)
(setq tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "OPEN U" "ALL"))
(TF4:Assert "Existing All mode still labels only the three actual sides of an open U" (= 3 (length tf4-result)))
(TF4:Delete tf4-result) (entdel tf4-a)
(setq tf4-a (TF4:Points '((200.0 0.0) (0.0 0.0) (0.0 100.0) (200.0 100.0)) nil)
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "REVERSED" "SHORT"))
(TF4:Assert "Reversing open-U direction preserves its real Short side and outside placement"
  (and (= 1 (length tf4-result)) (equal '(-17.5 50.0 0.0) (TF4:Position (car tf4-result)) 1e-7)))
(TF4:Delete tf4-result) (entdel tf4-a)

;;; The missing side can instead be one of the long sides.
(setq tf4-a (TF4:Points '((0.0 0.0) (0.0 100.0) (200.0 100.0) (200.0 0.0)) nil)
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "MISSING LONG" "LONG"))
(TF4:Assert "An open frame missing a long side labels only the one real Long side"
  (and (= 1 (length tf4-result)) (= 1 (nth 3 (car tf4-result))) (equal 200.0 (nth 2 (car tf4-result)) 1e-7)))
(TF4:Delete tf4-result)
(setq tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "MISSING LONG" "SHORT"))
(TF4:Assert "An open frame missing a long side retains both real Short sides"
  (and (= 2 (length tf4-result)) (equal '(0 2) (mapcar '(lambda (row) (nth 3 row)) tf4-result))
    (vl-every '(lambda (row) (equal 100.0 (nth 2 row) 1e-7)) tf4-result)))
(TF4:Delete tf4-result) (entdel tf4-a)

(setq tf4-a (TF4:Poly '(((200.0 100.0) 0.0) ((0.0 100.0) 0.0) ((0.0 0.0) 0.0) ((200.0 0.0) 10.0)) nil 0.0 nil)
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "UNUSED BULGE" "LONG"))
(TF4:Assert "Inactive last-vertex bulge of an open pline does not change Long classification"
  (and (= 2 (length tf4-result))
    (vl-every '(lambda (row) (equal 200.0 (nth 2 row) 1e-7)) tf4-result)))
(TF4:Delete tf4-result) (entdel tf4-a)
(setq tf4-a (TF4:Points '((0.0 0.0) (0.0 100.0) (200.0 100.0) (200.0 0.0)) T)
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "CLOCKWISE" "LONG"))
(TF4:Assert "Closed clockwise rectangle selects the correct opposite Long pair"
  (and (= 2 (length tf4-result)) (equal '(1 3) (mapcar '(lambda (row) (nth 3 row)) tf4-result))
    (equal '((100.0 117.5 0.0) (100.0 -17.5 0.0)) (mapcar 'TF4:Position tf4-result) 1e-7)))
(TF4:Delete tf4-result) (entdel tf4-a)

(setq tf4-a (TF4:Poly '(((0.0 0.0) 0.0) ((141.4213562373095 141.4213562373095) 0.0)
    ((70.71067811865476 212.13203435596424) 0.0) ((-70.71067811865476 70.71067811865476) 0.0)) T 25.0 '(0.0 0.0 -1.0))
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "ROTATED" "SHORT"))
(TF4:Assert "Rotated frame with reversed OCS normal retains Short lengths and the correct WCS elevation"
  (and (= 2 (length tf4-result))
    (vl-every '(lambda (row) (and (equal 100.0 (nth 2 row) 1e-7)
      (equal -25.0 (caddr (TF4:Position row)) 1e-7))) tf4-result)))
(TF4:Delete tf4-result) (entdel tf4-a)

(setq tf4-a (TF4:Rect 100.0 100.0)
      tf4-long (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "SQUARE" "LONG")
      tf4-short (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "SQUARE" "SHORT"))
(TF4:Assert "Square ties split deterministically into two complementary opposite pairs"
  (and (= 2 (length tf4-long)) (= 2 (length tf4-short))
    (equal '(0 2) (mapcar '(lambda (row) (nth 3 row)) tf4-long))
    (equal '(1 3) (mapcar '(lambda (row) (nth 3 row)) tf4-short))))
(TF4:Delete tf4-long) (TF4:Delete tf4-short) (entdel tf4-a)

(setq tf4-a (TF4:Rect 200.0 100.0) factor_maxlength_ 0.001 precision_maxlength_ 3
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "CONVERTED" "LONG"))
(TF4:Assert "Long mode applies configured unit conversion, precision and the existing prefix separator"
  (and (= 2 (length tf4-result)) (vl-every '(lambda (row) (= "TF4,0.200" (TF4:Value row "LENGTH"))) tf4-result)))
(TF4:Delete tf4-result)
(setq prefix_maxlength_ "" tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "NO PREFIX" "SHORT"))
(TF4:Assert "Short mode still supports an empty prefix without inserting a leading separator"
  (and (= 2 (length tf4-result)) (vl-every '(lambda (row) (= "0.100" (TF4:Value row "LENGTH"))) tf4-result)))
(TF4:Delete tf4-result) (entdel tf4-a)
(setq prefix_maxlength_ "TF4" factor_maxlength_ 1.0 precision_maxlength_ 2)

(setq tf4-a (TF4:Poly '(((0.0 0.0) 0.5) ((200.0 0.0) 0.0) ((200.0 100.0) 0.0) ((0.0 100.0) 0.0)) T 0.0 nil)
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "CURVED" "LONG"))
(TF4:Assert "Four-vertex curved sides use true arc lengths while keeping the opposite-side pair"
  (and (= 2 (length tf4-result)) (= "TF4,231.82" (TF4:Value (car tf4-result) "LENGTH"))
    (equal (vlax-curve-getDistAtParam tf4-a 1.0) (nth 2 (car tf4-result)) 1e-7)
    (equal 200.0 (nth 2 (cadr tf4-result)) 1e-7)))
(TF4:Delete tf4-result) (entdel tf4-a)
(setq tf4-a (TF4:Rect 200.4 200.1) precision_maxlength_ 0
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "ROUNDING" "LONG"))
(TF4:Assert "Long/Short classification uses unrounded lengths rather than displayed text"
  (and (= 2 (length tf4-result)) (equal '(0 2) (mapcar '(lambda (row) (nth 3 row)) tf4-result))
    (vl-every '(lambda (row) (= "TF4,200" (TF4:Value row "LENGTH"))) tf4-result)))
(TF4:Delete tf4-result) (entdel tf4-a) (setq precision_maxlength_ 2)

;;; Wrong vertex counts must fail before any annotation is inserted.
(setq tf4-a (TF4:Rect 200.0 100.0) tf4-b (TF4:Points '((500.0 0.0) (530.0 0.0) (530.0 40.0)) T)
      tf4-count (TF4:Count) tf4-before (mapcar 'entget (list tf4-a tf4-b))
      tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a tf4-b)) "MIXED COUNT" "LONG"))
(TF4:Assert "Long rejects a mixed 4/3-vertex batch atomically and preserves every source"
  (and (null tf4-result) (= tf4-count (TF4:Count)) (equal tf4-before (mapcar 'entget (list tf4-a tf4-b)))))
(setq tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-b)) "TRIANGLE" "SHORT"))
(TF4:Assert "Short rejects non-four-vertex plines while All/Max remain available for them"
  (and (null tf4-result) (not (TFO:FourVertexSelectionP (TF4:Set (list tf4-a tf4-b))))))
(entdel tf4-a) (entdel tf4-b)
(setq tf4-a (TF4:Points '((0.0 0.0) (0.0 0.0) (200.0 0.0) (200.0 100.0)) T)
      tf4-count (TF4:Count) tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "DUPLICATE" "SHORT"))
(TF4:Assert "Four-vertex frames with a zero-length side fail without partial labels"
  (and (null tf4-result) (= tf4-count (TF4:Count)) (entget tf4-a)))
(entdel tf4-a)

(setq tf4-a (TF4:Rect 200.0 100.0) tf4-count (TF4:Count) TF4:SavedInsert TFO:InsertAttributes tf4-inserts 0
      tf4-env (mapcar '(lambda (name) (cons name (getvar name))) '("CMDECHO" "OSMODE" "DIMZIN")))
(defun TFO:InsertAttributes (block point scale rotation values layer color)
  (setq tf4-inserts (1+ tf4-inserts))
  (if (= tf4-inserts 2) (TFO:Require nil "Simulated Long second-side insert failure."))
  (TF4:SavedInsert block point scale rotation values layer color))
(setq tf4-result (TFO:SideLengthBuild (TF4:Set (list tf4-a)) "ROLLBACK" "LONG") TFO:InsertAttributes TF4:SavedInsert)
(TF4:Assert "Failure on the second Long-side label cleans the first label and restores system variables"
  (and (null tf4-result) (= 2 tf4-inserts) (= tf4-count (TF4:Count)) (entget tf4-a)
    (equal tf4-env (mapcar '(lambda (name) (cons name (getvar name))) '("CMDECHO" "OSMODE" "DIMZIN")))))
(entdel tf4-a)
(TF4:Assert "All new modes reuse the same NAME/LENGTH definition without creating a suffixed block"
  (and (equal tf4-definition (TF4:Definition)) (not (tblsearch "BLOCK" "TF4_LABEL_2"))))

;;; Continue from script commands so native prompts and UNDO are exercised.
(setq tf4-cmd-a (TF4:Rect 200.0 100.0)
      tf4-cmd-b (TF4:Points '((800.0 100.0) (600.0 100.0) (600.0 0.0) (800.0 0.0)) nil))
(entmake '((0 . "LINE") (10 0.0 500.0 0.0) (11 100.0 500.0 0.0))) (setq tf4-cmd-line (entlast))
(setq tf4-cmd-ss (TF4:Set (list tf4-cmd-a tf4-cmd-b tf4-cmd-line))
      tf4-cmd-before (mapcar 'entget (list tf4-cmd-a tf4-cmd-b tf4-cmd-line)))
(setvar "PICKFIRST" 1)
(defun TF4:AfterCommand (mode expected-count material / ss index entity value ok)
  (setq ss (ssget "_X" (list '(0 . "INSERT") (cons 8 layer_maxlength_))) index 0 ok T)
  (if ss (repeat (sslength ss)
    (setq entity (ssname ss index) index (1+ index))
    (if (not (and (= material (TF4:Value (list nil entity) "NAME"))
      (= (if (= mode "LONG") "TF4,200.00" "TF4,100.00") (TF4:Value (list nil entity) "LENGTH")))) (setq ok nil))))
  (TF4:Assert (strcat "Native FML " mode " prompt labels the real sides of closed/open four-vertex plines")
    (and ss (= expected-count (sslength ss)) ok (= (TFO:FMLMode mode) mode_maxlength_) (= material name_maxlength_)
      (equal tf4-cmd-before (mapcar 'entget (list tf4-cmd-a tf4-cmd-b tf4-cmd-line)))))
  (if ss (repeat (sslength ss) (entdel (ssname ss (setq index (1- index)))))) (princ))
(defun TF4:PrepareOther ()
  (setq tf4-triangle (TF4:Points '((1000.0 0.0) (1030.0 0.0) (1030.0 40.0)) T)
        tf4-other-ss (TF4:Set (list tf4-triangle))) (princ))
(defun TF4:AfterOther (/ ss entity)
  (setq ss (ssget "_X" (list '(0 . "INSERT") (cons 8 layer_maxlength_))) entity (if ss (ssname ss 0)))
  (TF4:Assert "A non-four-vertex selection offers All/Max and falls back from remembered Short to Max"
    (and ss (= 1 (sslength ss)) (= "MAX" mode_maxlength_)
      (= "TF4,50.00" (TF4:Value (list nil entity) "LENGTH"))))
  (if entity (entdel entity)) (entdel tf4-triangle)
  (setq tf4-undo-count (TF4:Count)) (princ))
(defun TF4:AfterUndo (/ entity pair)
  (TF4:Assert "One UNDO removes all Short labels for a mixed closed/open batch and retains the sources"
    (and (= tf4-undo-count (TF4:Count))
      (equal tf4-cmd-before (mapcar 'entget (list tf4-cmd-a tf4-cmd-b tf4-cmd-line)))))
  (foreach entity (list tf4-cmd-a tf4-cmd-b tf4-cmd-line) (entdel entity))
  (foreach pair tf4-saved (set (car pair) (cdr pair)))
  (write-line (strcat "TOTAL PASS=" (itoa tf4-pass) " FAIL=" (itoa tf4-fail)) tf4-log)
  (close tf4-log)
  (princ (strcat "\nFML TOTAL PASS=" (itoa tf4-pass) " FAIL=" (itoa tf4-fail))) (princ))
(princ)
