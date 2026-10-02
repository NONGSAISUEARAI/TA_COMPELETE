;; Run in a disposable AutoCAD/Core Console drawing only.
(defun TA:BFTEST:Assert_ (label_ ok_)
  (write-line (strcat (if ok_ "PASS " "FAIL ") label_) ta_bft_log_)
  (if ok_
    (setq ta_bft_pass_ (1+ ta_bft_pass_))
    (setq ta_bft_fail_ (1+ ta_bft_fail_)))
  ok_
)

(defun TA:BFTEST:Entity_count_ (/ ss_)
  (if (setq ss_ (ssget "_X")) (sslength ss_) 0)
)

(defun TA:BFTEST:Run_
  (/ pts_ cw_ caps_ outline_ rev_outline_ specs_ cfg_ source_ source_data_
     result_ result_data_ rect_ check_ tilted_ elevation_ clicked_ model_owner_
     paper_source_ paper_output_ oldtab_ p_ shifted_ shift_result_ base_result_ layouts_
     bend_cfg_ bundle_ next_bundle_ old_entities_ before_count_ first_bend_
     second_bend_ bend_source_ bend_source_data_ fold_specs_ pair_data_)
  (setq ta_bft_log_ (open
        (strcat (if (boundp 'ta_bft_root_) ta_bft_root_ "")
                "tests/TA_BLANK_FLANGE_results.txt") "w")
        ta_bft_pass_ 0 ta_bft_fail_ 0)
  (setq pts_ '((0.0 0.0) (100.0 0.0) (100.0 80.0) (0.0 80.0))
        cw_ (reverse pts_) cfg_ (TA:BF:Preset_))
  (TA:BFTEST:Assert_ "valid CCW source" (TA:BF:Simple_polygon_p_ pts_ 1e-7))
  (TA:BFTEST:Assert_ "valid CW source" (TA:BF:Simple_polygon_p_ cw_ 1e-7))
  (TA:BFTEST:Assert_ "signed area" (equal (TA:BF:Area_ pts_) 8000.0 1e-7))
  (setq caps_ (TA:BF:Flange_ '(0.0 0.0) '(100.0 0.0) 10.0 45.0 45.0 1.0 1e-7))
  (TA:BFTEST:Assert_ "same 45 degree input at opposite ends"
    (equal caps_ '((10.0 10.0) (90.0 10.0)) 1e-7))
  (TA:BFTEST:Assert_ "square ends 90/90"
    (equal (TA:BF:Flange_ '(0.0 0.0) '(100.0 0.0) 10.0 90.0 90.0 1.0 1e-7)
           '((0.0 10.0) (100.0 10.0)) 1e-7))
  (TA:BFTEST:Assert_ "unequal end angles 45/90"
    (equal (TA:BF:Flange_ '(0.0 0.0) '(100.0 0.0) 10.0 45.0 90.0 1.0 1e-7)
           '((10.0 10.0) (100.0 10.0)) 1e-7))
  (TA:BFTEST:Assert_ "rotated vertical edge uses local angles"
    (equal (TA:BF:Flange_ '(0.0 0.0) '(0.0 100.0) 10.0 45.0 45.0 1.0 1e-7)
           '((-10.0 10.0) (-10.0 90.0)) 1e-7))
  (TA:BFTEST:Assert_ "reversed picking swaps unequal endpoint angles"
    (equal (TA:BF:Edge_spec_ 1 0 4 10.0 45.0 90.0) '(0 10.0 90.0 45.0)))
  (TA:BFTEST:Assert_ "closing edge supports wraparound"
    (equal (TA:BF:Edge_spec_ 0 3 4 10.0 45.0 90.0) '(3 10.0 90.0 45.0)))
  (TA:BFTEST:Assert_ "non-adjacent vertices rejected"
    (null (TA:BF:Edge_spec_ 0 2 4 10.0 45.0 45.0)))
  (TA:BFTEST:Assert_ "same vertex twice rejected"
    (null (TA:BF:Edge_spec_ 1 1 4 10.0 45.0 45.0)))
  (TA:BFTEST:Assert_ "end cuts cannot collapse flange"
    (null (TA:BF:Flange_ '(0.0 0.0) '(20.0 0.0) 15.0 45.0 45.0 1.0 1e-7)))
  (TA:BFTEST:Assert_ "zero/180 angles rejected"
    (and (null (TA:BF:Flange_ '(0.0 0.0) '(100.0 0.0) 10.0 0.0 45.0 1.0 1e-7))
         (null (TA:BF:Flange_ '(0.0 0.0) '(100.0 0.0) 10.0 45.0 180.0 1.0 1e-7))))
  (setq outline_ (TA:BF:Contour_ pts_ '((2 10.0 45.0 45.0)) 1e-7)
        rev_outline_ (TA:BF:Contour_ cw_ '((0 10.0 45.0 45.0)) 1e-7))
  (TA:BFTEST:Assert_ "outside independent of polygon winding"
    (and (equal (abs (TA:BF:Area_ outline_)) 8900.0 1e-7)
         (equal (abs (TA:BF:Area_ rev_outline_)) 8900.0 1e-7)
         (vl-some '(lambda (p_) (equal p_ '(10.0 90.0) 1e-7)) outline_)
         (vl-some '(lambda (p_) (equal p_ '(10.0 90.0) 1e-7)) rev_outline_)))
  ;; Six-vertex silhouette from the discussion; preserve the small kink.
  (setq rect_ '((0.0 0.0) (500.0 0.0) (550.0 -50.0)
                (630.0 -50.0) (630.0 -110.0) (0.0 -110.0))
        outline_ (TA:BF:Contour_ rect_ '((4 10.0 90.0 90.0) (0 25.0 45.0 45.0)) 1e-7))
  (TA:BFTEST:Assert_ "skipped kink vertices retained"
    (and (member '(550.0 -50.0) outline_) (member '(630.0 -50.0) outline_)
         (TA:BF:Simple_polygon_p_ outline_ 1e-7)))
  (TA:BFTEST:Assert_ "selection order does not change contour"
    (equal outline_ (TA:BF:Contour_ rect_ '((0 25.0 45.0 45.0) (4 10.0 90.0 90.0)) 1e-7)))
  (setq specs_ '((0 10.0 45.0 45.0) (1 10.0 45.0 45.0)
                 (2 10.0 45.0 45.0) (3 10.0 45.0 45.0)))
  (TA:BFTEST:Assert_ "all four flanges join into valid outline"
    (TA:BF:Simple_polygon_p_ (TA:BF:Contour_ pts_ specs_ 1e-7) 1e-7))
  (TA:BFTEST:Assert_ "self-crossing outline rejected"
    (not (TA:BF:Simple_polygon_p_ '((0 0) (100 100) (0 100) (100 0)) 1e-7)))
  (TA:BFTEST:Assert_ "collinear backtracking rejected"
    (not (TA:BF:Simple_polygon_p_ '((0 0) (100 0) (50 0) (100 100) (0 100)) 1e-7)))
  (TA:BFTEST:Assert_ "ordinary collinear vertices retained"
    (TA:BF:Simple_polygon_p_ '((0 0) (50 0) (100 0) (100 100) (0 100)) 1e-7))
  (setq shifted_ (mapcar '(lambda (p_) (mapcar '+ p_ '(10000000.0 -5000000.0))) pts_)
        shift_result_ (TA:BF:Contour_ shifted_ specs_ 1e-7)
        base_result_ (TA:BF:Contour_ pts_ specs_ 1e-7))
  (TA:BFTEST:Assert_ "large world coordinates keep area and topology"
    (and (equal (TA:BF:Area_ shift_result_) (TA:BF:Area_ base_result_) 1e-5)
         (TA:BF:Simple_polygon_p_ shift_result_ 1e-7)))
  (TA:BFTEST:Assert_ "output style prepared" (TA:BF:Ensure_style_ cfg_))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0")
                    (100 . "AcDbPolyline") (90 . 4) (70 . 1))
                  (mapcar '(lambda (p_) (cons 10 p_)) pts_)))
  (setq source_ (entlast) source_data_ (entget source_)
        result_ (TA:BF:Make_outline_ source_ base_result_ cfg_)
        result_data_ (entget result_)
        model_owner_ (cdr (assoc 330 source_data_)))
  (TA:BFTEST:Assert_ "result is one closed LWPOLYLINE"
    (and (= (cdr (assoc 0 result_data_)) "LWPOLYLINE") (= (cdr (assoc 70 result_data_)) 1)
         (= (cdr (assoc 90 result_data_)) (length base_result_))))
  (TA:BFTEST:Assert_ "all three preset properties applied"
    (and (= (cdr (assoc 8 result_data_)) "TA_BLANK_SIZE")
         (= (cdr (assoc 62 result_data_)) 3)
         (= (strcase (cond ((cdr (assoc 6 result_data_))) ("ByLayer"))) "CONTINUOUS")))
  (TA:BFTEST:Assert_ "model space ownership assigned for save"
    (equal (cdr (assoc 330 result_data_)) model_owner_))
  (TA:BFTEST:Assert_ "source geometry and properties untouched" (equal source_data_ (entget source_)))
  ;; Bend markers must exist only along accepted source edges, never offsets
  ;; or unselected edges. Exercise replacement/Undo cleanup on real entities.
  (setq bend_cfg_ (TA:BF:Bend_preset_ cfg_))
  (TA:BFTEST:Assert_ "bend style and dashed linetype prepared"
    (TA:BF:Ensure_style_ bend_cfg_))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0")
                    (100 . "AcDbPolyline") (90 . 6) (70 . 1))
                  (mapcar '(lambda (p_) (cons 10 p_)) rect_)))
  (setq bend_source_ (entlast) bend_source_data_ (entget bend_source_)
        fold_specs_ '((0 25.0 45.0 45.0) (2 10.0 45.0 45.0))
        before_count_ (TA:BFTEST:Entity_count_)
        bundle_ (TA:BF:Make_result_ bend_source_ rect_ fold_specs_
                   (TA:BF:Contour_ rect_ fold_specs_ 1e-7) cfg_)
        first_bend_ (car (cadr bundle_)) second_bend_ (cadr (cadr bundle_)))
  (TA:BFTEST:Assert_ "two selected edges produce exactly two bend lines"
    (and bundle_ (= (length (cadr bundle_)) 2)
         (= (TA:BFTEST:Entity_count_) (+ before_count_ 3))))
  (TA:BFTEST:Assert_ "bend segments follow source edges, including skipped gap"
    (and (equal (TA:BF:Vertices_ first_bend_ 1e-7) '((0.0 0.0) (500.0 0.0)))
         (equal (TA:BF:Vertices_ second_bend_ 1e-7) '((550.0 -50.0) (630.0 -50.0)))))
  (setq pair_data_ (entget first_bend_))
  (TA:BFTEST:Assert_ "bend line is an OPEN two-vertex polyline"
    (and (= (cdr (assoc 0 pair_data_)) "LWPOLYLINE")
         (= (cdr (assoc 90 pair_data_)) 2) (= (cdr (assoc 70 pair_data_)) 0)))
  (TA:BFTEST:Assert_ "bend layer color and linetype independent of outline"
    (and (= (cdr (assoc 8 pair_data_)) "TA_BEND_LINE")
         (= (cdr (assoc 62 pair_data_)) 7)
         (= (strcase (cdr (assoc 6 pair_data_))) "HIDDEN")
         (= (cdr (assoc 8 (entget (car bundle_)))) "TA_BLANK_SIZE")))
  (TA:BFTEST:Assert_ "bend linetype scale applied"
    (equal (cond ((cdr (assoc 48 pair_data_))) (1.0)) 1.0 1e-7))
  (setq old_entities_ (cons (car bundle_) (cadr bundle_))
        fold_specs_ '((0 30.0 30.0 60.0) (2 10.0 45.0 45.0))
        next_bundle_ (TA:BF:Make_result_ bend_source_ rect_ fold_specs_
                        (TA:BF:Contour_ rect_ fold_specs_ 1e-7) cfg_))
  (TA:BF:Erase_entities_ old_entities_)
  (setq bundle_ next_bundle_)
  (TA:BFTEST:Assert_ "editing an existing flange does not accumulate bend lines"
    (and (= (TA:BFTEST:Entity_count_) (+ before_count_ 3))
         (not (vl-some 'entget old_entities_))
         (equal (TA:BF:Vertices_ (car (cadr bundle_)) 1e-7)
                '((0.0 0.0) (500.0 0.0)))))
  (setq fold_specs_ '((0 25.0 45.0 45.0))
        next_bundle_ (TA:BF:Make_result_ bend_source_ rect_ fold_specs_
                        (TA:BF:Contour_ rect_ fold_specs_ 1e-7) cfg_))
  (TA:BF:Erase_entities_ (cons (car bundle_) (cadr bundle_)))
  (setq bundle_ next_bundle_)
  (TA:BFTEST:Assert_ "Undo to one flange leaves exactly one bend line"
    (and (= (TA:BFTEST:Entity_count_) (+ before_count_ 2))
         (= (length (cadr bundle_)) 1)))
  ;; Force a later creation failure after one marker has already been made.
  (TA:BFTEST:Assert_ "partial creation failure rolls back new entities only"
    (and (null (TA:BF:Make_result_ bend_source_ rect_
                 '((0 25.0 45.0 45.0) (999 10.0 45.0 45.0))
                 (TA:BF:Contour_ rect_ fold_specs_ 1e-7) cfg_))
         (= (TA:BFTEST:Entity_count_) (+ before_count_ 2))
         (entget (car bundle_)) (entget (car (cadr bundle_)))))
  (TA:BF:Erase_entities_ (cons (car bundle_) (cadr bundle_)))
  (TA:BF:Erase_entities_ (cons (car bundle_) (cadr bundle_)))
  (TA:BFTEST:Assert_ "cancellation cleanup is safe twice and keeps source"
    (and (= (TA:BFTEST:Entity_count_) before_count_)
         (equal bend_source_data_ (entget bend_source_))))
  (TA:BFTEST:Assert_ "Undo all/no flanges creates neither outline nor bend lines"
    (and (equal (TA:BF:Make_result_ bend_source_ rect_ nil rect_ cfg_) '(nil nil))
         (= (TA:BFTEST:Entity_count_) before_count_)))
  ;; Tilted entity OCS plus rotated/translated current UCS.
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0")
                    (100 . "AcDbPolyline") (90 . 4) (70 . 1) (38 . 12.0)
                    (210 0.0 1.0 0.0))
                  (mapcar '(lambda (p_) (cons 10 p_)) pts_)))
  (setq tilted_ (entlast))
  (command-s "_.UCS" "_World")
  (command-s "_.UCS" "_Origin" '(120.0 220.0 0.0))
  (command-s "_.UCS" "_Z" "35")
  (setq clicked_ (trans '(100.0 0.0 12.0) tilted_ 1))
  (TA:BFTEST:Assert_ "vertex picking converts rotated UCS to entity OCS"
    (= (TA:BF:Nearest_vertex_ clicked_ tilted_ pts_) 1))
  (setq check_ (TA:BF:Make_outline_ tilted_ base_result_ cfg_))
  (TA:BFTEST:Assert_ "tilted normal and elevation preserved"
    (and (equal (cdr (assoc 210 (entget check_))) '(0.0 1.0 0.0) 1e-7)
         (equal (cdr (assoc 38 (entget check_))) 12.0 1e-7)))
  (setq bundle_ (TA:BF:Make_result_ tilted_ pts_ specs_ base_result_ cfg_)
        pair_data_ (entget (car (cadr bundle_))))
  (TA:BFTEST:Assert_ "bend markers preserve tilted OCS plane and elevation"
    (and (equal (cdr (assoc 210 pair_data_)) '(0.0 1.0 0.0) 1e-7)
         (equal (cdr (assoc 38 pair_data_)) 12.0 1e-7)
         (equal (TA:BF:Vertices_ (car (cadr bundle_)) 1e-7) '((0.0 0.0) (100.0 0.0)))))
  (command-s "_.UCS" "_World")
  (setq oldtab_ (getvar "CTAB"))
  ;; Core Console does not expose layoutlist; read the native layout dictionary.
  (setq layouts_
    (vl-remove "Model"
      (mapcar 'cdr
        (vl-remove-if-not '(lambda (d_) (= (car d_) 3))
          (dictsearch (namedobjdict) "ACAD_LAYOUT")))))
  (setvar "CTAB" (car layouts_))
  (if (/= (getvar "CVPORT") 1) (command-s "_.PSPACE"))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0")
                    (100 . "AcDbPolyline") (90 . 4) (70 . 1))
                  (mapcar '(lambda (p_) (cons 10 p_)) pts_)))
  (setq paper_source_ (entlast)
        paper_output_ (TA:BF:Make_outline_ paper_source_ base_result_ cfg_))
  (TA:BFTEST:Assert_ "paper space owner/layout preserved"
    (and (= (cdr (assoc 67 (entget paper_output_))) 1)
         (= (cdr (assoc 410 (entget paper_output_))) (getvar "CTAB"))
         (equal (cdr (assoc 330 (entget paper_output_)))
                (cdr (assoc 330 (entget paper_source_))))))
  (setq bundle_ (TA:BF:Make_result_ paper_source_ pts_ specs_ base_result_ cfg_)
        pair_data_ (entget (car (cadr bundle_))))
  (TA:BFTEST:Assert_ "bend markers stay in source paper space"
    (and (= (cdr (assoc 67 pair_data_)) 1)
         (= (cdr (assoc 410 pair_data_)) (getvar "CTAB"))
         (equal (cdr (assoc 330 pair_data_)) (cdr (assoc 330 (entget paper_source_))))))
  (setvar "CTAB" oldtab_)
  (write-line (strcat "TOTAL PASS=" (itoa ta_bft_pass_) " FAIL=" (itoa ta_bft_fail_)) ta_bft_log_)
  (close ta_bft_log_)
  (princ (strcat "\nTESTS: " (itoa ta_bft_pass_) " passed, " (itoa ta_bft_fail_) " failed."))
  (princ)
)

(TA:BFTEST:Run_)
