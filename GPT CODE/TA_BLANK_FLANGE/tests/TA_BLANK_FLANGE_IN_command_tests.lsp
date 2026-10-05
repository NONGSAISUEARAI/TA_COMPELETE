;; Prepare a separate rectangle away from the other disposable test entities.
(defun TA:BFITEST:Command_setup_ ()
  (setq ta_bfi_log_ (open (strcat ta_bfi_root_ "tests/TA_BLANK_FLANGE_IN_command_results.txt") "w"))
  (setq ta_bfi_pass_ 0)
  (setq ta_bfi_fail_ 0)
  (setq ta_bfi_cmd_pts_ '((20000.0 30000.0) (20100.0 30000.0) (20100.0 30080.0) (20000.0 30080.0)))
  (entmake (append '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 4) (70 . 1)) (mapcar '(lambda (p_) (cons 10 p_)) ta_bfi_cmd_pts_)))
  (setq ta_bfi_cmd_source_ (entlast))
  (setq ta_bfi_cmd_count_ (TA:BFTEST:Entity_count_))
  (setq *TA:BFI:Width* nil *TA:BFI:Ang1* nil *TA:BFI:Ang2* nil)
  (setvar "OSMODE" 0)
  (setvar "CMDECHO" 1)
  (command-s "_.ZOOM" "_Object" ta_bfi_cmd_source_ "")
  (princ)
)

(defun TA:BFITEST:After_first_ ()
  (TA:BFITEST:Assert_ "FF2 command completed and added exactly one outline and one bend"
    (= (TA:BFTEST:Entity_count_) (+ ta_bfi_cmd_count_ 2)))
  (TA:BFITEST:Assert_ "FF2 command saved getreal inputs separately"
    (and (= *TA:BFI:Width* 10.0) (= *TA:BFI:Ang1* 45.0) (= *TA:BFI:Ang2* 45.0)
         (= *TA:BF:Width* 37.0) (= *TA:BF:Ang1* 30.0) (= *TA:BF:Ang2* 60.0)))
  (TA:BFITEST:Assert_ "FF2 command restored settings and kept original on Yes"
    (and (= (getvar "OSMODE") 0) (= (getvar "CMDECHO") 1) (entget ta_bfi_cmd_source_)))
  (setq ta_bfi_cmd_count_ (TA:BFTEST:Entity_count_))
  (princ)
)

(defun TA:BFITEST:After_second_ ()
  (TA:BFITEST:Assert_ "FF2 Enter reused defaults and Undo removed all new geometry"
    (and (= (TA:BFTEST:Entity_count_) ta_bfi_cmd_count_)
         (= *TA:BFI:Width* 10.0) (= *TA:BFI:Ang1* 45.0) (= *TA:BFI:Ang2* 45.0)))
  (TA:BFITEST:Assert_ "Undo all retains original and restores settings"
    (and (entget ta_bfi_cmd_source_) (= (getvar "OSMODE") 0) (= (getvar "CMDECHO") 1)))
  (write-line (strcat "TOTAL PASS=" (itoa ta_bfi_pass_) " FAIL=" (itoa ta_bfi_fail_)) ta_bfi_log_)
  (close ta_bfi_log_)
  (princ)
)

(TA:BFITEST:Command_setup_)
