;;; Run only against a disposable copy of ESTIMATE_C06_REV02.dwg.
(load "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/GPT CODE/TA_FACADE_OUTLINE/TA_FACADE_OUTLINE.lsp")
(setq tfoi-root "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/tmp/ta_facade_outline_validation/real_c06/"
      tfoi-log (open (strcat tfoi-root "trial-results.txt") "w"))
(defun TFOI:Log (text) (write-line text tfoi-log) (princ (strcat "\n" text)))
(defun TFOI:Set (handles / ss handle entity)
  (setq ss (ssadd))
  (foreach handle handles
    (if (setq entity (handent handle)) (ssadd entity ss)
      (TFOI:Log (strcat "MISSING HANDLE " handle)))) ss)
(defun TFOI:Delete (result / row entity)
  (foreach row result
    (foreach entity (append (cons (car row) (cadr row)) (list (caddr row)))
      (if (and entity (entget entity)) (entdel entity)))))
(defun TFOI:InfoValues (entity / data result)
  (while (and (setq entity (entnext entity))
    (/= "SEQEND" (TFO:Get 0 (setq data (entget entity)) "")))
    (if (= "ATTRIB" (TFO:Get 0 data ""))
      (setq result (cons (cons (TFO:Get 2 data "") (TFO:Get 1 data "")) result))))
  (reverse result))
(setq TFOI:OriginalRead TFO:Read)
(defun TFO:Read (entity matrix depth / data found name)
  (setq data (entget entity))
  (if (and (= "INSERT" (TFO:Get 0 data "")) (TFO:ExceptedBlock data))
    (progn
      (setq name (TFO:Get 2 data "") found (assoc name tfoi-skipped))
      (if found (setq tfoi-skipped (subst (cons name (1+ (cdr found))) found tfoi-skipped))
        (setq tfoi-skipped (cons (cons name 1) tfoi-skipped)))))
  (TFOI:OriginalRead entity matrix depth))
(defun TFOI:Trial (label ss / start result row area)
  (setq tfoi-skipped nil start (getvar "MILLISECS") result (TFO:CommandBuild ss))
  (TFOI:Log (strcat label ": selected=" (itoa (sslength ss))
    "; outlines=" (itoa (length result)) "; elapsed-ms=" (itoa (- (getvar "MILLISECS") start))))
  (TFOI:Log (strcat "  skipped=" (vl-princ-to-string tfoi-skipped)))
  (foreach row result
    (setq area (abs (TFO:LoopArea (TFO:LWVertices (entget (car row))))))
    (TFOI:Log (strcat "  outline-area-m2=" (rtos (* area factor_area_) 2 8)
      "; vertices=" (itoa (length (TFO:LWVertices (entget (car row)))))
      "; info-name=" (TFO:Get 2 (entget (caddr row)) "")
      "; values=" (vl-princ-to-string (TFOI:InfoValues (caddr row)))
      "; length-inserts=" (itoa (length (cadr row)))))) result)
(setq tfoi-sources '("31FB9" "31FB8" "31FB6" "31FB5" "31FB4" "31FB2" "31FB1" "31FB0"
                      "31FAE" "31FAD" "31FAC" "31C33" "31C32" "31C31")
      tfoi-data '("32284" "32271" "3225E" "3224B" "32238" "32225" "32212" "321FF" "321EC"
                   "321D9" "321C6" "321B3" "321A0" "3218D")
      tfoi-handles (append tfoi-sources tfoi-data '("32DE3"))
      tfoi-entities (mapcar 'handent tfoi-handles)
      tfoi-before (mapcar 'entget tfoi-entities)
      tfoi-ss (TFOI:Set tfoi-handles) tfoi-source-area 0.0)
(foreach handle tfoi-sources
  (setq tfoi-source-area (+ tfoi-source-area
    (abs (TFO:LoopArea (TFO:LWVertices (entget (handent handle))))))))
(TFOI:Log "SOURCE: 14 panel polylines + 14 panel-code blocks + 1 existing INFO block; old outline excluded from input.")
(TFOI:Log (strcat "Source panel area sum (m2)=" (rtos (* tfoi-source-area factor_area_) 2 8)))
(TFOI:Log (strcat "Existing outline area (m2)=" (rtos (* factor_area_
  (abs (TFO:LoopArea (TFO:LWVertices (entget (handent "32DE2")))))) 2 8)))
(setq tfoi-default-exceptions exception_blocks_
      tfoi-baseline (TFOI:Trial "A: default exception list" tfoi-ss))
(if tfoi-baseline
  (setq tfoi-baseline-area (abs (TFO:LoopArea (TFO:LWVertices (entget (caar tfoi-baseline)))))))
(TFOI:Delete tfoi-baseline)
(setq exception_blocks_ (append tfoi-default-exceptions '("000_CKST-FAMELINE_CEILING06_CODE_PANEL"))
      tfoi-result (TFOI:Trial "B: panel-code block added to exceptions" tfoi-ss))
(if tfoi-result
  (progn
    (setq tfoi-area (abs (TFO:LoopArea (TFO:LWVertices (entget (caar tfoi-result))))))
    (TFOI:Log (strcat "Outline difference from A (m2)="
      (if tfoi-baseline-area (rtos (* factor_area_ (- tfoi-area tfoi-baseline-area)) 2 8) "A failed")))
    (TFOI:Log (strcat "Overall minus source panel area sum (m2)="
      (rtos (* factor_area_ (- tfoi-area tfoi-source-area)) 2 8)))))
(TFOI:Log (strcat "Selected sources unchanged=" (if (equal tfoi-before (mapcar 'entget tfoi-entities)) "YES" "NO")))
(setq tfoi-file (open (strcat tfoi-root "trial-output.lspdata") "w"))
(foreach row tfoi-result
  (foreach entity (list (car row) (caddr row))
    (prin1 (list "ENTITY" (vl-remove-if '(lambda (pair) (= (type (cdr pair)) 'ENAME)) (entget entity))) tfoi-file)
    (write-line "" tfoi-file))
  (prin1 (list "VALUES" (TFOI:InfoValues (caddr row))) tfoi-file) (write-line "" tfoi-file))
(close tfoi-file)
;;; Replace just the old result pair in the trial copy, preserving all sources.
(if tfoi-result (progn (entdel (handent "32DE2")) (entdel (handent "32DE3"))))
(setq TFO:Read TFOI:OriginalRead exception_blocks_ tfoi-default-exceptions)
(close tfoi-log)
(princ)
