;;; TA_SPLITBY1.lsp -- Split one curve at intersections with selected cutters.
;;; Windows AutoCAD / Visual LISP. No gap; cutters are left in place.
;;; Targets: LINE, ARC, CIRCLE, LWPOLYLINE, 2D/3D POLYLINE,
;;;          ELLIPSE and SPLINE. Blocks, meshes and non-curves are excluded.
;;; Cutters additionally accept XLINE and RAY. Uses actual 3D intersections.
;;; Load with APPLOAD; run TA_SPLITBY1 (alias SPLIT1).
(vl-load-com)

(defun TA:SB1-curve-p (e / d)
  (and e (setq d (entget e))
    (member (cdr (assoc 0 d))
      '("LINE" "ARC" "CIRCLE" "LWPOLYLINE" "POLYLINE" "ELLIPSE" "SPLINE"))
    (or (/= "POLYLINE" (cdr (assoc 0 d)))
        (= 0 (logand 80 (cdr (assoc 70 d)))))))

(defun TA:SB1-cutter-p (e)
  (or (TA:SB1-curve-p e)
      (member (cdr (assoc 0 (entget e))) '("XLINE" "RAY"))))

(defun TA:SB1-length (e)
  (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)))

(defun TA:SB1-fail (msg)
  (princ (strcat "\nTA_SPLITBY1: " msg))
  (exit))

(defun TA:SB1-unique (pts tol / out p)
  (foreach p pts
    (if (not (vl-some '(lambda (q) (equal p q tol)) out))
      (setq out (cons p out))))
  (reverse out))

(defun TA:SB1-intersections (target cutters / obj e data pts)
  (setq obj (vlax-ename->vla-object target))
  (foreach e cutters
    (if (and (not (eq target e)) (TA:SB1-cutter-p e))
      (progn
        ;; vlax-invoke returns a flat list in WCS; 0 = acExtendNone.
        (setq data (vl-catch-all-apply 'vlax-invoke
          (list obj 'IntersectWith (vlax-ename->vla-object e) 0)))
        (if (vl-catch-all-error-p data)
          (TA:SB1-fail (strcat "Cannot calculate intersection with handle "
            (cdr (assoc 5 (entget e))) ": "
            (vl-catch-all-error-message data))))
        (while data
          (setq pts (cons (list (car data) (cadr data) (caddr data)) pts)
                data (cdddr data))))))
  (reverse pts))

(defun TA:SB1-points (e pts tol / closed len out p q d)
  (setq closed (vlax-curve-isClosed e) len (TA:SB1-length e))
  (foreach p (TA:SB1-unique pts tol)
    (setq q (vlax-curve-getClosestPointTo e p))
    (if (and q (<= (distance p q) tol))
      (progn
        (setq d (vlax-curve-getDistAtPoint e q))
        ;; Endpoints of an open curve are already boundaries.
        (if (or closed (and (> d tol) (> (- len d) tol)))
          (setq out (cons q out))))))
  (vl-sort (TA:SB1-unique out tol)
    '(lambda (a b) (< (vlax-curve-getDistAtPoint e a)
                      (vlax-curve-getDistAtPoint e b)))))

(defun TA:SB1-copy (e / copy)
  (setq copy (vlax-vla-object->ename (vla-Copy (vlax-ename->vla-object e)))
        ta:sb1-created (cons copy ta:sb1-created))
  copy)

(defun TA:SB1-break (e p q / marker next result err)
  (setq marker (entlast))
  (setq err (vl-catch-all-apply 'command-s
    (list "_.BREAK" e "_F" "_non" (trans p 0 1) "_non" (trans q 0 1))))
  ;; Collect all new main curve entities, skipping POLYLINE vertices/SEQEND.
  ;; Register them even on failure, so the command can remove working copies.
  (setq next marker)
  (while (setq next (entnext next))
    (if (TA:SB1-curve-p next)
      (setq result (cons next result)
            ta:sb1-created (cons next ta:sb1-created))))
  (if (entget e) (setq result (cons e result)))
  (if (vl-catch-all-error-p err)
    (TA:SB1-fail (vl-catch-all-error-message err)))
  result)

(defun TA:SB1-interior-p (e p tol / q d len)
  (and (setq q (vlax-curve-getClosestPointTo e p))
       (<= (distance q p) tol)
       (setq d (vlax-curve-getDistAtPoint e q)
             len (TA:SB1-length e))
       (> d tol) (> (- len d) tol)))

(defun TA:SB1-split (e pts tol / closed pieces a b p part new found expected sum)
  ;; Work exclusively on copies. The caller commits only after validation.
  (setq closed (vlax-curve-isClosed e))
  (if closed
    (progn
      (if (< (length pts) 2)
        (TA:SB1-fail "A closed curve needs at least two distinct cut points."))
      (setq a (TA:SB1-copy e) b (TA:SB1-copy e))
      ;; Complementary BREAKs retain both sides of a closed curve.
      (setq pieces (append
        (TA:SB1-break a (car pts) (cadr pts))
        (TA:SB1-break b (cadr pts) (car pts))))
      (if (or (/= 2 (length pieces))
              (vl-some 'vlax-curve-isClosed pieces))
        (TA:SB1-fail "AutoCAD could not open this closed curve safely."))
      (setq expected (length pts) pts (cddr pts)))
    (setq pieces (list (TA:SB1-copy e)) expected (1+ (length pts))))
  (foreach p pts
    (setq new nil found nil)
    (foreach part pieces
      (if (and (not found) (TA:SB1-interior-p part p tol))
        (progn
          (setq a (TA:SB1-break part p p))
          (if (/= 2 (length a))
            (TA:SB1-fail "AutoCAD did not produce two pieces at a cut point."))
          (setq new (append a new) found T))
        (setq new (cons part new))))
    (if (not found) (TA:SB1-fail "A cut point could not be located on a working piece."))
    (setq pieces new))
  (setq sum 0.0)
  (foreach part pieces
    (if (<= (TA:SB1-length part) tol)
      (TA:SB1-fail "A zero-length piece was detected."))
    (setq sum (+ sum (TA:SB1-length part))))
  (if (or (/= expected (length pieces))
          (> (abs (- sum (TA:SB1-length e)))
             (max (* 10.0 tol) (* 1e-8 (TA:SB1-length e)))))
    (TA:SB1-fail "Piece count or total length check failed; original retained."))
  pieces)

(defun TA:SB1-cleanup (entities / e)
  (foreach e entities
    (if (entget e) (vl-catch-all-apply 'entdel (list e)))))

(defun c:TA_SPLITBY1 (/ *error* doc oldvars undo target ss cutters i e p pair skip
                         len tol pts pieces ta:sb1-created ta:sb1-deleted)
  (defun *error* (msg)
    (TA:SB1-cleanup ta:sb1-created)
    (if (and ta:sb1-deleted (not (entget ta:sb1-deleted)))
      (entdel ta:sb1-deleted))
    (foreach pair oldvars (setvar (car pair) (cdr pair)))
    (if undo (vla-EndUndoMark doc))
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*EXIT*")))
      (princ (strcat "\nTA_SPLITBY1 error: " msg)))
    (princ))
  (setq target (car (entsel "\nSelect ONE curve to split (not a block): ")))
  (cond
    ((null target) (princ "\nNothing selected."))
    ((not (TA:SB1-curve-p target))
      (princ "\nSelect LINE / Polyline / ARC / CIRCLE / ELLIPSE / SPLINE. Blocks and non-curves are excluded."))
    ((/= 0 (logand 4 (cdr (assoc 70
         (tblsearch "LAYER" (cdr (assoc 8 (entget target))))))))
      (princ "\nThe target layer is locked."))
    (T
      (princ "\nSelect cutting objects (blocks and non-curves will be skipped): ")
      (if (setq ss (ssget))
        (progn
          (setq i 0 skip 0)
          (repeat (sslength ss)
            (setq e (ssname ss i) i (1+ i))
            (cond
              ((eq e target))
              ((TA:SB1-cutter-p e) (setq cutters (cons e cutters)))
              (T (setq skip (1+ skip)))))
          (setq len (TA:SB1-length target) tol (max 1e-7 (* len 1e-10))
                pts (TA:SB1-points target
                      (TA:SB1-intersections target cutters) tol))
          (cond
            ((null pts) (princ "\nNo distinct interior intersection points found."))
            ((and (vlax-curve-isClosed target) (< (length pts) 2))
              (princ "\nOnly one cut point: a closed curve needs at least two."))
            (T
              (setq doc (vla-get-ActiveDocument (vlax-get-acad-object))
                    oldvars (mapcar '(lambda (v) (cons v (getvar v)))
                                    '("CMDECHO" "OSMODE" "3DOSMODE")))
              (vla-StartUndoMark doc)
              (setq undo T)
              (setvar "CMDECHO" 0)
              (setvar "OSMODE" 0)
              (setvar "3DOSMODE" 0)
              (setq pieces (TA:SB1-split target pts tol))
              ;; Validate that every requested point is a shared boundary.
              (foreach p pts
                (setq i 0)
                (foreach e pieces
                  (if (or (equal p (vlax-curve-getStartPoint e) tol)
                          (equal p (vlax-curve-getEndPoint e) tol))
                    (setq i (1+ i))))
                (if (< i 2) (TA:SB1-fail "Cut boundary validation failed; original retained.")))
              (if (not (entdel target))
                (TA:SB1-fail "Cannot erase original; working copies removed."))
              (setq ta:sb1-deleted target)
              (foreach pair oldvars (setvar (car pair) (cdr pair)))
              (vla-EndUndoMark doc)
              (setq undo nil ta:sb1-created nil ta:sb1-deleted nil)
              (princ (strcat "\nSplit at " (itoa (length pts)) " points into "
                             (itoa (length pieces)) " pieces. Cutters retained."))))
          (if (> skip 0)
            (princ (strcat "\nSkipped " (itoa skip) " block/non-curve object(s).")))))))
  (princ))

(defun c:SPLIT1 () (c:TA_SPLITBY1))
(princ "\nLoaded TA_SPLITBY1. Command: TA_SPLITBY1 or SPLIT1.")
(princ)
