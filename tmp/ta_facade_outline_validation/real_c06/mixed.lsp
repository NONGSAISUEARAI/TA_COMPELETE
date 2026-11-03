(load "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/GPT CODE/TA_FACADE_OUTLINE/TA_FACADE_OUTLINE.lsp")
(setq tfoi-root "C:/Users/tawan.t/Documents/GitHub/TA_COMPELETE/tmp/ta_facade_outline_validation/real_c06/"
      exception_blocks_ (append exception_blocks_ '("000_CKST-FAMELINE_CEILING06_CODE_PANEL"))
      tfoi-mixed-sources '("2C232" "2C231" "2C227" "2C225" "2C224" "2C222" "2C221" "2C217"
        "2C216" "2C215" "2C214" "2C213" "2C212" "2C211" "2C207" "2C1FD" "2C1F3" "2C1E9"
        "2C1DF" "2C1D5" "2C1CB" "2C1C1" "2C1B7")
      tfoi-mixed-data '("2CBE5" "2CBD2" "2CBBF" "2CBAC" "2CB99" "2CB86" "2CB60" "2CB4D" "2CB27"
        "2CB14" "2CB01" "2CAEE" "2CADB" "2CAC8" "2CAB5" "2CAA2" "2CA8F" "2CA7C" "2CA69"
        "2CA56" "2CA43" "2CA30")
      tfoi-mixed-handles (append tfoi-mixed-sources tfoi-mixed-data)
      tfoi-mixed-entities (mapcar 'handent tfoi-mixed-handles)
      tfoi-mixed-before (mapcar 'entget tfoi-mixed-entities)
      tfoi-mixed-ss (ssadd) tfoi-mixed-start (getvar "MILLISECS")
      tfoi-mixed-log (open (strcat tfoi-root "mixed-results.txt") "w"))
(foreach entity tfoi-mixed-entities (if entity (ssadd entity tfoi-mixed-ss)))
(defun TFOI:MixedLog (text) (write-line text tfoi-mixed-log) (princ (strcat "\n" text)))
(setq tfoi-mixed-result (TFO:CommandBuild tfoi-mixed-ss))
(TFOI:MixedLog (strcat "MIXED SOURCE: 11 panel blocks + 11 panel polylines + 1 panel line + 22 panel-code blocks. Selected="
  (itoa (sslength tfoi-mixed-ss)) "; outlines=" (itoa (length tfoi-mixed-result))
  "; elapsed-ms=" (itoa (- (getvar "MILLISECS") tfoi-mixed-start))))
(setq tfoi-mixed-file (open (strcat tfoi-root "mixed-output.lspdata") "w"))
(foreach row tfoi-mixed-result
  (TFOI:MixedLog (strcat "Outline area (m2)="
    (rtos (* factor_area_ (abs (TFO:LoopArea (TFO:LWVertices (entget (car row)))))) 2 8)
    "; vertices=" (itoa (length (TFO:LWVertices (entget (car row)))))
    "; info-name=" (TFO:Get 2 (entget (caddr row)) "")
    "; length-inserts=" (itoa (length (cadr row)))))
  (foreach entity (list (car row) (caddr row))
    (prin1 (list "ENTITY" (vl-remove-if '(lambda (pair) (= (type (cdr pair)) 'ENAME)) (entget entity))) tfoi-mixed-file)
    (write-line "" tfoi-mixed-file))
  (setq entity (caddr row))
  (while (and (setq entity (entnext entity)) (/= "SEQEND" (TFO:Get 0 (entget entity) "")))
    (if (= "ATTRIB" (TFO:Get 0 (entget entity) ""))
      (progn
        (TFOI:MixedLog (strcat "  " (TFO:Get 2 (entget entity) "") "=" (TFO:Get 1 (entget entity) "")))
        (prin1 (list "ATTRIBUTE" (vl-remove-if '(lambda (pair) (= (type (cdr pair)) 'ENAME)) (entget entity))) tfoi-mixed-file)
        (write-line "" tfoi-mixed-file)))))
(TFOI:MixedLog (strcat "Selected source entities unchanged="
  (if (equal tfoi-mixed-before (mapcar 'entget tfoi-mixed-entities)) "YES" "NO")))
(close tfoi-mixed-file) (close tfoi-mixed-log)
;;; Save a view of the tested mixed group in the disposable copy.
(command-s "_.UCS" "_World") (command-s "_.ZOOM" "_Window" "_non" '(58000.0 -260000.0) "_non" '(70500.0 -255500.0))
(princ)
