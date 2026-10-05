;; Run only in a disposable Core Console drawing. Load the production file first.
(defun TA:BFITEST:Assert_ (name_ value_)
  (write-line (strcat (if value_ "PASS " "FAIL ") name_) ta_bfi_log_)
  (if value_ (setq ta_bfi_pass_ (1+ ta_bfi_pass_)) (setq ta_bfi_fail_ (1+ ta_bfi_fail_)))
)

(defun TA:BFITEST:Run_ (/ rect_ cw_ concave_ result_ other_ specs_ cfg_ source_ data_ bundle_ count_ tilted_)
  (setq ta_bfi_log_ (open (strcat ta_bfi_root_ "tests/TA_BLANK_FLANGE_IN_results.txt") "w"))
  (setq ta_bfi_pass_ 0)
  (setq ta_bfi_fail_ 0)
  (setq rect_ '((0.0 0.0) (100.0 0.0) (100.0 80.0) (0.0 80.0)))
  (setq cw_ (reverse rect_))
  (setq concave_ '((0.0 0.0) (100.0 0.0) (100.0 100.0) (60.0 100.0) (60.0 40.0) (40.0 40.0) (40.0 100.0) (0.0 100.0)))
  (TA:BFITEST:Assert_ "inside boundary and outside point classification"
    (and (TA:BFI:Point_inside_p_ '(50.0 20.0) rect_ 1e-7)
         (TA:BFI:Point_inside_p_ '(0.0 20.0) rect_ 1e-7)
         (not (TA:BFI:Point_inside_p_ '(50.0 -1.0) rect_ 1e-7))))
  (TA:BFITEST:Assert_ "concave segment must not leave panel even with inside endpoints"
    (not (TA:BFI:Segment_inside_p_ '(20.0 60.0) '(80.0 60.0) concave_ 1e-7)))
  (TA:BFITEST:Assert_ "boundary-collinear segment allowed"
    (TA:BFI:Segment_inside_p_ '(0.0 0.0) '(0.0 70.0) rect_ 1e-7))
  (setq result_ (TA:BFI:Contour_ rect_ '((0 10.0 45.0 45.0)) 1e-7))
  (TA:BFITEST:Assert_ "45 degree bottom flange goes inward and reduces area to 7100"
    (and (equal (TA:BF:Area_ result_) 7100.0 1e-7)
         (equal result_ '((0.0 0.0) (10.0 10.0) (90.0 10.0) (100.0 0.0) (100.0 80.0) (0.0 80.0)) 1e-7)))
  (setq other_ (TA:BFI:Contour_ cw_ '((2 10.0 45.0 45.0)) 1e-7))
  (TA:BFITEST:Assert_ "CW and CCW yield the same physical inward geometry"
    (and (equal (abs (TA:BF:Area_ other_)) 7100.0 1e-7)
         (vl-every '(lambda (p_) (vl-some '(lambda (q_) (equal p_ q_ 1e-7)) other_)) result_)))
  (setq specs_ (list (TA:BF:Edge_spec_ 1 0 4 10.0 45.0 90.0)))
  (TA:BFITEST:Assert_ "reverse pick swaps asymmetric angles"
    (equal (TA:BFI:Contour_ rect_ specs_ 1e-7)
           (TA:BFI:Contour_ rect_ '((0 10.0 90.0 45.0)) 1e-7) 1e-7))
  (setq result_ (TA:BFI:Contour_ rect_ '((0 10.0 90.0 90.0)) 1e-7))
  (TA:BFITEST:Assert_ "square ends remove retracing tips without losing closed outline"
    (and (= (length result_) 4) (equal (TA:BF:Area_ result_) 7000.0 1e-7)
         (TA:BF:Simple_polygon_p_ result_ 1e-7)))
  (setq specs_ '((0 10.0 45.0 45.0) (1 10.0 45.0 45.0) (2 10.0 45.0 45.0) (3 10.0 45.0 45.0)))
  (setq result_ (TA:BFI:Contour_ rect_ specs_ 1e-7))
  (TA:BFITEST:Assert_ "four equal inward mitres join into 80x60 rectangle"
    (and (= (length result_) 4) (equal (TA:BF:Area_ result_) 4800.0 1e-7)
         (TA:BF:Simple_polygon_p_ result_ 1e-7)))
  (TA:BFITEST:Assert_ "edge selection order does not change result"
    (equal result_ (TA:BFI:Contour_ rect_ (reverse specs_) 1e-7) 1e-7))
  (TA:BFITEST:Assert_ "adjacent overlapping square flanges rejected"
    (null (TA:BFI:Contour_ rect_ '((0 10.0 90.0 90.0) (1 10.0 90.0 90.0)) 1e-7)))
  (TA:BFITEST:Assert_ "too deep flange and collapsed panel rejected"
    (and (null (TA:BFI:Contour_ rect_ '((0 90.0 90.0 90.0)) 1e-7))
         (null (TA:BFI:Contour_ rect_ '((0 80.0 90.0 90.0)) 1e-7))))
  (TA:BFITEST:Assert_ "flange end angles crossing outside panel rejected"
    (null (TA:BFI:Contour_ rect_ '((0 10.0 120.0 120.0)) 1e-7)))
  (TA:BFITEST:Assert_ "concave valid flange accepted but crossing notch rejected"
    (and (TA:BFI:Contour_ concave_ '((0 10.0 90.0 90.0)) 1e-7)
         (null (TA:BFI:Contour_ concave_ '((0 60.0 90.0 90.0)) 1e-7))))
  (TA:BFITEST:Assert_ "ordinary collinear source vertices retained"
    (member '(50.0 80.0) (TA:BFI:Contour_ '((0.0 0.0) (100.0 0.0) (100.0 80.0) (50.0 80.0) (0.0 80.0)) '((0 10.0 45.0 45.0)) 1e-7)))
  (setq other_ (mapcar '(lambda (p_) (mapcar '+ p_ '(10000000.0 -5000000.0))) rect_))
  (TA:BFITEST:Assert_ "large coordinates preserve inward area"
    (equal (TA:BF:Area_ (TA:BFI:Contour_ other_ specs_ 1e-7)) 4800.0 1e-5))
  (TA:BFITEST:Assert_ "FF1 outward contour remains unchanged"
    (equal (TA:BF:Area_ (TA:BF:Contour_ rect_ '((0 10.0 45.0 45.0)) 1e-7)) 8900.0 1e-7))
  (setq cfg_ (TA:BF:Preset_))
  (TA:BF:Ensure_style_ cfg_)
  (TA:BF:Ensure_style_ (TA:BF:Bend_preset_ cfg_))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 4) (70 . 1)) (mapcar '(lambda (p_) (cons 10 p_)) rect_)))
  (setq source_ (entlast))
  (setq data_ (entget source_))
  (setq count_ (TA:BFTEST:Entity_count_))
  (setq bundle_ (TA:BF:Make_result_ source_ rect_ specs_ result_ cfg_))
  (TA:BFITEST:Assert_ "inside result creates closed outline and four original-edge bend lines"
    (and bundle_ (= (length (cadr bundle_)) 4) (= (TA:BFTEST:Entity_count_) (+ count_ 5))
         (= (cdr (assoc 70 (entget (car bundle_)))) 1)
         (equal (TA:BF:Vertices_ (car (cadr bundle_)) 1e-7) '((0.0 0.0) (100.0 0.0)))))
  (TA:BFITEST:Assert_ "source unchanged and output has drawing ownership"
    (and (equal data_ (entget source_))
         (equal (cdr (assoc 330 data_)) (cdr (assoc 330 (entget (car bundle_)))))))
  (TA:BF:Erase_entities_ (cons (car bundle_) (cadr bundle_)))
  (TA:BFITEST:Assert_ "inside result cleanup removes only created entities"
    (and (= (TA:BFTEST:Entity_count_) count_) (entget source_)))
  (TA:BFITEST:Assert_ "Undo to no selected edges yields empty result"
    (equal (TA:BF:Make_result_ source_ rect_ nil (TA:BFI:Contour_ rect_ nil 1e-7) cfg_) '(nil nil)))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 4) (70 . 1) (38 . 12.0) (210 0.0 1.0 0.0)) (mapcar '(lambda (p_) (cons 10 p_)) rect_)))
  (setq tilted_ (entlast))
  (setq bundle_ (TA:BF:Make_result_ tilted_ rect_ specs_ result_ cfg_))
  (TA:BFITEST:Assert_ "inside geometry retains tilted OCS and elevation"
    (and (equal (cdr (assoc 210 (entget (car bundle_)))) '(0.0 1.0 0.0) 1e-7)
         (equal (cdr (assoc 38 (entget (car bundle_)))) 12.0 1e-7)))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 5) (70 . 1)) (mapcar '(lambda (p_) (cons 10 p_)) (append rect_ (list (car rect_))))))
  (TA:BFITEST:Assert_ "explicit repeated closing vertex is stripped by shared helper"
    (equal (TA:BF:Vertices_ (entlast) 1e-7) rect_ 1e-7))
  ;; Loading the file again must not clear either command's remembered values.
  (setq *TA:BF:Width* 37.0 *TA:BF:Ang1* 30.0 *TA:BF:Ang2* 60.0)
  (setq *TA:BFI:Width* 12.0 *TA:BFI:Ang1* 45.0 *TA:BFI:Ang2* 90.0)
  (load (strcat ta_bfi_root_ "TA_BLANK_FLANGE.lsp"))
  (TA:BFITEST:Assert_ "reload preserves separate inward/outward input memory"
    (and (= *TA:BF:Width* 37.0) (= *TA:BF:Ang1* 30.0) (= *TA:BF:Ang2* 60.0)
         (= *TA:BFI:Width* 12.0) (= *TA:BFI:Ang1* 45.0) (= *TA:BFI:Ang2* 90.0)))
  (write-line (strcat "TOTAL PASS=" (itoa ta_bfi_pass_) " FAIL=" (itoa ta_bfi_fail_)) ta_bfi_log_)
  (close ta_bfi_log_)
  (princ)
)

(TA:BFITEST:Run_)
