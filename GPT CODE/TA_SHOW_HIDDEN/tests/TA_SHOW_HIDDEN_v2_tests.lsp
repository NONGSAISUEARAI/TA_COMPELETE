;;; Regression: material hatches must not substitute for the WIPEOUT silhouette.
;;; Run after TA_SHOW_HIDDEN_tests.lsp, in its disposable full-AutoCAD drawing.
(setq sht-log (open (strcat sht-root "tests/results-v2.txt") "w")
      sht-pass 0 sht-fail 0)

(defun SHT:V2Build (sources masks scale mode / result)
  (setq result (TA:SHW:BuildMode
    (mapcar 'vlax-vla-object->ename sources)
    (mapcar 'vlax-vla-object->ename masks) scale mode))
  (write-line (strcat "BUILD " mode ": "
    (if TA:SHW-LastError TA:SHW-LastError "OK")
    " count=" (itoa (length result)) " length=" (rtos (SHT:Len result) 2 8)) sht-log)
  result)

(defun SHT:V2Run (/ source material-outline material wipe-outline wipe out before
                    block array insertion nested transformed original oldlts
                    pattern obj expected owner scale shape space0 outline0
                    arcblock arcref arc0 arcmask outline1 a b length0)
  (setq source (SHT:Line '(195.0 5.0 0.0) '(215.0 5.0 0.0))
        material-outline (SHT:Rect 200.0 0.0 201.0 10.0)
        material (SHT:Hatch (list material-outline) 0)
        wipe-outline (SHT:Rect 204.0 0.0 210.0 10.0))
  (sssetfirst nil nil)
  (command-s "_.WIPEOUT" "_Polyline" (vlax-vla-object->ename wipe-outline) "_No")
  (setq wipe (vlax-ename->vla-object (entlast))
        out (SHT:V2Build (list source) (list material wipe) 'Auto "Auto"))
  (SHT:Assert "mixed masks use only actual WIPEOUT, excluding unrelated material hatch"
    (and (= 1 (length out)) (equal 6.0 (SHT:Len out) 1e-6)
         (equal '(204.0 5.0 0.0) (vlax-curve-getStartPoint (car out)) 1e-6)))
  (SHT:Remove out)
  (setq before (SHT:Count)
        out (SHT:V2Build (list source) (list material) 'Auto "Wipeout"))
  (SHT:Assert "SHW refuses hatch-only blockers instead of creating wrong short fragments"
    (and (null out) TA:SHW-LastError (= before (SHT:Count))))
  (setq out (SHT:V2Build (list source) (list material wipe) 'Auto "Hatch"))
  (SHT:Assert "explicit hatch mode still supports hatch-only overlaps"
    (and (= 1 (length out)) (equal 1.0 (SHT:Len out) 1e-6)))
  (SHT:Remove out)
  ;; All three entities occur inside one assembly block, just like a material
  ;; section with background masking. The generated line must stay outside it.
  (setq block (vla-Add (vla-get-Blocks sht-doc)
    (vlax-3d-point '(0.0 0.0 0.0)) "SHT_V2_ASSEMBLY")
        array (vlax-make-safearray vlax-vbObject '(0 . 2)))
  (vlax-safearray-fill array (list source material wipe))
  (vla-CopyObjects sht-doc (vlax-make-variant array) block)
  (setq insertion (vla-InsertBlock sht-space (vlax-3d-point '(0.0 100.0 0.0))
    "SHT_V2_ASSEMBLY" 1.0 1.0 1.0 0.0)
        original (entget (vlax-vla-object->ename insertion))
        before (SHT:Count)
        out (SHT:V2Build (list insertion) (list insertion) 'Auto "Wipeout"))
  (SHT:Assert "one assembly selection finds nested WIPEOUT and reveals the complete covered line"
    (and (= 1 (length out)) (equal 6.0 (SHT:Len out) 1e-6)
         (equal '(204.0 105.0 0.0) (vlax-curve-getStartPoint (car out)) 1e-6)))
  (SHT:Assert "mixed assembly keeps definition and insertion unchanged; no working geometry remains"
    (and (= 3 (vla-get-Count block))
         (equal original (entget (vlax-vla-object->ename insertion)))
         (= (+ before (length out)) (SHT:Count))
         (eq (vlax-vla-object->ename sht-space)
           (cdr (assoc 330 (entget (vlax-vla-object->ename (car out))))))))
  (SHT:Remove out)
  (setq nested (vla-Add (vla-get-Blocks sht-doc)
    (vlax-3d-point '(0.0 0.0 0.0)) "SHT_V2_NESTED"))
  (vla-InsertBlock nested (vlax-3d-point '(0.0 0.0 0.0))
    "SHT_V2_ASSEMBLY" 1.0 1.0 1.0 0.0)
  (setq transformed (vla-InsertBlock sht-space (vlax-3d-point '(500.0 500.0 0.0))
    "SHT_V2_NESTED" -2.0 0.5 1.0 (/ pi 2.0))
        before (SHT:Count)
        out (SHT:V2Build (list transformed) (list transformed) 'Auto "Wipeout"))
  (SHT:Assert "nested mirrored rotated nonuniform assembly preserves full wipeout coverage"
    (and (= 1 (length out)) (equal 12.0 (SHT:Len out) 1e-5)
         (= (+ before (length out)) (SHT:Count))))
  (SHT:Remove out)
  ;; Short fabricated-section legs should show several dashes rather than only
  ;; endpoint marks, even when the drawing has a very large global LTSCALE.
  (setq oldlts (getvar "LTSCALE"))
  (setvar "LTSCALE" 1000.0)
  (setq out (SHT:V2Build (list source) (list wipe) 'Auto "Wipeout")
        pattern (cdr (assoc 40 (tblsearch "LTYPE" "HIDDEN"))))
  (SHT:Assert "auto linetype scale fits at least four full dash periods"
    (and out (>= (/ (SHT:Len out)
      (* pattern (getvar "LTSCALE") (vla-get-LinetypeScale (car out)))) 3.999)))
  (SHT:Assert "auto linetype calculation preserves the drawing LTSCALE"
    (= 1000.0 (getvar "LTSCALE")))
  (SHT:Remove out) (setvar "LTSCALE" oldlts)
  (setq out (SHT:V2Build (list source) (list wipe) 0.0123 "Wipeout"))
  (SHT:Assert "manual linetype scale remains exact"
    (and out (equal 0.0123 (vla-get-LinetypeScale (car out)) 1e-10)))
  (SHT:Remove out)
  (setq out (SHT:V2Build (list transformed) (list transformed) 'Auto "Hatch"))
  (SHT:Assert "nonuniform mixed assembly still supports explicit material-hatch mode"
    (and out (equal 2.0 (SHT:Len out) 0.002)))
  (SHT:Remove out)
  (setq out (SHT:V2Build (list transformed) (list transformed) 'Auto "Auto"))
  (SHT:Assert "nonuniform Auto mode prefers WIPEOUT over transformed material hatch"
    (and out (equal 12.0 (SHT:Len out) 1e-5)))
  (SHT:Remove out)
  ;; Folded-section fillets: a reflected nonuniform quarter arc with a nonzero
  ;; block base point must remain the correct elliptical QUARTER, not 3/4 arc.
  (setq arcblock (vla-Add (vla-get-Blocks sht-doc)
    (vlax-3d-point '(10.0 20.0 0.0)) "SHT_V2_ARC_BASEPOINT")
        arc0 (vla-AddArc arcblock (vlax-3d-point '(10.0 20.0 0.0)) 3.0 0.0 (/ pi 2.0))
        arcref (vla-InsertBlock sht-space (vlax-3d-point '(1000.0 1000.0 0.0))
          "SHT_V2_ARC_BASEPOINT" -2.0 0.5 1.0 (/ pi 6.0))
        outline1 (SHT:Rect 980.0 980.0 1020.0 1020.0))
  (command-s "_.WIPEOUT" "_Polyline" (vlax-vla-object->ename outline1) "_No")
  (setq arcmask (vlax-ename->vla-object (entlast)) before (SHT:Count)
        out (SHT:V2Build (list arcref) (list arcmask) 'Auto "Wipeout")
        a '(994.8038475772934 997.0 0.0)
        b '(999.25 1001.2990381056767 0.0))
  (SHT:Assert "nonuniform reflected fillet retains correct quarter-ellipse length"
    (and (= 1 (length out)) (< 6.0 (SHT:Len out) 7.0)))
  (SHT:Assert "nonzero block base point and rotation map fillet endpoints correctly"
    (and out
      (or (and (equal a (vlax-curve-getStartPoint (car out)) 1e-5)
               (equal b (vlax-curve-getEndPoint (car out)) 1e-5))
          (and (equal b (vlax-curve-getStartPoint (car out)) 1e-5)
               (equal a (vlax-curve-getEndPoint (car out)) 1e-5)))))
  (SHT:Assert "fillet fallback preserves original block and cleans all intermediate copies"
    (and (= 1 (vla-get-Count arcblock)) (= (+ before (length out)) (SHT:Count))))
  (SHT:Remove out)
  (write-line (strcat "TOTAL " (itoa sht-pass) " passed, " (itoa sht-fail) " failed") sht-log)
  (close sht-log) (setq sht-log nil)
  (princ (strcat "\nV2 TOTAL " (itoa sht-pass) " passed, " (itoa sht-fail) " failed")))
(SHT:V2Run)
(princ)
