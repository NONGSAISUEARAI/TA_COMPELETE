;; FF1 partial-edge tests. Requires the original BF test helpers.
(defun TA:BFPTEST:Assert_ (name_ ok_)
  (write-line (strcat (if ok_ "PASS " "FAIL ") name_) ta_bfp_log_)
  (if ok_ (setq ta_bfp_pass_ (1+ ta_bfp_pass_)) (setq ta_bfp_fail_ (1+ ta_bfp_fail_)))
)

(defun TA:BFPTEST:Geometry_ (/ rect_ result_ full_ reversed_ cfg_ source_ source_data_ pick1_ pick2_ range_ bundle_ count_ tilted_ point_)
  (setq ta_bfp_log_ (open (strcat ta_bfi_root_ "tests/TA_BLANK_FLANGE_PARTIAL_results.txt") "w"))
  (setq ta_bfp_pass_ 0)
  (setq ta_bfp_fail_ 0)
  (setq rect_ '((0.0 0.0) (100.0 0.0) (100.0 80.0) (0.0 80.0)))
  (setq result_ (TA:BF:Contour_ rect_ '((0 10.0 45.0 45.0 0.0 0.5)) 1e-7))
  (TA:BFPTEST:Assert_ "flange ends halfway along original edge"
    (and (equal (TA:BF:Area_ result_) 8400.0 1e-7)
         (equal result_ '((0.0 0.0) (10.0 -10.0) (40.0 -10.0) (50.0 0.0) (100.0 0.0) (100.0 80.0) (0.0 80.0)) 1e-7)
         (TA:BF:Simple_polygon_p_ result_ 1e-7)))
  (setq result_ (TA:BF:Contour_ rect_ '((0 10.0 90.0 90.0 0.2 0.7)) 1e-7))
  (TA:BFPTEST:Assert_ "two interior endpoints retain unflanged portions at both ends"
    (and (equal (TA:BF:Area_ result_) 8500.0 1e-7)
         (equal result_ '((0.0 0.0) (20.0 0.0) (20.0 -10.0) (70.0 -10.0) (70.0 0.0) (100.0 0.0) (100.0 80.0) (0.0 80.0)) 1e-7)))
  (TA:BFPTEST:Assert_ "range-to-vertex does not repeat ending vertex"
    (TA:BF:Simple_polygon_p_ (TA:BF:Contour_ rect_ '((0 10.0 45.0 45.0 0.5 1.0)) 1e-7) 1e-7))
  (TA:BFPTEST:Assert_ "full-edge range remains compatible with original spec"
    (equal (TA:BF:Contour_ rect_ '((0 10.0 45.0 45.0 0.0 1.0)) 1e-7)
           (TA:BF:Contour_ rect_ '((0 10.0 45.0 45.0)) 1e-7) 1e-7))
  (TA:BFPTEST:Assert_ "reverse partial picking swaps asymmetric angles"
    (equal (TA:BF:Range_spec_ '(0 0.7 0.2) 10.0 30.0 60.0) '(0 10.0 60.0 30.0 0.2 0.7)))
  (setq reversed_ (TA:BF:Contour_ (reverse rect_) '((2 10.0 45.0 45.0 0.5 1.0)) 1e-7))
  (TA:BFPTEST:Assert_ "clockwise source still sends partial flange outside"
    (and (equal (abs (TA:BF:Area_ reversed_)) 8400.0 1e-7)
         (vl-some '(lambda (p_) (equal p_ '(40.0 -10.0) 1e-7)) reversed_)))
  (TA:BFPTEST:Assert_ "closing edge supports a partial range"
    (equal (TA:BF:Edge_points_ rect_ '(3 10.0 45.0 45.0 0.25 0.75)) '((0.0 60.0) (0.0 20.0)) 1e-7))
  (TA:BFPTEST:Assert_ "short interval with collapsing end cuts is rejected"
    (null (TA:BF:Contour_ rect_ '((0 10.0 45.0 45.0 0.0 0.1)) 1e-7)))
  (setq cfg_ (TA:BF:Preset_))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 4) (70 . 1)) (mapcar '(lambda (p_) (cons 10 p_)) rect_)))
  (setq source_ (entlast))
  (setq source_data_ (entget source_))
  (command-s "_.ZOOM" "_Object" source_ "")
  (setq pick1_ (TA:BF:Point_on_edges_ '(0.0 0.0 0.0) source_ rect_ 1e-7))
  (setq pick2_ (TA:BF:Point_on_edges_ '(50.0 0.0 0.0) source_ rect_ 1e-7))
  (TA:BFPTEST:Assert_ "vertex keeps both incident edges for second-point disambiguation"
    (and (assoc 0 pick1_) (assoc 3 pick1_)))
  (setq range_ (TA:BF:Pair_range_ pick1_ pick2_ 1e-7))
  (TA:BFPTEST:Assert_ "vertex to midpoint resolves exact selected range" (equal range_ '(0 0.0 0.5) 1e-7))
  (TA:BFPTEST:Assert_ "same point and points on different edges rejected"
    (and (null (TA:BF:Pair_range_ pick2_ pick2_ 1e-7))
         (null (TA:BF:Pair_range_ pick2_ (TA:BF:Point_on_edges_ '(100.0 40.0 0.0) source_ rect_ 1e-7) 1e-7))))
  (TA:BFPTEST:Assert_ "points away from boundary rejected"
    (null (TA:BF:Point_on_edges_ '(50.0 40.0 0.0) source_ rect_ 1e-7)))
  (setq count_ (TA:BFTEST:Entity_count_))
  (setq result_ (TA:BF:Contour_ rect_ '((0 10.0 45.0 45.0 0.0 0.5)) 1e-7))
  (setq bundle_ (TA:BF:Make_result_ source_ rect_ '((0 10.0 45.0 45.0 0.0 0.5)) result_ cfg_))
  (TA:BFPTEST:Assert_ "bend line stops at selected midpoint"
    (and (= (TA:BFTEST:Entity_count_) (+ count_ 2))
         (equal (TA:BF:Vertices_ (car (cadr bundle_)) 1e-7) '((0.0 0.0) (50.0 0.0)) 1e-7)))
  (TA:BFPTEST:Assert_ "source vertices and entity data untouched" (equal source_data_ (entget source_)))
  (TA:BF:Erase_entities_ (cons (car bundle_) (cadr bundle_)))
  (TA:BFPTEST:Assert_ "partial result cleanup removes outline and bend together" (= (TA:BFTEST:Entity_count_) count_))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 4) (70 . 1) (38 . 12.0) (210 0.0 1.0 0.0)) (mapcar '(lambda (p_) (cons 10 p_)) rect_)))
  (setq tilted_ (entlast))
  (command-s "_.UCS" "_Origin" '(120.0 220.0 0.0))
  (command-s "_.UCS" "_Z" "35")
  (setq point_ (trans '(25.0 0.0 12.0) tilted_ 1))
  (TA:BFPTEST:Assert_ "partial picking respects rotated UCS tilted OCS and elevation"
    (equal (cadr (assoc 0 (TA:BF:Point_on_edges_ point_ tilted_ rect_ 1e-7))) 0.25 1e-7))
  (command-s "_.UCS" "_World")
  (princ)
)

(defun TA:BFPTEST:Command_setup_ ()
  (setq ta_bfp_cmd_pts_ '((40000.0 30000.0) (40100.0 30000.0) (40100.0 30080.0) (40000.0 30080.0)))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 4) (70 . 1)) (mapcar '(lambda (p_) (cons 10 p_)) ta_bfp_cmd_pts_)))
  (setq ta_bfp_cmd_source_ (entlast))
  (setq ta_bfp_cmd_count_ (TA:BFTEST:Entity_count_))
  (setvar "OSMODE" 0)
  (setvar "CMDECHO" 1)
  (command-s "_.ZOOM" "_Object" ta_bfp_cmd_source_ "")
  (princ)
)

(defun TA:BFPTEST:Command_check_ ()
  (TA:BFPTEST:Assert_ "FF1 partial edit and Undo leave exactly one outline and bend"
    (= (TA:BFTEST:Entity_count_) (+ ta_bfp_cmd_count_ 2)))
  (TA:BFPTEST:Assert_ "FF1 Undo restores original half-edge bend after changing range"
    (equal (TA:BF:Vertices_ (entlast) 1e-7) '((40000.0 30000.0) (40050.0 30000.0)) 1e-7))
  (TA:BFPTEST:Assert_ "FF1 preserves remembered values and restores settings"
    (and (= *TA:BF:Width* 10.0) (= *TA:BF:Ang1* 45.0) (= *TA:BF:Ang2* 45.0)
         (= (getvar "OSMODE") 0) (= (getvar "CMDECHO") 1) (entget ta_bfp_cmd_source_)))
  (setq ta_bfp_cmd_count_ (TA:BFTEST:Entity_count_))
  (princ)
)

(defun TA:BFPTEST:Second_setup_ ()
  ;; Use a fresh non-overlapping panel so entsel cannot pick the earlier outline.
  (setq ta_bfp_cmd_pts_ '((50000.0 30000.0) (50100.0 30000.0) (50100.0 30080.0) (50000.0 30080.0)))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 4) (70 . 1)) (mapcar '(lambda (p_) (cons 10 p_)) ta_bfp_cmd_pts_)))
  (setq ta_bfp_cmd_source_ (entlast))
  (setq ta_bfp_cmd_count_ (TA:BFTEST:Entity_count_))
  (command-s "_.ZOOM" "_Object" ta_bfp_cmd_source_ "")
  (princ)
)

(defun TA:BFPTEST:Finish_ ()
  (TA:BFPTEST:Assert_ "FF1 reverse interior range produces exact bend endpoints"
    (equal (TA:BF:Vertices_ (entlast) 1e-7) '((50020.0 30000.0) (50070.0 30000.0)) 1e-7))
  (TA:BFPTEST:Assert_ "FF1 keep-original No deletes source safely after successful result"
    (and (null (entget ta_bfp_cmd_source_)) (= (TA:BFTEST:Entity_count_) (1+ ta_bfp_cmd_count_))))
  (write-line (strcat "TOTAL PASS=" (itoa ta_bfp_pass_) " FAIL=" (itoa ta_bfp_fail_)) ta_bfp_log_)
  (close ta_bfp_log_)
  (princ)
)

(TA:BFPTEST:Geometry_)
(TA:BFPTEST:Command_setup_)
