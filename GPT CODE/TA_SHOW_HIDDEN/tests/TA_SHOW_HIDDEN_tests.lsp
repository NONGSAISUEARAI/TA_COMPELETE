;;; Native AutoCAD / Core Console integration tests. Disposable drawing only.
(vl-load-com)
(setq sht-doc (vla-get-ActiveDocument (vlax-get-acad-object))
      sht-space (vla-get-ModelSpace sht-doc)
      sht-pass 0 sht-fail 0
      sht-log (open (strcat sht-root "tests/results.txt") "w"))

(defun SHT:Assert (label ok)
  (write-line (strcat (if ok "PASS " "FAIL ") label) sht-log)
  (princ (strcat "\n" (if ok "PASS " "FAIL ") label))
  (if ok (setq sht-pass (1+ sht-pass)) (setq sht-fail (1+ sht-fail))) ok)
(defun SHT:Line (a b)
  (vla-AddLine sht-space (vlax-3d-point a) (vlax-3d-point b)))
(defun SHT:Rect (x0 y0 x1 y1 / obj)
  (setq obj (vlax-invoke sht-space 'AddLightWeightPolyline
    (list x0 y0 x1 y0 x1 y1 x0 y1)))
  (vla-put-Closed obj :vlax-true) obj)
(defun SHT:Hatch (loops style / h arr)
  (setq h (vla-AddHatch sht-space 0 "SOLID" :vlax-false 0))
  (foreach obj loops
    (setq arr (vlax-make-safearray vlax-vbObject '(0 . 0)))
    (vlax-safearray-put-element arr 0 obj)
    (if (eq obj (car loops)) (vla-AppendOuterLoop h arr) (vla-AppendInnerLoop h arr)))
  (vla-put-HatchStyle h style) (vla-Evaluate h) h)
(defun SHT:Build (sources masks / result)
  (setq result (TA:SHW:Build (mapcar 'vlax-vla-object->ename sources)
               (mapcar 'vlax-vla-object->ename masks) 0.1))
  (write-line (strcat "BUILD: " (if TA:SHW-LastError TA:SHW-LastError "OK")
    " count=" (itoa (length result)) " length=" (rtos (SHT:Len result) 2 8)) sht-log)
  result)
(defun SHT:Len (objs / sum)
  (setq sum 0.0)
  (foreach obj objs (setq sum (+ sum (TA:SHW:Length obj)))) sum)
(defun SHT:Count (/ ss)
  (if (setq ss (ssget "_X")) (sslength ss) 0))
(defun SHT:Remove (objs) (foreach obj objs (TA:SHW:Delete obj)))

(defun SHT:Run (/ outline hatch source before out hole hatchhole hignore houter
                  circle curved arc tangent block insert nested rotated scaled
                  mirror nohit elev data original count0 unsupported failout
                  poly coords wipe vertices ss maskedblock maskref pap paperline
                  oldtab normalneg ellipse spline bound hpatch layer)
  (setq outline (SHT:Rect 0.0 0.0 10.0 10.0)
        hatch (SHT:Hatch (list outline) 0)
        source (SHT:Line '(-5.0 5.0 0.0) '(15.0 5.0 0.0))
        data (entget (vlax-vla-object->ename source))
        count0 (SHT:Count)
        out (SHT:Build (list source) (list hatch)))
  (SHT:Assert "line clips to hatch: one exact 10-unit segment"
    (and (= 1 (length out)) (equal 10.0 (SHT:Len out) 1e-6)))
  (SHT:Assert "source unchanged" (equal data (entget (vlax-vla-object->ename source))))
  (SHT:Assert "temporary objects removed" (= (+ count0 (length out)) (SHT:Count)))
  (SHT:Assert "overlay layer and hidden linetype"
    (and out (= TA:SHW-Layer (vla-get-Layer (car out)))
         (= "HIDDEN" (vla-get-Linetype (vla-Item (vla-get-Layers sht-doc) TA:SHW-Layer)))
         (equal 0.1 (vla-get-LinetypeScale (car out)) 1e-9)))
  (SHT:Remove out)
  ;; Rectangle from the user's illustration: two inside sides, two outside.
  (setq poly (SHT:Rect 5.0 5.0 15.0 15.0)
        out (SHT:Build (list poly) (list hatch)))
  (SHT:Assert "user example: only two covered rectangle sides"
    (and (= 2 (length out)) (equal 10.0 (SHT:Len out) 1e-6)))
  (SHT:Remove out)
  (setq hole (SHT:Rect 3.0 3.0 7.0 7.0)
        hatchhole (SHT:Hatch (list outline hole) 0)
        out (SHT:Build (list source) (list hatchhole)))
  (SHT:Assert "hatch island remains empty"
    (and (= 2 (length out)) (equal 6.0 (SHT:Len out) 1e-6)))
  (SHT:Remove out)
  (setq out (SHT:Build (list source) (list hatchhole hatch)))
  (SHT:Assert "overlapping masks form union without duplicate segments"
    (and (= 1 (length out)) (equal 10.0 (SHT:Len out) 1e-6)))
  (SHT:Remove out)
  (setq hignore (SHT:Hatch (list outline hole) 2)
        out (SHT:Build (list source) (list hignore)))
  (SHT:Assert "ignore-islands hatch style" (equal 10.0 (SHT:Len out) 1e-6))
  (SHT:Remove out)
  (setq nohit (SHT:Line '(-5.0 15.0 0.0) '(15.0 15.0 0.0))
        before (SHT:Count) out (SHT:Build (list nohit) (list hatch)))
  (SHT:Assert "no overlap creates nothing and cleans up"
    (and (null out) (null TA:SHW-LastError) (= before (SHT:Count))))
  (setq tangent (SHT:Line '(0.0 0.0 0.0) '(10.0 0.0 0.0))
        out (SHT:Build (list tangent) (list hatch)))
  (SHT:Assert "coincident mask edge is not an interior segment" (null out))
  (setq circle (vla-AddCircle sht-space (vlax-3d-point '(5.0 5.0 0.0)) 8.0)
        out (SHT:Build (list circle) (list hatch)))
  (SHT:Assert "circle outside square produces no overlays" (null out))
  (setq curved (vla-AddCircle sht-space (vlax-3d-point '(5.0 5.0 0.0)) 3.0)
        out (SHT:Build (list curved) (list hatch)))
  (SHT:Assert "fully covered circle remains an exact circle"
    (and (= 1 (length out)) (= "AcDbCircle" (vla-get-ObjectName (car out)))
         (equal (* 6.0 pi) (SHT:Len out) 1e-6)))
  (SHT:Remove out)
  (setq arc (vla-AddCircle sht-space (vlax-3d-point '(10.0 5.0 0.0)) 3.0)
        out (SHT:Build (list arc) (list hatch)))
  (SHT:Assert "half circle clips to exact arc"
    (and out (equal (* 3.0 pi) (SHT:Len out) 1e-6)
         (vl-every '(lambda (o) (= "AcDbArc" (vla-get-ObjectName o))) out)))
  (SHT:Remove out)
  ;; Curved mask; tangent should produce no segment.
  (setq hpatch (SHT:Hatch (list curved) 0)
        out (SHT:Build (list source) (list hpatch)))
  (SHT:Assert "circular hatch boundary uses exact intersections" (equal 6.0 (SHT:Len out) 1e-6))
  (SHT:Remove out)
  ;; Nonzero source elevation is preserved while overlap uses plan projection.
  (setq elev (SHT:Line '(-5.0 5.0 20.0) '(15.0 5.0 20.0))
        out (SHT:Build (list elev) (list hatch)))
  (SHT:Assert "plan overlap preserves original source elevation"
    (and out (equal 20.0 (caddr (vlax-curve-getStartPoint (car out))) 1e-7)
         (equal 10.0 (SHT:Len out) 1e-6)))
  (SHT:Remove out)
  ;; Block reference at (5,5), horizontal local line through origin.
  (setq block (vla-Add (vla-get-Blocks sht-doc) (vlax-3d-point '(0.0 0.0 0.0)) "SHT_SOURCE"))
  (vla-AddLine block (vlax-3d-point '(-10.0 0.0 0.0)) (vlax-3d-point '(10.0 0.0 0.0)))
  (setq insert (vla-InsertBlock sht-space (vlax-3d-point '(5.0 5.0 0.0)) "SHT_SOURCE" 1.0 1.0 1.0 0.0)
        original (entget (vlax-vla-object->ename insert))
        before (vla-get-Count block) count0 (SHT:Count)
        out (SHT:Build (list insert) (list hatch)))
  (SHT:Assert "block generates overlay in model space outside definition"
    (and out (eq (cdr (assoc 330 (entget (vlax-vla-object->ename (car out)))))
                 (vlax-vla-object->ename sht-space))
         (= before (vla-get-Count block))
         (equal original (entget (vlax-vla-object->ename insert)))
         (= (+ count0 (length out)) (SHT:Count))
         (equal 10.0 (SHT:Len out) 1e-6)))
  (SHT:Remove out)
  (setq rotated (vla-InsertBlock sht-space (vlax-3d-point '(5.0 5.0 0.0)) "SHT_SOURCE" 1.0 1.0 1.0 (/ pi 2.0))
        out (SHT:Build (list rotated) (list hatch)))
  (SHT:Assert "rotated block clips in world coordinates" (equal 10.0 (SHT:Len out) 1e-6))
  (SHT:Remove out)
  (setq scaled (vla-InsertBlock sht-space (vlax-3d-point '(5.0 5.0 0.0)) "SHT_SOURCE" 2.0 0.5 1.0 0.0)
        mirror (vla-InsertBlock sht-space (vlax-3d-point '(5.0 5.0 0.0)) "SHT_SOURCE" -1.0 1.0 1.0 0.0)
        out (SHT:Build (list scaled) (list hatch)))
  (SHT:Assert "nonuniformly scaled block" (equal 10.0 (SHT:Len out) 1e-6))
  (SHT:Remove out)
  (setq out (SHT:Build (list mirror) (list hatch)))
  (SHT:Assert "mirrored block" (equal 10.0 (SHT:Len out) 1e-6))
  (SHT:Remove out)
  (setq nested (vla-Add (vla-get-Blocks sht-doc) (vlax-3d-point '(0.0 0.0 0.0)) "SHT_NESTED"))
  (vla-InsertBlock nested (vlax-3d-point '(0.0 0.0 0.0)) "SHT_SOURCE" 1.0 1.0 1.0 (/ pi 2.0))
  (setq insert (vla-InsertBlock sht-space (vlax-3d-point '(5.0 5.0 0.0)) "SHT_NESTED" 1.0 1.0 1.0 0.0)
        out (SHT:Build (list insert) (list hatch)))
  (SHT:Assert "nested block retains its transform" (equal 10.0 (SHT:Len out) 1e-6))
  (SHT:Remove out)
  ;; Native WIPEOUT, rectangle generated from an actual polyline.
  (setq bound (SHT:Rect 0.0 0.0 10.0 10.0))
  (vl-cmdf "_.WIPEOUT" "_Polyline" (vlax-vla-object->ename bound) "_No")
  (setq wipe (vlax-ename->vla-object (entlast))
        out (SHT:Build (list source) (list wipe)))
  (SHT:Assert "native WIPEOUT boundary and half-pixel correction"
    (and (= "AcDbWipeout" (vla-get-ObjectName wipe))
         (= 1 (length out)) (equal 10.0 (SHT:Len out) 1e-6)
         (equal '(0.0 5.0 0.0) (vlax-curve-getStartPoint (car out)) 1e-6)))
  (SHT:Remove out)
  ;; Rejected tilted source must remove every temporary entity and output.
  (setq unsupported (SHT:Line '(0.0 0.0 0.0) '(10.0 10.0 2.0))
        before (SHT:Count) out (SHT:Build (list source unsupported) (list hatch)))
  (SHT:Assert "failure rolls back and removes working objects"
    (and (null out) TA:SHW-LastError (= before (SHT:Count))))
  ;; Mask geometry can itself be inside a translated block.
  (setq maskedblock (vla-Add (vla-get-Blocks sht-doc)
    (vlax-3d-point '(0.0 0.0 0.0)) "SHT_MASK"))
  (vla-CopyObjects sht-doc
    (vlax-make-variant (vlax-safearray-fill
      (vlax-make-safearray vlax-vbObject '(0 . 0)) (list hatch))) maskedblock)
  (setq maskref (vla-InsertBlock sht-space (vlax-3d-point '(20.0 0.0 0.0))
    "SHT_MASK" 1.0 1.0 1.0 0.0)
        elev (SHT:Line '(15.0 5.0 0.0) '(35.0 5.0 0.0))
        out (SHT:Build (list elev) (list maskref)))
  (SHT:Assert "hatch inside translated block acts as mask"
    (and out (equal 10.0 (SHT:Len out) 1e-6)
         (equal '(20.0 5.0 0.0) (vlax-curve-getStartPoint (car out)) 1e-6)))
  (SHT:Remove out)
  ;; Both the hatch and source must survive untouched, including on locked layers.
  (setq original (entget (vlax-vla-object->ename hatch))
        layer (vla-Add (vla-get-Layers sht-doc) "SHT_LOCKED"))
  (vla-put-Layer source "SHT_LOCKED") (vla-put-Lock layer :vlax-true)
  (setq before (SHT:Count) out (SHT:Build (list source) (list hatch)))
  (SHT:Assert "locked source layer is restored and temporary copies removed"
    (and out (= :vlax-true (vla-get-Lock layer))
         (= (+ before (length out)) (SHT:Count))
         (equal 10.0 (SHT:Len out) 1e-6)))
  (SHT:Assert "original hatch remains unchanged"
    (equal original (entget (vlax-vla-object->ename hatch))))
  (SHT:Remove out)
  ;; Rotated UCS affects neither the mask nor the generated world geometry.
  (command-s "_.UCS" "_Z" 37.0)
  (setq out (SHT:Build (list source) (list hatch)))
  (SHT:Assert "rotated UCS does not alter world-coordinate clipping"
    (and out (equal '(0.0 5.0 0.0) (vlax-curve-getStartPoint (car out)) 1e-6)))
  (SHT:Remove out) (command-s "_.UCS" "_World")
  ;; Ellipses and splines are emitted as adaptive polylines.
  (setq ellipse (vla-AddEllipse sht-space (vlax-3d-point '(5.0 5.0 0.0))
    (vlax-3d-point '(3.0 0.0 0.0)) 0.5)
        out (SHT:Build (list ellipse) (list hatch)))
  (SHT:Assert "ellipse produces a bounded-tolerance polyline"
    (and (= 1 (length out)) (= "AcDbPolyline" (vla-get-ObjectName (car out)))
         (< (abs (- (SHT:Len out) (TA:SHW:Length ellipse))) 0.15)))
  (SHT:Remove out)
  (setq spline (vlax-invoke sht-space 'AddSpline
    '(1.0 5.0 0.0 3.0 8.0 0.0 7.0 2.0 0.0 9.0 5.0 0.0)
    '(1.0 1.0 0.0) '(1.0 1.0 0.0))
        out (SHT:Build (list spline) (list hatch)))
  (SHT:Assert "S-shaped spline sampling preserves curvature"
    (and out (> (SHT:Len out) 10.0)
         (< (abs (- (SHT:Len out) (TA:SHW:Length spline))) 0.2)))
  (SHT:Remove out)
  ;; A source touching only the circular mask at one point creates no overlay.
  (setq tangent (SHT:Line '(0.0 8.0 0.0) '(10.0 8.0 0.0))
        out (SHT:Build (list tangent) (list hpatch)))
  (SHT:Assert "tangent to curved hatch does not create hidden geometry"
    (and (null out) (null TA:SHW-LastError)))
  ;; Nested islands: normal fills depth 3, outer style fills only depth 1.
  (setq bound (SHT:Rect 4.0 4.0 6.0 6.0)
        houter (SHT:Hatch (list outline hole bound) 1)
        hignore (SHT:Hatch (list outline hole bound) 0)
        out (SHT:Build (list source) (list houter)))
  (SHT:Assert "outer hatch style excludes inner nested island" (equal 6.0 (SHT:Len out) 1e-6))
  (SHT:Remove out)
  (setq out (SHT:Build (list source) (list hignore)))
  (SHT:Assert "normal hatch style fills nested island" (equal 8.0 (SHT:Len out) 1e-6))
  (SHT:Remove out)
  ;; Paper-space output must have the paper-space owner, never a block owner.
  (setvar "TILEMODE" 0)
  (setq pap (vla-get-PaperSpace sht-doc)
        paperline (vla-AddLine pap (vlax-3d-point '(-5.0 5.0 0.0))
          (vlax-3d-point '(15.0 5.0 0.0)))
        hpatch (car (TA:SHW:List (vla-CopyObjects sht-doc
          (vlax-make-variant (vlax-safearray-fill
            (vlax-make-safearray vlax-vbObject '(0 . 0)) (list hatch))) pap)))
        out (SHT:Build (list paperline) (list hpatch)))
  (SHT:Assert "paper space output belongs to active layout"
    (and out (equal 10.0 (SHT:Len out) 1e-6)
         (eq (vlax-vla-object->ename pap)
           (cdr (assoc 330 (entget (vlax-vla-object->ename (car out))))))))
  (SHT:Remove out) (setvar "TILEMODE" 1)
  (write-line (strcat "TOTAL " (itoa sht-pass) " passed, " (itoa sht-fail) " failed") sht-log)
  (close sht-log)
  (princ (strcat "\nTOTAL " (itoa sht-pass) " passed, " (itoa sht-fail) " failed")))
(SHT:Run)
(princ)
